import 'dart:async';
import '../utils/performance_monitor.dart';
import '../utils/object_pool.dart';
import 'settings_manager.dart';

/// Manages adaptive quality adjustments based on performance
class AdaptiveQualityManager {
  static final AdaptiveQualityManager _instance = AdaptiveQualityManager._internal();
  factory AdaptiveQualityManager() => _instance;
  AdaptiveQualityManager._internal();

  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final PoolManager _poolManager = PoolManager();
  final SettingsManager _settingsManager = SettingsManager();
  
  Timer? _adjustmentTimer;
  bool _isEnabled = false;
  bool _isInitialized = false;
  
  // Quality adjustment settings
  static const Duration _adjustmentInterval = Duration(seconds: 2);
  static const double _performanceThreshold = 0.6;
  static const double _recoveryThreshold = 0.8;
  
  // Current quality state
  QualityLevel _currentParticleQuality = QualityLevel.high;
  QualityLevel _currentGraphicsQuality = QualityLevel.high;
  bool _effectsReduced = false;
  
  // Quality change callbacks
  final List<Function(QualityLevel)> _particleQualityCallbacks = [];
  final List<Function(QualityLevel)> _graphicsQualityCallbacks = [];
  final List<Function(bool)> _effectsCallbacks = [];
  
  // Performance history for stability
  final List<double> _recentPerformance = [];
  static const int _performanceHistorySize = 5;

  /// Initialize the adaptive quality manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _performanceMonitor.initialize();
    _poolManager.initialize();
    
    // Set initial quality based on device profile
    final deviceProfile = _performanceMonitor.deviceProfile;
    if (deviceProfile != null) {
      _setInitialQuality(deviceProfile);
    }
    
    _isInitialized = true;
  }

  /// Start adaptive quality monitoring
  void startAdaptiveQuality() {
    if (!_isInitialized || _isEnabled) return;

    _isEnabled = true;
    _adjustmentTimer = Timer.periodic(_adjustmentInterval, (_) => _performQualityAdjustment());
  }

  /// Stop adaptive quality monitoring
  void stopAdaptiveQuality() {
    _isEnabled = false;
    _adjustmentTimer?.cancel();
    _adjustmentTimer = null;
  }

  /// Set initial quality based on device profile
  void _setInitialQuality(DevicePerformanceProfile profile) {
    if (profile.isLowEnd) {
      _currentParticleQuality = QualityLevel.low;
      _currentGraphicsQuality = QualityLevel.low;
      _effectsReduced = true;
    } else if (profile.performanceScore < 0.7) {
      _currentParticleQuality = QualityLevel.medium;
      _currentGraphicsQuality = QualityLevel.medium;
      _effectsReduced = false;
    } else {
      _currentParticleQuality = QualityLevel.high;
      _currentGraphicsQuality = QualityLevel.high;
      _effectsReduced = false;
    }
    
    _notifyQualityChanges();
  }

  /// Perform quality adjustment based on current performance
  void _performQualityAdjustment() {
    if (!_isEnabled) return;

    final currentPerformance = _performanceMonitor.performanceQuality;
    _recentPerformance.add(currentPerformance);
    
    if (_recentPerformance.length > _performanceHistorySize) {
      _recentPerformance.removeAt(0);
    }
    
    // Only adjust if we have enough history for stability
    if (_recentPerformance.length < 3) return;
    
    final averagePerformance = _recentPerformance.reduce((a, b) => a + b) / _recentPerformance.length;
    final isPerformancePoor = averagePerformance < _performanceThreshold;
    final isPerformanceGood = averagePerformance > _recoveryThreshold;
    final memoryPressure = _poolManager.isUnderMemoryPressure;
    
    bool qualityChanged = false;
    
    // Adjust particle quality
    if (isPerformancePoor || memoryPressure) {
      final newParticleQuality = _reduceQuality(_currentParticleQuality);
      if (newParticleQuality != _currentParticleQuality) {
        _currentParticleQuality = newParticleQuality;
        qualityChanged = true;
      }
    } else if (isPerformanceGood && !memoryPressure) {
      final newParticleQuality = _increaseQuality(_currentParticleQuality);
      if (newParticleQuality != _currentParticleQuality) {
        _currentParticleQuality = newParticleQuality;
        qualityChanged = true;
      }
    }
    
    // Adjust graphics quality (more conservative)
    if (averagePerformance < _performanceThreshold - 0.1) {
      final newGraphicsQuality = _reduceQuality(_currentGraphicsQuality);
      if (newGraphicsQuality != _currentGraphicsQuality) {
        _currentGraphicsQuality = newGraphicsQuality;
        qualityChanged = true;
      }
    } else if (averagePerformance > _recoveryThreshold + 0.1) {
      final newGraphicsQuality = _increaseQuality(_currentGraphicsQuality);
      if (newGraphicsQuality != _currentGraphicsQuality) {
        _currentGraphicsQuality = newGraphicsQuality;
        qualityChanged = true;
      }
    }
    
    // Adjust effects
    final shouldReduceEffects = averagePerformance < _performanceThreshold - 0.2 || memoryPressure;
    if (shouldReduceEffects != _effectsReduced) {
      _effectsReduced = shouldReduceEffects;
      qualityChanged = true;
    }
    
    if (qualityChanged) {
      _notifyQualityChanges();
    }
  }

  /// Reduce quality level
  QualityLevel _reduceQuality(QualityLevel current) {
    switch (current) {
      case QualityLevel.ultra:
        return QualityLevel.high;
      case QualityLevel.high:
        return QualityLevel.medium;
      case QualityLevel.medium:
        return QualityLevel.low;
      case QualityLevel.low:
        return QualityLevel.low; // Can't go lower
    }
  }

  /// Increase quality level
  QualityLevel _increaseQuality(QualityLevel current) {
    switch (current) {
      case QualityLevel.low:
        return QualityLevel.medium;
      case QualityLevel.medium:
        return QualityLevel.high;
      case QualityLevel.high:
        return QualityLevel.ultra;
      case QualityLevel.ultra:
        return QualityLevel.ultra; // Can't go higher
    }
  }

  /// Notify all callbacks about quality changes
  void _notifyQualityChanges() {
    for (final callback in _particleQualityCallbacks) {
      callback(_currentParticleQuality);
    }
    
    for (final callback in _graphicsQualityCallbacks) {
      callback(_currentGraphicsQuality);
    }
    
    for (final callback in _effectsCallbacks) {
      callback(_effectsReduced);
    }
  }

  /// Register callback for particle quality changes
  void onParticleQualityChanged(Function(QualityLevel) callback) {
    _particleQualityCallbacks.add(callback);
  }

  /// Register callback for graphics quality changes
  void onGraphicsQualityChanged(Function(QualityLevel) callback) {
    _graphicsQualityCallbacks.add(callback);
  }

  /// Register callback for effects changes
  void onEffectsChanged(Function(bool) callback) {
    _effectsCallbacks.add(callback);
  }

  /// Get current particle quality
  QualityLevel get currentParticleQuality => _currentParticleQuality;

  /// Get current graphics quality
  QualityLevel get currentGraphicsQuality => _currentGraphicsQuality;

  /// Check if effects are reduced
  bool get areEffectsReduced => _effectsReduced;

  /// Get particle count for current quality
  int get currentParticleCount {
    switch (_currentParticleQuality) {
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

  /// Force quality adjustment (for testing or manual override)
  void forceQualityAdjustment({
    QualityLevel? particleQuality,
    QualityLevel? graphicsQuality,
    bool? reduceEffects,
  }) {
    bool changed = false;
    
    if (particleQuality != null && particleQuality != _currentParticleQuality) {
      _currentParticleQuality = particleQuality;
      changed = true;
    }
    
    if (graphicsQuality != null && graphicsQuality != _currentGraphicsQuality) {
      _currentGraphicsQuality = graphicsQuality;
      changed = true;
    }
    
    if (reduceEffects != null && reduceEffects != _effectsReduced) {
      _effectsReduced = reduceEffects;
      changed = true;
    }
    
    if (changed) {
      _notifyQualityChanges();
    }
  }

  /// Get current quality statistics
  Map<String, dynamic> getQualityStats() {
    return {
      'particleQuality': _currentParticleQuality.name,
      'graphicsQuality': _currentGraphicsQuality.name,
      'effectsReduced': _effectsReduced,
      'currentParticleCount': currentParticleCount,
      'isEnabled': _isEnabled,
      'recentPerformance': _recentPerformance.isNotEmpty 
          ? (_recentPerformance.reduce((a, b) => a + b) / _recentPerformance.length).toStringAsFixed(2)
          : '0.00',
      'memoryPressure': _poolManager.isUnderMemoryPressure,
    };
  }

  /// Get performance recommendation for manual settings
  Map<String, dynamic> getPerformanceRecommendation() {
    final recommendation = _performanceMonitor.getAdaptiveQualityRecommendation();
    
    return {
      'recommendedParticleQuality': recommendation.particleQuality.name,
      'recommendedGraphicsQuality': recommendation.graphicsQuality.name,
      'shouldReduceEffects': recommendation.shouldReduceEffects,
      'memoryPressure': recommendation.memoryPressure,
      'recommendedParticleCount': recommendation.recommendedParticleCount,
      'deviceProfile': _performanceMonitor.deviceProfile?.toMap(),
    };
  }

  /// Dispose of resources
  void dispose() {
    stopAdaptiveQuality();
    _particleQualityCallbacks.clear();
    _graphicsQualityCallbacks.clear();
    _effectsCallbacks.clear();
    _recentPerformance.clear();
  }
}