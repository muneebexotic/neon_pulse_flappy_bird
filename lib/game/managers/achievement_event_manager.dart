import 'dart:async';
import '../../models/achievement.dart';

/// Base class for all achievement-related events
abstract class AchievementEvent {
  final String achievementId;
  final DateTime timestamp;

  const AchievementEvent({
    required this.achievementId,
    required this.timestamp,
  });
}

/// Event fired when achievement progress changes
class AchievementProgressEvent extends AchievementEvent {
  final double oldProgress;
  final double newProgress;
  final Achievement achievement;

  const AchievementProgressEvent({
    required String achievementId,
    required DateTime timestamp,
    required this.oldProgress,
    required this.newProgress,
    required this.achievement,
  }) : super(achievementId: achievementId, timestamp: timestamp);

  /// Get progress change amount
  double get progressChange => newProgress - oldProgress;

  /// Check if this is a significant progress milestone (every 25%)
  bool get isSignificantMilestone {
    final oldMilestone = (oldProgress * 4).floor();
    final newMilestone = (newProgress * 4).floor();
    return newMilestone > oldMilestone;
  }
}

/// Event fired when an achievement is fully unlocked
class AchievementUnlockedEvent extends AchievementEvent {
  final Achievement achievement;

  const AchievementUnlockedEvent({
    required String achievementId,
    required DateTime timestamp,
    required this.achievement,
  }) : super(achievementId: achievementId, timestamp: timestamp);
}

/// Event fired when game statistics are updated
class StatisticsUpdatedEvent extends AchievementEvent {
  final Map<String, int> oldStatistics;
  final Map<String, int> newStatistics;
  final Map<String, int> changedStatistics;

  const StatisticsUpdatedEvent({
    required DateTime timestamp,
    required this.oldStatistics,
    required this.newStatistics,
    required this.changedStatistics,
  }) : super(achievementId: 'statistics', timestamp: timestamp);

  /// Get the change for a specific statistic
  int getStatisticChange(String key) {
    return changedStatistics[key] ?? 0;
  }

  /// Check if a specific statistic changed
  bool hasStatisticChanged(String key) {
    return changedStatistics.containsKey(key);
  }
}

/// Manages achievement events and provides stream-based event handling
class AchievementEventManager {
  static AchievementEventManager? _instance;
  
  /// Singleton instance
  static AchievementEventManager get instance {
    _instance ??= AchievementEventManager._internal();
    return _instance!;
  }

  AchievementEventManager._internal();

  // Stream controllers for different event types
  final StreamController<AchievementEvent> _eventController = 
      StreamController<AchievementEvent>.broadcast();
  
  final StreamController<AchievementProgressEvent> _progressController = 
      StreamController<AchievementProgressEvent>.broadcast();
  
  final StreamController<AchievementUnlockedEvent> _unlockedController = 
      StreamController<AchievementUnlockedEvent>.broadcast();
  
  final StreamController<StatisticsUpdatedEvent> _statisticsController = 
      StreamController<StatisticsUpdatedEvent>.broadcast();

  /// Stream of all achievement events
  Stream<AchievementEvent> get achievementEvents => _eventController.stream;

  /// Stream of achievement progress events only
  Stream<AchievementProgressEvent> get progressEvents => _progressController.stream;

  /// Stream of achievement unlocked events only
  Stream<AchievementUnlockedEvent> get unlockedEvents => _unlockedController.stream;

  /// Stream of statistics updated events only
  Stream<StatisticsUpdatedEvent> get statisticsEvents => _statisticsController.stream;

  /// Notify that achievement progress has changed
  void notifyAchievementProgress({
    required Achievement achievement,
    required double oldProgress,
    required double newProgress,
  }) {
    final event = AchievementProgressEvent(
      achievementId: achievement.id,
      timestamp: DateTime.now(),
      oldProgress: oldProgress,
      newProgress: newProgress,
      achievement: achievement,
    );

    _eventController.add(event);
    _progressController.add(event);
  }

  /// Notify that an achievement has been unlocked
  void notifyAchievementUnlocked(Achievement achievement) {
    final event = AchievementUnlockedEvent(
      achievementId: achievement.id,
      timestamp: DateTime.now(),
      achievement: achievement,
    );

    _eventController.add(event);
    _unlockedController.add(event);
  }

  /// Notify that game statistics have been updated
  void notifyStatisticsUpdated({
    required Map<String, int> oldStatistics,
    required Map<String, int> newStatistics,
  }) {
    // Calculate changed statistics
    final changedStatistics = <String, int>{};
    
    for (final entry in newStatistics.entries) {
      final oldValue = oldStatistics[entry.key] ?? 0;
      final newValue = entry.value;
      
      if (newValue != oldValue) {
        changedStatistics[entry.key] = newValue - oldValue;
      }
    }

    // Only fire event if there are actual changes
    if (changedStatistics.isNotEmpty) {
      final event = StatisticsUpdatedEvent(
        timestamp: DateTime.now(),
        oldStatistics: Map.from(oldStatistics),
        newStatistics: Map.from(newStatistics),
        changedStatistics: changedStatistics,
      );

      _eventController.add(event);
      _statisticsController.add(event);
    }
  }

  /// Subscribe to achievement events for a specific achievement
  StreamSubscription<AchievementEvent> subscribeToAchievement(
    String achievementId,
    void Function(AchievementEvent) onEvent,
  ) {
    return achievementEvents
        .where((event) => event.achievementId == achievementId)
        .listen(onEvent);
  }

  /// Subscribe to progress events for a specific achievement
  StreamSubscription<AchievementProgressEvent> subscribeToProgress(
    String achievementId,
    void Function(AchievementProgressEvent) onProgress,
  ) {
    return progressEvents
        .where((event) => event.achievementId == achievementId)
        .listen(onProgress);
  }

  /// Subscribe to unlock events for a specific achievement
  StreamSubscription<AchievementUnlockedEvent> subscribeToUnlocks(
    String achievementId,
    void Function(AchievementUnlockedEvent) onUnlock,
  ) {
    return unlockedEvents
        .where((event) => event.achievementId == achievementId)
        .listen(onUnlock);
  }

  /// Subscribe to all achievement unlock events
  StreamSubscription<AchievementUnlockedEvent> subscribeToAllUnlocks(
    void Function(AchievementUnlockedEvent) onUnlock,
  ) {
    return unlockedEvents.listen(onUnlock);
  }

  /// Subscribe to all achievement progress events
  StreamSubscription<AchievementProgressEvent> subscribeToAllProgress(
    void Function(AchievementProgressEvent) onProgress,
  ) {
    return progressEvents.listen(onProgress);
  }

  /// Subscribe to statistics updates
  StreamSubscription<StatisticsUpdatedEvent> subscribeToStatistics(
    void Function(StatisticsUpdatedEvent) onStatisticsUpdate,
  ) {
    return statisticsEvents.listen(onStatisticsUpdate);
  }

  /// Get the number of active listeners for debugging
  int get activeListeners {
    return _eventController.hasListener ? 1 : 0;
  }

  /// Check if there are any active listeners
  bool get hasListeners {
    return _eventController.hasListener ||
           _progressController.hasListener ||
           _unlockedController.hasListener ||
           _statisticsController.hasListener;
  }

  /// Dispose of all stream controllers
  void dispose() {
    _eventController.close();
    _progressController.close();
    _unlockedController.close();
    _statisticsController.close();
    _instance = null;
  }

  /// Reset the singleton instance (useful for testing)
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}