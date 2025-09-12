import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'obstacle.dart';
import 'bird.dart';
import '../effects/neon_colors.dart';
import '../managers/difficulty_manager.dart';

/// Laser grid obstacle - horizontal laser beams with neon effects
class LaserGrid extends Obstacle {
  // Grid properties
  static const double gridWidth = 80.0;
  static const int laserCount = 3; // Number of horizontal laser beams
  static const double laserThickness = 4.0;
  static const double laserSpacing = 60.0; // Space between lasers
  
  // Movement properties
  static const double moveSpeed = 180.0; // Slightly slower than digital barriers
  
  // Visual properties
  static const Color laserColor = NeonColors.hotPink;
  static const Color disabledColor = NeonColors.uiDisabled;
  
  // Animation properties
  double animationTime = 0.0;
  double pulsePhase = 0.0;
  
  // Laser positions
  late List<double> laserYPositions;
  
  LaserGrid({
    required Vector2 startPosition, 
    required double worldHeight,
    double gapSizeMultiplier = 1.0,
  }) {
    type = ObstacleType.laserGrid;
    position = startPosition;
    size = Vector2(gridWidth, worldHeight);
    
    // Calculate laser positions with gap size multiplier
    _calculateLaserPositions(worldHeight, gapSizeMultiplier);
    
    // Set glow color
    glowColor = laserColor;
    
    // Random pulse phase for variety
    pulsePhase = math.Random().nextDouble() * math.pi * 2;
  }
  
  /// Calculate positions for horizontal laser beams
  void _calculateLaserPositions(double worldHeight, double gapSizeMultiplier) {
    laserYPositions = [];
    
    // Adjust spacing based on gap size multiplier
    final adjustedSpacing = laserSpacing * gapSizeMultiplier;
    
    // Create gaps between lasers that the bird can fly through
    final totalLaserSpace = (laserCount - 1) * adjustedSpacing;
    final startY = (worldHeight - totalLaserSpace) / 2;
    
    for (int i = 0; i < laserCount; i++) {
      final laserY = startY + i * adjustedSpacing;
      laserYPositions.add(laserY);
    }
  }
  
  @override
  void moveObstacle(double dt) {
    // Move from right to left
    position.x -= moveSpeed * dt;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update animation time for laser effects
    animationTime += dt;
  }
  
  @override
  bool checkCollision(Bird bird) {
    if (isDisabled) return false;
    
    final birdRect = bird.collisionRect;
    
    // Check collision with each laser beam
    for (final laserY in laserYPositions) {
      final laserRect = Rect.fromLTWH(
        position.x,
        laserY - laserThickness / 2,
        gridWidth,
        laserThickness,
      );
      
      if (birdRect.overlaps(laserRect)) {
        return true;
      }
    }
    
    return false;
  }
  
  @override
  Rect get collisionRect {
    // Return bounding box of entire laser grid
    return Rect.fromLTWH(
      position.x,
      position.y,
      size.x,
      size.y,
    );
  }
  
  /// Get collision rectangles for all laser beams
  List<Rect> get laserRects {
    return laserYPositions.map((laserY) {
      return Rect.fromLTWH(
        position.x,
        laserY - laserThickness / 2,
        gridWidth,
        laserThickness,
      );
    }).toList();
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Determine colors based on disabled state
    final currentColor = isDisabled ? disabledColor : laserColor;
    
    // Animated pulse effect
    final pulseIntensity = 0.6 + 0.4 * math.sin(animationTime * 4.0 + pulsePhase);
    final animatedColor = Color.lerp(
      currentColor.withOpacity(0.4), 
      currentColor, 
      pulseIntensity
    ) ?? currentColor;
    
    // Draw each laser beam
    for (int i = 0; i < laserYPositions.length; i++) {
      final laserY = laserYPositions[i] - position.y;
      _drawLaserBeam(canvas, laserY, animatedColor, i);
    }
    
    // Draw laser grid frame
    _drawGridFrame(canvas, currentColor);
  }
  
  /// Draw a single laser beam with neon effects
  void _drawLaserBeam(Canvas canvas, double laserY, Color color, int index) {
    final laserRect = Rect.fromLTWH(
      0,
      laserY - laserThickness / 2,
      gridWidth,
      laserThickness,
    );
    
    // Outer glow effect
    final outerGlowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12.0);
    
    final outerGlowRect = Rect.fromLTWH(
      laserRect.left - 6,
      laserRect.top - 6,
      laserRect.width + 12,
      laserRect.height + 12,
    );
    canvas.drawRect(outerGlowRect, outerGlowPaint);
    
    // Inner glow effect
    final innerGlowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6.0);
    
    final innerGlowRect = Rect.fromLTWH(
      laserRect.left - 3,
      laserRect.top - 3,
      laserRect.width + 6,
      laserRect.height + 6,
    );
    canvas.drawRect(innerGlowRect, innerGlowPaint);
    
    // Main laser beam
    final laserPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(laserRect, laserPaint);
    
    // Core bright line
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    final coreRect = Rect.fromLTWH(
      laserRect.left,
      laserRect.center.dy - 1,
      laserRect.width,
      2,
    );
    canvas.drawRect(coreRect, corePaint);
    
    // Animated sparks along the laser
    _drawLaserSparks(canvas, laserRect, color, index);
  }
  
  /// Draw animated sparks along the laser beam
  void _drawLaserSparks(Canvas canvas, Rect laserRect, Color color, int laserIndex) {
    final sparkCount = 3;
    final sparkSize = 3.0;
    
    for (int i = 0; i < sparkCount; i++) {
      // Animated position along the laser
      final progress = (animationTime * 2.0 + laserIndex * 0.5 + i * 0.3) % 1.0;
      final sparkX = laserRect.left + progress * laserRect.width;
      final sparkY = laserRect.center.dy;
      
      // Spark opacity based on position
      final opacity = math.sin(progress * math.pi);
      
      final sparkPaint = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(sparkX, sparkY),
        sparkSize,
        sparkPaint,
      );
    }
  }
  
  /// Draw the laser grid frame structure
  void _drawGridFrame(Canvas canvas, Color color) {
    final framePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Left frame edge
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, size.y),
      framePaint,
    );
    
    // Right frame edge
    canvas.drawLine(
      Offset(gridWidth, 0),
      Offset(gridWidth, size.y),
      framePaint,
    );
    
    // Connection points for lasers
    for (final laserY in laserYPositions) {
      final adjustedY = laserY - position.y;
      
      // Left connection
      canvas.drawCircle(
        Offset(0, adjustedY),
        4.0,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      
      // Right connection
      canvas.drawCircle(
        Offset(gridWidth, adjustedY),
        4.0,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }
}