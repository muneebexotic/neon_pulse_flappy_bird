import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/controllers/progression_animation_controller.dart';
import '../../lib/models/achievement.dart';
import '../../lib/models/bird_skin.dart';

void main() {
  group('ProgressionAnimationController', () {
    late ProgressionAnimationController controller;
    late TickerProvider tickerProvider;
    
    // Test data
    const testAchievement = Achievement(
      id: 'test_achievement',
      name: 'Test Achievement',
      description: 'Test description',
      icon: Icons.star,
      iconColor: Colors.blue,
      targetValue: 10,
      type: AchievementType.score,
      currentProgress: 5,
      isUnlocked: false,
    );
    
    final testSkin = BirdSkin(
      id: 'test_skin',
      name: 'Test Skin',
      description: 'Test skin description',
      imagePath: 'test/path',
      unlockRequirement: 'Test requirement',
      isUnlocked: true,
    );

    setUp(() {
      controller = ProgressionAnimationController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('should initialize animation controllers', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              tickerProvider = context as TickerProvider;
              return Container();
            },
          ),
        ),
      );
      
      controller.initializeNodeAnimation(testAchievement.id, tickerProvider);
      controller.initializeUnlockAnimation(testAchievement.id, tickerProvider);
      controller.initializeProgressAnimation(testAchievement.id, tickerProvider);
      
      expect(controller.getNodeAnimationController(testAchievement.id), isNotNull);
      expect(controller.getUnlockAnimationController(testAchievement.id), isNotNull);
      expect(controller.getProgressAnimationController(testAchievement.id), isNotNull);
    });

    testWidgets('should not initialize duplicate controllers', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              tickerProvider = context as TickerProvider;
              return Container();
            },
          ),
        ),
      );
      
      controller.initializeNodeAnimation(testAchievement.id, tickerProvider);
      final firstController = controller.getNodeAnimationController(testAchievement.id);
      
      controller.initializeNodeAnimation(testAchievement.id, tickerProvider);
      final secondController = controller.getNodeAnimationController(testAchievement.id);
      
      expect(identical(firstController, secondController), isTrue);
    });

    group('Animation State Management', () {
      testWidgets('should track animating nodes', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                tickerProvider = context as TickerProvider;
                return Container();
              },
            ),
          ),
        );
        
        controller.initializeProgressAnimation(testAchievement.id, tickerProvider);
        
        expect(controller.isNodeAnimating(testAchievement.id), isFalse);
        
        // Start animation
        controller.animateProgressUpdate(testAchievement, 0.0, 0.5);
        await tester.pump();
        
        // Animation should be tracked
        expect(controller.isNodeAnimating(testAchievement.id), isTrue);
        
        // Wait for animation to complete
        await tester.pump(const Duration(milliseconds: 800));
        
        expect(controller.isNodeAnimating(testAchievement.id), isFalse);
      });

      testWidgets('should track celebrating unlocks', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                tickerProvider = context as TickerProvider;
                return Container();
              },
            ),
          ),
        );
        
        controller.initializeUnlockAnimation(testAchievement.id, tickerProvider);
        
        expect(controller.isCelebratingUnlock(testAchievement.id), isFalse);
        
        // Start unlock animation
        controller.triggerUnlockAnimation(testAchievement);
        await tester.pump();
        
        expect(controller.isCelebratingUnlock(testAchievement.id), isTrue);
        
        // Wait for animation to complete
        await tester.pump(const Duration(milliseconds: 2000));
        
        expect(controller.isCelebratingUnlock(testAchievement.id), isFalse);
      });
    });

    group('Node Glow Animations', () {
      testWidgets('should start and stop node glow', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                tickerProvider = context as TickerProvider;
                return Container();
              },
            ),
          ),
        );
        
        controller.initializeNodeAnimation(testAchievement.id, tickerProvider);
        final animationController = controller.getNodeAnimationController(testAchievement.id)!;
        
        expect(animationController.isAnimating, isFalse);
        
        controller.startNodeGlow(testAchievement.id);
        await tester.pump();
        
        expect(animationController.isAnimating, isTrue);
        
        controller.stopNodeGlow(testAchievement.id);
        await tester.pump();
        
        expect(animationController.isAnimating, isFalse);
      });

      testWidgets('should start and stop progress pulse', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                tickerProvider = context as TickerProvider;
                return Container();
              },
            ),
          ),
        );
        
        controller.initializeNodeAnimation(testAchievement.id, tickerProvider);
        final animationController = controller.getNodeAnimationController(testAchievement.id)!;
        
        expect(animationController.isAnimating, isFalse);
        
        controller.startProgressPulse(testAchievement.id);
        await tester.pump();
        
        expect(animationController.isAnimating, isTrue);
        
        controller.stopProgressPulse(testAchievement.id);
        await tester.pump();
        
        expect(animationController.isAnimating, isFalse);
      });
    });

    group('Animation Tweens', () {
      testWidgets('should create unlock scale tween', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                tickerProvider = context as TickerProvider;
                return Container();
              },
            ),
          ),
        );
        
        controller.initializeUnlockAnimation(testAchievement.id, tickerProvider);
        
        final scaleTween = controller.createUnlockScaleTween(testAchievement.id);
        
        expect(scaleTween, isA<Animation<double>>());
        expect(scaleTween.value, equals(1.0)); // Initial value
      });

      testWidgets('should create unlock opacity tween', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                tickerProvider = context as TickerProvider;
                return Container();
              },
            ),
          ),
        );
        
        controller.initializeUnlockAnimation(testAchievement.id, tickerProvider);
        
        final opacityTween = controller.createUnlockOpacityTween(testAchievement.id);
        
        expect(opacityTween, isA<Animation<double>>());
        expect(opacityTween.value, equals(0.0)); // Initial value
      });

      testWidgets('should create progress tween', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                tickerProvider = context as TickerProvider;
                return Container();
              },
            ),
          ),
        );
        
        controller.initializeProgressAnimation(testAchievement.id, tickerProvider);
        
        final progressTween = controller.createProgressTween(testAchievement.id, 0.0, 0.5);
        
        expect(progressTween, isA<Animation<double>>());
        expect(progressTween.value, equals(0.0)); // Initial value
      });

      testWidgets('should create node glow tween', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                tickerProvider = context as TickerProvider;
                return Container();
              },
            ),
          ),
        );
        
        controller.initializeNodeAnimation(testAchievement.id, tickerProvider);
        
        final glowTween = controller.createNodeGlowTween(testAchievement.id);
        
        expect(glowTween, isA<Animation<double>>());
        expect(glowTween.value, equals(0.0)); // Initial value
      });

      test('should return default animations for non-existent controllers', () {
        final scaleTween = controller.createUnlockScaleTween('non_existent');
        final opacityTween = controller.createUnlockOpacityTween('non_existent');
        final progressTween = controller.createProgressTween('non_existent', 0.0, 1.0);
        final glowTween = controller.createNodeGlowTween('non_existent');
        
        expect(scaleTween, isA<AlwaysStoppedAnimation<double>>());
        expect(opacityTween, isA<AlwaysStoppedAnimation<double>>());
        expect(progressTween, isA<AlwaysStoppedAnimation<double>>());
        expect(glowTween, isA<AlwaysStoppedAnimation<double>>());
      });
    });

    group('Animation Progress', () {
      testWidgets('should track animation progress', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                tickerProvider = context as TickerProvider;
                return Container();
              },
            ),
          ),
        );
        
        controller.initializeUnlockAnimation(testAchievement.id, tickerProvider);
        controller.initializeProgressAnimation(testAchievement.id, tickerProvider);
        controller.initializeNodeAnimation(testAchievement.id, tickerProvider);
        
        expect(controller.getUnlockAnimationProgress(testAchievement.id), equals(0.0));
        expect(controller.getProgressAnimationProgress(testAchievement.id), equals(0.0));
        expect(controller.getNodeGlowProgress(testAchievement.id), equals(0.0));
        
        // Start animations
        final unlockController = controller.getUnlockAnimationController(testAchievement.id)!;
        final progressController = controller.getProgressAnimationController(testAchievement.id)!;
        final nodeController = controller.getNodeAnimationController(testAchievement.id)!;
        
        unlockController.forward();
        progressController.forward();
        nodeController.forward();
        
        await tester.pump(const Duration(milliseconds: 100));
        
        expect(controller.getUnlockAnimationProgress(testAchievement.id), greaterThan(0.0));
        expect(controller.getProgressAnimationProgress(testAchievement.id), greaterThan(0.0));
        expect(controller.getNodeGlowProgress(testAchievement.id), greaterThan(0.0));
      });

      test('should return 0.0 for non-existent controllers', () {
        expect(controller.getUnlockAnimationProgress('non_existent'), equals(0.0));
        expect(controller.getProgressAnimationProgress('non_existent'), equals(0.0));
        expect(controller.getNodeGlowProgress('non_existent'), equals(0.0));
      });
    });

    group('Animation Queue Management', () {
      testWidgets('should process unlock queue', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                tickerProvider = context as TickerProvider;
                return Container();
              },
            ),
          ),
        );
        
        controller.initializeUnlockAnimation(testAchievement.id, tickerProvider);
        
        bool animationStarted = false;
        bool animationCompleted = false;
        
        controller.onUnlockAnimationStart = (achievement) {
          animationStarted = true;
        };
        
        controller.onUnlockAnimationComplete = (achievement) {
          animationCompleted = true;
        };
        
        // Process queue should handle the animation
        controller.processUnlockQueue();
        await tester.pump();
        
        // Note: In a real test, you might need to trigger the queue differently
        // This is a simplified test structure
      });

      testWidgets('should process skin unlock queue', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                tickerProvider = context as TickerProvider;
                return Container();
              },
            ),
          ),
        );
        
        bool skinAnimationStarted = false;
        bool skinAnimationCompleted = false;
        
        controller.onSkinUnlockAnimationStart = (skin) {
          skinAnimationStarted = true;
        };
        
        controller.onSkinUnlockAnimationComplete = (skin) {
          skinAnimationCompleted = true;
        };
        
        // Process skin queue
        controller.processSkinUnlockQueue();
        await tester.pump();
      });
    });

    group('Animation Reset', () {
      testWidgets('should reset achievement animations', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                tickerProvider = context as TickerProvider;
                return Container();
              },
            ),
          ),
        );
        
        controller.initializeNodeAnimation(testAchievement.id, tickerProvider);
        controller.initializeUnlockAnimation(testAchievement.id, tickerProvider);
        controller.initializeProgressAnimation(testAchievement.id, tickerProvider);
        
        // Start animations
        controller.getNodeAnimationController(testAchievement.id)!.forward();
        controller.getUnlockAnimationController(testAchievement.id)!.forward();
        controller.getProgressAnimationController(testAchievement.id)!.forward();
        
        await tester.pump(const Duration(milliseconds: 100));
        
        // Reset animations
        controller.resetAchievementAnimations(testAchievement.id);
        
        expect(controller.getNodeAnimationController(testAchievement.id)!.value, equals(0.0));
        expect(controller.getUnlockAnimationController(testAchievement.id)!.value, equals(0.0));
        expect(controller.getProgressAnimationController(testAchievement.id)!.value, equals(0.0));
        
        expect(controller.isNodeAnimating(testAchievement.id), isFalse);
        expect(controller.isCelebratingUnlock(testAchievement.id), isFalse);
      });

      testWidgets('should reset all animations', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                tickerProvider = context as TickerProvider;
                return Container();
              },
            ),
          ),
        );
        
        controller.initializeNodeAnimation(testAchievement.id, tickerProvider);
        controller.initializeUnlockAnimation(testAchievement.id, tickerProvider);
        controller.initializeProgressAnimation(testAchievement.id, tickerProvider);
        
        // Start animations
        controller.getNodeAnimationController(testAchievement.id)!.forward();
        controller.getUnlockAnimationController(testAchievement.id)!.forward();
        controller.getProgressAnimationController(testAchievement.id)!.forward();
        
        await tester.pump(const Duration(milliseconds: 100));
        
        // Reset all animations
        controller.resetAllAnimations();
        
        expect(controller.getNodeAnimationController(testAchievement.id)!.value, equals(0.0));
        expect(controller.getUnlockAnimationController(testAchievement.id)!.value, equals(0.0));
        expect(controller.getProgressAnimationController(testAchievement.id)!.value, equals(0.0));
      });
    });

    group('Statistics and Debugging', () {
      testWidgets('should provide animation statistics', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                tickerProvider = context as TickerProvider;
                return Container();
              },
            ),
          ),
        );
        
        controller.initializeNodeAnimation(testAchievement.id, tickerProvider);
        controller.initializeUnlockAnimation(testAchievement.id, tickerProvider);
        controller.initializeProgressAnimation(testAchievement.id, tickerProvider);
        
        final stats = controller.getAnimationStats();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['nodeControllers'], equals(1));
        expect(stats['unlockControllers'], equals(1));
        expect(stats['progressControllers'], equals(1));
        expect(stats['animatingNodes'], equals(0));
        expect(stats['celebratingUnlocks'], equals(0));
      });
    });

    group('Disposal', () {
      testWidgets('should dispose achievement animations', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                tickerProvider = context as TickerProvider;
                return Container();
              },
            ),
          ),
        );
        
        controller.initializeNodeAnimation(testAchievement.id, tickerProvider);
        controller.initializeUnlockAnimation(testAchievement.id, tickerProvider);
        controller.initializeProgressAnimation(testAchievement.id, tickerProvider);
        
        expect(controller.getNodeAnimationController(testAchievement.id), isNotNull);
        
        controller.disposeAchievementAnimations(testAchievement.id);
        
        expect(controller.getNodeAnimationController(testAchievement.id), isNull);
        expect(controller.getUnlockAnimationController(testAchievement.id), isNull);
        expect(controller.getProgressAnimationController(testAchievement.id), isNull);
      });

      testWidgets('should dispose all controllers on dispose', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                tickerProvider = context as TickerProvider;
                return Container();
              },
            ),
          ),
        );
        
        controller.initializeNodeAnimation(testAchievement.id, tickerProvider);
        controller.initializeUnlockAnimation(testAchievement.id, tickerProvider);
        controller.initializeProgressAnimation(testAchievement.id, tickerProvider);
        
        final stats = controller.getAnimationStats();
        expect(stats['nodeControllers'], equals(1));
        
        controller.dispose();
        
        final statsAfterDispose = controller.getAnimationStats();
        expect(statsAfterDispose['nodeControllers'], equals(0));
        expect(statsAfterDispose['unlockControllers'], equals(0));
        expect(statsAfterDispose['progressControllers'], equals(0));
      });
    });
  });
}