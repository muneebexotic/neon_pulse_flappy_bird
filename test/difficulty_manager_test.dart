import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/game/managers/difficulty_manager.dart';

void main() {
  group('DifficultyManager Tests', () {
    group('Difficulty Level Calculation', () {
      test('should calculate correct difficulty level for various scores', () {
        expect(DifficultyManager.calculateDifficultyLevel(0), equals(1));
        expect(DifficultyManager.calculateDifficultyLevel(5), equals(1));
        expect(DifficultyManager.calculateDifficultyLevel(9), equals(1));
        expect(DifficultyManager.calculateDifficultyLevel(10), equals(2));
        expect(DifficultyManager.calculateDifficultyLevel(19), equals(2));
        expect(DifficultyManager.calculateDifficultyLevel(20), equals(3));
        expect(DifficultyManager.calculateDifficultyLevel(50), equals(6));
        expect(DifficultyManager.calculateDifficultyLevel(100), equals(11));
      });

      test('should cap difficulty level at maximum', () {
        expect(DifficultyManager.calculateDifficultyLevel(200), equals(20));
        expect(DifficultyManager.calculateDifficultyLevel(1000), equals(20));
      });
    });

    group('Game Speed Calculation', () {
      test('should calculate correct game speed for difficulty levels', () {
        expect(DifficultyManager.calculateGameSpeed(1), closeTo(1.0, 0.001));
        expect(DifficultyManager.calculateGameSpeed(2), closeTo(1.05, 0.001));
        expect(DifficultyManager.calculateGameSpeed(3), closeTo(1.10, 0.001));
        expect(DifficultyManager.calculateGameSpeed(10), closeTo(1.45, 0.001));
        expect(DifficultyManager.calculateGameSpeed(20), closeTo(1.95, 0.001));
      });

      test('should cap game speed at maximum', () {
        expect(DifficultyManager.calculateGameSpeed(25), equals(2.0));
        expect(DifficultyManager.calculateGameSpeed(100), equals(2.0));
      });
    });

    group('Spawn Interval Calculation', () {
      test('should calculate correct spawn intervals', () {
        expect(DifficultyManager.calculateSpawnInterval(1), equals(3.5));
        expect(DifficultyManager.calculateSpawnInterval(2), equals(3.4));
        expect(DifficultyManager.calculateSpawnInterval(5), equals(3.1));
        expect(DifficultyManager.calculateSpawnInterval(10), equals(2.6));
      });

      test('should respect minimum spawn interval', () {
        expect(DifficultyManager.calculateSpawnInterval(20), closeTo(1.6, 0.001));
        expect(DifficultyManager.calculateSpawnInterval(25), equals(1.5));
        expect(DifficultyManager.calculateSpawnInterval(30), equals(1.5));
      });
    });

    group('Multiple Obstacle Logic', () {
      test('should determine when to spawn multiple obstacles', () {
        expect(DifficultyManager.shouldSpawnMultipleObstacles(1), isFalse);
        expect(DifficultyManager.shouldSpawnMultipleObstacles(4), isFalse);
        expect(DifficultyManager.shouldSpawnMultipleObstacles(5), isTrue);
        expect(DifficultyManager.shouldSpawnMultipleObstacles(10), isTrue);
      });

      test('should calculate correct number of simultaneous obstacles', () {
        expect(DifficultyManager.calculateSimultaneousObstacles(1), equals(1));
        expect(DifficultyManager.calculateSimultaneousObstacles(4), equals(1));
        expect(DifficultyManager.calculateSimultaneousObstacles(5), equals(1));
        expect(DifficultyManager.calculateSimultaneousObstacles(8), equals(2));
        expect(DifficultyManager.calculateSimultaneousObstacles(11), equals(3));
        expect(DifficultyManager.calculateSimultaneousObstacles(20), equals(3));
      });
    });

    group('Obstacle Type Selection', () {
      test('should only provide digital barriers at low levels', () {
        final weights = DifficultyManager.getObstacleTypeWeights(1);
        expect(weights.containsKey(ObstacleType.digitalBarrier), isTrue);
        expect(weights.containsKey(ObstacleType.laserGrid), isFalse);
        expect(weights.containsKey(ObstacleType.floatingPlatform), isFalse);
      });

      test('should add laser grids at level 3', () {
        final weights = DifficultyManager.getObstacleTypeWeights(3);
        expect(weights.containsKey(ObstacleType.digitalBarrier), isTrue);
        expect(weights.containsKey(ObstacleType.laserGrid), isTrue);
        expect(weights.containsKey(ObstacleType.floatingPlatform), isFalse);
      });

      test('should add floating platforms at level 6', () {
        final weights = DifficultyManager.getObstacleTypeWeights(6);
        expect(weights.containsKey(ObstacleType.digitalBarrier), isTrue);
        expect(weights.containsKey(ObstacleType.laserGrid), isTrue);
        expect(weights.containsKey(ObstacleType.floatingPlatform), isTrue);
      });

      test('should select valid obstacle types', () {
        for (int level = 1; level <= 20; level++) {
          final obstacleType = DifficultyManager.selectObstacleType(level);
          expect(ObstacleType.values.contains(obstacleType), isTrue);
        }
      });
    });

    group('Difficulty Plateau System', () {
      test('should detect when difficulty has plateaued', () {
        expect(DifficultyManager.isDifficultyAtPlateau(19), isFalse);
        expect(DifficultyManager.isDifficultyAtPlateau(20), isTrue);
        expect(DifficultyManager.isDifficultyAtPlateau(25), isTrue);
      });

      test('should calculate difficulty progress correctly', () {
        expect(DifficultyManager.getDifficultyProgress(1), equals(0.05));
        expect(DifficultyManager.getDifficultyProgress(10), equals(0.5));
        expect(DifficultyManager.getDifficultyProgress(20), equals(1.0));
        expect(DifficultyManager.getDifficultyProgress(25), equals(1.0));
      });
    });

    group('Difficulty Descriptions', () {
      test('should provide correct difficulty descriptions', () {
        expect(DifficultyManager.getDifficultyDescription(1), equals('Beginner'));
        expect(DifficultyManager.getDifficultyDescription(3), equals('Easy'));
        expect(DifficultyManager.getDifficultyDescription(7), equals('Medium'));
        expect(DifficultyManager.getDifficultyDescription(12), equals('Hard'));
        expect(DifficultyManager.getDifficultyDescription(18), equals('Expert'));
        expect(DifficultyManager.getDifficultyDescription(20), equals('Master'));
      });
    });

    group('Score Calculations', () {
      test('should calculate score needed for next level', () {
        expect(DifficultyManager.getScoreForNextLevel(5), equals(10));
        expect(DifficultyManager.getScoreForNextLevel(15), equals(20));
        expect(DifficultyManager.getScoreForNextLevel(25), equals(30));
      });

      test('should return -1 when at max level', () {
        expect(DifficultyManager.getScoreForNextLevel(200), equals(-1));
      });
    });

    group('Difficulty Statistics', () {
      test('should provide comprehensive difficulty stats', () {
        final stats = DifficultyManager.getDifficultyStats(25);
        
        expect(stats['level'], equals(3));
        expect(stats['speed'], equals(1.10));
        expect(stats['spawnInterval'], equals(3.3));
        expect(stats['simultaneousObstacles'], equals(1));
        expect(stats['progress'], equals(0.15));
        expect(stats['description'], equals('Easy'));
        expect(stats['nextLevelScore'], equals(30));
        expect(stats['isAtPlateau'], isFalse);
      });

      test('should handle max level stats correctly', () {
        final stats = DifficultyManager.getDifficultyStats(200);
        
        expect(stats['level'], equals(20));
        expect(stats['speed'], closeTo(1.95, 0.001));
        expect(stats['isAtPlateau'], isTrue);
        expect(stats['nextLevelScore'], equals(-1));
      });
    });

    group('Edge Cases', () {
      test('should handle negative scores gracefully', () {
        expect(DifficultyManager.calculateDifficultyLevel(-5), equals(1));
        expect(DifficultyManager.calculateGameSpeed(0), closeTo(0.95, 0.001));
      });

      test('should handle very large difficulty levels', () {
        expect(DifficultyManager.calculateGameSpeed(1000), equals(2.0));
        expect(DifficultyManager.calculateSpawnInterval(1000), equals(1.5));
      });
    });

    group('Performance Validation', () {
      test('should maintain reasonable performance characteristics', () {
        // Test that difficulty scaling maintains playability
        for (int level = 1; level <= 20; level++) {
          final speed = DifficultyManager.calculateGameSpeed(level);
          final interval = DifficultyManager.calculateSpawnInterval(level);
          
          // Speed should never exceed 2x
          expect(speed, lessThanOrEqualTo(2.0));
          
          // Spawn interval should never be too fast
          expect(interval, greaterThanOrEqualTo(1.5));
          
          // Simultaneous obstacles should be reasonable
          final simultaneous = DifficultyManager.calculateSimultaneousObstacles(level);
          expect(simultaneous, lessThanOrEqualTo(3));
        }
      });
    });
  });
}