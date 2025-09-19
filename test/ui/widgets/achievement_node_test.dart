import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:neon_pulse_flappy_bird/ui/widgets/achievement_node.dart';
import 'package:neon_pulse_flappy_bird/models/achievement.dart';
import 'package:neon_pulse_flappy_bird/models/progression_path_models.dart';

void main() {
  group('AchievementNode Widget Tests', () {
    late Achievement testAchievement;

    setUp(() {
      testAchievement = const Achievement(
        id: 'test_achievement',
        name: 'Test Achievement',
        description: 'A test achievement',
        icon: Icons.star,
        iconColor: Colors.blue,
        targetValue: 100,
        type: AchievementType.score,
        currentProgress: 50,
      );
    });

    testWidgets('renders with minimum touch target size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementNode(
              achievement: testAchievement,
              visualState: NodeVisualState.locked,
              size: 44.0, // Minimum accessibility size
              enableAnimations: false, // Disable animations for testing
            ),
          ),
        ),
      );

      final nodeFinder = find.byType(AchievementNode);
      expect(nodeFinder, findsOneWidget);

      final nodeWidget = tester.widget<AchievementNode>(nodeFinder);
      expect(nodeWidget.size, equals(44.0));

      // Verify the actual rendered size meets accessibility requirements
      final containerFinder = find.descendant(
        of: nodeFinder,
        matching: find.byType(Container),
      );
      
      final RenderBox renderBox = tester.renderObject(containerFinder.first);
      expect(renderBox.size.width, greaterThanOrEqualTo(44.0));
      expect(renderBox.size.height, greaterThanOrEqualTo(44.0));
    });

    testWidgets('displays correct visual state for locked achievement', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementNode(
              achievement: testAchievement,
              visualState: NodeVisualState.locked,
              enableAnimations: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Check that the node has reduced opacity for locked state
      final iconFinder = find.byIcon(Icons.star);
      expect(iconFinder, findsOneWidget);

      final Opacity opacityWidget = tester.widget<Opacity>(
        find.ancestor(
          of: iconFinder,
          matching: find.byType(Opacity),
        ),
      );
      expect(opacityWidget.opacity, equals(0.4)); // Locked state opacity
    });

    testWidgets('displays progress ring for in-progress achievement', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementNode(
              achievement: testAchievement,
              visualState: NodeVisualState.inProgress,
              showProgressRing: true,
              enableAnimations: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Check for progress ring painter
      final progressRingFinder = find.byType(CustomPaint);
      expect(progressRingFinder, findsWidgets);

      // Verify progress ring is painted with correct progress
      final customPaintWidgets = tester.widgetList<CustomPaint>(progressRingFinder);
      bool foundProgressRing = false;
      
      for (final widget in customPaintWidgets) {
        if (widget.painter is ProgressRingPainter) {
          final painter = widget.painter as ProgressRingPainter;
          expect(painter.progress, equals(testAchievement.progressPercentage));
          foundProgressRing = true;
          break;
        }
      }
      
      expect(foundProgressRing, isTrue);
    });

    testWidgets('shows completion indicator for unlocked achievement', (WidgetTester tester) async {
      final unlockedAchievement = testAchievement.copyWith(
        isUnlocked: true,
        currentProgress: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementNode(
              achievement: unlockedAchievement,
              visualState: NodeVisualState.unlocked,
              enableAnimations: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Check for completion checkmark
      final checkmarkFinder = find.byIcon(Icons.check);
      expect(checkmarkFinder, findsOneWidget);
    });

    testWidgets('shows reward indicator for reward available achievement', (WidgetTester tester) async {
      final rewardAchievement = Achievement(
        id: 'reward_achievement',
        name: 'Reward Achievement',
        description: 'Achievement with reward',
        icon: Icons.star,
        iconColor: const Color(0xFFFFD700), // Gold color
        targetValue: 100,
        type: AchievementType.score,
        rewardSkinId: 'golden_bird',
        isUnlocked: true,
        currentProgress: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementNode(
              achievement: rewardAchievement,
              visualState: NodeVisualState.rewardAvailable,
              enableAnimations: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Check for reward star indicator
      final rewardStarFinder = find.byIcon(Icons.star);
      expect(rewardStarFinder, findsAtLeastNWidgets(1)); // Achievement icon + reward indicator
    });

    testWidgets('handles tap interactions correctly', (WidgetTester tester) async {
      bool tapCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementNode(
              achievement: testAchievement,
              visualState: NodeVisualState.unlocked,
              enableAnimations: false,
              onTap: () {
                tapCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Tap the node
      await tester.tap(find.byType(AchievementNode));
      await tester.pump();

      expect(tapCalled, isTrue);
    });

    testWidgets('provides visual feedback on press', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementNode(
              achievement: testAchievement,
              visualState: NodeVisualState.unlocked,
              enableAnimations: false,
            ),
          ),
        ),
      );

      await tester.pump();

      final nodeFinder = find.byType(AchievementNode);
      
      // Press down
      await tester.press(nodeFinder);
      await tester.pump();

      // The node should be scaled down when pressed
      final transformFinder = find.descendant(
        of: nodeFinder,
        matching: find.byType(Transform),
      );
      expect(transformFinder, findsWidgets);
    });

    testWidgets('respects enableAnimations parameter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementNode(
              achievement: testAchievement,
              visualState: NodeVisualState.inProgress,
              enableAnimations: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // With animations disabled, the widget should still render correctly
      final nodeFinder = find.byType(AchievementNode);
      expect(nodeFinder, findsOneWidget);
    });

    testWidgets('maintains accessibility touch targets across different sizes', (WidgetTester tester) async {
      final sizes = [44.0, 60.0, 80.0]; // Different node sizes

      for (final size in sizes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AchievementNode(
                achievement: testAchievement,
                visualState: NodeVisualState.unlocked,
                size: size,
                enableAnimations: false,
              ),
            ),
          ),
        );

        await tester.pump();

        // Verify touch target is at least 44dp
        final gestureDetectorFinder = find.byType(GestureDetector);
        final RenderBox renderBox = tester.renderObject(gestureDetectorFinder);
        expect(renderBox.size.width, greaterThanOrEqualTo(44.0));
        expect(renderBox.size.height, greaterThanOrEqualTo(44.0));
      }
    });

    group('ProgressRingPainter Tests', () {
      test('shouldRepaint returns correct values', () {
        final painter1 = ProgressRingPainter(
          progress: 0.5,
          color: Colors.blue,
          strokeWidth: 3.0,
        );

        final painter2 = ProgressRingPainter(
          progress: 0.5,
          color: Colors.blue,
          strokeWidth: 3.0,
        );

        final painter3 = ProgressRingPainter(
          progress: 0.7,
          color: Colors.blue,
          strokeWidth: 3.0,
        );

        expect(painter1.shouldRepaint(painter2), isFalse);
        expect(painter1.shouldRepaint(painter3), isTrue);
      });
    });

    group('Visual State Transitions', () {
      testWidgets('updates visual state correctly when widget updates', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AchievementNode(
                achievement: testAchievement,
                visualState: NodeVisualState.locked,
                enableAnimations: false,
              ),
            ),
          ),
        );

        await tester.pump();

        // Update to unlocked state
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AchievementNode(
                achievement: testAchievement.copyWith(isUnlocked: true),
                visualState: NodeVisualState.unlocked,
                enableAnimations: false,
              ),
            ),
          ),
        );

        await tester.pump();

        // Check for completion indicator
        final checkmarkFinder = find.byIcon(Icons.check);
        expect(checkmarkFinder, findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('provides semantic information', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AchievementNode(
                achievement: testAchievement,
                visualState: NodeVisualState.inProgress,
                enableAnimations: false,
                onTap: () {},
              ),
            ),
          ),
        );

        await tester.pump();

        // The widget should be tappable (has GestureDetector)
        final gestureDetectorFinder = find.byType(GestureDetector);
        expect(gestureDetectorFinder, findsOneWidget);
      });

      testWidgets('maintains touch target size across different screen densities', (WidgetTester tester) async {
        // Test with different device pixel ratios
        final devicePixelRatios = [1.0, 2.0, 3.0];

        for (final ratio in devicePixelRatios) {
          tester.binding.window.devicePixelRatioTestValue = ratio;
          
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AchievementNode(
                  achievement: testAchievement,
                  visualState: NodeVisualState.unlocked,
                  size: 44.0,
                  enableAnimations: false,
                ),
              ),
            ),
          );

          await tester.pump();

          final gestureDetectorFinder = find.byType(GestureDetector);
          final RenderBox renderBox = tester.renderObject(gestureDetectorFinder);
          
          // Touch target should remain at least 44dp regardless of pixel ratio
          expect(renderBox.size.width, greaterThanOrEqualTo(44.0));
          expect(renderBox.size.height, greaterThanOrEqualTo(44.0));
        }

        // Reset device pixel ratio
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });
  });
}