import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/game/managers/game_state_manager.dart';
import 'package:neon_pulse_flappy_bird/services/leaderboard_integration_service.dart';
import 'package:neon_pulse_flappy_bird/models/user.dart' as app_user;

app_user.User createTestUser({String? uid, String? displayName}) {
  return app_user.User(
    uid: uid,
    displayName: displayName ?? 'Test User',
    email: 'test@example.com',
    isGuest: false,
    gameStats: const app_user.UserGameStats(),
  );
}

void main() {
  group('GameStateManager', () {
    late GameStateManager gameStateManager;

    setUp(() {
      gameStateManager = GameStateManager();
    });

    tearDown(() {
      gameStateManager.dispose();
    });

    group('shouldShowScoreSubmission', () {
      test('returns false for zero score', () {
        final user = createTestUser(uid: 'test_user');
        
        final result = gameStateManager.shouldShowScoreSubmission(
          score: 0,
          currentBestScore: 10,
          user: user,
        );
        
        expect(result, false);
      });

      test('returns false for negative score', () {
        final user = createTestUser(uid: 'test_user');
        
        final result = gameStateManager.shouldShowScoreSubmission(
          score: -5,
          currentBestScore: 10,
          user: user,
        );
        
        expect(result, false);
      });

      test('returns false for unauthenticated user', () {
        final result = gameStateManager.shouldShowScoreSubmission(
          score: 15,
          currentBestScore: 10,
          user: null,
        );
        
        expect(result, false);
      });

      test('returns false for user without uid', () {
        final user = createTestUser(); // No uid provided
        
        final result = gameStateManager.shouldShowScoreSubmission(
          score: 15,
          currentBestScore: 10,
          user: user,
        );
        
        expect(result, false);
      });

      test('returns true when score is not better than current best (let service handle logic)', () {
        final user = createTestUser(uid: 'test_user');
        
        final result = gameStateManager.shouldShowScoreSubmission(
          score: 10,
          currentBestScore: 15,
          user: user,
        );
        
        expect(result, true);
      });

      test('returns true when score equals current best (let service handle logic)', () {
        final user = createTestUser(uid: 'test_user');
        
        final result = gameStateManager.shouldShowScoreSubmission(
          score: 15,
          currentBestScore: 15,
          user: user,
        );
        
        expect(result, true);
      });

      test('returns true when score is better than current best', () {
        final user = createTestUser(uid: 'test_user');
        
        final result = gameStateManager.shouldShowScoreSubmission(
          score: 20,
          currentBestScore: 15,
          user: user,
        );
        
        expect(result, true);
      });
    });

    group('state management', () {
      test('initial state has restart enabled and no submission in progress', () {
        expect(gameStateManager.isRestartEnabled, true);
        expect(gameStateManager.isScoreSubmissionInProgress, false);
      });

      test('disableRestart sets restart to false', () {
        gameStateManager.disableRestart();
        expect(gameStateManager.isRestartEnabled, false);
      });

      test('enableRestart sets restart to true', () {
        gameStateManager.disableRestart();
        gameStateManager.enableRestart();
        expect(gameStateManager.isRestartEnabled, true);
      });
    });

    group('fast-fail validation', () {
      test('rejects negative scores', () async {
        final user = createTestUser(uid: 'test_user');
        final gameSession = GameSession(
          startTime: DateTime.now().subtract(const Duration(minutes: 1)),
          endTime: DateTime.now(),
          finalScore: -5,
          jumpCount: 10,
          pulseUsage: 2,
          powerUpsCollected: 1,
          survivalTime: 30.0,
          sessionId: 'test_session',
        );

        final result = await gameStateManager.submitScore(
          score: -5,
          gameSession: gameSession,
          user: user,
        );

        expect(result, ScoreSubmissionResult.invalidScore);
      });

      test('rejects impossibly high scores', () async {
        final user = createTestUser(uid: 'test_user');
        final gameSession = GameSession(
          startTime: DateTime.now().subtract(const Duration(minutes: 1)),
          endTime: DateTime.now(),
          finalScore: 15000,
          jumpCount: 10,
          pulseUsage: 2,
          powerUpsCollected: 1,
          survivalTime: 30.0,
          sessionId: 'test_session',
        );

        final result = await gameStateManager.submitScore(
          score: 15000,
          gameSession: gameSession,
          user: user,
        );

        expect(result, ScoreSubmissionResult.invalidScore);
      });

      test('rejects sessions with impossible score-to-time ratios', () async {
        final user = createTestUser(uid: 'test_user');
        final now = DateTime.now();
        final gameSession = GameSession(
          startTime: now.subtract(const Duration(seconds: 1)),
          endTime: now,
          finalScore: 100, // 100 points in 1 second = 100 points/second (too fast)
          jumpCount: 10,
          pulseUsage: 2,
          powerUpsCollected: 1,
          survivalTime: 1.0,
          sessionId: 'test_session',
        );

        final result = await gameStateManager.submitScore(
          score: 100,
          gameSession: gameSession,
          user: user,
        );

        expect(result, ScoreSubmissionResult.invalidScore);
      });

      test('rejects sessions with excessive jump counts', () async {
        final user = createTestUser(uid: 'test_user');
        final gameSession = GameSession(
          startTime: DateTime.now().subtract(const Duration(minutes: 1)),
          endTime: DateTime.now(),
          finalScore: 10,
          jumpCount: 300, // 300 jumps for 10 points (30 jumps per point, exceeds 20 limit)
          pulseUsage: 2,
          powerUpsCollected: 1,
          survivalTime: 30.0,
          sessionId: 'test_session',
        );

        final result = await gameStateManager.submitScore(
          score: 10,
          gameSession: gameSession,
          user: user,
        );

        expect(result, ScoreSubmissionResult.invalidScore);
      });

      test('accepts valid game sessions', () async {
        final user = createTestUser(uid: 'test_user');
        final gameSession = GameSession(
          startTime: DateTime.now().subtract(const Duration(minutes: 1)),
          endTime: DateTime.now(),
          finalScore: 10,
          jumpCount: 20, // 2 jumps per point (reasonable)
          pulseUsage: 2,
          powerUpsCollected: 1,
          survivalTime: 30.0,
          sessionId: 'test_session',
        );

        // This will timeout after 1 second, but that's expected behavior
        final result = await gameStateManager.submitScore(
          score: 10,
          gameSession: gameSession,
          user: user,
        );

        // Should not be invalidScore (will be networkError due to timeout in test environment)
        expect(result, isNot(ScoreSubmissionResult.invalidScore));
      });
    });

    group('timeout handling', () {
      test('completes within 1 second', () async {
        final user = createTestUser(uid: 'test_user');
        final gameSession = GameSession(
          startTime: DateTime.now().subtract(const Duration(minutes: 1)),
          endTime: DateTime.now(),
          finalScore: 10,
          jumpCount: 20,
          pulseUsage: 2,
          powerUpsCollected: 1,
          survivalTime: 30.0,
          sessionId: 'test_session',
        );

        final stopwatch = Stopwatch()..start();
        
        final result = await gameStateManager.submitScore(
          score: 10,
          gameSession: gameSession,
          user: user,
        );
        
        stopwatch.stop();

        // Should complete within approximately 1 second (allowing some margin)
        expect(stopwatch.elapsedMilliseconds, lessThan(1500));
        // In test environment, score gets queued due to no network connection
        expect(result, anyOf([
          ScoreSubmissionResult.networkError,
          ScoreSubmissionResult.queued,
          ScoreSubmissionResult.failed,
        ]));
      });
    });
  });
}