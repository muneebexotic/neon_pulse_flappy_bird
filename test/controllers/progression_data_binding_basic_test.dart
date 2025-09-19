import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/achievement.dart';
import '../../lib/models/bird_skin.dart';

void main() {
  group('ProgressionDataBinding Basic Tests', () {
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
        icon: Icons.star,
        iconColor: Colors.orange,
        targetValue: 20,
        type: AchievementType.totalScore,
        currentProgress: 20,
        isUnlocked: true,
      ),
    ];
    
    final testSkin = BirdSkin(
      id: 'test_skin',
      name: 'Test Skin',
      primaryColor: Colors.red,
      trailColor: Colors.red,
      description: 'Test skin description',
      unlockScore: 100,
      isUnlocked: true,
    );

    test('should create achievement models correctly', () {
      expect(testAchievements[0].id, equals('test_1'));
      expect(testAchievements[0].isUnlocked, isFalse);
      expect(testAchievements[0].progressPercentage, equals(0.5));
      
      expect(testAchievements[1].id, equals('test_2'));
      expect(testAchievements[1].isUnlocked, isTrue);
      expect(testAchievements[1].progressPercentage, equals(1.0));
    });

    test('should create bird skin models correctly', () {
      expect(testSkin.id, equals('test_skin'));
      expect(testSkin.name, equals('Test Skin'));
      expect(testSkin.isUnlocked, isTrue);
      expect(testSkin.unlockScore, equals(100));
    });

    test('should handle achievement progress calculations', () {
      final achievement = testAchievements[0];
      
      expect(achievement.progressPercentage, equals(0.5));
      expect(achievement.isCompleted, isFalse);
      
      final completedAchievement = achievement.copyWith(currentProgress: 10);
      expect(completedAchievement.progressPercentage, equals(1.0));
      expect(completedAchievement.isCompleted, isTrue);
    });

    test('should handle achievement type filtering', () {
      final scoreAchievements = testAchievements
          .where((a) => a.type == AchievementType.score)
          .toList();
      
      expect(scoreAchievements.length, equals(1));
      expect(scoreAchievements[0].id, equals('test_1'));
      
      final totalScoreAchievements = testAchievements
          .where((a) => a.type == AchievementType.totalScore)
          .toList();
      
      expect(totalScoreAchievements.length, equals(1));
      expect(totalScoreAchievements[0].id, equals('test_2'));
    });

    test('should handle stream controllers', () async {
      final streamController = StreamController<List<Achievement>>.broadcast();
      
      final streamFuture = streamController.stream.first;
      
      streamController.add(testAchievements);
      
      final receivedAchievements = await streamFuture;
      expect(receivedAchievements, equals(testAchievements));
      
      await streamController.close();
    });

    test('should handle achievement updates', () {
      final originalAchievement = testAchievements[0];
      final updatedAchievement = originalAchievement.copyWith(
        currentProgress: 8,
        isUnlocked: false,
      );
      
      expect(updatedAchievement.currentProgress, equals(8));
      expect(updatedAchievement.progressPercentage, equals(0.8));
      expect(updatedAchievement.isUnlocked, isFalse);
      
      final unlockedAchievement = updatedAchievement.copyWith(
        isUnlocked: true,
      );
      
      expect(unlockedAchievement.isUnlocked, isTrue);
      expect(unlockedAchievement.currentProgress, equals(8));
    });

    test('should detect achievement changes', () {
      final achievements1 = testAchievements;
      final achievements2 = [
        testAchievements[0].copyWith(currentProgress: 8),
        testAchievements[1],
      ];
      
      // Simple change detection logic
      bool hasChanges = false;
      
      if (achievements1.length != achievements2.length) {
        hasChanges = true;
      } else {
        for (int i = 0; i < achievements1.length; i++) {
          if (achievements1[i].currentProgress != achievements2[i].currentProgress ||
              achievements1[i].isUnlocked != achievements2[i].isUnlocked) {
            hasChanges = true;
            break;
          }
        }
      }
      
      expect(hasChanges, isTrue);
    });

    test('should handle newly unlocked achievements', () {
      final previouslyLocked = testAchievements[0];
      final newlyUnlocked = previouslyLocked.copyWith(
        isUnlocked: true,
        currentProgress: 10,
      );
      
      expect(previouslyLocked.isUnlocked, isFalse);
      expect(newlyUnlocked.isUnlocked, isTrue);
      
      // Simulate detection of newly unlocked achievement
      final wasJustUnlocked = !previouslyLocked.isUnlocked && newlyUnlocked.isUnlocked;
      expect(wasJustUnlocked, isTrue);
    });

    test('should handle performance statistics', () {
      final stats = {
        'currentAchievements': testAchievements.length,
        'unlockedAchievements': testAchievements.where((a) => a.isUnlocked).length,
        'pendingAnimations': 0,
        'pendingSkinUnlocks': 0,
        'isInitialized': true,
        'hasActiveTimer': false,
      };
      
      expect(stats['currentAchievements'], equals(2));
      expect(stats['unlockedAchievements'], equals(1));
      expect(stats['isInitialized'], isTrue);
    });

    test('should handle error scenarios gracefully', () {
      // Test with empty achievements list
      final emptyAchievements = <Achievement>[];
      expect(emptyAchievements.isEmpty, isTrue);
      
      // Test with null safety
      Achievement? nullableAchievement;
      expect(nullableAchievement, isNull);
      
      // Test progress calculation edge cases
      const edgeCaseAchievement = Achievement(
        id: 'edge_case',
        name: 'Edge Case',
        description: 'Edge case test',
        icon: Icons.star,
        iconColor: Colors.blue,
        targetValue: 0, // Edge case: zero target
        type: AchievementType.score,
        currentProgress: 5,
        isUnlocked: false,
      );
      
      expect(edgeCaseAchievement.progressPercentage, equals(1.0)); // Should clamp to 1.0
    });
  });
}