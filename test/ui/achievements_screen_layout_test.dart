import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/ui/screens/achievements_progression_screen.dart';
import 'package:neon_pulse_flappy_bird/game/managers/achievement_manager.dart';
import 'package:neon_pulse_flappy_bird/game/managers/customization_manager.dart';

/// Mock CustomizationManager for testing
class MockCustomizationManager extends CustomizationManager {
  @override
  Future<void> initialize() async {
    // Skip SharedPreferences initialization in tests
  }
}

void main() {
  group('Achievements Screen Layout Tests', () {
    late AchievementManager achievementManager;
    late MockCustomizationManager customizationManager;

    setUp(() async {
      customizationManager = MockCustomizationManager();
      await customizationManager.initialize();
      achievementManager = AchievementManager(customizationManager);
    });

    testWidgets('Achievements progression screen renders without layout errors', (WidgetTester tester) async {
      // Build the achievements progression screen
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementsProgressionScreen(
            achievementManager: achievementManager,
          ),
        ),
      );

      // Allow the screen to initialize
      await tester.pump();
      
      // Verify the screen renders without throwing layout exceptions
      expect(find.byType(AchievementsProgressionScreen), findsOneWidget);
      
      // Verify the scaffold is present
      expect(find.byType(Scaffold), findsOneWidget);
      
      // The screen should not throw any RenderBox layout errors
      // If there were layout issues, the test would fail with exceptions
    });

    testWidgets('Screen handles different screen sizes without layout errors', (WidgetTester tester) async {
      // Test with a small screen size
      await tester.binding.setSurfaceSize(const Size(400, 600));
      
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementsProgressionScreen(
            achievementManager: achievementManager,
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AchievementsProgressionScreen), findsOneWidget);

      // Test with a large screen size
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementsProgressionScreen(
            achievementManager: achievementManager,
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AchievementsProgressionScreen), findsOneWidget);
      
      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });
  });
}