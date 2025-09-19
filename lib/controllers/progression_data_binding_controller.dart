import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/achievement.dart';
import '../models/bird_skin.dart';
import '../game/managers/achievement_manager.dart';
import 'progression_path_controller.dart';

/// Controller for managing real-time data binding and progress updates
/// for the achievements progression path
class ProgressionDataBindingController extends ChangeNotifier {
  final AchievementManager _achievementManager;
  final ProgressionPathController _pathController;
  
  // Stream controllers for reactive updates
  final StreamController<List<Achievement>> _achievementsStreamController = 
      StreamController<List<Achievement>>.broadcast();
  final StreamController<Achievement> _newUnlockStreamController = 
      StreamController<Achievement>.broadcast();
  final StreamController<BirdSkin> _skinUnlockStreamController = 
      StreamController<BirdSkin>.broadcast();
  
  // Current state
  List<Achievement> _currentAchievements = [];
  Set<String> _previouslyUnlockedIds = {};
  bool _isInitialized = false;
  Timer? _updateTimer;
  
  // Animation triggers
  final List<Achievement> _pendingUnlockAnimations = [];
  final List<BirdSkin> _pendingSkinUnlocks = [];
  
  ProgressionDataBindingController({
    required AchievementManager achievementManager,
    required ProgressionPathController pathController,
  }) : _achievementManager = achievementManager,
       _pathController = pathController {
    _setupAchievementManagerCallbacks();
  }

  /// Get stream of achievement updates
  Stream<List<Achievement>> get achievementsStream => _achievementsStreamController.stream;
  
  /// Get stream of newly unlocked achievements
  Stream<Achievement> get newUnlockStream => _newUnlockStreamController.stream;
  
  /// Get stream of newly unlocked skins
  Stream<BirdSkin> get skinUnlockStream => _skinUnlockStreamController.stream;
  
  /// Get current achievements
  List<Achievement> get currentAchievements => List.unmodifiable(_currentAchievements);
  
  /// Get pending unlock animations
  List<Achievement> get pendingUnlockAnimations => List.unmodifiable(_pendingUnlockAnimations);
  
  /// Get pending skin unlocks
  List<BirdSkin> get pendingSkinUnlocks => List.unmodifiable(_pendingSkinUnlocks);
  
  /// Check if controller is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the data binding controller
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize achievement manager if needed
      await _achievementManager.initialize();
      
      // Load initial achievement data
      await _loadInitialData();
      
      // Start periodic updates for real-time synchronization
      _startPeriodicUpdates();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing ProgressionDataBindingController: $e');
      rethrow;
    }
  }

  /// Setup callbacks for achievement manager events
  void _setupAchievementManagerCallbacks() {
    _achievementManager.onAchievementUnlocked = (achievement) {
      _handleAchievementUnlocked(achievement);
    };
    
    _achievementManager.onSkinUnlocked = (skin) {
      _handleSkinUnlocked(skin);
    };
  }

  /// Load initial achievement data
  Future<void> _loadInitialData() async {
    final achievements = _achievementManager.achievements;
    
    // Store previously unlocked achievement IDs
    _previouslyUnlockedIds = achievements
        .where((a) => a.isUnlocked)
        .map((a) => a.id)
        .toSet();
    
    // Update current achievements
    _currentAchievements = List.from(achievements);
    
    // Update path controller with initial data
    _updatePathController();
    
    // Emit initial data
    _achievementsStreamController.add(_currentAchievements);
  }

  /// Start periodic updates for real-time synchronization
  void _startPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _checkForUpdates();
    });
  }

  /// Check for achievement updates and handle changes
  void _checkForUpdates() {
    final latestAchievements = _achievementManager.achievements;
    
    // Check if achievements have changed
    if (_hasAchievementsChanged(latestAchievements)) {
      _handleAchievementUpdates(latestAchievements);
    }
  }

  /// Check if achievements have changed compared to current state
  bool _hasAchievementsChanged(List<Achievement> newAchievements) {
    if (newAchievements.length != _currentAchievements.length) {
      return true;
    }
    
    for (int i = 0; i < newAchievements.length; i++) {
      final newAchievement = newAchievements[i];
      final currentAchievement = _currentAchievements[i];
      
      if (newAchievement.id != currentAchievement.id ||
          newAchievement.isUnlocked != currentAchievement.isUnlocked ||
          newAchievement.currentProgress != currentAchievement.currentProgress) {
        return true;
      }
    }
    
    return false;
  }

  /// Handle achievement updates
  void _handleAchievementUpdates(List<Achievement> newAchievements) {
    final previousAchievements = Map.fromIterable(
      _currentAchievements,
      key: (a) => a.id,
      value: (a) => a,
    );
    
    // Update current achievements
    _currentAchievements = List.from(newAchievements);
    
    // Check for newly unlocked achievements
    for (final achievement in newAchievements) {
      final previousAchievement = previousAchievements[achievement.id];
      
      if (previousAchievement != null &&
          !previousAchievement.isUnlocked &&
          achievement.isUnlocked) {
        _handleNewlyUnlockedAchievement(achievement);
      }
    }
    
    // Update path controller
    _updatePathController();
    
    // Emit updated achievements
    _achievementsStreamController.add(_currentAchievements);
    
    // Notify listeners
    notifyListeners();
  }

  /// Handle newly unlocked achievement
  void _handleNewlyUnlockedAchievement(Achievement achievement) {
    if (!_previouslyUnlockedIds.contains(achievement.id)) {
      _previouslyUnlockedIds.add(achievement.id);
      _pendingUnlockAnimations.add(achievement);
      _newUnlockStreamController.add(achievement);
      
      debugPrint('New achievement unlocked: ${achievement.name}');
    }
  }

  /// Handle achievement unlocked callback from manager
  void _handleAchievementUnlocked(Achievement achievement) {
    // This is called directly by the achievement manager
    // We handle it in the periodic update check to ensure consistency
    debugPrint('Achievement unlock callback received: ${achievement.name}');
  }

  /// Handle skin unlocked callback from manager
  void _handleSkinUnlocked(BirdSkin skin) {
    _pendingSkinUnlocks.add(skin);
    _skinUnlockStreamController.add(skin);
    debugPrint('Skin unlocked: ${skin.name}');
  }

  /// Update path controller with current achievement data
  void _updatePathController() {
    _pathController.updatePathProgress(_currentAchievements);
  }

  /// Force refresh achievement data
  Future<void> refreshData() async {
    try {
      // Clear pending notifications from achievement manager
      _achievementManager.clearPendingNotifications();
      
      // Reload data
      await _loadInitialData();
      
      debugPrint('Achievement data refreshed');
    } catch (e) {
      debugPrint('Error refreshing achievement data: $e');
    }
  }

  /// Get achievement progress for a specific achievement
  double getAchievementProgress(String achievementId) {
    return _achievementManager.getAchievementProgress(achievementId);
  }

  /// Check if achievement is unlocked
  bool isAchievementUnlocked(String achievementId) {
    return _achievementManager.isAchievementUnlocked(achievementId);
  }

  /// Get next achievement to unlock
  Achievement? getNextAchievementToUnlock() {
    return _achievementManager.getNextAchievementToUnlock();
  }

  /// Get achievements by type
  List<Achievement> getAchievementsByType(AchievementType type) {
    return _currentAchievements.where((a) => a.type == type).toList();
  }

  /// Clear pending unlock animations (call after showing them)
  void clearPendingUnlockAnimations() {
    _pendingUnlockAnimations.clear();
    notifyListeners();
  }

  /// Clear pending skin unlocks (call after showing them)
  void clearPendingSkinUnlocks() {
    _pendingSkinUnlocks.clear();
    notifyListeners();
  }

  /// Update game statistics and trigger achievement checks
  Future<void> updateGameStatistics({
    int? score,
    int? gamesPlayed,
    int? pulseUsage,
    int? powerUpsCollected,
    int? survivalTime,
  }) async {
    try {
      await _achievementManager.updateGameStatistics(
        score: score,
        gamesPlayed: gamesPlayed,
        pulseUsage: pulseUsage,
        powerUpsCollected: powerUpsCollected,
        survivalTime: survivalTime,
      );
      
      // Force immediate update check after statistics update
      _checkForUpdates();
    } catch (e) {
      debugPrint('Error updating game statistics: $e');
    }
  }

  /// Get current game statistics
  Map<String, int> get gameStatistics => _achievementManager.gameStatistics;

  /// Share achievement
  Future<void> shareAchievement(Achievement achievement) async {
    await _achievementManager.shareAchievement(achievement);
  }

  /// Share high score
  Future<void> shareHighScore({
    required int score,
    String? customMessage,
  }) async {
    await _achievementManager.shareHighScore(
      score: score,
      customMessage: customMessage,
    );
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'currentAchievements': _currentAchievements.length,
      'unlockedAchievements': _currentAchievements.where((a) => a.isUnlocked).length,
      'pendingAnimations': _pendingUnlockAnimations.length,
      'pendingSkinUnlocks': _pendingSkinUnlocks.length,
      'isInitialized': _isInitialized,
      'hasActiveTimer': _updateTimer?.isActive ?? false,
    };
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _achievementsStreamController.close();
    _newUnlockStreamController.close();
    _skinUnlockStreamController.close();
    
    // Clear achievement manager callbacks
    _achievementManager.onAchievementUnlocked = null;
    _achievementManager.onSkinUnlocked = null;
    
    super.dispose();
  }
}