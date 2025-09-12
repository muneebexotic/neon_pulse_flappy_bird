import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../effects/neon_colors.dart';
import '../neon_pulse_game.dart';

/// Visual effect component for the energy pulse mechanic
class PulseEffect extends PositionComponent {
  // Pulse properties
  double radius = 0.0;
  double maxRadius;
  double duration;
  double elapsedTime = 0.0;
  bool isActive = false;
  
  // Visual properties
  Color pulseColor;
  double opacity = 1.0;
  
  // Animation properties
  late AnimationController? animationController;
  
  PulseEffect({
    required Vector2 center,
    required this.maxRadius,
    required this.duration,
    this.pulseColor = NeonColors.electricBlue,
  }) {
    position = center;
    size = Vector2(maxRadius * 2, maxRadius * 2);
  }
  
  /// Start the pulse animation
  void activate() {
    isActive = true;
    elapsedTime = 0.0;
    radius = 0.0;
    opacity = 1.0;
  }
  
  /// Stop the pulse animation
  void deactivate() {
    isActive = false;
    elapsedTime = 0.0;
    radius = 0.0;
    opacity = 0.0;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (!isActive) return;
    
    // Check if game is paused - don't update if paused
    final game = findGame() as NeonPulseGame?;
    if (game != null && game.gameState.isPaused) {
      return;
    }
    
    elapsedTime += dt;
    
    // Calculate animation progress (0.0 to 1.0)
    final progress = (elapsedTime / duration).clamp(0.0, 1.0);
    
    // Expand radius with easing
    radius = maxRadius * _easeOutCubic(progress);
    
    // Fade out opacity
    opacity = 1.0 - progress;
    
    // Check if animation is complete
    if (progress >= 1.0) {
      deactivate();
      removeFromParent();
    }
  }
  
  /// Cubic ease-out function for smooth animation
  double _easeOutCubic(double t) {
    return 1.0 - math.pow(1.0 - t, 3.0);
  }
  
  /// Check if a point is within the current pulse radius
  bool containsPoint(Vector2 point) {
    if (!isActive) return false;
    
    final center = Vector2(position.x, position.y);
    final distance = center.distanceTo(point);
    return distance <= radius;
  }
  
  /// Get current pulse radius
  double get currentRadius => radius;
  
  /// Check if pulse is currently active
  bool get active => isActive;
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    if (!isActive || opacity <= 0.0) return;
    
    // Simple, performance-optimized pulse rendering
    _drawSimplePulse(canvas);
  }
  
  /// Draw a simple, performance-optimized pulse
  void _drawSimplePulse(Canvas canvas) {
    // Single glow layer
    final glowPaint = Paint()
      ..color = pulseColor.withOpacity(opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10.0);
    
    canvas.drawCircle(Offset.zero, radius, glowPaint);
    
    // Main pulse ring
    final pulsePaint = Paint()
      ..color = pulseColor.withOpacity(opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawCircle(Offset.zero, radius, pulsePaint);
  }
}