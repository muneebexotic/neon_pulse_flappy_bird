import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'bird.dart';
import '../managers/difficulty_manager.dart';

/// Abstract base class for all obstacles in the game
abstract class Obstacle extends PositionComponent {
  // Obstacle properties
  bool isDisabled = false;
  double disableTimer = 0.0;
  late ObstacleType type;
  
  // Visual properties
  Color glowColor = const Color(0xFF00FFFF); // Electric blue
  double glowIntensity = 1.0;
  
  /// Check collision with bird using bounding box detection
  bool checkCollision(Bird bird) {
    if (isDisabled) return false;
    
    final birdRect = bird.collisionRect;
    final obstacleRect = collisionRect;
    
    return birdRect.overlaps(obstacleRect);
  }
  
  /// Get collision rectangle for this obstacle
  Rect get collisionRect {
    return Rect.fromLTWH(
      position.x,
      position.y,
      size.x,
      size.y,
    );
  }
  
  /// Disable obstacle temporarily (for pulse mechanic)
  void disable(double duration) {
    isDisabled = true;
    disableTimer = duration;
  }
  
  /// Enable obstacle
  void enable() {
    isDisabled = false;
    disableTimer = 0.0;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update disable timer
    if (isDisabled && disableTimer > 0) {
      disableTimer -= dt;
      if (disableTimer <= 0) {
        enable();
      }
    }
    
    // Move obstacle from right to left
    moveObstacle(dt);
  }
  
  /// Move obstacle (implemented by subclasses)
  void moveObstacle(double dt);
  
  /// Check if obstacle is off-screen and should be removed
  bool get shouldRemove => position.x + size.x < 0;
  
  /// Check if bird has passed this obstacle (for scoring)
  bool hasBirdPassed(Bird bird) {
    return bird.position.x > position.x + size.x;
  }
}

