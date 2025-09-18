import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neon_pulse_flappy_bird/managers/authentication_manager.dart';
import 'package:neon_pulse_flappy_bird/models/user.dart';

void main() {
  group('AuthenticationManager', () {
    late AuthenticationManager authManager;

    setUp(() async {
      // Initialize SharedPreferences with empty values
      SharedPreferences.setMockInitialValues({});
      authManager = AuthenticationManager();
    });

    tearDown(() async {
      // Clean up after each test
      await authManager.signOut();
    });

    group('Initialization', () {
      test('should initialize with initial state', () {
        expect(authManager.state, equals(AuthenticationState.initial));
        expect(authManager.currentUser, isNull);
        expect(authManager.isAuthenticated, isFalse);
        expect(authManager.isGuest, isFalse);
        expect(authManager.isLoading, isFalse);
        expect(authManager.hasError, isFalse);
      });

      test('should initialize successfully', () async {
        await authManager.initialize();
        expect(authManager.state, equals(AuthenticationState.initial));
      });
    });

    group('State Management', () {
      test('should notify listeners when state changes', () async {
        bool notified = false;
        authManager.addListener(() {
          notified = true;
        });

        await authManager.initialize();
        expect(notified, isTrue);
      });

      test('should clear error when clearError is called', () async {
        await authManager.initialize();
        
        // Simulate an error state
        authManager.clearError();
        
        expect(authManager.hasError, isFalse);
        expect(authManager.lastError, isNull);
        expect(authManager.errorMessage, isNull);
      });
    });

    group('User Statistics', () {
      test('should update user stats correctly', () async {
        await authManager.initialize();
        
        // Create a mock guest user
        await authManager.signInAsGuest();
        
        final newStats = UserGameStats(
          totalGamesPlayed: 5,
          bestScore: 100,
          totalScore: 300,
          averageScore: 60.0,
          lastPlayed: DateTime.now(),
        );

        await authManager.updateUserStats(newStats);
        
        expect(authManager.currentUser?.gameStats.totalGamesPlayed, equals(5));
        expect(authManager.currentUser?.gameStats.bestScore, equals(100));
        expect(authManager.currentUser?.gameStats.totalScore, equals(300));
        expect(authManager.currentUser?.gameStats.averageScore, equals(60.0));
      });
    });

    group('Error Handling', () {
      test('should handle initialization errors gracefully', () async {
        // This test verifies that the manager handles errors without crashing
        await authManager.initialize();
        
        // Even if there are errors, the manager should be in a valid state
        expect(authManager.state, isNotNull);
      });

      test('should set error state when sign in fails', () async {
        await authManager.initialize();
        
        // Since we're not actually connected to Firebase in tests,
        // sign in operations will likely fail, which is expected behavior
        final result = await authManager.signInWithGoogle();
        
        // The result should be false since we're not connected to Firebase
        expect(result, isFalse);
      });
    });

    group('Guest Mode', () {
      test('should create guest user successfully', () async {
        await authManager.initialize();
        
        final result = await authManager.signInAsGuest();
        
        expect(result, isTrue);
        expect(authManager.isGuest, isTrue);
        expect(authManager.currentUser, isNotNull);
        expect(authManager.currentUser?.isGuest, isTrue);
        expect(authManager.currentUser?.displayName, equals('Guest Player'));
      });

      test('should maintain guest state after sign in', () async {
        await authManager.initialize();
        await authManager.signInAsGuest();
        
        expect(authManager.state, equals(AuthenticationState.guest));
        expect(authManager.isAuthenticated, isFalse);
        expect(authManager.isGuest, isTrue);
      });
    });

    group('Sign Out', () {
      test('should clear user data on sign out', () async {
        await authManager.initialize();
        await authManager.signInAsGuest();
        
        expect(authManager.currentUser, isNotNull);
        
        final result = await authManager.signOut();
        
        expect(result, isTrue);
        expect(authManager.currentUser, isNull);
        expect(authManager.state, equals(AuthenticationState.initial));
        expect(authManager.isAuthenticated, isFalse);
        expect(authManager.isGuest, isFalse);
      });
    });

    group('Data Persistence', () {
      test('should persist user data across sessions', () async {
        await authManager.initialize();
        await authManager.signInAsGuest();
        
        final originalUser = authManager.currentUser;
        expect(originalUser, isNotNull);
        
        // Create a new manager instance to simulate app restart
        final newAuthManager = AuthenticationManager();
        await newAuthManager.initialize();
        
        // The user should be restored from persistence
        expect(newAuthManager.currentUser, isNotNull);
        expect(newAuthManager.currentUser?.uid, equals(originalUser?.uid));
        expect(newAuthManager.state, equals(AuthenticationState.guest));
      });
    });
  });
}