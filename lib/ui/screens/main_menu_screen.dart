import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'customization_screen.dart';
import 'achievements_screen.dart';
import '../../game/managers/customization_manager.dart';
import '../../game/managers/achievement_manager.dart';
import '../../game/managers/audio_manager.dart';
import '../utils/transition_manager.dart';
import '../utils/animation_config.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with WidgetsBindingObserver {
  final CustomizationManager _customizationManager = CustomizationManager();
  late final AchievementManager _achievementManager;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _achievementManager = AchievementManager(_customizationManager);
    _initializeCustomization();
    
    // Add observer for app lifecycle events
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Stop background music when app goes to background
        AudioManager().stopBackgroundMusic();
        break;
      case AppLifecycleState.resumed:
        // Restart background music when returning to foreground
        if (_isInitialized) {
          try {
            AudioManager().playBackgroundMusic(
              'cyberpunk_theme.mp3',
              fadeIn: true,
              fadeDuration: AnimationConfig.slow,
            );
          } catch (e) {
            print('Failed to restart background music: $e');
          }
        }
        break;
      case AppLifecycleState.detached:
        // App is being terminated - stop all audio
        AudioManager().stopBackgroundMusic();
        break;
    }
  }

  Future<void> _initializeCustomization() async {
    await _customizationManager.initialize();
    await _achievementManager.initialize();
    
    // Start background music with fade-in only if not already playing
    try {
      final audioManager = AudioManager();
      if (!audioManager.isMusicPlaying) {
        await audioManager.playBackgroundMusic(
          'cyberpunk_theme.mp3',
          fadeIn: true,
          fadeDuration: AnimationConfig.slow,
        );
      } else {
        print('Background music is already playing, not restarting');
      }
    } catch (e) {
      print('Failed to start background music: $e');
    }
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0B1F), // Deep space
              Color(0xFF1A0B2E), // Dark purple
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game title with animations
                TransitionManager.floatingAnimation(
                  Text(
                    'NEON PULSE',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 48,
                      letterSpacing: 4,
                    ),
                  ),
                ).animate().fadeIn(duration: AnimationConfig.slow.inMilliseconds.ms).slideY(begin: -0.3, end: 0),
                
                const SizedBox(height: 8),
                
                Text(
                  'FLAPPY BIRD',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 24,
                    color: Colors.pink,
                    shadows: [
                      const Shadow(
                        blurRadius: 10.0,
                        color: Colors.pink,
                        offset: Offset(0, 0),
                      ),
                      const Shadow(
                        blurRadius: 20.0,
                        color: Colors.pink,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: AnimationConfig.medium.inMilliseconds.ms, duration: AnimationConfig.slow.inMilliseconds.ms).slideY(begin: 0.3, end: 0),
                const SizedBox(height: 80),
                
                // Menu buttons with staggered animations
                ...TransitionManager.staggeredChildren([
                  _buildMenuButton(
                    context,
                    'PLAY',
                    _isInitialized ? () {
                      Navigator.of(context).push(
                        TransitionManager.neonTransition(
                          GameScreen(
                            achievementManager: _achievementManager,
                            customizationManager: _customizationManager,
                          ),
                          glowColor: Colors.green,
                        ),
                      );
                    } : null,
                  ),
                  const SizedBox(height: 20),
                  _buildMenuButton(
                    context,
                    'CUSTOMIZE',
                    _isInitialized ? () {
                      Navigator.of(context).push(
                        TransitionManager.slideTransition(
                          CustomizationScreen(
                            customizationManager: _customizationManager,
                          ),
                        ),
                      );
                    } : null,
                  ),
                  const SizedBox(height: 20),
                  _buildMenuButton(
                    context,
                    'ACHIEVEMENTS',
                    _isInitialized ? () {
                      Navigator.of(context).push(
                        TransitionManager.scaleTransition(
                          AchievementsScreen(
                            achievementManager: _achievementManager,
                          ),
                        ),
                      );
                    } : null,
                  ),
                  const SizedBox(height: 20),
                  _buildMenuButton(
                    context,
                    'SETTINGS',
                    () {
                      Navigator.of(context).push(
                        TransitionManager.fadeTransition(
                          SettingsScreen(
                            audioManager: AudioManager(),
                          ),
                        ),
                      );
                    },
                  ),
                ], staggerDelay: AnimationConfig.menuButtonDelay),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String text, VoidCallback? onPressed) {
    final isEnabled = onPressed != null;
    
    Widget button = SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: isEnabled ? Colors.cyan : Colors.grey,
          side: BorderSide(
            color: isEnabled ? Colors.cyan : Colors.grey,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          shadowColor: isEnabled ? Colors.cyan.withOpacity(0.5) : null,
          elevation: isEnabled ? 8 : 0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: isEnabled ? Colors.cyan : Colors.grey,
            shadows: isEnabled ? [
              const Shadow(
                blurRadius: 8.0,
                color: Colors.cyan,
                offset: Offset(0, 0),
              ),
            ] : null,
          ),
        ),
      ),
    );
    
    // Add pulse animation for enabled buttons
    if (isEnabled) {
      button = TransitionManager.pulseButton(button);
    }
    
    return button;
  }
}