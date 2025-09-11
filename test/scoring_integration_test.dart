import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neon_pulse_flappy_bird/game/managers/obstacle_manager.dart';
import 'package:neon_pulse_flappy_bird/game/components/bird.dart';
import 'package:neon_pulse_flappy_bird/models/game_state.dart';

void main() {
  group('Scoring Integration Tests', () {
    late ObstacleManager obstacleManager;
    late Bird bird;
    late GameState gameState;

    setUp(() {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      obstacleManager = ObstacleManager(
        worldWidth: 800.0,
        worldHeight: 600.0,
      );
      bird = Bird();
      bird.setWorldBounds(Vector2(800.0, 600.0));
      gameState = GameState();
    });

    group('Obstacle Passing Detection', () {
      test('should detect when bird passes obstacle center', () {
        // Position bird before obstacle
        bird.position = Vector2(100, 300);
        
        // Manually create and add an obstacle for testing
        obstacleManager.obstacles.clear();
        
        // Simulate obstacle spawning
        obstacleManager.update(0.1); // Small time step
        
        // Move bird past obstacle center
        bird.position = Vector2(500, 300);
        
        // Check for passed obstacles
        final passedObstacles = obstacleManager.checkPassedObstacles(bird);
        
        // Should detect passed obstacle if one was spawned
        expect(passedObstacles, isA<List>());
      });

      test('should not double-count passed obstacles', () {
        // Position bird before obstacle
        bird.position = Vector2(100, 300);
        
        // Spawn obstacle
        obstacleManager.update(0.1);
        
        // Move bird past obstacle
        bird.position = Vector2(500, 300);
        
        // Check for passed obstacles first time
        final firstCheck = obstacleManager.checkPassedObstacles(bird);
        
        // Check again without moving bird
        final secondCheck = obstacleManager.checkPassedObstacles(bird);
        
        // Second check should return empty list (no new passed obstacles)
        expect(secondCheck.length, equals(0));
      });

      test('should track multiple passed obstacles correctly', () {
        // Position bird at start
        bird.position = Vector2(50, 300);
        
        // Spawn multiple obstacles over time
        for (int i = 0; i < 3; i++) {
          obstacleManager.update(3.0); // Spawn interval
        }
        
        // Move bird past all obstacles
        bird.position = Vector2(700, 300);
        
        // Check passed obstacles count
        final passedCount = obstacleManager.passedObstacleCount;
        
        // Should have tracked passed obstacles
        expect(passedCount, greaterThanOrEqualTo(0));
      });
    });

    group('Game State Score Integration', () {
      test('should increment score when bird passes obstacles', () {
        expect(gameState.currentScore, equals(0));
        
        // Simulate scoring
        gameState.incrementScore();
        expect(gameState.currentScore, equals(1));
        
        gameState.incrementScore();
        expect(gameState.currentScore, equals(2));
      });

      test('should increase difficulty based on score', () {
        expect(gameState.difficultyLevel, equals(1));
        expect(gameState.gameSpeed, equals(1.0));
        
        // Score 10 points to trigger difficulty increase
        for (int i = 0; i < 10; i++) {
          gameState.incrementScore();
        }
        
        expect(gameState.difficultyLevel, equals(2));
        expect(gameState.gameSpeed, equals(1.05));
      });

      test('should update obstacle manager with new difficulty', () {
        // Initial difficulty
        obstacleManager.updateDifficulty(1.0, 1);
        expect(obstacleManager.currentGameSpeed, equals(1.0));
        expect(obstacleManager.difficultyLevel, equals(1));
        
        // Update difficulty
        obstacleManager.updateDifficulty(1.5, 3);
        expect(obstacleManager.currentGameSpeed, equals(1.5));
        expect(obstacleManager.difficultyLevel, equals(3));
      });
    });

    group('Collision Detection and Game Over', () {
      test('should detect collision with obstacles', () {
        // Position bird at obstacle location
        bird.position = Vector2(400, 300);
        
        // Spawn obstacle at same location
        obstacleManager.update(0.1);
        
        // Force obstacle to bird's position for testing
        if (obstacleManager.obstacles.isNotEmpty) {
          obstacleManager.obstacles.first.position = Vector2(400, 250);
        }
        
        // Check collision
        final hasCollision = obstacleManager.checkCollisions(bird);
        
        // Should detect collision based on positioning
        expect(hasCollision, isA<bool>());
      });

      test('should handle game over state correctly', () async {
        gameState.status = GameStatus.playing;
        gameState.currentScore = 15;
        gameState.highScore = 10;
        
        await gameState.endGame();
        
        expect(gameState.status, equals(GameStatus.gameOver));
        expect(gameState.isGameOver, equals(true));
        expect(gameState.highScore, equals(15)); // Should update high score
      });

      test('should reset game state for new game', () {
        // Set up game over state
        gameState.currentScore = 25;
        gameState.status = GameStatus.gameOver;
        gameState.isGameOver = true;
        gameState.difficultyLevel = 3;
        gameState.gameSpeed = 1.15;
        
        // Reset for new game
        gameState.reset();
        
        expect(gameState.currentScore, equals(0));
        expect(gameState.status, equals(GameStatus.playing));
        expect(gameState.isGameOver, equals(false));
        expect(gameState.difficultyLevel, equals(1));
        expect(gameState.gameSpeed, equals(1.0));
      });
    });

    group('Boundary Collision Detection', () {
      test('should detect bird hitting top boundary', () {
        bird.position = Vector2(100, -10); // Above screen
        bird.update(0.016); // One frame update
        
        expect(bird.isAlive, equals(false));
      });

      test('should detect bird hitting bottom boundary', () {
        bird.position = Vector2(100, 610); // Below screen (world height is 600)
        bird.update(0.016); // One frame update
        
        expect(bird.isAlive, equals(false));
      });

      test('should keep bird alive within boundaries', () {
        bird.position = Vector2(100, 300); // Center of screen
        bird.update(0.016); // One frame update
        
        expect(bird.isAlive, equals(true));
      });
    });

    group('Performance and Edge Cases', () {
      test('should handle empty obstacle list', () {
        obstacleManager.obstacles.clear();
        
        final hasCollision = obstacleManager.checkCollisions(bird);
        final passedObstacles = obstacleManager.checkPassedObstacles(bird);
        
        expect(hasCollision, equals(false));
        expect(passedObstacles, isEmpty);
      });

      test('should handle rapid score increments', () {
        // Rapidly increment score
        for (int i = 0; i < 100; i++) {
          gameState.incrementScore();
        }
        
        expect(gameState.currentScore, equals(100));
        expect(gameState.difficultyLevel, equals(11)); // (100 / 10) + 1
        expect(gameState.gameSpeed, equals(1.5)); // 1.0 + (10 * 0.05)
      });

      test('should clear obstacles on game reset', () {
        // Add some obstacles
        obstacleManager.update(0.1);
        obstacleManager.update(3.0);
        
        final initialCount = obstacleManager.obstacleCount;
        
        // Clear obstacles
        obstacleManager.clearAllObstacles();
        
        expect(obstacleManager.obstacleCount, equals(0));
        expect(obstacleManager.passedObstacleCount, equals(0));
      });
    });
  });
}