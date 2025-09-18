import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neon_pulse_flappy_bird/providers/authentication_provider.dart';
import 'package:neon_pulse_flappy_bird/models/user.dart';

void main() {
  group('AuthenticationProvider', () {
    late AuthenticationProvider authProvider;

    setUp(() async {
      // Initialize SharedPreferences with empty values
      SharedPreferences.setMockInitialValues({});
      authProvider = AuthenticationProvider();
    });

    tearDown(() async {
      // Clean up after each test
      await authProvider.signOut();
      authProvider.dispose();
    });

    group('Initialization', () {
      test('should initialize with correct default state', () {
        expect(authProvider.state, equals(AuthenticationState.initial));
        expect(authProvider.currentUser, isNull);
        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.isGuest, isFalse);
        expect(authProvider.isLoading, isFalse);
        expect(authProvider.hasError, isFalse);
      });

      test('should initialize successfully', () async {
        await authProvider.initialize();
        expect(authProvider.state, equals(AuthenticationState.initial));
      });
    });

    group('User Display Methods', () {
      test('should return default display name when no user', () {
        final displayName = authProvider.getUserDisplayName();
        expect(displayName, equals('Player'));
      });

      test('should return guest display name for guest user', () async {
        await authProvider.initialize();
        await authProvider.signInAsGuest();
        
        final displayName = authProvider.getUserDisplayName();
        expect(displayName, equals('Guest Player'));
      });

      test('should return null avatar URL when no user', () {
        final avatarUrl = authProvider.getUserAvatarUrl();
        expect(avatarUrl, isNull);
      });
    });

    group('Premium Features Access', () {
      test('should deny premium features for guest users', () async {
        await authProvider.initialize();
        await authProvider.signInAsGuest();
        
        expect(authProvider.canAccessPremiumFeatures(), isFalse);
      });

      test('should deny premium features when not authenticated', () {
        expect(authProvider.canAccessPremiumFeatures(), isFalse);
      });
    });

    group('Game Statistics', () {
      test('should return zero stats when no user', () {
        expect(authProvider.getUserBestScore(), equals(0));
        expect(authProvider.getUserTotalGames(), equals(0));
        expect(authProvider.getUserAverageScore(), equals(0.0));
      });

      test('should record game result correctly', () async {
        await authProvider.initialize();
        await authProvider.signInAsGuest();
        
        // Record first game
        await authProvider.recordGameResult(50);
        
        expect(authProvider.getUserBestScore(), equals(50));
        expect(authProvider.getUserTotalGames(), equals(1));
        expect(authProvider.getUserAverageScore(), equals(50.0));
        
        // Record second game
        await authProvider.recordGameResult(100);
        
        expect(authProvider.getUserBestScore(), equals(100));
        expect(authProvider.getUserTotalGames(), equals(2));
        expect(authProvider.getUserAverageScore(), equals(75.0));
        
        // Record third game with lower score
        await authProvider.recordGameResult(25);
        
        expect(authProvider.getUserBestScore(), equals(100)); // Should remain 100
        expect(authProvider.getUserTotalGames(), equals(3));
        expect(authProvider.getUserAverageScore(), closeTo(58.33, 0.01));
      });
    });

    group('Achievement System', () {
      test('should update achievement progress correctly', () async {
        await authProvider.initialize();
        await authProvider.signInAsGuest();
        
        await authProvider.updateAchievementProgress('first_flight', 1);
        await authProvider.updateAchievementProgress('score_master', 50);
        
        expect(authProvider.getAchievementProgress('first_flight'), equals(1));
        expect(authProvider.getAchievementProgress('score_master'), equals(50));
        expect(authProvider.getAchievementProgress('nonexistent'), equals(0));
      });

      test('should check achievement completion correctly', () async {
        await authProvider.initialize();
        await authProvider.signInAsGuest();
        
        await authProvider.updateAchievementProgress('score_100', 100);
        
        expect(authProvider.hasCompletedAchievement('score_100', 100), isTrue);
        expect(authProvider.hasCompletedAchievement('score_100', 150), isFalse);
        expect(authProvider.hasCompletedAchievement('score_100', 50), isTrue);
      });
    });

    group('Error Handling', () {
      test('should format error messages correctly', () {
        // Test with no error
        expect(authProvider.getFormattedErrorMessage(), equals(''));
        
        // Since we can't easily simulate specific errors in unit tests,
        // we'll test the error formatting logic indirectly
        authProvider.clearError();
        expect(authProvider.hasError, isFalse);
      });
    });

    group('State Notifications', () {
      test('should notify listeners when state changes', () async {
        bool notified = false;
        authProvider.addListener(() {
          notified = true;
        });

        await authProvider.initialize();
        expect(notified, isTrue);
      });

      test('should notify listeners when user stats change', () async {
        await authProvider.initialize();
        await authProvider.signInAsGuest();
        
        bool notified = false;
        authProvider.addListener(() {
          notified = true;
        });

        await authProvider.recordGameResult(100);
        expect(notified, isTrue);
      });
    });

    group('Guest User Operations', () {
      test('should create guest user successfully', () async {
        await authProvider.initialize();
        
        final result = await authProvider.signInAsGuest();
        
        expect(result, isTrue);
        expect(authProvider.isGuest, isTrue);
        expect(authProvider.currentUser, isNotNull);
        expect(authProvider.currentUser?.isGuest, isTrue);
      });

      test('should maintain guest statistics', () async {
        await authProvider.initialize();
        await authProvider.signInAsGuest();
        
        await authProvider.recordGameResult(75);
        await authProvider.updateAchievementProgress('test_achievement', 5);
        
        expect(authProvider.getUserBestScore(), equals(75));
        expect(authProvider.getAchievementProgress('test_achievement'), equals(5));
      });
    });

    group('Sign Out', () {
      test('should clear all data on sign out', () async {
        await authProvider.initialize();
        await authProvider.signInAsGuest();
        await authProvider.recordGameResult(100);
        
        expect(authProvider.currentUser, isNotNull);
        expect(authProvider.getUserBestScore(), equals(100));
        
        final result = await authProvider.signOut();
        
        expect(result, isTrue);
        expect(authProvider.currentUser, isNull);
        expect(authProvider.getUserBestScore(), equals(0));
        expect(authProvider.state, equals(AuthenticationState.initial));
      });
    });
  });
}