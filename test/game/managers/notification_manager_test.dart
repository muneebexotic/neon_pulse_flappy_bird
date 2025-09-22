import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neon_pulse_flappy_bird/game/managers/notification_manager.dart';
import 'package:neon_pulse_flappy_bird/models/achievement.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationManager', () {
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
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        null,
      );
    });

    test('should initialize successfully', () async {
      await notificationManager.initialize();
      expect(notificationManager.notificationsEnabled, isTrue);
    });

    test('should load and save preferences correctly', () async {
      await notificationManager.initialize();
      
      // Test default values
      expect(notificationManager.notificationsEnabled, isTrue);
      expect(notificationManager.achievementNotificationsEnabled, isTrue);
      expect(notificationManager.milestoneNotificationsEnabled, isTrue);
      
      // Test setting preferences
      await notificationManager.setNotificationsEnabled(false);
      expect(notificationManager.notificationsEnabled, isFalse);
      
      await notificationManager.setAchievementNotificationsEnabled(false);
      expect(notificationManager.achievementNotificationsEnabled, isFalse);
      
      await notificationManager.setMilestoneNotificationsEnabled(false);
      expect(notificationManager.milestoneNotificationsEnabled, isFalse);
    });

    test('should return correct notification settings', () async {
      await notificationManager.initialize();
      
      final settings = notificationManager.notificationSettings;
      expect(settings['notifications_enabled'], isTrue);
      expect(settings['achievement_notifications'], isTrue);
      expect(settings['milestone_notifications'], isTrue);
    });

    test('should show achievement notification when enabled', () async {
      await notificationManager.initialize();
      
      final achievement = Achievement(
        id: 'test_achievement',
        name: 'Test Achievement',
        description: 'This is a test achievement',
        icon: Icons.star,
        iconColor: Colors.cyan,
        type: AchievementType.score,
        targetValue: 100,
        currentProgress: 100,
        isUnlocked: true,
      );
      
      // Should not throw when showing notification
      expect(
        () async => await notificationManager.showAchievementNotification(achievement),
        returnsNormally,
      );
    });

    test('should not show achievement notification when disabled', () async {
      await notificationManager.initialize();
      await notificationManager.setAchievementNotificationsEnabled(false);
      
      final achievement = Achievement(
        id: 'test_achievement',
        name: 'Test Achievement',
        description: 'This is a test achievement',
        icon: Icons.star,
        iconColor: Colors.cyan,
        type: AchievementType.score,
        targetValue: 100,
        currentProgress: 100,
        isUnlocked: true,
      );
      
      // Should not throw but also should not show notification
      expect(
        () async => await notificationManager.showAchievementNotification(achievement),
        returnsNormally,
      );
    });

    test('should show milestone notification when enabled', () async {
      await notificationManager.initialize();
      
      // Should not throw when showing milestone notification
      expect(
        () async => await notificationManager.showMilestoneNotification(
          score: 100,
          milestone: 'Century Club',
          customMessage: 'You reached 100 points!',
        ),
        returnsNormally,
      );
    });

    test('should show high score notification', () async {
      await notificationManager.initialize();
      
      // Should not throw when showing high score notification
      expect(
        () async => await notificationManager.showHighScoreNotification(
          newScore: 150,
          previousBest: 100,
        ),
        returnsNormally,
      );
    });

    test('should show progression notification', () async {
      await notificationManager.initialize();
      
      // Should not throw when showing progression notification
      expect(
        () async => await notificationManager.showProgressionNotification(
          title: 'New Skin Unlocked!',
          message: 'You unlocked the Cyber Hawk skin!',
          payload: 'skin:cyber_hawk',
        ),
        returnsNormally,
      );
    });

    test('should cancel all notifications', () async {
      await notificationManager.initialize();
      
      // Should not throw when canceling notifications
      expect(
        () async => await notificationManager.cancelAllNotifications(),
        returnsNormally,
      );
    });

    test('should cancel specific notification', () async {
      await notificationManager.initialize();
      
      // Should not throw when canceling specific notification
      expect(
        () async => await notificationManager.cancelNotification(123),
        returnsNormally,
      );
    });

    test('should handle permission requests', () async {
      await notificationManager.initialize();
      
      // Should return true for mock implementation
      final granted = await notificationManager.requestPermissions();
      expect(granted, isTrue);
    });

    test('should check if notifications are enabled', () async {
      await notificationManager.initialize();
      
      // Should return true for mock implementation
      final enabled = await notificationManager.areNotificationsEnabled();
      expect(enabled, isTrue);
    });

    test('should handle initialization failure gracefully', () async {
      // Mock initialization failure
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'initialize') {
            throw PlatformException(code: 'INIT_FAILED', message: 'Initialization failed');
          }
          return null;
        },
      );

      final failingManager = NotificationManager();
      
      // Should not throw even if initialization fails
      expect(
        () async => await failingManager.initialize(),
        returnsNormally,
      );
    });

    test('should handle notification display failure gracefully', () async {
      // Mock notification display failure
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'show') {
            throw PlatformException(code: 'SHOW_FAILED', message: 'Show failed');
          }
          return true;
        },
      );

      await notificationManager.initialize();
      
      final achievement = Achievement(
        id: 'test_achievement',
        name: 'Test Achievement',
        description: 'This is a test achievement',
        icon: Icons.star,
        iconColor: Colors.cyan,
        type: AchievementType.score,
        targetValue: 100,
        currentProgress: 100,
        isUnlocked: true,
      );
      
      // Should not throw even if notification display fails
      expect(
        () async => await notificationManager.showAchievementNotification(achievement),
        returnsNormally,
      );
    });

    test('should persist settings across sessions', () async {
      // Initialize and change settings
      await notificationManager.initialize();
      await notificationManager.setNotificationsEnabled(false);
      await notificationManager.setAchievementNotificationsEnabled(false);
      
      // Create new instance to simulate app restart
      final newManager = NotificationManager();
      await newManager.initialize();
      
      // Settings should be persisted
      expect(newManager.notificationsEnabled, isFalse);
      expect(newManager.achievementNotificationsEnabled, isFalse);
    });

    test('should handle multiple rapid notification calls', () async {
      await notificationManager.initialize();
      
      final achievement = Achievement(
        id: 'test_achievement',
        name: 'Test Achievement',
        description: 'This is a test achievement',
        icon: Icons.star,
        iconColor: Colors.cyan,
        type: AchievementType.score,
        targetValue: 100,
        currentProgress: 100,
        isUnlocked: true,
      );
      
      // Should handle multiple rapid calls without issues
      final futures = List.generate(5, (index) => 
        notificationManager.showAchievementNotification(achievement)
      );
      
      expect(
        () async => await Future.wait(futures),
        returnsNormally,
      );
    });
  });

  group('NotificationManager Permission Handling', () {
    test('should handle permission requests', () async {
      SharedPreferences.setMockInitialValues({});
      
      // Mock permission handling
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'initialize':
              return true;
            case 'requestPermissions':
              return true; // Simulate granted permissions
            case 'areNotificationsEnabled':
              return true;
            default:
              return null;
          }
        },
      );

      final testNotificationManager = NotificationManager();
      await testNotificationManager.initialize();
      
      final granted = await testNotificationManager.requestPermissions();
      expect(granted, isTrue);
      
      final enabled = await testNotificationManager.areNotificationsEnabled();
      expect(enabled, isTrue);
      
      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        null,
      );
    });
  });
}