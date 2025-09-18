import 'package:flutter/material.dart';
import '../../game/managers/power_up_manager.dart';
import '../../game/components/power_up.dart';

/// Game HUD component that displays real-time score and other game information
class GameHUD extends StatelessWidget {
  final int currentScore;
  final int highScore;
  final bool isPaused;
  final VoidCallback? onPause;
  final VoidCallback? onSettings;
  final String? pulseStatus;
  final bool isPulseReady;
  final bool showDebugInfo;
  final List<ActivePowerUpEffect>? activePowerUps;
  final double? scoreMultiplier;

  const GameHUD({
    super.key,
    required this.currentScore,
    required this.highScore,
    this.isPaused = false,
    this.onPause,
    this.onSettings,
    this.pulseStatus,
    this.isPulseReady = false,
    this.showDebugInfo = false,
    this.activePowerUps,
    this.scoreMultiplier,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top row with score and pause button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Current Score Display
                _buildScoreDisplay(),
                
                // Control buttons
                Row(
                  children: [
                    // Settings Button (if callback provided)
                    if (onSettings != null) ...[
                      _buildSettingsButton(),
                      const SizedBox(width: 8),
                    ],
                    // Pause Button (if callback provided)
                    if (onPause != null)
                      _buildPauseButton(),
                  ],
                ),
              ],
            ),
            
            // High Score Display (smaller, below current score)
            Align(
              alignment: Alignment.centerLeft,
              child: _buildHighScoreDisplay(),
            ),
            
            // Pulse Status Display (if provided)
            if (pulseStatus != null)
              Align(
                alignment: Alignment.centerRight,
                child: _buildPulseStatusDisplay(),
              ),
            
            // Power-up Status Indicators
            if (activePowerUps != null && activePowerUps!.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: _buildPowerUpIndicators(),
              ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDisplay() {
    final isMultiplied = scoreMultiplier != null && scoreMultiplier! > 1.0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMultiplied 
              ? Colors.green.withValues(alpha: 0.7)
              : Colors.cyan.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentScore.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isMultiplied ? Colors.green : Colors.cyan,
              shadows: [
                Shadow(
                  blurRadius: 10.0,
                  color: isMultiplied ? Colors.green : Colors.cyan,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
          if (isMultiplied) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${scoreMultiplier!.toStringAsFixed(0)}x',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  shadows: [
                    Shadow(
                      blurRadius: 6.0,
                      color: Colors.green,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighScoreDisplay() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'BEST: $highScore',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green,
              shadows: [
                Shadow(
                  blurRadius: 6.0,
                  color: Colors.green,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onSettings,
        icon: Icon(
          Icons.settings,
          color: Colors.purple,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildPauseButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPause,
        icon: Icon(
          isPaused ? Icons.play_arrow : Icons.pause,
          color: Colors.orange,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildPulseStatusDisplay() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPulseReady 
              ? Colors.blue.withValues(alpha: 0.7)
              : Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flash_on,
            color: isPulseReady ? Colors.blue : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            pulseStatus ?? '',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPulseReady ? Colors.blue : Colors.grey,
              shadows: isPulseReady ? [
                Shadow(
                  blurRadius: 6.0,
                  color: Colors.blue,
                  offset: const Offset(0, 0),
                ),
              ] : null,
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildPowerUpIndicators() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: activePowerUps!.map((effect) => _buildPowerUpIndicator(effect)).toList(),
      ),
    );
  }
  
  Widget _buildPowerUpIndicator(ActivePowerUpEffect effect) {
    final isAboutToExpire = effect.isAboutToExpire;
    final progress = effect.progress;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAboutToExpire 
              ? Colors.red.withValues(alpha: 0.7)
              : effect.color.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Power-up icon
          Icon(
            _getPowerUpIcon(effect.type),
            color: isAboutToExpire ? Colors.red : effect.color,
            size: 16,
          ),
          const SizedBox(width: 4),
          
          // Power-up name
          Text(
            effect.description,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isAboutToExpire ? Colors.red : effect.color,
              shadows: [
                Shadow(
                  blurRadius: 4.0,
                  color: isAboutToExpire ? Colors.red : effect.color,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          
          // Timer progress bar
          Container(
            width: 30,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: isAboutToExpire ? Colors.red : effect.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          
          // Remaining time
          Text(
            '${effect.remainingTime.toStringAsFixed(0)}s',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isAboutToExpire ? Colors.red : effect.color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getPowerUpIcon(PowerUpType type) {
    switch (type) {
      case PowerUpType.shield:
        return Icons.shield;
      case PowerUpType.scoreMultiplier:
        return Icons.star;
      case PowerUpType.slowMotion:
        return Icons.access_time;
    }
  }
}