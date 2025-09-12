import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'customization_screen.dart';
import '../../game/managers/customization_manager.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final CustomizationManager _customizationManager = CustomizationManager();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCustomization();
  }

  Future<void> _initializeCustomization() async {
    await _customizationManager.initialize();
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
                // Game title
                Text(
                  'NEON PULSE',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 48,
                    letterSpacing: 4,
                  ),
                ),
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
                    ],
                  ),
                ),
                const SizedBox(height: 80),
                
                // Menu buttons
                _buildMenuButton(
                  context,
                  'PLAY',
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const GameScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuButton(
                  context,
                  'CUSTOMIZE',
                  _isInitialized ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CustomizationScreen(
                          customizationManager: _customizationManager,
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
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String text, VoidCallback? onPressed) {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}