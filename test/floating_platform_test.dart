import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:neon_pulse_flappy_bird/game/components/floating_platform.dart';
import 'package:neon_pulse_flappy_bird/game/components/bird.dart';
import 'package:neon_pulse_flappy_bird/game/managers/difficulty_manager.dart';
import 'dart:math' as math;

void main() {
  group('FloatingPlatform Tests', () {
    late FloatingPlatform floatingPlatform;
    late Bird bird;
    
    setUp(() {
      floatingPlatform = FloatingPlatform(
        startPosition: Vector2(400, 0),
        worldHeight: 600,
      );
      bird = Bird();
    });

    group('Initialization', () {
      test('should initialize with correct properties', () {
        expect(floatingPlatform.type, equals(ObstacleType.floatingPlatform));
        expect(floatingPlatform.position.x, equals(400));
        expect(floatingPlatform.size.x, equals(100.0)); // platformWidth
        expect(floatingPlatform.size.y, equals(600));
      });

      test('should create correct number of platforms', () {
        expect(floatingPlatform.platforms.length, equals(2));
      });

      test('should initialize platforms with different movement phases', () {
        final platforms = floatingPlatform.platforms;
        
        expect(platforms[0].movementPhase, equals(0));
        expect(platforms[1].movementPhase, equals(math.pi));
      });

      test('should initialize platforms with different movement speeds', () {
        final platforms = floatingPlatform.platforms;
        
        expect(platforms[0].movementSpeed, equals(1.0));
        expect(platforms[1].movementSpeed, equals(1.3));
      });
    });

    group('Movement', () {
      test('should move from right to left', () {
        final initialX = floatingPlatform.position.x;
        floatingPlatform.update(1.0); // 1 second
        
        expect(floatingPlatform.position.x, lessThan(initialX));
        expect(floatingPlatform.position.x, equals(initialX - 160.0)); // moveSpeed
      });

      test('should update platform vertical positions', () {
        final initialPositions = floatingPlatform.platforms
            .map((p) => p.currentY)
            .toList();
        
        floatingPlatform.update(1.0);
        
        final newPositions = floatingPlatform.platforms
            .map((p) => p.currentY)
            .toList();
        
        // Positions should have changed due to oscillation
        for (int i = 0; i < initialPositions.length; i++) {
          expect(newPositions[i], isNot(equals(initialPositions[i])));
        }
      });

      test('should be marked for removal when off-screen', () {
        floatingPlatform.position.x = -150;
        expect(floatingPlatform.shouldRemove, isTrue);
      });
    });

    group('Vertical Oscillation', () {
      test('should oscillate platforms within expected range', () {
        final platforms = floatingPlatform.platforms;
        final basePositions = platforms.map((p) => p.baseY).toList();
        
        // Update for several cycles to test oscillation
        for (int i = 0; i < 100; i++) {
          floatingPlatform.update(0.1);
          
          for (int j = 0; j < platforms.length; j++) {
            final platform = platforms[j];
            final deviation = (platform.currentY - platform.baseY).abs();
            
            // Should stay within vertical range (80.0)
            expect(deviation, lessThanOrEqualTo(80.0));
          }
        }
      });

      test('should have platforms moving in opposite directions', () {
        // Update to a specific time where oscillation is clear
        floatingPlatform.animationTime = math.pi / 4;
        floatingPlatform.update(0.0); // Just update positions without time
        
        final platform1 = floatingPlatform.platforms[0];
        final platform2 = floatingPlatform.platforms[1];
        
        final deviation1 = platform1.currentY - platform1.baseY;
        final deviation2 = platform2.currentY - platform2.baseY;
        
        // Due to opposite phases, they should move in opposite directions
        // (This test might be sensitive to timing, so we check the general behavior)
        expect(deviation1 * deviation2, lessThanOrEqualTo(0)); // Opposite signs or one is zero
      });
    });

    group('Collision Detection', () {
      test('should detect collision with platforms', () {
        // Position bird to intersect with first platform
        final platform = floatingPlatform.platforms[0];
        bird.position = Vector2(420, platform.currentY + 5);
        bird.size = Vector2(20, 20);
        
        expect(floatingPlatform.checkCollision(bird), isTrue);
      });

      test('should not detect collision in gaps between platforms', () {
        // Position bird in gap between platforms
        final platform1 = floatingPlatform.platforms[0];
        final platform2 = floatingPlatform.platforms[1];
        final gapY = (platform1.currentY + platform2.currentY) / 2;
        
        bird.position = Vector2(420, gapY);
        bird.size = Vector2(20, 20);
        
        expect(floatingPlatform.checkCollision(bird), isFalse);
      });

      test('should not detect collision when disabled', () {
        // Position bird to intersect with platform
        final platform = floatingPlatform.platforms[0];
        bird.position = Vector2(420, platform.currentY + 5);
        bird.size = Vector2(20, 20);
        
        // Disable the floating platform
        floatingPlatform.disable(2.0);
        
        expect(floatingPlatform.checkCollision(bird), isFalse);
      });

      test('should provide correct platform rectangles', () {
        final rects = floatingPlatform.platformRects;
        
        expect(rects.length, equals(2));
        
        for (int i = 0; i < rects.length; i++) {
          final rect = rects[i];
          final platform = floatingPlatform.platforms[i];
          
          expect(rect.left, equals(floatingPlatform.position.x));
          expect(rect.width, equals(100.0)); // platformWidth
          expect(rect.height, equals(20.0)); // platformHeight
          expect(rect.top, equals(platform.currentY));
        }
      });
    });

    group('Disable Mechanism', () {
      test('should disable and re-enable correctly', () {
        expect(floatingPlatform.isDisabled, isFalse);
        
        floatingPlatform.disable(2.0);
        expect(floatingPlatform.isDisabled, isTrue);
        expect(floatingPlatform.disableTimer, equals(2.0));
        
        // Update for 1 second
        floatingPlatform.update(1.0);
        expect(floatingPlatform.isDisabled, isTrue);
        expect(floatingPlatform.disableTimer, equals(1.0));
        
        // Update for another 1.5 seconds (total 2.5)
        floatingPlatform.update(1.5);
        expect(floatingPlatform.isDisabled, isFalse);
        expect(floatingPlatform.disableTimer, equals(0.0));
      });
    });

    group('Animation', () {
      test('should update animation time', () {
        final initialTime = floatingPlatform.animationTime;
        floatingPlatform.update(0.5);
        
        expect(floatingPlatform.animationTime, equals(initialTime + 0.5));
      });
    });

    group('Bird Passing Detection', () {
      test('should detect when bird has passed', () {
        bird.position = Vector2(550, 300); // Past the floating platform
        expect(floatingPlatform.hasBirdPassed(bird), isTrue);
      });

      test('should not detect passing when bird is before obstacle', () {
        bird.position = Vector2(300, 300); // Before the floating platform
        expect(floatingPlatform.hasBirdPassed(bird), isFalse);
      });
    });

    group('Collision Rectangle', () {
      test('should provide correct collision rectangle', () {
        final rect = floatingPlatform.collisionRect;
        
        expect(rect.left, equals(floatingPlatform.position.x));
        expect(rect.top, equals(floatingPlatform.position.y));
        expect(rect.width, equals(floatingPlatform.size.x));
        expect(rect.height, equals(floatingPlatform.size.y));
      });
    });

    group('Platform Data', () {
      test('should maintain platform data integrity', () {
        final platforms = floatingPlatform.platforms;
        
        for (final platform in platforms) {
          expect(platform.baseY, greaterThanOrEqualTo(0));
          expect(platform.baseY, lessThanOrEqualTo(600));
          expect(platform.movementSpeed, greaterThan(0));
        }
      });

      test('should have platforms spaced with gaps', () {
        final platforms = floatingPlatform.platforms;
        
        // Check that there's sufficient gap between platforms
        for (int i = 1; i < platforms.length; i++) {
          final gap = platforms[i].baseY - platforms[i-1].baseY - 20.0; // platformHeight
          expect(gap, greaterThanOrEqualTo(100.0)); // Should have at least 100px gap
        }
      });
    });
  });
}