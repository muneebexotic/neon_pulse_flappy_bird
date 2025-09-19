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

  /// Calculate complete path layout for given screen size and achievements with responsive design
  void calculatePathLayout(Size screenSize, List<Achievement> achievements, {double? devicePixelRatio}) {
    _screenSize = screenSize;
    _layoutConfig = PathLayoutConfig.responsive(screenSize, devicePixelRatio: devicePixelRatio);
    
    // Clear caches
    _pathCache.clear();
    _lengthCache.clear();
    
    // Group achievements by type
    final achievementsByType = _groupAchievementsByType(achievements);
    
    // Calculate responsive main path
    _calculateResponsiveMainPath(achievementsByType);
    
    // Calculate adaptive branch paths
    _calculateAdaptiveBranchPaths(achievementsByType);
    
    // Calculate responsive node positions
    _calculateResponsiveNodePositions(achievements);
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

  /// Calculate the responsive main path with adaptive layout
  void _calculateResponsiveMainPath(Map<AchievementType, List<Achievement>> achievementsByType) {
    if (_layoutConfig == null || _screenSize == null) return;
    
    final mainPathType = _branchingLogic.getBranchTypesByPriority().first;
    final mainAchievements = achievementsByType[mainPathType] ?? [];
    
    if (mainAchievements.isEmpty) return;
    
    final effectiveSize = _layoutConfig!.getEffectiveScreenSize(_screenSize!);
    final pathPoints = _calculateResponsiveMainPathPoints(effectiveSize, mainAchievements.length);
    
    // Calculate completion percentage
    final unlockedCount = mainAchievements.where((a) => a.isUnlocked).length;
    final completionPercentage = mainAchievements.isEmpty 
        ? 0.0 
        : unlockedCount / mainAchievements.length;
    
    final config = _branchingLogic.getResponsiveBranchConfig(mainPathType, _layoutConfig!)!;
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

  /// Calculate responsive main path points with adaptive algorithms
  List<Vector2> _calculateResponsiveMainPathPoints(Size effectiveSize, int nodeCount) {
    if (_layoutConfig == null) return [];
    
    final points = <Vector2>[];
    
    if (_layoutConfig!.isHorizontalLayout) {
      // Responsive horizontal path with adaptive row management
      points.addAll(_calculateResponsiveHorizontalPath(effectiveSize, nodeCount));
    } else {
      // Responsive vertical path with adaptive curvature
      points.addAll(_calculateResponsiveVerticalPath(effectiveSize, nodeCount));
    }
    
    return _applyResponsiveSmoothing(points);
  }

  /// Calculate responsive horizontal path with adaptive row management
  List<Vector2> _calculateResponsiveHorizontalPath(Size effectiveSize, int nodeCount) {
    final points = <Vector2>[];
    final spacing = _layoutConfig!.minNodeSpacing;
    final pathWidth = math.min(_layoutConfig!.maxPathWidth, effectiveSize.width);
    final maxNodesPerRow = _layoutConfig!.maxNodesPerRow;
    
    // Calculate optimal starting position
    final startX = _layoutConfig!.screenPadding.left + (_layoutConfig!.nodeSize / 2);
    double currentX = startX;
    double currentY = effectiveSize.height / 2;
    
    // Adaptive row height based on screen size
    final rowHeight = _calculateAdaptiveRowHeight();
    
    bool movingRight = true;
    int nodesInCurrentRow = 0;
    int currentRow = 0;
    
    for (int i = 0; i < nodeCount; i++) {
      points.add(Vector2(currentX, currentY));
      
      if (movingRight) {
        currentX += spacing;
        if (++nodesInCurrentRow >= maxNodesPerRow || currentX > pathWidth - _layoutConfig!.nodeSize) {
          // Move to next row
          currentRow++;
          currentY += rowHeight;
          currentX = pathWidth - _layoutConfig!.nodeSize / 2; // Start from right
          movingRight = false;
          nodesInCurrentRow = 0;
        }
      } else {
        currentX -= spacing;
        if (++nodesInCurrentRow >= maxNodesPerRow || currentX < startX) {
          // Move to next row
          currentRow++;
          currentY += rowHeight;
          currentX = startX; // Start from left
          movingRight = true;
          nodesInCurrentRow = 0;
        }
      }
    }
    
    return points;
  }

  /// Calculate responsive vertical path with adaptive curvature
  List<Vector2> _calculateResponsiveVerticalPath(Size effectiveSize, int nodeCount) {
    final points = <Vector2>[];
    final spacing = _layoutConfig!.minNodeSpacing;
    
    // Calculate adaptive starting position
    final centerX = effectiveSize.width / 2;
    final startY = _layoutConfig!.screenPadding.top + (_layoutConfig!.nodeSize / 2);
    
    double currentX = centerX;
    double currentY = startY;
    
    // Calculate path parameters based on screen size and node count
    final pathLength = (nodeCount - 1) * spacing;
    final availableHeight = effectiveSize.height - _layoutConfig!.screenPadding.vertical;
    
    // Adaptive amplitude for horizontal variation
    final amplitude = _calculateAdaptiveAmplitude(effectiveSize.width);
    
    // Frequency adjustment based on available space
    final frequency = _calculateAdaptiveFrequency(nodeCount, availableHeight);
    
    for (int i = 0; i < nodeCount; i++) {
      // Calculate horizontal variation with responsive amplitude
      final t = i / math.max(1, nodeCount - 1);
      final horizontalVariation = amplitude * math.sin(t * frequency * 2 * math.pi);
      
      // Add progressive curve for more organic feel
      final progressiveCurve = _calculateProgressiveCurve(t, effectiveSize.width);
      
      final x = centerX + horizontalVariation + progressiveCurve;
      final y = currentY;
      
      points.add(Vector2(x, y));
      currentY += spacing;
    }
    
    return points;
  }

  /// Calculate adaptive row height for horizontal layouts
  double _calculateAdaptiveRowHeight() {
    final baseHeight = _layoutConfig!.minNodeSpacing;
    
    switch (_layoutConfig!.sizeCategory) {
      case ScreenSizeCategory.small:
        return baseHeight * 0.8;
      case ScreenSizeCategory.medium:
        return baseHeight;
      case ScreenSizeCategory.large:
        return baseHeight * 1.2;
      case ScreenSizeCategory.extraLarge:
        return baseHeight * 1.4;
    }
  }

  /// Calculate adaptive amplitude for vertical path variation
  double _calculateAdaptiveAmplitude(double screenWidth) {
    final baseAmplitude = 30.0 * _layoutConfig!.scaleFactor;
    final maxAmplitude = screenWidth * 0.15; // Max 15% of screen width
    
    double amplitude = baseAmplitude;
    
    // Adjust based on layout configuration
    if (_layoutConfig!.enableCompactMode) {
      amplitude *= 0.5; // Reduce variation in compact mode
    }
    
    switch (_layoutConfig!.sizeCategory) {
      case ScreenSizeCategory.small:
        amplitude *= 0.7;
        break;
      case ScreenSizeCategory.medium:
        amplitude *= 1.0;
        break;
      case ScreenSizeCategory.large:
        amplitude *= 1.3;
        break;
      case ScreenSizeCategory.extraLarge:
        amplitude *= 1.5;
        break;
    }
    
    return math.min(amplitude, maxAmplitude);
  }

  /// Calculate adaptive frequency for path variation
  double _calculateAdaptiveFrequency(int nodeCount, double availableHeight) {
    // Base frequency creates about 2-3 waves for the entire path
    double baseFrequency = 2.5;
    
    // Adjust frequency based on path density
    final pathDensity = nodeCount / (availableHeight / _layoutConfig!.minNodeSpacing);
    if (pathDensity > 1.5) {
      baseFrequency *= 0.7; // Reduce frequency for dense paths
    } else if (pathDensity < 0.5) {
      baseFrequency *= 1.3; // Increase frequency for sparse paths
    }
    
    return baseFrequency;
  }

  /// Calculate progressive curve for more organic path appearance
  double _calculateProgressiveCurve(double t, double screenWidth) {
    if (_layoutConfig!.enableCompactMode) return 0.0;
    
    // Create a subtle S-curve that becomes more pronounced toward the end
    final curveIntensity = screenWidth * 0.05 * _layoutConfig!.pathCurvature;
    final progressiveFactor = math.pow(t, 1.5).toDouble();
    
    return curveIntensity * math.sin(t * math.pi) * progressiveFactor;
  }

  /// Apply responsive smoothing with adaptive curve complexity
  List<Vector2> _applyResponsiveSmoothing(List<Vector2> points) {
    if (points.length < 3) return points;
    
    final segments = _layoutConfig!.getOptimalPathSegments();
    final smoothingIntensity = _calculateSmoothingIntensity();
    
    if (_layoutConfig!.enableCompactMode || _layoutConfig!.sizeCategory == ScreenSizeCategory.small) {
      // Use simpler smoothing for compact/small screens
      return _applySimpleSmoothing(points, smoothingIntensity);
    } else {
      // Use advanced bezier smoothing for larger screens
      return _applyAdvancedSmoothing(points, segments, smoothingIntensity);
    }
  }

  /// Calculate smoothing intensity based on layout configuration
  double _calculateSmoothingIntensity() {
    double intensity = 0.3; // Base intensity
    
    switch (_layoutConfig!.sizeCategory) {
      case ScreenSizeCategory.small:
        intensity = 0.2; // Less smoothing for performance
        break;
      case ScreenSizeCategory.medium:
        intensity = 0.3;
        break;
      case ScreenSizeCategory.large:
        intensity = 0.4;
        break;
      case ScreenSizeCategory.extraLarge:
        intensity = 0.5; // More dramatic curves
        break;
    }
    
    return intensity * _layoutConfig!.pathCurvature;
  }

  /// Apply simple smoothing for compact layouts
  List<Vector2> _applySimpleSmoothing(List<Vector2> points, double intensity) {
    if (points.length < 3) return points;
    
    final smoothed = <Vector2>[points.first];
    
    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final next = points[i + 1];
      
      // Simple interpolation
      final smoothedPoint = Vector2(
        current.x + (prev.x + next.x - 2 * current.x) * intensity * 0.5,
        current.y + (prev.y + next.y - 2 * current.y) * intensity * 0.5,
      );
      
      smoothed.add(smoothedPoint);
    }
    
    smoothed.add(points.last);
    return smoothed;
  }

  /// Apply advanced bezier smoothing for larger screens
  List<Vector2> _applyAdvancedSmoothing(List<Vector2> points, int segments, double intensity) {
    if (points.length < 3) return points;
    
    final smoothed = <Vector2>[points.first];
    
    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final next = points[i + 1];
      
      // Calculate control points for bezier curves
      final control1 = _lerpVector2(prev, current, 0.7 + intensity * 0.2);
      final control2 = _lerpVector2(current, next, 0.3 - intensity * 0.2);
      
      // Add intermediate points for smooth curves
      for (int j = 1; j <= segments; j++) {
        final t = j / (segments + 1);
        final bezierPoint = _calculateBezierPoint(prev, control1, control2, next, t);
        smoothed.add(bezierPoint);
      }
      
      smoothed.add(current);
    }
    
    smoothed.add(points.last);
    return smoothed;
  }

  /// Calculate bezier curve point
  Vector2 _calculateBezierPoint(Vector2 p0, Vector2 p1, Vector2 p2, Vector2 p3, double t) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;
    
    final x = uuu * p0.x + 3 * uu * t * p1.x + 3 * u * tt * p2.x + ttt * p3.x;
    final y = uuu * p0.y + 3 * uu * t * p1.y + 3 * u * tt * p2.y + ttt * p3.y;
    
    return Vector2(x, y);
  }

  /// Calculate adaptive branch paths with responsive positioning
  void _calculateAdaptiveBranchPaths(Map<AchievementType, List<Achievement>> achievementsByType) {
    if (_pathSegments.isEmpty) return; // Need main path first
    
    final mainPath = _pathSegments.first;
    final branchTypes = _branchingLogic.getBranchTypesByPriority().skip(1);
    
    // Calculate optimal branch points along the main path
    final branchPoints = _branchingLogic.calculateBranchPoints(branchTypes.length, _layoutConfig!);
    
    int branchIndex = 0;
    for (final branchType in branchTypes) {
      final achievements = achievementsByType[branchType];
      if (achievements == null || achievements.isEmpty) continue;
      
      final branchPoint = branchIndex < branchPoints.length 
          ? branchPoints[branchIndex] 
          : (branchIndex + 1) / (branchTypes.length + 1);
      
      _calculateAdaptiveBranchPath(mainPath, branchType, achievements, branchPoint);
      branchIndex++;
    }
  }

  /// Calculate adaptive branch path with responsive positioning
  void _calculateAdaptiveBranchPath(
    PathSegment mainPath,
    AchievementType branchType,
    List<Achievement> achievements,
    double branchPointPercentage,
  ) {
    if (_layoutConfig == null) return;
    
    final config = _branchingLogic.getResponsiveBranchConfig(branchType, _layoutConfig!);
    if (config == null) return;
    
    // Find adaptive branch point on main path
    final branchPoint = mainPath.getPointAtPercentage(branchPointPercentage);
    
    // Calculate responsive branch path points
    final branchPoints = _branchingLogic.calculateBranchPath(
      branchPoint,
      branchType,
      _layoutConfig!,
    );
    
    // Apply collision avoidance with existing branches
    final adjustedBranchPoints = _applyBranchCollisionAvoidance(branchPoints, branchType);
    
    // Calculate completion percentage
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final completionPercentage = achievements.isEmpty 
        ? 0.0 
        : unlockedCount / achievements.length;
    
    final branchSegment = PathSegment(
      id: 'branch_${branchType.toString()}',
      category: branchType,
      pathPoints: adjustedBranchPoints,
      neonColor: config.neonColor,
      width: config.width,
      isMainPath: false,
      completionPercentage: completionPercentage,
      achievementIds: achievements.map((a) => a.id).toList(),
    );
    
    _pathSegments.add(branchSegment);
  }

  /// Apply collision avoidance to prevent branch overlap
  List<Vector2> _applyBranchCollisionAvoidance(List<Vector2> branchPoints, AchievementType branchType) {
    if (branchPoints.length < 2) return branchPoints;
    
    final adjustedPoints = <Vector2>[];
    final minDistance = _layoutConfig!.nodeSize * 2.0; // Increased minimum distance
    
    for (int i = 0; i < branchPoints.length; i++) {
      Vector2 currentPoint = branchPoints[i];
      bool adjusted = false;
      
      // Check collision with existing branch segments (skip main path for first point)
      for (final existingSegment in _pathSegments) {
        if (existingSegment.isMainPath && i == 0) continue; // Allow connection to main path
        
        for (final existingPoint in existingSegment.pathPoints) {
          final distance = currentPoint.distanceTo(existingPoint);
          
          if (distance < minDistance && distance > 0.1) { // Avoid division by zero
            // Adjust point to avoid collision
            final direction = (currentPoint - existingPoint);
            if (direction.length > 0.1) {
              final normalizedDirection = direction.normalized();
              currentPoint = existingPoint + (normalizedDirection * minDistance);
              adjusted = true;
            }
          }
        }
      }
      
      // If we couldn't find a good position, use a fallback strategy
      if (adjusted && i > 0) {
        // Ensure the adjusted point maintains reasonable distance from previous point
        final prevPoint = adjustedPoints[i - 1];
        final distanceToPrev = currentPoint.distanceTo(prevPoint);
        if (distanceToPrev < _layoutConfig!.minNodeSpacing) {
          final direction = (currentPoint - prevPoint).normalized();
          currentPoint = prevPoint + (direction * _layoutConfig!.minNodeSpacing);
        }
      }
      
      adjustedPoints.add(currentPoint);
    }
    
    return adjustedPoints;
  }

  /// Calculate responsive positions for all achievement nodes
  void _calculateResponsiveNodePositions(List<Achievement> achievements) {
    _nodePositions.clear();
    
    for (final segment in _pathSegments) {
      _calculateResponsiveNodesForSegment(segment, achievements);
    }
    
    // Apply final positioning adjustments
    _applyNodePositionOptimizations();
  }

  /// Calculate responsive node positions for a specific path segment
  void _calculateResponsiveNodesForSegment(PathSegment segment, List<Achievement> achievements) {
    final segmentAchievements = achievements
        .where((a) => segment.achievementIds.contains(a.id))
        .toList();
    
    if (segmentAchievements.isEmpty) return;
    
    // Calculate adaptive node distribution
    final nodeDistribution = _calculateAdaptiveNodeDistribution(segmentAchievements.length, segment);
    
    for (int i = 0; i < segmentAchievements.length; i++) {
      final achievement = segmentAchievements[i];
      final progress = nodeDistribution[i];
      
      // Get base position along the path
      Vector2 position = segment.getPointAtPercentage(progress);
      
      // Apply responsive positioning adjustments
      position = _applyResponsivePositionAdjustments(position, achievement, segment);
      
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

  /// Calculate adaptive node distribution along a path segment
  List<double> _calculateAdaptiveNodeDistribution(int nodeCount, PathSegment segment) {
    if (nodeCount == 0) return [];
    if (nodeCount == 1) return [0.5];
    
    final distribution = <double>[];
    
    if (_layoutConfig!.enableCompactMode && nodeCount > 3) {
      // Only use compact clustering for many nodes, maintain standard distribution for few nodes
      for (int i = 0; i < nodeCount; i++) {
        final t = i / (nodeCount - 1);
        final adjustedT = 0.1 + (t * 0.8); // Use middle 80% of the path
        distribution.add(adjustedT);
      }
    } else if (segment.isMainPath && _layoutConfig!.sizeCategory == ScreenSizeCategory.extraLarge && nodeCount > 5) {
      // Use more dramatic spacing on large screens for main path with many nodes
      for (int i = 0; i < nodeCount; i++) {
        final t = i / (nodeCount - 1);
        final easedT = _applyEasingFunction(t); // Apply easing for more organic distribution
        distribution.add(easedT);
      }
    } else {
      // Standard even distribution for most cases
      for (int i = 0; i < nodeCount; i++) {
        final t = i / (nodeCount - 1);
        distribution.add(t);
      }
    }
    
    return distribution;
  }

  /// Apply easing function for more organic node distribution
  double _applyEasingFunction(double t) {
    // Use ease-in-out cubic for smooth acceleration/deceleration
    return t < 0.5 
        ? 4 * t * t * t 
        : 1 - math.pow(-2 * t + 2, 3) / 2;
  }

  /// Apply responsive positioning adjustments to individual nodes
  Vector2 _applyResponsivePositionAdjustments(Vector2 basePosition, Achievement achievement, PathSegment segment) {
    Vector2 adjustedPosition = basePosition.clone();
    
    // Apply screen edge avoidance
    adjustedPosition = _applyScreenEdgeAvoidance(adjustedPosition);
    
    // Apply node overlap prevention
    adjustedPosition = _applyNodeOverlapPrevention(adjustedPosition, achievement.id);
    
    // Apply accessibility touch target adjustments
    adjustedPosition = _applyAccessibilityAdjustments(adjustedPosition);
    
    return adjustedPosition;
  }

  /// Ensure nodes don't get too close to screen edges
  Vector2 _applyScreenEdgeAvoidance(Vector2 position) {
    if (_layoutConfig == null || _screenSize == null) return position;
    
    final nodeRadius = _layoutConfig!.getResponsiveNodeSize() / 2;
    final padding = _layoutConfig!.screenPadding;
    
    final minX = padding.left + nodeRadius;
    final maxX = _screenSize!.width - padding.right - nodeRadius;
    final minY = padding.top + nodeRadius;
    final maxY = _screenSize!.height - padding.bottom - nodeRadius;
    
    return Vector2(
      position.x.clamp(minX, maxX),
      position.y.clamp(minY, maxY),
    );
  }

  /// Prevent nodes from overlapping with existing nodes
  Vector2 _applyNodeOverlapPrevention(Vector2 position, String currentNodeId) {
    final minDistance = _layoutConfig!.nodeSize * 1.8; // Increased spacing between nodes
    Vector2 adjustedPosition = position.clone();
    int maxIterations = 5; // Prevent infinite loops
    
    for (int iteration = 0; iteration < maxIterations; iteration++) {
      bool needsAdjustment = false;
      
      for (final existingNode in _nodePositions.values) {
        if (existingNode.achievementId == currentNodeId) continue;
        
        final distance = adjustedPosition.distanceTo(existingNode.position);
        if (distance < minDistance && distance > 0.1) { // Avoid division by zero
          // Push the node away from the existing node
          final direction = (adjustedPosition - existingNode.position);
          if (direction.length > 0.1) {
            final normalizedDirection = direction.normalized();
            adjustedPosition = existingNode.position + (normalizedDirection * minDistance);
            needsAdjustment = true;
          }
        }
      }
      
      if (!needsAdjustment) break; // No more adjustments needed
    }
    
    return adjustedPosition;
  }

  /// Apply accessibility-focused positioning adjustments
  Vector2 _applyAccessibilityAdjustments(Vector2 position) {
    // Ensure minimum touch target size is maintained
    // This is handled by the layout config, but we can add additional checks here
    
    // Round to pixel boundaries for crisp rendering
    return Vector2(
      position.x.roundToDouble(),
      position.y.roundToDouble(),
    );
  }

  /// Apply final optimizations to all node positions
  void _applyNodePositionOptimizations() {
    if (_nodePositions.isEmpty) return;
    
    // Apply global position optimizations
    _optimizeNodeSpacing();
    _optimizeAccessibilityCompliance();
    _optimizeVisualBalance();
  }

  /// Optimize spacing between all nodes globally
  void _optimizeNodeSpacing() {
    final minSpacing = _layoutConfig!.nodeSize * 1.1;
    final nodeList = _nodePositions.values.toList();
    
    // Use simple force-based adjustment to prevent overlaps
    for (int iteration = 0; iteration < 3; iteration++) {
      for (int i = 0; i < nodeList.length; i++) {
        Vector2 force = Vector2.zero();
        final currentNode = nodeList[i];
        
        for (int j = 0; j < nodeList.length; j++) {
          if (i == j) continue;
          
          final otherNode = nodeList[j];
          final distance = currentNode.position.distanceTo(otherNode.position);
          
          if (distance < minSpacing && distance > 0) {
            final direction = (currentNode.position - otherNode.position).normalized();
            final pushForce = (minSpacing - distance) * 0.1;
            force += direction * pushForce;
          }
        }
        
        if (force.length > 0) {
          final newPosition = currentNode.position + force;
          final adjustedPosition = _applyScreenEdgeAvoidance(newPosition);
          
          _nodePositions[currentNode.achievementId] = currentNode.copyWith(
            position: adjustedPosition,
          );
        }
      }
    }
  }

  /// Ensure all nodes meet accessibility requirements
  void _optimizeAccessibilityCompliance() {
    final minTouchTarget = 44.0;
    
    for (final entry in _nodePositions.entries) {
      final node = entry.value;
      
      // Ensure the effective touch area meets minimum requirements
      if (_layoutConfig!.nodeSize < minTouchTarget) {
        // The touch area will be expanded in the UI layer, but we can
        // adjust positioning to account for the larger touch area
        final touchAreaExpansion = (minTouchTarget - _layoutConfig!.nodeSize) / 2;
        final adjustedPosition = _applyScreenEdgeAvoidance(
          Vector2(node.position.x, node.position.y)
        );
        
        _nodePositions[entry.key] = node.copyWith(position: adjustedPosition);
      }
    }
  }

  /// Optimize visual balance of the overall layout
  void _optimizeVisualBalance() {
    if (_layoutConfig!.enableCompactMode) return; // Skip for compact layouts
    
    // Calculate center of mass for main path nodes
    final mainPathNodes = _nodePositions.values.where((n) => n.isOnMainPath).toList();
    if (mainPathNodes.isEmpty) return;
    
    Vector2 centerOfMass = Vector2.zero();
    for (final node in mainPathNodes) {
      centerOfMass += node.position;
    }
    centerOfMass /= mainPathNodes.length.toDouble();
    
    // Calculate screen center
    final screenCenter = Vector2(_screenSize!.width / 2, _screenSize!.height / 2);
    
    // Apply subtle adjustment to center the path better
    final offset = (screenCenter - centerOfMass) * 0.1; // 10% adjustment
    
    if (offset.length > 5.0) { // Only adjust if offset is significant
      for (final entry in _nodePositions.entries) {
        final node = entry.value;
        if (node.isOnMainPath) {
          final adjustedPosition = _applyScreenEdgeAvoidance(node.position + offset);
          _nodePositions[entry.key] = node.copyWith(position: adjustedPosition);
        }
      }
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
    _calculateResponsiveNodePositions(achievements);
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