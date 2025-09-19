import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/ui/components/score_submission_dialog.dart';
import 'package:neon_pulse_flappy_bird/services/leaderboard_integration_service.dart';

void main() {
  group('ScoreSubmissionDialog', () {
    testWidgets('should display success dialog correctly', (WidgetTester tester) async {
      bool onCloseCalled = false;
      bool onViewLeaderboardCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreSubmissionDialog(
              score: 500,
              result: ScoreSubmissionResult.success,
              leaderboardPosition: 25,
              isPersonalBest: true,
              onClose: () => onCloseCalled = true,
              onViewLeaderboard: () => onViewLeaderboardCalled = true,
            ),
          ),
        ),
      );

      // Verify success elements are displayed
      expect(find.text('Score Submitted!'), findsOneWidget);
      expect(find.text('Your score has been successfully submitted to the global leaderboard.'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
      expect(find.text('Global Rank: #25'), findsOneWidget);
      expect(find.text('Personal Best!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.leaderboard), findsOneWidget);

      // Verify buttons are present
      expect(find.text('CLOSE'), findsOneWidget);
      expect(find.text('LEADERBOARD'), findsOneWidget);

      // Test button interactions
      await tester.tap(find.text('LEADERBOARD'));
      await tester.pump();
      expect(onViewLeaderboardCalled, isTrue);

      await tester.tap(find.text('CLOSE'));
      await tester.pump();
      expect(onCloseCalled, isTrue);
    });

    testWidgets('should display queued dialog correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreSubmissionDialog(
              score: 300,
              result: ScoreSubmissionResult.queued,
              isPersonalBest: false,
            ),
          ),
        ),
      );

      // Verify queued elements are displayed
      expect(find.text('Score Queued'), findsOneWidget);
      expect(find.text('Your score has been saved and will be submitted when you\'re back online.'), findsOneWidget);
      expect(find.text('300'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);

      // Personal best badge should not be displayed
      expect(find.text('Personal Best!'), findsNothing);
      
      // Leaderboard position should not be displayed
      expect(find.textContaining('Global Rank:'), findsNothing);

      // Only close button should be present (no leaderboard button for queued)
      expect(find.text('CLOSE'), findsOneWidget);
      expect(find.text('LEADERBOARD'), findsNothing);
    });

    testWidgets('should display failed dialog with retry option', (WidgetTester tester) async {
      bool onRetryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreSubmissionDialog(
              score: 150,
              result: ScoreSubmissionResult.failed,
              onRetry: () => onRetryCalled = true,
            ),
          ),
        ),
      );

      // Verify failed elements are displayed
      expect(find.text('Submission Failed'), findsOneWidget);
      expect(find.text('Failed to submit your score. Please try again later.'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);

      // Verify retry button is present
      expect(find.text('RETRY'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);

      // Test retry button
      await tester.tap(find.text('RETRY'));
      await tester.pump();
      expect(onRetryCalled, isTrue);
    });

    testWidgets('should display network error dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreSubmissionDialog(
              score: 75,
              result: ScoreSubmissionResult.networkError,
            ),
          ),
        ),
      );

      // Verify network error elements are displayed
      expect(find.text('Network Error'), findsOneWidget);
      expect(find.text('Unable to connect to the server. Check your internet connection.'), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('should display invalid score dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreSubmissionDialog(
              score: 999,
              result: ScoreSubmissionResult.invalidScore,
            ),
          ),
        ),
      );

      // Verify invalid score elements are displayed
      expect(find.text('Invalid Score'), findsOneWidget);
      expect(find.text('This score could not be validated. Please play again.'), findsOneWidget);
      expect(find.text('999'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('should display not authenticated dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreSubmissionDialog(
              score: 200,
              result: ScoreSubmissionResult.notAuthenticated,
            ),
          ),
        ),
      );

      // Verify not authenticated elements are displayed
      expect(find.text('Sign In Required'), findsOneWidget);
      expect(find.text('Please sign in with Google to submit scores to the leaderboard.'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
      expect(find.byIcon(Icons.account_circle), findsOneWidget);
    });

    testWidgets('should handle missing leaderboard position gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreSubmissionDialog(
              score: 400,
              result: ScoreSubmissionResult.success,
              leaderboardPosition: null, // No position provided
              isPersonalBest: false,
            ),
          ),
        ),
      );

      // Verify success dialog displays without leaderboard position
      expect(find.text('Score Submitted!'), findsOneWidget);
      expect(find.text('400'), findsOneWidget);
      expect(find.textContaining('Global Rank:'), findsNothing);
      expect(find.text('Personal Best!'), findsNothing);
    });

    testWidgets('should animate dialog appearance', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreSubmissionDialog(
              score: 100,
              result: ScoreSubmissionResult.success,
            ),
          ),
        ),
      );

      // Dialog should be present
      expect(find.byType(ScoreSubmissionDialog), findsOneWidget);

      // Pump a few frames to test animation
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));

      // Dialog should still be visible after animation frames
      expect(find.byType(ScoreSubmissionDialog), findsOneWidget);
      expect(find.text('Score Submitted!'), findsOneWidget);
    });

    testWidgets('should handle default close behavior', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreSubmissionDialog(
              score: 100,
              result: ScoreSubmissionResult.success,
              // No onClose callback provided
            ),
          ),
        ),
      );

      // Close button should still be present and functional
      expect(find.text('CLOSE'), findsOneWidget);
      
      // Tapping close should not throw an error
      await tester.tap(find.text('CLOSE'));
      await tester.pump();
      
      // Dialog should be dismissed (Navigator.pop called)
      expect(find.byType(ScoreSubmissionDialog), findsNothing);
    });

    testWidgets('should show correct buttons based on result type', (WidgetTester tester) async {
      // Test success result - should show leaderboard button
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreSubmissionDialog(
              score: 100,
              result: ScoreSubmissionResult.success,
              onViewLeaderboard: () {},
            ),
          ),
        ),
      );

      expect(find.text('LEADERBOARD'), findsOneWidget);
      expect(find.text('RETRY'), findsNothing);

      // Test failed result - should show retry button
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreSubmissionDialog(
              score: 100,
              result: ScoreSubmissionResult.failed,
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('RETRY'), findsOneWidget);
      expect(find.text('LEADERBOARD'), findsNothing);

      // Test queued result - should show neither
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreSubmissionDialog(
              score: 100,
              result: ScoreSubmissionResult.queued,
            ),
          ),
        ),
      );

      expect(find.text('RETRY'), findsNothing);
      expect(find.text('LEADERBOARD'), findsNothing);
      expect(find.text('CLOSE'), findsOneWidget); // Always shows close
    });

    group('StatusConfig', () {
      testWidgets('should use correct colors for different statuses', (WidgetTester tester) async {
        // Test success status - should use green
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ScoreSubmissionDialog(
                score: 100,
                result: ScoreSubmissionResult.success,
              ),
            ),
          ),
        );

        // Find the icon and verify it's green (success color)
        final iconWidget = tester.widget<Icon>(find.byIcon(Icons.check_circle));
        expect(iconWidget.color, equals(Colors.green));

        // Test failed status - should use red
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ScoreSubmissionDialog(
                score: 100,
                result: ScoreSubmissionResult.failed,
              ),
            ),
          ),
        );

        final failedIconWidget = tester.widget<Icon>(find.byIcon(Icons.error));
        expect(failedIconWidget.color, equals(Colors.red));
      });
    });
  });
}