import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/authentication_service.dart';
import '../utils/secure_storage.dart';

/// Authentication state enum
enum AuthenticationState {
  initial,
  loading,
  authenticated,
  guest,
  error,
}

/// Authentication error types
enum AuthenticationError {
  networkError,
  signInCancelled,
  signInFailed,
  signOutFailed,
  accountUpgradeFailed,
  tokenExpired,
  unknown,
}

/// Authentication manager that handles user authentication state and persistence
class AuthenticationManager extends ChangeNotifier {
  static const String _userKey = 'cached_user';
  static const String _authStateKey = 'auth_state';
  static const String _sessionTokenKey = 'session_token';
  
  AuthenticationState _state = AuthenticationState.initial;
  User? _currentUser;
  AuthenticationError? _lastError;
  String? _errorMessage;
  SharedPreferences? _prefs;
  
  // Getters
  AuthenticationState get state => _state;
  User? get currentUser => _currentUser;
  AuthenticationError? get lastError => _lastError;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthenticationState.authenticated;
  bool get isGuest => _state == AuthenticationState.guest;
  bool get isLoading => _state == AuthenticationState.loading;
  bool get hasError => _state == AuthenticationState.error;
  
  /// Initialize the authentication manager
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await SecureStorage.initialize();
      await _loadPersistedUser();
      await _validateSession();
    } catch (e) {
      debugPrint('Failed to initialize AuthenticationManager: $e');
      _setState(AuthenticationState.error);
      _setError(AuthenticationError.unknown, 'Failed to initialize authentication');
    }
  }
  
  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setState(AuthenticationState.loading);
    _clearError();
    
    try {
      final user = await AuthenticationService.signInWithGoogle();
      
      if (user != null) {
        _currentUser = user;
        await _persistUser(user);
        await _persistAuthState(AuthenticationState.authenticated);
        await _storeSecureTokens();
        _setState(AuthenticationState.authenticated);
        return true;
      } else {
        _setError(AuthenticationError.signInCancelled, 'Sign in was cancelled');
        _setState(AuthenticationState.error);
        return false;
      }
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      _setError(AuthenticationError.signInFailed, 'Failed to sign in with Google: ${e.toString()}');
      _setState(AuthenticationState.error);
      return false;
    }
  }
  
  /// Sign in as guest
  Future<bool> signInAsGuest() async {
    _setState(AuthenticationState.loading);
    _clearError();
    
    try {
      final user = await AuthenticationService.signInAsGuest();
      
      if (user != null) {
        _currentUser = user;
        await _persistUser(user);
        await _persistAuthState(AuthenticationState.guest);
        _setState(AuthenticationState.guest);
        return true;
      } else {
        _setError(AuthenticationError.signInFailed, 'Failed to create guest account');
        _setState(AuthenticationState.error);
        return false;
      }
    } catch (e) {
      debugPrint('Guest sign-in failed: $e');
      _setError(AuthenticationError.signInFailed, 'Failed to sign in as guest: ${e.toString()}');
      _setState(AuthenticationState.error);
      return false;
    }
  }
  
  /// Upgrade guest account to Google account
  Future<bool> upgradeGuestToGoogle() async {
    if (!isGuest) {
      _setError(AuthenticationError.accountUpgradeFailed, 'Can only upgrade guest accounts');
      return false;
    }
    
    _setState(AuthenticationState.loading);
    _clearError();
    
    try {
      final user = await AuthenticationService.upgradeGuestToGoogle();
      
      if (user != null) {
        // Preserve game statistics from guest account
        final updatedUser = user.copyWith(
          gameStats: _currentUser?.gameStats ?? user.gameStats,
        );
        
        _currentUser = updatedUser;
        await _persistUser(updatedUser);
        await _persistAuthState(AuthenticationState.authenticated);
        await _storeSecureTokens();
        _setState(AuthenticationState.authenticated);
        return true;
      } else {
        _setError(AuthenticationError.accountUpgradeFailed, 'Failed to upgrade guest account');
        _setState(AuthenticationState.error);
        return false;
      }
    } catch (e) {
      debugPrint('Account upgrade failed: $e');
      _setError(AuthenticationError.accountUpgradeFailed, 'Failed to upgrade account: ${e.toString()}');
      _setState(AuthenticationState.error);
      return false;
    }
  }
  
  /// Sign out
  Future<bool> signOut() async {
    _setState(AuthenticationState.loading);
    _clearError();
    
    try {
      await AuthenticationService.signOut();
      await _clearPersistedData();
      await _clearSecureTokens();
      _currentUser = null;
      _setState(AuthenticationState.initial);
      return true;
    } catch (e) {
      debugPrint('Sign out failed: $e');
      _setError(AuthenticationError.signOutFailed, 'Failed to sign out: ${e.toString()}');
      _setState(AuthenticationState.error);
      return false;
    }
  }
  
  /// Update user game statistics
  Future<void> updateUserStats(UserGameStats newStats) async {
    if (_currentUser == null) return;
    
    try {
      final updatedUser = _currentUser!.copyWith(gameStats: newStats);
      _currentUser = updatedUser;
      await _persistUser(updatedUser);
      
      // Save to Firestore if authenticated
      if (isAuthenticated && !_currentUser!.isGuest) {
        await AuthenticationService.saveUserProfile(updatedUser);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update user stats: $e');
    }
  }
  
  /// Refresh user profile from server
  Future<void> refreshUserProfile() async {
    if (_currentUser?.uid == null || isGuest) return;
    
    try {
      final serverUser = await AuthenticationService.loadUserProfile(_currentUser!.uid!);
      if (serverUser != null) {
        _currentUser = serverUser;
        await _persistUser(serverUser);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to refresh user profile: $e');
    }
  }
  
  /// Clear authentication error
  void clearError() {
    _clearError();
    if (_state == AuthenticationState.error) {
      _setState(AuthenticationState.initial);
    }
  }
  
  /// Private methods
  
  void _setState(AuthenticationState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }
  
  void _setError(AuthenticationError error, String message) {
    _lastError = error;
    _errorMessage = message;
  }
  
  void _clearError() {
    _lastError = null;
    _errorMessage = null;
  }
  
  /// Load persisted user data
  Future<void> _loadPersistedUser() async {
    try {
      final userJson = _prefs?.getString(_userKey);
      final authStateString = _prefs?.getString(_authStateKey);
      
      if (userJson != null && authStateString != null) {
        final userData = json.decode(userJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(userData);
        
        // Parse auth state
        final authState = AuthenticationState.values.firstWhere(
          (state) => state.toString() == authStateString,
          orElse: () => AuthenticationState.initial,
        );
        
        _setState(authState);
      }
    } catch (e) {
      debugPrint('Failed to load persisted user: $e');
      await _clearPersistedData();
    }
  }
  
  /// Validate current session
  Future<void> _validateSession() async {
    if (_currentUser == null) {
      _setState(AuthenticationState.initial);
      return;
    }
    
    // For guest users, no validation needed
    if (_currentUser!.isGuest) {
      return;
    }
    
    // For authenticated users, check if Firebase session is still valid
    try {
      final currentFirebaseUser = AuthenticationService.currentUser;
      final tokensValid = await _validateStoredTokens();
      
      if (currentFirebaseUser == null || 
          currentFirebaseUser.uid != _currentUser!.uid || 
          !tokensValid) {
        // Session expired or invalid
        await _clearPersistedData();
        await _clearSecureTokens();
        _currentUser = null;
        _setState(AuthenticationState.initial);
        _setError(AuthenticationError.tokenExpired, 'Session expired, please sign in again');
      }
    } catch (e) {
      debugPrint('Session validation failed: $e');
      // Keep current state but log the error
    }
  }
  
  /// Persist user data
  Future<void> _persistUser(User user) async {
    try {
      final userJson = json.encode(user.toJson());
      await _prefs?.setString(_userKey, userJson);
    } catch (e) {
      debugPrint('Failed to persist user: $e');
    }
  }
  
  /// Persist authentication state
  Future<void> _persistAuthState(AuthenticationState state) async {
    try {
      await _prefs?.setString(_authStateKey, state.toString());
    } catch (e) {
      debugPrint('Failed to persist auth state: $e');
    }
  }
  
  /// Clear all persisted data
  Future<void> _clearPersistedData() async {
    try {
      await _prefs?.remove(_userKey);
      await _prefs?.remove(_authStateKey);
      await _prefs?.remove(_sessionTokenKey);
    } catch (e) {
      debugPrint('Failed to clear persisted data: $e');
    }
  }
  
  /// Store secure authentication tokens
  Future<void> _storeSecureTokens() async {
    try {
      final currentFirebaseUser = AuthenticationService.currentUser;
      if (currentFirebaseUser != null) {
        // Store Firebase ID token securely
        final idToken = await currentFirebaseUser.getIdToken();
        if (idToken != null) {
          await SecureStorage.storeAuthToken(idToken);
        }
        
        // Store user credentials for session validation
        final credentials = {
          'uid': currentFirebaseUser.uid,
          'email': currentFirebaseUser.email ?? '',
          'lastTokenRefresh': DateTime.now().millisecondsSinceEpoch,
        };
        await SecureStorage.storeUserCredentials(credentials);
      }
    } catch (e) {
      debugPrint('Failed to store secure tokens: $e');
    }
  }
  
  /// Clear secure authentication tokens
  Future<void> _clearSecureTokens() async {
    try {
      await SecureStorage.removeAuthToken();
      await SecureStorage.removeRefreshToken();
      await SecureStorage.removeUserCredentials();
    } catch (e) {
      debugPrint('Failed to clear secure tokens: $e');
    }
  }
  
  /// Validate stored tokens
  Future<bool> _validateStoredTokens() async {
    try {
      final credentials = await SecureStorage.getUserCredentials();
      if (credentials == null) return false;
      
      final lastRefresh = credentials['lastTokenRefresh'] as int?;
      if (lastRefresh == null) return false;
      
      final lastRefreshTime = DateTime.fromMillisecondsSinceEpoch(lastRefresh);
      final now = DateTime.now();
      
      // Tokens are valid for 1 hour, refresh if older than 45 minutes
      const tokenValidityDuration = Duration(minutes: 45);
      
      return now.difference(lastRefreshTime) < tokenValidityDuration;
    } catch (e) {
      debugPrint('Failed to validate stored tokens: $e');
      return false;
    }
  }
}