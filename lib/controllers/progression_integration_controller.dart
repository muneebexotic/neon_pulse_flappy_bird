import 'dart:async';
import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/bird_skin.dart';
import '../game/managers/achievement_manager.dart';
import 'progression_path_controller.dart';
import 'progression_data_binding_controller.dart';
import 'progression_animation_controller.dart';

/// Main integration controller that coordinates data binding, animations,
/// and real-time updates for the achievements progression path
class ProgressionIntegrationController extends ChangeNotifier {
  final AchievementManager _achievementManager;
  final ProgressionPathController _pathController;
  late final ProgressionDataBindingController _dataBindingController;
  late final ProgressionAnimationController _animationController;
  
  // Stream subscriptions
  StreamSubscription<List<Achievement>>? _achievementsSubscription;
  StreamSubscription<Achievement>? _unlockSubscription;
  StreamSubscription<BirdSkin>? _skinUnlockSubscription;
  
  // State management
  bool _isInitialized = false;
  bool _isDisposed = false;
  TickerProvider? _tickerProvider;
  
  // Performance tracking
  int _updateCount = 0;
  DateTime? _lastUpdateTime;
  
  ProgressionIntegrationController({
    required AchievementManager achievementManager,
    required ProgressionPathController pathController,
  }) : _achievementManager = achievementManager,
       _pathController = pathController {
    _initializeControllers();
  }

  /// Initialize sub-controllers
  void _initializeControllers() {
    _dataBindingController = ProgressionDataBindingController(
      achievementManager: _achievementManager,
      pathController: _pathController,
    );
    
    _animationController = ProgressionAnimationController();
    
    _setupAnimationCallbacks();
  }

  /// Setup animation callbacks
  void _setupAnimationCallbacks() {
    _animationController.onUnlockAnimationStart = (achievement) {
      debugPrint('Starting unlock animation for: ${achievement.name}');
    };
    
    _animationController.onUnlockAnimationComplete = (achievement) {
      debugPrint('Completed unlock animation for: ${achievement.name}');
    };
    
    _animationController.onSkinUnlockAnimationStart = (skin) {
      debugPrint('Starting skin unlock animation for: ${skin.name}');
    };
    
    _animationController.onSkinUnlockAnimationComplete = (skin) {
      debugPrint('Completed skin unlock animation for: ${skin.name}');
    };
  }

  /// Get data binding controller
  ProgressionDataBindingController get dataBinding => _dataBindingController;
  
  /// Get animation controller
  ProgressionAnimationController get animation => _animationController;
  
  /// Get path controller
  ProgressionPathController get pathController => _pathController;
  
  /// Get achievement manager
  AchievementManager get achievementManager => _achievementManager;
  
  /// Check if controller is initialized
  bool get isInitialized => _isInitialized;
  
  /// Get current achievements
  List<Achievement> get currentAchievements => _dataBindingController.currentAchievements;

  /// Initialize the integration controller
  Future<void> initialize(TickerProvider tickerProvider) async {
    if (_isInitialized || _isDisposed) return;
    
    _tickerProvider = tickerProvider;
    
    try {
      // Initialize data binding controller
      await _dataBindingController.initialize();
      
      // Setup stream subscriptions for reactive updates
      _setupStreamSubscriptions();
      
      // Initialize animations for existing achievements
      _initializeExistingAnimations();
      
      _isInitialized = true;
      notifyListeners();
      
      debugPrint('ProgressionIntegrationController initialized successfully');
    } catch (e) {
      debugPrint('Error initializing ProgressionIntegrationController: $e');
      rethrow;
    }
  }

  /// Setup stream subscriptions for reactive updates
  void _setupStreamSubscriptions() {
    // Subscribe to achievement updates
    _achievementsSubscription = _dataBindingController.achievementsStream.listen(
      _handleAchievementUpdates,
      onError: (error) {
        debugPrint('Error in achievements stream: $error');
      },
    );
    
    // Subscribe to unlock events
    _unlockSubscription = _dataBindingController.newUnlockStream.listen(
      _handleNewUnlock,
      onError: (error) {
        debugPrint('Error in unlock stream: $error');
      },
    );
    
    // Subscribe to skin unlock events
    _skinUnlockSubscription = _dataBindingController.skinUnlockStream.listen(
      _handleSkinUnlock,
      onError: (error) {
        debugPrint('Error in skin unlock stream: $error');
      },
    );
  }

  /// Initialize animations for existing achievements
  void _initializeExistingAnimations() {
    if (_tickerProvider == null) return;
    
    for (final achievement in _dataBindingController.currentAchievements) {
      _initializeAchievementAnimations(achievement);
    }
  }

  /// Initialize animations for a specific achievement
  void _initializeAchievementAnimations(Achievement achievement) {
    if (_tickerProvider == null) return;
    
    _animationController.initializeNodeAnimation(achievement.id, _tickerProvider!);
    _animationController.initializeUnlockAnimation(achievement.id, _tickerProvider!);
    _animationController.initializeProgressAnimation(achievement.id, _tickerProvider!);
    
    // Start appropriate animations based on achievement state
    if (achievement.isUnlocked) {
      // Subtle glow for unlocked achievements
      _animationController.startNodeGlow(achievement.id);
    } else if (achievement.currentProgress > 0) {
      // Pulsing animation for in-progress achievements
      _animationController.startProgressPulse(achievement.id);
    }
  }

  /// Handle achievement updates from data binding
  void _handleAchievementUpdates(List<Achievement> achievements) {
    _updateCount++;
    _lastUpdateTime = DateTime.now();
    
    // Initialize animations for new achievements
    for (final achievement in achievements) {
      if (_animationController.getNodeAnimationController(achievement.id) == null) {
        _initializeAchievementAnimations(achievement);
      }
    }
    
    // Update animation states based on achievement progress
    _updateAnimationStates(achievements);
    
    notifyListeners();
  }

  /// Update animation states based on achievement progress
  void _updateAnimationStates(List<Achievement> achievements) {
    for (final achievement in achievements) {
      if (achievement.isUnlocked) {
        _animationController.stopProgressPulse(achievement.id);
        _animationController.startNodeGlow(achievement.id);
      } else if (achievement.currentProgress > 0) {
        _animationController.stopNodeGlow(achievement.id);
        _animationController.startProgressPulse(achievement.id);
      } else {
        _animationController.stopNodeGlow(achievement.id);
        _animationController.stopProgressPulse(achievement.id);
      }
    }
  }

  /// Handle new achievement unlock
  void _handleNewUnlock(Achievement achievement) {
    // Trigger unlock animation
    _animationController.triggerUnlockAnimation(achievement);
    
    // Update visual state
    _animationController.stopProgressPulse(achievement.id);
    _animationController.startNodeGlow(achievement.id);
    
    notifyListeners();
  }

  /// Handle skin unlock
  void _handleSkinUnlock(BirdSkin skin) {
    // Trigger skin unlock animation
    _animationController.triggerSkinUnlockAnimation(skin);
    
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
    await _dataBindingController.updateGameStatistics(
      score: score,
      gamesPlayed: gamesPlayed,
      pulseUsage: pulseUsage,
      powerUpsCollected: powerUpsCollected,
      survivalTime: survivalTime,
    );
  }

  /// Force refresh all data
  Future<void> refreshData() async {
    await _dataBindingController.refreshData();
  }

  /// Get achievement progress for a specific achievement
  double getAchievementProgress(String achievementId) {
    return _dataBindingController.getAchievementProgress(achievementId);
  }

  /// Check if achievement is unlocked
  bool isAchievementUnlocked(String achievementId) {
    return _dataBindingController.isAchievementUnlocked(achievementId);
  }

  /// Get next achievement to unlock
  Achievement? getNextAchievementToUnlock() {
    return _dataBindingController.getNextAchievementToUnlock();
  }

  /// Get achievements by type
  List<Achievement> getAchievementsByType(AchievementType type) {
    return _dataBindingController.getAchievementsByType(type);
  }

  /// Share achievement
  Future<void> shareAchievement(Achievement achievement) async {
    await _dataBindingController.shareAchievement(achievement);
  }

  /// Share high score
  Future<void> shareHighScore({
    required int score,
    String? customMessage,
  }) async {
    await _dataBindingController.shareHighScore(
      score: score,
      customMessage: customMessage,
    );
  }

  /// Clear pending animations
  void clearPendingAnimations() {
    _dataBindingController.clearPendingUnlockAnimations();
    _dataBindingController.clearPendingSkinUnlocks();
  }

  /// Process all queued animations
  Future<void> processQueuedAnimations() async {
    await _animationController.processUnlockQueue();
    await _animationController.processSkinUnlockQueue();
  }

  /// Get node animation controller for UI components
  AnimationController? getNodeAnimationController(String achievementId) {
    return _animationController.getNodeAnimationController(achievementId);
  }

  /// Get unlock animation controller for UI components
  AnimationController? getUnlockAnimationController(String achievementId) {
    return _animationController.getUnlockAnimationController(achievementId);
  }

  /// Get progress animation controller for UI components
  AnimationController? getProgressAnimationController(String achievementId) {
    return _animationController.getProgressAnimationController(achievementId);
  }

  /// Create animation tweens for UI components
  Animation<double> createUnlockScaleTween(String achievementId) {
    return _animationController.createUnlockScaleTween(achievementId);
  }

  Animation<double> createUnlockOpacityTween(String achievementId) {
    return _animationController.createUnlockOpacityTween(achievementId);
  }

  Animation<double> createProgressTween(String achievementId, double fromProgress, double toProgress) {
    return _animationController.createProgressTween(achievementId, fromProgress, toProgress);
  }

  Animation<double> createNodeGlowTween(String achievementId) {
    return _animationController.createNodeGlowTween(achievementId);
  }

  /// Check if node is currently animating
  bool isNodeAnimating(String achievementId) {
    return _animationController.isNodeAnimating(achievementId);
  }

  /// Check if unlock is being celebrated
  bool isCelebratingUnlock(String achievementId) {
    return _animationController.isCelebratingUnlock(achievementId);
  }

  /// Get current game statistics
  Map<String, int> get gameStatistics => _dataBindingController.gameStatistics;

  /// Get comprehensive performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final dataStats = _dataBindingController.getPerformanceStats();
    final animationStats = _animationController.getAnimationStats();
    final pathStats = _pathController.getStats();
    
    return {
      'integration': {
        'isInitialized': _isInitialized,
        'updateCount': _updateCount,
        'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
      },
      'dataBinding': dataStats,
      'animation': animationStats,
      'pathController': pathStats,
    };
  }

  /// Validate controller state for debugging
  bool validateState() {
    try {
      // Check if all required components are initialized
      if (!_isInitialized) {
        debugPrint('Integration controller not initialized');
        return false;
      }
      
      if (!_dataBindingController.isInitialized) {
        debugPrint('Data binding controller not initialized');
        return false;
      }
      
      // Check if stream subscriptions are active
      if (_achievementsSubscription == null || _unlockSubscription == null) {
        debugPrint('Stream subscriptions not properly set up');
        return false;
      }
      
      // Check if ticker provider is available
      if (_tickerProvider == null) {
        debugPrint('Ticker provider not set');
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error validating controller state: $e');
      return false;
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    
    // Cancel stream subscriptions
    _achievementsSubscription?.cancel();
    _unlockSubscription?.cancel();
    _skinUnlockSubscription?.cancel();
    
    // Dispose sub-controllers
    _dataBindingController.dispose();
    _animationController.dispose();
    
    super.dispose();
  }
}