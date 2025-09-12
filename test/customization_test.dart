import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/game/managers/customization_manager.dart';
import '../lib/models/bird_skin.dart';
import '../lib/models/achievement.dart';

void main() {
  group('CustomizationManager Tests', () {
    late CustomizationManager customizationManager;

    setUp(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      customizationManager = CustomizationManager();
      await customizationManager.initialize();
    });

    group('Skin Management', () {
      test('should initialize with default skins', () {
        final skins = customizationManager.availableSkins;
        expect(skins.isNotEmpty, true);
        expect(skins.first.isUnlocked, true); // Default skin should be unlocked
      });

      test('should have default skin selected initially', () {
        final selectedSkin = customizationManager.selectedSkin;
        expect(selectedSkin.id, 'default');
        expect(selectedSkin.isUnlocked, true);
      });

      test('should unlock skins based on score', () async {
        const testScore = 100;
        final newlyUnlocked = await customizationManager.checkAndUnlockSkins(testScore);
        
        // Should unlock skins with unlock score <= 100
        expect(newlyUnlocked.isNotEmpty, true);
        
        final unlockedSkins = customizationManager.unlockedSkins;
        final highScoreSkins = unlockedSkins.where((skin) => skin.unlockScore <= testScore);
        expect(highScoreSkins.isNotEmpty, true);
      });

      test('should not unlock skins with higher score requirements', () async {
        const testScore = 25;
        await customizationManager.checkAndUnlockSkins(testScore);
        
        final unlockedSkins = customizationManager.unlockedSkins;
        final lockedSkins = unlockedSkins.where((skin) => skin.unlockScore > testScore);
        expect(lockedSkins.isEmpty, true);
      });

      test('should select unlocked skin successfully', () async {
        // First unlock a skin
        await customizationManager.checkAndUnlockSkins(100);
        
        // Find an unlocked skin that's not the default
        final unlockedSkin = customizationManager.unlockedSkins
            .firstWhere((skin) => skin.id != 'default');
        
        final success = await customizationManager.selectSkin(unlockedSkin.id);
        expect(success, true);
        expect(customizationManager.selectedSkin.id, unlockedSkin.id);
      });

      test('should not select locked skin', () async {
        // Find a locked skin
        final lockedSkin = customizationManager.availableSkins
            .firstWhere((skin) => !skin.isUnlocked);
        
        final success = await customizationManager.selectSkin(lockedSkin.id);
        expect(success, false);
        expect(customizationManager.selectedSkin.id, isNot(lockedSkin.id));
      });
    });

    group('Achievement System', () {
      test('should initialize with default achievements', () {
        final achievements = customizationManager.achievements;
        expect(achievements.isNotEmpty, true);
        expect(achievements.every((a) => !a.isUnlocked), true); // All should start locked
      });

      test('should unlock score-based achievements', () async {
        const testScore = 100;
        final newAchievements = await customizationManager.updateStatistics(
          score: testScore,
        );
        
        // Check if any score-based achievements were unlocked
        final scoreAchievements = customizationManager.achievements
            .where((a) => a.type == AchievementType.score && a.targetValue <= testScore);
        
        if (scoreAchievements.isNotEmpty) {
          expect(scoreAchievements.every((a) => a.isUnlocked), true);
        }
      });

      test('should track cumulative statistics', () async {
        // Update statistics multiple times
        await customizationManager.updateStatistics(score: 50, gamesPlayed: 1);
        await customizationManager.updateStatistics(score: 75, gamesPlayed: 1);
        
        final stats = customizationManager.gameStatistics;
        expect(stats['totalScore'], 125); // 50 + 75
        expect(stats['gamesPlayed'], 2);
        expect(stats['highScore'], 75); // Higher of the two scores
      });

      test('should unlock achievements with reward skins', () async {
        // Find an achievement with a reward skin
        final rewardAchievement = customizationManager.achievements
            .firstWhere((a) => a.rewardSkinId != null);
        
        // Update statistics to unlock the achievement
        switch (rewardAchievement.type) {
          case AchievementType.score:
            await customizationManager.updateStatistics(
              score: rewardAchievement.targetValue,
            );
            break;
          case AchievementType.gamesPlayed:
            await customizationManager.updateStatistics(
              gamesPlayed: rewardAchievement.targetValue,
            );
            break;
          case AchievementType.pulseUsage:
            await customizationManager.updateStatistics(
              pulseUsage: rewardAchievement.targetValue,
            );
            break;
          case AchievementType.powerUps:
            await customizationManager.updateStatistics(
              powerUpsCollected: rewardAchievement.targetValue,
            );
            break;
          default:
            break;
        }
        
        // Check if achievement is unlocked
        final updatedAchievement = customizationManager.achievements
            .firstWhere((a) => a.id == rewardAchievement.id);
        expect(updatedAchievement.isUnlocked, true);
        
        // Check if reward skin is available and unlocked
        if (rewardAchievement.rewardSkinId != null) {
          final rewardSkin = customizationManager.availableSkins
              .where((s) => s.id == rewardAchievement.rewardSkinId)
              .firstOrNull;
          
          if (rewardSkin != null) {
            expect(rewardSkin.isUnlocked, true);
          }
        }
      });

      test('should update achievement progress correctly', () async {
        const partialProgress = 5;
        const targetValue = 10;
        
        // Find an achievement we can partially progress
        final achievement = customizationManager.achievements
            .firstWhere((a) => a.targetValue >= targetValue);
        
        // Update with partial progress
        switch (achievement.type) {
          case AchievementType.pulseUsage:
            await customizationManager.updateStatistics(pulseUsage: partialProgress);
            break;
          case AchievementType.powerUps:
            await customizationManager.updateStatistics(powerUpsCollected: partialProgress);
            break;
          case AchievementType.gamesPlayed:
            await customizationManager.updateStatistics(gamesPlayed: partialProgress);
            break;
          default:
            break;
        }
        
        final updatedAchievement = customizationManager.achievements
            .firstWhere((a) => a.id == achievement.id);
        
        expect(updatedAchievement.currentProgress, partialProgress);
        expect(updatedAchievement.isUnlocked, false);
        expect(updatedAchievement.progressPercentage, 
               partialProgress / updatedAchievement.targetValue);
      });
    });

    group('Persistence', () {
      test('should persist selected skin across sessions', () async {
        // Unlock and select a skin
        await customizationManager.checkAndUnlockSkins(100);
        final skinToSelect = customizationManager.unlockedSkins
            .firstWhere((skin) => skin.id != 'default');
        
        await customizationManager.selectSkin(skinToSelect.id);
        expect(customizationManager.selectedSkin.id, skinToSelect.id);
        
        // Create new manager instance (simulating app restart)
        final newManager = CustomizationManager();
        await newManager.initialize();
        
        // Should have the same selected skin
        expect(newManager.selectedSkin.id, skinToSelect.id);
      });

      test('should persist unlocked skins across sessions', () async {
        // Unlock skins
        const testScore = 150;
        await customizationManager.checkAndUnlockSkins(testScore);
        final unlockedCount = customizationManager.unlockedSkins.length;
        
        // Create new manager instance
        final newManager = CustomizationManager();
        await newManager.initialize();
        
        // Should have the same number of unlocked skins
        expect(newManager.unlockedSkins.length, unlockedCount);
      });

      test('should persist achievement progress across sessions', () async {
        // Make some progress
        await customizationManager.updateStatistics(
          score: 50,
          gamesPlayed: 5,
          pulseUsage: 10,
        );
        
        final originalStats = Map<String, int>.from(customizationManager.gameStatistics);
        
        // Create new manager instance
        final newManager = CustomizationManager();
        await newManager.initialize();
        
        // Should have the same statistics
        expect(newManager.gameStatistics, originalStats);
      });
    });

    group('Data Reset', () {
      test('should reset all data correctly', () async {
        // Make some progress first
        await customizationManager.checkAndUnlockSkins(100);
        await customizationManager.updateStatistics(score: 50, gamesPlayed: 3);
        
        // Reset all data
        await customizationManager.resetAllData();
        
        // Should be back to initial state
        expect(customizationManager.selectedSkin.id, 'default');
        expect(customizationManager.unlockedSkins.length, 1); // Only default
        expect(customizationManager.gameStatistics['totalScore'], 0);
        expect(customizationManager.achievements.every((a) => !a.isUnlocked), true);
      });
    });
  });

  group('BirdSkin Tests', () {
    test('should serialize and deserialize correctly', () {
      const originalSkin = BirdSkin(
        id: 'test_skin',
        name: 'Test Skin',
        primaryColor: Colors.red,
        trailColor: Colors.blue,
        description: 'A test skin',
        unlockScore: 100,
        isUnlocked: true,
      );
      
      final json = originalSkin.toJson();
      final deserializedSkin = BirdSkin.fromJson(json);
      
      expect(deserializedSkin.id, originalSkin.id);
      expect(deserializedSkin.name, originalSkin.name);
      expect(deserializedSkin.primaryColor.value, originalSkin.primaryColor.value);
      expect(deserializedSkin.trailColor.value, originalSkin.trailColor.value);
      expect(deserializedSkin.description, originalSkin.description);
      expect(deserializedSkin.unlockScore, originalSkin.unlockScore);
      expect(deserializedSkin.isUnlocked, originalSkin.isUnlocked);
    });

    test('should create copy with updated unlock status', () {
      const originalSkin = BirdSkin(
        id: 'test_skin',
        name: 'Test Skin',
        primaryColor: Colors.red,
        trailColor: Colors.blue,
        description: 'A test skin',
        unlockScore: 100,
        isUnlocked: false,
      );
      
      final unlockedSkin = originalSkin.copyWith(isUnlocked: true);
      
      expect(unlockedSkin.isUnlocked, true);
      expect(unlockedSkin.id, originalSkin.id); // Other properties unchanged
      expect(unlockedSkin.name, originalSkin.name);
    });
  });

  group('Achievement Tests', () {
    test('should calculate progress percentage correctly', () {
      const achievement = Achievement(
        id: 'test_achievement',
        name: 'Test Achievement',
        description: 'A test achievement',
        icon: Icons.star,
        iconColor: Color(0xFFFFD700), // Gold
        targetValue: 100,
        type: AchievementType.score,
        currentProgress: 25,
      );
      
      expect(achievement.progressPercentage, 0.25);
      expect(achievement.isCompleted, false);
    });

    test('should detect completion correctly', () {
      const achievement = Achievement(
        id: 'test_achievement',
        name: 'Test Achievement',
        description: 'A test achievement',
        icon: Icons.star,
        iconColor: Color(0xFFFFD700), // Gold
        targetValue: 100,
        type: AchievementType.score,
        currentProgress: 100,
      );
      
      expect(achievement.isCompleted, true);
      expect(achievement.progressPercentage, 1.0);
    });

    test('should serialize and deserialize correctly', () {
      const originalAchievement = Achievement(
        id: 'test_achievement',
        name: 'Test Achievement',
        description: 'A test achievement',
        icon: Icons.star,
        iconColor: Color(0xFFFFD700), // Gold
        targetValue: 100,
        type: AchievementType.score,
        rewardSkinId: 'reward_skin',
        isUnlocked: true,
        currentProgress: 50,
      );
      
      final json = originalAchievement.toJson();
      final deserializedAchievement = Achievement.fromJson(json);
      
      expect(deserializedAchievement.id, originalAchievement.id);
      expect(deserializedAchievement.name, originalAchievement.name);
      expect(deserializedAchievement.targetValue, originalAchievement.targetValue);
      expect(deserializedAchievement.type, originalAchievement.type);
      expect(deserializedAchievement.rewardSkinId, originalAchievement.rewardSkinId);
      expect(deserializedAchievement.isUnlocked, originalAchievement.isUnlocked);
      expect(deserializedAchievement.currentProgress, originalAchievement.currentProgress);
    });
  });
}