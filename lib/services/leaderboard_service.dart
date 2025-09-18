import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

/// Model for leaderboard entries
class LeaderboardEntry {
  final String id;
  final String userId;
  final String playerName;
  final int score;
  final DateTime timestamp;
  final String? photoURL;
  int rank;

  LeaderboardEntry({
    required this.id,
    required this.userId,
    required this.playerName,
    required this.score,
    required this.timestamp,
    this.photoURL,
    this.rank = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'playerName': playerName,
      'score': score,
      'timestamp': Timestamp.fromDate(timestamp),
      'photoURL': photoURL,
    };
  }

  static LeaderboardEntry fromJson(String id, Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: id,
      userId: json['userId'] ?? '',
      playerName: json['playerName'] ?? 'Unknown Player',
      score: json['score'] ?? 0,
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoURL: json['photoURL'],
    );
  }
}

/// Model for leaderboard data
class LeaderboardData {
  final List<LeaderboardEntry> topScores;
  final LeaderboardEntry? userBestScore;
  final int totalPlayers;
  final DateTime lastUpdated;

  LeaderboardData({
    required this.topScores,
    this.userBestScore,
    required this.totalPlayers,
    required this.lastUpdated,
  });
}

/// Service class for managing global leaderboards
class LeaderboardService {
  static const String _leaderboardCollection = 'leaderboards';
  static const String _defaultGameMode = 'classic';
  static const int _maxLeaderboardSize = 100;

  /// Submit a score to the leaderboard
  static Future<bool> submitScore({
    required String userId,
    required String playerName,
    required int score,
    String? photoURL,
    String gameMode = _defaultGameMode,
  }) async {
    try {
      if (!FirebaseService.isOnline) {
        // Queue score for later submission
        await _queueOfflineScore(userId, playerName, score, photoURL, gameMode);
        return false;
      }

      // Validate score
      if (!_isValidScore(score)) {
        print('Invalid score: $score');
        return false;
      }

      final entry = LeaderboardEntry(
        id: '', // Will be set by Firestore
        userId: userId,
        playerName: playerName,
        score: score,
        timestamp: DateTime.now(),
        photoURL: photoURL,
      );

      // Submit to Firestore
      await FirebaseService.firestore!
          .collection(_leaderboardCollection)
          .doc(gameMode)
          .collection('scores')
          .add(entry.toJson());

      print('Score submitted successfully: $score');
      return true;
    } catch (e) {
      print('Failed to submit score: $e');
      // Queue for offline submission
      await _queueOfflineScore(userId, playerName, score, photoURL, gameMode);
      return false;
    }
  }

  /// Get top scores from leaderboard
  static Future<LeaderboardData> getLeaderboard({
    String gameMode = _defaultGameMode,
    int limit = 50,
    String? userId,
  }) async {
    try {
      if (!FirebaseService.isOnline) {
        return LeaderboardData(
          topScores: [],
          userBestScore: null,
          totalPlayers: 0,
          lastUpdated: DateTime.now(),
        );
      }

      // Get top scores
      final topScoresQuery = await FirebaseService.firestore!
          .collection(_leaderboardCollection)
          .doc(gameMode)
          .collection('scores')
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      final topScores = <LeaderboardEntry>[];
      for (int i = 0; i < topScoresQuery.docs.length; i++) {
        final doc = topScoresQuery.docs[i];
        final entry = LeaderboardEntry.fromJson(doc.id, doc.data());
        entry.rank = i + 1;
        topScores.add(entry);
      }

      // Get user's best score if userId provided
      LeaderboardEntry? userBestScore;
      if (userId != null) {
        final userScoresQuery = await FirebaseService.firestore!
            .collection(_leaderboardCollection)
            .doc(gameMode)
            .collection('scores')
            .where('userId', isEqualTo: userId)
            .orderBy('score', descending: true)
            .limit(1)
            .get();

        if (userScoresQuery.docs.isNotEmpty) {
          final doc = userScoresQuery.docs.first;
          userBestScore = LeaderboardEntry.fromJson(doc.id, doc.data());
          
          // Calculate user's rank
          final rankQuery = await FirebaseService.firestore!
              .collection(_leaderboardCollection)
              .doc(gameMode)
              .collection('scores')
              .where('score', isGreaterThan: userBestScore.score)
              .get();
          
          userBestScore.rank = rankQuery.docs.length + 1;
        }
      }

      // Get total player count
      final totalPlayersQuery = await FirebaseService.firestore!
          .collection(_leaderboardCollection)
          .doc(gameMode)
          .collection('scores')
          .get();

      return LeaderboardData(
        topScores: topScores,
        userBestScore: userBestScore,
        totalPlayers: totalPlayersQuery.docs.length,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('Failed to get leaderboard: $e');
      return LeaderboardData(
        topScores: [],
        userBestScore: null,
        totalPlayers: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Get real-time leaderboard updates
  static Stream<List<LeaderboardEntry>> getLeaderboardStream({
    String gameMode = _defaultGameMode,
    int limit = 50,
  }) {
    if (!FirebaseService.isOnline) {
      return Stream.value([]);
    }

    return FirebaseService.firestore!
        .collection(_leaderboardCollection)
        .doc(gameMode)
        .collection('scores')
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final entries = <LeaderboardEntry>[];
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final entry = LeaderboardEntry.fromJson(doc.id, doc.data());
        entry.rank = i + 1;
        entries.add(entry);
      }
      return entries;
    });
  }

  /// Validate score to prevent cheating
  static bool _isValidScore(int score) {
    return score >= 0 && score <= 10000; // Maximum reasonable score
  }

  /// Queue score for offline submission
  static Future<void> _queueOfflineScore(
    String userId,
    String playerName,
    int score,
    String? photoURL,
    String gameMode,
  ) async {
    // TODO: Implement offline score queuing using local storage
    // This would store scores locally and submit them when online
    print('Score queued for offline submission: $score');
  }

  /// Process queued offline scores
  static Future<void> processOfflineScores() async {
    // TODO: Implement processing of queued offline scores
    // This would be called when the app comes back online
    print('Processing offline scores...');
  }

  /// Clean up old scores to maintain leaderboard size
  static Future<void> cleanupOldScores({
    String gameMode = _defaultGameMode,
  }) async {
    try {
      if (!FirebaseService.isOnline) return;

      // Get all scores ordered by score descending
      final allScoresQuery = await FirebaseService.firestore!
          .collection(_leaderboardCollection)
          .doc(gameMode)
          .collection('scores')
          .orderBy('score', descending: true)
          .get();

      // If we have more than the max size, delete the excess
      if (allScoresQuery.docs.length > _maxLeaderboardSize) {
        final docsToDelete = allScoresQuery.docs.skip(_maxLeaderboardSize);
        
        final batch = FirebaseService.firestore!.batch();
        for (final doc in docsToDelete) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        print('Cleaned up ${docsToDelete.length} old scores');
      }
    } catch (e) {
      print('Failed to cleanup old scores: $e');
    }
  }
}