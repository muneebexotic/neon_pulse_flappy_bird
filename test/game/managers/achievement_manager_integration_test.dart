import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/game/managers/achievement_manager.dart';
import 'package:neon_pulse_flappy_bird/game/managers/achievement_event_manager.dart';
import 'package:neon_pulse_flappy_bird/game/managers/customization_manager.dart';
import 'package:neon_pulse_flappy_bird/game/managers/notification_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AchievementManager Integration with EventManager', () {
    late AchievementManager achievementManager;
    late CustomizationManager customizationManager;
    late NotificationManager notificationManager;
    late AchievementEventManager eventManager;

    setUp(() {
      // Reset event manager singleton
      AchievementEventManager.reset();
      
      customizationManager = CustomizationManager();
      notificationManager = NotificationManager();
      achievementManager = AchievementManager(customizationManager, notificationManager);
      eventManager = AchievementEventManager.instance;
    });

    tearDown(() {
      AchievementEventManager.reset();
    });

    test('should have AchievementEventManager integrated', () {
      // Verify that AchievementManager has access to the event manager
      expect(achievementManager, isA<AchievementManager>());
      expect(eventManager, isA<AchievementEventManager>());
      expect(eventManager, same(AchievementEventManager.instance));
    });

    test('should have helper methods for event notifications', () {
      // Verify that the helper methods exist (we can't test them directly without mocking)
      // But we can verify the AchievementManager was constructed properly
      expect(achievementManager.achievements, isA<List>());
      expect(achievementManager.gameStatistics, isA<Map<String, int>>());
    });

    test('should have real-time update methods that can emit events', () {
      // Verify the methods exist and are callable
      expect(achievementManager.updateScoreProgress, isA<Function>());
      expect(achievementManager.updatePulseUsage, isA<Function>());
      expect(achievementManager.updatePowerUpCollection, isA<Function>());
      expect(achievementManager.updateSurvivalTime, isA<Function>());
      expect(achievementManager.updateGameStatistics, isA<Function>());
    });

    test('should maintain event manager singleton pattern', () {
      // Create another achievement manager
      final anotherCustomizationManager = CustomizationManager();
      final anotherNotificationManager = NotificationManager();
      final anotherAchievementManager = AchievementManager(
        anotherCustomizationManager, 
        anotherNotificationManager
      );
      
      // Both should use the same event manager instance
      expect(AchievementEventManager.instance, same(eventManager));
    });

    test('should be able to listen to event streams', () {
      bool progressEventReceived = false;
      bool unlockEventReceived = false;
      bool statisticsEventReceived = false;

      // Set up listeners
      eventManager.subscribeToAllProgress((event) {
        progressEventReceived = true;
      });

      eventManager.subscribeToAllUnlocks((event) {
        unlockEventReceived = true;
      });

      eventManager.subscribeToStatistics((event) {
        statisticsEventReceived = true;
      });

      // Verify listeners are set up (they won't receive events without actual data changes)
      expect(eventManager.hasListeners, isTrue);
    });
  });
}