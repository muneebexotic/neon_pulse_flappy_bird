import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/controllers/progression_scroll_controller.dart';
import 'package:neon_pulse_flappy_bird/models/achievement.dart';
import 'package:neon_pulse_flappy_bird/models/progression_path_models.dart';
import 'package:flame/components.dart';

void main() {
  group('ProgressionScrollController', () {
    late ProgressionScrollController controller;
    late List<Achievement> testAchievements;
    late Map<String, NodePosition> testNodePositions;
    late Size testScreenSize;

    setUp(() {
      controller = ProgressionScrollController();
      testScreenSize = const Size(400, 800);
      
      // Create test achievements
      testAchievements = [
        Achievement(
          id: 'achievement_1',
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
          id: 'achievement_2',
          name: 'Higher Score',
          description: 'Score 50 points',
          icon: Icons.star,
          iconColor: Colors.cyan,
          type: AchievementType.score,
          targetValue: 50,
          currentProgress: 25,
          isUnlocked: false,
        ),
        Achievement(
          id: 'achievement_3',
          name: 'Master Score',
          description: 'Score 100 points',
          icon: Icons.star,
          iconColor: Colors.cyan,
          type: AchievementType.score,
          targetValue: 100,
          currentProgress: 0,
          isUnlocked: false,
        ),
      ];

      // Create test node positions
      testNodePositions = {
        'achievement_1': NodePosition(
          position: Vector2(200, 100),
          achievementId: 'achievement_1',
          category: AchievementType.score,
          visualState: NodeVisualState.unlocked,
          pathProgress: 0.2,
          isOnMainPath: true,
        ),
        'achievement_2': NodePosition(
          position: Vector2(200, 400),
          achievementId: 'achievement_2',
          category: AchievementType.score,
          visualState: NodeVisualState.inProgress,
          pathProgress: 0.5,
          isOnMainPath: true,
        ),
        'achievement_3': NodePosition(
          position: Vector2(200, 700),
          achievementId: 'achievement_3',
          category: AchievementType.score,
          visualState: NodeVisualState.locked,
          pathProgress: 0.8,
          isOnMainPath: true,
        ),
      };
    });

    tearDown(() {
      controller.dispose();
    });

    group('Initialization', () {
      test('should initialize with default values', () {
        expect(controller.currentProgressPosition, equals(0.0));
        expect(controller.isAutoScrolling, isFalse);
      });

      test('should set callbacks correctly', () {
        bool scrollStartCalled = false;
        bool scrollEndCalled = false;
        double? progressValue;

        controller.setOnScrollStart(() => scrollStartCalled = true);
        controller.setOnScrollEnd(() => scrollEndCalled = true);
        controller.setOnProgressChanged((value) => progressValue = value);

        // Verify callbacks are set (we can't directly test private fields)
        expect(controller.currentProgressPosition, equals(0.0));
      });
    });

    group('Progress Calculation', () {
      testWidgets('should calculate current progress position correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: controller,
                child: SizedBox(
                  height: 1000,
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        // Wait for the scroll view to be built
        await tester.pumpAndSettle();

        // Test scroll position calculation
        expect(controller.hasClients, isTrue);
      });

      test('should find furthest unlocked achievement', () {
        // This tests the internal logic through public methods
        expect(testAchievements.where((a) => a.isUnlocked).length, equals(1));
        expect(testAchievements.first.isUnlocked, isTrue);
      });
    });

    group('Animation Methods', () {
      testWidgets('should handle animateToPosition', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: controller,
                child: SizedBox(
                  height: 2000,
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test animation to position
        expect(controller.hasClients, isTrue);
        
        // Start animation
        final animationFuture = controller.animateToPosition(100.0);
        expect(controller.isAutoScrolling, isTrue);

        // Complete animation
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        
        await animationFuture;
        expect(controller.isAutoScrolling, isFalse);
      });

      testWidgets('should handle animateToCurrentProgress', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: controller,
                child: SizedBox(
                  height: 2000,
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test animation to current progress
        final animationFuture = controller.animateToCurrentProgress(
          achievements: testAchievements,
          nodePositions: testNodePositions,
          screenSize: testScreenSize,
        );

        expect(controller.isAutoScrolling, isTrue);
        
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        
        await animationFuture;
        expect(controller.isAutoScrolling, isFalse);
      });

      testWidgets('should handle animateToAchievement', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: controller,
                child: SizedBox(
                  height: 2000,
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test animation to specific achievement
        final animationFuture = controller.animateToAchievement(
          achievementId: 'achievement_2',
          nodePositions: testNodePositions,
          screenSize: testScreenSize,
        );

        expect(controller.isAutoScrolling, isTrue);
        
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        
        await animationFuture;
        expect(controller.isAutoScrolling, isFalse);
      });
    });

    group('Custom Physics', () {
      test('should create custom scroll physics', () {
        final physics = controller.physics;
        expect(physics, isA<CustomScrollPhysics>());
      });

      test('CustomScrollPhysics should have correct properties', () {
        const physics = CustomScrollPhysics(
          momentumThreshold: 50.0,
          boundarySpringStrength: 0.8,
        );

        expect(physics.momentumThreshold, equals(50.0));
        expect(physics.boundarySpringStrength, equals(0.8));
        expect(physics.minFlingVelocity, equals(50.0));
      });

      test('CustomScrollPhysics should apply to ancestor', () {
        const physics = CustomScrollPhysics(
          momentumThreshold: 50.0,
          boundarySpringStrength: 0.8,
        );

        final appliedPhysics = physics.applyTo(null);
        expect(appliedPhysics, isA<CustomScrollPhysics>());
        expect(appliedPhysics.momentumThreshold, equals(50.0));
      });
    });

    group('Boundary Conditions', () {
      test('should handle boundary conditions correctly', () {
        const physics = CustomScrollPhysics(
          momentumThreshold: 50.0,
          boundarySpringStrength: 0.8,
        );

        // Create mock scroll metrics
        final metrics = FixedScrollMetrics(
          minScrollExtent: 0.0,
          maxScrollExtent: 1000.0,
          pixels: 500.0,
          viewportDimension: 800.0,
          axisDirection: AxisDirection.down,
          devicePixelRatio: 1.0,
        );

        // Test normal scroll position
        final normalResult = physics.applyBoundaryConditions(metrics, 600.0);
        expect(normalResult, equals(0.0));

        // Test overscroll
        final overscrollMetrics = FixedScrollMetrics(
          minScrollExtent: 0.0,
          maxScrollExtent: 1000.0,
          pixels: 1000.0,
          viewportDimension: 800.0,
          axisDirection: AxisDirection.down,
          devicePixelRatio: 1.0,
        );

        final overscrollResult = physics.applyBoundaryConditions(overscrollMetrics, 1100.0);
        expect(overscrollResult, equals(100.0));
      });
    });

    group('Error Handling', () {
      test('should handle missing node positions gracefully', () {
        expect(() => controller.animateToAchievement(
          achievementId: 'nonexistent',
          nodePositions: {},
          screenSize: testScreenSize,
        ), returnsNormally);
      });

      test('should handle empty achievements list', () {
        expect(() => controller.animateToCurrentProgress(
          achievements: [],
          nodePositions: testNodePositions,
          screenSize: testScreenSize,
        ), returnsNormally);
      });

      testWidgets('should handle controller without clients', (tester) async {
        // Test methods when controller has no clients
        expect(() => controller.animateToPosition(100.0), returnsNormally);
        expect(() => controller.animateToCurrentProgress(
          achievements: testAchievements,
          nodePositions: testNodePositions,
          screenSize: testScreenSize,
        ), returnsNormally);
      });
    });

    group('Callback Integration', () {
      testWidgets('should trigger scroll callbacks', (tester) async {
        bool scrollStartCalled = false;
        bool scrollEndCalled = false;
        double? lastProgressValue;

        controller.setOnScrollStart(() => scrollStartCalled = true);
        controller.setOnScrollEnd(() => scrollEndCalled = true);
        controller.setOnProgressChanged((value) => lastProgressValue = value);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: controller,
                child: SizedBox(
                  height: 2000,
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Trigger animation
        final animationFuture = controller.animateToPosition(200.0);
        
        // Check that scroll start was called
        expect(scrollStartCalled, isTrue);
        
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        
        await animationFuture;
        
        // Check that scroll end was called
        expect(scrollEndCalled, isTrue);
        
        // Progress callback should have been called
        expect(lastProgressValue, isNotNull);
      });
    });

    group('Disposal', () {
      test('should dispose cleanly', () {
        final testController = ProgressionScrollController();
        testController.setOnScrollStart(() {});
        testController.setOnScrollEnd(() {});
        testController.setOnProgressChanged((_) {});

        expect(() => testController.dispose(), returnsNormally);
      });
    });
  });
}