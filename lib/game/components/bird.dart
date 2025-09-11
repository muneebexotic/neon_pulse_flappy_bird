import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../effects/particle_system.dart';
import '../effects/neon_colors.dart';

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
  Color birdColor = NeonColors.electricBlue;
  
  // Trail particle system
  late ParticleSystem particleSystem;
  double trailSpawnTimer = 0.0;
  static const double trailSpawnInterval = 0.05; // Spawn trail every 50ms
  
  // Animation properties
  double animationTime = 0.0;
  
  // Component state
  bool hasLoaded = false;
  
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
    
    // Initialize particle system for trail effects
    particleSystem = ParticleSystem();
    add(particleSystem);
    
    // Mark as loaded
    hasLoaded = true;
    
    debugPrint('Bird component loaded at position: $position');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (!isAlive) return;
    
    // Update animation time
    animationTime += dt;
    
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
    
    // Update trail particles
    _updateTrailParticles(dt);
    
    // Check world boundaries
    _checkBoundaries();
  }
  
  /// Make the bird jump (apply upward force)
  void jump() {
    if (!isAlive) return;
    
    velocity.y = jumpForce;
    
    // Add jump particle effect if particle system is available
    if (hasLoaded && children.contains(particleSystem)) {
      particleSystem.addSparks(
        position: Vector2(position.x + size.x / 2, position.y + size.y),
        color: _getPerformanceColor(),
        sparkCount: 3,
        speed: 60.0,
        life: 0.8,
      );
    }
    
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
  
  /// Update trail particles that follow bird movement
  void _updateTrailParticles(double dt) {
    // Only update trail particles if particle system is available
    if (!hasLoaded || !children.contains(particleSystem)) return;
    
    trailSpawnTimer += dt;
    
    if (trailSpawnTimer >= trailSpawnInterval) {
      trailSpawnTimer = 0.0;
      
      // Spawn trail particle at bird's current position
      final trailPosition = Vector2(
        position.x + size.x / 2,
        position.y + size.y / 2,
      );
      
      // Create trail velocity opposite to bird movement
      final trailVelocity = Vector2(
        -velocity.x * 0.3 + (math.Random().nextDouble() - 0.5) * 20,
        -velocity.y * 0.2 + (math.Random().nextDouble() - 0.5) * 20,
      );
      
      particleSystem.addTrailParticle(
        position: trailPosition,
        color: _getPerformanceColor(),
        velocity: trailVelocity,
        size: 2.0 + math.Random().nextDouble() * 1.0,
        life: 1.2,
      );
    }
  }
  
  /// Get trail color based on bird performance (velocity and position)
  Color _getPerformanceColor() {
    // Calculate performance based on velocity and position safety
    final velocityFactor = (1.0 - (velocity.y.abs() / maxFallSpeed)).clamp(0.0, 1.0);
    final positionFactor = isWithinSafeBounds ? 1.0 : 0.3;
    final performance = (velocityFactor + positionFactor) / 2.0;
    
    return NeonColors.getPerformanceColor(performance);
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
    animationTime = 0.0;
    trailSpawnTimer = 0.0;
    
    // Clear existing particles if particle system is initialized
    if (hasLoaded && children.contains(particleSystem)) {
      particleSystem.clearAllParticles();
    }
    
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
    
    // Get animated bird color
    final animatedColor = NeonColors.getAnimatedColor(
      birdColor, 
      animationTime,
      minIntensity: 0.8,
      maxIntensity: 1.0,
    );
    
    // Draw neon glow layers
    _drawNeonGlow(canvas, animatedColor);
    
    // Draw bird body
    final paint = Paint()
      ..color = animatedColor
      ..style = PaintingStyle.fill;
    
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );
    
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8.0));
    canvas.drawRRect(rrect, paint);
    
    // Draw neon outline
    final outlinePaint = Paint()
      ..color = animatedColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawRRect(rrect, outlinePaint);
    
    // Draw glowing eye
    _drawGlowingEye(canvas);
    
    // Restore canvas state
    canvas.restore();
  }
  
  /// Draw neon glow effect around the bird
  void _drawNeonGlow(Canvas canvas, Color color) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );
    
    // Outer glow
    final outerGlowPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 15.0);
    
    final outerRRect = RRect.fromRectAndRadius(rect, const Radius.circular(8.0));
    canvas.drawRRect(outerRRect, outerGlowPaint);
    
    // Inner glow
    final innerGlowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8.0);
    
    canvas.drawRRect(outerRRect, innerGlowPaint);
  }
  
  /// Draw glowing eye with neon effect
  void _drawGlowingEye(Canvas canvas) {
    final eyePosition = Offset(size.x * 0.2, -size.y * 0.1);
    
    // Eye glow
    final eyeGlowPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5.0);
    
    canvas.drawCircle(eyePosition, 4.0, eyeGlowPaint);
    
    // Eye base
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(eyePosition, 3.0, eyePaint);
    
    // Glowing pupil
    final pupilGlowPaint = Paint()
      ..color = NeonColors.electricBlue.withOpacity(0.8)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 2.0);
    
    final pupilPosition = Offset(size.x * 0.25, -size.y * 0.1);
    canvas.drawCircle(pupilPosition, 2.0, pupilGlowPaint);
    
    // Pupil core
    final pupilPaint = Paint()
      ..color = NeonColors.electricBlue
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(pupilPosition, 1.5, pupilPaint);
  }
}