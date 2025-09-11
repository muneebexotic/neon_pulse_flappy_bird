import 'package:shared_preferences/shared_preferences.dart';
import '../game/managers/difficulty_manager.dart';

/// Represents the current state of the game
enum GameStatus {
  menu,
  playing,
  paused,
  gameOver,
}

/// Main game state model that tracks all game progress and settings
class GameState {
  int currentScore;
  int highScore;
  double gameSpeed;
  int difficultyLevel;
  GameStatus status;
  bool isPaused;
  bool isGameOver;
  
  GameState({
    this.currentScore = 0,
    this.highScore = 0,
    this.gameSpeed = 1.0,
    this.difficultyLevel = 1,
    this.status = GameStatus.menu,
    this.isPaused = false,
    this.isGameOver = false,
  });

  /// Reset game state for a new game
  void reset() {
    currentScore = 0;
    gameSpeed = 1.0;
    difficultyLevel = 1;
    status = GameStatus.playing;
    isPaused = false;
    isGameOver = false;
  }

  /// Update high score if current score is higher and save to local storage
  Future<void> updateHighScore() async {
    if (currentScore > highScore) {
      highScore = currentScore;
      await _saveHighScore();
    }
  }

  /// Load high score from local storage
  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('high_score') ?? 0;
  }

  /// Save high score to local storage
  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('high_score', highScore);
  }

  /// Increment score and adjust difficulty
  void incrementScore() {
    currentScore++;
    
    // Update difficulty using DifficultyManager
    difficultyLevel = DifficultyManager.calculateDifficultyLevel(currentScore);
    gameSpeed = DifficultyManager.calculateGameSpeed(difficultyLevel);
  }
  
  /// Get difficulty statistics
  Map<String, dynamic> get difficultyStats {
    return DifficultyManager.getDifficultyStats(currentScore);
  }

  /// End the game
  Future<void> endGame() async {
    status = GameStatus.gameOver;
    isGameOver = true;
    await updateHighScore();
  }
}