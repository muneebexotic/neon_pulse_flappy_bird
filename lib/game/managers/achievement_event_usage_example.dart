// This file provides usage examples for the AchievementEventManager
// It's not meant to be used in production, but serves as documentation

import 'dart:async';
import 'package:flutter/material.dart';
import 'achievement_event_manager.dart';
import '../../models/achievement.dart';

/// Example class showing how to use the AchievementEventManager
class AchievementEventUsageExample {
  late StreamSubscription<AchievementEvent> _allEventsSubscription;
  late StreamSubscription<AchievementProgressEvent> _progressSubscription;
  late StreamSubscription<AchievementUnlockedEvent> _unlockedSubscription;
  late StreamSubscription<StatisticsUpdatedEvent> _statisticsSubscription;

  final AchievementEventManager _eventManager = AchievementEventManager.instance;

  /// Example: Subscribe to all achievement events
  void subscribeToAllEvents() {
    _allEventsSubscription = _eventManager.achievementEvents.listen((event) {
      print('Achievement event: ${event.runtimeType} for ${event.achievementId}');
      
      if (event is AchievementProgressEvent) {
        print('Progress changed from ${event.oldProgress} to ${event.newProgress}');
      } else if (event is AchievementUnlockedEvent) {
        print('Achievement unlocked: ${event.achievement.name}');
      } else if (event is StatisticsUpdatedEvent) {
        print('Statistics updated: ${event.changedStatistics}');
      }
    });
  }

  /// Example: Subscribe to progress events only
  void subscribeToProgressEvents() {
    _progressSubscription = _eventManager.progressEvents.listen((event) {
      print('Achievement ${event.achievement.name} progress: ${(event.newProgress * 100).toInt()}%');
      
      if (event.isSignificantMilestone) {
        print('Significant milestone reached!');
      }
    });
  }

  /// Example: Subscribe to unlock events only
  void subscribeToUnlockEvents() {
    _unlockedSubscription = _eventManager.unlockedEvents.listen((event) {
      print('🏆 Achievement Unlocked: ${event.achievement.name}');
      print('Description: ${event.achievement.description}');
      
      // Show notification or update UI here
      _showAchievementNotification(event.achievement);
    });
  }

  /// Example: Subscribe to statistics updates
  void subscribeToStatisticsUpdates() {
    _statisticsSubscription = _eventManager.statisticsEvents.listen((event) {
      print('Game statistics updated:');
      for (final entry in event.changedStatistics.entries) {
        print('  ${entry.key}: +${entry.value}');
      }
    });
  }

  /// Example: Subscribe to specific achievement
  void subscribeToSpecificAchievement(String achievementId) {
    _eventManager.subscribeToAchievement(achievementId, (event) {
      print('Event for $achievementId: ${event.runtimeType}');
    });
  }

  /// Example: Fire achievement progress event
  void simulateProgressUpdate() {
    final achievement = const Achievement(
      id: 'test_achievement',
      name: 'Test Achievement',
      description: 'A test achievement',
      icon: Icons.star,
      iconColor: Colors.yellow,
      targetValue: 100,
      type: AchievementType.score,
      trackingType: AchievementTrackingType.singleRun,
      resetsOnFailure: true,
      currentProgress: 75,
    );

    _eventManager.notifyAchievementProgress(
      achievement: achievement,
      oldProgress: 0.5, // 50%
      newProgress: 0.75, // 75%
    );
  }

  /// Example: Fire achievement unlock event
  void simulateAchievementUnlock() {
    final achievement = const Achievement(
      id: 'unlocked_achievement',
      name: 'Unlocked Achievement',
      description: 'This achievement was just unlocked',
      icon: Icons.emoji_events,
      iconColor: Color(0xFFFFD700),
      targetValue: 100,
      type: AchievementType.score,
      trackingType: AchievementTrackingType.milestone,
      currentProgress: 100,
      isUnlocked: true,
    );

    _eventManager.notifyAchievementUnlocked(achievement);
  }

  /// Example: Fire statistics update event
  void simulateStatisticsUpdate() {
    final oldStats = {
      'score': 100,
      'gamesPlayed': 5,
      'pulseUsage': 20,
    };

    final newStats = {
      'score': 150,
      'gamesPlayed': 6,
      'pulseUsage': 25,
      'powerUpsCollected': 3,
    };

    _eventManager.notifyStatisticsUpdated(
      oldStatistics: oldStats,
      newStatistics: newStats,
    );
  }

  /// Example notification handler
  void _showAchievementNotification(Achievement achievement) {
    // In a real app, this would show a UI notification
    print('🎉 Showing notification for: ${achievement.name}');
  }

  /// Clean up subscriptions
  void dispose() {
    _allEventsSubscription.cancel();
    _progressSubscription.cancel();
    _unlockedSubscription.cancel();
    _statisticsSubscription.cancel();
  }
}

/// Example widget showing how to use events in a Flutter widget
class AchievementEventWidget extends StatefulWidget {
  const AchievementEventWidget({super.key});

  @override
  State<AchievementEventWidget> createState() => _AchievementEventWidgetState();
}

class _AchievementEventWidgetState extends State<AchievementEventWidget> {
  final AchievementEventManager _eventManager = AchievementEventManager.instance;
  StreamSubscription<AchievementUnlockedEvent>? _unlockedSubscription;
  List<Achievement> _recentUnlocks = [];

  @override
  void initState() {
    super.initState();
    _subscribeToUnlocks();
  }

  void _subscribeToUnlocks() {
    _unlockedSubscription = _eventManager.unlockedEvents.listen((event) {
      setState(() {
        _recentUnlocks.add(event.achievement);
        // Keep only the last 5 unlocks
        if (_recentUnlocks.length > 5) {
          _recentUnlocks.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _unlockedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Recent Achievement Unlocks:'),
        ..._recentUnlocks.map((achievement) => ListTile(
          leading: Icon(achievement.icon, color: achievement.iconColor),
          title: Text(achievement.name),
          subtitle: Text(achievement.description),
        )),
      ],
    );
  }
}