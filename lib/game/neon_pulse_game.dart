import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import 'input_handler.dart';
import 'components/bird.dart';
import 'managers/obstacle_manager.dart';
import 'managers/pulse_manager.dart';
import 'managers/audio_manager.dart';
import 'managers/power_up_manager.dart';
import 'managers/customization_manager.dart';
import 'managers/achievement_manager.dart';
import 'managers/notification_manager.dart';
import 'managers/settings_manager.dart';
import 'managers/haptic_manager.dart';
import 'managers/accessibility_manager.dart';
import 'managers/adaptive_quality_manager.dart';
import 'components/cyberpunk_background.dart';
import 'effects/neon_colors.dart';
import 'utils/performance_monitor.dart';
import 'utils/object_pool.dart';
import 'utils/performance_test_suite.dart';

/// Main game class that extends FlameGame for the Neon Pulse Flappy Bird
class NeonPulseGame extends FlameGame with HasCollisionDetection {
  late GameState gameState;
  bool hasLoaded = false;
  
  // Game world boundaries
  static const double worldWidth = 800.0;
  static const double worldHeight = 600.0;
  
  // Camera system
  late CameraComponent gameCamera;
  
  // Input handling
  late InputHandler inputHandler;
  
  // Game components
  late Bird bird;
  late ObstacleManager obstacleManager;
  late PulseManager pulseManager;
  late PowerUpManager powerUpManager;
  late CyberpunkBackground background;
  
  // Audio system
  final AudioManager _audioManager = AudioManager();
  
  // Customization system
  final CustomizationManager _customizationManager = CustomizationManager();
  
  // Achievement system
  late final AchievementManager _achievementManager;
  
  // Settings system
  final SettingsManager _settingsManager = SettingsManager();
  
  // Performance monitoring and optimization
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final AdaptiveQualityManager _adaptiveQualityManager = AdaptiveQualityManager();
  final PoolManager _poolManager = PoolManager();
  final PerformanceTestSuite _performanceTestSuite = PerformanceTestSuite();
  
  // Real-time achievement tracking
  double _survivalTime = 0.0;
  double _lastAchievementUpdateTime = 0.0;
  static const double _achievementUpdateInterval = 1.0; // Update achievements every second
  
  @override
  Color backgroundColor() => NeonColors.deepSpace;

  /// Constructor - initialize gameState immediately for UI access
  NeonPulseGame() {
    gameState = GameState();
  }

  @override
  @override
Future<void> onLoad() async {
  super.onLoad();
  
  // Initialize performance monitoring first
  await _performanceMonitor.initialize();
  
  // Initialize object pooling system
  _poolManager.initialize();
  
  // Initialize adaptive quality management
  await _adaptiveQualityManager.initialize();
  
  // Initialize settings system
  await _settingsManager.initialize();
  
  // Initialize audio system with settings
  await _audioManager.initialize();
  
  // Initialize haptic manager
  await HapticManager().initialize();
  
  // Synchronize audio settings - AudioManager is the source of truth for audio
  // Update SettingsManager to match AudioManager's loaded values
  await _settingsManager.setMusicEnabled(_audioManager.isMusicEnabled);
  await _settingsManager.setSfxEnabled(_audioManager.isSfxEnabled);
  await _settingsManager.setMusicVolume(_audioManager.musicVolume);
  await _settingsManager.setSfxVolume(_audioManager.sfxVolume);
  
  // Synchronize haptic settings - HapticManager is the source of truth for haptic
  await _settingsManager.setHapticEnabled(HapticManager().hapticEnabled);
  await _settingsManager.setVibrationEnabled(HapticManager().vibrationEnabled);
  await _settingsManager.setHapticIntensity(HapticManager().hapticIntensity);
  await _settingsManager.setVibrationIntensity(HapticManager().vibrationIntensity);
  
  // Test audio system to diagnose any issues
  await _audioManager.testAudioSystem();
  
  // Initialize customization system
  await _customizationManager.initialize();
  
  // Initialize achievement system (depends on customization manager)
  _achievementManager = AchievementManager(_customizationManager, NotificationManager());
  await _achievementManager.initialize();
  
  // Load high score from local storage
  await gameState.loadHighScore();
  
  // Set up game world boundaries and coordinate system
  _setupWorldBoundaries();
  
  // Initialize camera system
  _setupCamera();
  
  // Initialize input handling system
  _setupInputHandler();
  
  // Initialize game components
  _setupGameComponents();
  
  
  // Set up performance optimization callbacks
  _setupPerformanceOptimization();
  
  // Start adaptive quality monitoring if enabled
  if (_settingsManager.autoQualityAdjustment) {
    _adaptiveQualityManager.startAdaptiveQuality();
  }
  
  // Mark as loaded
  hasLoaded = true;
  
  debugPrint('Neon Pulse Game initialized - World: ${worldWidth}x$worldHeight');
  debugPrint('Performance optimization systems initialized');
  
  // Auto-start the game after loading (fix for initial start from main menu)
  startGame();
}

  /// Set up performance optimization callbacks
  void _setupPerformanceOptimization() {
    // Register callbacks for adaptive quality changes
    _adaptiveQualityManager.onParticleQualityChanged((quality) {
      final particleCount = _getParticleCountForQuality(quality);
      bird.particleSystem.setMaxParticles(particleCount);
      debugPrint('Adaptive quality: Particle count adjusted to $particleCount (${quality.name})');
    });
    
    _adaptiveQualityManager.onGraphicsQualityChanged((quality) {
      _applyGraphicsQualityLevel(quality);
      debugPrint('Adaptive quality: Graphics quality adjusted to ${quality.name}');
    });
    
    _adaptiveQualityManager.onEffectsChanged((reduced) {
      _applyEffectsReduction(reduced);
      debugPrint('Adaptive quality: Effects ${reduced ? 'reduced' : 'restored'}');
    });
  }

  /// Get particle count for quality level
  int _getParticleCountForQuality(QualityLevel quality) {
    switch (quality) {
      case QualityLevel.low:
        return 50;
      case QualityLevel.medium:
        return 150;
      case QualityLevel.high:
        return 300;
      case QualityLevel.ultra:
        return 500;
    }
  }

  /// Apply graphics quality level
  void _applyGraphicsQualityLevel(QualityLevel quality) {
    switch (quality) {
      case QualityLevel.low:
        background.setGridAnimationSpeed(0.1);
        background.setColorShiftSpeed(0.05);
        break;
      case QualityLevel.medium:
        background.setGridAnimationSpeed(0.3);
        background.setColorShiftSpeed(0.15);
        break;
      case QualityLevel.high:
        background.setGridAnimationSpeed(0.5);
        background.setColorShiftSpeed(0.3);
        break;
      case QualityLevel.ultra:
        background.setGridAnimationSpeed(0.8);
        background.setColorShiftSpeed(0.5);
        break;
    }
  }

  /// Apply effects reduction
  void _applyEffectsReduction(bool reduced) {
    if (reduced) {
      // Reduce particle effects
      bird.particleSystem.setBatchRendering(true);
      bird.particleSystem.setQuality(0.5);
      
      // Reduce background effects
      background.setGridAnimationSpeed(background.getGridAnimationSpeed() * 0.5);
    } else {
      // Restore effects
      bird.particleSystem.setBatchRendering(false);
      bird.particleSystem.setQuality(1.0);
    }
  }

  /// Set up game world boundaries and coordinate system
  void _setupWorldBoundaries() {
    // Game world boundaries are defined by constants
    // The camera will handle scaling to fit different screen sizes
    debugPrint('World boundaries set: ${worldWidth}x$worldHeight');
  }

  /// Initialize camera system for proper viewport management
  void _setupCamera() {
    gameCamera = CameraComponent.withFixedResolution(
      width: worldWidth,
      height: worldHeight,
    );
    
    // Add camera to the game
    add(gameCamera);
    
    debugPrint('Camera system initialized');
  }

  /// Initialize input handling system
  void _setupInputHandler() {
    inputHandler = InputHandler(
      tapSensitivity: _settingsManager.tapSensitivity,
      doubleTapTiming: _settingsManager.doubleTapTiming,
    );
    
    // Set up input callbacks
    inputHandler.onSingleTap = _handleSingleTap;
    inputHandler.onDoubleTap = _handleDoubleTap;
    inputHandler.onTapPosition = (position) {
      debugPrint('Tap at screen position: $position');
    };
    
    debugPrint('Input handler initialized with sensitivity: ${_settingsManager.tapSensitivity}, double-tap timing: ${_settingsManager.doubleTapTiming}ms');
  }

  /// Initialize game components
  void _setupGameComponents() {
    // Create and add cyberpunk background (render first)
    background = CyberpunkBackground();
    add(background);
    
    // Create and add bird component
    bird = Bird();
    bird.setWorldBounds(Vector2(worldWidth, worldHeight));
    
    // Apply selected skin to bird
    bird.updateSkin(_customizationManager.selectedSkin);
    
    add(bird);
    
    // Create and add obstacle manager
    obstacleManager = ObstacleManager(
      worldWidth: worldWidth,
      worldHeight: worldHeight,
    );
    add(obstacleManager);
    
    // Create and add pulse manager
    pulseManager = PulseManager(
      bird: bird,
      obstacleManager: obstacleManager,
    );
    add(pulseManager);
    
    // Create and add power-up manager
    powerUpManager = PowerUpManager(
      worldWidth: worldWidth,
      worldHeight: worldHeight,
      bird: bird,
      obstacleManager: obstacleManager,
      gameState: gameState,
    );
    
    // Set up real-time achievement tracking callback
    powerUpManager.onPowerUpCollected = _updateRealTimePowerUpProgress;
    
    add(powerUpManager);
    
    debugPrint('Game components initialized');
  }


  @override
  void update(double dt) {
    super.update(dt);
    
    // Record frame for performance monitoring (if enabled)
    if (_settingsManager.performanceMonitorEnabled) {
      _performanceMonitor.recordFrame();
    }
    
    // Apply graphics and particle quality settings
    _applyQualitySettings();
    
    // Auto-adjust quality based on performance if enabled
    if (_settingsManager.autoQualityAdjustment && _settingsManager.performanceMonitorEnabled) {
      _autoAdjustQuality();
    }
    
    // Update game state and components based on current status
    switch (gameState.status) {
      case GameStatus.playing:
        if (!gameState.isPaused) {
          _updateGameplay(dt);
        }
        break;
      case GameStatus.menu:
        _updateMenu(dt);
        break;
      case GameStatus.gameOver:
        _updateGameOver(dt);
        break;
      case GameStatus.paused:
        // Game is paused, minimal updates only
        break;
    }
  }

  /// Update gameplay logic when game is active
  void _updateGameplay(double dt) {
    // Check if bird is still alive
    if (!bird.isAlive) {
      endGame();
      return;
    }
    
    // Update survival time for real-time achievement tracking
    _survivalTime += dt;
    
    // Update power-up effects in game state
    gameState.updatePowerUpEffects(
      newScoreMultiplier: powerUpManager.scoreMultiplier,
      newIsInvulnerable: powerUpManager.isBirdInvulnerable,
      newGameSpeedMultiplier: powerUpManager.gameSpeedMultiplier,
    );
    
    // Update obstacle manager with current difficulty and speed modifiers
    final baseDifficultyMultiplier = _settingsManager.difficultyLevel.speedMultiplier;
    final effectiveGameSpeed = gameState.gameSpeed * gameState.gameSpeedMultiplier * baseDifficultyMultiplier;
    obstacleManager.updateDifficulty(effectiveGameSpeed, gameState.difficultyLevel, _settingsManager.difficultyLevel);
    
    // Update pulse manager and bird pulse charge indicator
    final pulseChargeColor = pulseManager.getPulseChargeColor();
    final pulseChargeGlow = pulseManager.getPulseChargeGlow();
    bird.updatePulseCharge(pulseChargeColor, pulseChargeGlow);
    
    // Update bird power-up effects
    bird.updatePowerUpEffects(gameState.isInvulnerable);
    
    // Check collision detection with obstacles (unless invulnerable)
    if (!gameState.isInvulnerable && obstacleManager.checkCollisions(bird)) {
      // Bird hit an obstacle - end game
      bird.isAlive = false;
      _audioManager.playSoundEffect(SoundEffect.collision);
      
      // Add haptic feedback for collision
      HapticManager().heavyImpact();
      HapticManager().collisionVibration();
      
      // Add accessibility sound feedback
      AccessibilityManager().playSoundFeedback(SoundFeedbackType.dangerZone);
      
      endGame();
      return;
    }
    
    // Check if bird passed any obstacles (for scoring)
    final passedObstacles = obstacleManager.checkPassedObstacles(bird);
    for (final _ in passedObstacles) {
      gameState.incrementScore();
      _audioManager.playSoundEffect(SoundEffect.score);
      
      // Add haptic feedback for scoring
      HapticManager().lightImpact();
      
      // Add accessibility sound feedback
      AccessibilityManager().playSoundFeedback(SoundFeedbackType.scoreIncrement);
      
      // Check for score milestones (every 10 points)
      if (gameState.currentScore % 10 == 0) {
        HapticManager().scoreMilestoneVibration();
      }
      
      debugPrint('Score: ${gameState.currentScore} (multiplier: ${gameState.scoreMultiplier}x)');
      
      // Check for newly unlocked skins
      _checkSkinUnlocks();
      
      // Update real-time score progress for achievements
      _updateRealTimeScoreProgress();
    }
    
    // Update real-time achievement progress periodically
    _lastAchievementUpdateTime += dt;
    if (_lastAchievementUpdateTime >= _achievementUpdateInterval) {
      _updateRealTimeAchievementProgress();
      _lastAchievementUpdateTime = 0.0;
    }
  }

  /// Update menu state
  void _updateMenu(double dt) {
    // TODO: Update menu animations and effects
  }

  /// Update game over state
  void _updateGameOver(double dt) {
    // TODO: Update game over screen effects
  }

  // Input handling system for tap detection
  void handleTap([Offset? position]) {
    inputHandler.processTap(position);
  }

  /// Handle single tap input
  void _handleSingleTap() {
    print('NeonPulseGame: Single tap detected, current status: ${gameState.status}');
    
    switch (gameState.status) {
      case GameStatus.menu:
        // Start game on tap in menu
        print('NeonPulseGame: Starting game from menu...');
        startGame();
        break;
      case GameStatus.playing:
        if (!gameState.isPaused) {
          // Bird jump on tap during gameplay
          handleBirdJump();
        }
        break;
      case GameStatus.gameOver:
        // Restart game on tap in game over screen
        print('NeonPulseGame: Restarting game from game over...');
        startGame();
        break;
      case GameStatus.paused:
        // Resume game on tap when paused
        resumeGame();
        break;
    }
    
    debugPrint('Single tap processed - Game Status: ${gameState.status}');
  }

  /// Handle double tap input for pulse mechanic
  void _handleDoubleTap() {
    if (gameState.status == GameStatus.playing && !gameState.isPaused) {
      _handlePulseActivation();
    }
    
    debugPrint('Double tap processed - Game Status: ${gameState.status}');
  }

  /// Handle bird jump action
  void handleBirdJump() {
    if (bird.isAlive) {
      print('NeonPulseGame: Bird jumping...');
      bird.jump();
      print('NeonPulseGame: Playing jump sound effect...');
      _audioManager.playSoundEffect(SoundEffect.jump);
      
      // Add haptic feedback for bird jump
      HapticManager().lightImpact();
    }
  }

  /// Handle pulse mechanic activation
  void _handlePulseActivation() {
    if (pulseManager.tryActivatePulse()) {
      _audioManager.playSoundEffect(SoundEffect.pulse);
      
      // Update real-time pulse usage progress for achievements
      _updateRealTimePulseProgress();
      
      debugPrint('Pulse activated successfully');
    } else {
      debugPrint('Pulse activation failed - still on cooldown');
    }
  }

  /// Start a new game
  void startGame() {
    print('NeonPulseGame: Starting new game...');
    
    gameState.reset();
    print('NeonPulseGame: Game state reset, status: ${gameState.status}');
    
    // Reset camera position
    gameCamera.viewfinder.position = Vector2.zero();
    
    // Reset bird position and state
    bird.reset();
    
    // Clear all obstacles
    obstacleManager.clearAllObstacles();
    
    // Reset pulse manager
    pulseManager.reset();
    
    // Clear all power-ups and effects
    powerUpManager.clearAll();
    
    // Reset background animation
    background.setGridAnimationSpeed(0.5);
    background.setColorShiftSpeed(0.3);
    
    // Reset real-time achievement tracking
    _survivalTime = 0.0;
    _lastAchievementUpdateTime = 0.0;
    
    debugPrint('Game started - Status: ${gameState.status}');
  }

  /// Pause the game
  void pauseGame() {
    if (gameState.canPause()) {
      gameState.pauseGame();
      
      // Don't stop background music when pausing - keep it playing
      // This provides a better user experience
      
      debugPrint('Game paused');
    }
  }

  /// Resume the game
  void resumeGame() {
    if (gameState.canResume()) {
      gameState.resumeGame();
      
      
      debugPrint('Game resumed');
    }
  }

  /// End the current game
  Future<void> endGame() async {
    await gameState.endGame();
    
    // Update statistics and check achievements
    await _updateGameStatistics();
    
    // Don't stop background music when game ends - keep it playing in the background
    // Background music should continue for a seamless experience
    
    debugPrint('Game ended - Score: ${gameState.currentScore}, High Score: ${gameState.highScore}');
  }

  /// Get current game world boundaries
  Vector2 get worldBounds => Vector2(worldWidth, worldHeight);
  
  /// Check if a position is within world boundaries
  bool isWithinWorldBounds(Vector2 position) {
    return position.x >= 0 && 
           position.x <= worldWidth && 
           position.y >= 0 && 
           position.y <= worldHeight;
  }

  /// Convert screen coordinates to world coordinates
  Vector2 screenToWorld(Vector2 screenPosition) {
    return gameCamera.viewfinder.globalToLocal(screenPosition);
  }

  /// Convert world coordinates to screen coordinates
  Vector2 worldToScreen(Vector2 worldPosition) {
    return gameCamera.viewfinder.localToGlobal(worldPosition);
  }

  /// Get performance statistics
  Map<String, dynamic> get performanceStats => _performanceMonitor.getStats();
  
  /// Get audio manager for settings access
  AudioManager get audioManager => _audioManager;
  
  /// Get customization manager for UI access
  CustomizationManager get customizationManager => _customizationManager;
  
  /// Get achievement manager for UI access
  AchievementManager get achievementManager => _achievementManager;
  
  /// Get settings manager for UI access
  SettingsManager get settingsManager => _settingsManager;
  
  /// Get performance monitor for UI access
  PerformanceMonitor get performanceMonitor => _performanceMonitor;
  
  /// Get adaptive quality manager for UI access
  AdaptiveQualityManager get adaptiveQualityManager => _adaptiveQualityManager;
  
  /// Get pool manager for UI access
  PoolManager get poolManager => _poolManager;
  
  /// Get performance test suite for UI access
  PerformanceTestSuite get performanceTestSuite => _performanceTestSuite;
  
  /// Update real-time score progress for achievements
  Future<void> _updateRealTimeScoreProgress() async {
    await _achievementManager.updateScoreProgress(gameState.currentScore);
  }
  
  /// Update real-time pulse usage progress for achievements
  Future<void> _updateRealTimePulseProgress() async {
    final totalPulseUsage = pulseManager.getTotalPulseUsage();
    await _achievementManager.updatePulseUsage(totalPulseUsage);
  }
  
  /// Update real-time power-up collection progress for achievements
  Future<void> _updateRealTimePowerUpProgress() async {
    final totalPowerUpsCollected = powerUpManager.getTotalPowerUpsCollected();
    await _achievementManager.updatePowerUpCollection(totalPowerUpsCollected);
  }
  
  /// Update real-time survival time progress for achievements
  Future<void> _updateRealTimeSurvivalProgress() async {
    final survivalTimeSeconds = _survivalTime.floor();
    await _achievementManager.updateSurvivalTime(survivalTimeSeconds);
  }
  
  /// Update all real-time achievement progress (called periodically)
  Future<void> _updateRealTimeAchievementProgress() async {
    await _updateRealTimeSurvivalProgress();
    await _updateRealTimePowerUpProgress();
  }

  /// Check for newly unlocked skins based on current score
  Future<void> _checkSkinUnlocks() async {
    // Use AchievementManager to handle skin unlocks with notifications
    await _achievementManager.updateGameStatistics(score: gameState.currentScore);
  }
  
  /// Update game statistics and achievements at end of game
  Future<void> _updateGameStatistics() async {
    // Count pulse usage during this game (would need to track this)
    final pulseUsageThisGame = pulseManager.getTotalPulseUsage();
    
    // Count power-ups collected during this game
    final powerUpsThisGame = powerUpManager.getTotalPowerUpsCollected();
    
    // Calculate survival time (would need to track this)
    final survivalTime = _calculateSurvivalTime();
    
    // Update statistics and check achievements through AchievementManager
    await _achievementManager.updateGameStatistics(
      score: gameState.currentScore,
      gamesPlayed: 1,
      pulseUsage: pulseUsageThisGame,
      powerUpsCollected: powerUpsThisGame,
      survivalTime: survivalTime,
    );
  }
  
  /// Calculate survival time for this game session
  int _calculateSurvivalTime() {
    // This would need to be tracked during gameplay
    // For now, estimate based on score (rough approximation)
    return gameState.currentScore * 2; // 2 seconds per point
  }
  
  /// Update bird skin (called from UI)
  Future<void> updateBirdSkin(String skinId) async {
    final success = await _customizationManager.selectSkin(skinId);
    if (success) {
      bird.updateSkin(_customizationManager.selectedSkin);
      debugPrint('Bird skin updated to: ${_customizationManager.selectedSkin.name}');
    }
  }
  
  /// Apply graphics and particle quality settings
  void _applyQualitySettings() {
    // Apply particle quality settings
    final particleQuality = _settingsManager.particleQuality;
    bird.particleSystem.setMaxParticles(particleQuality.maxParticles);
    
    // Apply graphics quality settings to background
    switch (_settingsManager.graphicsQuality) {
      case GraphicsQuality.low:
        background.setGridAnimationSpeed(0.2);
        background.setColorShiftSpeed(0.1);
        break;
      case GraphicsQuality.medium:
        background.setGridAnimationSpeed(0.4);
        background.setColorShiftSpeed(0.2);
        break;
      case GraphicsQuality.high:
        background.setGridAnimationSpeed(0.6);
        background.setColorShiftSpeed(0.4);
        break;
      case GraphicsQuality.ultra:
        background.setGridAnimationSpeed(0.8);
        background.setColorShiftSpeed(0.6);
        break;
      case GraphicsQuality.auto:
        // Auto quality is handled by _autoAdjustQuality
        break;
    }
  }
  
  /// Auto-adjust quality based on performance
  void _autoAdjustQuality() {
    if (!_performanceMonitor.isPerformanceGood) {
      final performanceScore = _performanceMonitor.performanceQuality;
      
      // Auto-adjust graphics quality if set to auto
      if (_settingsManager.graphicsQuality == GraphicsQuality.auto) {
        final recommendedGraphics = _settingsManager.getRecommendedGraphicsQuality(performanceScore);
        _applyGraphicsQuality(recommendedGraphics);
      }
      
      // Auto-adjust particle quality
      final recommendedParticles = _settingsManager.getRecommendedParticleQuality(performanceScore);
      bird.particleSystem.setMaxParticles(recommendedParticles.maxParticles);
    }
  }
  
  /// Apply specific graphics quality level
  void _applyGraphicsQuality(GraphicsQuality quality) {
    switch (quality) {
      case GraphicsQuality.low:
        background.setGridAnimationSpeed(0.2);
        background.setColorShiftSpeed(0.1);
        break;
      case GraphicsQuality.medium:
        background.setGridAnimationSpeed(0.4);
        background.setColorShiftSpeed(0.2);
        break;
      case GraphicsQuality.high:
        background.setGridAnimationSpeed(0.6);
        background.setColorShiftSpeed(0.4);
        break;
      case GraphicsQuality.ultra:
        background.setGridAnimationSpeed(0.8);
        background.setColorShiftSpeed(0.6);
        break;
      case GraphicsQuality.auto:
        // Should not reach here in auto-adjustment
        break;
    }
  }
  
  /// Update settings from UI (called when settings change)
  Future<void> updateSettings() async {
    // Update audio settings
    await _audioManager.setMusicVolume(_settingsManager.musicVolume);
    await _audioManager.setSfxVolume(_settingsManager.sfxVolume);
    
    // Update input handler settings
    inputHandler.updateSettings(
      tapSensitivity: _settingsManager.tapSensitivity,
      doubleTapTiming: _settingsManager.doubleTapTiming,
    );
    
    // Apply quality settings immediately
    _applyQualitySettings();
    
    // Update adaptive quality system
    if (_settingsManager.autoQualityAdjustment) {
      _adaptiveQualityManager.startAdaptiveQuality();
    } else {
      _adaptiveQualityManager.stopAdaptiveQuality();
    }
    
    debugPrint('Game settings updated');
  }

  /// Run performance benchmark
  Future<PerformanceTestResults> runPerformanceBenchmark() async {
    return await _performanceTestSuite.runFullTestSuite();
  }

  /// Get comprehensive performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'monitor': _performanceMonitor.getStats(),
      'adaptiveQuality': _adaptiveQualityManager.getQualityStats(),
      'objectPools': _poolManager.getAllStats(),
      'particleSystem': bird.particleSystem.getStats(),
    };
  }

  /// Force performance optimization cleanup
  void forcePerformanceCleanup() {
    // Clear all object pools
    _poolManager.clearAll();
    
    // Force particle system cleanup
    bird.particleSystem.forceCleanup();
    
    // Reset performance monitoring
    _performanceMonitor.reset();
    
    debugPrint('Performance cleanup completed');
  }
}