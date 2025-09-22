import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/game/managers/game_state_manager.dart';
import 'package:neon_pulse_flappy_bird/services/leaderboard_integration_service.dart';
import 'package:neon_pulse_flappy_bird/models/user.dart' as app_user;

void main() {
  group('GameStateManager Integration Tests', () {
    late GameStateManager gameStateManager;

    setUp(() {
      gameStateManager = GameStateManager();
    });

    tearDown(() {
      gameStateManager.dispose();
    });

    test('complete score submission flow with conditional loading', () async {
      // Test user with valid uid
      final user = app_user.User(
        uid: 'test_user_123',
        displayName: 'Test Player',
        email: 'test@example.com',
        isGuest: false,
        gameStats: const app_user.UserGameStats(bestScore: 50),
      );

      // Test scenarios
      final testCases = [
        {
          'score': 0,
          'currentBest': 50,
          'shouldShow': false,
          'description': 'Zero score should not show loading'
        },
        {
          'score': 30,
          'currentBest': 50,
          'shouldShow': true,
          'description': 'Score lower than best should show loading (service handles logic)'
        },
        {
          'score': 50,
          'currentBest': 50,
          'shouldShow': true,
          'description': 'Score equal to best should show loading (service handles logic)'
        },
        {
          'score': 75,
          'currentBest': 50,
          'shouldShow': true,
          'description': 'Score higher than best should show loading'
        },
      ];

      for (final testCase in testCases) {
        final score = testCase['score'] as int;
        final currentBest = testCase['currentBest'] as int;
        final shouldShow = testCase['shouldShow'] as bool;
        final description = testCase['description'] as String;

        final result = gameStateManager.shouldShowScoreSubmission(
          score: score,
          currentBestScore: currentBest,
          user: user,
        );

        expect(result, shouldShow, reason: description);
      }
    });

    test('restart button state management during submission', () async {
      // Initial state
      expect(gameStateManager.isRestartEnabled, true);
      expect(gameStateManager.isScoreSubmissionInProgress, false);

      // Test manual state control
      gameStateManager.disableRestart();
      expect(gameStateManager.isRestartEnabled, false);

      gameStateManager.enableRestart();
      expect(gameStateManager.isRestartEnabled, true);
    });

    test('fast-fail validation prevents unnecessary network calls', () async {
      final user = app_user.User(
        uid: 'test_user_123',
        displayName: 'Test Player',
        email: 'test@example.com',
        isGuest: false,
        gameStats: const app_user.UserGameStats(),
      );

      // Test invalid scores that should fail immediately
      final invalidCases = [
        {
          'score': -10,
          'description': 'Negative score'
        },
        {
          'score': 15000,
          'description': 'Impossibly high score'
        },
      ];

      for (final testCase in invalidCases) {
        final score = testCase['score'] as int;
        final description = testCase['description'] as String;

        final gameSession = GameSession(
          startTime: DateTime.now().subtract(const Duration(minutes: 1)),
          endTime: DateTime.now(),
          finalScore: score,
          jumpCount: 10,
          pulseUsage: 2,
          powerUpsCollected: 1,
          survivalTime: 30.0,
          sessionId: 'test_session',
        );

        final result = await gameStateManager.submitScore(
          score: score,
          gameSession: gameSession,
          user: user,
        );

        expect(result, ScoreSubmissionResult.invalidScore, reason: description);
      }
    });

    test('timeout mechanism works within 1 second', () async {
      final user = app_user.User(
        uid: 'test_user_123',
        displayName: 'Test Player',
        email: 'test@example.com',
        isGuest: false,
        gameStats: const app_user.UserGameStats(),
      );

      final gameSession = GameSession(
        startTime: DateTime.now().subtract(const Duration(minutes: 1)),
        endTime: DateTime.now(),
        finalScore: 100,
        jumpCount: 50,
        pulseUsage: 10,
        powerUpsCollected: 5,
        survivalTime: 60.0,
        sessionId: 'test_session',
      );

      final stopwatch = Stopwatch()..start();

      final result = await gameStateManager.submitScore(
        score: 100,
        gameSession: gameSession,
        user: user,
      );

      stopwatch.stop();

      // Should complete within 1.5 seconds (1 second timeout + margin)
      expect(stopwatch.elapsedMilliseconds, lessThan(1500));
      
      // Result should be one of the expected timeout/error results
      expect(result, anyOf([
        ScoreSubmissionResult.networkError,
        ScoreSubmissionResult.queued,
        ScoreSubmissionResult.failed,
      ]));
    });

    test('state management during submission lifecycle', () async {
      final user = app_user.User(
        uid: 'test_user_123',
        displayName: 'Test Player',
        email: 'test@example.com',
        isGuest: false,
        gameStats: const app_user.UserGameStats(),
      );

      final gameSession = GameSession(
        startTime: DateTime.now().subtract(const Duration(minutes: 1)),
        endTime: DateTime.now(),
        finalScore: 100,
        jumpCount: 50,
        pulseUsage: 10,
        powerUpsCollected: 5,
        survivalTime: 60.0,
        sessionId: 'test_session',
      );

      // Start submission (this will run in background)
      final submissionFuture = gameStateManager.submitScore(
        score: 100,
        gameSession: gameSession,
        user: user,
      );

      // Check that submission is in progress and restart is disabled
      expect(gameStateManager.isScoreSubmissionInProgress, true);
      expect(gameStateManager.isRestartEnabled, false);

      // Wait for completion
      await submissionFuture;

      // Check that submission is complete and restart is enabled
      expect(gameStateManager.isScoreSubmissionInProgress, false);
      expect(gameStateManager.isRestartEnabled, true);
    });
  });
}