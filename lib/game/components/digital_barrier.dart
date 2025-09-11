import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'obstacle.dart';
import 'bird.dart';

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
  static const Color barrierColor = Color(0xFF00FFFF); // Electric blue
  static const Color disabledColor = Color(0xFF333333); // Dark gray
  
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
    final currentGlowIntensity = isDisabled ? 0.2 : glowIntensity;
    
    // Create paint for barriers with glow effect
    final barrierPaint = Paint()
      ..color = currentColor
      ..style = PaintingStyle.fill;
    
    // Create glow paint
    final glowPaint = Paint()
      ..color = currentColor.withOpacity(0.3 * currentGlowIntensity)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 8.0 * currentGlowIntensity);
    
    // Animate glow intensity
    final animatedGlowIntensity = currentGlowIntensity * 
        (0.8 + 0.2 * math.sin(animationTime * 3.0));
    
    final animatedGlowPaint = Paint()
      ..color = currentColor.withOpacity(0.2 * animatedGlowIntensity)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 12.0 * animatedGlowIntensity);
    
    // Draw top barrier
    final topBarrierRect = Rect.fromLTWH(0, -position.y, barrierWidth, topBarrierHeight);
    
    // Draw glow effects for top barrier
    canvas.drawRect(topBarrierRect, animatedGlowPaint);
    canvas.drawRect(topBarrierRect, glowPaint);
    
    // Draw main top barrier
    canvas.drawRect(topBarrierRect, barrierPaint);
    
    // Draw bottom barrier
    final bottomBarrierRect = Rect.fromLTWH(
      0, 
      size.y - bottomBarrierHeight - position.y, 
      barrierWidth, 
      bottomBarrierHeight
    );
    
    // Draw glow effects for bottom barrier
    canvas.drawRect(bottomBarrierRect, animatedGlowPaint);
    canvas.drawRect(bottomBarrierRect, glowPaint);
    
    // Draw main bottom barrier
    canvas.drawRect(bottomBarrierRect, barrierPaint);
    
    // Draw digital grid pattern on barriers
    _drawDigitalPattern(canvas, topBarrierRect, currentColor);
    _drawDigitalPattern(canvas, bottomBarrierRect, currentColor);
  }
  
  /// Draw digital grid pattern on barrier surface
  void _drawDigitalPattern(Canvas canvas, Rect barrierRect, Color color) {
    final patternPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw vertical lines
    for (double x = 0; x < barrierRect.width; x += 10) {
      canvas.drawLine(
        Offset(barrierRect.left + x, barrierRect.top),
        Offset(barrierRect.left + x, barrierRect.bottom),
        patternPaint,
      );
    }
    
    // Draw horizontal lines
    for (double y = 0; y < barrierRect.height; y += 10) {
      canvas.drawLine(
        Offset(barrierRect.left, barrierRect.top + y),
        Offset(barrierRect.right, barrierRect.top + y),
        patternPaint,
      );
    }
  }
}