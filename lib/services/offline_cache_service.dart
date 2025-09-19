import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'leaderboard_service.dart';

/// Service class for managing offline data caching
class OfflineCacheService {
  static const String _leaderboardCacheKey = 'cached_leaderboard_data';
  static const String _userBestScoreCacheKey = 'cached_user_best_score';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const Duration _cacheExpiration = Duration(hours: 1);

  /// Cache leaderboard data for offline viewing
  static Future<void> cacheLeaderboardData(LeaderboardData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cache the leaderboard data
      final cacheData = {
        'topScores': data.topScores.map((entry) => {
          'id': entry.id,
          'userId': entry.userId,
          'playerName': entry.playerName,
          'score': entry.score,
          'timestamp': entry.timestamp.toIso8601String(),
          'photoURL': entry.photoURL,
          'rank': entry.rank,
        }).toList(),
        'userBestScore': data.userBestScore != null ? {
          'id': data.userBestScore!.id,
          'userId': data.userBestScore!.userId,
          'playerName': data.userBestScore!.playerName,
          'score': data.userBestScore!.score,
          'timestamp': data.userBestScore!.timestamp.toIso8601String(),
          'photoURL': data.userBestScore!.photoURL,
          'rank': data.userBestScore!.rank,
        } : null,
        'totalPlayers': data.totalPlayers,
        'lastUpdated': data.lastUpdated.toIso8601String(),
      };
      
      await prefs.setString(_leaderboardCacheKey, jsonEncode(cacheData));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      
      print('Leaderboard data cached successfully');
    } catch (e) {
      print('Error caching leaderboard data: $e');
    }
  }

  /// Get cached leaderboard data
  static Future<LeaderboardData?> getCachedLeaderboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if cache exists and is not expired
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);
      if (cacheTimestamp == null) {
        return null;
      }
      
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTimestamp;
      if (cacheAge > _cacheExpiration.inMilliseconds) {
        print('Cached leaderboard data expired');
        return null;
      }
      
      final cachedDataJson = prefs.getString(_leaderboardCacheKey);
      if (cachedDataJson == null) {
        return null;
      }
      
      final cachedData = jsonDecode(cachedDataJson) as Map<String, dynamic>;
      
      // Parse top scores
      final topScoresList = cachedData['topScores'] as List? ?? [];
      final topScores = topScoresList.map((scoreData) {
        return LeaderboardEntry(
          id: scoreData['id'] ?? '',
          userId: scoreData['userId'] ?? '',
          playerName: scoreData['playerName'] ?? 'Unknown Player',
          score: scoreData['score'] ?? 0,
          timestamp: DateTime.parse(scoreData['timestamp'] ?? DateTime.now().toIso8601String()),
          photoURL: scoreData['photoURL'],
          rank: scoreData['rank'] ?? 0,
        );
      }).toList();
      
      // Parse user best score
      LeaderboardEntry? userBestScore;
      final userBestScoreData = cachedData['userBestScore'] as Map<String, dynamic>?;
      if (userBestScoreData != null) {
        userBestScore = LeaderboardEntry(
          id: userBestScoreData['id'] ?? '',
          userId: userBestScoreData['userId'] ?? '',
          playerName: userBestScoreData['playerName'] ?? 'Unknown Player',
          score: userBestScoreData['score'] ?? 0,
          timestamp: DateTime.parse(userBestScoreData['timestamp'] ?? DateTime.now().toIso8601String()),
          photoURL: userBestScoreData['photoURL'],
          rank: userBestScoreData['rank'] ?? 0,
        );
      }
      
      return LeaderboardData(
        topScores: topScores,
        userBestScore: userBestScore,
        totalPlayers: cachedData['totalPlayers'] ?? 0,
        lastUpdated: DateTime.parse(cachedData['lastUpdated'] ?? DateTime.now().toIso8601String()),
      );
    } catch (e) {
      print('Error getting cached leaderboard data: $e');
      return null;
    }
  }

  /// Cache user's best score separately for quick access
  static Future<void> cacheUserBestScore(LeaderboardEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final scoreData = {
        'id': entry.id,
        'userId': entry.userId,
        'playerName': entry.playerName,
        'score': entry.score,
        'timestamp': entry.timestamp.toIso8601String(),
        'photoURL': entry.photoURL,
        'rank': entry.rank,
      };
      
      await prefs.setString(_userBestScoreCacheKey, jsonEncode(scoreData));
      print('User best score cached: ${entry.score}');
    } catch (e) {
      print('Error caching user best score: $e');
    }
  }

  /// Get cached user best score
  static Future<LeaderboardEntry?> getCachedUserBestScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedScoreJson = prefs.getString(_userBestScoreCacheKey);
      
      if (cachedScoreJson == null) {
        return null;
      }
      
      final scoreData = jsonDecode(cachedScoreJson) as Map<String, dynamic>;
      
      return LeaderboardEntry(
        id: scoreData['id'] ?? '',
        userId: scoreData['userId'] ?? '',
        playerName: scoreData['playerName'] ?? 'Unknown Player',
        score: scoreData['score'] ?? 0,
        timestamp: DateTime.parse(scoreData['timestamp'] ?? DateTime.now().toIso8601String()),
        photoURL: scoreData['photoURL'],
        rank: scoreData['rank'] ?? 0,
      );
    } catch (e) {
      print('Error getting cached user best score: $e');
      return null;
    }
  }

  /// Check if cached data is available
  static Future<bool> hasCachedLeaderboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);
      
      if (cacheTimestamp == null) {
        return false;
      }
      
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTimestamp;
      return cacheAge <= _cacheExpiration.inMilliseconds;
    } catch (e) {
      print('Error checking cached data availability: $e');
      return false;
    }
  }

  /// Get cache age in minutes
  static Future<int> getCacheAgeMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);
      
      if (cacheTimestamp == null) {
        return -1;
      }
      
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTimestamp;
      return (cacheAge / (1000 * 60)).round();
    } catch (e) {
      print('Error getting cache age: $e');
      return -1;
    }
  }

  /// Clear all cached data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_leaderboardCacheKey);
      await prefs.remove(_userBestScoreCacheKey);
      await prefs.remove(_cacheTimestampKey);
      print('All cached data cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);
      final hasLeaderboardCache = prefs.containsKey(_leaderboardCacheKey);
      final hasUserScoreCache = prefs.containsKey(_userBestScoreCacheKey);
      
      int cacheAgeMinutes = -1;
      bool isExpired = true;
      
      if (cacheTimestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTimestamp;
        cacheAgeMinutes = (cacheAge / (1000 * 60)).round();
        isExpired = cacheAge > _cacheExpiration.inMilliseconds;
      }
      
      return {
        'hasLeaderboardCache': hasLeaderboardCache,
        'hasUserScoreCache': hasUserScoreCache,
        'cacheAgeMinutes': cacheAgeMinutes,
        'isExpired': isExpired,
        'expirationHours': _cacheExpiration.inHours,
      };
    } catch (e) {
      print('Error getting cache stats: $e');
      return {
        'hasLeaderboardCache': false,
        'hasUserScoreCache': false,
        'cacheAgeMinutes': -1,
        'isExpired': true,
        'expirationHours': _cacheExpiration.inHours,
      };
    }
  }
}