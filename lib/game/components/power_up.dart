import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../effects/neon_colors.dart';
import 'bird.dart';
import '../neon_pulse_game.dart';

/// Enum for different power-up types
enum PowerUpType {
  shield,
  scoreMultiplier,
  slowMotion,
}

/// Base class for all power-ups in the game
abstract class PowerUp extends PositionComponent {
  // Power-up properties
  final PowerUpType type;
  final double duration;
  bool isCollected = false;
  bool shouldRemove = false;
  
  // Visual properties
  static const double powerUpSize = 30.0;
  late Color glowColor;
  late Color coreColor;
  
  // Animation properties
  double animationTime = 0.0;
  double floatOffset = 0.0;
  double rotationAngle = 0.0;
  
  // Movement properties
  static const double moveSpeed = 150.0; // pixels per second
  
  PowerUp({
    required this.type,
    required this.duration,
    required Vector2 startPosition,
  }) {
    position = startPosition.clone();
    size = Vector2.all(powerUpSize);
    _initializeColors();
  }
  
  /// Initialize colors based on power-up type
  void _initializeColors() {
    switch (type) {
      case PowerUpType.shield:
        glowColor = NeonColors.electricBlue;
        coreColor = Colors.lightBlueAccent;
        break;
      case PowerUpType.scoreMultiplier:
        glowColor = NeonColors.neonGreen;
        coreColor = Colors.greenAccent;
        break;
      case PowerUpType.slowMotion:
        glowColor = NeonColors.hotPink;
        coreColor = Colors.pinkAccent;
        break;
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (isCollected) return;
    
    // Check if game is paused - don't update if paused
    final game = findGame() as NeonPulseGame?;
    if (game != null && game.gameState.isPaused) {
      return;
    }
    
    // Update animation time
    animationTime += dt;
    
    // Move left across the screen
    position.x -= moveSpeed * dt;
    
    // Update floating animation
    floatOffset = math.sin(animationTime * 3.0) * 5.0;
    
    // Update rotation animation
    rotationAngle += dt * 2.0;
    
    // Mark for removal if off-screen
    if (position.x + size.x < 0) {
      shouldRemove = true;
    }
  }
  
  /// Check collision with bird
  bool checkCollision(Bird bird) {
    if (isCollected) return false;
    
    final powerUpRect = Rect.fromLTWH(
      position.x,
      position.y + floatOffset,
      size.x,
      size.y,
    );
    
    final birdRect = bird.collisionRect;
    
    return powerUpRect.overlaps(birdRect);
  }
  
  /// Collect this power-up
  void collect() {
    if (!isCollected) {
      isCollected = true;
      shouldRemove = true;
      debugPrint('Power-up collected: ${type.name}');
    }
  }
  
  /// Get the effect description for UI display
  String get effectDescription;
  
  /// Get the power-up icon character for UI display
  String get iconCharacter;
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    if (isCollected) return;
    
    // Save canvas state
    canvas.save();
    
    // Apply floating offset
    canvas.translate(0, floatOffset);
    
    // Translate to center for rotation
    canvas.translate(size.x / 2, size.y / 2);
    
    // Apply rotation
    canvas.rotate(rotationAngle);
    
    // Draw power-up with neon effects
    _drawPowerUpGlow(canvas);
    _drawPowerUpCore(canvas);
    _drawPowerUpIcon(canvas);
    
    // Restore canvas state
    canvas.restore();
  }
  
  /// Draw the neon glow effect
  void _drawPowerUpGlow(Canvas canvas) {
    final glowIntensity = 0.5 + math.sin(animationTime * 4.0) * 0.3;
    
    // Outer glow
    final outerGlowPaint = Paint()
      ..color = glowColor.withOpacity(glowIntensity * 0.2)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 20.0);
    
    canvas.drawCircle(Offset.zero, size.x * 0.8, outerGlowPaint);
    
    // Inner glow
    final innerGlowPaint = Paint()
      ..color = glowColor.withOpacity(glowIntensity * 0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10.0);
    
    canvas.drawCircle(Offset.zero, size.x * 0.6, innerGlowPaint);
  }
  
  /// Draw the core orb
  void _drawPowerUpCore(Canvas canvas) {
    final coreIntensity = 0.7 + math.sin(animationTime * 5.0) * 0.3;
    
    // Core orb
    final corePaint = Paint()
      ..color = coreColor.withOpacity(coreIntensity)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset.zero, size.x * 0.4, corePaint);
    
    // Core outline
    final outlinePaint = Paint()
      ..color = glowColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(Offset.zero, size.x * 0.4, outlinePaint);
  }
  
  /// Draw the power-up icon (to be implemented by subclasses)
  void _drawPowerUpIcon(Canvas canvas);
}

/// Shield power-up that provides temporary invulnerability
class ShieldPowerUp extends PowerUp {
  ShieldPowerUp({required Vector2 startPosition})
      : super(
          type: PowerUpType.shield,
          duration: 3.0, // 3 seconds of invulnerability
          startPosition: startPosition,
        );
  
  @override
  String get effectDescription => "Invulnerable for 3 seconds";
  
  @override
  String get iconCharacter => "🛡";
  
  @override
  void _drawPowerUpIcon(Canvas canvas) {
    // Draw shield icon using paths
    final shieldPath = Path();
    final shieldSize = size.x * 0.25;
    
    // Create shield shape
    shieldPath.moveTo(0, -shieldSize);
    shieldPath.lineTo(shieldSize * 0.7, -shieldSize * 0.3);
    shieldPath.lineTo(shieldSize * 0.7, shieldSize * 0.3);
    shieldPath.lineTo(0, shieldSize);
    shieldPath.lineTo(-shieldSize * 0.7, shieldSize * 0.3);
    shieldPath.lineTo(-shieldSize * 0.7, -shieldSize * 0.3);
    shieldPath.close();
    
    // Draw shield with glow
    final shieldGlowPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3.0);
    
    canvas.drawPath(shieldPath, shieldGlowPaint);
    
    // Draw shield core
    final shieldPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(shieldPath, shieldPaint);
  }
}

/// Score multiplier power-up that doubles points for a duration
class ScoreMultiplierPowerUp extends PowerUp {
  ScoreMultiplierPowerUp({required Vector2 startPosition})
      : super(
          type: PowerUpType.scoreMultiplier,
          duration: 10.0, // 10 seconds of 2x points
          startPosition: startPosition,
        );
  
  @override
  String get effectDescription => "2x Score for 10 seconds";
  
  @override
  String get iconCharacter => "2x";
  
  @override
  void _drawPowerUpIcon(Canvas canvas) {
    // Draw "2x" text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '2x',
        style: TextStyle(
          color: Colors.white,
          fontSize: size.x * 0.3,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // Draw text with glow
    final textOffset = Offset(
      -textPainter.width / 2,
      -textPainter.height / 2,
    );
    
    // Text glow
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 2.0);
    
    canvas.drawRect(
      Rect.fromLTWH(
        textOffset.dx - 2,
        textOffset.dy - 2,
        textPainter.width + 4,
        textPainter.height + 4,
      ),
      glowPaint,
    );
    
    textPainter.paint(canvas, textOffset);
  }
}

/// Slow motion power-up that reduces game speed
class SlowMotionPowerUp extends PowerUp {
  SlowMotionPowerUp({required Vector2 startPosition})
      : super(
          type: PowerUpType.slowMotion,
          duration: 5.0, // 5 seconds of 50% speed
          startPosition: startPosition,
        );
  
  @override
  String get effectDescription => "Slow Motion for 5 seconds";
  
  @override
  String get iconCharacter => "⏱";
  
  @override
  void _drawPowerUpIcon(Canvas canvas) {
    // Draw clock/time icon
    final clockRadius = size.x * 0.2;
    
    // Clock face
    final clockPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(Offset.zero, clockRadius, clockPaint);
    
    // Clock hands
    final handPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Hour hand
    canvas.drawLine(
      Offset.zero,
      Offset(0, -clockRadius * 0.5),
      handPaint,
    );
    
    // Minute hand
    canvas.drawLine(
      Offset.zero,
      Offset(clockRadius * 0.3, -clockRadius * 0.3),
      handPaint,
    );
    
    // Center dot
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset.zero, 2.0, centerPaint);
  }
}