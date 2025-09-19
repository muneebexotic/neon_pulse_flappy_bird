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

/// Screen size categories for responsive design
enum ScreenSizeCategory {
  small,    // < 600dp
  medium,   // 600-900dp
  large,    // 900-1200dp
  extraLarge, // > 1200dp
}

/// Layout orientation based on aspect ratio
enum LayoutOrientation {
  portrait,     // height > width * 1.2
  landscape,    // width > height * 1.2
  square,       // roughly equal dimensions
}

/// Configuration for path layout calculations with enhanced responsive features
class PathLayoutConfig {
  final bool isHorizontalLayout;
  final double pathSpacing;
  final double nodeSize;
  final double branchAngle;
  final EdgeInsets screenPadding;
  final double minNodeSpacing;
  final double maxPathWidth;
  final double branchOffset;
  
  // Enhanced responsive properties
  final ScreenSizeCategory sizeCategory;
  final LayoutOrientation orientation;
  final double scaleFactor;
  final double aspectRatio;
  final double densityFactor;
  final int maxNodesPerRow;
  final double branchSpacing;
  final double pathCurvature;
  final bool enableCompactMode;

  const PathLayoutConfig({
    required this.isHorizontalLayout,
    required this.pathSpacing,
    required this.nodeSize,
    required this.branchAngle,
    required this.screenPadding,
    required this.sizeCategory,
    required this.orientation,
    required this.scaleFactor,
    required this.aspectRatio,
    required this.densityFactor,
    this.minNodeSpacing = 80.0,
    this.maxPathWidth = 400.0,
    this.branchOffset = 60.0,
    this.maxNodesPerRow = 5,
    this.branchSpacing = 120.0,
    this.pathCurvature = 0.3,
    this.enableCompactMode = false,
  });

  /// Create a responsive layout config based on screen size and device characteristics
  factory PathLayoutConfig.responsive(Size screenSize, {double? devicePixelRatio}) {
    final pixelRatio = devicePixelRatio ?? 1.0;
    final aspectRatio = screenSize.width / screenSize.height;
    
    // Determine screen size category
    final minDimension = math.min(screenSize.width, screenSize.height);
    final sizeCategory = _determineScreenSizeCategory(minDimension);
    
    // Determine layout orientation
    final orientation = _determineLayoutOrientation(aspectRatio);
    
    // Calculate responsive scale factor
    final scaleFactor = _calculateScaleFactor(screenSize, sizeCategory);
    
    // Determine if horizontal layout is better
    final isHorizontal = _shouldUseHorizontalLayout(screenSize, orientation, sizeCategory);
    
    // Calculate density-aware sizing
    final densityFactor = math.max(1.0, pixelRatio / 2.0);
    final baseNodeSize = 44.0; // Minimum accessibility touch target
    final nodeSize = math.max(baseNodeSize, baseNodeSize * scaleFactor / densityFactor);
    
    // Calculate adaptive spacing
    final baseSpacing = _calculateBaseSpacing(sizeCategory, orientation);
    final pathSpacing = baseSpacing * scaleFactor;
    final minNodeSpacing = math.max(nodeSize * 1.8, 60.0 * scaleFactor);
    
    // Calculate branch configuration
    final branchAngle = _calculateOptimalBranchAngle(orientation, aspectRatio);
    final branchOffset = _calculateBranchOffset(sizeCategory, scaleFactor);
    final branchSpacing = _calculateBranchSpacing(sizeCategory, scaleFactor);
    
    // Calculate path width constraints
    final maxPathWidth = _calculateMaxPathWidth(screenSize, sizeCategory, orientation);
    
    // Determine compact mode for small screens
    final enableCompactMode = sizeCategory == ScreenSizeCategory.small || 
                             (orientation == LayoutOrientation.portrait && aspectRatio < 0.6);
    
    // Calculate max nodes per row
    final maxNodesPerRow = _calculateMaxNodesPerRow(screenSize, nodeSize, minNodeSpacing);
    
    // Calculate path curvature based on available space
    final pathCurvature = _calculatePathCurvature(sizeCategory, orientation);
    
    // Calculate responsive padding
    final paddingValue = _calculatePadding(sizeCategory, scaleFactor);
    final screenPadding = EdgeInsets.all(paddingValue);
    
    return PathLayoutConfig(
      isHorizontalLayout: isHorizontal,
      pathSpacing: pathSpacing,
      nodeSize: nodeSize,
      branchAngle: branchAngle,
      screenPadding: screenPadding,
      sizeCategory: sizeCategory,
      orientation: orientation,
      scaleFactor: scaleFactor,
      aspectRatio: aspectRatio,
      densityFactor: densityFactor,
      minNodeSpacing: minNodeSpacing,
      maxPathWidth: maxPathWidth,
      branchOffset: branchOffset,
      maxNodesPerRow: maxNodesPerRow,
      branchSpacing: branchSpacing,
      pathCurvature: pathCurvature,
      enableCompactMode: enableCompactMode,
    );
  }

  /// Determine screen size category based on minimum dimension
  static ScreenSizeCategory _determineScreenSizeCategory(double minDimension) {
    if (minDimension < 600) return ScreenSizeCategory.small;
    if (minDimension < 800) return ScreenSizeCategory.medium;
    if (minDimension < 1100) return ScreenSizeCategory.large;
    return ScreenSizeCategory.extraLarge;
  }

  /// Determine layout orientation based on aspect ratio
  static LayoutOrientation _determineLayoutOrientation(double aspectRatio) {
    if (aspectRatio > 1.2) return LayoutOrientation.landscape;
    if (aspectRatio < 0.83) return LayoutOrientation.portrait; // 1/1.2
    return LayoutOrientation.square;
  }

  /// Calculate responsive scale factor
  static double _calculateScaleFactor(Size screenSize, ScreenSizeCategory category) {
    final baseSize = 400.0;
    final minDimension = math.min(screenSize.width, screenSize.height);
    
    // Base scale factor
    double scaleFactor = minDimension / baseSize;
    
    // Apply category-specific adjustments
    switch (category) {
      case ScreenSizeCategory.small:
        scaleFactor = math.max(0.8, scaleFactor * 0.9);
        break;
      case ScreenSizeCategory.medium:
        scaleFactor = math.max(1.0, scaleFactor);
        break;
      case ScreenSizeCategory.large:
        scaleFactor = math.min(1.5, scaleFactor * 1.1);
        break;
      case ScreenSizeCategory.extraLarge:
        scaleFactor = math.min(2.0, scaleFactor * 1.2);
        break;
    }
    
    return scaleFactor.clamp(0.7, 2.5);
  }

  /// Determine if horizontal layout should be used
  static bool _shouldUseHorizontalLayout(
    Size screenSize, 
    LayoutOrientation orientation, 
    ScreenSizeCategory category
  ) {
    // Always use horizontal for landscape on medium+ screens
    if (orientation == LayoutOrientation.landscape && 
        category != ScreenSizeCategory.small) {
      return true;
    }
    
    // Use horizontal for very wide screens
    if (screenSize.width > screenSize.height * 1.5) {
      return true;
    }
    
    // Use vertical for portrait and small screens
    return false;
  }

  /// Calculate base spacing for different screen categories
  static double _calculateBaseSpacing(ScreenSizeCategory category, LayoutOrientation orientation) {
    double baseSpacing = 120.0;
    
    switch (category) {
      case ScreenSizeCategory.small:
        baseSpacing = orientation == LayoutOrientation.portrait ? 100.0 : 110.0;
        break;
      case ScreenSizeCategory.medium:
        baseSpacing = 120.0;
        break;
      case ScreenSizeCategory.large:
        baseSpacing = 140.0;
        break;
      case ScreenSizeCategory.extraLarge:
        baseSpacing = 160.0;
        break;
    }
    
    return baseSpacing;
  }

  /// Calculate optimal branch angle based on orientation and aspect ratio
  static double _calculateOptimalBranchAngle(LayoutOrientation orientation, double aspectRatio) {
    switch (orientation) {
      case LayoutOrientation.portrait:
        return math.pi / 4; // 45 degrees - more vertical space
      case LayoutOrientation.landscape:
        return math.pi / 6; // 30 degrees - more horizontal space
      case LayoutOrientation.square:
        return math.pi / 5; // 36 degrees - balanced
    }
  }

  /// Calculate branch offset based on screen size and scale
  static double _calculateBranchOffset(ScreenSizeCategory category, double scaleFactor) {
    double baseOffset = 60.0;
    
    switch (category) {
      case ScreenSizeCategory.small:
        baseOffset = 45.0;
        break;
      case ScreenSizeCategory.medium:
        baseOffset = 60.0;
        break;
      case ScreenSizeCategory.large:
        baseOffset = 75.0;
        break;
      case ScreenSizeCategory.extraLarge:
        baseOffset = 90.0;
        break;
    }
    
    return baseOffset * scaleFactor;
  }

  /// Calculate branch spacing
  static double _calculateBranchSpacing(ScreenSizeCategory category, double scaleFactor) {
    double baseSpacing = 120.0;
    
    switch (category) {
      case ScreenSizeCategory.small:
        baseSpacing = 100.0;
        break;
      case ScreenSizeCategory.medium:
        baseSpacing = 120.0;
        break;
      case ScreenSizeCategory.large:
        baseSpacing = 140.0;
        break;
      case ScreenSizeCategory.extraLarge:
        baseSpacing = 160.0;
        break;
    }
    
    return baseSpacing * scaleFactor;
  }

  /// Calculate maximum path width
  static double _calculateMaxPathWidth(
    Size screenSize, 
    ScreenSizeCategory category, 
    LayoutOrientation orientation
  ) {
    double maxWidth = screenSize.width * 0.8;
    
    switch (category) {
      case ScreenSizeCategory.small:
        maxWidth = math.min(maxWidth, 300.0);
        break;
      case ScreenSizeCategory.medium:
        maxWidth = math.min(maxWidth, 500.0);
        break;
      case ScreenSizeCategory.large:
        maxWidth = math.min(maxWidth, 700.0);
        break;
      case ScreenSizeCategory.extraLarge:
        maxWidth = math.min(maxWidth, 900.0);
        break;
    }
    
    // Adjust for orientation
    if (orientation == LayoutOrientation.portrait) {
      maxWidth = math.min(maxWidth, screenSize.width * 0.9);
    }
    
    return maxWidth;
  }

  /// Calculate maximum nodes per row
  static int _calculateMaxNodesPerRow(Size screenSize, double nodeSize, double minSpacing) {
    final availableWidth = screenSize.width * 0.8;
    final nodeWithSpacing = nodeSize + minSpacing;
    final maxNodes = (availableWidth / nodeWithSpacing).floor();
    return math.max(2, math.min(8, maxNodes));
  }

  /// Calculate path curvature factor
  static double _calculatePathCurvature(ScreenSizeCategory category, LayoutOrientation orientation) {
    double curvature = 0.3;
    
    switch (category) {
      case ScreenSizeCategory.small:
        curvature = 0.2; // Less curvature for small screens
        break;
      case ScreenSizeCategory.medium:
        curvature = 0.3;
        break;
      case ScreenSizeCategory.large:
        curvature = 0.4;
        break;
      case ScreenSizeCategory.extraLarge:
        curvature = 0.5; // More dramatic curves on large screens
        break;
    }
    
    // Adjust for orientation
    if (orientation == LayoutOrientation.landscape) {
      curvature *= 0.8; // Reduce curvature in landscape
    }
    
    return curvature;
  }

  /// Calculate responsive padding
  static double _calculatePadding(ScreenSizeCategory category, double scaleFactor) {
    double basePadding = 20.0;
    
    switch (category) {
      case ScreenSizeCategory.small:
        basePadding = 16.0;
        break;
      case ScreenSizeCategory.medium:
        basePadding = 20.0;
        break;
      case ScreenSizeCategory.large:
        basePadding = 24.0;
        break;
      case ScreenSizeCategory.extraLarge:
        basePadding = 32.0;
        break;
    }
    
    return basePadding * scaleFactor;
  }

  /// Get the effective screen size after padding
  Size getEffectiveScreenSize(Size screenSize) {
    return Size(
      screenSize.width - screenPadding.horizontal,
      screenSize.height - screenPadding.vertical,
    );
  }

  /// Get responsive node size with minimum touch target compliance
  double getResponsiveNodeSize() {
    return math.max(44.0, nodeSize); // Ensure minimum 44dp touch target
  }

  /// Get adaptive branch length based on available space
  double getAdaptiveBranchLength(double baseLength) {
    return baseLength * scaleFactor * (enableCompactMode ? 0.8 : 1.0);
  }

  /// Check if the layout should use compact mode
  bool shouldUseCompactMode() {
    return enableCompactMode;
  }

  /// Get the optimal number of path segments for smooth curves
  int getOptimalPathSegments() {
    switch (sizeCategory) {
      case ScreenSizeCategory.small:
        return 8;
      case ScreenSizeCategory.medium:
        return 12;
      case ScreenSizeCategory.large:
        return 16;
      case ScreenSizeCategory.extraLarge:
        return 20;
    }
  }

  /// Create a copy with updated properties
  PathLayoutConfig copyWith({
    bool? isHorizontalLayout,
    double? pathSpacing,
    double? nodeSize,
    double? branchAngle,
    EdgeInsets? screenPadding,
    double? minNodeSpacing,
    double? maxPathWidth,
    double? branchOffset,
    int? maxNodesPerRow,
    double? branchSpacing,
    double? pathCurvature,
    bool? enableCompactMode,
  }) {
    return PathLayoutConfig(
      isHorizontalLayout: isHorizontalLayout ?? this.isHorizontalLayout,
      pathSpacing: pathSpacing ?? this.pathSpacing,
      nodeSize: nodeSize ?? this.nodeSize,
      branchAngle: branchAngle ?? this.branchAngle,
      screenPadding: screenPadding ?? this.screenPadding,
      sizeCategory: sizeCategory,
      orientation: orientation,
      scaleFactor: scaleFactor,
      aspectRatio: aspectRatio,
      densityFactor: densityFactor,
      minNodeSpacing: minNodeSpacing ?? this.minNodeSpacing,
      maxPathWidth: maxPathWidth ?? this.maxPathWidth,
      branchOffset: branchOffset ?? this.branchOffset,
      maxNodesPerRow: maxNodesPerRow ?? this.maxNodesPerRow,
      branchSpacing: branchSpacing ?? this.branchSpacing,
      pathCurvature: pathCurvature ?? this.pathCurvature,
      enableCompactMode: enableCompactMode ?? this.enableCompactMode,
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

  /// Calculate branch path points from a starting point with responsive positioning
  List<Vector2> calculateBranchPath(
    Vector2 startPoint,
    AchievementType type,
    PathLayoutConfig layoutConfig,
  ) {
    final config = getBranchConfig(type);
    if (config == null) return [startPoint];

    final points = <Vector2>[startPoint.clone()];
    
    // Calculate responsive branch direction based on layout configuration
    double effectiveAngle = _calculateResponsiveBranchAngle(config.angle, layoutConfig);
    
    // Calculate adaptive branch length
    final adaptiveBranchLength = _calculateAdaptiveBranchLength(config.length, layoutConfig);
    
    // Create branch points with responsive spacing
    final segments = _calculateOptimalBranchSegments(layoutConfig);
    final direction = Vector2(math.cos(effectiveAngle), math.sin(effectiveAngle));
    
    for (int i = 1; i <= segments; i++) {
      final t = i / segments.toDouble();
      final distance = adaptiveBranchLength * t;
      
      // Apply responsive curvature
      final curveFactor = _calculateCurveFactor(t, layoutConfig);
      final curveOffset = Vector2(-direction.y, direction.x) * curveFactor * adaptiveBranchLength;
      
      final point = startPoint + (direction * distance) + curveOffset;
      points.add(point);
    }

    return points;
  }

  /// Calculate responsive branch angle based on layout configuration
  double _calculateResponsiveBranchAngle(double baseAngle, PathLayoutConfig layoutConfig) {
    double effectiveAngle = baseAngle;
    
    // Adjust for layout orientation
    switch (layoutConfig.orientation) {
      case LayoutOrientation.landscape:
        // Compress angles horizontally in landscape mode
        effectiveAngle = baseAngle * 0.7;
        if (layoutConfig.isHorizontalLayout) {
          effectiveAngle += math.pi / 2; // Rotate for horizontal main path
        }
        break;
      case LayoutOrientation.portrait:
        // Expand angles vertically in portrait mode
        effectiveAngle = baseAngle * 1.2;
        break;
      case LayoutOrientation.square:
        // Use base angle for square layouts
        effectiveAngle = baseAngle;
        break;
    }
    
    // Adjust for compact mode
    if (layoutConfig.enableCompactMode) {
      effectiveAngle *= 0.8; // Reduce branch spread in compact mode
    }
    
    // Ensure branches don't overlap with main path
    final minAngle = math.pi / 8; // 22.5 degrees minimum
    if (effectiveAngle.abs() < minAngle) {
      effectiveAngle = effectiveAngle.sign * minAngle;
    }
    
    return effectiveAngle;
  }

  /// Calculate adaptive branch length based on screen size and layout
  double _calculateAdaptiveBranchLength(double baseLength, PathLayoutConfig layoutConfig) {
    double adaptiveLength = baseLength * layoutConfig.scaleFactor;
    
    // Adjust for screen size category
    switch (layoutConfig.sizeCategory) {
      case ScreenSizeCategory.small:
        adaptiveLength *= 0.7; // Shorter branches on small screens
        break;
      case ScreenSizeCategory.medium:
        adaptiveLength *= 1.0;
        break;
      case ScreenSizeCategory.large:
        adaptiveLength *= 1.3;
        break;
      case ScreenSizeCategory.extraLarge:
        adaptiveLength *= 1.5;
        break;
    }
    
    // Adjust for compact mode
    if (layoutConfig.enableCompactMode) {
      adaptiveLength *= 0.6;
    }
    
    // Ensure minimum branch length for visibility
    return math.max(adaptiveLength, 40.0 * layoutConfig.scaleFactor);
  }

  /// Calculate optimal number of branch segments for smooth curves
  int _calculateOptimalBranchSegments(PathLayoutConfig layoutConfig) {
    switch (layoutConfig.sizeCategory) {
      case ScreenSizeCategory.small:
        return layoutConfig.enableCompactMode ? 2 : 3;
      case ScreenSizeCategory.medium:
        return 4;
      case ScreenSizeCategory.large:
        return 5;
      case ScreenSizeCategory.extraLarge:
        return 6;
    }
  }

  /// Calculate curve factor for organic branch appearance
  double _calculateCurveFactor(double t, PathLayoutConfig layoutConfig) {
    final baseCurveFactor = math.sin(t * math.pi) * layoutConfig.pathCurvature;
    
    // Adjust curve intensity based on screen size
    double curveMultiplier = 1.0;
    switch (layoutConfig.sizeCategory) {
      case ScreenSizeCategory.small:
        curveMultiplier = 0.5; // Subtle curves on small screens
        break;
      case ScreenSizeCategory.medium:
        curveMultiplier = 0.8;
        break;
      case ScreenSizeCategory.large:
        curveMultiplier = 1.0;
        break;
      case ScreenSizeCategory.extraLarge:
        curveMultiplier = 1.2; // More dramatic curves on large screens
        break;
    }
    
    return baseCurveFactor * curveMultiplier;
  }

  /// Calculate optimal branch point positions along the main path
  List<double> calculateBranchPoints(int branchCount, PathLayoutConfig layoutConfig) {
    if (branchCount == 0) return [];
    
    final points = <double>[];
    
    // Distribute branches along the path based on layout configuration
    if (layoutConfig.enableCompactMode) {
      // Cluster branches closer to the beginning in compact mode
      for (int i = 0; i < branchCount; i++) {
        final t = (i + 1) / (branchCount + 1);
        final adjustedT = math.pow(t, 0.7).toDouble(); // Bias toward beginning
        points.add(adjustedT);
      }
    } else {
      // Even distribution for normal layouts
      for (int i = 0; i < branchCount; i++) {
        final t = (i + 1) / (branchCount + 1);
        points.add(t);
      }
    }
    
    return points;
  }

  /// Get responsive branch configuration with adaptive properties
  BranchConfig? getResponsiveBranchConfig(AchievementType type, PathLayoutConfig layoutConfig) {
    final baseConfig = getBranchConfig(type);
    if (baseConfig == null) return null;
    
    // Create responsive branch config
    return BranchConfig(
      type: baseConfig.type,
      neonColor: baseConfig.neonColor,
      width: baseConfig.width * layoutConfig.scaleFactor,
      angle: _calculateResponsiveBranchAngle(baseConfig.angle, layoutConfig),
      length: _calculateAdaptiveBranchLength(baseConfig.length, layoutConfig),
      priority: baseConfig.priority,
    );
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