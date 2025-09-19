import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/achievement.dart';
import '../../models/bird_skin.dart';
import '../../game/managers/achievement_manager.dart';
import '../theme/neon_theme.dart';

/// Modal overlay that displays detailed achievement information with rich content
class AchievementDetailOverlay extends StatefulWidget {
  final Achievement achievement;
  final BirdSkin? rewardSkin;
  final AchievementManager achievementManager;
  final VoidCallback? onClose;
  final VoidCallback? onShare;

  const AchievementDetailOverlay({
    super.key,
    required this.achievement,
    this.rewardSkin,
    required this.achievementManager,
    this.onClose,
    this.onShare,
  });

  @override
  State<AchievementDetailOverlay> createState() => _AchievementDetailOverlayState();
}

class _AchievementDetailOverlayState extends State<AchievementDetailOverlay>
    with TickerProviderStateMixin {
  late AnimationController _overlayController;
  late AnimationController _contentController;
  late AnimationController _progressController;
  late AnimationController _particleController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));

    _startAnimations();
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _contentController.dispose();
    _progressController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _startAnimations() async {
    _overlayController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _contentController.forward();
      _progressController.forward();
      if (widget.achievement.isUnlocked) {
        _particleController.repeat();
      }
    }
  }

  Future<void> _closeOverlay() async {
    _particleController.stop();
    await _contentController.reverse();
    await _overlayController.reverse();
    if (mounted) {
      widget.onClose?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _overlayController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withValues(alpha: 0.8 * _fadeAnimation.value),
            child: Stack(
              children: [
                // Background particles for unlocked achievements
                if (widget.achievement.isUnlocked)
                  _buildBackgroundParticles(),
                
                // Main content
                Center(
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: _buildOverlayContent(),
                  ),
                ),
                
                // Close button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 16,
                  child: _buildCloseButton(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverlayContent() {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * _slideAnimation.value),
          child: Opacity(
            opacity: 1.0 - _slideAnimation.value,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: NeonTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.achievement.iconColor.withValues(alpha: 0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.achievement.iconColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildDescription(),
                    const SizedBox(height: 24),
                    _buildProgressSection(),
                    const SizedBox(height: 24),
                    if (widget.rewardSkin != null) ...[
                      _buildRewardSection(),
                      const SizedBox(height: 24),
                    ],
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Achievement icon with glow effect
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.achievement.iconColor.withValues(alpha: 0.1),
            border: Border.all(
              color: widget.achievement.iconColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.achievement.iconColor.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            widget.achievement.icon,
            size: 40,
            color: widget.achievement.iconColor,
          ),
        ).animate().scale(
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
        ),
        
        const SizedBox(height: 16),
        
        // Achievement name with Orbitron font
        Text(
          widget.achievement.name,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: NeonTheme.textPrimary,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ).animate().slideY(
          begin: 0.5,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        ),
        
        const SizedBox(height: 8),
        
        // Achievement status badge
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final isUnlocked = widget.achievement.isUnlocked;
    final color = isUnlocked ? NeonTheme.successNeon : NeonTheme.warningNeon;
    final text = isUnlocked ? 'UNLOCKED' : 'IN PROGRESS';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    ).animate().slideX(
      begin: 0.3,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonTheme.deepSpace.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NeonTheme.textSecondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: NeonTheme.textPrimary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.achievement.description,
            style: TextStyle(
              fontSize: 14,
              color: NeonTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _buildRequirementDetails(),
        ],
      ),
    ).animate().slideY(
      begin: 0.3,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
    );
  }

  Widget _buildRequirementDetails() {
    final typeText = _getAchievementTypeText(widget.achievement.type);
    final targetText = _getTargetValueText();
    
    return Row(
      children: [
        Icon(
          Icons.flag,
          size: 16,
          color: NeonTheme.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$typeText: $targetText',
            style: TextStyle(
              fontSize: 12,
              color: NeonTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    if (widget.achievement.isUnlocked) {
      return _buildCompletedSection();
    } else {
      return _buildProgressBar();
    }
  }

  Widget _buildCompletedSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonTheme.successNeon.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NeonTheme.successNeon,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: NeonTheme.successNeon.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: NeonTheme.successNeon,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Achievement Completed!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: NeonTheme.successNeon,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    ).animate().scale(
      duration: const Duration(milliseconds: 500),
      curve: Curves.bounceOut,
    ).shimmer(
      duration: const Duration(seconds: 2),
      color: NeonTheme.successNeon.withValues(alpha: 0.3),
    );
  }

  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        final animatedProgress = widget.achievement.progressPercentage * _progressController.value;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NeonTheme.deepSpace.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.achievement.iconColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: NeonTheme.textPrimary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '${(animatedProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.achievement.iconColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Progress bar background
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: NeonTheme.charcoal,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    // Progress fill
                    FractionallySizedBox(
                      widthFactor: animatedProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.achievement.iconColor,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: widget.achievement.iconColor.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Current/Target values
              Text(
                '${widget.achievement.currentProgress} / ${widget.achievement.targetValue}',
                style: TextStyle(
                  fontSize: 12,
                  color: NeonTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRewardSection() {
    if (widget.rewardSkin == null) return const SizedBox.shrink();
    
    final skin = widget.rewardSkin!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: skin.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: skin.primaryColor.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: skin.primaryColor.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reward',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: NeonTheme.textPrimary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              // Bird skin preview
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: skin.primaryColor.withValues(alpha: 0.2),
                  border: Border.all(
                    color: skin.primaryColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: skin.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: skin.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: skin.trailColor.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Skin details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skin.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: skin.primaryColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      skin.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: NeonTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideX(
      begin: 0.3,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (widget.achievement.isUnlocked && widget.onShare != null) ...[
          Expanded(
            child: _buildActionButton(
              text: 'Share',
              icon: Icons.share,
              color: NeonTheme.secondaryNeon,
              onPressed: widget.onShare!,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _buildActionButton(
            text: 'Close',
            icon: Icons.close,
            color: NeonTheme.textSecondary,
            onPressed: _closeOverlay,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          side: BorderSide(color: color, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),
    ).animate().slideY(
      begin: 0.5,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
    );
  }

  Widget _buildCloseButton() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NeonTheme.charcoal.withValues(alpha: 0.8),
              border: Border.all(
                color: NeonTheme.textSecondary.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: _closeOverlay,
              icon: Icon(
                Icons.close,
                color: NeonTheme.textSecondary,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: AchievementParticlesPainter(
            animation: _particleController,
            color: widget.achievement.iconColor,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  String _getAchievementTypeText(AchievementType type) {
    switch (type) {
      case AchievementType.score:
        return 'Single Game Score';
      case AchievementType.totalScore:
        return 'Total Score';
      case AchievementType.gamesPlayed:
        return 'Games Played';
      case AchievementType.pulseUsage:
        return 'Pulse Usage';
      case AchievementType.powerUps:
        return 'Power-ups Collected';
      case AchievementType.survival:
        return 'Survival Time';
    }
  }

  String _getTargetValueText() {
    switch (widget.achievement.type) {
      case AchievementType.score:
      case AchievementType.totalScore:
        return '${widget.achievement.targetValue} points';
      case AchievementType.gamesPlayed:
        return '${widget.achievement.targetValue} games';
      case AchievementType.pulseUsage:
        return '${widget.achievement.targetValue} pulses';
      case AchievementType.powerUps:
        return '${widget.achievement.targetValue} power-ups';
      case AchievementType.survival:
        return '${widget.achievement.targetValue} seconds';
    }
  }
}

/// Custom painter for achievement celebration particles
class AchievementParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  AchievementParticlesPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Create floating particles around the overlay
    for (int i = 0; i < 20; i++) {
      final progress = (animation.value + (i / 20)) % 1.0;
      final angle = (i / 20) * 2 * 3.14159;
      final radius = 100 + (i % 3) * 50;
      
      final x = centerX + radius * 0.8 * progress * (1 + 0.3 * (i % 2));
      final y = centerY + radius * 0.8 * progress * (1 + 0.3 * (i % 2));
      
      paint.color = color.withValues(alpha: 0.3 * (1.0 - progress));
      
      canvas.drawCircle(
        Offset(
          centerX + (x - centerX) * (0.3 + 0.7 * progress),
          centerY + (y - centerY) * (0.3 + 0.7 * progress),
        ),
        2.0 + (i % 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}