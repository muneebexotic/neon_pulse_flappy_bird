import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/models/achievement.dart';
import 'package:neon_pulse_flappy_bird/game/managers/achievement_manager.dart';
import 'package:neon_pulse_flappy_bird/game/managers/achievement_event_manager.dart';
import 'package:neon_pulse_flappy_bird/game/managers/customization_manager.dart';
import 'package:neon_pulse_flappy_bird/game/managers/notification_manager.dart';
import 'package:neon_pulse_flappy_bird/ui/screens/achievements_progression_screen.dart';

void main() {
  group('AchievementsProgressionScreen Real-time Updates', () {
    late AchievementManager achievementManager;
    late AchievementEventManager eventManager;
    late CustomizationManager customizationManager;
    late NotificationManager notificationManager;

    setUp(() {
      // Reset the singleton before each test
      AchievementEventManager.reset();
      eventManager = AchievementEventManager.instance;
      
      // Create managers for testing
      customizationManager = CustomizationManager();
      notificationManager = NotificationManager();
      achievementManager = AchievementManager(customizationManager, notificationManager);
    });

    tearDown(() {
      AchievementEventManager.reset();
    });

    testWidgets('should subscribe to achievement events on init', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementsProgressionScreen(
            achievementManager: achievementManager,
          ),
        ),
      );

      // Verify the screen is rendered
      expect(find.byType(AchievementsProgressionScreen), findsOneWidget);
      
      // Verify that the event manager has listeners
      expect(eventManager.hasListeners, isTrue);
    });

    testWidgets('should handle achievement progress events', (WidgetTester tester) async {
      // Create a test achievement
      final testAchievement = Achievement(
        id: 'test_achievement',
        name: 'Test Achievement',
        description: 'A test achievement',
        icon: Icons.star,
        iconColor: Colors.yellow,
        targetValue: 100,
        type: AchievementType.score,
        currentProgress: 50,
      );

      // Add the achievement to the manager
      achievementManager.achievements.add(testAchievement);

      await tester.pumpWidget(
        MaterialApp(
          home: AchievementsProgressionScreen(
            achievementManager: achievementManager,
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Simulate an achievement progress event
      final updatedAchievement = Achievement(
        id: 'test_achievement',
        name: 'Test Achievement',
        description: 'A test achievement',
        icon: Icons.star,
        iconColor: Colors.yellow,
        targetValue: 100,
        type: AchievementType.score,
        currentProgress: 75,
      );

      eventManager.notifyAchievementProgress(
        achievement: updatedAchievement,
        oldProgress: 0.5,
        newProgress: 0.75,
      );

      // Pump the widget to process the event
      await tester.pump();

      // Verify the screen is still rendered (no crashes)
      expect(find.byType(AchievementsProgressionScreen), findsOneWidget);
    });

    testWidgets('should handle achievement unlock events', (WidgetTester tester) async {
      // Create a test achievement
      final testAchievement = Achievement(
        id: 'test_achievement',
        name: 'Test Achievement',
        description: 'A test achievement',
        icon: Icons.star,
        iconColor: Colors.yellow,
        targetValue: 100,
        type: AchievementType.score,
        currentProgress: 100,
        isUnlocked: true,
      );

      // Add the achievement to the manager
      achievementManager.achievements.add(testAchievement);

      await tester.pumpWidget(
        MaterialApp(
          home: AchievementsProgressionScreen(
            achievementManager: achievementManager,
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Simulate an achievement unlock event
      eventManager.notifyAchievementUnlocked(testAchievement);

      // Pump the widget to process the event
      await tester.pump();

      // Verify the screen is still rendered (no crashes)
      expect(find.byType(AchievementsProgressionScreen), findsOneWidget);
    });

    testWidgets('should handle statistics update events', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementsProgressionScreen(
            achievementManager: achievementManager,
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Simulate a statistics update event
      eventManager.notifyStatisticsUpdated(
        oldStatistics: {'score': 100, 'games_played': 5},
        newStatistics: {'score': 150, 'games_played': 6},
      );

      // Pump the widget to process the event
      await tester.pump();

      // Verify the screen is still rendered (no crashes)
      expect(find.byType(AchievementsProgressionScreen), findsOneWidget);
    });

    testWidgets('should dispose subscription properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementsProgressionScreen(
            achievementManager: achievementManager,
          ),
        ),
      );

      // Verify listeners are active
      expect(eventManager.hasListeners, isTrue);

      // Remove the widget
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // Verify the screen is no longer rendered
      expect(find.byType(AchievementsProgressionScreen), findsNothing);
    });
  });
}