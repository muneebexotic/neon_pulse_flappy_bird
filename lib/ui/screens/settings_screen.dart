import 'package:flutter/material.dart';
import '../components/audio_settings.dart';
import '../theme/neon_theme.dart';
import '../../game/managers/audio_manager.dart';

/// Settings screen with audio controls and other game settings
class SettingsScreen extends StatelessWidget {
  final AudioManager? audioManager;
  
  const SettingsScreen({
    super.key,
    this.audioManager,
  });

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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back,
                        color: NeonTheme.electricBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SETTINGS',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: NeonTheme.electricBlue,
                        letterSpacing: 3,
                        shadows: NeonTheme.getNeonGlow(NeonTheme.electricBlue),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Settings content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Audio Settings
                      if (audioManager != null) ...[
                        AudioSettings(audioManager: audioManager!),
                        const SizedBox(height: 30),
                      ],
                      
                      // Game Settings
                      _buildGameSettings(context),
                      const SizedBox(height: 30),
                      
                      // Performance Settings
                      _buildPerformanceSettings(context),
                      const SizedBox(height: 30),
                      
                      // About Section
                      _buildAboutSection(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameSettings(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeonTheme.darkPurple.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: NeonTheme.hotPink.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: NeonTheme.hotPink.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: NeonTheme.hotPink,
              shadows: NeonTheme.getNeonGlow(NeonTheme.hotPink),
            ),
          ),
          const SizedBox(height: 20),
          
          _buildSettingRow(
            'Difficulty',
            'Normal',
            Icons.speed,
            () {
              // TODO: Implement difficulty selection
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Difficulty settings coming soon!'),
                  backgroundColor: NeonTheme.hotPink,
                ),
              );
            },
          ),
          
          const SizedBox(height: 15),
          
          _buildSettingRow(
            'Controls',
            'Tap & Double-tap',
            Icons.touch_app,
            () {
              // TODO: Implement control customization
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Control customization coming soon!'),
                  backgroundColor: NeonTheme.hotPink,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSettings(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeonTheme.darkPurple.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: NeonTheme.neonGreen.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: NeonTheme.neonGreen.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: NeonTheme.neonGreen,
              shadows: NeonTheme.getNeonGlow(NeonTheme.neonGreen),
            ),
          ),
          const SizedBox(height: 20),
          
          _buildSettingRow(
            'Graphics Quality',
            'Auto',
            Icons.auto_awesome,
            () {
              // TODO: Implement graphics quality settings
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Graphics settings coming soon!'),
                  backgroundColor: NeonTheme.neonGreen,
                ),
              );
            },
          ),
          
          const SizedBox(height: 15),
          
          _buildSettingRow(
            'Particle Effects',
            'High',
            Icons.auto_fix_high,
            () {
              // TODO: Implement particle quality settings
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Particle settings coming soon!'),
                  backgroundColor: NeonTheme.neonGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeonTheme.darkPurple.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: NeonTheme.warningOrange.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: NeonTheme.warningOrange.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: NeonTheme.warningOrange,
              shadows: NeonTheme.getNeonGlow(NeonTheme.warningOrange),
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            'Neon Pulse Flappy Bird',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: NeonTheme.electricBlue,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 14,
              color: NeonTheme.neonGreen.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 15),
          
          Text(
            'A cyberpunk-themed Flappy Bird game with neon effects, pulse mechanics, and beat-synchronized gameplay.',
            style: TextStyle(
              fontSize: 14,
              color: NeonTheme.white.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String title, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: NeonTheme.electricBlue.withOpacity(0.8),
              size: 24,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: NeonTheme.white,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: NeonTheme.electricBlue.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: NeonTheme.electricBlue.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}