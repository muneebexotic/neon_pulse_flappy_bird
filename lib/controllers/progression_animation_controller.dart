import 'dart:async';
import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/bird_skin.dart';

/// Controller for managing achievement unlock animations and visual effects
class ProgressionAnimationController extends ChangeNotifier {
  // Animation controllers for different effects
  final Map<String, AnimationController> _nodeAnimationControllers = {};
  final Map<String, AnimationController> _unlockAnimationControllers = {};
  final Map<String, AnimationController> _progressAnimationControllers = {};
  
  // Animation states
  final Set<String> _animatingNodes = {};
  final Set<String> _celebratingUnlocks = {};
  final Queue<Achievement> _unlockQueue = Queue<Achievement>();
  final Queue<BirdSkin> _skinUnlockQueue = Queue<BirdSkin>();
  
  // Animation timing
  static const Duration _unlockAnimationDuration = Duration(milliseconds: 1500);
  static const Duration _progressAnimationDuration = Duration(milliseconds: 800);
  static const Duration _nodeGlowDuration = Duration(milliseconds: 2000);
  
  // Callbacks for animation events
  Function(Achievement)? onUnlockAnimationStart;
  Function(Achievement)? onUnlockAnimationComplete;
  Function(BirdSkin)? onSkinUnlockAnimationStart;
  Function(BirdSkin)? onSkinUnlockAnimationComplete;
  
  ProgressionAnimationController();

  /// Get animation controller for a specific node
  AnimationController? getNodeAnimationController(String achievementId) {
    return _nodeAnimationControllers[achievementId];
  }

  /// Get unlock animation controller for a specific achievement
  AnimationController? getUnlockAnimationController(String achievementId) {
    return _unlockAnimationControllers[achievementId];
  }

  /// Get progress animation controller for a specific achievement
  AnimationController? getProgressAnimationController(String achievementId) {
    return _progressAnimationControllers[achievementId];
  }

  /// Check if a node is currently animating
  bool isNodeAnimating(String achievementId) {
    return _animatingNodes.contains(achievementId);
  }

  /// Check if an unlock is currently being celebrated
  bool isCelebratingUnlock(String achievementId) {
    return _celebratingUnlocks.contains(achievementId);
  }

  /// Initialize animation controller for a node
  void initializeNodeAnimation(String achievementId, TickerProvider vsync) {
    if (_nodeAnimationControllers.containsKey(achievementId)) return;
    
    final controller = AnimationController(
      duration: _nodeGlowDuration,
      vsync: vsync,
    );
    
    _nodeAnimationControllers[achievementId] = controller;
  }

  /// Initialize unlock animation controller for an achievement
  void initializeUnlockAnimation(String achievementId, TickerProvider vsync) {
    if (_unlockAnimationControllers.containsKey(achievementId)) return;
    
    final controller = AnimationController(
      duration: _unlockAnimationDuration,
      vsync: vsync,
    );
    
    _unlockAnimationControllers[achievementId] = controller;
  }

  /// Initialize progress animation controller for an achievement
  void initializeProgressAnimation(String achievementId, TickerProvider vsync) {
    if (_progressAnimationControllers.containsKey(achievementId)) return;
    
    final controller = AnimationController(
      duration: _progressAnimationDuration,
      vsync: vsync,
    );
    
    _progressAnimationControllers[achievementId] = controller;
  }

  /// Trigger unlock animation for an achievement
  Future<void> triggerUnlockAnimation(Achievement achievement) async {
    if (_celebratingUnlocks.contains(achievement.id)) return;
    
    _celebratingUnlocks.add(achievement.id);
    _unlockQueue.add(achievement);
    
    onUnlockAnimationStart?.call(achievement);
    
    final controller = _unlockAnimationControllers[achievement.id];
    if (controller != null) {
      try {
        await controller.forward();
        await Future.delayed(const Duration(milliseconds: 500)); // Hold at end
        await controller.reverse();
      } catch (e) {
        debugPrint('Error in unlock animation for ${achievement.id}: $e');
      }
    }
    
    _celebratingUnlocks.remove(achievement.id);
    _unlockQueue.remove(achievement);
    
    onUnlockAnimationComplete?.call(achievement);
    notifyListeners();
  }

  /// Trigger skin unlock animation
  Future<void> triggerSkinUnlockAnimation(BirdSkin skin) async {
    _skinUnlockQueue.add(skin);
    
    onSkinUnlockAnimationStart?.call(skin);
    
    // Skin unlock animation is typically handled by the UI layer
    // This method provides coordination and callbacks
    
    await Future.delayed(const Duration(milliseconds: 2000)); // Animation duration
    
    _skinUnlockQueue.remove(skin);
    
    onSkinUnlockAnimationComplete?.call(skin);
    notifyListeners();
  }

  /// Animate progress update for an achievement
  Future<void> animateProgressUpdate(Achievement achievement, double fromProgress, double toProgress) async {
    if (_animatingNodes.contains(achievement.id)) return;
    
    _animatingNodes.add(achievement.id);
    
    final controller = _progressAnimationControllers[achievement.id];
    if (controller != null) {
      try {
        controller.reset();
        await controller.forward();
      } catch (e) {
        debugPrint('Error in progress animation for ${achievement.id}: $e');
      }
    }
    
    _animatingNodes.remove(achievement.id);
    notifyListeners();
  }

  /// Start node glow animation (for highlighting current progress)
  void startNodeGlow(String achievementId) {
    final controller = _nodeAnimationControllers[achievementId];
    if (controller != null && !controller.isAnimating) {
      controller.repeat(reverse: true);
    }
  }

  /// Stop node glow animation
  void stopNodeGlow(String achievementId) {
    final controller = _nodeAnimationControllers[achievementId];
    if (controller != null) {
      controller.stop();
      controller.reset();
    }
  }

  /// Start pulsing animation for in-progress achievements
  void startProgressPulse(String achievementId) {
    final controller = _nodeAnimationControllers[achievementId];
    if (controller != null && !controller.isAnimating) {
      controller.repeat(reverse: true);
    }
  }

  /// Stop pulsing animation
  void stopProgressPulse(String achievementId) {
    final controller = _nodeAnimationControllers[achievementId];
    if (controller != null) {
      controller.stop();
      controller.reset();
    }
  }

  /// Process queued unlock animations
  Future<void> processUnlockQueue() async {
    while (_unlockQueue.isNotEmpty) {
      final achievement = _unlockQueue.removeFirst();
      await triggerUnlockAnimation(achievement);
      
      // Small delay between animations to prevent overwhelming the user
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  /// Process queued skin unlock animations
  Future<void> processSkinUnlockQueue() async {
    while (_skinUnlockQueue.isNotEmpty) {
      final skin = _skinUnlockQueue.removeFirst();
      await triggerSkinUnlockAnimation(skin);
      
      // Small delay between animations
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Get unlock animation progress for a specific achievement
  double getUnlockAnimationProgress(String achievementId) {
    final controller = _unlockAnimationControllers[achievementId];
    return controller?.value ?? 0.0;
  }

  /// Get progress animation progress for a specific achievement
  double getProgressAnimationProgress(String achievementId) {
    final controller = _progressAnimationControllers[achievementId];
    return controller?.value ?? 0.0;
  }

  /// Get node glow animation progress for a specific achievement
  double getNodeGlowProgress(String achievementId) {
    final controller = _nodeAnimationControllers[achievementId];
    return controller?.value ?? 0.0;
  }

  /// Create unlock animation tween for UI components
  Animation<double> createUnlockScaleTween(String achievementId) {
    final controller = _unlockAnimationControllers[achievementId];
    if (controller == null) {
      return AlwaysStoppedAnimation(1.0);
    }
    
    return Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    ));
  }

  /// Create unlock animation opacity tween
  Animation<double> createUnlockOpacityTween(String achievementId) {
    final controller = _unlockAnimationControllers[achievementId];
    if (controller == null) {
      return AlwaysStoppedAnimation(1.0);
    }
    
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
  }

  /// Create progress animation tween
  Animation<double> createProgressTween(String achievementId, double fromProgress, double toProgress) {
    final controller = _progressAnimationControllers[achievementId];
    if (controller == null) {
      return AlwaysStoppedAnimation(toProgress);
    }
    
    return Tween<double>(
      begin: fromProgress,
      end: toProgress,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }

  /// Create node glow animation tween
  Animation<double> createNodeGlowTween(String achievementId) {
    final controller = _nodeAnimationControllers[achievementId];
    if (controller == null) {
      return AlwaysStoppedAnimation(0.0);
    }
    
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }

  /// Reset all animations for a specific achievement
  void resetAchievementAnimations(String achievementId) {
    _nodeAnimationControllers[achievementId]?.reset();
    _unlockAnimationControllers[achievementId]?.reset();
    _progressAnimationControllers[achievementId]?.reset();
    
    _animatingNodes.remove(achievementId);
    _celebratingUnlocks.remove(achievementId);
  }

  /// Reset all animations
  void resetAllAnimations() {
    for (final controller in _nodeAnimationControllers.values) {
      controller.reset();
    }
    for (final controller in _unlockAnimationControllers.values) {
      controller.reset();
    }
    for (final controller in _progressAnimationControllers.values) {
      controller.reset();
    }
    
    _animatingNodes.clear();
    _celebratingUnlocks.clear();
    _unlockQueue.clear();
    _skinUnlockQueue.clear();
  }

  /// Get animation statistics for debugging
  Map<String, dynamic> getAnimationStats() {
    return {
      'nodeControllers': _nodeAnimationControllers.length,
      'unlockControllers': _unlockAnimationControllers.length,
      'progressControllers': _progressAnimationControllers.length,
      'animatingNodes': _animatingNodes.length,
      'celebratingUnlocks': _celebratingUnlocks.length,
      'unlockQueue': _unlockQueue.length,
      'skinUnlockQueue': _skinUnlockQueue.length,
    };
  }

  /// Dispose of animation controller for a specific achievement
  void disposeAchievementAnimations(String achievementId) {
    _nodeAnimationControllers[achievementId]?.dispose();
    _unlockAnimationControllers[achievementId]?.dispose();
    _progressAnimationControllers[achievementId]?.dispose();
    
    _nodeAnimationControllers.remove(achievementId);
    _unlockAnimationControllers.remove(achievementId);
    _progressAnimationControllers.remove(achievementId);
    
    _animatingNodes.remove(achievementId);
    _celebratingUnlocks.remove(achievementId);
  }

  @override
  void dispose() {
    // Dispose all animation controllers
    for (final controller in _nodeAnimationControllers.values) {
      controller.dispose();
    }
    for (final controller in _unlockAnimationControllers.values) {
      controller.dispose();
    }
    for (final controller in _progressAnimationControllers.values) {
      controller.dispose();
    }
    
    _nodeAnimationControllers.clear();
    _unlockAnimationControllers.clear();
    _progressAnimationControllers.clear();
    
    _animatingNodes.clear();
    _celebratingUnlocks.clear();
    _unlockQueue.clear();
    _skinUnlockQueue.clear();
    
    super.dispose();
  }
}