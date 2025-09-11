import 'package:flutter/material.dart';

/// Game HUD component that displays real-time score and other game information
class GameHUD extends StatelessWidget {
  final int currentScore;
  final int highScore;
  final bool isPaused;
  final VoidCallback? onPause;
  final String? pulseStatus;
  final bool isPulseReady;
  final Map<String, dynamic>? performanceStats;
  final bool showDebugInfo;

  const GameHUD({
    super.key,
    required this.currentScore,
    required this.highScore,
    this.isPaused = false,
    this.onPause,
    this.pulseStatus,
    this.isPulseReady = false,
    this.performanceStats,
    this.showDebugInfo = false,
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
                
                // Pause Button (if callback provided)
                if (onPause != null)
                  _buildPauseButton(),
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
            
            // Debug Performance Info (if enabled)
            if (showDebugInfo && performanceStats != null)
              Align(
                alignment: Alignment.bottomLeft,
                child: _buildPerformanceDisplay(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.cyan.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        currentScore.toString(),
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.cyan,
          shadows: [
            Shadow(
              blurRadius: 10.0,
              color: Colors.cyan,
              offset: const Offset(0, 0),
            ),
          ],
        ),
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

  Widget _buildPerformanceDisplay() {
    if (performanceStats == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.yellow.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'FPS: ${performanceStats!['averageFps']}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.yellow,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            'Frame: ${performanceStats!['frameTimeMs']}ms',
            style: TextStyle(
              fontSize: 10,
              color: Colors.yellow,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            'Quality: ${performanceStats!['quality']}',
            style: TextStyle(
              fontSize: 10,
              color: performanceStats!['performanceGood'] ? Colors.green : Colors.red,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}