import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../models/achievement.dart';
import '../../models/progression_path_models.dart';
import '../../game/managers/haptic_manager.dart';
import '../theme/neon_theme.dart';

/// Interactive achievement node widget with visual states and neon effects
class AchievementNode extends StatefulWidget {
  final Achievement achievement;
  final NodeVisualState visualState;
  final VoidCallback? onTap;
  final double size;
  final bool showProgressRing;
  final bool enableAnimations;

  const AchievementNode({
    Key? key,
    required this.achievement,
    required this.visualState,
    this.onTap,
    this.size = 44.0, // Minimum touch target size for accessibility
    this.showProgressRing = true,
    this.enableAnimations = true,
  }) : super(key: key);

  @override
  State<AchievementNode> createState() => _AchievementNodeState();
}

class _AchievementNodeState extends State<AchievementNode>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _progressController;
  late AnimationController _unlockController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _unlockAnimation;
  
  bool _isPressed = false;
  final HapticManager _hapticManager = HapticManager();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationsBasedOnState();
  }

  void _initializeAnimations() {
    // Pulse animation for in-progress nodes
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Glow animation for unlocked nodes
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Progress ring animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: widget.enableAnimations ? 0.0 : widget.achievement.progressPercentage,
      end: widget.achievement.progressPercentage,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    // Unlock celebration animation
    _unlockController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _unlockAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _unlockController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimationsBasedOnState() {
    switch (widget.visualState) {
      case NodeVisualState.inProgress:
        if (widget.enableAnimations) {
          _pulseController.repeat(reverse: true);
          _progressController.forward();
        } else {
          // Set progress immediately when animations are disabled
          _progressController.value = 1.0;
        }
        break;
      case NodeVisualState.unlocked:
      case NodeVisualState.rewardAvailable:
        if (widget.enableAnimations) {
          _glowController.repeat(reverse: true);
          _unlockController.forward();
        } else {
          // Set unlock state immediately when animations are disabled
          _unlockController.value = 1.0;
        }
        break;
      case NodeVisualState.locked:
        // No animations for locked state
        break;
    }
  }

  @override
  void didUpdateWidget(AchievementNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.visualState != widget.visualState) {
      _stopAllAnimations();
      _startAnimationsBasedOnState();
    }
    
    if (oldWidget.achievement.progressPercentage != widget.achievement.progressPercentage) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.achievement.progressPercentage,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ));
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _stopAllAnimations() {
    _pulseController.stop();
    _glowController.stop();
    _progressController.stop();
    _unlockController.stop();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _progressController.dispose();
    _unlockController.dispose();
    super.dispose();
  }

  Color _getNodeColor() {
    switch (widget.visualState) {
      case NodeVisualState.locked:
        return NeonTheme.textSecondary.withOpacity(0.3);
      case NodeVisualState.inProgress:
        return widget.achievement.iconColor.withOpacity(0.7);
      case NodeVisualState.unlocked:
        return widget.achievement.iconColor;
      case NodeVisualState.rewardAvailable:
        return NeonTheme.warningOrange;
    }
  }

  Color _getGlowColor() {
    switch (widget.visualState) {
      case NodeVisualState.locked:
        return Colors.transparent;
      case NodeVisualState.inProgress:
        return widget.achievement.iconColor.withOpacity(0.4);
      case NodeVisualState.unlocked:
        return widget.achievement.iconColor.withOpacity(0.6);
      case NodeVisualState.rewardAvailable:
        return NeonTheme.warningOrange.withOpacity(0.8);
    }
  }

  double _getOpacity() {
    switch (widget.visualState) {
      case NodeVisualState.locked:
        return 0.4;
      case NodeVisualState.inProgress:
        return 0.8;
      case NodeVisualState.unlocked:
      case NodeVisualState.rewardAvailable:
        return 1.0;
    }
  }

  void _handleTap() {
    if (widget.onTap != null) {
      _hapticManager.selectionClick();
      widget.onTap!();
    }
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _hapticManager.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseAnimation,
          _glowAnimation,
          _progressAnimation,
          _unlockAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? 0.95 : 1.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background glow effect
                  _buildGlowEffect(),
                  
                  // Progress ring
                  if (widget.showProgressRing && 
                      widget.visualState == NodeVisualState.inProgress)
                    _buildProgressRing(),
                  
                  // Main node circle
                  _buildMainNode(),
                  
                  // Achievement icon
                  _buildIcon(),
                  
                  // Completion indicator
                  if (widget.visualState == NodeVisualState.unlocked ||
                      widget.visualState == NodeVisualState.rewardAvailable)
                    _buildCompletionIndicator(),
                  
                  // Reward indicator
                  if (widget.visualState == NodeVisualState.rewardAvailable)
                    _buildRewardIndicator(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlowEffect() {
    final glowColor = _getGlowColor();
    if (glowColor == Colors.transparent) return const SizedBox.shrink();

    double glowIntensity = 1.0;
    if (widget.visualState == NodeVisualState.unlocked ||
        widget.visualState == NodeVisualState.rewardAvailable) {
      glowIntensity = _glowAnimation.value;
    } else if (widget.visualState == NodeVisualState.inProgress) {
      glowIntensity = _pulseAnimation.value * 0.5;
    }

    return Container(
      width: widget.size * 1.5,
      height: widget.size * 1.5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.3 * glowIntensity),
            blurRadius: 20.0 * glowIntensity,
            spreadRadius: 5.0 * glowIntensity,
          ),
          BoxShadow(
            color: glowColor.withOpacity(0.1 * glowIntensity),
            blurRadius: 40.0 * glowIntensity,
            spreadRadius: 10.0 * glowIntensity,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing() {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: ProgressRingPainter(
        progress: _progressAnimation.value,
        color: widget.achievement.iconColor,
        strokeWidth: 3.0,
      ),
    );
  }

  Widget _buildMainNode() {
    double scale = 1.0;
    if (widget.visualState == NodeVisualState.inProgress) {
      scale = _pulseAnimation.value;
    } else if (widget.visualState == NodeVisualState.unlocked ||
               widget.visualState == NodeVisualState.rewardAvailable) {
      scale = _unlockAnimation.value;
    }

    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.size * 0.8,
        height: widget.size * 0.8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: NeonTheme.charcoal.withOpacity(_getOpacity()),
          border: Border.all(
            color: _getNodeColor(),
            width: 2.0,
          ),
          boxShadow: widget.visualState != NodeVisualState.locked
              ? [
                  BoxShadow(
                    color: _getNodeColor().withOpacity(0.3),
                    blurRadius: 8.0,
                    spreadRadius: 1.0,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Opacity(
      opacity: _getOpacity(),
      child: Icon(
        widget.achievement.icon,
        size: widget.size * 0.4,
        color: _getNodeColor(),
      ),
    );
  }

  Widget _buildCompletionIndicator() {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Transform.scale(
        scale: _unlockAnimation.value,
        child: Container(
          width: widget.size * 0.3,
          height: widget.size * 0.3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: NeonTheme.successNeon,
            border: Border.all(
              color: NeonTheme.backgroundColor,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: NeonTheme.successNeon.withOpacity(0.5),
                blurRadius: 6.0,
                spreadRadius: 1.0,
              ),
            ],
          ),
          child: Icon(
            Icons.check,
            size: widget.size * 0.15,
            color: NeonTheme.backgroundColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRewardIndicator() {
    return Positioned(
      top: 0,
      right: 0,
      child: Transform.scale(
        scale: _unlockAnimation.value,
        child: Container(
          width: widget.size * 0.25,
          height: widget.size * 0.25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: NeonTheme.warningOrange,
            border: Border.all(
              color: NeonTheme.backgroundColor,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: NeonTheme.warningOrange.withOpacity(0.6),
                blurRadius: 8.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: Icon(
            Icons.star,
            size: widget.size * 0.12,
            color: NeonTheme.backgroundColor,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for drawing progress rings around achievement nodes
class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  ProgressRingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    // Background ring
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress ring
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Add glow effect
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..strokeWidth = strokeWidth + 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      final sweepAngle = 2 * math.pi * progress;
      const startAngle = -math.pi / 2; // Start from top

      // Draw glow
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );

      // Draw progress
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}