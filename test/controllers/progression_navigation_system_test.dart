import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/controllers/progression_navigation_system.dart';
import 'package:neon_pulse_flappy_bird/controllers/progression_scroll_controller.dart';
import 'package:neon_pulse_flappy_bird/controllers/scan_line_animation_controller.dart';
import 'package:neon_pulse_flappy_bird/models/achievement.dart';
import 'package:neon_pulse_flappy_bird/models/progression_path_models.dart';
import 'package:flame/components.dart';

void main() {
  group('ProgressionNavigationSystem', () {
    late ProgressionNavigationSystem navigationSystem;
    late List<Achievement> testAchievements;
    late Map<String, NodePosition> testNodePositions;
    late Size testScreenSize;

    setUp(() {
      navigationSystem = ProgressionNavigationSystem();
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
      navigationSystem.dispose();
    });

    group('Initialization', () {
      test('should initialize with default values', () {
        expect(navigationSystem.isInitialized, isFalse);
        expect(navigationSystem.isNavigating, isFalse);
        expect(navigationSystem.targetAchievementId, isNull);
        expect(navigationSystem.scrollProgress, equals(0.0));
      });

      test('should provide access to controllers', () {
        expect(navigationSystem.scrollController, isA<ProgressionScrollController>());
        expect(navigationSystem.scanLineController, isA<ScanLineAnimationController>());
      });

      testWidgets('should initialize correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Container();
              },
            ),
          ),
        );

        await navigationSystem.initialize(
          tickerProvider: tester,
          screenSize: testScreenSize,
          achievements: testAchievements,
          nodePositions: testNodePositions,
        );

        expect(navigationSystem.isInitialized, isTrue);
        expect(navigationSystem.scanLineController.isInitialized, isTrue);
      });

      test('should handle multiple initialization calls', () {
        testWidgets('multiple init calls', (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) => Container(),
              ),
            ),
          );

          await navigationSystem.initialize(
            tickerProvider: tester,
            screenSize: testScreenSize,
            achievements: testAchievements,
            nodePositions: testNodePositions,
          );

          expect(navigationSystem.isInitialized, isTrue);

          // Second initialization should be ignored
          await navigationSystem.initialize(
            tickerProvider: tester,
            screenSize: testScreenSize,
            achievements: testAchievements,
            nodePositions: testNodePositions,
          );

          expect(navigationSystem.isInitialized, isTrue);
        });
      });
    });

    group('Navigation Control', () {
      testWidgets('should start initial reveal sequence', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: navigationSystem.scrollController,
                child: SizedBox(
                  height: 2000,
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await navigationSystem.initialize(
          tickerProvider: tester,
          screenSize: testScreenSize,
          achievements: testAchievements,
          nodePositions: testNodePositions,
        );

        expect(navigationSystem.isScanLineAnimating, isFalse);

        // Start reveal sequence
        final revealFuture = navigationSystem.startInitialRevealSequence();
        
        // Should start scan line animation
        await tester.pump(const Duration(milliseconds: 100));
        expect(navigationSystem.isScanLineAnimating, isTrue);

        // Complete the sequence
        await tester.pumpAndSettle();
        await revealFuture;

        expect(navigationSystem.isScanLineAnimating, isFalse);
      });

      testWidgets('should navigate to achievement', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: navigationSystem.scrollController,
                child: SizedBox(
                  height: 2000,
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await navigationSystem.initialize(
          tickerProvider: tester,
          screenSize: testScreenSize,
          achievements: testAchievements,
          nodePositions: testNodePositions,
        );

        expect(navigationSystem.targetAchievementId, isNull);

        // Navigate to specific achievement
        final navigationFuture = navigationSystem.navigateToAchievement('achievement_2');
        
        expect(navigationSystem.targetAchievementId, equals('achievement_2'));
        expect(navigationSystem.isNavigating, isTrue);

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        await navigationFuture;

        expect(navigationSystem.isNavigating, isFalse);
        expect(navigationSystem.targetAchievementId, isNull);
      });

      testWidgets('should scroll to current progress', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: navigationSystem.scrollController,
                child: SizedBox(
                  height: 2000,
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await navigationSystem.initialize(
          tickerProvider: tester,
          screenSize: testScreenSize,
          achievements: testAchievements,
          nodePositions: testNodePositions,
        );

        final scrollFuture = navigationSystem.scrollToCurrentProgress();
        
        expect(navigationSystem.isNavigating, isTrue);

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        await scrollFuture;

        expect(navigationSystem.isNavigating, isFalse);
      });

      testWidgets('should scroll to position', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: navigationSystem.scrollController,
                child: SizedBox(
                  height: 2000,
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await navigationSystem.initialize(
          tickerProvider: tester,
          screenSize: testScreenSize,
          achievements: testAchievements,
          nodePositions: testNodePositions,
        );

        final scrollFuture = navigationSystem.scrollToPosition(500.0);
        
        expect(navigationSystem.isNavigating, isTrue);

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        await scrollFuture;

        expect(navigationSystem.isNavigating, isFalse);
      });
    });

    group('Data Management', () {
      testWidgets('should update data correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Container(),
            ),
          ),
        );

        await navigationSystem.initialize(
          tickerProvider: tester,
          screenSize: testScreenSize,
          achievements: testAchievements,
          nodePositions: testNodePositions,
        );

        int notificationCount = 0;
        navigationSystem.addListener(() => notificationCount++);

        // Update with new data
        final newAchievements = [...testAchievements];
        newAchievements.add(Achievement(
          id: 'achievement_4',
          name: 'New Achievement',
          description: 'New description',
          icon: Icons.star,
          iconColor: Colors.cyan,
          type: AchievementType.score,
          targetValue: 200,
          currentProgress: 0,
          isUnlocked: false,
        ));

        navigationSystem.updateData(achievements: newAchievements);
        expect(notificationCount, greaterThan(0));

        // Update with same data should not notify
        notificationCount = 0;
        navigationSystem.updateData(achievements: newAchievements);
        expect(notificationCount, equals(0));
      });

      test('should reset correctly', () {
        navigationSystem.reset();
        
        expect(navigationSystem.targetAchievementId, isNull);
        expect(navigationSystem.isNavigating, isFalse);
      });
    });

    group('Callback Management', () {
      testWidgets('should handle navigation callbacks', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: navigationSystem.scrollController,
                child: SizedBox(
                  height: 2000,
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await navigationSystem.initialize(
          tickerProvider: tester,
          screenSize: testScreenSize,
          achievements: testAchievements,
          nodePositions: testNodePositions,
        );

        bool navigationStartCalled = false;
        bool navigationCompleteCalled = false;
        String? targetAchievementChanged;

        navigationSystem.setOnNavigationStart(() => navigationStartCalled = true);
        navigationSystem.setOnNavigationComplete(() => navigationCompleteCalled = true);
        navigationSystem.setOnTargetAchievementChanged((id) => targetAchievementChanged = id);

        // Trigger navigation
        final navigationFuture = navigationSystem.navigateToAchievement('achievement_2');
        
        expect(navigationStartCalled, isTrue);
        expect(targetAchievementChanged, equals('achievement_2'));

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        await navigationFuture;

        expect(navigationCompleteCalled, isTrue);
        expect(targetAchievementChanged, isNull); // Should be cleared after navigation
      });
    });

    group('Reveal System Integration', () {
      testWidgets('should integrate scan line reveal correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Container(),
            ),
          ),
        );

        await navigationSystem.initialize(
          tickerProvider: tester,
          screenSize: testScreenSize,
          achievements: testAchievements,
          nodePositions: testNodePositions,
        );

        // Test reveal methods
        expect(navigationSystem.shouldRevealPoint(100.0), isA<bool>());
        expect(navigationSystem.getRevealOpacity(100.0), isA<double>());
        expect(navigationSystem.getScanLineGlow(100.0), isA<double>());

        // Test painter creation
        final painter = navigationSystem.createScanLinePainter();
        expect(painter, isA<CustomPainter>());
      });

      test('should handle reveal methods without initialization', () {
        // Should not crash when called before initialization
        expect(() => navigationSystem.shouldRevealPoint(100.0), returnsNormally);
        expect(() => navigationSystem.getRevealOpacity(100.0), returnsNormally);
        expect(() => navigationSystem.getScanLineGlow(100.0), returnsNormally);
        expect(navigationSystem.createScanLinePainter(), isNull);
      });
    });

    group('Achievement Finding', () {
      testWidgets('should find closest achievement', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: navigationSystem.scrollController,
                child: SizedBox(
                  height: 2000,
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await navigationSystem.initialize(
          tickerProvider: tester,
          screenSize: testScreenSize,
          achievements: testAchievements,
          nodePositions: testNodePositions,
        );

        await tester.pumpAndSettle();

        final closestId = navigationSystem.findClosestAchievement();
        expect(closestId, isNotNull);
        expect(testNodePositions.containsKey(closestId), isTrue);
      });

      testWidgets('should get visible achievements', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: navigationSystem.scrollController,
                child: SizedBox(
                  height: 2000,
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await navigationSystem.initialize(
          tickerProvider: tester,
          screenSize: testScreenSize,
          achievements: testAchievements,
          nodePositions: testNodePositions,
        );

        await tester.pumpAndSettle();

        final visibleAchievements = navigationSystem.getVisibleAchievements();
        expect(visibleAchievements, isA<List<String>>());
      });

      test('should handle empty data gracefully', () {
        expect(navigationSystem.findClosestAchievement(), isNull);
        expect(navigationSystem.getVisibleAchievements(), isEmpty);
      });
    });

    group('Error Handling', () {
      test('should handle operations before initialization', () {
        expect(() => navigationSystem.startInitialRevealSequence(), returnsNormally);
        expect(() => navigationSystem.scrollToCurrentProgress(), returnsNormally);
        expect(() => navigationSystem.navigateToAchievement('test'), returnsNormally);
        expect(() => navigationSystem.scrollToPosition(100.0), returnsNormally);
      });

      testWidgets('should handle navigation to nonexistent achievement', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: navigationSystem.scrollController,
                child: SizedBox(
                  height: 2000,
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await navigationSystem.initialize(
          tickerProvider: tester,
          screenSize: testScreenSize,
          achievements: testAchievements,
          nodePositions: testNodePositions,
        );

        expect(() => navigationSystem.navigateToAchievement('nonexistent'), returnsNormally);
      });

      testWidgets('should handle concurrent navigation requests', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: navigationSystem.scrollController,
                child: SizedBox(
                  height: 2000,
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await navigationSystem.initialize(
          tickerProvider: tester,
          screenSize: testScreenSize,
          achievements: testAchievements,
          nodePositions: testNodePositions,
        );

        // Start first navigation
        final nav1 = navigationSystem.navigateToAchievement('achievement_1');
        
        // Start second navigation while first is in progress
        final nav2 = navigationSystem.navigateToAchievement('achievement_2');

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Both should complete without error
        await nav1;
        await nav2;

        expect(navigationSystem.isNavigating, isFalse);
      });
    });

    group('Disposal', () {
      testWidgets('should dispose cleanly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Container(),
            ),
          ),
        );

        await navigationSystem.initialize(
          tickerProvider: tester,
          screenSize: testScreenSize,
          achievements: testAchievements,
          nodePositions: testNodePositions,
        );

        // Set callbacks
        navigationSystem.setOnNavigationStart(() {});
        navigationSystem.setOnNavigationComplete(() {});
        navigationSystem.setOnTargetAchievementChanged((_) {});

        expect(() => navigationSystem.dispose(), returnsNormally);
      });

      test('should dispose cleanly when not initialized', () {
        expect(() => navigationSystem.dispose(), returnsNormally);
      });

      testWidgets('should dispose cleanly during navigation', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: navigationSystem.scrollController,
                child: SizedBox(
                  height: 2000,
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await navigationSystem.initialize(
          tickerProvider: tester,
          screenSize: testScreenSize,
          achievements: testAchievements,
          nodePositions: testNodePositions,
        );

        // Start navigation
        navigationSystem.navigateToAchievement('achievement_1');
        await tester.pump(const Duration(milliseconds: 100));

        // Dispose during navigation
        expect(() => navigationSystem.dispose(), returnsNormally);
      });
    });

    group('Change Notification', () {
      testWidgets('should notify listeners appropriately', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Container(),
            ),
          ),
        );

        int notificationCount = 0;
        navigationSystem.addListener(() => notificationCount++);

        await navigationSystem.initialize(
          tickerProvider: tester,
          screenSize: testScreenSize,
          achievements: testAchievements,
          nodePositions: testNodePositions,
        );

        expect(notificationCount, greaterThan(0));

        notificationCount = 0;
        navigationSystem.reset();
        expect(notificationCount, equals(1));
      });
    });
  });
}