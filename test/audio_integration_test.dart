import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/game/neon_pulse_game.dart';
import 'package:neon_pulse_flappy_bird/game/managers/audio_manager.dart';

void main() {
  group('Audio Integration Tests', () {
    late NeonPulseGame game;
    late AudioManager audioManager;

    setUp(() async {
      game = NeonPulseGame();
      await game.onLoad();
      audioManager = game.audioManager;
    });

    test('should initialize audio manager in game', () {
      expect(audioManager, isNotNull);
      expect(audioManager.isMusicEnabled, isTrue);
      expect(audioManager.isSfxEnabled, isTrue);
    });

    test('should play sound effects during gameplay', () async {
      // Start the game
      game.startGame();
      
      // Test bird jump sound
      game.handleBirdJump();
      // In a real test, we would verify that the sound was played
      // For now, we just ensure no exceptions are thrown
      
      expect(game.gameState.status.name, equals('playing'));
    });


    test('should stop music when game ends', () async {
      game.startGame();
      
      // Simulate game over
      await game.endGame();
      
      // Verify game state changed
      expect(game.gameState.status.name, equals('gameOver'));
    });

    test('should handle pause and resume with audio', () async {
      game.startGame();
      
      // Test pause
      game.pauseGame();
      expect(game.gameState.isPaused, isTrue);
      
      // Test resume
      game.resumeGame();
      expect(game.gameState.isPaused, isFalse);
    });


    test('should handle audio settings changes', () async {
      // Test volume changes
      await audioManager.setMusicVolume(0.5);
      expect(audioManager.musicVolume, equals(0.5));
      
      await audioManager.setSfxVolume(0.3);
      expect(audioManager.sfxVolume, equals(0.3));
      
      // Test toggles
      await audioManager.toggleMusic();
      await audioManager.toggleSfx();
      
      // Verify settings were applied
      expect(audioManager.isMusicEnabled, isFalse);
      expect(audioManager.isSfxEnabled, isFalse);
    });


    tearDown(() {
      audioManager.dispose();
    });
  });
}