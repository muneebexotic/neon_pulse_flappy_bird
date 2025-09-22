import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/achievement.dart';

/// Manages local notifications for achievements and milestones
class NotificationManager {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _achievementNotificationsKey = 'achievement_notifications_enabled';
  static const String _milestoneNotificationsKey = 'milestone_notifications_enabled';
  
  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  bool _notificationsEnabled = true;
  bool _achievementNotificationsEnabled = true;
  bool _milestoneNotificationsEnabled = true;

  /// Initialize the notification manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load user preferences
      await _loadPreferences();

      // Initialize notification plugin
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();

    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        final bool? granted = await androidImplementation?.requestNotificationsPermission();
        return granted ?? false;
      } else if (Platform.isIOS) {
        final bool? result = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        return result ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Failed to request notification permissions: $e');
      return false;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) await initialize();
    
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        final bool? enabled = await androidImplementation?.areNotificationsEnabled();
        return enabled ?? false;
      } else if (Platform.isIOS) {
        final bool? enabled = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.checkPermissions()
            .then((permissions) => permissions?.isEnabled ?? false);
        return enabled ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Failed to check notification permissions: $e');
      return false;
    }
  }

  /// Show achievement unlock notification
  Future<void> showAchievementNotification(Achievement achievement) async {
    if (!_notificationsEnabled || !_achievementNotificationsEnabled) return;
    if (!_isInitialized) await initialize();

    try {
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'achievement_channel',
        'Achievement Notifications',
        channelDescription: 'Notifications for unlocked achievements',
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFF00FFFF), // Neon cyan
        ledColor: const Color(0xFF00FFFF),
        ledOnMs: 1000,
        ledOffMs: 500,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
        styleInformation: BigTextStyleInformation(
          achievement.description,
          htmlFormatBigText: true,
          contentTitle: '🏆 Achievement Unlocked!',
          htmlFormatContentTitle: true,
          summaryText: 'Neon Pulse',
          htmlFormatSummaryText: true,
        ),
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        subtitle: 'Achievement Unlocked!',
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notificationsPlugin.show(
        achievement.hashCode,
        '🏆 ${achievement.name}',
        achievement.description,
        platformChannelSpecifics,
        payload: 'achievement:${achievement.id}',
      );
    } catch (e) {
      debugPrint('Failed to show achievement notification: $e');
    }
  }

  /// Show milestone notification for score achievements
  Future<void> showMilestoneNotification({
    required int score,
    required String milestone,
    String? customMessage,
  }) async {
    if (!_notificationsEnabled || !_milestoneNotificationsEnabled) return;
    if (!_isInitialized) await initialize();

    try {
      final String message = customMessage ?? 
          'You\'ve reached $milestone with a score of $score points!';

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'milestone_channel',
        'Milestone Notifications',
        channelDescription: 'Notifications for score milestones and progression',
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFFFF1493), // Neon pink
        ledColor: const Color(0xFFFF1493),
        ledOnMs: 1000,
        ledOffMs: 500,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
        styleInformation: BigTextStyleInformation(
          message,
          htmlFormatBigText: true,
          contentTitle: '🚀 Milestone Reached!',
          htmlFormatContentTitle: true,
          summaryText: 'Neon Pulse',
          htmlFormatSummaryText: true,
        ),
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        subtitle: 'Milestone Reached!',
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notificationsPlugin.show(
        score.hashCode,
        '🚀 $milestone',
        message,
        platformChannelSpecifics,
        payload: 'milestone:$score',
      );
    } catch (e) {
      debugPrint('Failed to show milestone notification: $e');
    }
  }

  /// Show high score notification
  Future<void> showHighScoreNotification({
    required int newScore,
    required int previousBest,
  }) async {
    if (!_notificationsEnabled || !_milestoneNotificationsEnabled) return;
    if (!_isInitialized) await initialize();

    try {
      final String message = previousBest > 0
          ? 'New personal best! You beat your previous score of $previousBest points!'
          : 'Congratulations on your first high score!';

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'highscore_channel',
        'High Score Notifications',
        channelDescription: 'Notifications for new high scores',
        importance: Importance.max,
        priority: Priority.max,
        color: const Color(0xFF39FF14), // Neon green
        ledColor: const Color(0xFF39FF14),
        ledOnMs: 1000,
        ledOffMs: 500,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        styleInformation: BigTextStyleInformation(
          message,
          htmlFormatBigText: true,
          contentTitle: '🎉 New High Score!',
          htmlFormatContentTitle: true,
          summaryText: 'Neon Pulse',
          htmlFormatSummaryText: true,
        ),
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        subtitle: 'New High Score!',
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notificationsPlugin.show(
        newScore.hashCode + 1000000, // Ensure unique ID
        '🎉 New High Score: $newScore',
        message,
        platformChannelSpecifics,
        payload: 'highscore:$newScore',
      );
    } catch (e) {
      debugPrint('Failed to show high score notification: $e');
    }
  }

  /// Show progression milestone notification
  Future<void> showProgressionNotification({
    required String title,
    required String message,
    String? payload,
  }) async {
    if (!_notificationsEnabled || !_milestoneNotificationsEnabled) return;
    if (!_isInitialized) await initialize();

    try {
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'progression_channel',
        'Progression Notifications',
        channelDescription: 'Notifications for game progression and unlocks',
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFF8A2BE2), // Neon purple
        ledColor: const Color(0xFF8A2BE2),
        ledOnMs: 750,
        ledOffMs: 750,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 300, 300, 300]),
        styleInformation: BigTextStyleInformation(
          message,
          htmlFormatBigText: true,
          contentTitle: title,
          htmlFormatContentTitle: true,
          summaryText: 'Neon Pulse',
          htmlFormatSummaryText: true,
        ),
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notificationsPlugin.show(
        title.hashCode,
        title,
        message,
        platformChannelSpecifics,
        payload: payload ?? 'progression',
      );
    } catch (e) {
      debugPrint('Failed to show progression notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel notifications: $e');
    }
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;
    
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Failed to cancel notification $id: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload == null) return;

    debugPrint('Notification tapped with payload: $payload');
    
    // Handle different notification types
    if (payload.startsWith('achievement:')) {
      final achievementId = payload.substring('achievement:'.length);
      _handleAchievementNotificationTap(achievementId);
    } else if (payload.startsWith('milestone:')) {
      final scoreStr = payload.substring('milestone:'.length);
      final score = int.tryParse(scoreStr);
      if (score != null) {
        _handleMilestoneNotificationTap(score);
      }
    } else if (payload.startsWith('highscore:')) {
      final scoreStr = payload.substring('highscore:'.length);
      final score = int.tryParse(scoreStr);
      if (score != null) {
        _handleHighScoreNotificationTap(score);
      }
    }
  }

  /// Handle achievement notification tap
  void _handleAchievementNotificationTap(String achievementId) {
    // This could navigate to achievements screen or show achievement details
    debugPrint('Achievement notification tapped: $achievementId');
  }

  /// Handle milestone notification tap
  void _handleMilestoneNotificationTap(int score) {
    // This could navigate to game or show milestone details
    debugPrint('Milestone notification tapped: $score');
  }

  /// Handle high score notification tap
  void _handleHighScoreNotificationTap(int score) {
    // This could navigate to leaderboard or game
    debugPrint('High score notification tapped: $score');
  }

  /// Load user preferences for notifications
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      _achievementNotificationsEnabled = 
          prefs.getBool(_achievementNotificationsKey) ?? true;
      _milestoneNotificationsEnabled = 
          prefs.getBool(_milestoneNotificationsKey) ?? true;
    } catch (e) {
      debugPrint('Failed to load notification preferences: $e');
    }
  }

  /// Save user preferences for notifications
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, _notificationsEnabled);
      await prefs.setBool(_achievementNotificationsKey, _achievementNotificationsEnabled);
      await prefs.setBool(_milestoneNotificationsKey, _milestoneNotificationsEnabled);
    } catch (e) {
      debugPrint('Failed to save notification preferences: $e');
    }
  }

  // Getters and setters for notification preferences
  bool get notificationsEnabled => _notificationsEnabled;
  bool get achievementNotificationsEnabled => _achievementNotificationsEnabled;
  bool get milestoneNotificationsEnabled => _milestoneNotificationsEnabled;

  /// Enable or disable all notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _savePreferences();
    
    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  /// Enable or disable achievement notifications
  Future<void> setAchievementNotificationsEnabled(bool enabled) async {
    _achievementNotificationsEnabled = enabled;
    await _savePreferences();
  }

  /// Enable or disable milestone notifications
  Future<void> setMilestoneNotificationsEnabled(bool enabled) async {
    _milestoneNotificationsEnabled = enabled;
    await _savePreferences();
  }

  /// Get notification settings for display in settings screen
  Map<String, bool> get notificationSettings => {
    'notifications_enabled': _notificationsEnabled,
    'achievement_notifications': _achievementNotificationsEnabled,
    'milestone_notifications': _milestoneNotificationsEnabled,
  };

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
  }
}