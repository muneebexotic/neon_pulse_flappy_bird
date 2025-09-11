import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'obstacle.dart';
import 'bird.dart';
import '../effects/neon_colors.dart';

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
    final currentGlowIntensity = isDisabled ? 0.2 : glowIntensity;
    
    // Get animated color for pulsing effect
    final animatedColor = NeonColors.getAnimatedColor(
      currentColor,
      animationTime,
      minIntensity: 0.7,
      maxIntensity: 1.0,
    );
    
    // Draw top barrier
    final topBarrierRect = Rect.fromLTWH(0, -position.y, barrierWidth, topBarrierHeight);
    _drawNeonBarrier(canvas, topBarrierRect, animatedColor, currentGlowIntensity);
    
    // Draw bottom barrier
    final bottomBarrierRect = Rect.fromLTWH(
      0, 
      size.y - bottomBarrierHeight - position.y, 
      barrierWidth, 
      bottomBarrierHeight
    );
    _drawNeonBarrier(canvas, bottomBarrierRect, animatedColor, currentGlowIntensity);
    
    // Draw digital grid pattern on barriers
    _drawDigitalPattern(canvas, topBarrierRect, animatedColor);
    _drawDigitalPattern(canvas, bottomBarrierRect, animatedColor);
    
    // Draw neon edges
    _drawNeonEdges(canvas, topBarrierRect, animatedColor);
    _drawNeonEdges(canvas, bottomBarrierRect, animatedColor);
  }
  
  /// Draw a neon barrier with multiple glow layers
  void _drawNeonBarrier(Canvas canvas, Rect barrierRect, Color color, double glowIntensity) {
    // Animate glow intensity
    final animatedGlowIntensity = glowIntensity * 
        (0.6 + 0.4 * math.sin(animationTime * 2.5));
    
    // Draw multiple glow layers for depth
    _drawGlowLayer(canvas, barrierRect, color, 20.0, 0.05 * animatedGlowIntensity);
    _drawGlowLayer(canvas, barrierRect, color, 15.0, 0.1 * animatedGlowIntensity);
    _drawGlowLayer(canvas, barrierRect, color, 10.0, 0.2 * animatedGlowIntensity);
    _drawGlowLayer(canvas, barrierRect, color, 5.0, 0.4 * animatedGlowIntensity);
    
    // Draw main barrier
    final barrierPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(barrierRect, barrierPaint);
  }
  
  /// Draw a single glow layer
  void _drawGlowLayer(Canvas canvas, Rect rect, Color color, double blurRadius, double opacity) {
    final glowPaint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, blurRadius);
    
    canvas.drawRect(rect, glowPaint);
  }
  
  /// Draw neon edges around barriers
  void _drawNeonEdges(Canvas canvas, Rect barrierRect, Color color) {
    final edgePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Draw glowing outline
    final glowEdgePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3.0);
    
    canvas.drawRect(barrierRect, glowEdgePaint);
    canvas.drawRect(barrierRect, edgePaint);
  }
  
  /// Draw digital grid pattern on barrier surface
  void _drawDigitalPattern(Canvas canvas, Rect barrierRect, Color color) {
    final patternOpacity = 0.2 + 0.1 * math.sin(animationTime * 4.0);
    
    final patternPaint = Paint()
      ..color = color.withOpacity(patternOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    final glowPatternPaint = Paint()
      ..color = color.withOpacity(patternOpacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 1.0);
    
    // Draw animated vertical lines
    for (double x = 0; x < barrierRect.width; x += 12) {
      final lineOpacity = 0.5 + 0.5 * math.sin(animationTime * 3.0 + x * 0.1);
      
      final animatedPaint = Paint()
        ..color = color.withOpacity(patternOpacity * lineOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawLine(
        Offset(barrierRect.left + x, barrierRect.top),
        Offset(barrierRect.left + x, barrierRect.bottom),
        glowPatternPaint,
      );
      
      canvas.drawLine(
        Offset(barrierRect.left + x, barrierRect.top),
        Offset(barrierRect.left + x, barrierRect.bottom),
        animatedPaint,
      );
    }
    
    // Draw animated horizontal lines
    for (double y = 0; y < barrierRect.height; y += 12) {
      final lineOpacity = 0.5 + 0.5 * math.sin(animationTime * 2.5 + y * 0.1);
      
      final animatedPaint = Paint()
        ..color = color.withOpacity(patternOpacity * lineOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawLine(
        Offset(barrierRect.left, barrierRect.top + y),
        Offset(barrierRect.right, barrierRect.top + y),
        glowPatternPaint,
      );
      
      canvas.drawLine(
        Offset(barrierRect.left, barrierRect.top + y),
        Offset(barrierRect.right, barrierRect.top + y),
        animatedPaint,
      );
    }
    
    // Draw corner highlights
    _drawCornerHighlights(canvas, barrierRect, color);
  }
  
  /// Draw glowing corner highlights
  void _drawCornerHighlights(Canvas canvas, Rect barrierRect, Color color) {
    final cornerSize = 8.0;
    final cornerOpacity = 0.6 + 0.4 * math.sin(animationTime * 3.5);
    
    final cornerPaint = Paint()
      ..color = color.withOpacity(cornerOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final glowCornerPaint = Paint()
      ..color = color.withOpacity(cornerOpacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 2.0);
    
    // Top-left corner
    canvas.drawLine(
      Offset(barrierRect.left, barrierRect.top),
      Offset(barrierRect.left + cornerSize, barrierRect.top),
      glowCornerPaint,
    );
    canvas.drawLine(
      Offset(barrierRect.left, barrierRect.top),
      Offset(barrierRect.left, barrierRect.top + cornerSize),
      glowCornerPaint,
    );
    
    canvas.drawLine(
      Offset(barrierRect.left, barrierRect.top),
      Offset(barrierRect.left + cornerSize, barrierRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(barrierRect.left, barrierRect.top),
      Offset(barrierRect.left, barrierRect.top + cornerSize),
      cornerPaint,
    );
    
    // Top-right corner
    canvas.drawLine(
      Offset(barrierRect.right, barrierRect.top),
      Offset(barrierRect.right - cornerSize, barrierRect.top),
      glowCornerPaint,
    );
    canvas.drawLine(
      Offset(barrierRect.right, barrierRect.top),
      Offset(barrierRect.right, barrierRect.top + cornerSize),
      glowCornerPaint,
    );
    
    canvas.drawLine(
      Offset(barrierRect.right, barrierRect.top),
      Offset(barrierRect.right - cornerSize, barrierRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(barrierRect.right, barrierRect.top),
      Offset(barrierRect.right, barrierRect.top + cornerSize),
      cornerPaint,
    );
  }
}