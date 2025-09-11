import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import 'input_handler.dart';
import 'components/bird.dart';

/// Main game class that extends FlameGame for the Neon Pulse Flappy Bird
class NeonPulseGame extends FlameGame with HasCollisionDetection {
  late GameState gameState;
  
  // Game world boundaries
  static const double worldWidth = 800.0;
  static const double worldHeight = 600.0;
  
  // Camera system
  late CameraComponent gameCamera;
  
  // Input handling
  late InputHandler inputHandler;
  
  // Game components
  late Bird bird;
  
  @override
  Color backgroundColor() => const Color(0xFF0B0B1F);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Initialize game state
    gameState = GameState();
    
    // Set up game world boundaries and coordinate system
    _setupWorldBoundaries();
    
    // Initialize camera system
    _setupCamera();
    
    // Initialize input handling system
    _setupInputHandler();
    
    // Initialize game components
    _setupGameComponents();
    
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
    // Create and add bird component
    bird = Bird();
    bird.setWorldBounds(Vector2(worldWidth, worldHeight));
    add(bird);
    
    debugPrint('Game components initialized');
  }

  @override
  void update(double dt) {
    super.update(dt);
    
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
    
    // TODO: Update other game components
    // - Obstacle movement
    // - Collision detection with obstacles
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
  void handleTap() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    // Check for double tap
    if (currentTime - inputHandler.lastTapTime < InputHandler.doubleTapThreshold) {
      _handleDoubleTap();
    } else {
      _handleSingleTap();
    }
    
    inputHandler.lastTapTime = currentTime;
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
    }
  }

  /// Handle pulse mechanic activation
  void _handlePulseActivation() {
    // TODO: Implement pulse mechanic
    // This will be implemented in task 7 (pulse mechanic system)
    debugPrint('Pulse activation triggered');
  }



  /// Start a new game
  void startGame() {
    gameState.reset();
    
    // Reset camera position
    gameCamera.viewfinder.position = Vector2.zero();
    
    // Reset bird position and state
    bird.reset();
    
    // TODO: Reset other game components when they are implemented
    // - Clear obstacles
    // - Reset particle systems
    // - Start background music
    
    debugPrint('Game started - Status: ${gameState.status}');
  }

  /// Pause the game
  void pauseGame() {
    if (gameState.status == GameStatus.playing) {
      gameState.status = GameStatus.paused;
      gameState.isPaused = true;
      
      // TODO: Pause audio and animations when implemented
      // - Pause background music
      // - Pause particle animations
      // - Show pause overlay
      
      debugPrint('Game paused');
    }
  }

  /// Resume the game
  void resumeGame() {
    if (gameState.status == GameStatus.paused) {
      gameState.status = GameStatus.playing;
      gameState.isPaused = false;
      
      // TODO: Resume audio and animations when implemented
      // - Resume background music
      // - Resume particle animations
      // - Hide pause overlay
      
      debugPrint('Game resumed');
    }
  }

  /// End the current game
  void endGame() {
    gameState.endGame();
    
    // TODO: Handle game over state when components are implemented
    // - Stop audio
    // - Show game over screen
    // - Save high score
    // - Stop all animations
    
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
}