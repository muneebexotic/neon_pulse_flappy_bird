import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget that displays beat sync bonus score indicators
class BeatSyncBonus extends StatefulWidget {
  final int bonusPoints;
  final bool isVisible;
  final VoidCallback? onAnimationComplete;
  
  const BeatSyncBonus({
    super.key,
    required this.bonusPoints,
    this.isVisible = false,
    this.onAnimationComplete,
  });
  
  @override
  State<BeatSyncBonus> createState() => _BeatSyncBonusState();
}

class _BeatSyncBonusState extends State<BeatSyncBonus>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Initialize animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -2),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInQuart,
    ));
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(BeatSyncBonus oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible && !oldWidget.isVisible) {
      _startAnimation();
    }
  }
  
  void _startAnimation() async {
    // Reset all animations
    _slideController.reset();
    _pulseController.reset();
    _fadeController.reset();
    
    // Start pulse animation immediately
    _pulseController.forward();
    
    // Start slide animation
    _slideController.forward();
    
    // Wait a bit, then start fade out
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      _fadeController.forward();
    }
    
    // Complete animation after total duration
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted && widget.onAnimationComplete != null) {
      widget.onAnimationComplete!();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.3,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _slideAnimation,
          _pulseAnimation,
          _fadeAnimation,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              0,
              _slideAnimation.value.dy * 100,
            ),
            child: Transform.scale(
              scale: _pulseAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Beat sync icon
                        Icon(
                          Icons.music_note,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        
                        // "BEAT SYNC" text
                        Text(
                          'BEAT SYNC!',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 8.0,
                                color: Colors.green,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        
                        // Bonus points
                        Text(
                          '+${widget.bonusPoints} BONUS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                blurRadius: 6.0,
                                color: Colors.green.withOpacity(0.5),
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Widget for displaying rhythm streak bonuses
class RhythmStreakBonus extends StatefulWidget {
  final int streakCount;
  final int bonusMultiplier;
  final bool isVisible;
  final VoidCallback? onAnimationComplete;
  
  const RhythmStreakBonus({
    super.key,
    required this.streakCount,
    required this.bonusMultiplier,
    this.isVisible = false,
    this.onAnimationComplete,
  });
  
  @override
  State<RhythmStreakBonus> createState() => _RhythmStreakBonusState();
}

class _RhythmStreakBonusState extends State<RhythmStreakBonus>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInQuart,
    ));
  }
  
  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(RhythmStreakBonus oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible && !oldWidget.isVisible) {
      _startAnimation();
    }
  }
  
  void _startAnimation() async {
    // Reset animations
    _scaleController.reset();
    _rotationController.reset();
    _fadeController.reset();
    
    // Start scale and rotation
    _scaleController.forward();
    _rotationController.forward();
    
    // Wait, then fade out
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      _fadeController.forward();
    }
    
    // Complete
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted && widget.onAnimationComplete != null) {
      widget.onAnimationComplete!();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }
    
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _rotationAnimation,
          _fadeAnimation,
        ]),
        builder: (context, child) {
          return Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 0.1, // Subtle rotation
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.purple,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Streak icon
                        Icon(
                          Icons.whatshot,
                          color: Colors.purple,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        
                        // Streak text
                        Text(
                          'RHYTHM STREAK!',
                          style: TextStyle(
                            color: Colors.purple,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.purple,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        
                        // Streak count
                        Text(
                          '${widget.streakCount} IN A ROW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Multiplier bonus
                        Text(
                          '${widget.bonusMultiplier}x SCORE MULTIPLIER',
                          style: TextStyle(
                            color: Colors.yellow,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 6.0,
                                color: Colors.yellow.withOpacity(0.5),
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}