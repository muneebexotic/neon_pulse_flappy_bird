import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neon_pulse_flappy_bird/models/game_state.dart';

void main() {
  group('GameState Tests', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
    });

    group('Initialization', () {
      test('should initialize with default values', () {
        expect(gameState.currentScore, equals(0));
        expect(gameState.highScore, equals(0));
        expect(gameState.gameSpeed, equals(1.0));
        expect(gameState.difficultyLevel, equals(1));
        expect(gameState.status, equals(GameStatus.menu));
        expect(gameState.isPaused, equals(false));
        expect(gameState.isGameOver, equals(false));
      });

      test('should initialize with custom values', () {
        final customGameState = GameState(
          currentScore: 10,
          highScore: 50,
          gameSpeed: 1.5,
          difficultyLevel: 3,
          status: GameStatus.playing,
          isPaused: true,
          isGameOver: true,
        );

        expect(customGameState.currentScore, equals(10));
        expect(customGameState.highScore, equals(50));
        expect(customGameState.gameSpeed, equals(1.5));
        expect(customGameState.difficultyLevel, equals(3));
        expect(customGameState.status, equals(GameStatus.playing));
        expect(customGameState.isPaused, equals(true));
        expect(customGameState.isGameOver, equals(true));
      });
    });

    group('Game State Management', () {
      test('should reset game state correctly', () {
        // Set some non-default values
        gameState.currentScore = 25;
        gameState.gameSpeed = 2.0;
        gameState.difficultyLevel = 5;
        gameState.status = GameStatus.gameOver;
        gameState.isPaused = true;
        gameState.isGameOver = true;

        // Reset the game state
        gameState.reset();

        // Verify reset values
        expect(gameState.currentScore, equals(0));
        expect(gameState.gameSpeed, equals(1.0));
        expect(gameState.difficultyLevel, equals(1));
        expect(gameState.status, equals(GameStatus.playing));
        expect(gameState.isPaused, equals(false));
        expect(gameState.isGameOver, equals(false));
        
        // High score should not be reset (it should remain unchanged)
        // Since we didn't set a high score in this test, it should still be 0
        expect(gameState.highScore, equals(0));
      });

      test('should end game correctly', () async {
        gameState.currentScore = 15;
        gameState.status = GameStatus.playing;
        gameState.isGameOver = false;

        await gameState.endGame();

        expect(gameState.status, equals(GameStatus.gameOver));
        expect(gameState.isGameOver, equals(true));
      });
    });

    group('Scoring System', () {
      test('should increment score correctly', () {
        expect(gameState.currentScore, equals(0));
        expect(gameState.difficultyLevel, equals(1));
        expect(gameState.gameSpeed, equals(1.0));

        gameState.incrementScore();

        expect(gameState.currentScore, equals(1));
        expect(gameState.difficultyLevel, equals(1)); // Should not change yet
        expect(gameState.gameSpeed, equals(1.0)); // Should not change yet
      });

      test('should increase difficulty every 10 points', () {
        // Score 9 points - should not increase difficulty
        for (int i = 0; i < 9; i++) {
          gameState.incrementScore();
        }
        expect(gameState.currentScore, equals(9));
        expect(gameState.difficultyLevel, equals(1));
        expect(gameState.gameSpeed, equals(1.0));

        // Score the 10th point - should increase difficulty
        gameState.incrementScore();
        expect(gameState.currentScore, equals(10));
        expect(gameState.difficultyLevel, equals(2));
        expect(gameState.gameSpeed, equals(1.05)); // 5% increase

        // Score 10 more points - should increase difficulty again
        for (int i = 0; i < 10; i++) {
          gameState.incrementScore();
        }
        expect(gameState.currentScore, equals(20));
        expect(gameState.difficultyLevel, equals(3));
        expect(gameState.gameSpeed, equals(1.10)); // 10% increase from base
      });

      test('should calculate game speed correctly for various difficulty levels', () {
        // Test multiple difficulty levels
        final testCases = [
          {'score': 10, 'expectedLevel': 2, 'expectedSpeed': 1.05},
          {'score': 20, 'expectedLevel': 3, 'expectedSpeed': 1.10},
          {'score': 50, 'expectedLevel': 6, 'expectedSpeed': 1.25},
          {'score': 100, 'expectedLevel': 11, 'expectedSpeed': 1.50},
        ];

        for (final testCase in testCases) {
          gameState.reset();
          final targetScore = testCase['score'] as int;
          
          for (int i = 0; i < targetScore; i++) {
            gameState.incrementScore();
          }

          expect(gameState.currentScore, equals(targetScore));
          expect(gameState.difficultyLevel, equals(testCase['expectedLevel']));
          expect(gameState.gameSpeed, closeTo(testCase['expectedSpeed'] as double, 0.001));
        }
      });
    });

    group('High Score Management', () {
      test('should update high score when current score is higher', () async {
        gameState.highScore = 10;
        gameState.currentScore = 15;

        await gameState.updateHighScore();

        expect(gameState.highScore, equals(15));
      });

      test('should not update high score when current score is lower', () async {
        gameState.highScore = 20;
        gameState.currentScore = 15;

        await gameState.updateHighScore();

        expect(gameState.highScore, equals(20));
      });

      test('should not update high score when current score is equal', () async {
        gameState.highScore = 15;
        gameState.currentScore = 15;

        await gameState.updateHighScore();

        expect(gameState.highScore, equals(15));
      });

      test('should load high score from shared preferences', () async {
        // Set up mock data
        SharedPreferences.setMockInitialValues({'high_score': 42});

        await gameState.loadHighScore();

        expect(gameState.highScore, equals(42));
      });

      test('should use default high score when no saved data exists', () async {
        // Ensure no saved data
        SharedPreferences.setMockInitialValues({});

        await gameState.loadHighScore();

        expect(gameState.highScore, equals(0));
      });

      test('should save high score to shared preferences when updated', () async {
        SharedPreferences.setMockInitialValues({});
        
        gameState.currentScore = 25;
        await gameState.updateHighScore();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('high_score'), equals(25));
      });
    });

    group('Game State Transitions', () {
      test('should transition from menu to playing when reset', () {
        gameState.status = GameStatus.menu;
        gameState.reset();
        expect(gameState.status, equals(GameStatus.playing));
      });

      test('should transition from playing to game over when ended', () async {
        gameState.status = GameStatus.playing;
        await gameState.endGame();
        expect(gameState.status, equals(GameStatus.gameOver));
      });

      test('should maintain high score through game state transitions', () async {
        gameState.highScore = 50;
        gameState.currentScore = 30;

        // End game
        await gameState.endGame();
        expect(gameState.highScore, equals(50));

        // Reset game
        gameState.reset();
        expect(gameState.highScore, equals(50));
      });

      test('should update high score when ending game with new record', () async {
        gameState.highScore = 20;
        gameState.currentScore = 35;

        await gameState.endGame();

        expect(gameState.highScore, equals(35));
        expect(gameState.status, equals(GameStatus.gameOver));
        expect(gameState.isGameOver, equals(true));
      });
    });

    group('Edge Cases', () {
      test('should handle zero scores correctly', () {
        gameState.currentScore = 0;
        gameState.incrementScore();
        
        expect(gameState.currentScore, equals(1));
        expect(gameState.difficultyLevel, equals(1));
      });

      test('should handle large scores correctly', () {
        // Test with a large score
        gameState.currentScore = 999;
        gameState.incrementScore();
        
        expect(gameState.currentScore, equals(1000));
        expect(gameState.difficultyLevel, equals(101)); // (1000 / 10) + 1
        expect(gameState.gameSpeed, equals(6.0)); // 1.0 + (100 * 0.05)
      });

      test('should handle negative high scores gracefully', () async {
        SharedPreferences.setMockInitialValues({'high_score': -5});
        
        await gameState.loadHighScore();
        
        // Should load the negative value as stored
        expect(gameState.highScore, equals(-5));
        
        // But updating with 0 should work correctly
        gameState.currentScore = 0;
        await gameState.updateHighScore();
        expect(gameState.highScore, equals(0));
      });
    });
  });
}