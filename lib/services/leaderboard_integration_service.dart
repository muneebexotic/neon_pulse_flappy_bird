import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'leaderboard_service.dart';
import '../models/user.dart' as app_user;

/// Result of score submission
enum ScoreSubmissionResult {
  success,
  queued,
  failed,
  invalidScore,
  notAuthenticated,
  networkError,
}

/// Model for queued offline scores
class QueuedScore {
  final String userId;
  final String playerName;
  final int score;
  final String? photoURL;
  final DateTime timestamp;
  final String gameMode;
  final Map<String, dynamic> gameSession;

  QueuedScore({
    required this.userId,
    required this.playerName,
    required this.score,
    this.photoURL,
    required this.timestamp,
    this.gameMode = 'classic',
    required this.gameSession,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'playerName': playerName,
      'score': score,
      'photoURL': photoURL,
      'timestamp': timestamp.toIso8601String(),
      'gameMode': gameMode,
      'gameSession': gameSession,
    };
  }

  static QueuedScore fromJson(Map<String, dynamic> json) {
    return QueuedScore(
      userId: json['userId'] ?? '',
      playerName: json['playerName'] ?? '',
      score: json['score'] ?? 0,
      photoURL: json['photoURL'],
      timestamp: DateTime.parse(json['timestamp']),
      gameMode: json['gameMode'] ?? 'classic',
      gameSession: json['gameSession'] ?? {},
    );
  }
}

/// Model for game session validation
class GameSession {
  final DateTime startTime;
  final DateTime endTime;
  final int finalScore;
  final int jumpCount;
  final int pulseUsage;
  final int powerUpsCollected;
  final double survivalTime;
  final String sessionId;

  GameSession({
    required this.startTime,
    required this.endTime,
    required this.finalScore,
    required this.jumpCount,
    required this.pulseUsage,
    required this.powerUpsCollected,
    required this.survivalTime,
    required this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'finalScore': finalScore,
      'jumpCount': jumpCount,
      'pulseUsage': pulseUsage,
      'powerUpsCollected': powerUpsCollected,
      'survivalTime': survivalTime,
      'sessionId': sessionId,
    };
  }

  /// Validate game session for anti-cheat measures
  bool isValid() {
    // Basic validation rules
    if (finalScore < 0 || finalScore > 10000) return false;
    if (survivalTime < 0 || survivalTime > 3600) return false; // Max 1 hour
    if (jumpCount < 0 || jumpCount > finalScore * 10) return false; // Reasonable jump ratio
    if (pulseUsage < 0 || pulseUsage > finalScore) return false; // Can't use more pulses than score
    if (powerUpsCollected < 0 || powerUpsCollected > finalScore) return false;
    
    // Time-based validation
    final sessionDuration = endTime.difference(startTime).inSeconds;
    if (sessionDuration < 1 || sessionDuration > 3600) return false;
    if (survivalTime > sessionDuration + 5) return false; // Allow small margin
    
    // Score-time ratio validation (prevent impossible scores)
    final minTimeForScore = finalScore * 0.5; // At least 0.5 seconds per point
    if (survivalTime < minTimeForScore) return false;
    
    return true;
  }
}

/// Service for integrating leaderboard with game flow
class LeaderboardIntegrationService {
  static const String _queuedScoresKey = 'queued_scores';
  static const String _lastSubmissionKey = 'last_submission_time';
  static const int _submissionCooldownSeconds = 5; // Prevent spam submissions
  
  /// Submit score with comprehensive validation and anti-cheat measures
  static Future<ScoreSubmissionResult> submitScore({
    required int score,
    required GameSession gameSession,
    app_user.User? user,
    String gameMode = 'classic',
  }) async {
    try {
      // Check if user exists (allow both authenticated and guest users)
      if (user == null) {
        return ScoreSubmissionResult.notAuthenticated;
      }

      // Validate score
      if (!_isValidScore(score)) {
        print('Invalid score: $score');
        return ScoreSubmissionResult.invalidScore;
      }

      // Validate game session for anti-cheat
      if (!gameSession.isValid()) {
        print('Invalid game session detected');
        return ScoreSubmissionResult.invalidScore;
      }

      // Check submission cooldown to prevent spam
      if (await _isInCooldown()) {
        print('Score submission in cooldown period');
        return ScoreSubmissionResult.failed;
      }

      // Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult == ConnectivityResult.mobile ||
                      connectivityResult == ConnectivityResult.wifi;

      if (!isOnline) {
        // Queue score for offline submission
        await _queueScore(user, score, gameSession, gameMode);
        return ScoreSubmissionResult.queued;
      }

      // Submit score to leaderboard
      final success = await LeaderboardService.submitScore(
        userId: user.uid!,
        playerName: user.displayName ?? 'Player',
        score: score,
        photoURL: user.photoURL,
        gameMode: gameMode,
      );

      if (success) {
        await _updateLastSubmissionTime();
        return ScoreSubmissionResult.success;
      } else {
        // Queue score if submission failed
        await _queueScore(user, score, gameSession, gameMode);
        return ScoreSubmissionResult.queued;
      }
    } catch (e) {
      print('Error submitting score: $e');
      
      // Try to queue score as fallback
      if (user != null) {
        await _queueScore(user, score, gameSession, gameMode);
        return ScoreSubmissionResult.queued;
      }
      
      return ScoreSubmissionResult.failed;
    }
  }

  /// Process all queued offline scores
  static Future<int> processQueuedScores() async {
    try {
      final queuedScores = await _getQueuedScores();
      if (queuedScores.isEmpty) return 0;

      // Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult == ConnectivityResult.mobile ||
                      connectivityResult == ConnectivityResult.wifi;

      if (!isOnline) return 0;

      int processedCount = 0;
      final failedScores = <QueuedScore>[];

      for (final queuedScore in queuedScores) {
        try {
          final success = await LeaderboardService.submitScore(
            userId: queuedScore.userId,
            playerName: queuedScore.playerName,
            score: queuedScore.score,
            photoURL: queuedScore.photoURL,
            gameMode: queuedScore.gameMode,
          );

          if (success) {
            processedCount++;
            print('Processed queued score: ${queuedScore.score}');
          } else {
            failedScores.add(queuedScore);
          }
        } catch (e) {
          print('Failed to process queued score: $e');
          failedScores.add(queuedScore);
        }
      }

      // Update queue with failed scores only
      await _saveQueuedScores(failedScores);
      
      if (processedCount > 0) {
        print('Processed $processedCount queued scores');
      }

      return processedCount;
    } catch (e) {
      print('Error processing queued scores: $e');
      return 0;
    }
  }

  /// Get user's leaderboard position for a specific score
  static Future<int?> getUserLeaderboardPosition({
    required String userId,
    required int score,
    String gameMode = 'classic',
  }) async {
    try {
      final leaderboardData = await LeaderboardService.getLeaderboard(
        gameMode: gameMode,
        limit: 1000, // Get more entries to find user position
        userId: userId,
      );

      // Find user's position based on score
      for (int i = 0; i < leaderboardData.topScores.length; i++) {
        if (leaderboardData.topScores[i].score <= score) {
          return i + 1; // Position is 1-based
        }
      }

      // If not found in top scores, estimate position
      return leaderboardData.topScores.length + 1;
    } catch (e) {
      print('Error getting user leaderboard position: $e');
      return null;
    }
  }

  /// Check if score qualifies for top leaderboard positions
  static Future<bool> isTopScore({
    required int score,
    int topN = 10,
    String gameMode = 'classic',
  }) async {
    try {
      final leaderboardData = await LeaderboardService.getLeaderboard(
        gameMode: gameMode,
        limit: topN,
      );

      if (leaderboardData.topScores.length < topN) {
        return true; // Leaderboard not full yet
      }

      final lowestTopScore = leaderboardData.topScores.last.score;
      return score > lowestTopScore;
    } catch (e) {
      print('Error checking if top score: $e');
      return false;
    }
  }

  /// Get celebration level based on achievement
  static Future<CelebrationLevel> getCelebrationLevel({
    required int score,
    required bool isPersonalBest,
    String gameMode = 'classic',
  }) async {
    try {
      // Check if it's a top global score
      final isTop10 = await isTopScore(score: score, topN: 10, gameMode: gameMode);
      final isTop100 = await isTopScore(score: score, topN: 100, gameMode: gameMode);

      if (isTop10) {
        return CelebrationLevel.legendary; // Top 10 global
      } else if (isTop100) {
        return CelebrationLevel.epic; // Top 100 global
      } else if (isPersonalBest) {
        return CelebrationLevel.great; // Personal best
      } else {
        return CelebrationLevel.good; // Regular score
      }
    } catch (e) {
      print('Error determining celebration level: $e');
      return isPersonalBest ? CelebrationLevel.great : CelebrationLevel.good;
    }
  }

  /// Clear all queued scores (for testing or reset)
  static Future<void> clearQueuedScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queuedScoresKey);
  }

  /// Get count of queued scores
  static Future<int> getQueuedScoreCount() async {
    final queuedScores = await _getQueuedScores();
    return queuedScores.length;
  }

  // Private helper methods

  static bool _isValidScore(int score) {
    return score >= 0 && score <= 10000; // Maximum reasonable score
  }

  static Future<bool> _isInCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSubmissionTime = prefs.getInt(_lastSubmissionKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cooldownMs = _submissionCooldownSeconds * 1000;
    
    return (now - lastSubmissionTime) < cooldownMs;
  }

  static Future<void> _updateLastSubmissionTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSubmissionKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> _queueScore(
    app_user.User user,
    int score,
    GameSession gameSession,
    String gameMode,
  ) async {
    final queuedScore = QueuedScore(
      userId: user.uid!,
      playerName: user.displayName ?? 'Player',
      score: score,
      photoURL: user.photoURL,
      timestamp: DateTime.now(),
      gameMode: gameMode,
      gameSession: gameSession.toJson(),
    );

    final queuedScores = await _getQueuedScores();
    queuedScores.add(queuedScore);
    
    // Keep only the latest 50 queued scores to prevent storage bloat
    if (queuedScores.length > 50) {
      queuedScores.removeRange(0, queuedScores.length - 50);
    }
    
    await _saveQueuedScores(queuedScores);
    print('Score queued for offline submission: $score');
  }

  static Future<List<QueuedScore>> _getQueuedScores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoresJson = prefs.getString(_queuedScoresKey);
      
      if (scoresJson == null) return [];
      
      final scoresList = jsonDecode(scoresJson) as List;
      return scoresList.map((json) => QueuedScore.fromJson(json)).toList();
    } catch (e) {
      print('Error loading queued scores: $e');
      return [];
    }
  }

  static Future<void> _saveQueuedScores(List<QueuedScore> scores) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoresJson = jsonEncode(scores.map((s) => s.toJson()).toList());
      await prefs.setString(_queuedScoresKey, scoresJson);
    } catch (e) {
      print('Error saving queued scores: $e');
    }
  }
}

/// Celebration levels for different achievements
enum CelebrationLevel {
  good,      // Regular score
  great,     // Personal best
  epic,      // Top 100 global
  legendary, // Top 10 global
}