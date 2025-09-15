import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Enhanced performance monitoring utility with device profiling
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Queue<double> _frameTimes = Queue<double>();
  final Queue<double> _memoryUsage = Queue<double>();
  DateTime? _lastFrameTime;
  DateTime? _lastMemoryCheck;
  double _averageFps = 60.0;
  double _averageMemoryMB = 0.0;
  int _frameCount = 0;
  int _droppedFrames = 0;
  
  // Performance thresholds
  static const int _maxSamples = 120; // Keep last 2 seconds of frame times
  static const double _targetFps = 60.0;
  static const double _lowPerformanceThreshold = 45.0; // FPS below this is considered poor
  static const double _memoryCheckInterval = 1.0; // Check memory every second
  
  // Device performance profile
  DevicePerformanceProfile? _deviceProfile;
  bool _isLowEndDevice = false;
  
  // Performance history for trend analysis
  final Queue<double> _performanceHistory = Queue<double>();
  static const int _maxHistorySamples = 30; // 30 seconds of history

  /// Initialize performance monitoring with device profiling
  Future<void> initialize() async {
    _deviceProfile = await _createDeviceProfile();
    _isLowEndDevice = _deviceProfile!.isLowEnd;
    
    if (kDebugMode) {
      print('Device Profile: ${_deviceProfile!.toString()}');
    }
  }

  /// Record a frame update with enhanced metrics
  void recordFrame() {
    final now = DateTime.now();
    
    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!).inMicroseconds / 1000000.0;
      
      // Track dropped frames (frame time > 20ms indicates dropped frame at 60fps)
      if (frameTime > 0.020) {
        _droppedFrames++;
      }
      
      _frameTimes.add(frameTime);
      
      // Keep only recent samples
      if (_frameTimes.length > _maxSamples) {
        _frameTimes.removeFirst();
      }
      
      // Calculate average FPS
      if (_frameTimes.isNotEmpty) {
        final averageFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
        _averageFps = 1.0 / averageFrameTime;
      }
      
      // Update performance history every second
      if (_frameCount % 60 == 0) {
        _performanceHistory.add(performanceQuality);
        if (_performanceHistory.length > _maxHistorySamples) {
          _performanceHistory.removeFirst();
        }
      }
    }
    
    _lastFrameTime = now;
    _frameCount++;
    
    // Check memory usage periodically
    _checkMemoryUsage(now);
  }

  /// Check and record memory usage
  void _checkMemoryUsage(DateTime now) {
    if (_lastMemoryCheck == null || 
        now.difference(_lastMemoryCheck!).inMilliseconds >= _memoryCheckInterval * 1000) {
      
      // Note: ProcessInfo.currentRss is not available in Flutter
      // We'll use a placeholder for now and implement platform-specific memory monitoring
      final memoryMB = _getMemoryUsageMB();
      
      _memoryUsage.add(memoryMB);
      if (_memoryUsage.length > 60) { // Keep 1 minute of memory samples
        _memoryUsage.removeFirst();
      }
      
      if (_memoryUsage.isNotEmpty) {
        _averageMemoryMB = _memoryUsage.reduce((a, b) => a + b) / _memoryUsage.length;
      }
      
      _lastMemoryCheck = now;
    }
  }

  /// Get current memory usage in MB (placeholder implementation)
  double _getMemoryUsageMB() {
    // This is a placeholder - in a real implementation, you would use
    // platform-specific code to get actual memory usage
    return 50.0 + (_frameCount * 0.001); // Simulated memory growth
  }

  /// Create device performance profile
  Future<DevicePerformanceProfile> _createDeviceProfile() async {
    // Detect device capabilities
    final isAndroid = Platform.isAndroid;
    final isIOS = Platform.isIOS;
    
    // Run a quick performance test
    final performanceScore = await _runPerformanceTest();
    
    return DevicePerformanceProfile(
      platform: isAndroid ? 'Android' : (isIOS ? 'iOS' : 'Other'),
      performanceScore: performanceScore,
      isLowEnd: performanceScore < 0.6,
      recommendedParticleCount: _getRecommendedParticleCount(performanceScore),
      recommendedGraphicsQuality: _getRecommendedGraphicsQuality(performanceScore),
    );
  }

  /// Run a quick performance test to assess device capabilities
  Future<double> _runPerformanceTest() async {
    final stopwatch = Stopwatch()..start();
    
    // Simulate some computational work
    double result = 0.0;
    for (int i = 0; i < 100000; i++) {
      result += i * 0.001;
    }
    
    stopwatch.stop();
    final executionTimeMs = stopwatch.elapsedMicroseconds / 1000.0;
    
    // Score based on execution time (lower is better)
    // Normalize to 0.0-1.0 range where 1.0 is best performance
    final score = (20.0 / executionTimeMs).clamp(0.0, 1.0);
    
    return score;
  }

  /// Get recommended particle count based on performance score
  int _getRecommendedParticleCount(double score) {
    if (score >= 0.8) return 300;
    if (score >= 0.6) return 200;
    if (score >= 0.4) return 100;
    return 50;
  }

  /// Get recommended graphics quality based on performance score
  String _getRecommendedGraphicsQuality(double score) {
    if (score >= 0.8) return 'high';
    if (score >= 0.6) return 'medium';
    return 'low';
  }

  /// Get current average FPS
  double get averageFps => _averageFps;

  /// Get current frame time in milliseconds
  double get currentFrameTimeMs => _frameTimes.isNotEmpty ? _frameTimes.last * 1000 : 16.67;

  /// Get current memory usage in MB
  double get currentMemoryMB => _averageMemoryMB;

  /// Check if performance is good
  bool get isPerformanceGood => _averageFps >= _lowPerformanceThreshold;

  /// Check if performance is degrading
  bool get isPerformanceDegrading {
    if (_performanceHistory.length < 5) return false;
    
    final recent = _performanceHistory.skip(_performanceHistory.length - 3).toList();
    final older = _performanceHistory.take(3).toList();
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    
    return recentAvg < olderAvg - 0.1; // 10% degradation
  }

  /// Get performance quality (0.0 to 1.0)
  double get performanceQuality => (_averageFps / _targetFps).clamp(0.0, 1.0);

  /// Get performance trend (-1.0 to 1.0, negative means degrading)
  double get performanceTrend {
    if (_performanceHistory.length < 10) return 0.0;
    
    final recent = _performanceHistory.skip(_performanceHistory.length - 5);
    final older = _performanceHistory.take(5);
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    
    return ((recentAvg - olderAvg) * 2.0).clamp(-1.0, 1.0);
  }

  /// Get dropped frame percentage
  double get droppedFramePercentage => 
      _frameCount > 0 ? (_droppedFrames / _frameCount) * 100.0 : 0.0;

  /// Check if device is low-end
  bool get isLowEndDevice => _isLowEndDevice;

  /// Get device performance profile
  DevicePerformanceProfile? get deviceProfile => _deviceProfile;

  /// Get adaptive quality recommendation
  AdaptiveQualityRecommendation getAdaptiveQualityRecommendation() {
    final currentQuality = performanceQuality;
    final trend = performanceTrend;
    final memoryPressure = _averageMemoryMB > 200.0; // High memory usage threshold
    
    QualityLevel particleQuality;
    QualityLevel graphicsQuality;
    
    // Determine particle quality
    if (currentQuality >= 0.9 && trend >= 0.0 && !memoryPressure) {
      particleQuality = QualityLevel.ultra;
    } else if (currentQuality >= 0.7 && trend >= -0.2) {
      particleQuality = QualityLevel.high;
    } else if (currentQuality >= 0.5) {
      particleQuality = QualityLevel.medium;
    } else {
      particleQuality = QualityLevel.low;
    }
    
    // Determine graphics quality (slightly more conservative)
    if (currentQuality >= 0.85 && trend >= 0.0 && !memoryPressure) {
      graphicsQuality = QualityLevel.ultra;
    } else if (currentQuality >= 0.65 && trend >= -0.2) {
      graphicsQuality = QualityLevel.high;
    } else if (currentQuality >= 0.45) {
      graphicsQuality = QualityLevel.medium;
    } else {
      graphicsQuality = QualityLevel.low;
    }
    
    return AdaptiveQualityRecommendation(
      particleQuality: particleQuality,
      graphicsQuality: graphicsQuality,
      shouldReduceEffects: currentQuality < 0.6 || trend < -0.3,
      memoryPressure: memoryPressure,
    );
  }

  /// Get comprehensive performance statistics
  Map<String, dynamic> getStats() {
    return {
      'averageFps': _averageFps.toStringAsFixed(1),
      'frameTimeMs': currentFrameTimeMs.toStringAsFixed(2),
      'frameCount': _frameCount,
      'droppedFrames': _droppedFrames,
      'droppedFramePercentage': droppedFramePercentage.toStringAsFixed(1),
      'performanceGood': isPerformanceGood,
      'performanceDegrading': isPerformanceDegrading,
      'quality': performanceQuality.toStringAsFixed(2),
      'trend': performanceTrend.toStringAsFixed(2),
      'memoryMB': _averageMemoryMB.toStringAsFixed(1),
      'isLowEndDevice': _isLowEndDevice,
      'deviceProfile': _deviceProfile?.toMap(),
    };
  }

  /// Get performance test results for benchmarking
  Map<String, dynamic> runPerformanceTest() {
    final stopwatch = Stopwatch()..start();
    
    // CPU test
    double cpuResult = 0.0;
    for (int i = 0; i < 1000000; i++) {
      cpuResult += i * 0.001;
    }
    final cpuTime = stopwatch.elapsedMicroseconds;
    
    stopwatch.reset();
    
    // Memory allocation test
    final List<List<double>> memoryTest = [];
    for (int i = 0; i < 1000; i++) {
      memoryTest.add(List.filled(100, i.toDouble()));
    }
    final memoryTime = stopwatch.elapsedMicroseconds;
    
    stopwatch.stop();
    
    return {
      'cpuTestTime': cpuTime,
      'memoryTestTime': memoryTime,
      'cpuScore': (1000000.0 / cpuTime).clamp(0.0, 1.0),
      'memoryScore': (100000.0 / memoryTime).clamp(0.0, 1.0),
      'overallScore': ((1000000.0 / cpuTime) + (100000.0 / memoryTime)) / 2.0,
    };
  }

  /// Reset statistics
  void reset() {
    _frameTimes.clear();
    _memoryUsage.clear();
    _performanceHistory.clear();
    _lastFrameTime = null;
    _lastMemoryCheck = null;
    _averageFps = 60.0;
    _averageMemoryMB = 0.0;
    _frameCount = 0;
    _droppedFrames = 0;
  }
}

/// Device performance profile
class DevicePerformanceProfile {
  final String platform;
  final double performanceScore;
  final bool isLowEnd;
  final int recommendedParticleCount;
  final String recommendedGraphicsQuality;

  DevicePerformanceProfile({
    required this.platform,
    required this.performanceScore,
    required this.isLowEnd,
    required this.recommendedParticleCount,
    required this.recommendedGraphicsQuality,
  });

  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'performanceScore': performanceScore,
      'isLowEnd': isLowEnd,
      'recommendedParticleCount': recommendedParticleCount,
      'recommendedGraphicsQuality': recommendedGraphicsQuality,
    };
  }

  @override
  String toString() {
    return 'DeviceProfile(platform: $platform, score: ${performanceScore.toStringAsFixed(2)}, '
           'lowEnd: $isLowEnd, particles: $recommendedParticleCount, graphics: $recommendedGraphicsQuality)';
  }
}

/// Quality levels for adaptive adjustment
enum QualityLevel {
  low,
  medium,
  high,
  ultra,
}

/// Adaptive quality recommendation
class AdaptiveQualityRecommendation {
  final QualityLevel particleQuality;
  final QualityLevel graphicsQuality;
  final bool shouldReduceEffects;
  final bool memoryPressure;

  AdaptiveQualityRecommendation({
    required this.particleQuality,
    required this.graphicsQuality,
    required this.shouldReduceEffects,
    required this.memoryPressure,
  });

  /// Get particle count for the recommended quality level
  int get recommendedParticleCount {
    switch (particleQuality) {
      case QualityLevel.low:
        return 50;
      case QualityLevel.medium:
        return 150;
      case QualityLevel.high:
        return 300;
      case QualityLevel.ultra:
        return 500;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'particleQuality': particleQuality.name,
      'graphicsQuality': graphicsQuality.name,
      'shouldReduceEffects': shouldReduceEffects,
      'memoryPressure': memoryPressure,
      'recommendedParticleCount': recommendedParticleCount,
    };
  }
}