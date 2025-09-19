import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/achievement.dart';
import '../models/progression_path_models.dart';

/// Helper function to interpolate between two Vector2 points
Vector2 _lerpVector2(Vector2 a, Vector2 b, double t) {
  return Vector2(
    a.x + (b.x - a.x) * t,
    a.y + (b.y - a.y) * t,
  );
}

/// Controller for managing progression path layout and calculations
class ProgressionPathController {
  final BranchingLogic _branchingLogic;
  
  List<PathSegment> _pathSegments = [];
  Map<String, NodePosition> _nodePositions = {};
  PathLayoutConfig? _layoutConfig;
  Size? _screenSize;
  
  // Cache for performance optimization
  final Map<String, List<Vector2>> _pathCache = {};
  final Map<String, double> _lengthCache = {};

  ProgressionPathController({
    BranchingLogic? branchingLogic,
  }) : _branchingLogic = branchingLogic ?? BranchingLogic.defaultConfig();

  /// Get current path segments
  List<PathSegment> get pathSegments => List.unmodifiable(_pathSegments);

  /// Get current node positions
  Map<String, NodePosition> get nodePositions => Map.unmodifiable(_nodePositions);

  /// Get current layout configuration
  PathLayoutConfig? get layoutConfig => _layoutConfig;

  /// Calculate complete path layout for given screen size and achievements
  void calculatePathLayout(Size screenSize, List<Achievement> achievements) {
    _screenSize = screenSize;
    _layoutConfig = PathLayoutConfig.responsive(screenSize);
    
    // Clear caches
    _pathCache.clear();
    _lengthCache.clear();
    
    // Group achievements by type
    final achievementsByType = _groupAchievementsByType(achievements);
    
    // Calculate main path first
    _calculateMainPath(achievementsByType);
    
    // Calculate branch paths
    _calculateBranchPaths(achievementsByType);
    
    // Calculate node positions
    _calculateNodePositions(achievements);
  }

  /// Group achievements by their type
  Map<AchievementType, List<Achievement>> _groupAchievementsByType(
    List<Achievement> achievements,
  ) {
    final grouped = <AchievementType, List<Achievement>>{};
    
    for (final achievement in achievements) {
      grouped.putIfAbsent(achievement.type, () => []).add(achievement);
    }
    
    // Sort achievements within each type by target value (difficulty)
    for (final list in grouped.values) {
      list.sort((a, b) => a.targetValue.compareTo(b.targetValue));
    }
    
    return grouped;
  }

  /// Calculate the main path (typically score-based achievements)
  void _calculateMainPath(Map<AchievementType, List<Achievement>> achievementsByType) {
    if (_layoutConfig == null || _screenSize == null) return;
    
    final mainPathType = _branchingLogic.getBranchTypesByPriority().first;
    final mainAchievements = achievementsByType[mainPathType] ?? [];
    
    if (mainAchievements.isEmpty) return;
    
    final effectiveSize = _layoutConfig!.getEffectiveScreenSize(_screenSize!);
    final pathPoints = _calculateMainPathPoints(effectiveSize, mainAchievements.length);
    
    // Calculate completion percentage
    final unlockedCount = mainAchievements.where((a) => a.isUnlocked).length;
    final completionPercentage = mainAchievements.isEmpty 
        ? 0.0 
        : unlockedCount / mainAchievements.length;
    
    final config = _branchingLogic.getBranchConfig(mainPathType)!;
    final mainSegment = PathSegment(
      id: 'main_path',
      category: mainPathType,
      pathPoints: pathPoints,
      neonColor: config.neonColor,
      width: config.width,
      isMainPath: true,
      completionPercentage: completionPercentage,
      achievementIds: mainAchievements.map((a) => a.id).toList(),
    );
    
    _pathSegments = [mainSegment];
  }

  /// Calculate main path points based on layout orientation
  List<Vector2> _calculateMainPathPoints(Size effectiveSize, int nodeCount) {
    if (_layoutConfig == null) return [];
    
    final points = <Vector2>[];
    final isHorizontal = _layoutConfig!.isHorizontalLayout;
    
    if (isHorizontal) {
      // Horizontal snaking path
      points.addAll(_calculateHorizontalPath(effectiveSize, nodeCount));
    } else {
      // Vertical snaking path
      points.addAll(_calculateVerticalPath(effectiveSize, nodeCount));
    }
    
    return points;
  }

  /// Calculate horizontal snaking path
  List<Vector2> _calculateHorizontalPath(Size effectiveSize, int nodeCount) {
    final points = <Vector2>[];
    final spacing = _layoutConfig!.minNodeSpacing;
    final pathWidth = math.min(_layoutConfig!.maxPathWidth, effectiveSize.width);
    
    // Start from left side
    double currentX = _layoutConfig!.screenPadding.left;
    double currentY = effectiveSize.height / 2;
    
    bool movingRight = true;
    int nodesInCurrentRow = 0;
    final maxNodesPerRow = (pathWidth / spacing).floor();
    
    for (int i = 0; i < nodeCount; i++) {
      points.add(Vector2(currentX, currentY));
      
      if (movingRight) {
        currentX += spacing;
        if (++nodesInCurrentRow >= maxNodesPerRow) {
          // Switch to next row
          currentY += spacing;
          movingRight = false;
          nodesInCurrentRow = 0;
        }
      } else {
        currentX -= spacing;
        if (++nodesInCurrentRow >= maxNodesPerRow) {
          // Switch to next row
          currentY += spacing;
          movingRight = true;
          nodesInCurrentRow = 0;
        }
      }
    }
    
    return _smoothPath(points);
  }

  /// Calculate vertical snaking path
  List<Vector2> _calculateVerticalPath(Size effectiveSize, int nodeCount) {
    final points = <Vector2>[];
    final spacing = _layoutConfig!.minNodeSpacing;
    
    // Start from top center
    double currentX = effectiveSize.width / 2;
    double currentY = _layoutConfig!.screenPadding.top;
    
    // Create a snaking vertical path
    for (int i = 0; i < nodeCount; i++) {
      // Add some horizontal variation for visual interest
      final variation = math.sin(i * 0.5) * 30.0;
      points.add(Vector2(currentX + variation, currentY));
      currentY += spacing;
    }
    
    return _smoothPath(points);
  }

  /// Smooth path points using bezier curves
  List<Vector2> _smoothPath(List<Vector2> points) {
    if (points.length < 3) return points;
    
    final smoothed = <Vector2>[points.first];
    
    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final next = points[i + 1];
      
      // Add control points for smooth curves
      final control1 = _lerpVector2(prev, current, 0.7);
      final control2 = _lerpVector2(current, next, 0.3);
      
      smoothed.add(control1);
      smoothed.add(current);
      smoothed.add(control2);
    }
    
    smoothed.add(points.last);
    return smoothed;
  }

  /// Calculate branch paths for non-main achievement types
  void _calculateBranchPaths(Map<AchievementType, List<Achievement>> achievementsByType) {
    if (_pathSegments.isEmpty) return; // Need main path first
    
    final mainPath = _pathSegments.first;
    final branchTypes = _branchingLogic.getBranchTypesByPriority().skip(1);
    
    for (final branchType in branchTypes) {
      final achievements = achievementsByType[branchType];
      if (achievements == null || achievements.isEmpty) continue;
      
      _calculateBranchPath(mainPath, branchType, achievements);
    }
  }

  /// Calculate a single branch path
  void _calculateBranchPath(
    PathSegment mainPath,
    AchievementType branchType,
    List<Achievement> achievements,
  ) {
    if (_layoutConfig == null) return;
    
    final config = _branchingLogic.getBranchConfig(branchType);
    if (config == null) return;
    
    // Find branch point on main path (typically 1/3 along the path)
    final branchPoint = mainPath.getPointAtPercentage(0.33);
    
    // Calculate branch path points
    final branchPoints = _branchingLogic.calculateBranchPath(
      branchPoint,
      branchType,
      _layoutConfig!,
    );
    
    // Calculate completion percentage
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final completionPercentage = achievements.isEmpty 
        ? 0.0 
        : unlockedCount / achievements.length;
    
    final branchSegment = PathSegment(
      id: 'branch_${branchType.toString()}',
      category: branchType,
      pathPoints: branchPoints,
      neonColor: config.neonColor,
      width: config.width,
      isMainPath: false,
      completionPercentage: completionPercentage,
      achievementIds: achievements.map((a) => a.id).toList(),
    );
    
    _pathSegments.add(branchSegment);
  }

  /// Calculate positions for all achievement nodes
  void _calculateNodePositions(List<Achievement> achievements) {
    _nodePositions.clear();
    
    for (final segment in _pathSegments) {
      _calculateNodesForSegment(segment, achievements);
    }
  }

  /// Calculate node positions for a specific path segment
  void _calculateNodesForSegment(PathSegment segment, List<Achievement> achievements) {
    final segmentAchievements = achievements
        .where((a) => segment.achievementIds.contains(a.id))
        .toList();
    
    if (segmentAchievements.isEmpty) return;
    
    // Distribute nodes evenly along the path
    for (int i = 0; i < segmentAchievements.length; i++) {
      final achievement = segmentAchievements[i];
      final progress = segmentAchievements.length == 1 
          ? 0.5 
          : i / (segmentAchievements.length - 1);
      
      final position = segment.getPointAtPercentage(progress);
      final visualState = _determineNodeVisualState(achievement);
      
      _nodePositions[achievement.id] = NodePosition(
        position: position,
        achievementId: achievement.id,
        category: achievement.type,
        visualState: visualState,
        pathProgress: progress,
        isOnMainPath: segment.isMainPath,
      );
    }
  }

  /// Determine the visual state of an achievement node
  NodeVisualState _determineNodeVisualState(Achievement achievement) {
    if (achievement.isUnlocked) {
      return achievement.rewardSkinId != null 
          ? NodeVisualState.rewardAvailable 
          : NodeVisualState.unlocked;
    } else if (achievement.currentProgress > 0) {
      return NodeVisualState.inProgress;
    } else {
      return NodeVisualState.locked;
    }
  }

  /// Get node position for a specific achievement
  NodePosition? getNodePosition(String achievementId) {
    return _nodePositions[achievementId];
  }

  /// Update path progress based on new achievement data
  void updatePathProgress(List<Achievement> achievements) {
    if (_pathSegments.isEmpty) return;
    
    // Update segment completion percentages
    final updatedSegments = <PathSegment>[];
    
    for (final segment in _pathSegments) {
      final segmentAchievements = achievements
          .where((a) => segment.achievementIds.contains(a.id))
          .toList();
      
      final unlockedCount = segmentAchievements.where((a) => a.isUnlocked).length;
      final completionPercentage = segmentAchievements.isEmpty 
          ? 0.0 
          : unlockedCount / segmentAchievements.length;
      
      updatedSegments.add(segment.copyWith(
        completionPercentage: completionPercentage,
      ));
    }
    
    _pathSegments = updatedSegments;
    
    // Update node positions with new visual states
    _calculateNodePositions(achievements);
  }

  /// Get the total path length for scroll calculations
  double getTotalPathLength() {
    if (_pathSegments.isEmpty) return 0.0;
    
    // Use main path length as reference
    final mainPath = _pathSegments.firstWhere(
      (s) => s.isMainPath,
      orElse: () => _pathSegments.first,
    );
    
    return mainPath.pathLength;
  }

  /// Get scroll position for a specific achievement
  double getScrollPositionForAchievement(String achievementId) {
    final nodePosition = getNodePosition(achievementId);
    if (nodePosition == null) return 0.0;
    
    final totalLength = getTotalPathLength();
    if (totalLength == 0) return 0.0;
    
    return nodePosition.pathProgress * totalLength;
  }

  /// Get the current progress position (furthest unlocked achievement)
  double getCurrentProgressPosition(List<Achievement> achievements) {
    double maxProgress = 0.0;
    
    for (final achievement in achievements) {
      if (achievement.isUnlocked) {
        final nodePosition = getNodePosition(achievement.id);
        if (nodePosition != null && nodePosition.isOnMainPath) {
          maxProgress = math.max(maxProgress, nodePosition.pathProgress);
        }
      }
    }
    
    return maxProgress;
  }

  /// Generate branching paths for all achievement types
  void generateBranchingPaths() {
    // This method is called as part of calculatePathLayout
    // Implementation is distributed across _calculateMainPath and _calculateBranchPaths
  }

  /// Clear all cached data
  void clearCache() {
    _pathCache.clear();
    _lengthCache.clear();
  }

  /// Get performance statistics
  Map<String, dynamic> getStats() {
    return {
      'pathSegments': _pathSegments.length,
      'nodePositions': _nodePositions.length,
      'cachedPaths': _pathCache.length,
      'cachedLengths': _lengthCache.length,
      'totalPathLength': getTotalPathLength(),
      'screenSize': _screenSize?.toString() ?? 'null',
      'layoutConfig': _layoutConfig != null ? 'configured' : 'null',
    };
  }
}