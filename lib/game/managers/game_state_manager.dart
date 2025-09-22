import 'dart:async';
import '../../../services/leaderboard_integration_service.dart';
import '../../../models/user.dart' as app_user;

/// Manages game state including score submission and restart controls
class GameStateManager {
  bool _scoreSubmissionInProgress = false;
  bool _restartEnabled = true;
  Timer? _submissionTimeoutTimer;
  
  static const Duration _maxSubmissionTimeout = Duration(seconds: 1);
  
  /// Whether score submission is currently in progress
  bool get isScoreSubmissionInProgress => _scoreSubmissionInProgress;
  
  /// Whether restart button should be enabled
  bool get isRestartEnabled => _restartEnabled;
  
  /// Determines if score submission loading should be shown
  /// Returns false only for obviously invalid cases (zero scores, unauthenticated users)
  /// The actual "best score" logic is handled by LeaderboardIntegrationService
  bool shouldShowScoreSubmission({
    required int score,
    required int currentBestScore,
    app_user.User? user,
  }) {
    // Don't show loading for zero scores
    if (score <= 0) {
      return false;
    }
    
    // Don't show loading if user is not authenticated
    if (user == null || user.uid == null) {
      return false;
    }
    
    // Show loading for all valid scores - let LeaderboardIntegrationService handle best score logic
    return true;
  }
  
  /// Starts score submission process with timeout and state management
  Future<ScoreSubmissionResult> submitScore({
    required int score,
    required GameSession gameSession,
    required app_user.User? user,
    String gameMode = 'classic',
  }) async {
    // Fast-fail for obviously invalid submissions
    if (_isObviouslyInvalid(score, gameSession)) {
      return ScoreSubmissionResult.invalidScore;
    }
    
    // Set submission state
    _setSubmissionInProgress(true);
    
    try {
      // Start timeout timer
      final completer = Completer<ScoreSubmissionResult>();
      
      _submissionTimeoutTimer = Timer(_maxSubmissionTimeout, () {
        if (!completer.isCompleted) {
          completer.complete(ScoreSubmissionResult.networkError);
        }
      });
      
      // Submit score
      final submissionFuture = LeaderboardIntegrationService.submitScore(
        score: score,
        gameSession: gameSession,
        user: user,
        gameMode: gameMode,
      );
      
      // Race between submission and timeout
      final result = await Future.any([
        submissionFuture,
        completer.future,
      ]);
      
      _submissionTimeoutTimer?.cancel();
      return result;
      
    } catch (e) {
      print('Error in GameStateManager.submitScore: $e');
      return ScoreSubmissionResult.failed;
    } finally {
      _setSubmissionInProgress(false);
    }
  }
  
  /// Sets score submission state and manages restart button
  void _setSubmissionInProgress(bool inProgress) {
    _scoreSubmissionInProgress = inProgress;
    _restartEnabled = !inProgress;
  }
  
  /// Enables restart button (called when submission completes)
  void enableRestart() {
    _restartEnabled = true;
  }
  
  /// Disables restart button (called when submission starts)
  void disableRestart() {
    _restartEnabled = false;
  }
  
  /// Fast-fail validation for obviously invalid submissions
  bool _isObviouslyInvalid(int score, GameSession gameSession) {
    // Negative scores are invalid
    if (score < 0) {
      return true;
    }
    
    // Impossibly high scores (more than 10000)
    if (score > 10000) {
      return true;
    }
    
    // Check session duration vs score ratio
    final sessionDuration = gameSession.endTime.difference(gameSession.startTime).inSeconds;
    
    // Session too short for the score (less than 0.1 seconds per point)
    if (sessionDuration > 0 && score / sessionDuration > 10) {
      return true;
    }
    
    // Session impossibly long (more than 1 hour)
    if (sessionDuration > 3600) {
      return true;
    }
    
    // Jump count validation (can't have more than 20 jumps per point)
    if (gameSession.jumpCount > score * 20) {
      return true;
    }
    
    // Survival time validation (can't survive longer than session duration + 5 seconds margin)
    if (gameSession.survivalTime > sessionDuration + 5) {
      return true;
    }
    
    return false;
  }
  
  /// Cleanup resources
  void dispose() {
    _submissionTimeoutTimer?.cancel();
    _submissionTimeoutTimer = null;
  }
}