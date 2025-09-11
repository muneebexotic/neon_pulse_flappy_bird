import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:neon_pulse_flappy_bird/game/components/laser_grid.dart';
import 'package:neon_pulse_flappy_bird/game/components/bird.dart';
import 'package:neon_pulse_flappy_bird/game/managers/difficulty_manager.dart';

void main() {
  group('LaserGrid Tests', () {
    late LaserGrid laserGrid;
    late Bird bird;
    
    setUp(() {
      laserGrid = LaserGrid(
        startPosition: Vector2(400, 0),
        worldHeight: 600,
      );
      bird = Bird();
    });

    group('Initialization', () {
      test('should initialize with correct properties', () {
        expect(laserGrid.type, equals(ObstacleType.laserGrid));
        expect(laserGrid.position.x, equals(400));
        expect(laserGrid.size.x, equals(80.0)); // gridWidth
        expect(laserGrid.size.y, equals(600));
      });

      test('should create correct number of laser beams', () {
        expect(laserGrid.laserYPositions.length, equals(3));
      });

      test('should position lasers with proper spacing', () {
        final positions = laserGrid.laserYPositions;
        
        // Check that lasers are spaced correctly
        for (int i = 1; i < positions.length; i++) {
          final spacing = positions[i] - positions[i - 1];
          expect(spacing, equals(60.0)); // laserSpacing
        }
      });
    });

    group('Movement', () {
      test('should move from right to left', () {
        final initialX = laserGrid.position.x;
        laserGrid.update(1.0); // 1 second
        
        expect(laserGrid.position.x, lessThan(initialX));
        expect(laserGrid.position.x, equals(initialX - 180.0)); // moveSpeed
      });

      test('should be marked for removal when off-screen', () {
        laserGrid.position.x = -100;
        expect(laserGrid.shouldRemove, isTrue);
      });
    });

    group('Collision Detection', () {
      test('should detect collision with laser beams', () {
        // Position bird to intersect with first laser
        bird.position = Vector2(420, laserGrid.laserYPositions[0]);
        bird.size = Vector2(20, 20);
        
        expect(laserGrid.checkCollision(bird), isTrue);
      });

      test('should not detect collision in gaps between lasers', () {
        // Position bird in gap between first and second laser
        final gapY = (laserGrid.laserYPositions[0] + laserGrid.laserYPositions[1]) / 2;
        bird.position = Vector2(420, gapY);
        bird.size = Vector2(20, 20);
        
        expect(laserGrid.checkCollision(bird), isFalse);
      });

      test('should not detect collision when disabled', () {
        // Position bird to intersect with laser
        bird.position = Vector2(420, laserGrid.laserYPositions[0]);
        bird.size = Vector2(20, 20);
        
        // Disable the laser grid
        laserGrid.disable(2.0);
        
        expect(laserGrid.checkCollision(bird), isFalse);
      });

      test('should provide correct laser rectangles', () {
        final rects = laserGrid.laserRects;
        
        expect(rects.length, equals(3));
        
        for (int i = 0; i < rects.length; i++) {
          final rect = rects[i];
          expect(rect.left, equals(laserGrid.position.x));
          expect(rect.width, equals(80.0)); // gridWidth
          expect(rect.height, equals(4.0)); // laserThickness
          expect(rect.center.dy, closeTo(laserGrid.laserYPositions[i], 0.1));
        }
      });
    });

    group('Disable Mechanism', () {
      test('should disable and re-enable correctly', () {
        expect(laserGrid.isDisabled, isFalse);
        
        laserGrid.disable(2.0);
        expect(laserGrid.isDisabled, isTrue);
        expect(laserGrid.disableTimer, equals(2.0));
        
        // Update for 1 second
        laserGrid.update(1.0);
        expect(laserGrid.isDisabled, isTrue);
        expect(laserGrid.disableTimer, equals(1.0));
        
        // Update for another 1.5 seconds (total 2.5)
        laserGrid.update(1.5);
        expect(laserGrid.isDisabled, isFalse);
        expect(laserGrid.disableTimer, equals(0.0));
      });
    });

    group('Animation', () {
      test('should update animation time', () {
        final initialTime = laserGrid.animationTime;
        laserGrid.update(0.5);
        
        expect(laserGrid.animationTime, equals(initialTime + 0.5));
      });
    });

    group('Bird Passing Detection', () {
      test('should detect when bird has passed', () {
        bird.position = Vector2(500, 300); // Past the laser grid
        expect(laserGrid.hasBirdPassed(bird), isTrue);
      });

      test('should not detect passing when bird is before obstacle', () {
        bird.position = Vector2(300, 300); // Before the laser grid
        expect(laserGrid.hasBirdPassed(bird), isFalse);
      });
    });

    group('Collision Rectangle', () {
      test('should provide correct collision rectangle', () {
        final rect = laserGrid.collisionRect;
        
        expect(rect.left, equals(laserGrid.position.x));
        expect(rect.top, equals(laserGrid.position.y));
        expect(rect.width, equals(laserGrid.size.x));
        expect(rect.height, equals(laserGrid.size.y));
      });
    });
  });
}