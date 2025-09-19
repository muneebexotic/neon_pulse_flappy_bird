import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/ui/components/celebration_overlay.dart';
import 'package:neon_pulse_flappy_bird/services/leaderboard_integration_service.dart';

void main() {
  group('CelebrationOverlay', () {
    testWidgets('should display legendary celebration correctly', (WidgetTester tester) async {
      bool onCompleteTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CelebrationOverlay(
              level: CelebrationLevel.legendary,
              score: 1000,
              leaderboardPosition: 5,
              isPersonalBest: true,
              duration: const Duration(milliseconds: 100), // Short duration for testing
              onComplete: () {
                onCompleteTriggered = true;
              },
            ),
          ),
        ),
      );

      // Verify legendary celebration text is displayed
      expect(find.text('LEGENDARY!\nTOP 10 GLOBAL!'), findsOneWidget);
      
      // Verify score is displayed
      expect(find.text('1000'), findsOneWidget);
      
      // Verify leaderboard position is displayed
      expect(find.text('Global Rank: #5'), findsOneWidget);
      
      // Verify personal best badge is displayed
      expect(find.text('Personal Best!'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);

      // Wait for animation and completion
      await tester.pump(const Duration(milliseconds: 200));
      
      expect(onCompleteTriggered, isTrue);
    });

    testWidgets('should display epic celebration correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CelebrationOverlay(
              level: CelebrationLevel.epic,
              score: 500,
              leaderboardPosition: 50,
              isPersonalBest: false,
              duration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Verify epic celebration text is displayed
      expect(find.text('EPIC SCORE!\nTOP 100 GLOBAL!'), findsOneWidget);
      
      // Verify score is displayed
      expect(find.text('500'), findsOneWidget);
      
      // Verify leaderboard position is displayed
      expect(find.text('Global Rank: #50'), findsOneWidget);
      
      // Personal best badge should not be displayed
      expect(find.text('Personal Best!'), findsNothing);
    });

    testWidgets('should display great celebration for personal best', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CelebrationOverlay(
              level: CelebrationLevel.great,
              score: 200,
              isPersonalBest: true,
              duration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Verify great celebration text is displayed
      expect(find.text('GREAT JOB!\nNEW PERSONAL BEST!'), findsOneWidget);
      
      // Verify score is displayed
      expect(find.text('200'), findsOneWidget);
      
      // Verify personal best badge is displayed
      expect(find.text('Personal Best!'), findsOneWidget);
      
      // Leaderboard position should not be displayed (not provided)
      expect(find.textContaining('Global Rank:'), findsNothing);
    });

    testWidgets('should display good celebration correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CelebrationOverlay(
              level: CelebrationLevel.good,
              score: 50,
              isPersonalBest: false,
              duration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Verify good celebration text is displayed
      expect(find.text('NICE SCORE!'), findsOneWidget);
      
      // Verify score is displayed
      expect(find.text('50'), findsOneWidget);
      
      // Personal best badge should not be displayed
      expect(find.text('Personal Best!'), findsNothing);
      
      // Leaderboard position should not be displayed
      expect(find.textContaining('Global Rank:'), findsNothing);
    });

    testWidgets('should handle missing leaderboard position gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CelebrationOverlay(
              level: CelebrationLevel.legendary,
              score: 1000,
              leaderboardPosition: null, // No position provided
              isPersonalBest: true,
              duration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Verify celebration displays without leaderboard position
      expect(find.text('LEGENDARY!\nTOP 10 GLOBAL!'), findsOneWidget);
      expect(find.text('1000'), findsOneWidget);
      expect(find.textContaining('Global Rank:'), findsNothing);
      expect(find.text('Personal Best!'), findsOneWidget);
    });

    testWidgets('should animate properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CelebrationOverlay(
              level: CelebrationLevel.great,
              score: 100,
              duration: const Duration(seconds: 1),
            ),
          ),
        ),
      );

      // Initial state - should be visible
      expect(find.byType(CelebrationOverlay), findsOneWidget);

      // Pump a few frames to test animation
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));

      // Should still be visible during animation
      expect(find.byType(CelebrationOverlay), findsOneWidget);
    });

    group('CelebrationConfig', () {
      testWidgets('should use correct colors for legendary level', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CelebrationOverlay(
                level: CelebrationLevel.legendary,
                score: 1000,
                duration: const Duration(milliseconds: 100),
              ),
            ),
          ),
        );

        // Find the main text widget and verify it uses gold color
        final textWidget = tester.widget<Text>(find.text('LEGENDARY!\nTOP 10 GLOBAL!'));
        expect(textWidget.style?.color, equals(const Color(0xFFFFD700))); // Gold
      });

      testWidgets('should use correct colors for epic level', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CelebrationOverlay(
                level: CelebrationLevel.epic,
                score: 500,
                duration: const Duration(milliseconds: 100),
              ),
            ),
          ),
        );

        // Find the main text widget and verify it uses purple color
        final textWidget = tester.widget<Text>(find.text('EPIC SCORE!\nTOP 100 GLOBAL!'));
        expect(textWidget.style?.color, equals(const Color(0xFF9D4EDD))); // Purple
      });

      testWidgets('should use correct colors for great level', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CelebrationOverlay(
                level: CelebrationLevel.great,
                score: 200,
                duration: const Duration(milliseconds: 100),
              ),
            ),
          ),
        );

        // Find the main text widget and verify it uses green color
        final textWidget = tester.widget<Text>(find.text('GREAT JOB!\nNEW PERSONAL BEST!'));
        expect(textWidget.style?.color, equals(const Color(0xFF06FFA5))); // Green
      });

      testWidgets('should use correct colors for good level', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CelebrationOverlay(
                level: CelebrationLevel.good,
                score: 50,
                duration: const Duration(milliseconds: 100),
              ),
            ),
          ),
        );

        // Find the main text widget and verify it uses cyan color
        final textWidget = tester.widget<Text>(find.text('NICE SCORE!'));
        expect(textWidget.style?.color, equals(const Color(0xFF00FFFF))); // Cyan
      });
    });

    testWidgets('should handle onComplete callback correctly', (WidgetTester tester) async {
      bool callbackTriggered = false;
      int callbackCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CelebrationOverlay(
              level: CelebrationLevel.good,
              score: 50,
              duration: const Duration(milliseconds: 50), // Very short for testing
              onComplete: () {
                callbackTriggered = true;
                callbackCount++;
              },
            ),
          ),
        ),
      );

      // Initially callback should not be triggered
      expect(callbackTriggered, isFalse);
      expect(callbackCount, equals(0));

      // Wait for duration to complete
      await tester.pump(const Duration(milliseconds: 100));

      // Callback should be triggered exactly once
      expect(callbackTriggered, isTrue);
      expect(callbackCount, equals(1));
    });

    testWidgets('should handle null onComplete callback gracefully', (WidgetTester tester) async {
      // Should not throw when onComplete is null
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CelebrationOverlay(
              level: CelebrationLevel.good,
              score: 50,
              duration: const Duration(milliseconds: 100),
              onComplete: null, // Null callback
            ),
          ),
        ),
      );

      // Should complete without error
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CelebrationOverlay), findsOneWidget);
    });
  });
}