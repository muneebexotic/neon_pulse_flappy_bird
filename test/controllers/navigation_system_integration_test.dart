import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/controllers/progression_navigation_system.dart';
import 'package:neon_pulse_flappy_bird/controllers/progression_scroll_controller.dart';
import 'package:neon_pulse_flappy_bird/controllers/scan_line_animation_controller.dart';
import 'package:neon_pulse_flappy_bird/models/achievement.dart';
import 'package:neon_pulse_flappy_bird/models/progression_path_models.dart';
import 'package:flame/components.dart';

void main() {
  group('Navigation System Integration', () {
    testWidgets('should create and initialize navigation system', (tester) async {
      final navigationSystem = ProgressionNavigationSystem();
      
      final testAchievements = [
        Achievement(
          id: 'test_achievement',
          name: 'Test Achievement',
          description: 'Test description',
          icon: Icons.star,
          iconColor: Colors.cyan,
          type: AchievementType.score,
          targetValue: 10,
          currentProgress: 5,
          isUnlocked: false,
        ),
      ];

      final testNodePositions = {
        'test_achievement': NodePosition(
          position: Vector2(200, 400),
          achievementId: 'test_achievement',
          category: AchievementType.score,
          visualState: NodeVisualState.inProgress,
          pathProgress: 0.5,
          isOnMainPath: true,
        ),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: navigationSystem.scrollController,
              child: SizedBox(
                height: 1000,
                child: Container(),
              ),
            ),
          ),
        ),
      );

      await navigationSystem.initialize(
        tickerProvider: tester,
        screenSize: const Size(400, 800),
        achievements: testAchievements,
        nodePositions: testNodePositions,
      );

      expect(navigationSystem.isInitialized, isTrue);
      expect(navigationSystem.scrollController, isA<ProgressionScrollController>());
      expect(navigationSystem.scanLineController, isA<ScanLineAnimationController>());

      navigationSystem.dispose();
    });

    testWidgets('should handle scroll operations', (tester) async {
      final scrollController = ProgressionScrollController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: scrollController,
              child: SizedBox(
                height: 2000,
                child: Container(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(scrollController.hasClients, isTrue);
      expect(scrollController.currentProgressPosition, equals(0.0));
      expect(scrollController.isAutoScrolling, isFalse);

      scrollController.dispose();
    });

    testWidgets('should handle scan line animation', (tester) async {
      final scanLineController = ScanLineAnimationController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              scanLineController.initialize(tester);
              return Container();
            },
          ),
        ),
      );

      expect(scanLineController.isInitialized, isTrue);
      expect(scanLineController.scanLinePosition, equals(0.0));
      expect(scanLineController.isAnimating, isFalse);

      scanLineController.dispose();
    });

    test('should create custom scroll physics', () {
      const physics = CustomScrollPhysics(
        momentumThreshold: 50.0,
        boundarySpringStrength: 0.8,
      );

      expect(physics.momentumThreshold, equals(50.0));
      expect(physics.boundarySpringStrength, equals(0.8));
      expect(physics.minFlingVelocity, equals(50.0));
    });

    test('should create scan line painter', () {
      const screenSize = Size(400, 800);
      
      final painter = ScanLinePainter(
        scanLinePosition: 0.5,
        revealProgress: 0.5,
        glowIntensity: 0.5,
        scanLineColor: Colors.cyan,
        scanLineWidth: 3.0,
        glowRadius: 20.0,
        screenSize: screenSize,
      );

      expect(painter, isA<ScanLinePainter>());
      expect(painter.scanLinePosition, equals(0.5));
      expect(painter.revealProgress, equals(0.5));
    });
  });
}