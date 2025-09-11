import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Bird component that handles player-controlled bird with physics
class Bird extends PositionComponent {
  // Physics constants
  static const double gravity = 980.0; // pixels per second squared
  static const double jumpForce = -350.0; // negative for upward movement
  static const double maxFallSpeed = 400.0; // terminal velocity
  static const double rotationSpeed = 3.0; // rotation speed multiplier
  
  // Bird properties
  Vector2 velocity = Vector2.zero();
  double rotation = 0.0;
  bool isAlive = true;
  
  // Visual properties
  static const double birdWidth = 40.0;
  static const double birdHeight = 30.0;
  Color birdColor = const Color(0xFF00FFFF); // Electric blue
  
  // World boundaries (will be set by game)
  late Vector2 worldBounds;
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Set bird size
    size = Vector2(birdWidth, birdHeight);
    
    // Set initial position (will be updated by game)
    position = Vector2(100, 300);
    
    // Initialize velocity
    velocity = Vector2.zero();
    
    debugPrint('Bird component loaded at position: $position');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (!isAlive) return;
    
    // Apply gravity
    velocity.y += gravity * dt;
    
    // Limit fall speed
    if (velocity.y > maxFallSpeed) {
      velocity.y = maxFallSpeed;
    }
    
    // Update position based on velocity
    position += velocity * dt;
    
    // Update rotation based on velocity direction
    _updateRotation();
    
    // Check world boundaries
    _checkBoundaries();
  }
  
  /// Make the bird jump (apply upward force)
  void jump() {
    if (!isAlive) return;
    
    velocity.y = jumpForce;
    debugPrint('Bird jumped - velocity: ${velocity.y}');
  }
  
  /// Update bird rotation based on velocity direction for visual feedback
  void _updateRotation() {
    // Calculate target rotation based on vertical velocity
    // Positive velocity (falling) = rotate down
    // Negative velocity (jumping) = rotate up
    double targetRotation = (velocity.y / maxFallSpeed) * (math.pi / 4); // Max 45 degrees
    
    // Clamp rotation between -45 and 45 degrees
    targetRotation = targetRotation.clamp(-math.pi / 4, math.pi / 4);
    
    // Smoothly interpolate to target rotation
    rotation = rotation + (targetRotation - rotation) * rotationSpeed * 0.016; // Assuming 60fps
  }
  
  /// Check collision with world boundaries (screen edges)
  void _checkBoundaries() {
    // Check top boundary
    if (position.y <= 0) {
      position.y = 0;
      velocity.y = 0;
      _handleBoundaryCollision();
    }
    
    // Check bottom boundary
    if (position.y + size.y >= worldBounds.y) {
      position.y = worldBounds.y - size.y;
      velocity.y = 0;
      _handleBoundaryCollision();
    }
    
    // Check left boundary (shouldn't happen in normal gameplay)
    if (position.x <= 0) {
      position.x = 0;
      _handleBoundaryCollision();
    }
    
    // Check right boundary (shouldn't happen in normal gameplay)
    if (position.x + size.x >= worldBounds.x) {
      position.x = worldBounds.x - size.x;
      _handleBoundaryCollision();
    }
  }
  
  /// Handle collision with world boundaries
  void _handleBoundaryCollision() {
    if (isAlive) {
      isAlive = false;
      debugPrint('Bird hit boundary - Game Over');
      // The game will handle the game over logic
    }
  }
  
  /// Set world boundaries for collision detection
  void setWorldBounds(Vector2 bounds) {
    worldBounds = bounds;
    debugPrint('Bird world bounds set to: $worldBounds');
  }
  
  /// Reset bird to initial state
  void reset() {
    position = Vector2(100, worldBounds.y / 2); // Center vertically
    velocity = Vector2.zero();
    rotation = 0.0;
    isAlive = true;
    debugPrint('Bird reset to position: $position');
  }
  
  /// Get bird's collision rectangle for collision detection
  Rect get collisionRect {
    return Rect.fromLTWH(
      position.x,
      position.y,
      size.x,
      size.y,
    );
  }
  
  /// Check if bird is within safe bounds (not touching edges)
  bool get isWithinSafeBounds {
    return position.y > 0 && 
           position.y + size.y < worldBounds.y &&
           position.x > 0 && 
           position.x + size.x < worldBounds.x;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Save canvas state
    canvas.save();
    
    // Translate to bird center for rotation
    canvas.translate(size.x / 2, size.y / 2);
    
    // Apply rotation
    canvas.rotate(rotation);
    
    // Draw bird as a simple colored rectangle with rounded corners
    final paint = Paint()
      ..color = birdColor
      ..style = PaintingStyle.fill;
    
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );
    
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8.0));
    canvas.drawRRect(rrect, paint);
    
    // Draw a simple eye
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.x * 0.2, -size.y * 0.1),
      3.0,
      eyePaint,
    );
    
    // Draw pupil
    final pupilPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.x * 0.25, -size.y * 0.1),
      1.5,
      pupilPaint,
    );
    
    // Restore canvas state
    canvas.restore();
  }
}