import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neon_pulse_flappy_bird/game/neon_pulse_game.dart';
import 'package:neon_pulse_flappy_bird/models/game_state.dart';
import 'package:neon_pulse_flappy_bird/game/components/bird.dart';

void main() {
  group('Game Integration Tests', () {
    late NeonPulseGame game;
    
    setUp(() async {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      game = NeonPulseGame();
      await game.onLoad();
    });
    
    test('should handle bird jump during gameplay', () {
      // Arrange
      game.startGame();
      expect(game.gameState.status, equals(GameStatus.playing));
      
      final initialVelocity = game.bird.velocity.y;
      
      // Act - Directly call the jump handling method
      game.handleBirdJump();
      
      // Assert
      expect(game.bird.velocity.y, lessThan(initialVelocity));
      expect(game.bird.velocity.y, equals(Bird.jumpForce));
    });
    
    test('should start game from menu', () {
      // Arrange
      expect(game.gameState.status, equals(GameStatus.menu));
      
      // Act
      game.startGame();
      
      // Assert
      expect(game.gameState.status, equals(GameStatus.playing));
    });
    
    test('should handle bird boundary collision and game over', () {
      // Arrange
      game.startGame();
      game.bird.position.y = -10; // Position bird outside boundary
      
      // Act
      game.update(0.016); // One frame update
      
      // Assert
      expect(game.bird.isAlive, isFalse);
      expect(game.gameState.status, equals(GameStatus.gameOver));
    });
    
    test('should reset bird state when starting new game', () {
      // Arrange
      game.startGame();
      game.bird.velocity.y = 200;
      game.bird.position.y = 500;
      game.bird.isAlive = false;
      
      // Act
      game.startGame();
      
      // Assert
      expect(game.bird.velocity.y, equals(0));
      expect(game.bird.position.y, equals(300)); // Center of world height
      expect(game.bird.isAlive, isTrue);
    });
    
    test('should handle game state transitions correctly', () {
      // Test menu -> playing
      expect(game.gameState.status, equals(GameStatus.menu));
      game.startGame();
      expect(game.gameState.status, equals(GameStatus.playing));
      
      // Test playing -> paused
      game.pauseGame();
      expect(game.gameState.status, equals(GameStatus.paused));
      expect(game.gameState.isPaused, isTrue);
      
      // Test paused -> playing
      game.resumeGame();
      expect(game.gameState.status, equals(GameStatus.playing));
      expect(game.gameState.isPaused, isFalse);
      
      // Test playing -> game over
      game.endGame();
      expect(game.gameState.status, equals(GameStatus.gameOver));
    });
  });
}