import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/controllers/progression_integration_controller.dart';
import '../../lib/controllers/progression_path_controller.dart';
import '../../lib/game/managers/achievement_manager.dart';
import '../../lib/models/achievement.dart';
import '../../lib/models/bird_skin.dart';

// Generate mocks
@GenerateMocks([AchievementManager, ProgressionPathController])
import 'progression_integration_controller_test.mocks.dart';

void main() {
  group('ProgressionIntegrationController', () {
    late ProgressionIntegrationController controller;
    late MockAchievementManager mockAchievementManager;
    late MockProgressionPathController mockPathController;
    late TickerProvider tickerProvider;
    
    // Test data
    final testAchievements = [
      const Achievement(
        id: 'test_1',
        name: 'Test Achievement 1',
        description: 'Test description 1',
        icon: Icons.star,
        iconColor: Colors.blue,
        targetValue: 10,
        type: AchievementType.score,
        currentProgress: 5,
        isUnlocked: false,
      ),
      const Achievement(
        id: 'test_2',
        name: 'Test Achievement 2',
        description: 'Test description 2',
        icon: Icons.trophy,
        iconColor: Colors.gold,
        targetValue: 20,
        type: AchievementType.totalScore,
        currentProgress: 20,
        isUnlocked: true,
      ),
    ];
    
    final testSkin = BirdSkin(
      id: 'test_skin',
      name: 'Test Skin',
      description: 'Test skin description',
      imagePath: 'test/path',
      unlockRequirement: 'Test requirement',
      isUnlocked: true,
    );

    setUp(() {
      mockAchievementManager = MockAchievementManager();
      mockPathController = MockProgressionPathController();
      
      // Setup default mock behavior
      when(mockAchievementManager.achievements).thenReturn(testAchievements);
      when(mockAchievementManager.gameStatistics).thenReturn({
        'highScore': 100,
        'totalScore': 500,
        'gamesPlayed': 10,
      });
      when(mockAchievementManager.initialize()).thenAnswer((_) async {});
      when(mockAchievementManager.clearPendingNotifications()).thenReturn(null);
      
      controller = ProgressionIntegrationController(
        achievementManager: mockAchievementManager,
        pathController: mockPathController,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('should initialize successfully', (WidgetTester tester) async {
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
      
      await controller.initialize(tickerProvider);
      
      expect(controller.isInitialized, isTrue);
      expect(controller.currentAchievements, equals(testAchievements));
      verify(mockAchievementManager.initialize()).called(1);
    });

    testWidgets('should not initialize twice', (WidgetTester tester) async {
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
      
      await controller.initialize(tickerProvider);
      await controller.initialize(tickerProvider);
      
      verify(mockAchievementManager.initialize()).called(1);
    });

    testWidgets('should handle initialization errors', (WidgetTester tester) async {
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
      
      when(mockAchievementManager.initialize()).thenThrow(Exception('Init error'));
      
      expect(() => controller.initialize(tickerProvider), throwsException);
    });

    group('Data Binding Integration', () {
      testWidgets('should provide access to data binding controller', (WidgetTester tester) async {
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
        
        await controller.initialize(tickerProvider);
        
        expect(controller.dataBinding, isNotNull);
        expect(controller.dataBinding.isInitialized, isTrue);
      });

      testWidgets('should delegate achievement queries to data binding', (WidgetTester tester) async {
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
        
        when(mockAchievementManager.getAchievementProgress('test_1')).thenReturn(0.5);
        when(mockAchievementManager.isAchievementUnlocked('test_2')).thenReturn(true);
        when(mockAchievementManager.getNextAchievementToUnlock()).thenReturn(testAchievements[0]);
        
        await controller.initialize(tickerProvider);
        
        expect(controller.getAchievementProgress('test_1'), equals(0.5));
        expect(controller.isAchievementUnlocked('test_2'), isTrue);
        expect(controller.getNextAchievementToUnlock(), equals(testAchievements[0]));
        
        final scoreAchievements = controller.getAchievementsByType(AchievementType.score);
        expect(scoreAchievements.length, equals(1));
      });

      testWidgets('should handle game statistics updates', (WidgetTester tester) async {
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
        
        when(mockAchievementManager.updateGameStatistics(
          score: 150,
          gamesPlayed: 1,
        )).thenAnswer((_) async {});
        
        await controller.initialize(tickerProvider);
        
        await controller.updateGameStatistics(
          score: 150,
          gamesPlayed: 1,
        );
        
        verify(mockAchievementManager.updateGameStatistics(
          score: 150,
          gamesPlayed: 1,
        )).called(1);
      });
    });

    group('Animation Integration', () {
      testWidgets('should provide access to animation controller', (WidgetTester tester) async {
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
        
        await controller.initialize(tickerProvider);
        
        expect(controller.animation, isNotNull);
      });

      testWidgets('should initialize animations for existing achievements', (WidgetTester tester) async {
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
        
        await controller.initialize(tickerProvider);
        
        // Check that animation controllers were created for test achievements
        expect(controller.getNodeAnimationController('test_1'), isNotNull);
        expect(controller.getUnlockAnimationController('test_1'), isNotNull);
        expect(controller.getProgressAnimationController('test_1'), isNotNull);
        
        expect(controller.getNodeAnimationController('test_2'), isNotNull);
        expect(controller.getUnlockAnimationController('test_2'), isNotNull);
        expect(controller.getProgressAnimationController('test_2'), isNotNull);
      });

      testWidgets('should create animation tweens', (WidgetTester tester) async {
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
        
        await controller.initialize(tickerProvider);
        
        final scaleTween = controller.createUnlockScaleTween('test_1');
        final opacityTween = controller.createUnlockOpacityTween('test_1');
        final progressTween = controller.createProgressTween('test_1', 0.0, 0.5);
        final glowTween = controller.createNodeGlowTween('test_1');
        
        expect(scaleTween, isA<Animation<double>>());
        expect(opacityTween, isA<Animation<double>>());
        expect(progressTween, isA<Animation<double>>());
        expect(glowTween, isA<Animation<double>>());
      });

      testWidgets('should track animation states', (WidgetTester tester) async {
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
        
        await controller.initialize(tickerProvider);
        
        expect(controller.isNodeAnimating('test_1'), isFalse);
        expect(controller.isCelebratingUnlock('test_1'), isFalse);
      });
    });

    group('Stream Integration', () {
      testWidgets('should handle achievement updates from streams', (WidgetTester tester) async {
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
        
        await controller.initialize(tickerProvider);
        
        // Simulate achievement update
        final updatedAchievements = [
          testAchievements[0].copyWith(currentProgress: 8),
          testAchievements[1],
        ];
        
        when(mockAchievementManager.achievements).thenReturn(updatedAchievements);
        
        // Trigger refresh to simulate stream update
        await controller.refreshData();
        
        expect(controller.currentAchievements[0].currentProgress, equals(8));
      });

      testWidgets('should handle new unlock events', (WidgetTester tester) async {
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
        
        await controller.initialize(tickerProvider);
        
        // Simulate achievement unlock
        final unlockedAchievement = testAchievements[0].copyWith(isUnlocked: true);
        
        // This would normally be triggered by the stream
        // In a real test, you might need to simulate the stream event
        expect(controller.currentAchievements[0].isUnlocked, isFalse);
      });

      testWidgets('should handle skin unlock events', (WidgetTester tester) async {
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
        
        await controller.initialize(tickerProvider);
        
        // Simulate skin unlock callback
        mockAchievementManager.onSkinUnlocked?.call(testSkin);
        
        // The skin unlock should be handled by the data binding controller
        expect(controller.dataBinding.pendingSkinUnlocks, contains(testSkin));
      });
    });

    group('Sharing Functionality', () {
      testWidgets('should delegate sharing to data binding', (WidgetTester tester) async {
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
        
        when(mockAchievementManager.shareAchievement(testAchievements[1]))
            .thenAnswer((_) async {});
        when(mockAchievementManager.shareHighScore(
          score: 150,
          customMessage: 'Test message',
        )).thenAnswer((_) async {});
        
        await controller.initialize(tickerProvider);
        
        await controller.shareAchievement(testAchievements[1]);
        await controller.shareHighScore(
          score: 150,
          customMessage: 'Test message',
        );
        
        verify(mockAchievementManager.shareAchievement(testAchievements[1])).called(1);
        verify(mockAchievementManager.shareHighScore(
          score: 150,
          customMessage: 'Test message',
        )).called(1);
      });
    });

    group('State Management', () {
      testWidgets('should provide access to controllers', (WidgetTester tester) async {
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
        
        await controller.initialize(tickerProvider);
        
        expect(controller.pathController, equals(mockPathController));
        expect(controller.achievementManager, equals(mockAchievementManager));
        expect(controller.gameStatistics, isA<Map<String, int>>());
      });

      testWidgets('should clear pending animations', (WidgetTester tester) async {
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
        
        await controller.initialize(tickerProvider);
        
        controller.clearPendingAnimations();
        
        expect(controller.dataBinding.pendingUnlockAnimations, isEmpty);
        expect(controller.dataBinding.pendingSkinUnlocks, isEmpty);
      });

      testWidgets('should process queued animations', (WidgetTester tester) async {
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
        
        await controller.initialize(tickerProvider);
        
        // This should not throw
        await controller.processQueuedAnimations();
      });
    });

    group('Performance and Statistics', () {
      testWidgets('should provide comprehensive performance stats', (WidgetTester tester) async {
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
        
        when(mockPathController.getStats()).thenReturn({
          'pathSegments': 2,
          'nodePositions': 4,
        });
        
        await controller.initialize(tickerProvider);
        
        final stats = controller.getPerformanceStats();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['integration'], isA<Map<String, dynamic>>());
        expect(stats['dataBinding'], isA<Map<String, dynamic>>());
        expect(stats['animation'], isA<Map<String, dynamic>>());
        expect(stats['pathController'], isA<Map<String, dynamic>>());
        
        expect(stats['integration']['isInitialized'], isTrue);
      });

      testWidgets('should validate controller state', (WidgetTester tester) async {
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
        
        // Before initialization
        expect(controller.validateState(), isFalse);
        
        await controller.initialize(tickerProvider);
        
        // After initialization
        expect(controller.validateState(), isTrue);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle data binding errors gracefully', (WidgetTester tester) async {
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
        
        when(mockAchievementManager.updateGameStatistics(score: 100))
            .thenThrow(Exception('Update error'));
        
        await controller.initialize(tickerProvider);
        
        // Should not throw, but handle error gracefully
        await controller.updateGameStatistics(score: 100);
      });

      testWidgets('should handle refresh errors', (WidgetTester tester) async {
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
        
        await controller.initialize(tickerProvider);
        
        when(mockAchievementManager.achievements).thenThrow(Exception('Data error'));
        
        // Should not throw, but handle error gracefully
        await controller.refreshData();
      });
    });

    group('Disposal', () {
      testWidgets('should dispose properly', (WidgetTester tester) async {
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
        
        await controller.initialize(tickerProvider);
        
        // Should not throw
        controller.dispose();
        
        // Should not be able to validate state after disposal
        expect(controller.validateState(), isFalse);
      });

      testWidgets('should handle multiple dispose calls', (WidgetTester tester) async {
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
        
        await controller.initialize(tickerProvider);
        
        controller.dispose();
        controller.dispose(); // Should not throw
      });
    });
  });
}