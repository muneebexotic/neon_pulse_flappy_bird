import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:neon_pulse_flappy_bird/game/components/bird.dart';

void main() {
  group('Bird Component Tests', () {
    late Bird bird;
    
    setUp(() async {
      bird = Bird();
      await bird.onLoad(); // Ensure the bird is properly loaded
      bird.setWorldBounds(Vector2(800, 600));
    });
    
    group('Physics Tests', () {
      test('should apply gravity over time', () {
        // Arrange
        final initialVelocityY = bird.velocity.y;
        const deltaTime = 0.1; // Small time step to avoid max speed clamping
        
        // Act
        bird.update(deltaTime);
        
        // Assert
        expect(bird.velocity.y, greaterThan(initialVelocityY));
        expect(bird.velocity.y, equals(Bird.gravity * deltaTime));
      });
      
      test('should limit fall speed to maximum', () {
        // Arrange
        bird.velocity.y = Bird.maxFallSpeed + 100; // Set velocity higher than max
        const deltaTime = 0.016; // ~60fps
        
        // Act
        bird.update(deltaTime);
        
        // Assert
        expect(bird.velocity.y, lessThanOrEqualTo(Bird.maxFallSpeed));
      });
      
      test('should update position based on velocity', () {
        // Arrange
        final initialPosition = Vector2.copy(bird.position);
        bird.velocity = Vector2(100, 50); // Set some velocity
        const deltaTime = 0.5; // Half second
        
        // Act
        bird.update(deltaTime);
        
        // Assert
        final expectedPosition = initialPosition + bird.velocity * deltaTime;
        expect(bird.position.x, closeTo(expectedPosition.x, 0.1));
        // Y position will be affected by gravity, so we check it separately
        expect(bird.position.y, greaterThan(initialPosition.y));
      });
      
      test('should calculate rotation based on velocity', () {
        // Arrange - Start with neutral state
        bird.velocity.y = 0;
        bird.rotation = 0;
        
        // Act - Test falling (positive velocity should rotate down)
        bird.velocity.y = Bird.maxFallSpeed / 2;
        bird.update(0.016);
        final fallingRotation = bird.rotation;
        
        // Reset and test jumping (negative velocity should rotate up)
        bird.velocity.y = Bird.jumpForce / 2;
        bird.rotation = 0; // Reset rotation
        bird.update(0.016);
        final jumpingRotation = bird.rotation;
        
        // Assert
        expect(fallingRotation, greaterThan(0)); // Should rotate downward (positive)
        expect(jumpingRotation, lessThan(0)); // Should rotate upward (negative)
      });
    });
    
    group('Jump Mechanics Tests', () {
      test('should apply jump force when jump is called', () {
        // Arrange
        bird.velocity.y = 100; // Set some downward velocity
        
        // Act
        bird.jump();
        
        // Assert
        expect(bird.velocity.y, equals(Bird.jumpForce));
      });
      
      test('should not jump when bird is not alive', () {
        // Arrange
        bird.isAlive = false;
        final initialVelocity = bird.velocity.y;
        
        // Act
        bird.jump();
        
        // Assert
        expect(bird.velocity.y, equals(initialVelocity));
      });
      
      test('should jump multiple times with consistent force', () {
        // Act & Assert
        for (int i = 0; i < 5; i++) {
          bird.jump();
          expect(bird.velocity.y, equals(Bird.jumpForce));
        }
      });
    });
    
    group('Boundary Collision Tests', () {
      test('should detect collision with top boundary', () {
        // Arrange
        bird.position.y = -10; // Above screen
        bird.velocity.y = -100; // Moving upward
        
        // Act
        bird.update(0.016);
        
        // Assert
        expect(bird.position.y, equals(0));
        expect(bird.velocity.y, equals(0));
        expect(bird.isAlive, isFalse);
      });
      
      test('should detect collision with bottom boundary', () {
        // Arrange
        bird.position.y = 580; // Near bottom boundary
        bird.velocity.y = 100; // Moving downward fast
        
        // Act
        bird.update(0.016);
        
        // Assert
        expect(bird.position.y, equals(600 - Bird.birdHeight));
        expect(bird.velocity.y, equals(0));
        expect(bird.isAlive, isFalse);
      });
      
      test('should detect collision with left boundary', () {
        // Arrange
        bird.position.x = -10; // Left of screen
        
        // Act
        bird.update(0.016);
        
        // Assert
        expect(bird.position.x, equals(0));
        expect(bird.isAlive, isFalse);
      });
      
      test('should detect collision with right boundary', () {
        // Arrange
        bird.position.x = 770; // Near right boundary
        bird.velocity.x = 100; // Moving right fast
        
        // Act
        bird.update(0.016);
        
        // Assert
        expect(bird.position.x, equals(800 - Bird.birdWidth));
        expect(bird.isAlive, isFalse);
      });
      
      test('should remain alive when within boundaries', () {
        // Arrange
        bird.position = Vector2(400, 300); // Center of screen
        bird.velocity = Vector2(0, 0);
        
        // Act
        bird.update(0.016);
        
        // Assert
        expect(bird.isAlive, isTrue);
      });
    });
    
    group('Utility Methods Tests', () {
      test('should provide correct collision rectangle', () {
        // Arrange
        bird.position = Vector2(100, 200);
        
        // Act
        final rect = bird.collisionRect;
        
        // Assert
        expect(rect.left, equals(100));
        expect(rect.top, equals(200));
        expect(rect.width, equals(Bird.birdWidth));
        expect(rect.height, equals(Bird.birdHeight));
      });
      
      test('should correctly identify safe bounds', () {
        // Arrange & Act & Assert
        bird.position = Vector2(400, 300); // Center - should be safe
        expect(bird.isWithinSafeBounds, isTrue);
        
        bird.position = Vector2(0, 0); // Top-left corner - touching edge
        expect(bird.isWithinSafeBounds, isFalse);
        
        bird.position = Vector2(1, 1); // Just inside bounds - should be safe
        expect(bird.isWithinSafeBounds, isTrue);
        
        bird.position = Vector2(800 - Bird.birdWidth, 600 - Bird.birdHeight); // Bottom-right corner
        expect(bird.isWithinSafeBounds, isFalse);
      });
      
      test('should reset to initial state correctly', () {
        // Arrange
        bird.position = Vector2(500, 100);
        bird.velocity = Vector2(50, 200);
        bird.rotation = 1.0;
        bird.isAlive = false;
        
        // Act
        bird.reset();
        
        // Assert
        expect(bird.position.x, equals(100));
        expect(bird.position.y, equals(300)); // worldBounds.y / 2
        expect(bird.velocity, equals(Vector2.zero()));
        expect(bird.rotation, equals(0.0));
        expect(bird.isAlive, isTrue);
      });
      
      test('should set world bounds correctly', () {
        // Arrange
        final newBounds = Vector2(1024, 768);
        
        // Act
        bird.setWorldBounds(newBounds);
        
        // Assert
        expect(bird.worldBounds, equals(newBounds));
      });
    });
    
    group('Integration Tests', () {
      test('should simulate realistic gameplay physics', () {
        // Arrange
        bird.position = Vector2(100, 100); // Start higher to avoid boundary collision
        bird.velocity = Vector2.zero();
        
        // Act - Simulate falling for a short time
        for (int i = 0; i < 30; i++) { // 30 frames at 60fps (0.5 seconds)
          bird.update(1.0 / 60.0);
          if (!bird.isAlive) break; // Stop if bird hits boundary
        }
        
        // Assert - Bird should have fallen and gained velocity (if still alive)
        if (bird.isAlive) {
          expect(bird.position.y, greaterThan(100));
          expect(bird.velocity.y, greaterThan(0));
          expect(bird.velocity.y, lessThanOrEqualTo(Bird.maxFallSpeed));
        } else {
          // If bird hit boundary, that's also valid behavior
          expect(bird.position.y, anyOf(equals(0), equals(600 - Bird.birdHeight)));
        }
      });
      
      test('should handle jump and fall cycle', () {
        // Arrange
        bird.position = Vector2(100, 300);
        final initialY = bird.position.y;
        
        // Act - Jump and then let it fall
        bird.jump();
        
        // Simulate a few frames of upward movement
        for (int i = 0; i < 10; i++) {
          bird.update(1.0 / 60.0);
        }
        final peakY = bird.position.y;
        
        // Simulate falling back down
        for (int i = 0; i < 30; i++) {
          bird.update(1.0 / 60.0);
        }
        final fallY = bird.position.y;
        
        // Assert
        expect(peakY, lessThan(initialY)); // Should have moved up
        expect(fallY, greaterThan(peakY)); // Should have fallen back down
        expect(bird.velocity.y, greaterThan(0)); // Should be falling
      });
    });
  });
}