import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'obstacle.dart';
import 'bird.dart';
import '../effects/neon_colors.dart';
import '../managers/difficulty_manager.dart';

/// Digital barrier obstacle - basic vertical obstacle with neon glow
class DigitalBarrier extends Obstacle {
  // Barrier properties
  static const double barrierWidth = 60.0;
  static const double gapHeight = 150.0;
  late double topBarrierHeight;
  late double bottomBarrierHeight;
  
  // Movement properties
  static const double moveSpeed = 200.0; // pixels per second
  
  // Visual properties
  static const Color barrierColor = NeonColors.electricBlue;
  static const Color disabledColor = NeonColors.uiDisabled;
  
  // Animation properties
  double animationTime = 0.0;
  
  DigitalBarrier({required Vector2 startPosition, required double worldHeight}) {
    type = ObstacleType.digitalBarrier;
    position = startPosition;
    size = Vector2(barrierWidth, worldHeight);
    
    // Calculate barrier heights with gap in the middle
    _calculateBarrierHeights(worldHeight);
    
    // Set glow color
    glowColor = barrierColor;
  }
  
  /// Calculate top and bottom barrier heights with gap
  void _calculateBarrierHeights(double worldHeight) {
    // Random gap position (keep gap away from edges)
    final minGapY = gapHeight;
    final maxGapY = worldHeight - gapHeight * 2;
    final gapY = minGapY + math.Random().nextDouble() * (maxGapY - minGapY);
    
    topBarrierHeight = gapY;
    bottomBarrierHeight = worldHeight - gapY - gapHeight;
  }
  
  @override
  void moveObstacle(double dt) {
    // Move from right to left
    position.x -= moveSpeed * dt;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update animation time for glow effects
    animationTime += dt;
  }
  
  @override
  bool checkCollision(Bird bird) {
    if (isDisabled) return false;
    
    final birdRect = bird.collisionRect;
    
    // Check collision with top barrier
    final topBarrierRect = Rect.fromLTWH(
      position.x,
      0,
      barrierWidth,
      topBarrierHeight,
    );
    
    // Check collision with bottom barrier
    final bottomBarrierRect = Rect.fromLTWH(
      position.x,
      position.y + size.y - bottomBarrierHeight,
      barrierWidth,
      bottomBarrierHeight,
    );
    
    return birdRect.overlaps(topBarrierRect) || birdRect.overlaps(bottomBarrierRect);
  }
  
  @override
  Rect get collisionRect {
    // Return combined collision area (this is used for general collision checks)
    return Rect.fromLTWH(
      position.x,
      position.y,
      size.x,
      size.y,
    );
  }
  
  /// Get top barrier collision rectangle
  Rect get topBarrierRect {
    return Rect.fromLTWH(
      position.x,
      0,
      barrierWidth,
      topBarrierHeight,
    );
  }
  
  /// Get bottom barrier collision rectangle
  Rect get bottomBarrierRect {
    return Rect.fromLTWH(
      position.x,
      position.y + size.y - bottomBarrierHeight,
      barrierWidth,
      bottomBarrierHeight,
    );
  }
  
  /// Get gap rectangle (for visual debugging)
  Rect get gapRect {
    return Rect.fromLTWH(
      position.x,
      topBarrierHeight,
      barrierWidth,
      gapHeight,
    );
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Determine colors based on disabled state
    final currentColor = isDisabled ? disabledColor : barrierColor;
    
    // Simple animated color (much less computation)
    final pulseIntensity = 0.8 + 0.2 * math.sin(animationTime * 2.0);
    final animatedColor = Color.lerp(currentColor, currentColor.withOpacity(0.6), 1.0 - pulseIntensity) ?? currentColor;
    
    // Draw top barrier
    final topBarrierRect = Rect.fromLTWH(0, -position.y, barrierWidth, topBarrierHeight);
    _drawSimpleBarrier(canvas, topBarrierRect, animatedColor);
    
    // Draw bottom barrier
    final bottomBarrierRect = Rect.fromLTWH(
      0, 
      size.y - bottomBarrierHeight - position.y, 
      barrierWidth, 
      bottomBarrierHeight
    );
    _drawSimpleBarrier(canvas, bottomBarrierRect, animatedColor);
  }
  
  /// Draw a simple, performance-optimized barrier
  void _drawSimpleBarrier(Canvas canvas, Rect barrierRect, Color color) {
    // Single glow layer (much more efficient)
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8.0);
    
    canvas.drawRect(barrierRect, glowPaint);
    
    // Main barrier
    final barrierPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(barrierRect, barrierPaint);
    
    // Simple outline
    final outlinePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawRect(barrierRect, outlinePaint);
  }
}