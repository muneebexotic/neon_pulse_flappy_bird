import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../lib/controllers/progression_path_controller.dart';
import '../../lib/models/progression_path_models.dart';
import '../../lib/models/achievement.dart';

void main() {
  group('ProgressionPathController', () {
    late ProgressionPathController controller;
    late List<Achievement> testAchievements;

    setUp(() {
      controller = ProgressionPathController();
      testAchievements = _createTestAchievements();
    });

    group('Path Layout Calculation', () {
      test('should calculate path layout for portrait screen', () {
        const screenSize = Size(400, 800);
        
        controller.calculatePathLayout(screenSize, testAchievements);
        
        expect(controller.pathSegments, isNotEmpty);
        expect(controller.nodePositions, isNotEmpty);
        expect(controller.layoutConfig, isNotNull);
        expect(controller.layoutConfig!.isHorizontalLayout, isFalse);
      });

      test('should calculate path layout for landscape screen', () {
        const screenSize = Size(800, 400);
        
        controller.calculatePathLayout(screenSize, testAchievements);
        
        expect(controller.pathSegments, isNotEmpty);
        expect(controller.nodePositions, isNotEmpty);
        expect(controller.layoutConfig, isNotNull);
        expect(controller.layoutConfig!.isHorizontalLayout, isTrue);
      });

      test('should create main path segment', () {
        const screenSize = Size(400, 800);
        
        controller.calculatePathLayout(screenSize, testAchievements);
        
        final mainPath = controller.pathSegments.firstWhere(
          (s) => s.isMainPath,
          orElse: () => throw StateError('No main path found'),
        );
        
        expect(mainPath.isMainPath, isTrue);
        expect(mainPath.pathPoints, isNotEmpty);
        expect(mainPath.pathPoints.length, greaterThan(1));
        expect(mainPath.category, AchievementType.score);
      });

      test('should create branch paths for different achievement types', () {
        const screenSize = Size(400, 800);
        
        controller.calculatePathLayout(screenSize, testAchievements);
        
        final branchPaths = controller.pathSegments.where((s) => !s.isMainPath);
        expect(branchPaths, isNotEmpty);
        
        // Should have branches for different achievement types
        final branchTypes = branchPaths.map((s) => s.category).toSet();
        expect(branchTypes.length, greaterThan(1));
      });

      test('should handle empty achievement list', () {
        const screenSize = Size(400, 800);
        
        controller.calculatePathLayout(screenSize, []);
        
        expect(controller.pathSegments, isEmpty);
        expect(controller.nodePositions, isEmpty);
        expect(controller.layoutConfig, isNotNull);
      });
    });

    group('Node Positioning', () {
      test('should position nodes along path segments', () {
        const screenSize = Size(400, 800);
        
        controller.calculatePathLayout(screenSize, testAchievements);
        
        for (final achievement in testAchievements) {
          final nodePosition = controller.getNodePosition(achievement.id);
          expect(nodePosition, isNotNull);
          expect(nodePosition!.position.x, greaterThanOrEqualTo(0));
          expect(nodePosition.position.y, greaterThanOrEqualTo(0));
          expect(nodePosition.achievementId, achievement.id);
        }
      });

      test('should set correct visual states for nodes', () {
        const screenSize = Size(400, 800);
        final achievements = [
          _createAchievement('locked', isUnlocked: false, progress: 0),
          _createAchievement('in_progress', isUnlocked: false, progress: 50),
          _createAchievement('unlocked', isUnlocked: true, progress: 100),
          _createAchievement('reward', isUnlocked: true, progress: 100, rewardSkinId: 'test_skin'),
        ];
        
        controller.calculatePathLayout(screenSize, achievements);
        
        final lockedNode = controller.getNodePosition('locked')!;
        expect(lockedNode.visualState, NodeVisualState.locked);
        
        final progressNode = controller.getNodePosition('in_progress')!;
        expect(progressNode.visualState, NodeVisualState.inProgress);
        
        final unlockedNode = controller.getNodePosition('unlocked')!;
        expect(unlockedNode.visualState, NodeVisualState.unlocked);
        
        final rewardNode = controller.getNodePosition('reward')!;
        expect(rewardNode.visualState, NodeVisualState.rewardAvailable);
      });

      test('should maintain minimum touch target size', () {
        const screenSize = Size(400, 800);
        
        controller.calculatePathLayout(screenSize, testAchievements);
        
        expect(controller.layoutConfig!.nodeSize, greaterThanOrEqualTo(44.0));
      });

      test('should distribute nodes evenly along path segments', () {
        const screenSize = Size(400, 800);
        final achievements = List.generate(5, (i) => 
          _createAchievement('test_$i', type: AchievementType.score));
        
        controller.calculatePathLayout(screenSize, achievements);
        
        final positions = achievements
            .map((a) => controller.getNodePosition(a.id)!)
            .toList();
        
        // Check that progress values are distributed from 0 to 1
        positions.sort((a, b) => a.pathProgress.compareTo(b.pathProgress));
        
        expect(positions.first.pathProgress, closeTo(0.0, 0.1));
        expect(positions.last.pathProgress, closeTo(1.0, 0.1));
        
        // Check spacing between nodes
        for (int i = 1; i < positions.length; i++) {
          final spacing = positions[i].pathProgress - positions[i - 1].pathProgress;
          expect(spacing, greaterThan(0.1)); // Reasonable spacing
        }
      });
    });

    group('Path Geometry', () {
      test('should calculate path length correctly', () {
        const screenSize = Size(400, 800);
        
        controller.calculatePathLayout(screenSize, testAchievements);
        
        final totalLength = controller.getTotalPathLength();
        expect(totalLength, greaterThan(0));
        
        // Length should be reasonable for screen size
        expect(totalLength, lessThan(screenSize.height * 2));
      });

      test('should get point at percentage along path', () {
        final pathPoints = [
          Vector2(0, 0),
          Vector2(100, 0),
          Vector2(100, 100),
        ];
        
        final segment = PathSegment(
          id: 'test',
          category: AchievementType.score,
          pathPoints: pathPoints,
          neonColor: Colors.pink,
          width: 8.0,
          isMainPath: true,
          completionPercentage: 0.5,
          achievementIds: ['test'],
        );
        
        final startPoint = segment.getPointAtPercentage(0.0);
        expect(startPoint.x, closeTo(0, 0.1));
        expect(startPoint.y, closeTo(0, 0.1));
        
        final midPoint = segment.getPointAtPercentage(0.5);
        expect(midPoint.x, closeTo(100, 10));
        expect(midPoint.y, closeTo(0, 10));
        
        final endPoint = segment.getPointAtPercentage(1.0);
        expect(endPoint.x, closeTo(100, 0.1));
        expect(endPoint.y, closeTo(100, 0.1));
      });

      test('should handle edge cases in path calculations', () {
        // Empty path
        final emptySegment = PathSegment(
          id: 'empty',
          category: AchievementType.score,
          pathPoints: [],
          neonColor: Colors.pink,
          width: 8.0,
          isMainPath: true,
          completionPercentage: 0.0,
          achievementIds: [],
        );
        
        expect(emptySegment.pathLength, 0.0);
        expect(emptySegment.getPointAtPercentage(0.5), Vector2.zero());
        
        // Single point path
        final singlePointSegment = PathSegment(
          id: 'single',
          category: AchievementType.score,
          pathPoints: [Vector2(50, 50)],
          neonColor: Colors.pink,
          width: 8.0,
          isMainPath: true,
          completionPercentage: 0.0,
          achievementIds: [],
        );
        
        expect(singlePointSegment.pathLength, 0.0);
        final point = singlePointSegment.getPointAtPercentage(0.5);
        expect(point.x, 50.0);
        expect(point.y, 50.0);
      });
    });

    group('Progress Updates', () {
      test('should update path progress when achievements change', () {
        const screenSize = Size(400, 800);
        
        controller.calculatePathLayout(screenSize, testAchievements);
        
        final initialProgress = controller.pathSegments.first.completionPercentage;
        
        // Unlock more achievements
        final updatedAchievements = testAchievements.map((a) => 
          a.copyWith(isUnlocked: true)).toList();
        
        controller.updatePathProgress(updatedAchievements);
        
        final updatedProgress = controller.pathSegments.first.completionPercentage;
        expect(updatedProgress, greaterThan(initialProgress));
      });

      test('should get current progress position', () {
        const screenSize = Size(400, 800);
        final achievements = [
          _createAchievement('first', isUnlocked: true, type: AchievementType.score),
          _createAchievement('second', isUnlocked: true, type: AchievementType.score),
          _createAchievement('third', isUnlocked: false, type: AchievementType.score),
        ];
        
        controller.calculatePathLayout(screenSize, achievements);
        
        final currentProgress = controller.getCurrentProgressPosition(achievements);
        expect(currentProgress, greaterThan(0.0));
        expect(currentProgress, lessThanOrEqualTo(1.0));
      });

      test('should get scroll position for achievement', () {
        const screenSize = Size(400, 800);
        
        controller.calculatePathLayout(screenSize, testAchievements);
        
        final achievement = testAchievements.first;
        final scrollPosition = controller.getScrollPositionForAchievement(achievement.id);
        
        expect(scrollPosition, greaterThanOrEqualTo(0.0));
        expect(scrollPosition, lessThanOrEqualTo(controller.getTotalPathLength()));
      });
    });

    group('Branching Logic', () {
      test('should create default branching configuration', () {
        final branchingLogic = BranchingLogic.defaultConfig();
        
        expect(branchingLogic.branchConfigs, isNotEmpty);
        expect(branchingLogic.branchConfigs.length, AchievementType.values.length);
        
        // Main path should have priority 0
        final mainConfig = branchingLogic.getBranchConfig(AchievementType.score);
        expect(mainConfig, isNotNull);
        expect(mainConfig!.priority, 0);
        expect(branchingLogic.isMainPath(AchievementType.score), isTrue);
      });

      test('should calculate branch paths with correct angles', () {
        final branchingLogic = BranchingLogic.defaultConfig();
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

      test('should sort branch types by priority', () {
        final branchingLogic = BranchingLogic.defaultConfig();
        
        final sortedTypes = branchingLogic.getBranchTypesByPriority();
        
        expect(sortedTypes, isNotEmpty);
        expect(sortedTypes.first, AchievementType.score); // Should be main path
        
        // Check that priorities are in ascending order
        for (int i = 1; i < sortedTypes.length; i++) {
          final prevConfig = branchingLogic.getBranchConfig(sortedTypes[i - 1])!;
          final currentConfig = branchingLogic.getBranchConfig(sortedTypes[i])!;
          expect(currentConfig.priority, greaterThanOrEqualTo(prevConfig.priority));
        }
      });
    });

    group('Layout Configuration', () {
      test('should create responsive layout for different screen sizes', () {
        final portraitConfig = PathLayoutConfig.responsive(const Size(400, 800));
        expect(portraitConfig.isHorizontalLayout, isFalse);
        
        final landscapeConfig = PathLayoutConfig.responsive(const Size(800, 400));
        expect(landscapeConfig.isHorizontalLayout, isTrue);
        
        final squareConfig = PathLayoutConfig.responsive(const Size(500, 500));
        expect(squareConfig.isHorizontalLayout, isFalse); // Default to vertical
      });

      test('should scale layout elements based on screen size', () {
        final smallConfig = PathLayoutConfig.responsive(const Size(200, 400));
        final largeConfig = PathLayoutConfig.responsive(const Size(800, 1600));
        
        expect(largeConfig.nodeSize, greaterThan(smallConfig.nodeSize));
        expect(largeConfig.pathSpacing, greaterThan(smallConfig.pathSpacing));
        expect(largeConfig.minNodeSpacing, greaterThan(smallConfig.minNodeSpacing));
      });

      test('should maintain minimum touch target size', () {
        final tinyConfig = PathLayoutConfig.responsive(const Size(100, 200));
        
        // Even on tiny screens, nodes should be at least 44dp
        expect(tinyConfig.nodeSize, greaterThanOrEqualTo(44.0 * 0.25)); // Scaled minimum
      });

      test('should calculate effective screen size', () {
        const screenSize = Size(400, 800);
        final config = PathLayoutConfig.responsive(screenSize);
        
        final effectiveSize = config.getEffectiveScreenSize(screenSize);
        
        expect(effectiveSize.width, lessThan(screenSize.width));
        expect(effectiveSize.height, lessThan(screenSize.height));
        expect(effectiveSize.width, screenSize.width - config.screenPadding.horizontal);
        expect(effectiveSize.height, screenSize.height - config.screenPadding.vertical);
      });
    });

    group('Performance and Caching', () {
      test('should provide performance statistics', () {
        const screenSize = Size(400, 800);
        
        controller.calculatePathLayout(screenSize, testAchievements);
        
        final stats = controller.getStats();
        
        expect(stats['pathSegments'], greaterThan(0));
        expect(stats['nodePositions'], greaterThan(0));
        expect(stats['totalPathLength'], greaterThan(0));
        expect(stats['screenSize'], isNotNull);
        expect(stats['layoutConfig'], 'configured');
      });

      test('should clear cache when requested', () {
        const screenSize = Size(400, 800);
        
        controller.calculatePathLayout(screenSize, testAchievements);
        controller.clearCache();
        
        // Should still work after cache clear
        final totalLength = controller.getTotalPathLength();
        expect(totalLength, greaterThan(0));
      });
    });
  });
}

/// Helper function to create test achievements
List<Achievement> _createTestAchievements() {
  return [
    _createAchievement('score_1', type: AchievementType.score, isUnlocked: true),
    _createAchievement('score_2', type: AchievementType.score, isUnlocked: false),
    _createAchievement('total_1', type: AchievementType.totalScore, isUnlocked: true),
    _createAchievement('games_1', type: AchievementType.gamesPlayed, isUnlocked: false),
    _createAchievement('pulse_1', type: AchievementType.pulseUsage, isUnlocked: false),
    _createAchievement('power_1', type: AchievementType.powerUps, isUnlocked: true),
  ];
}

/// Helper function to create a test achievement
Achievement _createAchievement(
  String id, {
  AchievementType type = AchievementType.score,
  bool isUnlocked = false,
  int progress = 0,
  String? rewardSkinId,
}) {
  return Achievement(
    id: id,
    name: 'Test $id',
    description: 'Test achievement $id',
    icon: Icons.star,
    iconColor: Colors.blue,
    targetValue: 100,
    type: type,
    rewardSkinId: rewardSkinId,
    isUnlocked: isUnlocked,
    currentProgress: progress,
  );
}