import 'dart:async' as async;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../game/managers/adaptive_quality_manager.dart';
import '../game/utils/performance_monitor.dart';
import '../game/utils/object_pool.dart';
import '../models/progression_path_models.dart';
import '../ui/effects/progression_particle_system.dart';
import '../ui/painters/path_renderer.dart';

/// Performance optimization controller for the progression path system
class ProgressionPerformanceController {
  static final ProgressionPerformanceController _instance = 
      ProgressionPerformanceController._internal();
  factory ProgressionPerformanceController() => _instance;
  ProgressionPerformanceController._internal();

  // Core performance managers
  final AdaptiveQualityManager _qualityManager = AdaptiveQualityManager();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final PoolManager _poolManager = PoolManager();

  // Progression-specific performance state
  bool _isInitialized = false;
  bool _isOptimizationEnabled = true;
  async.Timer? _optimizationTimer;
  
  // Viewport culling
  Rect _currentViewport = Rect.zero;
  final Set<String> _visibleSegments = <String>{};
  final Set<String> _visibleNodes = <String>{};
  
  // Quality adjustment callbacks
  final List<Function(QualityLevel)> _particleQualityCallbacks = [];
  final List<Function(QualityLevel)> _graphicsQualityCallbacks = [];
  final List<Function(bool)> _effectsCallbacks = [];
  final List<Function(double)> _qualityScaleCallbacks = [];
  
  // Performance metrics
  int _frameCount = 0;
  double _averageFrameTime = 16.67; // Target 60fps
  final List<double> _recentFrameTimes = [];
  static const int _maxFrameTimeHistory = 60; // 1 second at 60fps
  
  // Optimization settings
  static const Duration _optimizationInterval = Duration(milliseconds: 500);
  static const double _targetFrameTime = 16.67; // 60fps
  static const double _performanceThreshold = 0.7;
  
  // Current optimization state
  QualityLevel _currentParticleQuality = QualityLevel.high;
  QualityLevel _currentGraphicsQuality = QualityLevel.high;
  double _currentQualityScale = 1.0;
  bool _viewportCullingEnabled = true;
  bool _particlePoolingEnabled = true;
  bool _effectsReduced = false;

  /// Initialize the performance controller
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize core performance systems
    await _qualityManager.initialize();
    await _performanceMonitor.initialize();
    _poolManager.initialize();

    // Set up quality change listeners
    _qualityManager.onParticleQualityChanged(_onParticleQualityChanged);
    _qualityManager.onGraphicsQualityChanged(_onGraphicsQualityChanged);
    _qualityManager.onEffectsChanged(_onEffectsChanged);

    // Start adaptive quality monitoring
    _qualityManager.startAdaptiveQuality();

    _isInitialized = true;
  }

  /// Start performance optimization monitoring
  void startOptimization() {
    if (!_isInitialized || !_isOptimizationEnabled) return;

    _optimizationTimer = async.Timer.periodic(_optimizationInterval, (_) {
      _performOptimizationCycle();
    });
  }

  /// Stop performance optimization monitoring
  void stopOptimization() {
    _optimizationTimer?.cancel();
    _optimizationTimer = null;
  }

  /// Record frame performance data
  void recordFrame(double frameTime) {
    _frameCount++;
    _performanceMonitor.recordFrame();
    
    _recentFrameTimes.add(frameTime);
    if (_recentFrameTimes.length > _maxFrameTimeHistory) {
      _recentFrameTimes.removeAt(0);
    }
    
    if (_recentFrameTimes.isNotEmpty) {
      _averageFrameTime = _recentFrameTimes.reduce((a, b) => a + b) / _recentFrameTimes.length;
    }
  }

  /// Update viewport for culling calculations
  void updateViewport(Rect viewport) {
    _currentViewport = viewport;
    if (_viewportCullingEnabled) {
      _updateVisibilityLists();
    }
  }

  /// Update visibility lists based on current viewport
  void _updateVisibilityLists() {
    _visibleSegments.clear();
    _visibleNodes.clear();
    
    // This will be populated by the path controller when segments/nodes are checked
    // The actual culling logic is implemented in the individual update methods
  }

  /// Check if a path segment is visible in the current viewport
  bool isSegmentVisible(PathSegment segment) {
    if (!_viewportCullingEnabled) return true;
    
    // Check if any part of the segment intersects with the viewport
    for (final point in segment.pathPoints) {
      if (_currentViewport.contains(Offset(point.x, point.y))) {
        _visibleSegments.add(segment.id);
        return true;
      }
    }
    
    // Check if segment bounds intersect with viewport (for segments that cross viewport)
    final segmentBounds = _calculateSegmentBounds(segment);
    final intersects = _currentViewport.overlaps(segmentBounds);
    
    if (intersects) {
      _visibleSegments.add(segment.id);
    }
    
    return intersects;
  }

  /// Check if a node is visible in the current viewport
  bool isNodeVisible(NodePosition node) {
    if (!_viewportCullingEnabled) return true;
    
    // Add buffer around viewport for smooth transitions
    final buffer = 50.0;
    final expandedViewport = _currentViewport.inflate(buffer);
    
    final isVisible = expandedViewport.contains(Offset(node.position.x, node.position.y));
    
    if (isVisible) {
      _visibleNodes.add(node.achievementId);
    }
    
    return isVisible;
  }

  /// Calculate bounding rectangle for a path segment
  Rect _calculateSegmentBounds(PathSegment segment) {
    if (segment.pathPoints.isEmpty) return Rect.zero;
    
    double minX = segment.pathPoints.first.x;
    double maxX = segment.pathPoints.first.x;
    double minY = segment.pathPoints.first.y;
    double maxY = segment.pathPoints.first.y;
    
    for (final point in segment.pathPoints) {
      minX = math.min(minX, point.x);
      maxX = math.max(maxX, point.x);
      minY = math.min(minY, point.y);
      maxY = math.max(maxY, point.y);
    }
    
    // Add path width to bounds
    final halfWidth = segment.width / 2;
    return Rect.fromLTRB(
      minX - halfWidth,
      minY - halfWidth,
      maxX + halfWidth,
      maxY + halfWidth,
    );
  }

  /// Perform optimization cycle
  void _performOptimizationCycle() {
    if (!_isInitialized) return;

    // Check current performance
    final currentPerformance = _calculateCurrentPerformance();
    final memoryPressure = _poolManager.isUnderMemoryPressure;
    
    // Determine if optimization is needed
    final needsOptimization = currentPerformance < _performanceThreshold || memoryPressure;
    final canImproveQuality = currentPerformance > 0.9 && !memoryPressure;
    
    if (needsOptimization) {
      _applyPerformanceOptimizations();
    } else if (canImproveQuality) {
      _improveQualitySettings();
    }
    
    // Update quality scale based on current performance
    _updateQualityScale(currentPerformance);
  }

  /// Calculate current performance score (0.0 to 1.0)
  double _calculateCurrentPerformance() {
    // Combine frame rate performance with memory usage
    final frameRateScore = math.min(1.0, _targetFrameTime / _averageFrameTime);
    final memoryScore = _poolManager.isUnderMemoryPressure ? 0.5 : 1.0;
    final monitorScore = _performanceMonitor.performanceQuality;
    
    return (frameRateScore + memoryScore + monitorScore) / 3.0;
  }

  /// Apply performance optimizations
  void _applyPerformanceOptimizations() {
    // Reduce particle quality
    if (_currentParticleQuality != QualityLevel.low) {
      _currentParticleQuality = _reduceQuality(_currentParticleQuality);
      _notifyParticleQualityChange();
    }
    
    // Reduce graphics quality if performance is very poor
    if (_averageFrameTime > _targetFrameTime * 1.5) {
      if (_currentGraphicsQuality != QualityLevel.low) {
        _currentGraphicsQuality = _reduceQuality(_currentGraphicsQuality);
        _notifyGraphicsQualityChange();
      }
    }
    
    // Enable effects reduction
    if (!_effectsReduced) {
      _effectsReduced = true;
      _notifyEffectsChange();
    }
    
    // Ensure viewport culling is enabled
    if (!_viewportCullingEnabled) {
      _viewportCullingEnabled = true;
    }
  }

  /// Improve quality settings when performance allows
  void _improveQualitySettings() {
    // Only improve if we have good performance for a sustained period
    if (_recentFrameTimes.length < 30) return; // Need enough history
    
    final recentAverage = _recentFrameTimes.skip(_recentFrameTimes.length - 30)
        .reduce((a, b) => a + b) / 30;
    
    if (recentAverage < _targetFrameTime * 0.8) { // Consistently good performance
      // Improve particle quality
      if (_currentParticleQuality != QualityLevel.ultra) {
        _currentParticleQuality = _increaseQuality(_currentParticleQuality);
        _notifyParticleQualityChange();
      }
      
      // Improve graphics quality
      if (_currentGraphicsQuality != QualityLevel.ultra && recentAverage < _targetFrameTime * 0.7) {
        _currentGraphicsQuality = _increaseQuality(_currentGraphicsQuality);
        _notifyGraphicsQualityChange();
      }
      
      // Disable effects reduction
      if (_effectsReduced) {
        _effectsReduced = false;
        _notifyEffectsChange();
      }
    }
  }

  /// Update quality scale based on performance
  void _updateQualityScale(double performance) {
    final newScale = math.max(0.3, math.min(1.0, performance));
    
    if ((newScale - _currentQualityScale).abs() > 0.05) { // Only update if significant change
      _currentQualityScale = newScale;
      _notifyQualityScaleChange();
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
        return QualityLevel.low;
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
        return QualityLevel.ultra;
    }
  }

  /// Handle particle quality changes from adaptive quality manager
  void _onParticleQualityChanged(QualityLevel quality) {
    _currentParticleQuality = quality;
    _notifyParticleQualityChange();
  }

  /// Handle graphics quality changes from adaptive quality manager
  void _onGraphicsQualityChanged(QualityLevel quality) {
    _currentGraphicsQuality = quality;
    _notifyGraphicsQualityChange();
  }

  /// Handle effects changes from adaptive quality manager
  void _onEffectsChanged(bool reduced) {
    _effectsReduced = reduced;
    _notifyEffectsChange();
  }

  /// Notify particle quality change callbacks
  void _notifyParticleQualityChange() {
    for (final callback in _particleQualityCallbacks) {
      callback(_currentParticleQuality);
    }
  }

  /// Notify graphics quality change callbacks
  void _notifyGraphicsQualityChange() {
    for (final callback in _graphicsQualityCallbacks) {
      callback(_currentGraphicsQuality);
    }
  }

  /// Notify effects change callbacks
  void _notifyEffectsChange() {
    for (final callback in _effectsCallbacks) {
      callback(_effectsReduced);
    }
  }

  /// Notify quality scale change callbacks
  void _notifyQualityScaleChange() {
    for (final callback in _qualityScaleCallbacks) {
      callback(_currentQualityScale);
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

  /// Register callback for quality scale changes
  void onQualityScaleChanged(Function(double) callback) {
    _qualityScaleCallbacks.add(callback);
  }

  /// Get optimized particle count for current quality level
  int getOptimizedParticleCount() {
    switch (_currentParticleQuality) {
      case QualityLevel.low:
        return 30;
      case QualityLevel.medium:
        return 80;
      case QualityLevel.high:
        return 150;
      case QualityLevel.ultra:
        return 250;
    }
  }

  /// Get optimized render settings for path renderer
  PathRenderSettings getOptimizedRenderSettings() {
    return PathRenderSettings(
      enableGlowEffects: !_effectsReduced,
      glowIntensity: _currentQualityScale,
      enableAntiAliasing: _currentGraphicsQuality != QualityLevel.low,
      qualityScale: _currentQualityScale,
      enableBatching: _currentParticleQuality == QualityLevel.low,
    );
  }

  /// Force quality adjustment for testing
  void forceQualityAdjustment({
    QualityLevel? particleQuality,
    QualityLevel? graphicsQuality,
    bool? reduceEffects,
    double? qualityScale,
  }) {
    if (particleQuality != null) {
      _currentParticleQuality = particleQuality;
      _notifyParticleQualityChange();
    }
    
    if (graphicsQuality != null) {
      _currentGraphicsQuality = graphicsQuality;
      _notifyGraphicsQualityChange();
    }
    
    if (reduceEffects != null) {
      _effectsReduced = reduceEffects;
      _notifyEffectsChange();
    }
    
    if (qualityScale != null) {
      _currentQualityScale = qualityScale.clamp(0.1, 1.0);
      _notifyQualityScaleChange();
    }
  }

  /// Enable or disable viewport culling
  void setViewportCullingEnabled(bool enabled) {
    _viewportCullingEnabled = enabled;
    if (!enabled) {
      _visibleSegments.clear();
      _visibleNodes.clear();
    }
  }

  /// Enable or disable particle pooling
  void setParticlePoolingEnabled(bool enabled) {
    _particlePoolingEnabled = enabled;
  }

  /// Get comprehensive performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'frameCount': _frameCount,
      'averageFrameTime': _averageFrameTime.toStringAsFixed(2),
      'targetFrameTime': _targetFrameTime,
      'currentFps': (1000 / _averageFrameTime).toStringAsFixed(1),
      'performanceScore': _calculateCurrentPerformance().toStringAsFixed(2),
      'particleQuality': _currentParticleQuality.name,
      'graphicsQuality': _currentGraphicsQuality.name,
      'qualityScale': _currentQualityScale.toStringAsFixed(2),
      'effectsReduced': _effectsReduced,
      'viewportCullingEnabled': _viewportCullingEnabled,
      'particlePoolingEnabled': _particlePoolingEnabled,
      'visibleSegments': _visibleSegments.length,
      'visibleNodes': _visibleNodes.length,
      'memoryPressure': _poolManager.isUnderMemoryPressure,
      'poolStats': _poolManager.getAllStats(),
      'qualityManagerStats': _qualityManager.getQualityStats(),
      'performanceMonitorStats': _performanceMonitor.getStats(),
    };
  }

  /// Get memory usage estimate in KB
  double getMemoryUsageKB() {
    final stats = _poolManager.getAllStats();
    return stats['totalMemoryEstimate'] ?? 0.0;
  }

  /// Clear all performance data
  void clearPerformanceData() {
    _frameCount = 0;
    _recentFrameTimes.clear();
    _averageFrameTime = 16.67;
    _visibleSegments.clear();
    _visibleNodes.clear();
  }

  /// Dispose of resources
  void dispose() {
    stopOptimization();
    _qualityManager.dispose();
    _performanceMonitor.reset();
    _poolManager.clearAll();
    
    _particleQualityCallbacks.clear();
    _graphicsQualityCallbacks.clear();
    _effectsCallbacks.clear();
    _qualityScaleCallbacks.clear();
    
    clearPerformanceData();
  }

  // Getters for current state
  QualityLevel get currentParticleQuality => _currentParticleQuality;
  QualityLevel get currentGraphicsQuality => _currentGraphicsQuality;
  double get currentQualityScale => _currentQualityScale;
  bool get areEffectsReduced => _effectsReduced;
  bool get isViewportCullingEnabled => _viewportCullingEnabled;
  bool get isParticlePoolingEnabled => _particlePoolingEnabled;
  Set<String> get visibleSegments => Set.unmodifiable(_visibleSegments);
  Set<String> get visibleNodes => Set.unmodifiable(_visibleNodes);
}

/// Settings for optimized path rendering
class PathRenderSettings {
  final bool enableGlowEffects;
  final double glowIntensity;
  final bool enableAntiAliasing;
  final double qualityScale;
  final bool enableBatching;

  const PathRenderSettings({
    required this.enableGlowEffects,
    required this.glowIntensity,
    required this.enableAntiAliasing,
    required this.qualityScale,
    required this.enableBatching,
  });
}