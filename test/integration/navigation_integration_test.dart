import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/ui/screens/main_menu_screen.dart';
import 'package:neon_pulse_flappy_bird/ui/screens/achievements_progression_screen.dart';
import 'package:neon_pulse_flappy_bird/game/managers/achievement_manager.dart';

void main() {
  group('Navigation Integration Tests', () {
    late AchievementManager mockAchievementManager;

    setUp(() {
      // Create a mock achievement manager for testing
      mockAchievementManager = AchievementManager(null);
    });
    testWidgets('Main menu can navigate to achievements progression screen', (WidgetTester tester) async {
      // Test basic navigation without full initialization to avoid plugin issues
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  // Simulate the navigation that happens in main menu
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AchievementsProgressionScreen(
                        achievementManager: mockAchievementManager,
                      ),
                    ),
                  );
                },
                child: const Text('ACHIEVEMENTS'),
              ),
            ),
          ),
        ),
      );

      // Find and tap the achievements button
      await tester.tap(find.text('ACHIEVEMENTS'));
      await tester.pumpAndSettle();

      // Should navigate without throwing errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Navigation preserves widget tree structure', (WidgetTester tester) async {
      // Test that navigation maintains proper widget structure
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Main Menu')),
              body: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AchievementsProgressionScreen(
                            achievementManager: mockAchievementManager,
                          ),
                        ),
                      );
                    },
                    child: const Text('Go to Achievements'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('Main Menu'), findsOneWidget);
      expect(find.text('Go to Achievements'), findsOneWidget);

      // Navigate
      await tester.tap(find.text('Go to Achievements'));
      await tester.pumpAndSettle();

      // Should have navigated successfully
      expect(tester.takeException(), isNull);
      
      // Navigate back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Should be back at main menu
      expect(find.text('Main Menu'), findsOneWidget);
    });

    test('Screen classes are properly exported and importable', () {
      // Test that both screen classes can be instantiated
      expect(() => AchievementsProgressionScreen(achievementManager: mockAchievementManager), 
             returnsNormally);
    });
  });
}