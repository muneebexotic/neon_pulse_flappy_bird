import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/models/game_state.dart';

void main() {
  group('Pause Functionality Tests', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
    });

    test('should initialize with correct default state', () {
      expect(gameState.status, GameStatus.menu);
      expect(gameState.isPaused, false);
      expect(gameState.canPause(), false);
      expect(gameState.canResume(), false);
    });

    test('should allow pausing when playing', () {
      // Start playing
      gameState.status = GameStatus.playing;
      
      expect(gameState.canPause(), true);
      expect(gameState.canResume(), false);
      
      // Pause the game
      gameState.pauseGame();
      
      expect(gameState.status, GameStatus.paused);
      expect(gameState.isPaused, true);
      expect(gameState.canPause(), false);
      expect(gameState.canResume(), true);
    });

    test('should allow resuming when paused', () {
      // Start playing and then pause
      gameState.status = GameStatus.playing;
      gameState.pauseGame();
      
      expect(gameState.status, GameStatus.paused);
      expect(gameState.isPaused, true);
      
      // Resume the game
      gameState.resumeGame();
      
      expect(gameState.status, GameStatus.playing);
      expect(gameState.isPaused, false);
      expect(gameState.canPause(), true);
      expect(gameState.canResume(), false);
    });

    test('should not pause when not playing', () {
      gameState.status = GameStatus.menu;
      
      expect(gameState.canPause(), false);
      
      gameState.pauseGame();
      
      // Should remain in menu state
      expect(gameState.status, GameStatus.menu);
      expect(gameState.isPaused, false);
    });

    test('should not resume when not paused', () {
      gameState.status = GameStatus.playing;
      
      expect(gameState.canResume(), false);
      
      gameState.resumeGame();
      
      // Should remain in playing state
      expect(gameState.status, GameStatus.playing);
      expect(gameState.isPaused, false);
    });

    test('should clear pause state when ending game', () {
      // Start playing and pause
      gameState.status = GameStatus.playing;
      gameState.pauseGame();
      
      expect(gameState.status, GameStatus.paused);
      expect(gameState.isPaused, true);
      
      // End the game
      gameState.endGame();
      
      expect(gameState.status, GameStatus.gameOver);
      expect(gameState.isPaused, false);
      expect(gameState.canPause(), false);
      expect(gameState.canResume(), false);
    });

    test('should preserve state correctly across pause/resume cycles', () {
      // Start playing
      gameState.status = GameStatus.playing;
      gameState.currentScore = 10;
      
      // Pause
      gameState.pauseGame();
      expect(gameState.status, GameStatus.paused);
      expect(gameState.currentScore, 10); // Score should be preserved
      
      // Resume
      gameState.resumeGame();
      expect(gameState.status, GameStatus.playing);
      expect(gameState.currentScore, 10); // Score should still be preserved
      
      // Pause again
      gameState.pauseGame();
      expect(gameState.status, GameStatus.paused);
      expect(gameState.currentScore, 10); // Score should still be preserved
    });
  });
}