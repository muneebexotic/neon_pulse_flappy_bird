import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import '../../game/neon_pulse_game.dart';
import '../../models/game_state.dart';
import '../../models/achievement.dart';
import '../../models/bird_skin.dart';
import '../../game/managers/achievement_manager.dart';
import '../../game/managers/customization_manager.dart';
import '../components/game_hud.dart';
import '../components/pause_overlay.dart';
import '../components/achievement_notification.dart';
import 'game_over_screen.dart';
import 'settings_screen.dart';
import 'customization_screen.dart';

/// Game screen that displays the actual game
class GameScreen extends StatefulWidget {
  final AchievementManager? achievementManager;
  final CustomizationManager? customizationManager;

  const GameScreen({
    super.key,
    this.achievementManager,
    this.customizationManager,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late NeonPulseGame game;
  late AnimationController _gameStateController;
  DateTime? _lastTapTime;
  static const Duration _doubleTapThreshold = Duration(milliseconds: 250);
  bool _wasPlayingBeforeBackground = false;
  
  // Achievement tracking
  late AchievementManager _achievementManager;
  late CustomizationManager _customizationManager;
  List<Achievement> _pendingAchievements = [];
  List<BirdSkin> _pendingSkins = [];
  
  // Screenshot functionality
  final GlobalKey _screenshotKey = GlobalKey();
  
  // Game statistics tracking
  int _gameStartTime = 0;
  int _pulseUsageCount = 0;
  int _powerUpsCollectedCount = 0;

  @override
  void initState() {
    super.initState();
    
    // Initialize managers
    _customizationManager = widget.customizationManager ?? CustomizationManager();
    _achievementManager = widget.achievementManager ?? AchievementManager(_customizationManager);
    
    // Initialize game
    game = NeonPulseGame();
    
    // Set up achievement callbacks
    _achievementManager.onAchievementUnlocked = (achievement) {
      setState(() {
        _pendingAchievements.add(achievement);
      });
    };
    
    _achievementManager.onSkinUnlocked = (skin) {
      setState(() {
        _pendingSkins.add(skin);
      });
    };
    
    // Add observer for app lifecycle events
    WidgetsBinding.instance.addObserver(this);
    
    // Animation controller for smooth transitions
    _gameStateController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Start checking game state periodically (much less frequently)
    _startGameStateMonitoring();
    
    // Initialize achievement tracking
    _initializeAchievementTracking();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gameStateController.dispose();
    super.dispose();
  }

  Future<void> _initializeAchievementTracking() async {
    if (!_customizationManager.availableSkins.isNotEmpty) {
      await _customizationManager.initialize();
    }
    await _achievementManager.initialize();
  }

  void _trackGameStart() {
    _gameStartTime = DateTime.now().millisecondsSinceEpoch;
    _pulseUsageCount = 0;
    _powerUpsCollectedCount = 0;
  }

  void _trackGameEnd() {
    if (_gameStartTime > 0) {
      final survivalTime = (DateTime.now().millisecondsSinceEpoch - _gameStartTime) ~/ 1000;
      
      // Update achievement statistics
      _achievementManager.updateGameStatistics(
        score: game.gameState.currentScore,
        gamesPlayed: 1,
        pulseUsage: _pulseUsageCount,
        powerUpsCollected: _powerUpsCollectedCount,
        survivalTime: survivalTime,
      );
    }
  }

  void _trackPulseUsage() {
    _pulseUsageCount++;
  }

  void _trackPowerUpCollection() {
    _powerUpsCollectedCount++;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Auto-pause when app goes to background
        if (game.hasLoaded && game.gameState.status == GameStatus.playing && !game.gameState.isPaused) {
          _wasPlayingBeforeBackground = true;
          game.pauseGame();
        }
        break;
      case AppLifecycleState.resumed:
        // Don't auto-resume - let user manually resume
        _wasPlayingBeforeBackground = false;
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        break;
      case AppLifecycleState.hidden:
        // App is hidden but still running
        break;
    }
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
          // Game widget with screenshot capability
          RepaintBoundary(
            key: _screenshotKey,
            child: GestureDetector(
              onTap: () {
                _handleTap();
              },
              child: GameWidget<NeonPulseGame>.controlled(
                gameFactory: () => game,
              ),
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
              activePowerUps: game.powerUpManager.allActiveEffects,
              scoreMultiplier: game.gameState.scoreMultiplier,
              onPause: () {
                if (game.gameState.canResume()) {
                  game.resumeGame();
                } else if (game.gameState.canPause()) {
                  game.pauseGame();
                }
              },
              onSettings: () {
                // Pause the game first, then show pause overlay which will handle settings
                if (game.gameState.canPause()) {
                  game.pauseGame();
                }
              },
            ),
          
          // Pause Overlay - show when game is paused
          if (game.hasLoaded && game.gameState.status == GameStatus.paused)
            PauseOverlay(
              isVisible: game.gameState.isPaused,
              onResume: () {
                game.resumeGame();
              },
              onRestart: () {
                game.startGame();
              },
              onSettings: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      audioManager: game.audioManager,
                      settingsManager: game.settingsManager,
                      performanceMonitor: game.performanceMonitor,
                      onSettingsChanged: () {
                        // Update game settings when they change
                        game.updateSettings();
                      },
                    ),
                  ),
                );
              },
              onMainMenu: () {
                Navigator.of(context).pop();
              },
            ),

          // Game Over Screen - only show when game is over
          if (game.hasLoaded && game.gameState.status == GameStatus.gameOver)
            GameOverScreen(
              finalScore: game.gameState.currentScore,
              highScore: game.gameState.highScore,
              achievementManager: _achievementManager,
              screenshotKey: _screenshotKey,
              onRestart: () {
                _trackGameStart();
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
          
          // Achievement notifications overlay
          if (_pendingAchievements.isNotEmpty || _pendingSkins.isNotEmpty)
            AchievementNotificationOverlay(
              achievements: _pendingAchievements,
              skins: _pendingSkins,
              onAllDismissed: () {
                setState(() {
                  _pendingAchievements.clear();
                  _pendingSkins.clear();
                });
                _achievementManager.clearPendingNotifications();
              },
              onSkinTapped: (skin) {
                // Navigate to customization screen to equip the skin
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CustomizationScreen(
                      customizationManager: _customizationManager,
                    ),
                  ),
                );
              },
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
    
    // Don't handle taps when paused (pause overlay will handle its own taps)
    if (game.gameState.status == GameStatus.paused) {
      return;
    }
    
    // Track game start on first tap
    if (game.gameState.status == GameStatus.menu && _gameStartTime == 0) {
      _trackGameStart();
    }
    
    // Always handle single tap immediately for responsive gameplay
    game.handleTap();
    
    // Check for double tap
    if (_lastTapTime != null && 
        now.difference(_lastTapTime!) < _doubleTapThreshold) {
      // Double tap detected - activate pulse
      if (game.gameState.status == GameStatus.playing && !game.gameState.isPaused) {
        final pulseActivated = game.pulseManager.tryActivatePulse();
        if (pulseActivated) {
          _trackPulseUsage();
          debugPrint('Double tap detected - pulse activated');
        }
      }
    }
    
    // Track game end when game over
    if (game.gameState.status == GameStatus.gameOver && _gameStartTime > 0) {
      _trackGameEnd();
      _gameStartTime = 0; // Reset for next game
    }
    
    _lastTapTime = now;
  }
}