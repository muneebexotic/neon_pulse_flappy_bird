import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import 'input_handler.dart';
import 'components/bird.dart';
import 'managers/obstacle_manager.dart';
import 'managers/pulse_manager.dart';
import 'managers/audio_manager.dart';
import 'components/cyberpunk_background.dart';
import 'effects/neon_colors.dart';
import 'utils/performance_monitor.dart';

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
  late CyberpunkBackground background;
  
  // Audio system
  final AudioManager _audioManager = AudioManager();
  
  // Performance monitoring
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  
  @override
  Color backgroundColor() => NeonColors.deepSpace;

  /// Constructor - initialize gameState immediately for UI access
  NeonPulseGame() {
    gameState = GameState();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Initialize audio system
    await _audioManager.initialize();
    
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
    
    // Set up beat synchronization
    _setupBeatSynchronization();
    
    // Mark as loaded
    hasLoaded = true;
    
    debugPrint('Neon Pulse Game initialized - World: ${worldWidth}x$worldHeight');
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
    inputHandler = InputHandler();
    
    // Set up input callbacks
    inputHandler.onSingleTap = _handleSingleTap;
    inputHandler.onDoubleTap = _handleDoubleTap;
    inputHandler.onTapPosition = (position) {
      debugPrint('Tap at screen position: $position');
    };
    
    debugPrint('Input handler initialized');
  }

  /// Initialize game components
  void _setupGameComponents() {
    // Create and add cyberpunk background (render first)
    background = CyberpunkBackground();
    add(background);
    
    // Create and add bird component
    bird = Bird();
    bird.setWorldBounds(Vector2(worldWidth, worldHeight));
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
    
    debugPrint('Game components initialized');
  }

  /// Set up beat synchronization with obstacle spawning
  void _setupBeatSynchronization() {
    _audioManager.beatStream.listen((beatEvent) {
      if (gameState.status == GameStatus.playing && !gameState.isPaused) {
        // Synchronize obstacle spawning with beats
        obstacleManager.onBeatDetected(beatEvent.bpm);
      }
    });
    
    debugPrint('Beat synchronization initialized');
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Record frame for performance monitoring
    _performanceMonitor.recordFrame();
    
    // Adjust particle quality based on performance
    if (!_performanceMonitor.isPerformanceGood) {
      bird.particleSystem.setQuality(_performanceMonitor.performanceQuality * 0.5);
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
    
    // Update obstacle manager with current difficulty
    obstacleManager.updateDifficulty(gameState.gameSpeed, gameState.difficultyLevel);
    
    // Update pulse manager and bird pulse charge indicator
    final pulseChargeColor = pulseManager.getPulseChargeColor();
    final pulseChargeGlow = pulseManager.getPulseChargeGlow();
    bird.updatePulseCharge(pulseChargeColor, pulseChargeGlow);
    
    // Check collision detection with obstacles
    if (obstacleManager.checkCollisions(bird)) {
      // Bird hit an obstacle - end game
      bird.isAlive = false;
      _audioManager.playSoundEffect(SoundEffect.collision);
      endGame();
      return;
    }
    
    // Check if bird passed any obstacles (for scoring)
    final passedObstacles = obstacleManager.checkPassedObstacles(bird);
    for (final _ in passedObstacles) {
      gameState.incrementScore();
      _audioManager.playSoundEffect(SoundEffect.score);
      debugPrint('Score: ${gameState.currentScore}');
    }
    
    // TODO: Update other game components
    // - Particle effects
    // - Audio synchronization
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
  // This will be implemented when we integrate with the Flutter widget
  void handleTap([Offset? position]) {
    inputHandler.processTap(position);
  }

  /// Handle single tap input
  void _handleSingleTap() {
    switch (gameState.status) {
      case GameStatus.menu:
        // Start game on tap in menu
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
      bird.jump();
      _audioManager.playSoundEffect(SoundEffect.jump);
    }
  }

  /// Handle pulse mechanic activation
  void _handlePulseActivation() {
    if (pulseManager.tryActivatePulse()) {
      _audioManager.playSoundEffect(SoundEffect.pulse);
      debugPrint('Pulse activated successfully');
    } else {
      debugPrint('Pulse activation failed - still on cooldown');
    }
  }



  /// Start a new game
  void startGame() {
    gameState.reset();
    
    // Reset camera position
    gameCamera.viewfinder.position = Vector2.zero();
    
    // Reset bird position and state
    bird.reset();
    
    // Clear all obstacles
    obstacleManager.clearAllObstacles();
    
    // Reset pulse manager
    pulseManager.reset();
    
    // Reset background animation
    background.setGridAnimationSpeed(0.5);
    background.setColorShiftSpeed(0.3);
    
    // Start background music with beat synchronization
    _audioManager.playBackgroundMusic('cyberpunk_theme.mp3');
    
    debugPrint('Game started - Status: ${gameState.status}');
  }

  /// Pause the game
  void pauseGame() {
    if (gameState.status == GameStatus.playing) {
      gameState.status = GameStatus.paused;
      gameState.isPaused = true;
      
      // Pause background music
      _audioManager.stopBackgroundMusic();
      
      debugPrint('Game paused');
    }
  }

  /// Resume the game
  void resumeGame() {
    if (gameState.status == GameStatus.paused) {
      gameState.status = GameStatus.playing;
      gameState.isPaused = false;
      
      // Resume background music
      _audioManager.playBackgroundMusic('cyberpunk_theme.mp3');
      
      debugPrint('Game resumed');
    }
  }

  /// End the current game
  Future<void> endGame() async {
    await gameState.endGame();
    
    // Stop background music
    _audioManager.stopBackgroundMusic();
    
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
}