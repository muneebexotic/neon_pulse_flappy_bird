import 'package:flutter/material.dart';
import 'dart:async';
import '../models/achievement.dart';
import '../models/progression_path_models.dart';
import 'progression_scroll_controller.dart';
import 'scan_line_animation_controller.dart';

/// Coordinates smooth scrolling and navigation for the progression path
class ProgressionNavigationSystem extends ChangeNotifier {
  final ProgressionScrollController _scrollController;
  final ScanLineAnimationController _scanLineController;
  
  // Navigation state
  bool _isInitialized = false;
  bool _isNavigating = false;
  String? _targetAchievementId;
  
  // Screen and layout data
  Size? _screenSize;
  Map<String, NodePosition> _nodePositions = {};
  List<Achievement> _achievements = [];
  
  // Auto-scroll configuration
  final Duration _initialRevealDelay;
  final bool _enableAutoScrollOnLoad;
  
  // Callbacks
  VoidCallback? _onNavigationStart;
  VoidCallback? _onNavigationComplete;
  ValueChanged<String?>? _onTargetAchievementChanged;

  ProgressionNavigationSystem({
    ProgressionScrollController? scrollController,
    ScanLineAnimationController? scanLineController,
    Duration initialRevealDelay = const Duration(milliseconds: 500),
    bool enableAutoScrollOnLoad = true,
  }) : _scrollController = scrollController ?? ProgressionScrollController(),
       _scanLineController = scanLineController ?? ScanLineAnimationController(),
       _initialRevealDelay = initialRevealDelay,
       _enableAutoScrollOnLoad = enableAutoScrollOnLoad {
    
    // Set up scroll controller callbacks
    _scrollController.setOnScrollStart(_handleScrollStart);
    _scrollController.setOnScrollEnd(_handleScrollEnd);
    _scrollController.setOnProgressChanged(_handleProgressChanged);
  }

  /// Initialize the navigation system
  Future<void> initialize({
    required TickerProvider tickerProvider,
    required Size screenSize,
    required List<Achievement> achievements,
    required Map<String, NodePosition> nodePositions,
  }) async {
    if (_isInitialized) return;

    _screenSize = screenSize;
    _achievements = achievements;
    _nodePositions = nodePositions;

    // Initialize scan line controller
    _scanLineController.initialize(tickerProvider);

    _isInitialized = true;
    notifyListeners();
  }

  /// Start the initial reveal animation and auto-scroll sequence
  Future<void> startInitialRevealSequence() async {
    if (!_isInitialized) return;

    try {
      // Start scan line reveal animation
      await _scanLineController.startRevealAnimation();
      
      // Wait for reveal delay
      await Future.delayed(_initialRevealDelay);
      
      // Auto-scroll to current progress if enabled
      if (_enableAutoScrollOnLoad) {
        await scrollToCurrentProgress();
      }
    } catch (e) {
      // Handle any animation errors gracefully
      debugPrint('Error during initial reveal sequence: $e');
    }
  }

  /// Scroll to the current player progress position
  Future<void> scrollToCurrentProgress() async {
    if (!_isInitialized || _screenSize == null) return;

    await _scrollController.animateToCurrentProgress(
      achievements: _achievements,
      nodePositions: _nodePositions,
      screenSize: _screenSize!,
    );
  }

  /// Navigate to a specific achievement
  Future<void> navigateToAchievement(String achievementId) async {
    if (!_isInitialized || _screenSize == null || _isNavigating) return;

    _targetAchievementId = achievementId;
    _onTargetAchievementChanged?.call(achievementId);
    notifyListeners();

    await _scrollController.animateToAchievement(
      achievementId: achievementId,
      nodePositions: _nodePositions,
      screenSize: _screenSize!,
    );
  }

  /// Scroll to a specific position with smooth animation
  Future<void> scrollToPosition(double position) async {
    if (!_isInitialized) return;

    await _scrollController.animateToPosition(position);
  }

  /// Update the achievement data and node positions
  void updateData({
    List<Achievement>? achievements,
    Map<String, NodePosition>? nodePositions,
    Size? screenSize,
  }) {
    bool hasChanges = false;

    if (achievements != null && achievements != _achievements) {
      _achievements = achievements;
      hasChanges = true;
    }

    if (nodePositions != null && nodePositions != _nodePositions) {
      _nodePositions = nodePositions;
      hasChanges = true;
    }

    if (screenSize != null && screenSize != _screenSize) {
      _screenSize = screenSize;
      hasChanges = true;
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  /// Reset the navigation system to initial state
  void reset() {
    _scanLineController.reset();
    _targetAchievementId = null;
    _isNavigating = false;
    notifyListeners();
  }

  /// Handle scroll start events
  void _handleScrollStart() {
    if (!_scrollController.isAutoScrolling) {
      // User initiated scroll - stop any ongoing animations
      _scanLineController.stop();
    }
    
    _isNavigating = true;
    _onNavigationStart?.call();
    notifyListeners();
  }

  /// Handle scroll end events
  void _handleScrollEnd() {
    _isNavigating = false;
    _targetAchievementId = null;
    _onNavigationComplete?.call();
    _onTargetAchievementChanged?.call(null);
    notifyListeners();
  }

  /// Handle progress position changes
  void _handleProgressChanged(double progress) {
    // Update any progress-dependent UI elements
    notifyListeners();
  }

  /// Set callback for navigation start events
  void setOnNavigationStart(VoidCallback? callback) {
    _onNavigationStart = callback;
  }

  /// Set callback for navigation complete events
  void setOnNavigationComplete(VoidCallback? callback) {
    _onNavigationComplete = callback;
  }

  /// Set callback for target achievement changes
  void setOnTargetAchievementChanged(ValueChanged<String?>? callback) {
    _onTargetAchievementChanged = callback;
  }

  /// Get the scroll controller
  ProgressionScrollController get scrollController => _scrollController;

  /// Get the scan line animation controller
  ScanLineAnimationController get scanLineController => _scanLineController;

  /// Check if the system is initialized
  bool get isInitialized => _isInitialized;

  /// Check if currently navigating
  bool get isNavigating => _isNavigating;

  /// Get the current target achievement ID
  String? get targetAchievementId => _targetAchievementId;

  /// Get current scroll progress (0.0 to 1.0)
  double get scrollProgress => _scrollController.currentProgressPosition;

  /// Check if scan line animation is active
  bool get isScanLineAnimating => _scanLineController.isAnimating;

  /// Get scan line reveal progress
  double get scanLineRevealProgress => _scanLineController.revealProgress;

  /// Check if a point should be revealed by scan line
  bool shouldRevealPoint(double y) {
    if (_screenSize == null) return true;
    return _scanLineController.shouldRevealPoint(y, _screenSize!.height);
  }

  /// Get reveal opacity for a point
  double getRevealOpacity(double y) {
    if (_screenSize == null) return 1.0;
    return _scanLineController.getRevealOpacity(y, _screenSize!.height);
  }

  /// Get scan line glow effect for a point
  double getScanLineGlow(double y) {
    if (_screenSize == null) return 0.0;
    return _scanLineController.getScanLineGlow(y, _screenSize!.height);
  }

  /// Create scan line painter for custom painting
  CustomPainter? createScanLinePainter() {
    if (_screenSize == null) return null;
    return _scanLineController.createScanLinePainter(_screenSize!);
  }

  /// Find the closest achievement to current scroll position
  String? findClosestAchievement() {
    if (_nodePositions.isEmpty || _screenSize == null) return null;

    final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final screenCenter = scrollOffset + (_screenSize!.height / 2);

    String? closestId;
    double closestDistance = double.infinity;

    for (final entry in _nodePositions.entries) {
      final distance = (entry.value.position.y - screenCenter).abs();
      if (distance < closestDistance) {
        closestDistance = distance;
        closestId = entry.key;
      }
    }

    return closestId;
  }

  /// Get visible achievements in current viewport
  List<String> getVisibleAchievements() {
    if (_nodePositions.isEmpty || _screenSize == null || !_scrollController.hasClients) {
      return [];
    }

    final scrollOffset = _scrollController.offset;
    final viewportTop = scrollOffset;
    final viewportBottom = scrollOffset + _screenSize!.height;

    return _nodePositions.entries
        .where((entry) {
          final y = entry.value.position.y;
          return y >= viewportTop && y <= viewportBottom;
        })
        .map((entry) => entry.key)
        .toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scanLineController.dispose();
    _onNavigationStart = null;
    _onNavigationComplete = null;
    _onTargetAchievementChanged = null;
    super.dispose();
  }
}