import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/models/achievement.dart';
import '../../../lib/game/managers/achievement_manager.dart';
import '../../../lib/game/managers/customization_manager.dart';
import '../../../lib/game/managers/notification_manager.dart';

void main() {
  group('Achievement Tracking Logic', () {
    late AchievementManager achievementManager;
    late CustomizationManager customizationManager;
    late NotificationManager notificationManager;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      // Create managers
      customizationManager = CustomizationManager();
      notificationManager = NotificationManager();
      achievementManager = AchievementManager(customizationManager, notificationManager);
      
      // Initialize managers
      await customizationManager.initialize();
      await achievementManager.initialize();
    });

    test('should handle different achievement tracking types correctly', () async {
      // Get achievements with different tracking types
      final achievements = customizationManager.achievements;
      
      // Find achievements by tracking type
      final cumulativeAchievement = achievements.firstWhere(
        (a) => a.trackingType == AchievementTrackingType.cumulative,
      );
      final singleRunAchievement = achievements.firstWhere(
        (a) => a.trackingType == AchievementTrackingType.singleRun,
      );
      
      expect(cumulativeAchievement.trackingType, AchievementTrackingType.cumulative);
      expect(singleRunAchievement.trackingType, AchievementTrackingType.singleRun);
      expect(singleRunAchievement.resetsOnFailure, true);
    });

    test('should reset single-run achievements on failure', () async {
      // Manually set progress for a single-run achievement (simulating in-game progress)
      customizationManager.updateAchievementProgress('century_club', 50);
      
      // Get the single-run achievement (should have progress now)
      var achievements = customizationManager.achievements;
      var singleRunAchievement = achievements.firstWhere(
        (a) => a.id == 'century_club',
      );
      
      expect(singleRunAchievement.currentProgress, 50);
      expect(singleRunAchievement.trackingType, AchievementTrackingType.singleRun);
      expect(singleRunAchievement.resetsOnFailure, true);
      
      // Reset single-run progress (simulating game failure)
      await achievementManager.resetSingleRunProgress();
      
      // Check that single-run achievement progress was reset
      achievements = customizationManager.achievements;
      singleRunAchievement = achievements.firstWhere(
        (a) => a.id == 'century_club',
      );
      
      expect(singleRunAchievement.currentProgress, 0);
    });

    test('should not reset cumulative achievements on failure', () async {
      // Update statistics to give progress to cumulative achievements
      await customizationManager.updateStatistics(pulseUsage: 25);
      
      // Get the cumulative achievement (should have progress now)
      var achievements = customizationManager.achievements;
      var cumulativeAchievement = achievements.firstWhere(
        (a) => a.trackingType == AchievementTrackingType.cumulative && a.type == AchievementType.pulseUsage,
      );
      
      expect(cumulativeAchievement.currentProgress, 25);
      
      // Reset single-run progress (should not affect cumulative)
      await achievementManager.resetSingleRunProgress();
      
      // Check that cumulative achievement progress was NOT reset
      achievements = customizationManager.achievements;
      cumulativeAchievement = achievements.firstWhere(
        (a) => a.trackingType == AchievementTrackingType.cumulative && a.type == AchievementType.pulseUsage,
      );
      
      expect(cumulativeAchievement.currentProgress, 25);
    });

    test('should handle achievement progress calculation based on tracking type', () async {
      // Test cumulative achievement progress
      await customizationManager.updateStatistics(gamesPlayed: 10);
      
      var achievements = customizationManager.achievements;
      var gamesPlayedAchievement = achievements.firstWhere(
        (a) => a.type == AchievementType.gamesPlayed,
      );
      
      expect(gamesPlayedAchievement.currentProgress, 10);
      expect(gamesPlayedAchievement.trackingType, AchievementTrackingType.cumulative);
      
      // Add more games
      await customizationManager.updateStatistics(gamesPlayed: 5);
      
      achievements = customizationManager.achievements;
      gamesPlayedAchievement = achievements.firstWhere(
        (a) => a.type == AchievementType.gamesPlayed,
      );
      
      expect(gamesPlayedAchievement.currentProgress, 15);
    });

    test('should preserve unlocked achievements during reset', () async {
      // Unlock a single-run achievement
      await customizationManager.updateStatistics(score: 100);
      
      var achievements = customizationManager.achievements;
      var centuryClubAchievement = achievements.firstWhere(
        (a) => a.id == 'century_club',
      );
      
      expect(centuryClubAchievement.isUnlocked, true);
      
      // Reset single-run progress
      await achievementManager.resetSingleRunProgress();
      
      // Check that unlocked achievement remains unlocked
      achievements = customizationManager.achievements;
      centuryClubAchievement = achievements.firstWhere(
        (a) => a.id == 'century_club',
      );
      
      expect(centuryClubAchievement.isUnlocked, true);
    });
  });
}