import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'obstacle.dart';
import 'bird.dart';
import '../effects/neon_colors.dart';
import '../managers/difficulty_manager.dart';

/// Floating platform obstacle - moving platforms with vertical movement patterns
class FloatingPlatform extends Obstacle {
  // Platform properties
  static const double platformWidth = 100.0;
  static const double platformHeight = 20.0;
  static const int platformCount = 2; // Number of platforms in the obstacle
  
  // Movement properties
  static const double moveSpeed = 160.0; // Slower horizontal movement
  static const double verticalSpeed = 50.0; // Vertical oscillation speed
  static const double verticalRange = 80.0; // How far platforms move vertically
  
  // Visual properties
  static const Color platformColor = NeonColors.neonGreen;
  static const Color disabledColor = NeonColors.uiDisabled;
  
  // Animation properties
  double animationTime = 0.0;
  double verticalPhase = 0.0;
  
  // Platform data
  late List<PlatformData> platforms;
  
  FloatingPlatform({
    required Vector2 startPosition, 
    required double worldHeight,
    double gapSizeMultiplier = 1.0,
  }) {
    type = ObstacleType.floatingPlatform;
    position = startPosition;
    size = Vector2(platformWidth, worldHeight);
    
    // Initialize platforms with gap size multiplier
    _initializePlatforms(worldHeight, gapSizeMultiplier);
    
    // Set glow color
    glowColor = platformColor;
    
    // Random vertical phase for variety
    verticalPhase = math.Random().nextDouble() * math.pi * 2;
  }
  
  /// Initialize platform positions and movement patterns
  void _initializePlatforms(double worldHeight, double gapSizeMultiplier) {
    platforms = [];
    
    // Adjust gap between platforms based on multiplier
    final baseGap = 120.0;
    final adjustedGap = baseGap * gapSizeMultiplier;
    
    // Create platforms with gaps between them
    final totalPlatformSpace = platformCount * platformHeight + (platformCount - 1) * adjustedGap;
    final startY = (worldHeight - totalPlatformSpace) / 2;
    
    for (int i = 0; i < platformCount; i++) {
      final baseY = startY + i * (platformHeight + adjustedGap);
      
      // Each platform has different movement pattern
      final movementPhase = i * math.pi; // Opposite phases for interesting patterns
      final movementSpeed = 1.0 + i * 0.3; // Slightly different speeds
      
      platforms.add(PlatformData(
        baseY: baseY,
        currentY: baseY,
        movementPhase: movementPhase,
        movementSpeed: movementSpeed,
      ));
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
    
    // Update animation time
    animationTime += dt;
    
    // Update platform vertical positions
    for (final platform in platforms) {
      final oscillation = math.sin(
        animationTime * platform.movementSpeed + 
        platform.movementPhase + 
        verticalPhase
      );
      
      platform.currentY = platform.baseY + oscillation * verticalRange;
    }
  }
  
  @override
  bool checkCollision(Bird bird) {
    if (isDisabled) return false;
    
    final birdRect = bird.collisionRect;
    
    // Check collision with each platform
    for (final platform in platforms) {
      final platformRect = Rect.fromLTWH(
        position.x,
        platform.currentY,
        platformWidth,
        platformHeight,
      );
      
      if (birdRect.overlaps(platformRect)) {
        return true;
      }
    }
    
    return false;
  }
  
  @override
  Rect get collisionRect {
    // Return bounding box of entire platform system
    return Rect.fromLTWH(
      position.x,
      position.y,
      size.x,
      size.y,
    );
  }
  
  /// Get collision rectangles for all platforms
  List<Rect> get platformRects {
    return platforms.map((platform) {
      return Rect.fromLTWH(
        position.x,
        platform.currentY,
        platformWidth,
        platformHeight,
      );
    }).toList();
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Determine colors based on disabled state
    final currentColor = isDisabled ? disabledColor : platformColor;
    
    // Draw each platform
    for (int i = 0; i < platforms.length; i++) {
      final platform = platforms[i];
      final platformY = platform.currentY - position.y;
      
      _drawPlatform(canvas, platformY, currentColor, i);
    }
    
    // Draw connection beams between platforms
    _drawConnectionBeams(canvas, currentColor);
  }
  
  /// Draw a single floating platform with neon effects
  void _drawPlatform(Canvas canvas, double platformY, Color color, int index) {
    final platformRect = Rect.fromLTWH(
      0,
      platformY,
      platformWidth,
      platformHeight,
    );
    
    // Animated pulse effect
    final pulseIntensity = 0.7 + 0.3 * math.sin(animationTime * 3.0 + index * 0.8);
    final animatedColor = Color.lerp(
      color.withOpacity(0.5), 
      color, 
      pulseIntensity
    ) ?? color;
    
    // Outer glow effect
    final outerGlowPaint = Paint()
      ..color = animatedColor.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10.0);
    
    final outerGlowRect = Rect.fromLTWH(
      platformRect.left - 5,
      platformRect.top - 5,
      platformRect.width + 10,
      platformRect.height + 10,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outerGlowRect, const Radius.circular(8.0)),
      outerGlowPaint,
    );
    
    // Inner glow effect
    final innerGlowPaint = Paint()
      ..color = animatedColor.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4.0);
    
    final innerGlowRect = Rect.fromLTWH(
      platformRect.left - 2,
      platformRect.top - 2,
      platformRect.width + 4,
      platformRect.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerGlowRect, const Radius.circular(6.0)),
      innerGlowPaint,
    );
    
    // Main platform body
    final platformPaint = Paint()
      ..color = animatedColor
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(platformRect, const Radius.circular(4.0)),
      platformPaint,
    );
    
    // Platform surface highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    
    final highlightRect = Rect.fromLTWH(
      platformRect.left + 2,
      platformRect.top + 1,
      platformRect.width - 4,
      3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, const Radius.circular(2.0)),
      highlightPaint,
    );
    
    // Platform edge details
    _drawPlatformDetails(canvas, platformRect, animatedColor);
  }
  
  /// Draw platform edge details and energy effects
  void _drawPlatformDetails(Canvas canvas, Rect platformRect, Color color) {
    // Energy nodes on platform edges
    final nodeSize = 3.0;
    final nodeCount = 3;
    
    for (int i = 0; i < nodeCount; i++) {
      final progress = (i + 1) / (nodeCount + 1);
      final nodeX = platformRect.left + progress * platformRect.width;
      
      // Top edge nodes
      final topNodePaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(nodeX, platformRect.top),
        nodeSize,
        topNodePaint,
      );
      
      // Bottom edge nodes
      canvas.drawCircle(
        Offset(nodeX, platformRect.bottom),
        nodeSize,
        topNodePaint,
      );
    }
    
    // Side energy trails
    final trailPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Left trail
    canvas.drawLine(
      Offset(platformRect.left - 10, platformRect.center.dy),
      Offset(platformRect.left, platformRect.center.dy),
      trailPaint,
    );
    
    // Right trail
    canvas.drawLine(
      Offset(platformRect.right, platformRect.center.dy),
      Offset(platformRect.right + 10, platformRect.center.dy),
      trailPaint,
    );
  }
  
  /// Draw connection beams between platforms
  void _drawConnectionBeams(Canvas canvas, Color color) {
    if (platforms.length < 2) return;
    
    final beamPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Draw beams between consecutive platforms
    for (int i = 0; i < platforms.length - 1; i++) {
      final platform1 = platforms[i];
      final platform2 = platforms[i + 1];
      
      final y1 = platform1.currentY - position.y + platformHeight / 2;
      final y2 = platform2.currentY - position.y + platformHeight / 2;
      
      // Animated beam effect
      final beamIntensity = 0.3 + 0.2 * math.sin(animationTime * 2.0 + i);
      final animatedBeamPaint = Paint()
        ..color = color.withOpacity(beamIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      canvas.drawLine(
        Offset(platformWidth / 2, y1),
        Offset(platformWidth / 2, y2),
        animatedBeamPaint,
      );
    }
  }
}

/// Data class to track individual platform state
class PlatformData {
  final double baseY; // Original Y position
  double currentY; // Current Y position (with movement)
  final double movementPhase; // Phase offset for movement
  final double movementSpeed; // Speed multiplier for movement
  
  PlatformData({
    required this.baseY,
    required this.currentY,
    required this.movementPhase,
    required this.movementSpeed,
  });
}