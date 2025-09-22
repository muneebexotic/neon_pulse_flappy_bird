import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/game/managers/achievement_event_manager.dart';
import '../../../lib/models/achievement.dart';

void main() {
  group('AchievementEventManager', () {
    late AchievementEventManager eventManager;
    late Achievement testAchievement;

    setUp(() {
      // Reset singleton before each test
      AchievementEventManager.reset();
      eventManager = AchievementEventManager.instance;
      
      testAchievement = const Achievement(
        id: 'test_achievement',
        name: 'Test Achievement',
        description: 'A test achievement',
        icon: Icons.star,
        iconColor: Colors.yellow,
        targetValue: 100,
        type: AchievementType.score,
        currentProgress: 50,
      );
    });

    tearDown(() {
      eventManager.dispose();
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = AchievementEventManager.instance;
        final instance2 = AchievementEventManager.instance;
        expect(instance1, same(instance2));
      });

      test('should create new instance after reset', () {
        final instance1 = AchievementEventManager.instance;
        AchievementEventManager.reset();
        final instance2 = AchievementEventManager.instance;
        expect(instance1, isNot(same(instance2)));
      });
    });

    group('Achievement Progress Events', () {
      test('should notify achievement progress changes', () async {
        final events = <AchievementProgressEvent>[];
        final subscription = eventManager.progressEvents.listen(events.add);

        eventManager.notifyAchievementProgress(
          achievement: testAchievement,
          oldProgress: 0.3,
          newProgress: 0.7,
        );

        await Future.delayed(Duration.zero); // Allow event to propagate

        expect(events, hasLength(1));
        expect(events.first.achievementId, equals('test_achievement'));
        expect(events.first.oldProgress, equals(0.3));
        expect(events.first.newProgress, equals(0.7));
        expect(events.first.progressChange, closeTo(0.4, 0.001));
        expect(events.first.achievement, equals(testAchievement));

        await subscription.cancel();
      });

      test('should detect significant milestones', () {
        final event = AchievementProgressEvent(
          achievementId: 'test',
          timestamp: DateTime.now(),
          oldProgress: 0.2, // 20%
          newProgress: 0.8, // 80%
          achievement: testAchievement,
        );

        expect(event.isSignificantMilestone, isTrue);
      });

      test('should not detect insignificant progress changes', () {
        final event = AchievementProgressEvent(
          achievementId: 'test',
          timestamp: DateTime.now(),
          oldProgress: 0.2, // 20%
          newProgress: 0.22, // 22%
          achievement: testAchievement,
        );

        expect(event.isSignificantMilestone, isFalse);
      });
    });

    group('Achievement Unlocked Events', () {
      test('should notify achievement unlocks', () async {
        final events = <AchievementUnlockedEvent>[];
        final subscription = eventManager.unlockedEvents.listen(events.add);

        eventManager.notifyAchievementUnlocked(testAchievement);

        await Future.delayed(Duration.zero); // Allow event to propagate

        expect(events, hasLength(1));
        expect(events.first.achievementId, equals('test_achievement'));
        expect(events.first.achievement, equals(testAchievement));

        await subscription.cancel();
      });
    });

    group('Statistics Updated Events', () {
      test('should notify statistics updates with changes', () async {
        final events = <StatisticsUpdatedEvent>[];
        final subscription = eventManager.statisticsEvents.listen(events.add);

        final oldStats = {'score': 100, 'gamesPlayed': 5};
        final newStats = {'score': 150, 'gamesPlayed': 6, 'pulseUsage': 10};

        eventManager.notifyStatisticsUpdated(
          oldStatistics: oldStats,
          newStatistics: newStats,
        );

        await Future.delayed(Duration.zero); // Allow event to propagate

        expect(events, hasLength(1));
        expect(events.first.changedStatistics, equals({
          'score': 50,
          'gamesPlayed': 1,
          'pulseUsage': 10,
        }));
        expect(events.first.getStatisticChange('score'), equals(50));
        expect(events.first.hasStatisticChanged('score'), isTrue);
        expect(events.first.hasStatisticChanged('nonexistent'), isFalse);

        await subscription.cancel();
      });

      test('should not notify when no statistics change', () async {
        final events = <StatisticsUpdatedEvent>[];
        final subscription = eventManager.statisticsEvents.listen(events.add);

        final stats = {'score': 100, 'gamesPlayed': 5};

        eventManager.notifyStatisticsUpdated(
          oldStatistics: stats,
          newStatistics: stats,
        );

        await Future.delayed(Duration.zero); // Allow event to propagate

        expect(events, isEmpty);

        await subscription.cancel();
      });
    });

    group('Event Broadcasting', () {
      test('should broadcast to all achievement events stream', () async {
        final allEvents = <AchievementEvent>[];
        final subscription = eventManager.achievementEvents.listen(allEvents.add);

        // Send different types of events
        eventManager.notifyAchievementProgress(
          achievement: testAchievement,
          oldProgress: 0.3,
          newProgress: 0.7,
        );

        eventManager.notifyAchievementUnlocked(testAchievement);

        eventManager.notifyStatisticsUpdated(
          oldStatistics: {'score': 100},
          newStatistics: {'score': 150},
        );

        await Future.delayed(Duration.zero); // Allow events to propagate

        expect(allEvents, hasLength(3));
        expect(allEvents[0], isA<AchievementProgressEvent>());
        expect(allEvents[1], isA<AchievementUnlockedEvent>());
        expect(allEvents[2], isA<StatisticsUpdatedEvent>());

        await subscription.cancel();
      });

      test('should support multiple listeners', () async {
        final events1 = <AchievementEvent>[];
        final events2 = <AchievementEvent>[];
        
        final subscription1 = eventManager.achievementEvents.listen(events1.add);
        final subscription2 = eventManager.achievementEvents.listen(events2.add);

        eventManager.notifyAchievementUnlocked(testAchievement);

        await Future.delayed(Duration.zero); // Allow event to propagate

        expect(events1, hasLength(1));
        expect(events2, hasLength(1));
        expect(events1.first.achievementId, equals('test_achievement'));
        expect(events2.first.achievementId, equals('test_achievement'));

        await subscription1.cancel();
        await subscription2.cancel();
      });
    });

    group('Subscription Methods', () {
      test('should subscribe to specific achievement events', () async {
        final events = <AchievementEvent>[];
        final subscription = eventManager.subscribeToAchievement(
          'test_achievement',
          events.add,
        );

        // Send event for target achievement
        eventManager.notifyAchievementUnlocked(testAchievement);

        // Send event for different achievement
        final otherAchievement = testAchievement.copyWith();
        eventManager.notifyAchievementUnlocked(
          Achievement(
            id: 'other_achievement',
            name: 'Other',
            description: 'Other achievement',
            icon: Icons.star,
            iconColor: Colors.blue,
            targetValue: 50,
            type: AchievementType.score,
          ),
        );

        await Future.delayed(Duration.zero); // Allow events to propagate

        expect(events, hasLength(1));
        expect(events.first.achievementId, equals('test_achievement'));

        await subscription.cancel();
      });

      test('should subscribe to specific achievement progress', () async {
        final events = <AchievementProgressEvent>[];
        final subscription = eventManager.subscribeToProgress(
          'test_achievement',
          events.add,
        );

        eventManager.notifyAchievementProgress(
          achievement: testAchievement,
          oldProgress: 0.3,
          newProgress: 0.7,
        );

        await Future.delayed(Duration.zero); // Allow event to propagate

        expect(events, hasLength(1));
        expect(events.first.achievementId, equals('test_achievement'));

        await subscription.cancel();
      });

      test('should subscribe to all unlocks', () async {
        final events = <AchievementUnlockedEvent>[];
        final subscription = eventManager.subscribeToAllUnlocks(events.add);

        eventManager.notifyAchievementUnlocked(testAchievement);

        await Future.delayed(Duration.zero); // Allow event to propagate

        expect(events, hasLength(1));
        expect(events.first.achievementId, equals('test_achievement'));

        await subscription.cancel();
      });

      test('should subscribe to all progress events', () async {
        final events = <AchievementProgressEvent>[];
        final subscription = eventManager.subscribeToAllProgress(events.add);

        eventManager.notifyAchievementProgress(
          achievement: testAchievement,
          oldProgress: 0.3,
          newProgress: 0.7,
        );

        await Future.delayed(Duration.zero); // Allow event to propagate

        expect(events, hasLength(1));
        expect(events.first.achievementId, equals('test_achievement'));

        await subscription.cancel();
      });

      test('should subscribe to statistics updates', () async {
        final events = <StatisticsUpdatedEvent>[];
        final subscription = eventManager.subscribeToStatistics(events.add);

        eventManager.notifyStatisticsUpdated(
          oldStatistics: {'score': 100},
          newStatistics: {'score': 150},
        );

        await Future.delayed(Duration.zero); // Allow event to propagate

        expect(events, hasLength(1));
        expect(events.first.changedStatistics['score'], equals(50));

        await subscription.cancel();
      });
    });

    group('Listener Management', () {
      test('should track active listeners', () {
        expect(eventManager.hasListeners, isFalse);

        final subscription = eventManager.achievementEvents.listen((_) {});
        expect(eventManager.hasListeners, isTrue);

        subscription.cancel();
      });
    });

    group('Disposal', () {
      test('should dispose all streams', () {
        eventManager.dispose();
        
        // After disposal, streams should be closed
        expect(eventManager.achievementEvents.isBroadcast, isTrue);
        // The stream controller is closed, but we can still listen (it just won't emit)
        final subscription = eventManager.achievementEvents.listen((_) {});
        expect(subscription, isNotNull);
        subscription.cancel();
      });
    });
  });
}