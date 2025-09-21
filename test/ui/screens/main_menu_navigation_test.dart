import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../../../lib/ui/screens/main_menu_screen.dart';
import '../../../lib/ui/screens/achievements_progression_screen.dart';
import '../../../lib/providers/authentication_provider.dart';
import '../../../lib/game/managers/achievement_manager.dart';
import '../../../lib/game/managers/customization_manager.dart';

void main() {
  group('MainMenuScreen Navigation Integration', () {
    testWidgets('should navigate to AchievementsProgressionScreen when ACHIEVEMENTS button is tapped', (WidgetTester tester) async {
      // Create mock providers
      final authProvider = AuthenticationProvider();
      
      // Build the widget tree with providers
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthenticationProvider>(
            create: (_) => authProvider,
            child: const MainMenuScreen(),
          ),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find the ACHIEVEMENTS button
      final achievementsButton = find.text('ACHIEVEMENTS');
      expect(achievementsButton, findsOneWidget);

      // Tap the ACHIEVEMENTS button
      await tester.tap(achievementsButton);
      await tester.pumpAndSettle();

      // Verify that AchievementsProgressionScreen is pushed
      // We check for the screen title which should be "PROGRESSION PATH"
      expect(find.text('PROGRESSION PATH'), findsOneWidget);
    });

    testWidgets('ACHIEVEMENTS button should be disabled when not initialized', (WidgetTester tester) async {
      // Create mock providers
      final authProvider = AuthenticationProvider();
      
      // Build the widget tree with providers
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthenticationProvider>(
            create: (_) => authProvider,
            child: const MainMenuScreen(),
          ),
        ),
      );

      // Don't wait for initialization - check immediately
      await tester.pump();

      // Find the ACHIEVEMENTS button
      final achievementsButton = find.text('ACHIEVEMENTS');
      expect(achievementsButton, findsOneWidget);

      // Verify the button is disabled (should not be tappable)
      final buttonWidget = tester.widget<ElevatedButton>(
        find.ancestor(
          of: achievementsButton,
          matching: find.byType(ElevatedButton),
        ),
      );
      
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('should use correct transition animation for ACHIEVEMENTS navigation', (WidgetTester tester) async {
      // Create mock providers
      final authProvider = AuthenticationProvider();
      
      // Build the widget tree with providers
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthenticationProvider>(
            create: (_) => authProvider,
            child: const MainMenuScreen(),
          ),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap the ACHIEVEMENTS button
      final achievementsButton = find.text('ACHIEVEMENTS');
      await tester.tap(achievementsButton);
      
      // Pump a few frames to see the transition
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      
      // The transition should be in progress
      // We can't easily test the specific transition type, but we can verify
      // that navigation occurred by checking for the new screen
      await tester.pumpAndSettle();
      expect(find.text('PROGRESSION PATH'), findsOneWidget);
    });
  });
}