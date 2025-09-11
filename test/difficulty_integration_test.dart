import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:neon_pulse_flappy_bird/game/managers/difficulty_manager.dart';
import 'package:neon_pulse_flappy_bird/game/managers/obstacle_manager.dart';
import 'package:neon_pulse_flappy_bird/models/game_state.dart';

void main() {
  group('Difficulty Integration Tests', () {
    late GameState gameState;
    late ObstacleManager obstacleManager;
    
    setUp(() {
      gameState = GameState();
      obstacleManager = ObstacleManager(
        worldWidth: 800,
        worldHeight: 600,
      );
    });

    group('GameState and DifficultyManager Integration', () {
      test('should update difficulty correctly as score increases', () {
        // Start at score 0
        expect(gameState.difficultyLevel, equals(1));
        expect(gameState.gameSpeed, equals(1.0));
        
        // Score 10 points
        for (int i = 0; i < 10; i++) {
          gameState.incrementScore();
        }
        
        expect(gameState.currentScore, equals(10));
        expect(gameState.difficultyLevel, equals(2));
        expect(gameState.gameSpeed, closeTo(1.05, 0.001));
        
        // Score 20 more points (total 30)
        for (int i = 0; i < 20; i++) {
          gameState.incrementScore();
        }
        
        expect(gameState.currentScore, equals(30));
        expect(gameState.difficultyLevel, equals(4));
        expect(gameState.gameSpeed, closeTo(1.15, 0.001));
      });

      test('should provide difficulty statistics', () {
        gameState.currentScore = 25;
        gameState.incrementScore(); // Score becomes 26
        
        final stats = gameState.difficultyStats;
        
        expect(stats['level'], equals(3));
        expect(stats['speed'], closeTo(1.10, 0.001));
        expect(stats['description'], equals('Easy'));
        expect(stats['isAtPlateau'], isFalse);
      });

      test('should handle plateau correctly at high scores', () {
        // Set score to trigger max difficulty
        gameState.currentScore = 199;
        gameState.incrementScore(); // Score becomes 200
        
        final stats = gameState.difficultyStats;
        
        expect(stats['level'], equals(20));
        expect(stats['isAtPlateau'], isTrue);
        expect(stats['nextLevelScore'], equals(-1));
      });
    });

    group('ObstacleManager and DifficultyManager Integration', () {
      test('should calculate correct spawn intervals for different difficulty levels', () {
        // Level 1
        obstacleManager.updateDifficulty(1.0, 1);
        final interval1 = DifficultyManager.calculateSpawnInterval(1);
        expect(interval1, equals(3.5));
        
        // Level 5
        obstacleManager.updateDifficulty(1.2, 5);
        final interval5 = DifficultyManager.calculateSpawnInterval(5);
        expect(interval5, equals(3.1));
        
        // Level 10
        obstacleManager.updateDifficulty(1.45, 10);
        final interval10 = DifficultyManager.calculateSpawnInterval(10);
        expect(interval10, equals(2.6));
      });

      test('should determine correct obstacle types for different levels', () {
        // Level 1 - only digital barriers
        final weights1 = DifficultyManager.getObstacleTypeWeights(1);
        expect(weights1.keys.length, equals(1));
        expect(weights1.containsKey(ObstacleType.digitalBarrier), isTrue);
        
        // Level 5 - digital barriers and laser grids
        final weights5 = DifficultyManager.getObstacleTypeWeights(5);
        expect(weights5.keys.length, equals(2));
        expect(weights5.containsKey(ObstacleType.digitalBarrier), isTrue);
        expect(weights5.containsKey(ObstacleType.laserGrid), isTrue);
        
        // Level 8 - all obstacle types
        final weights8 = DifficultyManager.getObstacleTypeWeights(8);
        expect(weights8.keys.length, equals(3));
        expect(weights8.containsKey(ObstacleType.digitalBarrier), isTrue);
        expect(weights8.containsKey(ObstacleType.laserGrid), isTrue);
        expect(weights8.containsKey(ObstacleType.floatingPlatform), isTrue);
      });

      test('should calculate correct simultaneous obstacle counts', () {
        // Level 1-4: single obstacles
        for (int level = 1; level <= 4; level++) {
          final count = DifficultyManager.calculateSimultaneousObstacles(level);
          expect(count, equals(1), reason: 'Level $level should have 1 obstacle');
        }
        
        // Level 5-7: still single obstacles
        for (int level = 5; level <= 7; level++) {
          final count = DifficultyManager.calculateSimultaneousObstacles(level);
          expect(count, equals(1), reason: 'Level $level should have 1 obstacle');
        }
        
        // Level 8-10: two obstacles
        for (int level = 8; level <= 10; level++) {
          final count = DifficultyManager.calculateSimultaneousObstacles(level);
          expect(count, equals(2), reason: 'Level $level should have 2 obstacles');
        }
        
        // Level 11+: three obstacles (capped)
        for (int level = 11; level <= 20; level++) {
          final count = DifficultyManager.calculateSimultaneousObstacles(level);
          expect(count, equals(3), reason: 'Level $level should have 3 obstacles');
        }
      });
    });

    group('Performance Characteristics', () {
      test('should maintain reasonable difficulty progression', () {
        for (int score = 0; score <= 200; score += 10) {
          final level = DifficultyManager.calculateDifficultyLevel(score);
          final speed = DifficultyManager.calculateGameSpeed(level);
          final interval = DifficultyManager.calculateSpawnInterval(level);
          
          // Speed should never exceed 2x
          expect(speed, lessThanOrEqualTo(2.0));
          
          // Spawn interval should never be too fast
          expect(interval, greaterThanOrEqualTo(1.5));
          
          // Difficulty level should be reasonable
          expect(level, lessThanOrEqualTo(20));
        }
      });

      test('should provide smooth difficulty transitions', () {
        final speeds = <double>[];
        final intervals = <double>[];
        
        for (int level = 1; level <= 10; level++) {
          speeds.add(DifficultyManager.calculateGameSpeed(level));
          intervals.add(DifficultyManager.calculateSpawnInterval(level));
        }
        
        // Check that speeds increase smoothly
        for (int i = 1; i < speeds.length; i++) {
          expect(speeds[i], greaterThan(speeds[i - 1]));
        }
        
        // Check that intervals decrease smoothly
        for (int i = 1; i < intervals.length; i++) {
          expect(intervals[i], lessThan(intervals[i - 1]));
        }
      });
    });

    group('Edge Cases', () {
      test('should handle score overflow gracefully', () {
        gameState.currentScore = 999999;
        gameState.incrementScore();
        
        expect(gameState.difficultyLevel, equals(20)); // Capped
        expect(gameState.gameSpeed, closeTo(1.95, 0.001)); // Capped
      });

      test('should handle rapid score increases', () {
        // Simulate rapid scoring
        for (int i = 0; i < 100; i++) {
          gameState.incrementScore();
        }
        
        expect(gameState.currentScore, equals(100));
        expect(gameState.difficultyLevel, equals(11));
        expect(gameState.gameSpeed, closeTo(1.5, 0.001));
        
        final stats = gameState.difficultyStats;
        expect(stats['description'], equals('Hard'));
      });
    });
  });
}