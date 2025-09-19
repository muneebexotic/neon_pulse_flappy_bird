import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';
import 'connectivity_service.dart';
import 'offline_cache_service.dart';

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
  /// Replaces existing user entry if new score is better, otherwise adds new entry
  static Future<bool> submitScore({
    required String userId,
    required String playerName,
    required int score,
    String? photoURL,
    String gameMode = _defaultGameMode,
  }) async {
    try {
      if (!ConnectivityService.isOnline) {
        // Queue score for later submission
        await _queueOfflineScore(userId, playerName, score, photoURL, gameMode);
        print('Score queued for offline submission: $score');
        return false;
      }

      // Validate score
      if (!_isValidScore(score)) {
        print('Invalid score: $score');
        return false;
      }

      print('Submitting score to Firestore: $score for user: $userId');

      // Check if user already has an entry on the leaderboard
      final existingUserScores = await FirebaseService.firestore!
          .collection(_leaderboardCollection)
          .doc(gameMode)
          .collection('scores')
          .where('userId', isEqualTo: userId)
          .get();

      final entry = LeaderboardEntry(
        id: '', // Will be set by Firestore
        userId: userId,
        playerName: playerName,
        score: score,
        timestamp: DateTime.now(),
        photoURL: photoURL,
      );

      if (existingUserScores.docs.isNotEmpty) {
        // User has existing entries - find the best one and replace it if new score is better
        var bestExistingDoc = existingUserScores.docs.first;
        final bestExistingData = bestExistingDoc.data() as Map<String, dynamic>;
        var bestExistingScore = bestExistingData['score'] ?? 0;
        
        // Find the actual best score among all user's entries
        for (final doc in existingUserScores.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final docScore = data['score'] ?? 0;
          if (docScore > bestExistingScore) {
            bestExistingDoc = doc;
            bestExistingScore = docScore;
          }
        }

        if (score > bestExistingScore) {
          // New score is better - replace the best existing entry
          await bestExistingDoc.reference.update(entry.toJson());
          print('Updated existing entry with better score: $score (was $bestExistingScore)');
          
          // Delete any other entries for this user to ensure only one entry per user
          for (final doc in existingUserScores.docs) {
            if (doc.id != bestExistingDoc.id) {
              await doc.reference.delete();
              print('Deleted duplicate entry for user: ${doc.id}');
            }
          }
          
          return true;
        } else {
          // New score is not better - don't submit
          print('Score $score is not better than existing best score $bestExistingScore, not submitting');
          
          // Still clean up any duplicate entries for this user
          if (existingUserScores.docs.length > 1) {
            // Keep the best entry, delete the rest
            for (int i = 1; i < existingUserScores.docs.length; i++) {
              await existingUserScores.docs[i].reference.delete();
              print('Deleted duplicate entry for user: ${existingUserScores.docs[i].id}');
            }
          }
          
          return false; // Indicate that score was not submitted
        }
      } else {
        // User has no existing entries - add new entry
        final docRef = await FirebaseService.firestore!
            .collection(_leaderboardCollection)
            .doc(gameMode)
            .collection('scores')
            .add(entry.toJson());

        print('Added new leaderboard entry: $score with ID: ${docRef.id}');
        return true;
      }
    } catch (e) {
      print('Failed to submit score: $e');
      print('Error type: ${e.runtimeType}');
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
      if (!ConnectivityService.isOnline) {
        // Try to get cached data when offline
        final cachedData = await OfflineCacheService.getCachedLeaderboardData();
        if (cachedData != null) {
          print('Returning cached leaderboard data (offline mode)');
          return cachedData;
        }
        
        // Return empty data if no cache available
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

      // Get user's score if userId provided (should be only one entry per user now)
      LeaderboardEntry? userBestScore;
      if (userId != null) {
        final userScoresQuery = await FirebaseService.firestore!
            .collection(_leaderboardCollection)
            .doc(gameMode)
            .collection('scores')
            .where('userId', isEqualTo: userId)
            .limit(1) // Should only be one entry per user
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

      final leaderboardData = LeaderboardData(
        topScores: topScores,
        userBestScore: userBestScore,
        totalPlayers: totalPlayersQuery.docs.length,
        lastUpdated: DateTime.now(),
      );

      // Cache the data for offline use
      await OfflineCacheService.cacheLeaderboardData(leaderboardData);
      
      // Cache user's best score separately if available
      if (userBestScore != null) {
        await OfflineCacheService.cacheUserBestScore(userBestScore);
      }

      return leaderboardData;
    } catch (e) {
      print('Failed to get leaderboard: $e');
      
      // Try to return cached data on error
      final cachedData = await OfflineCacheService.getCachedLeaderboardData();
      if (cachedData != null) {
        print('Returning cached leaderboard data due to error');
        return cachedData;
      }
      
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
    if (!ConnectivityService.isOnline) {
      // Return cached data as a stream when offline
      return Stream.fromFuture(_getCachedLeaderboardEntries());
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final queuedScoresJson = prefs.getString('queued_leaderboard_scores') ?? '[]';
      final queuedScoresList = jsonDecode(queuedScoresJson) as List;
      
      // Add new score to queue
      queuedScoresList.add({
        'userId': userId,
        'playerName': playerName,
        'score': score,
        'photoURL': photoURL,
        'gameMode': gameMode,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Keep only the latest 50 scores to prevent storage bloat
      if (queuedScoresList.length > 50) {
        queuedScoresList.removeRange(0, queuedScoresList.length - 50);
      }
      
      // Save back to storage
      await prefs.setString('queued_leaderboard_scores', jsonEncode(queuedScoresList));
      print('Score queued for offline submission: $score');
    } catch (e) {
      print('Error queuing score for offline submission: $e');
    }
  }

  /// Get cached leaderboard entries as a list
  static Future<List<LeaderboardEntry>> _getCachedLeaderboardEntries() async {
    try {
      final cachedData = await OfflineCacheService.getCachedLeaderboardData();
      return cachedData?.topScores ?? [];
    } catch (e) {
      print('Error getting cached leaderboard entries: $e');
      return [];
    }
  }

  /// Process queued offline scores
  static Future<void> processOfflineScores() async {
    try {
      if (!ConnectivityService.isOnline) return;
      
      final prefs = await SharedPreferences.getInstance();
      final queuedScoresJson = prefs.getString('queued_leaderboard_scores');
      
      if (queuedScoresJson == null) return;
      
      final queuedScoresList = jsonDecode(queuedScoresJson) as List;
      if (queuedScoresList.isEmpty) return;
      
      int processedCount = 0;
      final failedScores = <Map<String, dynamic>>[];
      
      for (final scoreData in queuedScoresList) {
        try {
          final success = await submitScore(
            userId: scoreData['userId'] ?? '',
            playerName: scoreData['playerName'] ?? '',
            score: scoreData['score'] ?? 0,
            photoURL: scoreData['photoURL'],
            gameMode: scoreData['gameMode'] ?? _defaultGameMode,
          );
          
          if (success) {
            processedCount++;
          } else {
            failedScores.add(scoreData);
          }
        } catch (e) {
          print('Failed to process queued score: $e');
          failedScores.add(scoreData);
        }
      }
      
      // Update queue with only failed scores
      await prefs.setString('queued_leaderboard_scores', jsonEncode(failedScores));
      
      if (processedCount > 0) {
        print('Processed $processedCount queued leaderboard scores');
      }
    } catch (e) {
      print('Error processing queued offline scores: $e');
    }
  }

  /// Get offline queue statistics
  static Future<Map<String, int>> getOfflineQueueStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queuedScoresJson = prefs.getString('queued_leaderboard_scores') ?? '[]';
      final queuedScoresList = jsonDecode(queuedScoresJson) as List;
      
      return {
        'queuedScores': queuedScoresList.length,
        'totalQueuedOperations': await ConnectivityService.getQueuedOperationsCount(),
      };
    } catch (e) {
      print('Error getting offline queue stats: $e');
      return {'queuedScores': 0, 'totalQueuedOperations': 0};
    }
  }

  /// Clean up old scores to maintain leaderboard size and ensure one entry per user
  static Future<void> cleanupOldScores({
    String gameMode = _defaultGameMode,
  }) async {
    try {
      if (!ConnectivityService.isOnline) return;

      // Get all scores
      final allScoresQuery = await FirebaseService.firestore!
          .collection(_leaderboardCollection)
          .doc(gameMode)
          .collection('scores')
          .get();

      // Group scores by userId to find duplicates
      final userScores = <String, List<QueryDocumentSnapshot>>{};
      for (final doc in allScoresQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] as String? ?? '';
        if (userId.isNotEmpty) {
          userScores.putIfAbsent(userId, () => []).add(doc);
        }
      }

      final batch = FirebaseService.firestore!.batch();
      int duplicatesDeleted = 0;

      // For each user, keep only their best score
      for (final userEntries in userScores.values) {
        if (userEntries.length > 1) {
          // Sort by score descending to find the best
          userEntries.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final scoreA = dataA['score'] as int? ?? 0;
            final scoreB = dataB['score'] as int? ?? 0;
            return scoreB.compareTo(scoreA);
          });

          // Delete all but the best entry
          for (int i = 1; i < userEntries.length; i++) {
            batch.delete(userEntries[i].reference);
            duplicatesDeleted++;
          }
        }
      }

      // After removing duplicates, check if we still need to remove low scores
      final remainingEntries = userScores.values.map((entries) => entries.first).toList();
      if (remainingEntries.length > _maxLeaderboardSize) {
        // Sort by score descending
        remainingEntries.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final scoreA = dataA['score'] as int? ?? 0;
          final scoreB = dataB['score'] as int? ?? 0;
          return scoreB.compareTo(scoreA);
        });

        // Delete entries beyond the max size
        for (int i = _maxLeaderboardSize; i < remainingEntries.length; i++) {
          batch.delete(remainingEntries[i].reference);
        }
      }

      if (duplicatesDeleted > 0 || remainingEntries.length > _maxLeaderboardSize) {
        await batch.commit();
        print('Cleaned up $duplicatesDeleted duplicate entries and maintained max leaderboard size');
      }
    } catch (e) {
      print('Failed to cleanup old scores: $e');
    }
  }
}