import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'achievement.dart';

/// Helper function to interpolate between two Vector2 points
Vector2 _lerpVector2(Vector2 a, Vector2 b, double t) {
  return Vector2(
    a.x + (b.x - a.x) * t,
    a.y + (b.y - a.y) * t,
  );
}

/// Represents a segment of the progression path
class PathSegment {
  final String id;
  final AchievementType category;
  final List<Vector2> pathPoints;
  final Color neonColor;
  final double width;
  final bool isMainPath;
  final double completionPercentage;
  final List<String> achievementIds;

  const PathSegment({
    required this.id,
    required this.category,
    required this.pathPoints,
    required this.neonColor,
    required this.width,
    required this.isMainPath,
    required this.completionPercentage,
    required this.achievementIds,
  });

  /// Create a copy with updated completion percentage
  PathSegment copyWith({
    double? completionPercentage,
    List<Vector2>? pathPoints,
  }) {
    return PathSegment(
      id: id,
      category: category,
      pathPoints: pathPoints ?? this.pathPoints,
      neonColor: neonColor,
      width: width,
      isMainPath: isMainPath,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      achievementIds: achievementIds,
    );
  }

  /// Get the length of the path segment
  double get pathLength {
    if (pathPoints.length < 2) return 0.0;
    
    double length = 0.0;
    for (int i = 1; i < pathPoints.length; i++) {
      length += pathPoints[i].distanceTo(pathPoints[i - 1]);
    }
    return length;
  }

  /// Get a point along the path at the given percentage (0.0 to 1.0)
  Vector2 getPointAtPercentage(double percentage) {
    if (pathPoints.isEmpty) return Vector2.zero();
    if (pathPoints.length == 1) return pathPoints.first.clone();
    
    percentage = percentage.clamp(0.0, 1.0);
    final targetDistance = pathLength * percentage;
    
    double currentDistance = 0.0;
    for (int i = 1; i < pathPoints.length; i++) {
      final segmentLength = pathPoints[i].distanceTo(pathPoints[i - 1]);
      
      if (currentDistance + segmentLength >= targetDistance) {
        // Point is within this segment
        final segmentPercentage = (targetDistance - currentDistance) / segmentLength;
        return _lerpVector2(pathPoints[i - 1], pathPoints[i], segmentPercentage);
      }
      
      currentDistance += segmentLength;
    }
    
    return pathPoints.last.clone();
  }
}

/// Visual state of an achievement node
enum NodeVisualState {
  locked,
  inProgress,
  unlocked,
  rewardAvailable,
}

/// Configuration for path layout calculations
class PathLayoutConfig {
  final bool isHorizontalLayout;
  final double pathSpacing;
  final double nodeSize;
  final double branchAngle;
  final EdgeInsets screenPadding;
  final double minNodeSpacing;
  final double maxPathWidth;
  final double branchOffset;

  const PathLayoutConfig({
    required this.isHorizontalLayout,
    required this.pathSpacing,
    required this.nodeSize,
    required this.branchAngle,
    required this.screenPadding,
    this.minNodeSpacing = 80.0,
    this.maxPathWidth = 400.0,
    this.branchOffset = 60.0,
  });

  /// Create a responsive layout config based on screen size
  factory PathLayoutConfig.responsive(Size screenSize) {
    final isWide = screenSize.width > screenSize.height * 1.2;
    final scaleFactor = math.min(screenSize.width, screenSize.height) / 400.0;
    
    return PathLayoutConfig(
      isHorizontalLayout: isWide,
      pathSpacing: 120.0 * scaleFactor,
      nodeSize: 44.0 * scaleFactor, // Minimum touch target size
      branchAngle: isWide ? math.pi / 6 : math.pi / 4, // 30° or 45°
      screenPadding: EdgeInsets.all(20.0 * scaleFactor),
      minNodeSpacing: 80.0 * scaleFactor,
      maxPathWidth: math.min(400.0 * scaleFactor, screenSize.width * 0.8),
      branchOffset: 60.0 * scaleFactor,
    );
  }

  /// Get the effective screen size after padding
  Size getEffectiveScreenSize(Size screenSize) {
    return Size(
      screenSize.width - screenPadding.horizontal,
      screenSize.height - screenPadding.vertical,
    );
  }
}

/// Configuration for a specific branch type
class BranchConfig {
  final AchievementType type;
  final Color neonColor;
  final double width;
  final double angle;
  final double length;
  final int priority; // Lower numbers have higher priority

  const BranchConfig({
    required this.type,
    required this.neonColor,
    required this.width,
    required this.angle,
    required this.length,
    required this.priority,
  });
}

/// Logic for calculating branching paths
class BranchingLogic {
  final Map<AchievementType, BranchConfig> branchConfigs;
  
  const BranchingLogic({required this.branchConfigs});

  /// Get default branching logic with cyberpunk neon colors
  factory BranchingLogic.defaultConfig() {
    return BranchingLogic(
      branchConfigs: {
        AchievementType.score: const BranchConfig(
          type: AchievementType.score,
          neonColor: Color(0xFFFF1493), // Hot pink - main path
          width: 8.0,
          angle: 0.0, // Straight path
          length: 100.0,
          priority: 0,
        ),
        AchievementType.totalScore: const BranchConfig(
          type: AchievementType.totalScore,
          neonColor: Color(0xFF9932CC), // Purple
          width: 6.0,
          angle: math.pi / 6, // 30 degrees
          length: 80.0,
          priority: 1,
        ),
        AchievementType.gamesPlayed: const BranchConfig(
          type: AchievementType.gamesPlayed,
          neonColor: Color(0xFF00FFFF), // Cyan
          width: 5.0,
          angle: -math.pi / 6, // -30 degrees
          length: 70.0,
          priority: 2,
        ),
        AchievementType.pulseUsage: const BranchConfig(
          type: AchievementType.pulseUsage,
          neonColor: Color(0xFFFFFF00), // Yellow
          width: 5.0,
          angle: math.pi / 4, // 45 degrees
          length: 75.0,
          priority: 3,
        ),
        AchievementType.powerUps: const BranchConfig(
          type: AchievementType.powerUps,
          neonColor: Color(0xFF00FF00), // Green
          width: 5.0,
          angle: -math.pi / 4, // -45 degrees
          length: 65.0,
          priority: 4,
        ),
        AchievementType.survival: const BranchConfig(
          type: AchievementType.survival,
          neonColor: Color(0xFFFF4500), // Orange-red
          width: 4.0,
          angle: math.pi / 3, // 60 degrees
          length: 60.0,
          priority: 5,
        ),
      },
    );
  }

  /// Get branch configuration for a specific achievement type
  BranchConfig? getBranchConfig(AchievementType type) {
    return branchConfigs[type];
  }

  /// Calculate branch path points from a starting point
  List<Vector2> calculateBranchPath(
    Vector2 startPoint,
    AchievementType type,
    PathLayoutConfig layoutConfig,
  ) {
    final config = getBranchConfig(type);
    if (config == null) return [startPoint];

    final points = <Vector2>[startPoint.clone()];
    
    // Calculate branch direction based on layout orientation
    double effectiveAngle = config.angle;
    if (layoutConfig.isHorizontalLayout) {
      // Adjust angles for horizontal layout
      effectiveAngle = config.angle + math.pi / 2;
    }

    // Create branch points
    final branchLength = config.length * (layoutConfig.nodeSize / 44.0); // Scale with node size
    final direction = Vector2(math.cos(effectiveAngle), math.sin(effectiveAngle));
    
    // Add intermediate points for smooth curves
    const segments = 3;
    for (int i = 1; i <= segments; i++) {
      final t = i / segments;
      final distance = branchLength * t;
      
      // Add slight curve to make branches more organic
      final curveFactor = math.sin(t * math.pi) * 0.2;
      final curveOffset = Vector2(-direction.y, direction.x) * curveFactor * branchLength;
      
      final point = startPoint + (direction * distance) + curveOffset;
      points.add(point);
    }

    return points;
  }

  /// Get all branch types sorted by priority
  List<AchievementType> getBranchTypesByPriority() {
    final types = branchConfigs.keys.toList();
    types.sort((a, b) {
      final configA = branchConfigs[a]!;
      final configB = branchConfigs[b]!;
      return configA.priority.compareTo(configB.priority);
    });
    return types;
  }

  /// Check if a type represents the main path
  bool isMainPath(AchievementType type) {
    final config = getBranchConfig(type);
    return config?.priority == 0;
  }
}

/// Node position data with additional metadata
class NodePosition {
  final Vector2 position;
  final String achievementId;
  final AchievementType category;
  final NodeVisualState visualState;
  final double pathProgress; // 0.0 to 1.0 along the path
  final bool isOnMainPath;

  const NodePosition({
    required this.position,
    required this.achievementId,
    required this.category,
    required this.visualState,
    required this.pathProgress,
    required this.isOnMainPath,
  });

  /// Create a copy with updated visual state
  NodePosition copyWith({
    Vector2? position,
    NodeVisualState? visualState,
    double? pathProgress,
  }) {
    return NodePosition(
      position: position ?? this.position,
      achievementId: achievementId,
      category: category,
      visualState: visualState ?? this.visualState,
      pathProgress: pathProgress ?? this.pathProgress,
      isOnMainPath: isOnMainPath,
    );
  }
}