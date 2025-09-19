import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../lib/models/progression_path_models.dart';
import '../../lib/models/achievement.dart';

void main() {
  group('PathSegment', () {
    late PathSegment testSegment;

    setUp(() {
      testSegment = PathSegment(
        id: 'test_segment',
        category: AchievementType.score,
        pathPoints: [
          Vector2(0, 0),
          Vector2(100, 0),
          Vector2(100, 100),
          Vector2(200, 100),
        ],
        neonColor: Colors.pink,
        width: 8.0,
        isMainPath: true,
        completionPercentage: 0.5,
        achievementIds: ['achievement_1', 'achievement_2'],
      );
    });

    test('should calculate path length correctly', () {
      final length = testSegment.pathLength;
      
      // Expected: 100 + 100 + 100 = 300
      expect(length, closeTo(300.0, 0.1));
    });

    test('should handle empty path points', () {
      final emptySegment = testSegment.copyWith(pathPoints: []);
      
      expect(emptySegment.pathLength, 0.0);
      expect(emptySegment.getPointAtPercentage(0.5), Vector2.zero());
    });

    test('should handle single path point', () {
      final singlePointSegment = testSegment.copyWith(
        pathPoints: [Vector2(50, 50)],
      );
      
      expect(singlePointSegment.pathLength, 0.0);
      
      final point = singlePointSegment.getPointAtPercentage(0.5);
      expect(point.x, 50.0);
      expect(point.y, 50.0);
    });

    test('should get point at percentage correctly', () {
      // At 0% - should be start point
      final startPoint = testSegment.getPointAtPercentage(0.0);
      expect(startPoint.x, closeTo(0, 0.1));
      expect(startPoint.y, closeTo(0, 0.1));
      
      // At 100% - should be end point
      final endPoint = testSegment.getPointAtPercentage(1.0);
      expect(endPoint.x, closeTo(200, 0.1));
      expect(endPoint.y, closeTo(100, 0.1));
      
      // At 33.33% - should be at (100, 0)
      final oneThirdPoint = testSegment.getPointAtPercentage(1/3);
      expect(oneThirdPoint.x, closeTo(100, 5));
      expect(oneThirdPoint.y, closeTo(0, 5));
      
      // At 66.66% - should be at (100, 100)
      final twoThirdPoint = testSegment.getPointAtPercentage(2/3);
      expect(twoThirdPoint.x, closeTo(100, 5));
      expect(twoThirdPoint.y, closeTo(100, 5));
    });

    test('should clamp percentage to valid range', () {
      final beforeStart = testSegment.getPointAtPercentage(-0.5);
      final afterEnd = testSegment.getPointAtPercentage(1.5);
      
      expect(beforeStart.x, closeTo(0, 0.1));
      expect(beforeStart.y, closeTo(0, 0.1));
      
      expect(afterEnd.x, closeTo(200, 0.1));
      expect(afterEnd.y, closeTo(100, 0.1));
    });

    test('should create copy with updated values', () {
      final updatedSegment = testSegment.copyWith(
        completionPercentage: 0.8,
        pathPoints: [Vector2(0, 0), Vector2(50, 50)],
      );
      
      expect(updatedSegment.completionPercentage, 0.8);
      expect(updatedSegment.pathPoints.length, 2);
      expect(updatedSegment.id, testSegment.id); // Unchanged
      expect(updatedSegment.category, testSegment.category); // Unchanged
    });
  });

  group('NodeVisualState', () {
    test('should have all required states', () {
      expect(NodeVisualState.values.length, 4);
      expect(NodeVisualState.values, contains(NodeVisualState.locked));
      expect(NodeVisualState.values, contains(NodeVisualState.inProgress));
      expect(NodeVisualState.values, contains(NodeVisualState.unlocked));
      expect(NodeVisualState.values, contains(NodeVisualState.rewardAvailable));
    });
  });

  group('PathLayoutConfig', () {
    test('should create responsive config for portrait screen', () {
      const portraitSize = Size(400, 800);
      final config = PathLayoutConfig.responsive(portraitSize);
      
      expect(config.isHorizontalLayout, isFalse);
      expect(config.nodeSize, greaterThanOrEqualTo(44.0)); // Minimum touch target
      expect(config.pathSpacing, greaterThan(0));
      expect(config.branchAngle, greaterThan(0));
    });

    test('should create responsive config for landscape screen', () {
      const landscapeSize = Size(800, 400);
      final config = PathLayoutConfig.responsive(landscapeSize);
      
      expect(config.isHorizontalLayout, isTrue);
      expect(config.nodeSize, greaterThanOrEqualTo(44.0)); // Minimum touch target
      expect(config.pathSpacing, greaterThan(0));
      expect(config.branchAngle, greaterThan(0));
    });

    test('should scale elements based on screen size', () {
      const smallSize = Size(200, 400);
      const largeSize = Size(800, 1600);
      
      final smallConfig = PathLayoutConfig.responsive(smallSize);
      final largeConfig = PathLayoutConfig.responsive(largeSize);
      
      expect(largeConfig.nodeSize, greaterThan(smallConfig.nodeSize));
      expect(largeConfig.pathSpacing, greaterThan(smallConfig.pathSpacing));
      expect(largeConfig.minNodeSpacing, greaterThan(smallConfig.minNodeSpacing));
    });

    test('should calculate effective screen size correctly', () {
      const screenSize = Size(400, 800);
      final config = PathLayoutConfig.responsive(screenSize);
      
      final effectiveSize = config.getEffectiveScreenSize(screenSize);
      
      expect(effectiveSize.width, screenSize.width - config.screenPadding.horizontal);
      expect(effectiveSize.height, screenSize.height - config.screenPadding.vertical);
      expect(effectiveSize.width, lessThan(screenSize.width));
      expect(effectiveSize.height, lessThan(screenSize.height));
    });

    test('should handle edge case screen sizes', () {
      // Very small screen
      const tinySize = Size(100, 200);
      final tinyConfig = PathLayoutConfig.responsive(tinySize);
      
      expect(tinyConfig.nodeSize, greaterThan(0));
      expect(tinyConfig.pathSpacing, greaterThan(0));
      
      // Very large screen
      const hugeSize = Size(2000, 4000);
      final hugeConfig = PathLayoutConfig.responsive(hugeSize);
      
      expect(hugeConfig.nodeSize, lessThanOrEqualTo(250)); // Should have reasonable upper bound
      expect(hugeConfig.pathSpacing, lessThanOrEqualTo(600)); // Should have reasonable upper bound
    });
  });

  group('BranchConfig', () {
    test('should create valid branch configuration', () {
      const config = BranchConfig(
        type: AchievementType.pulseUsage,
        neonColor: Colors.yellow,
        width: 5.0,
        angle: math.pi / 4,
        length: 75.0,
        priority: 3,
      );
      
      expect(config.type, AchievementType.pulseUsage);
      expect(config.neonColor, Colors.yellow);
      expect(config.width, 5.0);
      expect(config.angle, math.pi / 4);
      expect(config.length, 75.0);
      expect(config.priority, 3);
    });
  });

  group('BranchingLogic', () {
    late BranchingLogic branchingLogic;

    setUp(() {
      branchingLogic = BranchingLogic.defaultConfig();
    });

    test('should create default configuration with all achievement types', () {
      expect(branchingLogic.branchConfigs.length, AchievementType.values.length);
      
      for (final type in AchievementType.values) {
        final config = branchingLogic.getBranchConfig(type);
        expect(config, isNotNull);
        expect(config!.type, type);
      }
    });

    test('should identify main path correctly', () {
      expect(branchingLogic.isMainPath(AchievementType.score), isTrue);
      expect(branchingLogic.isMainPath(AchievementType.pulseUsage), isFalse);
      expect(branchingLogic.isMainPath(AchievementType.totalScore), isFalse);
    });

    test('should sort branch types by priority', () {
      final sortedTypes = branchingLogic.getBranchTypesByPriority();
      
      expect(sortedTypes, isNotEmpty);
      expect(sortedTypes.first, AchievementType.score); // Should be priority 0
      
      // Check that priorities are in ascending order
      for (int i = 1; i < sortedTypes.length; i++) {
        final prevConfig = branchingLogic.getBranchConfig(sortedTypes[i - 1])!;
        final currentConfig = branchingLogic.getBranchConfig(sortedTypes[i])!;
        expect(currentConfig.priority, greaterThanOrEqualTo(prevConfig.priority));
      }
    });

    test('should calculate branch path points', () {
      final layoutConfig = PathLayoutConfig.responsive(const Size(400, 800));
      final startPoint = Vector2(100, 100);
      
      final branchPath = branchingLogic.calculateBranchPath(
        startPoint,
        AchievementType.pulseUsage,
        layoutConfig,
      );
      
      expect(branchPath, isNotEmpty);
      expect(branchPath.first, startPoint);
      expect(branchPath.length, greaterThan(1));
      
      // Branch should extend away from start point
      final endPoint = branchPath.last;
      final distance = endPoint.distanceTo(startPoint);
      expect(distance, greaterThan(0));
    });

    test('should handle unknown achievement type', () {
      // Create a custom branching logic without all types
      final customLogic = BranchingLogic(branchConfigs: {
        AchievementType.score: const BranchConfig(
          type: AchievementType.score,
          neonColor: Colors.pink,
          width: 8.0,
          angle: 0.0,
          length: 100.0,
          priority: 0,
        ),
      });
      
      expect(customLogic.getBranchConfig(AchievementType.pulseUsage), isNull);
      
      final layoutConfig = PathLayoutConfig.responsive(const Size(400, 800));
      final branchPath = customLogic.calculateBranchPath(
        Vector2(100, 100),
        AchievementType.pulseUsage,
        layoutConfig,
      );
      
      // Should return just the start point for unknown types
      expect(branchPath.length, 1);
      expect(branchPath.first, Vector2(100, 100));
    });

    test('should create smooth curved branches', () {
      final layoutConfig = PathLayoutConfig.responsive(const Size(400, 800));
      final startPoint = Vector2(100, 100);
      
      final branchPath = branchingLogic.calculateBranchPath(
        startPoint,
        AchievementType.totalScore,
        layoutConfig,
      );
      
      expect(branchPath.length, greaterThan(2)); // Should have multiple segments for curves
      
      // Check that points are not in a straight line (indicating curves)
      if (branchPath.length >= 3) {
        final firstSegment = branchPath[1] - branchPath[0];
        final secondSegment = branchPath[2] - branchPath[1];
        
        // Vectors should not be parallel (indicating curve)
        final crossProduct = firstSegment.x * secondSegment.y - firstSegment.y * secondSegment.x;
        expect(crossProduct.abs(), greaterThan(0.1)); // Some curve should be present
      }
    });

    test('should scale branch length with node size', () {
      final smallLayoutConfig = PathLayoutConfig(
        isHorizontalLayout: false,
        pathSpacing: 100,
        nodeSize: 22, // Half the standard size
        branchAngle: math.pi / 4,
        screenPadding: const EdgeInsets.all(20),
      );
      
      final largeLayoutConfig = PathLayoutConfig(
        isHorizontalLayout: false,
        pathSpacing: 100,
        nodeSize: 88, // Double the standard size
        branchAngle: math.pi / 4,
        screenPadding: const EdgeInsets.all(20),
      );
      
      final startPoint = Vector2(100, 100);
      
      final smallBranch = branchingLogic.calculateBranchPath(
        startPoint,
        AchievementType.pulseUsage,
        smallLayoutConfig,
      );
      
      final largeBranch = branchingLogic.calculateBranchPath(
        startPoint,
        AchievementType.pulseUsage,
        largeLayoutConfig,
      );
      
      final smallLength = smallBranch.last.distanceTo(startPoint);
      final largeLength = largeBranch.last.distanceTo(startPoint);
      
      expect(largeLength, greaterThan(smallLength));
    });
  });

  group('NodePosition', () {
    late NodePosition testNodePosition;

    setUp(() {
      testNodePosition = NodePosition(
        position: Vector2(100, 200),
        achievementId: 'test_achievement',
        category: AchievementType.score,
        visualState: NodeVisualState.inProgress,
        pathProgress: 0.5,
        isOnMainPath: true,
      );
    });

    test('should create node position with all properties', () {
      expect(testNodePosition.position.x, 100);
      expect(testNodePosition.position.y, 200);
      expect(testNodePosition.achievementId, 'test_achievement');
      expect(testNodePosition.category, AchievementType.score);
      expect(testNodePosition.visualState, NodeVisualState.inProgress);
      expect(testNodePosition.pathProgress, 0.5);
      expect(testNodePosition.isOnMainPath, isTrue);
    });

    test('should create copy with updated values', () {
      final updatedPosition = testNodePosition.copyWith(
        position: Vector2(150, 250),
        visualState: NodeVisualState.unlocked,
        pathProgress: 0.8,
      );
      
      expect(updatedPosition.position.x, 150);
      expect(updatedPosition.position.y, 250);
      expect(updatedPosition.visualState, NodeVisualState.unlocked);
      expect(updatedPosition.pathProgress, 0.8);
      
      // Unchanged properties
      expect(updatedPosition.achievementId, testNodePosition.achievementId);
      expect(updatedPosition.category, testNodePosition.category);
      expect(updatedPosition.isOnMainPath, testNodePosition.isOnMainPath);
    });

    test('should handle edge case progress values', () {
      final startPosition = testNodePosition.copyWith(pathProgress: 0.0);
      final endPosition = testNodePosition.copyWith(pathProgress: 1.0);
      
      expect(startPosition.pathProgress, 0.0);
      expect(endPosition.pathProgress, 1.0);
    });
  });

  group('Integration Tests', () {
    test('should work together for complete path calculation', () {
      final branchingLogic = BranchingLogic.defaultConfig();
      final layoutConfig = PathLayoutConfig.responsive(const Size(400, 800));
      
      // Create a main path segment
      final mainPathPoints = [
        Vector2(200, 100),
        Vector2(200, 200),
        Vector2(200, 300),
        Vector2(200, 400),
      ];
      
      final mainSegment = PathSegment(
        id: 'main',
        category: AchievementType.score,
        pathPoints: mainPathPoints,
        neonColor: Colors.pink,
        width: 8.0,
        isMainPath: true,
        completionPercentage: 0.5,
        achievementIds: ['score_1', 'score_2'],
      );
      
      // Create branch from main path
      final branchStartPoint = mainSegment.getPointAtPercentage(0.33);
      final branchPath = branchingLogic.calculateBranchPath(
        branchStartPoint,
        AchievementType.pulseUsage,
        layoutConfig,
      );
      
      expect(branchPath, isNotEmpty);
      expect(branchPath.first, branchStartPoint);
      
      // Create node positions along paths
      final mainNodePosition = NodePosition(
        position: mainSegment.getPointAtPercentage(0.5),
        achievementId: 'score_1',
        category: AchievementType.score,
        visualState: NodeVisualState.unlocked,
        pathProgress: 0.5,
        isOnMainPath: true,
      );
      
      final branchNodePosition = NodePosition(
        position: branchPath.last,
        achievementId: 'pulse_1',
        category: AchievementType.pulseUsage,
        visualState: NodeVisualState.locked,
        pathProgress: 1.0,
        isOnMainPath: false,
      );
      
      expect(mainNodePosition.isOnMainPath, isTrue);
      expect(branchNodePosition.isOnMainPath, isFalse);
      expect(mainNodePosition.category, AchievementType.score);
      expect(branchNodePosition.category, AchievementType.pulseUsage);
    });
  });
}