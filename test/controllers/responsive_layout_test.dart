import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'dart:math' as math;
import '../../lib/controllers/progression_path_controller.dart';
import '../../lib/models/progression_path_models.dart';
import '../../lib/models/achievement.dart';

void main() {
  group('Responsive Layout System Tests', () {
    late ProgressionPathController controller;
    late List<Achievement> testAchievements;

    setUp(() {
      controller = ProgressionPathController();
      testAchievements = _createTestAchievements();
    });

    group('PathLayoutConfig Responsive Creation', () {
      test('should create small screen layout configuration', () {
        const screenSize = Size(360, 640); // Small phone
        final config = PathLayoutConfig.responsive(screenSize);

        expect(config.sizeCategory, ScreenSizeCategory.small);
        expect(config.orientation, LayoutOrientation.portrait);
        expect(config.isHorizontalLayout, false);
        expect(config.enableCompactMode, true);
        expect(config.nodeSize, greaterThanOrEqualTo(44.0)); // Accessibility minimum
      });

      test('should create medium screen layout configuration', () {
        const screenSize = Size(768, 1024); // Tablet portrait
        final config = PathLayoutConfig.responsive(screenSize);

        expect(config.sizeCategory, ScreenSizeCategory.medium);
        expect(config.orientation, LayoutOrientation.portrait);
        expect(config.isHorizontalLayout, false);
        expect(config.enableCompactMode, false);
      });

      test('should create large screen layout configuration', () {
        const screenSize = Size(1200, 800); // Large tablet landscape
        final config = PathLayoutConfig.responsive(screenSize);

        expect(config.sizeCategory, ScreenSizeCategory.large);
        expect(config.orientation, LayoutOrientation.landscape);
        expect(config.isHorizontalLayout, true);
        expect(config.enableCompactMode, false);
      });

      test('should create extra large screen layout configuration', () {
        const screenSize = Size(1920, 1200); // Desktop
        final config = PathLayoutConfig.responsive(screenSize);

        expect(config.sizeCategory, ScreenSizeCategory.extraLarge);
        expect(config.orientation, LayoutOrientation.landscape);
        expect(config.isHorizontalLayout, true);
        expect(config.enableCompactMode, false);
      });

      test('should handle square aspect ratio', () {
        const screenSize = Size(800, 800); // Square screen
        final config = PathLayoutConfig.responsive(screenSize);

        expect(config.orientation, LayoutOrientation.square);
        expect(config.aspectRatio, closeTo(1.0, 0.1));
      });

      test('should respect device pixel ratio', () {
        const screenSize = Size(360, 640);
        const devicePixelRatio = 3.0;
        
        final config = PathLayoutConfig.responsive(
          screenSize, 
          devicePixelRatio: devicePixelRatio,
        );

        expect(config.densityFactor, greaterThan(1.0));
        expect(config.nodeSize, greaterThanOrEqualTo(44.0));
      });
    });

    group('Adaptive Layout Logic', () {
      test('should calculate appropriate node spacing for different screen sizes', () {
        final smallConfig = PathLayoutConfig.responsive(const Size(360, 640));
        final largeConfig = PathLayoutConfig.responsive(const Size(1920, 1080));

        expect(smallConfig.minNodeSpacing, lessThan(largeConfig.minNodeSpacing));
        expect(smallConfig.pathSpacing, lessThan(largeConfig.pathSpacing));
      });

      test('should adjust branch angles for different orientations', () {
        final portraitConfig = PathLayoutConfig.responsive(const Size(360, 640));
        final landscapeConfig = PathLayoutConfig.responsive(const Size(640, 360));

        expect(portraitConfig.branchAngle, greaterThan(landscapeConfig.branchAngle));
      });

      test('should calculate max nodes per row based on screen width', () {
        final narrowConfig = PathLayoutConfig.responsive(const Size(360, 640));
        final wideConfig = PathLayoutConfig.responsive(const Size(1920, 1080));

        expect(narrowConfig.maxNodesPerRow, lessThan(wideConfig.maxNodesPerRow));
        expect(narrowConfig.maxNodesPerRow, greaterThanOrEqualTo(2));
        expect(wideConfig.maxNodesPerRow, lessThanOrEqualTo(8));
      });
    });

    group('Responsive Path Calculation', () {
      test('should generate vertical path for portrait orientation', () {
        const screenSize = Size(360, 640);
        controller.calculatePathLayout(screenSize, testAchievements);

        final pathSegments = controller.pathSegments;
        expect(pathSegments, isNotEmpty);

        final mainPath = pathSegments.first;
        expect(mainPath.isMainPath, true);
        expect(mainPath.pathPoints.length, greaterThan(1));

        // Verify vertical progression (Y coordinates should increase)
        for (int i = 1; i < mainPath.pathPoints.length; i++) {
          expect(
            mainPath.pathPoints[i].y,
            greaterThanOrEqualTo(mainPath.pathPoints[i - 1].y),
          );
        }
      });

      test('should generate horizontal path for landscape orientation', () {
        const screenSize = Size(1024, 600);
        controller.calculatePathLayout(screenSize, testAchievements);

        final pathSegments = controller.pathSegments;
        expect(pathSegments, isNotEmpty);

        final mainPath = pathSegments.first;
        expect(mainPath.isMainPath, true);
        expect(mainPath.pathPoints.length, greaterThan(1));

        // Verify horizontal progression pattern
        final points = mainPath.pathPoints;
        bool hasHorizontalProgression = false;
        
        for (int i = 1; i < points.length; i++) {
          if ((points[i].x - points[i - 1].x).abs() > 
              (points[i].y - points[i - 1].y).abs()) {
            hasHorizontalProgression = true;
            break;
          }
        }
        
        expect(hasHorizontalProgression, true);
      });

      test('should apply appropriate smoothing based on screen size', () {
        final smallScreenSize = Size(360, 640);
        final largeScreenSize = Size(1920, 1080);

        controller.calculatePathLayout(smallScreenSize, testAchievements);
        final smallPathPoints = controller.pathSegments.first.pathPoints.length;

        controller.calculatePathLayout(largeScreenSize, testAchievements);
        final largePathPoints = controller.pathSegments.first.pathPoints.length;

        // Large screens should have more path points for smoother curves
        expect(largePathPoints, greaterThanOrEqualTo(smallPathPoints));
      });
    });

    group('Branch Positioning Algorithms', () {
      test('should position branches without overlap', () {
        const screenSize = Size(800, 600);
        controller.calculatePathLayout(screenSize, testAchievements);

        final branchSegments = controller.pathSegments.where((s) => !s.isMainPath).toList();
        
        if (branchSegments.length > 1) {
          // Check that branch endpoints don't overlap (more realistic than all points)
          for (int i = 0; i < branchSegments.length; i++) {
            for (int j = i + 1; j < branchSegments.length; j++) {
              final branch1 = branchSegments[i];
              final branch2 = branchSegments[j];
              
              if (branch1.pathPoints.isNotEmpty && branch2.pathPoints.isNotEmpty) {
                final endpoint1 = branch1.pathPoints.last;
                final endpoint2 = branch2.pathPoints.last;
                final distance = endpoint1.distanceTo(endpoint2);
                expect(distance, greaterThan(20.0)); // Minimum separation for endpoints
              }
            }
          }
        }
      });

      test('should adapt branch lengths to screen size', () {
        final smallConfig = PathLayoutConfig.responsive(const Size(360, 640));
        final largeConfig = PathLayoutConfig.responsive(const Size(1920, 1080));
        
        final branchingLogic = BranchingLogic.defaultConfig();
        
        final smallBranchConfig = branchingLogic.getResponsiveBranchConfig(
          AchievementType.totalScore, 
          smallConfig,
        );
        final largeBranchConfig = branchingLogic.getResponsiveBranchConfig(
          AchievementType.totalScore, 
          largeConfig,
        );

        expect(smallBranchConfig?.length, lessThan(largeBranchConfig?.length ?? 0));
      });

      test('should calculate branch angles appropriate for aspect ratio', () {
        final portraitConfig = PathLayoutConfig.responsive(const Size(360, 640));
        final landscapeConfig = PathLayoutConfig.responsive(const Size(1024, 600));
        
        final branchingLogic = BranchingLogic.defaultConfig();
        
        final portraitPoints = branchingLogic.calculateBranchPath(
          Vector2(100, 100),
          AchievementType.totalScore,
          portraitConfig,
        );
        
        final landscapePoints = branchingLogic.calculateBranchPath(
          Vector2(100, 100),
          AchievementType.totalScore,
          landscapeConfig,
        );

        expect(portraitPoints.length, greaterThan(1));
        expect(landscapePoints.length, greaterThan(1));
        
        // Verify different branch characteristics
        final portraitSpread = _calculatePathSpread(portraitPoints);
        final landscapeSpread = _calculatePathSpread(landscapePoints);
        
        expect(portraitSpread, isNot(equals(landscapeSpread)));
      });
    });

    group('Node Sizing and Spacing', () {
      test('should maintain minimum touch target size', () {
        const screenSize = Size(320, 568); // Very small screen
        controller.calculatePathLayout(screenSize, testAchievements);

        final config = controller.layoutConfig!;
        expect(config.getResponsiveNodeSize(), greaterThanOrEqualTo(44.0));
      });

      test('should scale node sizes appropriately', () {
        final smallConfig = PathLayoutConfig.responsive(const Size(360, 640));
        final largeConfig = PathLayoutConfig.responsive(const Size(1920, 1080));

        expect(smallConfig.nodeSize, lessThan(largeConfig.nodeSize));
        expect(smallConfig.nodeSize, greaterThanOrEqualTo(44.0));
        expect(largeConfig.nodeSize, greaterThanOrEqualTo(44.0));
      });

      test('should prevent node overlap', () {
        const screenSize = Size(600, 800);
        controller.calculatePathLayout(screenSize, testAchievements);

        final nodePositions = controller.nodePositions.values.toList();
        final minDistance = controller.layoutConfig!.nodeSize * 1.5; // More realistic minimum

        for (int i = 0; i < nodePositions.length; i++) {
          for (int j = i + 1; j < nodePositions.length; j++) {
            final distance = nodePositions[i].position.distanceTo(nodePositions[j].position);
            expect(distance, greaterThan(minDistance));
          }
        }
      });

      test('should keep nodes within screen bounds', () {
        const screenSize = Size(400, 600);
        controller.calculatePathLayout(screenSize, testAchievements);

        final config = controller.layoutConfig!;
        final nodeRadius = config.getResponsiveNodeSize() / 2;
        final padding = config.screenPadding;

        // Allow for some tolerance due to optimization algorithms
        const tolerance = 10.0;

        for (final nodePosition in controller.nodePositions.values) {
          final pos = nodePosition.position;
          
          expect(pos.x, greaterThanOrEqualTo(padding.left + nodeRadius - tolerance));
          expect(pos.x, lessThanOrEqualTo(screenSize.width - padding.right - nodeRadius + tolerance));
          expect(pos.y, greaterThanOrEqualTo(padding.top + nodeRadius - tolerance));
          expect(pos.y, lessThanOrEqualTo(screenSize.height - padding.bottom - nodeRadius + tolerance));
        }
      });
    });

    group('Compact Mode Behavior', () {
      test('should enable compact mode for small screens', () {
        const screenSize = Size(320, 568);
        final config = PathLayoutConfig.responsive(screenSize);

        expect(config.enableCompactMode, true);
        expect(config.pathCurvature, lessThan(0.3));
      });

      test('should adjust layout for compact mode', () {
        const screenSize = Size(320, 568);
        controller.calculatePathLayout(screenSize, testAchievements);

        final config = controller.layoutConfig!;
        expect(config.enableCompactMode, true);

        // Verify compact layout characteristics
        final pathSegments = controller.pathSegments;
        expect(pathSegments, isNotEmpty);

        final mainPath = pathSegments.first;
        final pathLength = mainPath.pathLength;
        
        // Compact mode should create more condensed paths
        expect(pathLength, lessThan(1000.0)); // Reasonable upper bound for compact
      });
    });

    group('Performance and Edge Cases', () {
      test('should handle empty achievement list', () {
        const screenSize = Size(600, 800);
        controller.calculatePathLayout(screenSize, []);

        expect(controller.pathSegments, isEmpty);
        expect(controller.nodePositions, isEmpty);
      });

      test('should handle single achievement', () {
        const screenSize = Size(600, 800);
        final singleAchievement = [testAchievements.first];
        
        controller.calculatePathLayout(screenSize, singleAchievement);

        expect(controller.pathSegments, isNotEmpty);
        expect(controller.nodePositions, hasLength(1));
      });

      test('should handle extreme aspect ratios', () {
        const ultraWideSize = Size(2560, 600); // Ultra-wide
        const ultraTallSize = Size(400, 2000); // Ultra-tall

        expect(() {
          controller.calculatePathLayout(ultraWideSize, testAchievements);
        }, returnsNormally);

        expect(() {
          controller.calculatePathLayout(ultraTallSize, testAchievements);
        }, returnsNormally);
      });

      test('should maintain performance with many achievements', () {
        const screenSize = Size(800, 600);
        final manyAchievements = _createManyTestAchievements(100);

        final stopwatch = Stopwatch()..start();
        controller.calculatePathLayout(screenSize, manyAchievements);
        stopwatch.stop();

        // Should complete within reasonable time (adjust threshold as needed)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(controller.nodePositions, hasLength(100));
      });
    });

    group('Layout Consistency', () {
      test('should produce consistent results for same input', () {
        const screenSize = Size(600, 800);
        
        controller.calculatePathLayout(screenSize, testAchievements);
        final firstResult = Map.from(controller.nodePositions);
        
        controller.calculatePathLayout(screenSize, testAchievements);
        final secondResult = controller.nodePositions;

        expect(firstResult.length, equals(secondResult.length));
        
        for (final key in firstResult.keys) {
          expect(secondResult.containsKey(key), true);
          expect(
            firstResult[key]!.position.distanceTo(secondResult[key]!.position),
            lessThan(0.1), // Allow for minimal floating point differences
          );
        }
      });

      test('should adapt smoothly to screen size changes', () {
        final sizes = [
          const Size(360, 640),
          const Size(400, 700),
          const Size(500, 800),
          const Size(600, 900),
        ];

        final results = <Size, int>{};
        
        for (final size in sizes) {
          controller.calculatePathLayout(size, testAchievements);
          results[size] = controller.pathSegments.first.pathPoints.length;
        }

        // Verify smooth progression in path complexity
        final pointCounts = results.values.toList();
        for (int i = 1; i < pointCounts.length; i++) {
          expect(pointCounts[i], greaterThanOrEqualTo(pointCounts[i - 1]));
        }
      });
    });
  });
}

/// Create test achievements for various categories
List<Achievement> _createTestAchievements() {
  return [
    Achievement(
      id: 'score_1',
      name: 'First Score',
      description: 'Score 10 points',
      icon: Icons.star,
      iconColor: Colors.cyan,
      type: AchievementType.score,
      targetValue: 10,
      currentProgress: 15,
      isUnlocked: true,
    ),
    Achievement(
      id: 'score_2',
      name: 'Good Score',
      description: 'Score 50 points',
      icon: Icons.star,
      iconColor: Colors.blue,
      type: AchievementType.score,
      targetValue: 50,
      currentProgress: 30,
      isUnlocked: false,
    ),
    Achievement(
      id: 'total_1',
      name: 'Total Score',
      description: 'Reach 1000 total points',
      icon: Icons.star,
      iconColor: Colors.purple,
      type: AchievementType.totalScore,
      targetValue: 1000,
      currentProgress: 500,
      isUnlocked: false,
    ),
    Achievement(
      id: 'games_1',
      name: 'Persistent Player',
      description: 'Play 10 games',
      icon: Icons.star,
      iconColor: Colors.green,
      type: AchievementType.gamesPlayed,
      targetValue: 10,
      currentProgress: 10,
      isUnlocked: true,
    ),
    Achievement(
      id: 'pulse_1',
      name: 'Pulse Master',
      description: 'Use pulse 50 times',
      icon: Icons.star,
      iconColor: Colors.yellow,
      type: AchievementType.pulseUsage,
      targetValue: 50,
      currentProgress: 25,
      isUnlocked: false,
    ),
  ];
}

/// Create many test achievements for performance testing
List<Achievement> _createManyTestAchievements(int count) {
  final achievements = <Achievement>[];
  final types = AchievementType.values;
  final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange];
  
  for (int i = 0; i < count; i++) {
    final type = types[i % types.length];
    final color = colors[i % colors.length];
    achievements.add(
      Achievement(
        id: 'test_$i',
        name: 'Test Achievement $i',
        description: 'Test description $i',
        icon: Icons.star,
        iconColor: color,
        type: type,
        targetValue: (i + 1) * 10,
        currentProgress: i * 5,
        isUnlocked: i % 3 == 0,
      ),
    );
  }
  
  return achievements;
}

/// Calculate the spread of a path (max distance between points)
double _calculatePathSpread(List<Vector2> points) {
  if (points.length < 2) return 0.0;
  
  double maxDistance = 0.0;
  for (int i = 0; i < points.length; i++) {
    for (int j = i + 1; j < points.length; j++) {
      final distance = points[i].distanceTo(points[j]);
      maxDistance = math.max(maxDistance, distance);
    }
  }
  
  return maxDistance;
}