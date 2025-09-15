import 'package:flutter/material.dart';
import '../../game/managers/achievement_manager.dart';
import '../theme/neon_theme.dart';

/// Game over screen that displays final score, high score, and restart button
class GameOverScreen extends StatelessWidget {
  final int finalScore;
  final int highScore;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;
  final AchievementManager? achievementManager;
  final GlobalKey? screenshotKey;

  const GameOverScreen({
    super.key,
    required this.finalScore,
    required this.highScore,
    required this.onRestart,
    required this.onMainMenu,
    this.achievementManager,
    this.screenshotKey,
  });

  @override
  Widget build(BuildContext context) {
    final isNewHighScore = finalScore == highScore && finalScore > 0;
    
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0B0B1F),
            border: Border.all(
              color: Colors.cyan,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Game Over Title
              Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.red,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // New High Score indicator (if applicable)
              if (isNewHighScore) ...[
                Text(
                  'NEW HIGH SCORE!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                    shadows: [
                      Shadow(
                        blurRadius: 8.0,
                        color: Colors.yellow,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Final Score
              _buildScoreRow('SCORE', finalScore, Colors.cyan),
              
              const SizedBox(height: 12),
              
              // High Score
              _buildScoreRow('HIGH SCORE', highScore, Colors.green),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Restart Button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildActionButton(
                        'RESTART',
                        Icons.refresh,
                        Colors.cyan,
                        onRestart,
                      ),
                    ),
                  ),
                  
                  // Main Menu Button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildActionButton(
                        'MENU',
                        Icons.home,
                        Colors.orange,
                        onMainMenu,
                      ),
                    ),
                  ),
                  
                  // Share Score Button (only if achievement manager is available)
                  if (achievementManager != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildActionButton(
                          'SHARE',
                          Icons.share,
                          NeonTheme.secondaryNeon,
                          () => _shareScore(),
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Tap to restart hint
              Text(
                'Tap RESTART to play again',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, int score, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          score.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [
              Shadow(
                blurRadius: 8.0,
                color: color,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        side: BorderSide(color: color, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(0, 48),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }



  void _shareScore() {
    if (achievementManager != null) {
      final isNewHighScore = finalScore == highScore && finalScore > 0;
      final message = isNewHighScore
          ? 'NEW HIGH SCORE! Just scored $finalScore points in Neon Pulse! 🚀✨ Can you beat my cyberpunk bird skills? #NeonPulse #NewRecord'
          : 'Just scored $finalScore points in Neon Pulse! 🚀✨ My high score is $highScore. Can you beat it? #NeonPulse #Gaming';
      
      achievementManager!.shareHighScore(
        score: finalScore,
        customMessage: message,
      );
    }
  }


}