import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'dart:async';
import 'dart:math' as math;
import '../theme/neon_theme.dart';
import '../effects/progression_particle_system.dart';
import '../../game/effects/particle_system.dart';

/// Widget for displaying loading state with skeleton path and shimmer effects
class ProgressionLoadingState extends StatefulWidget {
  final Size screenSize;
  final bool showShimmer;

  const ProgressionLoadingState({
    super.key,
    required this.screenSize,
    this.showShimmer = true,
  });

  @override
  State<ProgressionLoadingState> createState() => _ProgressionLoadingStateState();
}

class _ProgressionLoadingStateState extends State<ProgressionLoadingState>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.showShimmer) {
      _shimmerController.repeat();
    }
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Skeleton path
        CustomPaint(
          size: widget.screenSize,
          painter: _SkeletonPathPainter(
            shimmerAnimation: _shimmerAnimation,
            pulseAnimation: _pulseAnimation,
            showShimmer: widget.showShimmer,
          ),
        ),
        
        // Loading indicator
        Positioned(
          top: widget.screenSize.height * 0.4,
          left: 0,
          right: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(NeonTheme.primaryNeon),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _pulseAnimation.value,
                    child: Text(
                      'Loading Progression Path...',
                      style: TextStyle(
                        color: NeonTheme.textSecondary,
                        fontSize: 16,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying motivational empty state for players with no unlocked achievements
class ProgressionEmptyState extends StatefulWidget {
  final Size screenSize;
  final VoidCallback? onStartJourney;

  const ProgressionEmptyState({
    super.key,
    required this.screenSize,
    this.onStartJourney,
  });

  @override
  State<ProgressionEmptyState> createState() => _ProgressionEmptyStateState();
}

class _ProgressionEmptyStateState extends State<ProgressionEmptyState>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _floatController;
  late Animation<double> _glowAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _floatAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
    
    _glowController.repeat(reverse: true);
    _floatController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Faded path preview
        CustomPaint(
          size: widget.screenSize,
          painter: _EmptyPathPainter(),
        ),
        
        // Motivational content
        Positioned(
          top: widget.screenSize.height * 0.3,
          left: 0,
          right: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Floating achievement icon
              AnimatedBuilder(
                animation: Listenable.merge([_glowAnimation, _floatAnimation]),
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: NeonTheme.primaryNeon.withValues(alpha: 0.1),
                        border: Border.all(
                          color: NeonTheme.primaryNeon.withValues(alpha: _glowAnimation.value),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: NeonTheme.primaryNeon.withValues(alpha: _glowAnimation.value * 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.star_outline,
                        size: 40,
                        color: NeonTheme.primaryNeon.withValues(alpha: _glowAnimation.value),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Motivational title
              Text(
                'BEGIN YOUR JOURNEY',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: NeonTheme.primaryNeon,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Motivational message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Your progression path awaits! Start playing to unlock achievements and discover new bird skins.',
                  style: TextStyle(
                    color: NeonTheme.textSecondary,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Start journey button
              if (widget.onStartJourney != null)
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: NeonTheme.primaryNeon.withValues(alpha: _glowAnimation.value * 0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: widget.onStartJourney,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NeonTheme.primaryNeon.withValues(alpha: 0.1),
                          foregroundColor: NeonTheme.primaryNeon,
                          side: BorderSide(
                            color: NeonTheme.primaryNeon.withValues(alpha: _glowAnimation.value),
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'START PLAYING',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying celebration state with confetti effects for 100% completion
class ProgressionCelebrationState extends StatefulWidget {
  final Size screenSize;
  final int totalAchievements;
  final VoidCallback? onContinue;

  const ProgressionCelebrationState({
    super.key,
    required this.screenSize,
    required this.totalAchievements,
    this.onContinue,
  });

  @override
  State<ProgressionCelebrationState> createState() => _ProgressionCelebrationStateState();
}

class _ProgressionCelebrationStateState extends State<ProgressionCelebrationState>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _textController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _textAnimation;
  late ProgressionParticleSystem _particleSystem;

  @override
  void initState() {
    super.initState();
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.easeInOut,
    ));
    
    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));
    
    // Initialize particle system for confetti
    final baseParticleSystem = ParticleSystem();
    _particleSystem = ProgressionParticleSystem(
      baseParticleSystem: baseParticleSystem,
    );
    
    _startCelebrationSequence();
  }

  void _startCelebrationSequence() async {
    // Start confetti particles
    _particleSystem.addCelebrationConfetti(
      centerPosition: Vector2(widget.screenSize.width / 2, widget.screenSize.height / 2),
      screenSize: widget.screenSize,
    );
    
    // Start animations in sequence
    _confettiController.forward();
    
    // Use Future.delayed with mounted checks for test compatibility
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _celebrationController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _textController.forward();
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _textController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti particle system
        CustomPaint(
          size: widget.screenSize,
          painter: _ConfettiPainter(_particleSystem, _confettiController),
        ),
        
        // Celebration content
        Positioned(
          top: widget.screenSize.height * 0.25,
          left: 0,
          right: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated trophy/crown icon
              AnimatedBuilder(
                animation: Listenable.merge([_scaleAnimation, _rotationAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 0.1, // Subtle rotation
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              NeonTheme.primaryNeon.withValues(alpha: 0.8),
                              NeonTheme.primaryNeon.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: NeonTheme.primaryNeon.withValues(alpha: 0.6),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          size: 60,
                          color: NeonTheme.primaryNeon,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Animated celebration title
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - _textAnimation.value) * 20),
                      child: Text(
                        'MASTER ACHIEVED!',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: NeonTheme.primaryNeon,
                          letterSpacing: 3.0,
                          shadows: [
                            Shadow(
                              color: NeonTheme.primaryNeon.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Achievement count
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - _textAnimation.value) * 30),
                      child: Text(
                        '${widget.totalAchievements} / ${widget.totalAchievements} ACHIEVEMENTS',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: NeonTheme.accentNeon,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Congratulatory message
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - _textAnimation.value) * 40),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Congratulations! You have unlocked all achievements and mastered the neon skies. You are a true Pulse Master!',
                          style: TextStyle(
                            color: NeonTheme.textSecondary,
                            fontSize: 16,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // Continue button
              if (widget.onContinue != null)
                AnimatedBuilder(
                  animation: _textAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - _textAnimation.value) * 50),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: NeonTheme.accentNeon.withValues(alpha: 0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: widget.onContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: NeonTheme.accentNeon.withValues(alpha: 0.1),
                              foregroundColor: NeonTheme.accentNeon,
                              side: BorderSide(
                                color: NeonTheme.accentNeon,
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'CONTINUE',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for skeleton path with shimmer effect
class _SkeletonPathPainter extends CustomPainter {
  final Animation<double> shimmerAnimation;
  final Animation<double> pulseAnimation;
  final bool showShimmer;

  _SkeletonPathPainter({
    required this.shimmerAnimation,
    required this.pulseAnimation,
    required this.showShimmer,
  }) : super(repaint: Listenable.merge([shimmerAnimation, pulseAnimation]));

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Draw skeleton main path
    final path = Path();
    final centerX = size.width / 2;
    final startY = size.height * 0.1;
    final endY = size.height * 0.9;
    
    // Create a more realistic curved path that resembles the actual progression path
    path.moveTo(centerX, startY);
    for (int i = 1; i <= 12; i++) {
      final progress = i / 12.0;
      final y = startY + (endY - startY) * progress;
      final x = centerX + math.sin(progress * math.pi * 1.5) * 40;
      path.lineTo(x, y);
    }

    // Apply shimmer effect if enabled
    if (showShimmer) {
      final shimmerGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          NeonTheme.primaryNeon.withValues(alpha: 0.4 * pulseAnimation.value),
          NeonTheme.primaryNeon.withValues(alpha: 0.6 * pulseAnimation.value),
          Colors.transparent,
        ],
        stops: [
          (shimmerAnimation.value - 0.4).clamp(0.0, 1.0),
          (shimmerAnimation.value - 0.1).clamp(0.0, 1.0),
          shimmerAnimation.value.clamp(0.0, 1.0),
          (shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
        ],
      );
      
      paint.shader = shimmerGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      paint.color = NeonTheme.primaryNeon.withValues(alpha: 0.3 * pulseAnimation.value);
    }

    canvas.drawPath(path, paint);

    // Draw skeleton branch paths
    _drawSkeletonBranches(canvas, size, centerX, startY, endY);

    // Draw skeleton nodes with different sizes for variety
    final nodePaint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i <= 12; i++) {
      final progress = i / 12.0;
      final y = startY + (endY - startY) * progress;
      final x = centerX + math.sin(progress * math.pi * 1.5) * 40;
      
      // Vary node opacity and size for more realistic skeleton
      final nodeAlpha = (0.15 + 0.1 * math.sin(progress * math.pi * 3)) * pulseAnimation.value;
      final nodeSize = 12.0 + 6.0 * math.sin(progress * math.pi * 2);
      
      nodePaint.color = NeonTheme.primaryNeon.withValues(alpha: nodeAlpha);
      canvas.drawCircle(Offset(x, y), nodeSize, nodePaint);
      
      // Add inner glow effect
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = NeonTheme.primaryNeon.withValues(alpha: nodeAlpha * 0.5);
      canvas.drawCircle(Offset(x, y), nodeSize + 3, glowPaint);
    }
  }

  /// Draw skeleton branch paths for more realistic loading state
  void _drawSkeletonBranches(Canvas canvas, Size size, double centerX, double startY, double endY) {
    final branchPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = NeonTheme.accentNeon.withValues(alpha: 0.2 * pulseAnimation.value);

    // Draw a few branch paths
    for (int branch = 0; branch < 3; branch++) {
      final branchStartProgress = 0.3 + (branch * 0.2);
      final branchY = startY + (endY - startY) * branchStartProgress;
      final branchStartX = centerX + math.sin(branchStartProgress * math.pi * 1.5) * 40;
      
      final branchPath = Path();
      branchPath.moveTo(branchStartX, branchY);
      
      // Create branch curve
      for (int i = 1; i <= 4; i++) {
        final progress = i / 4.0;
        final y = branchY + progress * 80;
        final x = branchStartX + (branch % 2 == 0 ? 1 : -1) * progress * 60;
        branchPath.lineTo(x, y);
      }
      
      canvas.drawPath(branchPath, branchPaint);
    }
  }

  @override
  bool shouldRepaint(_SkeletonPathPainter oldDelegate) => true;
}

/// Custom painter for empty state path preview
class _EmptyPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = NeonTheme.primaryNeon.withValues(alpha: 0.1);

    // Draw faded path preview
    final path = Path();
    final centerX = size.width / 2;
    final startY = size.height * 0.2;
    final endY = size.height * 0.8;
    
    path.moveTo(centerX, startY);
    for (int i = 1; i <= 8; i++) {
      final progress = i / 8.0;
      final y = startY + (endY - startY) * progress;
      final x = centerX + math.sin(progress * math.pi * 1.5) * 40;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Draw faded nodes
    final nodePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = NeonTheme.primaryNeon.withValues(alpha: 0.1);

    for (int i = 0; i <= 8; i++) {
      final progress = i / 8.0;
      final y = startY + (endY - startY) * progress;
      final x = centerX + math.sin(progress * math.pi * 1.5) * 40;
      canvas.drawCircle(Offset(x, y), 12, nodePaint);
    }
  }

  @override
  bool shouldRepaint(_EmptyPathPainter oldDelegate) => false;
}

/// Custom painter for confetti particles
class _ConfettiPainter extends CustomPainter {
  final ProgressionParticleSystem particleSystem;
  final AnimationController controller;
  DateTime _lastUpdateTime = DateTime.now();

  _ConfettiPainter(this.particleSystem, this.controller) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // Update particle system
    final now = DateTime.now();
    final dt = now.difference(_lastUpdateTime).inMicroseconds / 1000000.0;
    _lastUpdateTime = now;
    
    // Update particles with empty path segments (confetti doesn't need paths)
    particleSystem.update(dt, []);
    
    // Render particles
    particleSystem.render(canvas);
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}