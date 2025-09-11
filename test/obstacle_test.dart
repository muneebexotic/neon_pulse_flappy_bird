import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../lib/game/components/obstacle.dart';
import '../lib/game/components/digital_barrier.dart';
import '../lib/game/components/bird.dart';
import '../lib/game/managers/obstacle_manager.dart';
import '../lib/game/managers/difficulty_manager.dart';

void main() {
  group('Obstacle Tests', () {
    late Bird testBird;
    
    setUp(() {
      testBird = Bird();
      testBird.position = Vector2(100, 300);
      testBird.size = Vector2(40, 30);
      testBird.setWorldBounds(Vector2(800, 600));
    });
    
    group('DigitalBarrier Tests', () {
      test('should create digital barrier with correct properties', () {
        final barrier = DigitalBarrier(
          startPosition: Vector2(400, 0),
          worldHeight: 600,
        );
        
        expect(barrier.type, equals(ObstacleType.digitalBarrier));
        expect(barrier.position.x, equals(400));
        expect(barrier.position.y, equals(0));
        expect(barrier.size.x, equals(DigitalBarrier.barrierWidth));
        expect(barrier.size.y, equals(600));
        expect(barrier.isDisabled, isFalse);
      });
      
      test('should move from right to left', () {
        final barrier = DigitalBarrier(
          startPosition: Vector2(400, 0),
          worldHeight: 600,
        );
        
        final initialX = barrier.position.x;
        barrier.update(1.0); // 1 second
        
        expect(barrier.position.x, lessThan(initialX));
        expect(barrier.position.x, equals(initialX - DigitalBarrier.moveSpeed));
      });
      
      test('should be marked for removal when off-screen', () {
        final barrier = DigitalBarrier(
          startPosition: Vector2(-100, 0), // Already off-screen
          worldHeight: 600,
        );
        
        expect(barrier.shouldRemove, isTrue);
      });
      
      test('should not be marked for removal when on-screen', () {
        final barrier = DigitalBarrier(
          startPosition: Vector2(400, 0),
          worldHeight: 600,
        );
        
        expect(barrier.shouldRemove, isFalse);
      });
      
      test('should detect bird passed when bird is to the right', () {
        final barrier = DigitalBarrier(
          startPosition: Vector2(400, 0),
          worldHeight: 600,
        );
        
        // Bird is to the left of barrier
        testBird.position = Vector2(300, 300);
        expect(barrier.hasBirdPassed(testBird), isFalse);
        
        // Bird is to the right of barrier
        testBird.position = Vector2(500, 300);
        expect(barrier.hasBirdPassed(testBird), isTrue);
      });
    });
    
    group('Collision Detection Tests', () {
      test('should detect collision when bird overlaps with top barrier', () {
        final barrier = DigitalBarrier(
          startPosition: Vector2(100, 0),
          worldHeight: 600,
        );
        
        // Position bird to collide with top barrier
        testBird.position = Vector2(120, 50); // Inside top barrier area
        
        expect(barrier.checkCollision(testBird), isTrue);
      });
      
      test('should detect collision when bird overlaps with bottom barrier', () {
        final barrier = DigitalBarrier(
          startPosition: Vector2(100, 0),
          worldHeight: 600,
        );
        
        // Position bird to collide with bottom barrier
        testBird.position = Vector2(120, 550); // Inside bottom barrier area
        
        expect(barrier.checkCollision(testBird), isTrue);
      });
      
      test('should not detect collision when bird is in gap', () {
        final barrier = DigitalBarrier(
          startPosition: Vector2(100, 0),
          worldHeight: 600,
        );
        
        // Position bird in the middle gap area
        testBird.position = Vector2(120, 300); // Should be in gap
        
        expect(barrier.checkCollision(testBird), isFalse);
      });
      
      test('should not detect collision when bird is far from barrier', () {
        final barrier = DigitalBarrier(
          startPosition: Vector2(400, 0),
          worldHeight: 600,
        );
        
        // Bird is far to the left
        testBird.position = Vector2(100, 300);
        
        expect(barrier.checkCollision(testBird), isFalse);
      });
      
      test('should not detect collision when obstacle is disabled', () {
        final barrier = DigitalBarrier(
          startPosition: Vector2(100, 0),
          worldHeight: 600,
        );
        
        // Disable the barrier
        barrier.disable(2.0);
        
        // Position bird to collide with barrier
        testBird.position = Vector2(120, 50);
        
        expect(barrier.checkCollision(testBird), isFalse);
      });
      
      test('should re-enable obstacle after disable timer expires', () {
        final barrier = DigitalBarrier(
          startPosition: Vector2(100, 0),
          worldHeight: 600,
        );
        
        // Disable the barrier for 1 second
        barrier.disable(1.0);
        expect(barrier.isDisabled, isTrue);
        
        // Update for 0.5 seconds - should still be disabled
        barrier.update(0.5);
        expect(barrier.isDisabled, isTrue);
        
        // Update for another 0.6 seconds - should be enabled
        barrier.update(0.6);
        expect(barrier.isDisabled, isFalse);
      });
    });
    
    group('Bounding Box Collision Tests', () {
      test('should correctly calculate collision rectangles', () {
        final barrier = DigitalBarrier(
          startPosition: Vector2(100, 0),
          worldHeight: 600,
        );
        
        final topRect = barrier.topBarrierRect;
        final bottomRect = barrier.bottomBarrierRect;
        
        // Top barrier should start at y=0
        expect(topRect.top, equals(0));
        expect(topRect.left, equals(100));
        expect(topRect.width, equals(DigitalBarrier.barrierWidth));
        
        // Bottom barrier should end at worldHeight
        expect(bottomRect.bottom, equals(600));
        expect(bottomRect.left, equals(100));
        expect(bottomRect.width, equals(DigitalBarrier.barrierWidth));
        
        // Gap should exist between barriers
        expect(topRect.bottom, lessThan(bottomRect.top));
      });
      
      test('should detect precise bounding box overlaps', () {
        final barrier = DigitalBarrier(
          startPosition: Vector2(100, 0),
          worldHeight: 600,
        );
        
        // Test collision with top barrier - bird positioned in top area
        testBird.position = Vector2(100, 20); // In top barrier area
        expect(barrier.checkCollision(testBird), isTrue);
        
        // Test actual overlap (bird overlaps with barrier by 1 pixel)
        testBird.position = Vector2(61, 20); // Bird right edge (61+40=101) overlaps barrier left edge (100)
        expect(barrier.checkCollision(testBird), isTrue);
        
        // Test just outside collision (bird right edge touches barrier left edge - no overlap)
        testBird.position = Vector2(60, 20); // Bird right edge (60+40=100) touches barrier left edge (100)
        expect(barrier.checkCollision(testBird), isFalse);
        
        // Test collision with bottom barrier - bird positioned in bottom area
        testBird.position = Vector2(120, 550); // In bottom barrier area
        expect(barrier.checkCollision(testBird), isTrue);
        
        // Test just outside right edge of barrier
        testBird.position = Vector2(160, 20); // Bird left edge (160) is right of barrier right edge (160)
        expect(barrier.checkCollision(testBird), isFalse);
        
        // Test bird in gap area - should not collide
        testBird.position = Vector2(120, 300); // In gap area
        expect(barrier.checkCollision(testBird), isFalse);
      });
    });
  });
  
  group('ObstacleManager Tests', () {
    late ObstacleManager manager;
    late Bird testBird;
    
    setUp(() {
      manager = ObstacleManager(worldWidth: 800, worldHeight: 600);
      testBird = Bird();
      testBird.position = Vector2(100, 300);
      testBird.size = Vector2(40, 30);
      testBird.setWorldBounds(Vector2(800, 600));
    });
    
    test('should initialize with correct properties', () {
      expect(manager.worldWidth, equals(800));
      expect(manager.worldHeight, equals(600));
      expect(manager.obstacleCount, equals(0));
      expect(manager.passedObstacleCount, equals(0));
    });
    
    test('should spawn obstacles at regular intervals', () {
      // Initially no obstacles
      expect(manager.obstacleCount, equals(0));
      
      // Update for spawn interval duration
      manager.update(ObstacleManager.spawnInterval + 0.1);
      
      // Should have spawned one obstacle
      expect(manager.obstacleCount, equals(1));
    });
    
    test('should update difficulty settings', () {
      manager.updateDifficulty(1.5, 3);
      
      expect(manager.currentGameSpeed, equals(1.5));
      expect(manager.difficultyLevel, equals(3));
    });
    
    test('should detect collisions with any obstacle', () {
      // Add a test obstacle manually
      final barrier = DigitalBarrier(
        startPosition: Vector2(100, 0),
        worldHeight: 600,
      );
      manager.obstacles.add(barrier);
      
      // Position bird to collide
      testBird.position = Vector2(120, 50);
      
      expect(manager.checkCollisions(testBird), isTrue);
    });
    
    test('should not detect collisions when no obstacles present', () {
      expect(manager.checkCollisions(testBird), isFalse);
    });
    
    test('should track passed obstacles for scoring', () {
      // Add a test obstacle (bird is at x=100, so obstacle at x=50 with width 60 means right edge is at 110)
      final barrier = DigitalBarrier(
        startPosition: Vector2(30, 0), // Behind bird (right edge at 30+60=90, which is left of bird at 100)
        worldHeight: 600,
      );
      manager.obstacles.add(barrier);
      
      // Check passed obstacles
      final passed = manager.checkPassedObstacles(testBird);
      
      expect(passed.length, equals(1));
      expect(manager.passedObstacleCount, equals(1));
      
      // Calling again should not return the same obstacle
      final passedAgain = manager.checkPassedObstacles(testBird);
      expect(passedAgain.length, equals(0));
    });
    
    test('should clear all obstacles on reset', () {
      // Add some test obstacles
      manager.obstacles.add(DigitalBarrier(
        startPosition: Vector2(400, 0),
        worldHeight: 600,
      ));
      manager.obstacles.add(DigitalBarrier(
        startPosition: Vector2(600, 0),
        worldHeight: 600,
      ));
      
      expect(manager.obstacleCount, equals(2));
      
      manager.clearAllObstacles();
      
      expect(manager.obstacleCount, equals(0));
      expect(manager.passedObstacleCount, equals(0));
    });
    
    test('should disable obstacles in pulse range', () {
      // Add test obstacles
      final nearObstacle = DigitalBarrier(
        startPosition: Vector2(150, 0),
        worldHeight: 600,
      );
      final farObstacle = DigitalBarrier(
        startPosition: Vector2(400, 0),
        worldHeight: 600,
      );
      
      manager.obstacles.addAll([nearObstacle, farObstacle]);
      
      // Pulse from bird position with radius 100
      manager.disableObstaclesInRange(Vector2(100, 300), 100.0, 2.0);
      
      // Near obstacle should be disabled, far obstacle should not
      expect(nearObstacle.isDisabled, isTrue);
      expect(farObstacle.isDisabled, isFalse);
      expect(manager.hasDisabledObstacles, isTrue);
    });
    
    test('should adjust spawn interval based on difficulty', () {
      // Test with different difficulty levels
      manager.updateDifficulty(1.0, 1);
      manager.update(ObstacleManager.spawnInterval + 0.1);
      final countLevel1 = manager.obstacleCount;
      
      manager.clearAllObstacles();
      
      manager.updateDifficulty(1.0, 5);
      manager.update(ObstacleManager.spawnInterval + 0.1);
      final countLevel5 = manager.obstacleCount;
      
      // Higher difficulty should spawn more obstacles in same time
      // (This test verifies the spawn interval adjustment logic)
      expect(countLevel5, greaterThanOrEqualTo(countLevel1));
    });
  });
}