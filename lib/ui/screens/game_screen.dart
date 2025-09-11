import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../../game/neon_pulse_game.dart';
import '../../models/game_state.dart';
import '../components/game_hud.dart';
import 'game_over_screen.dart';
import 'settings_screen.dart';

/// Game screen that displays the actual game
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late NeonPulseGame game;
  late AnimationController _gameStateController;
  DateTime? _lastTapTime;
  static const Duration _doubleTapThreshold = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    game = NeonPulseGame();
    
    // Animation controller for smooth transitions
    _gameStateController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Start checking game state periodically (much less frequently)
    _startGameStateMonitoring();
  }

  @override
  void dispose() {
    _gameStateController.dispose();
    super.dispose();
  }

  void _startGameStateMonitoring() {
    // Check game state every 100ms instead of every frame for better performance
    _gameStateController.repeat(period: const Duration(milliseconds: 100));
    _gameStateController.addListener(() {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild to update the UI based on game state
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game widget with improved tap handling
          GestureDetector(
            onTap: () {
              _handleTap();
            },
            child: GameWidget<NeonPulseGame>.controlled(
              gameFactory: () => game,
            ),
          ),
          
          // Game HUD - only show during gameplay
          if (game.hasLoaded && game.gameState.status == GameStatus.playing)
            GameHUD(
              currentScore: game.gameState.currentScore,
              highScore: game.gameState.highScore,
              isPaused: game.gameState.isPaused,
              pulseStatus: game.pulseManager.getPulseStatusText(),
              isPulseReady: game.pulseManager.pulseReady,
              performanceStats: game.performanceStats,
              showDebugInfo: true, // Enable for debugging performance issues
              onPause: () {
                if (game.gameState.isPaused) {
                  game.resumeGame();
                } else {
                  game.pauseGame();
                }
              },
              onSettings: () {
                // Pause the game before opening settings
                if (!game.gameState.isPaused) {
                  game.pauseGame();
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      audioManager: game.audioManager,
                    ),
                  ),
                );
              },
            ),
          
          // Game Over Screen - only show when game is over
          if (game.hasLoaded && game.gameState.status == GameStatus.gameOver)
            GameOverScreen(
              finalScore: game.gameState.currentScore,
              highScore: game.gameState.highScore,
              onRestart: () {
                game.startGame();
              },
              onMainMenu: () {
                Navigator.of(context).pop();
              },
            ),
          
          // Debug info overlay (can be removed later)
          if (game.hasLoaded && game.gameState.status == GameStatus.playing)
            Positioned(
              bottom: 100,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tap to Jump',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Double-tap for Pulse',
                      style: TextStyle(
                        color: Colors.cyan.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Back button - only show when not playing
          if (game.hasLoaded && game.gameState.status != GameStatus.playing)
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: Colors.cyan,
                  size: 30,
                ),
              ),
            ),
          
          // Loading indicator while game is loading
          if (!game.hasLoaded)
            Container(
              color: const Color(0xFF0B0B1F),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.cyan,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Game...',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Handle tap with immediate response and double-tap detection
  void _handleTap() {
    final now = DateTime.now();
    
    // Always handle single tap immediately for responsive gameplay
    game.handleTap();
    
    // Check for double tap
    if (_lastTapTime != null && 
        now.difference(_lastTapTime!) < _doubleTapThreshold) {
      // Double tap detected - activate pulse
      if (game.gameState.status == GameStatus.playing && !game.gameState.isPaused) {
        game.pulseManager.tryActivatePulse();
        debugPrint('Double tap detected - pulse activated');
      }
    }
    
    _lastTapTime = now;
  }
}