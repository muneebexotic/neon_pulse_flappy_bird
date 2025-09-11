import 'dart:collection';

/// Simple performance monitoring utility
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Queue<double> _frameTimes = Queue<double>();
  DateTime? _lastFrameTime;
  double _averageFps = 60.0;
  int _frameCount = 0;
  
  static const int _maxSamples = 60; // Keep last 60 frame times
  static const double _targetFps = 60.0;

  /// Record a frame update
  void recordFrame() {
    final now = DateTime.now();
    
    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!).inMicroseconds / 1000000.0;
      
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
    }
    
    _lastFrameTime = now;
    _frameCount++;
  }

  /// Get current average FPS
  double get averageFps => _averageFps;

  /// Get current frame time in milliseconds
  double get currentFrameTimeMs => _frameTimes.isNotEmpty ? _frameTimes.last * 1000 : 16.67;

  /// Check if performance is good
  bool get isPerformanceGood => _averageFps >= _targetFps * 0.8; // 80% of target

  /// Get performance quality (0.0 to 1.0)
  double get performanceQuality => (_averageFps / _targetFps).clamp(0.0, 1.0);

  /// Get performance statistics
  Map<String, dynamic> getStats() {
    return {
      'averageFps': _averageFps.toStringAsFixed(1),
      'frameTimeMs': currentFrameTimeMs.toStringAsFixed(2),
      'frameCount': _frameCount,
      'performanceGood': isPerformanceGood,
      'quality': performanceQuality.toStringAsFixed(2),
    };
  }

  /// Reset statistics
  void reset() {
    _frameTimes.clear();
    _lastFrameTime = null;
    _averageFps = 60.0;
    _frameCount = 0;
  }
}