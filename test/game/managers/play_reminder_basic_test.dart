import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/game/managers/notification_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Play Reminder Basic Tests', () {
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
      
      notificationManager = NotificationManager(disableTimers: true);
    });

    tearDown(() {
      notificationManager.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        null,
      );
    });

    test('should have play reminders enabled by default', () async {
      await notificationManager.initialize();
      expect(notificationManager.playRemindersEnabled, isTrue);
    });

    test('should include play reminders in notification settings', () async {
      await notificationManager.initialize();
      final settings = notificationManager.notificationSettings;
      expect(settings.containsKey('play_reminders'), isTrue);
      expect(settings['play_reminders'], isTrue);
    });

    test('should toggle play reminder setting', () async {
      await notificationManager.initialize();
      
      // Initially enabled
      expect(notificationManager.playRemindersEnabled, isTrue);
      
      // Disable play reminders
      await notificationManager.setPlayRemindersEnabled(false);
      expect(notificationManager.playRemindersEnabled, isFalse);
      
      // Re-enable play reminders
      await notificationManager.setPlayRemindersEnabled(true);
      expect(notificationManager.playRemindersEnabled, isTrue);
    });

    test('should update last play time without errors', () async {
      await notificationManager.initialize();
      
      // This should complete without throwing
      await expectLater(
        notificationManager.updateLastPlayTime(),
        completes,
      );
    });

    test('should show play reminder notification', () async {
      await notificationManager.initialize();
      
      // Should not throw when showing play reminder notification
      expect(
        () async => await notificationManager.showPlayReminderNotification(),
        returnsNormally,
      );
    });
  });
}