import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/game/neon_pulse_game.dart';
import 'package:neon_pulse_flappy_bird/models/game_state.dart';

void main() {
  group('Pause Integration Tests', () {
    late NeonPulseGame game;

    setUp(() {
      game = NeonPulseGame();
    });

    test('should pause all game components when game is paused', () async {
      // Initialize the game
      await game.onLoad();
      
      // Start the game
      game.startGame();
      expect(game.gameState.status, GameStatus.playing);
      expect(game.gameState.isPaused, false);
      
      // Record initial bird position
      final initialBirdPosition = game.bird.position.clone();
      
      // Pause the game
      game.pauseGame();
      expect(game.gameState.status, GameStatus.paused);
      expect(game.gameState.isPaused, true);
      
      // Simulate some time passing while paused
      game.update(1.0); // 1 second
      
      // Bird position should not have changed due to gravity
      expect(game.bird.position.x, initialBirdPosition.x);
      expect(game.bird.position.y, initialBirdPosition.y);
      
      // Resume the game
      game.resumeGame();
      expect(game.gameState.status, GameStatus.playing);
      expect(game.gameState.isPaused, false);
      
      // Now bird should be able to move again
      game.update(0.1); // Small time step
      // Bird should fall due to gravity after resume
      expect(game.bird.position.y, greaterThan(initialBirdPosition.y));
    });

    test('should preserve bird velocity when pausing and resuming', () async {
      // Initialize the game
      await game.onLoad();
      
      // Start the game
      game.startGame();
      
      // Make bird jump to give it upward velocity
      game.bird.jump();
      final velocityBeforePause = game.bird.velocity.clone();
      
      // Pause immediately after jump
      game.pauseGame();
      
      // Simulate time passing while paused
      game.update(0.5);
      
      // Velocity should be preserved during pause
      expect(game.bird.velocity.x, velocityBeforePause.x);
      expect(game.bird.velocity.y, velocityBeforePause.y);
      
      // Resume and check that physics continue from where they left off
      game.resumeGame();
      game.update(0.1);
      
      // Bird should continue with physics from the paused state
      expect(game.bird.velocity.y, greaterThan(velocityBeforePause.y)); // Gravity should have been applied
    });

    test('should not spawn obstacles while paused', () async {
      // Initialize the game
      await game.onLoad();
      
      // Start the game
      game.startGame();
      
      // Clear any existing obstacles
      game.obstacleManager.clearAllObstacles();
      final initialObstacleCount = game.obstacleManager.obstacles.length;
      
      // Pause the game
      game.pauseGame();
      
      // Force obstacle spawn timer to trigger (simulate long time)
      game.obstacleManager.spawnTimer = 10.0; // Much longer than spawn interval
      
      // Update the game while paused
      game.update(1.0);
      
      // No new obstacles should have been spawned
      expect(game.obstacleManager.obstacles.length, initialObstacleCount);
      
      // Resume and verify obstacles can spawn again
      game.resumeGame();
      // Note: We can't easily test spawning without mocking the random chance
      // but the important thing is that the pause prevented spawning
    });

    test('should not update power-ups while paused', () async {
      // Initialize the game
      await game.onLoad();
      
      // Start the game
      game.startGame();
      
      // Clear any existing power-ups
      game.powerUpManager.clearAll();
      
      // Pause the game
      game.pauseGame();
      
      // Force power-up spawn timer to trigger
      game.powerUpManager.spawnTimer = 20.0; // Much longer than spawn interval
      
      // Update while paused
      game.update(1.0);
      
      // No power-ups should have been spawned or updated
      expect(game.powerUpManager.activePowerUps.length, 0);
    });
  });
}