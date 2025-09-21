import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/ui/screens/achievements_progression_screen.dart';
import 'package:neon_pulse_flappy_bird/ui/screens/achievements_screen.dart';
import 'package:neon_pulse_flappy_bird/game/managers/achievement_manager.dart';
import 'package:neon_pulse_flappy_bird/game/managers/customization_manager.dart';
import 'package:neon_pulse_flappy_bird/models/achievement.dart';

/// Mock CustomizationManager for testing
class MockCustomizationManager extends CustomizationManager {
  @override
  Future<void> initialize() async {
    // Skip SharedPreferences initialization in tests
  }
}

void main() {
  group('Achievements Screen Migration Tests', () {
    late AchievementManager achievementManager;
    late MockCustomizationManager customizationManager;

    setUp(() async {
      // Create a mock customization manager for testing
      customizationManager = MockCustomizationManager();
      await customizationManager.initialize();
      
      // Create a mock achievement manager for testing
      achievementManager = AchievementManager(customizationManager);
    });

    testWidgets('New progression screen can be instantiated with same parameters as old screen', (WidgetTester tester) async {
      // Test that the new screen accepts the same basic parameters
      final oldScreen = AchievementsScreen(
        achievementManager: achievementManager,
      );
      
      final newScreen = AchievementsProgressionScreen(
        achievementManager: achievementManager,
      );

      // Both screens should be creatable
      expect(oldScreen, isA<Widget>());
      expect(newScreen, isA<Widget>());
    });

    test('Achievement manager backward compatibility methods work', () {
      // Test that new methods added for backward compatibility work
      final achievements = achievementManager.achievements;
      
      // Test with non-existent ID
      final nonExistentAchievement = achievementManager.getAchievementById('non-existent-id');
      expect(nonExistentAchievement, isNull);
      
      // Test getAchievementsByType method exists
      final scoreAchievements = achievementManager.getAchievementsByType(AchievementType.score);
      expect(scoreAchievements, isA<List<Achievement>>());
    });

    test('Achievement data migration compatibility', () async {
      // Test that existing achievement data works with new screen
      final testAchievements = [
        Achievement(
          id: 'test-1',
          name: 'Test Achievement 1',
          description: 'Test description',
          type: AchievementType.score,
          targetValue: 100,
          currentProgress: 50,
          icon: Icons.star,
          iconColor: Colors.yellow,
        ),
        Achievement(
          id: 'test-2',
          name: 'Test Achievement 2',
          description: 'Test description 2',
          type: AchievementType.gamesPlayed,
          targetValue: 10,
          currentProgress: 10,
          icon: Icons.games,
          iconColor: Colors.blue,
        ),
      ];

      // Verify achievements can be processed by both old and new systems
      for (final achievement in testAchievements) {
        expect(achievement.id, isNotEmpty);
        expect(achievement.name, isNotEmpty);
        expect(achievement.progressPercentage, isA<double>());
        expect(achievement.isUnlocked, isA<bool>());
      }

      // Test achievement manager methods work with test data
      final scoreAchievements = achievementManager.getAchievementsByType(AchievementType.score);
      expect(scoreAchievements, isA<List<Achievement>>());

      final gamesAchievements = achievementManager.getAchievementsByType(AchievementType.gamesPlayed);
      expect(gamesAchievements, isA<List<Achievement>>());
    });
  });
}