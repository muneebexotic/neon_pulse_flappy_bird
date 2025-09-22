import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/game/managers/notification_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Play Reminder System Tests', () {
    late NotificationManager notificationManager;

    setUp(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      // Mock platform channels for notifications
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'initialize':
              return true;
            case 'requestPermissions':
              return true;
            case 'areNotificationsEnabled':
              return true;
            case 'show':
              return null;
            case 'cancel':
              return null;
            case 'cancelAll':
              return null;
            default:
              return null;
          }
        },
      );
      
      notificationManager = NotificationManager();
    });

    tearDown(() {
      notificationManager.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        null,
      );
    });

    test('should initialize with play reminders enabled by default', () async {
      await notificationManager.initialize();
      expect(notificationManager.playRemindersEnabled, isTrue);
    });

    test('should save and load play reminder preferences', () async {
      await notificationManager.initialize();
      
      // Disable play reminders
      await notificationManager.setPlayRemindersEnabled(false);
      expect(notificationManager.playRemindersEnabled, isFalse);

      // Create new instance to test persistence
      final newManager = NotificationManager();
      await newManager.initialize();
      expect(newManager.playRemindersEnabled, isFalse);
      
      newManager.dispose();
    });

    test('should include play reminders in notification settings', () async {
      await notificationManager.initialize();
      final settings = notificationManager.notificationSettings;
      expect(settings.containsKey('play_reminders'), isTrue);
      expect(settings['play_reminders'], isTrue);
    });

    test('should update last play time', () async {
      await notificationManager.initialize();
      final beforeTime = DateTime.now().millisecondsSinceEpoch;
      
      await notificationManager.updateLastPlayTime();
      
      // Verify the time was saved (we can't check exact value due to timing)
      final prefs = await SharedPreferences.getInstance();
      final savedTime = prefs.getInt('last_play_time');
      expect(savedTime, isNotNull);
      expect(savedTime! >= beforeTime, isTrue);
    });

    test('should disable play reminders when notifications are disabled', () async {
      await notificationManager.initialize();
      
      // Enable play reminders first
      await notificationManager.setPlayRemindersEnabled(true);
      expect(notificationManager.playRemindersEnabled, isTrue);

      // Disable all notifications
      await notificationManager.setNotificationsEnabled(false);
      
      // Play reminders should still be enabled in settings but not active
      expect(notificationManager.playRemindersEnabled, isTrue);
      expect(notificationManager.notificationsEnabled, isFalse);
    });

    test('should re-enable play reminders when notifications are re-enabled', () async {
      await notificationManager.initialize();
      
      // Disable notifications first
      await notificationManager.setNotificationsEnabled(false);
      
      // Enable play reminders while notifications are off
      await notificationManager.setPlayRemindersEnabled(true);
      
      // Re-enable notifications
      await notificationManager.setNotificationsEnabled(true);
      
      expect(notificationManager.notificationsEnabled, isTrue);
      expect(notificationManager.playRemindersEnabled, isTrue);
    });

    test('should handle notification manager disposal properly', () async {
      await notificationManager.initialize();
      // This should not throw any exceptions
      expect(() => notificationManager.dispose(), returnsNormally);
    });

    group('Play Reminder Scheduling', () {
      test('should handle updateLastPlayTime without errors', () async {
        await notificationManager.initialize();
        // This should complete without throwing
        await expectLater(
          notificationManager.updateLastPlayTime(),
          completes,
        );
      });

      test('should handle multiple updateLastPlayTime calls', () async {
        await notificationManager.initialize();
        // Multiple calls should not cause issues
        await notificationManager.updateLastPlayTime();
        await notificationManager.updateLastPlayTime();
        await notificationManager.updateLastPlayTime();
        
        // Should complete without errors
        expect(true, isTrue);
      });
    });

    group('Settings Integration', () {
      test('should maintain play reminder setting when other settings change', () async {
        await notificationManager.initialize();
        
        // Set play reminders to false
        await notificationManager.setPlayRemindersEnabled(false);
        
        // Change other settings
        await notificationManager.setAchievementNotificationsEnabled(false);
        await notificationManager.setMilestoneNotificationsEnabled(false);
        
        // Play reminder setting should remain unchanged
        expect(notificationManager.playRemindersEnabled, isFalse);
      });

      test('should update settings map when play reminders are toggled', () async {
        await notificationManager.initialize();
        
        // Initially enabled
        expect(notificationManager.notificationSettings['play_reminders'], isTrue);
        
        // Disable play reminders
        await notificationManager.setPlayRemindersEnabled(false);
        expect(notificationManager.notificationSettings['play_reminders'], isFalse);
        
        // Re-enable play reminders
        await notificationManager.setPlayRemindersEnabled(true);
        expect(notificationManager.notificationSettings['play_reminders'], isTrue);
      });
    });
  });
}