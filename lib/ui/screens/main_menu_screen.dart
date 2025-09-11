import 'package:flutter/material.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

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
                    // TODO: Navigate to game screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Game screen not implemented yet'),
                        backgroundColor: Colors.cyan,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuButton(
                  context,
                  'CUSTOMIZE',
                  () {
                    // TODO: Navigate to customization screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Customization screen not implemented yet'),
                        backgroundColor: Colors.pink,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuButton(
                  context,
                  'SETTINGS',
                  () {
                    // TODO: Navigate to settings screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings screen not implemented yet'),
                        backgroundColor: Colors.green,
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

  Widget _buildMenuButton(BuildContext context, String text, VoidCallback onPressed) {
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