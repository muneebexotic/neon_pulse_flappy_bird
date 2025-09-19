import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'dart:math' as math;
import '../models/achievement.dart';
import '../models/progression_path_models.dart';

/// Custom scroll controller for the progression path with auto-scroll and smooth navigation
class ProgressionScrollController extends ScrollController {
  final Duration _autoScrollDuration;
  final Curve _autoScrollCurve;
  final double _momentumThreshold;
  final double _boundarySpringStrength;
  
  // Current progress tracking
  double _currentProgressPosition = 0.0;
  bool _isAutoScrolling = false;
  
  // Callbacks for scroll events
  VoidCallback? _onScrollStart;
  VoidCallback? _onScrollEnd;
  ValueChanged<double>? _onProgressChanged;

  ProgressionScrollController({
    Duration autoScrollDuration = const Duration(milliseconds: 800),
    Curve autoScrollCurve = Curves.easeInOutCubic,
    double momentumThreshold = 50.0,
    double boundarySpringStrength = 0.8,
  }) : _autoScrollDuration = autoScrollDuration,
       _autoScrollCurve = autoScrollCurve,
       _momentumThreshold = momentumThreshold,
       _boundarySpringStrength = boundarySpringStrength,
       super();

  /// Set callback for scroll start events
  void setOnScrollStart(VoidCallback? callback) {
    _onScrollStart = callback;
  }

  /// Set callback for scroll end events
  void setOnScrollEnd(VoidCallback? callback) {
    _onScrollEnd = callback;
  }

  /// Set callback for progress position changes
  void setOnProgressChanged(ValueChanged<double>? callback) {
    _onProgressChanged = callback;
  }

  /// Get current progress position (0.0 to 1.0)
  double get currentProgressPosition => _currentProgressPosition;

  /// Check if currently auto-scrolling
  bool get isAutoScrolling => _isAutoScrolling;

  /// Auto-scroll to the current player progress position
  Future<void> animateToCurrentProgress({
    required List<Achievement> achievements,
    required Map<String, NodePosition> nodePositions,
    required Size screenSize,
  }) async {
    if (!hasClients) return;

    final targetPosition = _calculateCurrentProgressScrollPosition(
      achievements,
      nodePositions,
      screenSize,
    );

    await animateToPosition(targetPosition);
  }

  /// Animate to a specific scroll position with smooth easing
  Future<void> animateToPosition(double targetPosition) async {
    if (!hasClients) return;

    _isAutoScrolling = true;
    _onScrollStart?.call();

    try {
      await animateTo(
        targetPosition.clamp(position.minScrollExtent, position.maxScrollExtent),
        duration: _autoScrollDuration,
        curve: _autoScrollCurve,
      );
    } finally {
      _isAutoScrolling = false;
      _onScrollEnd?.call();
    }
  }

  /// Animate to a specific achievement node
  Future<void> animateToAchievement({
    required String achievementId,
    required Map<String, NodePosition> nodePositions,
    required Size screenSize,
  }) async {
    final nodePosition = nodePositions[achievementId];
    if (nodePosition == null) return;

    final scrollPosition = _calculateScrollPositionForNode(
      nodePosition,
      screenSize,
    );

    await animateToPosition(scrollPosition);
  }

  /// Calculate the scroll position for the current player progress
  double _calculateCurrentProgressScrollPosition(
    List<Achievement> achievements,
    Map<String, NodePosition> nodePositions,
    Size screenSize,
  ) {
    // Find the furthest unlocked achievement or first locked achievement
    Achievement? targetAchievement;
    double maxProgress = -1.0;

    for (final achievement in achievements) {
      final nodePosition = nodePositions[achievement.id];
      if (nodePosition == null) continue;

      if (achievement.isUnlocked) {
        // Track furthest unlocked achievement
        if (nodePosition.pathProgress > maxProgress) {
          maxProgress = nodePosition.pathProgress;
          targetAchievement = achievement;
        }
      } else if (targetAchievement == null || !targetAchievement.isUnlocked) {
        // If no unlocked achievements found, target first locked one
        if (nodePosition.pathProgress < maxProgress || maxProgress < 0) {
          maxProgress = nodePosition.pathProgress;
          targetAchievement = achievement;
        }
      }
    }

    if (targetAchievement == null) return 0.0;

    final nodePosition = nodePositions[targetAchievement.id];
    if (nodePosition == null) return 0.0;

    return _calculateScrollPositionForNode(nodePosition, screenSize);
  }

  /// Calculate scroll position to center a node on screen
  double _calculateScrollPositionForNode(
    NodePosition nodePosition,
    Size screenSize,
  ) {
    // Center the node vertically on screen
    final targetY = nodePosition.position.y - (screenSize.height / 2);
    return math.max(0.0, targetY);
  }

  /// Handle momentum scrolling with custom physics
  @override
  ScrollPhysics get physics => CustomScrollPhysics(
    momentumThreshold: _momentumThreshold,
    boundarySpringStrength: _boundarySpringStrength,
  );

  /// Update current progress position based on scroll offset
  void _updateProgressPosition(double scrollOffset, double maxScrollExtent) {
    if (maxScrollExtent <= 0) {
      _currentProgressPosition = 0.0;
    } else {
      _currentProgressPosition = (scrollOffset / maxScrollExtent).clamp(0.0, 1.0);
    }
    _onProgressChanged?.call(_currentProgressPosition);
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    position.addListener(_handleScrollUpdate);
  }

  @override
  void detach(ScrollPosition position) {
    position.removeListener(_handleScrollUpdate);
    super.detach(position);
  }

  /// Handle scroll position updates
  void _handleScrollUpdate() {
    if (hasClients) {
      _updateProgressPosition(offset, position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _onScrollStart = null;
    _onScrollEnd = null;
    _onProgressChanged = null;
    super.dispose();
  }
}

/// Custom scroll physics for enhanced momentum and boundary handling
class CustomScrollPhysics extends ScrollPhysics {
  final double momentumThreshold;
  final double boundarySpringStrength;

  const CustomScrollPhysics({
    super.parent,
    required this.momentumThreshold,
    required this.boundarySpringStrength,
  });

  @override
  CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomScrollPhysics(
      parent: buildParent(ancestor),
      momentumThreshold: momentumThreshold,
      boundarySpringStrength: boundarySpringStrength,
    );
  }

  @override
  SpringDescription get spring => SpringDescription(
    mass: 0.5,
    stiffness: 100.0,
    damping: 0.8,
  );

  @override
  double get minFlingVelocity => momentumThreshold;

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    
    if (velocity.abs() < tolerance.velocity || 
        (velocity > 0.0 && position.pixels >= position.maxScrollExtent) ||
        (velocity < 0.0 && position.pixels <= position.minScrollExtent)) {
      return null;
    }

    // Enhanced momentum simulation
    if (position.outOfRange) {
      double end;
      if (position.pixels > position.maxScrollExtent) {
        end = position.maxScrollExtent;
      } else {
        end = position.minScrollExtent;
      }

      return ScrollSpringSimulation(
        spring,
        position.pixels,
        end,
        velocity,
        tolerance: tolerance,
      );
    }

    // Custom friction simulation for smooth deceleration
    return FrictionSimulation(
      0.135, // Friction coefficient for smooth scrolling
      position.pixels,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value < position.pixels && 
        position.pixels <= position.minScrollExtent) {
      // Underscroll
      return value - position.pixels;
    }
    if (position.maxScrollExtent <= position.pixels && 
        position.pixels < value) {
      // Overscroll
      return value - position.pixels;
    }
    if (value < position.minScrollExtent && 
        position.minScrollExtent < position.pixels) {
      // Hit top boundary
      return value - position.minScrollExtent;
    }
    if (position.pixels < position.maxScrollExtent && 
        position.maxScrollExtent < value) {
      // Hit bottom boundary
      return value - position.maxScrollExtent;
    }
    return 0.0;
  }
}