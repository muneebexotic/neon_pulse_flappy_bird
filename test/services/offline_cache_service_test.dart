import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neon_pulse_flappy_bird/services/offline_cache_service.dart';
import 'package:neon_pulse_flappy_bird/services/leaderboard_service.dart';

void main() {
  group('OfflineCacheService', () {
    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should cache and retrieve leaderboard data', () async {
      // Create test data
      final testEntry = LeaderboardEntry(
        id: 'test123',
        userId: 'user123',
        playerName: 'Test Player',
        score: 100,
        timestamp: DateTime.now(),
        photoURL: 'https://example.com/photo.jpg',
        rank: 1,
      );

      final testData = LeaderboardData(
        topScores: [testEntry],
        userBestScore: testEntry,
        totalPlayers: 1,
        lastUpdated: DateTime.now(),
      );

      // Cache the data
      await OfflineCacheService.cacheLeaderboardData(testData);

      // Retrieve the data
      final cachedData = await OfflineCacheService.getCachedLeaderboardData();

      // Verify the data
      expect(cachedData, isNotNull);
      expect(cachedData!.topScores.length, equals(1));
      expect(cachedData.topScores.first.id, equals('test123'));
      expect(cachedData.topScores.first.playerName, equals('Test Player'));
      expect(cachedData.topScores.first.score, equals(100));
      expect(cachedData.userBestScore, isNotNull);
      expect(cachedData.userBestScore!.score, equals(100));
      expect(cachedData.totalPlayers, equals(1));
    });

    test('should cache and retrieve user best score', () async {
      final testEntry = LeaderboardEntry(
        id: 'best123',
        userId: 'user123',
        playerName: 'Best Player',
        score: 500,
        timestamp: DateTime.now(),
        rank: 5,
      );

      // Cache the score
      await OfflineCacheService.cacheUserBestScore(testEntry);

      // Retrieve the score
      final cachedScore = await OfflineCacheService.getCachedUserBestScore();

      // Verify the score
      expect(cachedScore, isNotNull);
      expect(cachedScore!.id, equals('best123'));
      expect(cachedScore.playerName, equals('Best Player'));
      expect(cachedScore.score, equals(500));
      expect(cachedScore.rank, equals(5));
    });

    test('should return null for non-existent cached data', () async {
      final cachedData = await OfflineCacheService.getCachedLeaderboardData();
      expect(cachedData, isNull);

      final cachedScore = await OfflineCacheService.getCachedUserBestScore();
      expect(cachedScore, isNull);
    });

    test('should check cache availability correctly', () async {
      // Initially no cache
      bool hasCache = await OfflineCacheService.hasCachedLeaderboardData();
      expect(hasCache, isFalse);

      // Cache some data
      final testData = LeaderboardData(
        topScores: [],
        totalPlayers: 0,
        lastUpdated: DateTime.now(),
      );
      await OfflineCacheService.cacheLeaderboardData(testData);

      // Now should have cache
      hasCache = await OfflineCacheService.hasCachedLeaderboardData();
      expect(hasCache, isTrue);
    });

    test('should provide cache age information', () async {
      // Initially no cache age
      int cacheAge = await OfflineCacheService.getCacheAgeMinutes();
      expect(cacheAge, equals(-1));

      // Cache some data
      final testData = LeaderboardData(
        topScores: [],
        totalPlayers: 0,
        lastUpdated: DateTime.now(),
      );
      await OfflineCacheService.cacheLeaderboardData(testData);

      // Should have recent cache age
      cacheAge = await OfflineCacheService.getCacheAgeMinutes();
      expect(cacheAge, greaterThanOrEqualTo(0));
      expect(cacheAge, lessThan(5)); // Should be very recent
    });

    test('should clear all cached data', () async {
      // Cache some data
      final testEntry = LeaderboardEntry(
        id: 'test123',
        userId: 'user123',
        playerName: 'Test Player',
        score: 100,
        timestamp: DateTime.now(),
        rank: 1,
      );

      final testData = LeaderboardData(
        topScores: [testEntry],
        totalPlayers: 1,
        lastUpdated: DateTime.now(),
      );

      await OfflineCacheService.cacheLeaderboardData(testData);
      await OfflineCacheService.cacheUserBestScore(testEntry);

      // Verify data is cached
      expect(await OfflineCacheService.getCachedLeaderboardData(), isNotNull);
      expect(await OfflineCacheService.getCachedUserBestScore(), isNotNull);

      // Clear cache
      await OfflineCacheService.clearCache();

      // Verify data is cleared
      expect(await OfflineCacheService.getCachedLeaderboardData(), isNull);
      expect(await OfflineCacheService.getCachedUserBestScore(), isNull);
    });

    test('should provide cache statistics', () async {
      // Initially no cache
      var stats = await OfflineCacheService.getCacheStats();
      expect(stats['hasLeaderboardCache'], isFalse);
      expect(stats['hasUserScoreCache'], isFalse);
      expect(stats['cacheAgeMinutes'], equals(-1));
      expect(stats['isExpired'], isTrue);

      // Cache some data
      final testEntry = LeaderboardEntry(
        id: 'test123',
        userId: 'user123',
        playerName: 'Test Player',
        score: 100,
        timestamp: DateTime.now(),
        rank: 1,
      );

      final testData = LeaderboardData(
        topScores: [testEntry],
        totalPlayers: 1,
        lastUpdated: DateTime.now(),
      );

      await OfflineCacheService.cacheLeaderboardData(testData);
      await OfflineCacheService.cacheUserBestScore(testEntry);

      // Check updated stats
      stats = await OfflineCacheService.getCacheStats();
      expect(stats['hasLeaderboardCache'], isTrue);
      expect(stats['hasUserScoreCache'], isTrue);
      expect(stats['cacheAgeMinutes'], greaterThanOrEqualTo(0));
      expect(stats['isExpired'], isFalse);
      expect(stats['expirationHours'], equals(1));
    });

    test('should handle empty leaderboard data', () async {
      final emptyData = LeaderboardData(
        topScores: [],
        totalPlayers: 0,
        lastUpdated: DateTime.now(),
      );

      await OfflineCacheService.cacheLeaderboardData(emptyData);
      final cachedData = await OfflineCacheService.getCachedLeaderboardData();

      expect(cachedData, isNotNull);
      expect(cachedData!.topScores, isEmpty);
      expect(cachedData.totalPlayers, equals(0));
      expect(cachedData.userBestScore, isNull);
    });

    test('should handle malformed cache data gracefully', () async {
      // Manually set invalid cache data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_leaderboard_data', 'invalid_json');

      // Should return null instead of throwing
      final cachedData = await OfflineCacheService.getCachedLeaderboardData();
      expect(cachedData, isNull);
    });

    test('should handle multiple leaderboard entries correctly', () async {
      final entries = List.generate(10, (index) => LeaderboardEntry(
        id: 'test$index',
        userId: 'user$index',
        playerName: 'Player $index',
        score: 100 - index,
        timestamp: DateTime.now().subtract(Duration(minutes: index)),
        rank: index + 1,
      ));

      final testData = LeaderboardData(
        topScores: entries,
        userBestScore: entries.first,
        totalPlayers: 10,
        lastUpdated: DateTime.now(),
      );

      await OfflineCacheService.cacheLeaderboardData(testData);
      final cachedData = await OfflineCacheService.getCachedLeaderboardData();

      expect(cachedData, isNotNull);
      expect(cachedData!.topScores.length, equals(10));
      expect(cachedData.topScores.first.score, equals(100));
      expect(cachedData.topScores.last.score, equals(91));
      expect(cachedData.userBestScore!.score, equals(100));
    });
  });
}