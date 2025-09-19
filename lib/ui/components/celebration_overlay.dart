import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/leaderboard_integration_service.dart';
import '../theme/neon_theme.dart';

/// Overlay that displays celebration animations for achievements
class CelebrationOverlay extends StatefulWidget {
  final CelebrationLevel level;
  final int score;
  final int? leaderboardPosition;
  final bool isPersonalBest;
  final VoidCallback? onComplete;
  final Duration duration;

  const CelebrationOverlay({
    super.key,
    required this.level,
    required this.score,
    this.leaderboardPosition,
    this.isPersonalBest = false,
    this.onComplete,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _textController;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _startAnimation();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _startAnimation() async {
    // Start all animations
    _mainController.forward();
    _particleController.repeat();
    _textController.forward();

    // Complete after duration
    await Future.delayed(widget.duration);
    if (mounted) {
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withValues(alpha: 0.7),
        child: Stack(
          children: [
            // Background particles
            _buildBackgroundParticles(),
            
            // Main celebration content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main celebration text
                  _buildMainText(),
                  
                  const SizedBox(height: 20),
                  
                  // Score display
                  _buildScoreDisplay(),
                  
                  const SizedBox(height: 16),
                  
                  // Additional achievement info
                  if (widget.leaderboardPosition != null)
                    _buildLeaderboardPosition(),
                  
                  if (widget.isPersonalBest)
                    _buildPersonalBestBadge(),
                ],
              ),
            ),
            
            // Fireworks/particles overlay
            _buildCelebrationParticles(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainText() {
    final config = _getCelebrationConfig();
    
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.5 + (_textController.value * 0.5),
          child: Opacity(
            opacity: _textController.value,
            child: Text(
              config.title,
              style: TextStyle(
                fontSize: config.titleSize,
                fontWeight: FontWeight.bold,
                color: config.primaryColor,
                shadows: [
                  Shadow(
                    blurRadius: 20.0,
                    color: config.primaryColor,
                    offset: const Offset(0, 0),
                  ),
                  Shadow(
                    blurRadius: 40.0,
                    color: config.primaryColor.withValues(alpha: 0.5),
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreDisplay() {
    final config = _getCelebrationConfig();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: config.primaryColor.withValues(alpha: 0.1),
        border: Border.all(color: config.primaryColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: config.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        '${widget.score}',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: config.primaryColor,
          shadows: [
            Shadow(
              blurRadius: 10.0,
              color: config.primaryColor,
              offset: const Offset(0, 0),
            ),
          ],
        ),
      ),
    ).animate().scale(
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
    ).shimmer(
      duration: const Duration(seconds: 2),
      color: config.primaryColor.withValues(alpha: 0.5),
    );
  }

  Widget _buildLeaderboardPosition() {
    final config = _getCelebrationConfig();
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: config.secondaryColor.withValues(alpha: 0.1),
        border: Border.all(color: config.secondaryColor, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Global Rank: #${widget.leaderboardPosition}',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: config.secondaryColor,
          shadows: [
            Shadow(
              blurRadius: 8.0,
              color: config.secondaryColor,
              offset: const Offset(0, 0),
            ),
          ],
        ),
      ),
    ).animate().slideY(
      begin: 1,
      duration: const Duration(milliseconds: 800),
      curve: Curves.bounceOut,
    );
  }

  Widget _buildPersonalBestBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.yellow.withValues(alpha: 0.1),
        border: Border.all(color: Colors.yellow, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: Colors.yellow,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Personal Best!',
            style: TextStyle(
              fontSize: 16,
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
        ],
      ),
    ).animate().slideY(
      begin: 1,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.bounceOut,
    ).shimmer(
      duration: const Duration(seconds: 1),
      color: Colors.yellow.withValues(alpha: 0.5),
    );
  }

  Widget _buildBackgroundParticles() {
    final config = _getCelebrationConfig();
    
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: BackgroundParticlesPainter(
            animation: _particleController,
            color: config.primaryColor,
            particleCount: config.particleCount,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildCelebrationParticles() {
    final config = _getCelebrationConfig();
    
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return CustomPaint(
          painter: CelebrationParticlesPainter(
            animation: _mainController,
            primaryColor: config.primaryColor,
            secondaryColor: config.secondaryColor,
            level: widget.level,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  CelebrationConfig _getCelebrationConfig() {
    switch (widget.level) {
      case CelebrationLevel.legendary:
        return CelebrationConfig(
          title: 'LEGENDARY!\nTOP 10 GLOBAL!',
          titleSize: 32,
          primaryColor: const Color(0xFFFFD700), // Gold
          secondaryColor: const Color(0xFFFF6B35), // Orange
          particleCount: 100,
        );
      case CelebrationLevel.epic:
        return CelebrationConfig(
          title: 'EPIC SCORE!\nTOP 100 GLOBAL!',
          titleSize: 28,
          primaryColor: const Color(0xFF9D4EDD), // Purple
          secondaryColor: const Color(0xFF06FFA5), // Green
          particleCount: 75,
        );
      case CelebrationLevel.great:
        return CelebrationConfig(
          title: 'GREAT JOB!\nNEW PERSONAL BEST!',
          titleSize: 24,
          primaryColor: const Color(0xFF06FFA5), // Green
          secondaryColor: const Color(0xFF00FFFF), // Cyan
          particleCount: 50,
        );
      case CelebrationLevel.good:
        return CelebrationConfig(
          title: 'NICE SCORE!',
          titleSize: 20,
          primaryColor: const Color(0xFF00FFFF), // Cyan
          secondaryColor: const Color(0xFFFF1493), // Pink
          particleCount: 25,
        );
    }
  }
}

/// Configuration for different celebration levels
class CelebrationConfig {
  final String title;
  final double titleSize;
  final Color primaryColor;
  final Color secondaryColor;
  final int particleCount;

  CelebrationConfig({
    required this.title,
    required this.titleSize,
    required this.primaryColor,
    required this.secondaryColor,
    required this.particleCount,
  });
}

/// Custom painter for background particles
class BackgroundParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final int particleCount;

  BackgroundParticlesPainter({
    required this.animation,
    required this.color,
    required this.particleCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final progress = (animation.value + (i / particleCount)) % 1.0;
      final x = (i * 37) % size.width;
      final y = size.height * progress;
      final radius = 2.0 + (i % 3);
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for celebration particles (fireworks, etc.)
class CelebrationParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primaryColor;
  final Color secondaryColor;
  final CelebrationLevel level;

  CelebrationParticlesPainter({
    required this.animation,
    required this.primaryColor,
    required this.secondaryColor,
    required this.level,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (level == CelebrationLevel.legendary || level == CelebrationLevel.epic) {
      _paintFireworks(canvas, size);
    } else {
      _paintBurst(canvas, size);
    }
  }

  void _paintFireworks(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = size.width * 0.3;

    // Multiple firework bursts
    for (int burst = 0; burst < 3; burst++) {
      final burstProgress = (animation.value * 3 - burst).clamp(0.0, 1.0);
      if (burstProgress <= 0) continue;

      final burstX = centerX + (burst - 1) * size.width * 0.2;
      final burstY = centerY + (burst - 1) * size.height * 0.1;

      for (int i = 0; i < 20; i++) {
        final angle = (i / 20) * 2 * 3.14159;
        final radius = maxRadius * burstProgress;
        final x = burstX + radius * 0.8 * burstProgress * (1 + 0.2 * (i % 3));
        final y = burstY + radius * 0.8 * burstProgress * (1 + 0.2 * (i % 3));

        paint.color = i % 2 == 0 ? primaryColor : secondaryColor;
        paint.color = paint.color.withValues(alpha: 1.0 - burstProgress);

        canvas.drawCircle(
          Offset(
            burstX + (x - burstX) * (0.5 + 0.5 * burstProgress),
            burstY + (y - burstY) * (0.5 + 0.5 * burstProgress),
          ),
          3.0 * (1.0 - burstProgress * 0.5),
          paint,
        );
      }
    }
  }

  void _paintBurst(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = size.width * 0.2;

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * 3.14159;
      final radius = maxRadius * animation.value;
      final x = centerX + radius * 0.8 * animation.value;
      final y = centerY + radius * 0.8 * animation.value;

      paint.color = i % 2 == 0 ? primaryColor : secondaryColor;
      paint.color = paint.color.withValues(alpha: 1.0 - animation.value);

      canvas.drawCircle(
        Offset(
          centerX + (x - centerX) * (0.3 + 0.7 * animation.value),
          centerY + (y - centerY) * (0.3 + 0.7 * animation.value),
        ),
        4.0 * (1.0 - animation.value * 0.7),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}