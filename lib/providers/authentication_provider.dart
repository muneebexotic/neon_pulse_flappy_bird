import 'package:flutter/foundation.dart';
import '../managers/authentication_manager.dart';
import '../models/user.dart';

// Re-export enums for convenience
export '../managers/authentication_manager.dart' show AuthenticationState, AuthenticationError;

/// Provider wrapper for AuthenticationManager to integrate with Provider pattern
class AuthenticationProvider extends ChangeNotifier {
  final AuthenticationManager _authManager = AuthenticationManager();
  
  // Expose authentication manager properties
  AuthenticationState get state => _authManager.state;
  User? get currentUser => _authManager.currentUser;
  AuthenticationError? get lastError => _authManager.lastError;
  String? get errorMessage => _authManager.errorMessage;
  bool get isAuthenticated => _authManager.isAuthenticated;
  bool get isGuest => _authManager.isGuest;
  bool get isLoading => _authManager.isLoading;
  bool get hasError => _authManager.hasError;
  
  AuthenticationProvider() {
    // Listen to authentication manager changes
    _authManager.addListener(_onAuthStateChanged);
  }
  
  /// Initialize the authentication system
  Future<void> initialize() async {
    await _authManager.initialize();
  }
  
  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    return await _authManager.signInWithGoogle();
  }
  
  /// Sign in as guest
  Future<bool> signInAsGuest() async {
    return await _authManager.signInAsGuest();
  }
  
  /// Upgrade guest account to Google account
  Future<bool> upgradeGuestToGoogle() async {
    return await _authManager.upgradeGuestToGoogle();
  }
  
  /// Sign out
  Future<bool> signOut() async {
    return await _authManager.signOut();
  }
  
  /// Update user game statistics
  Future<void> updateUserStats(UserGameStats newStats) async {
    await _authManager.updateUserStats(newStats);
  }
  
  /// Refresh user profile from server
  Future<void> refreshUserProfile() async {
    await _authManager.refreshUserProfile();
  }
  
  /// Clear authentication error
  void clearError() {
    _authManager.clearError();
  }
  
  /// Get user display name with fallback
  String getUserDisplayName() {
    if (currentUser?.displayName?.isNotEmpty == true) {
      return currentUser!.displayName;
    }
    return isGuest ? 'Guest Player' : 'Player';
  }
  
  /// Get user avatar URL with fallback
  String? getUserAvatarUrl() {
    return currentUser?.photoURL;
  }
  
  /// Check if user can access premium features (authenticated users only)
  bool canAccessPremiumFeatures() {
    return isAuthenticated && !isGuest;
  }
  
  /// Get user's best score
  int getUserBestScore() {
    return currentUser?.gameStats.bestScore ?? 0;
  }
  
  /// Get user's total games played
  int getUserTotalGames() {
    return currentUser?.gameStats.totalGamesPlayed ?? 0;
  }
  
  /// Get user's average score
  double getUserAverageScore() {
    return currentUser?.gameStats.averageScore ?? 0.0;
  }
  
  /// Update game statistics after a game ends
  Future<void> recordGameResult(int score) async {
    if (currentUser == null) return;
    
    final currentStats = currentUser!.gameStats;
    final newTotalGames = currentStats.totalGamesPlayed + 1;
    final newTotalScore = currentStats.totalScore + score;
    final newBestScore = score > currentStats.bestScore ? score : currentStats.bestScore;
    final newAverageScore = newTotalScore / newTotalGames;
    
    final updatedStats = currentStats.copyWith(
      totalGamesPlayed: newTotalGames,
      bestScore: newBestScore,
      totalScore: newTotalScore,
      averageScore: newAverageScore,
      lastPlayed: DateTime.now(),
    );
    
    await updateUserStats(updatedStats);
  }
  
  /// Update achievement progress
  Future<void> updateAchievementProgress(String achievementId, int progress) async {
    if (currentUser == null) return;
    
    final currentStats = currentUser!.gameStats;
    final updatedProgress = Map<String, int>.from(currentStats.achievementProgress);
    updatedProgress[achievementId] = progress;
    
    final updatedStats = currentStats.copyWith(
      achievementProgress: updatedProgress,
    );
    
    await updateUserStats(updatedStats);
  }
  
  /// Get achievement progress for a specific achievement
  int getAchievementProgress(String achievementId) {
    return currentUser?.gameStats.achievementProgress[achievementId] ?? 0;
  }
  
  /// Check if user has completed an achievement
  bool hasCompletedAchievement(String achievementId, int requiredProgress) {
    return getAchievementProgress(achievementId) >= requiredProgress;
  }
  
  /// Get formatted error message for UI display
  String getFormattedErrorMessage() {
    if (!hasError || errorMessage == null) return '';
    
    switch (lastError) {
      case AuthenticationError.networkError:
        return 'Network error. Please check your connection and try again.';
      case AuthenticationError.signInCancelled:
        return 'Sign in was cancelled.';
      case AuthenticationError.signInFailed:
        return 'Sign in failed. Please try again.';
      case AuthenticationError.signOutFailed:
        return 'Sign out failed. Please try again.';
      case AuthenticationError.accountUpgradeFailed:
        return 'Failed to upgrade account. Please try again.';
      case AuthenticationError.tokenExpired:
        return 'Your session has expired. Please sign in again.';
      case AuthenticationError.unknown:
      default:
        return errorMessage ?? 'An unknown error occurred.';
    }
  }
  
  /// Private methods
  
  void _onAuthStateChanged() {
    notifyListeners();
  }
  
  @override
  void dispose() {
    _authManager.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}