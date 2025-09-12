import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/game/neon_pulse_game.dart';
import '../lib/game/managers/settings_manager.dart';

void main() {
  group('Settings Integration Tests', () {
    late NeonPulseGame game;
    late SettingsManager settingsManager;

    setUp(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      // Create game instance
      game = NeonPulseGame();
      await game.onLoad();
      
      settingsManager = game.settingsManager;
    });

    test('should apply difficulty settings to gameplay', () async {
      // Set difficulty to hard
      await settingsManager.setDifficultyLevel(DifficultyLevel.hard);
      
      // Update game settings
      await game.updateSettings();
      
      // Verify difficulty is applied
      expect(settingsManager.difficultyLevel, DifficultyLevel.hard);
      expect(settingsManager.difficultyLevel.speedMultiplier, 1.3);
      expect(settingsManager.difficultyLevel.gapSizeMultiplier, 0.8);
    });

    test('should apply graphics quality settings', () async {
      // Set graphics quality to low
      await settingsManager.setGraphicsQuality(GraphicsQuality.low);
      
      // Update game settings
      await game.updateSettings();
      
      // Verify graphics quality is applied
      expect(settingsManager.graphicsQuality, GraphicsQuality.low);
    });

    test('should apply particle quality settings', () async {
      // Set particle quality to ultra
      await settingsManager.setParticleQuality(ParticleQuality.ultra);
      
      // Update game settings
      await game.updateSettings();
      
      // Verify particle quality is applied
      expect(settingsManager.particleQuality, ParticleQuality.ultra);
      expect(settingsManager.particleQuality.maxParticles, 500);
    });

    test('should apply control settings', () async {
      // Set custom control settings
      await settingsManager.setTapSensitivity(1.5);
      await settingsManager.setDoubleTapTiming(400.0);
      
      // Update game settings
      await game.updateSettings();
      
      // Verify control settings are applied
      expect(settingsManager.tapSensitivity, 1.5);
      expect(settingsManager.doubleTapTiming, 400.0);
      expect(game.inputHandler.tapSensitivity, 1.5);
    });

    test('should apply performance monitor settings', () async {
      // Enable performance monitor
      await settingsManager.setPerformanceMonitorEnabled(true);
      
      // Update game settings
      await game.updateSettings();
      
      // Verify performance monitor is enabled
      expect(settingsManager.performanceMonitorEnabled, true);
    });

    test('should apply audio settings', () async {
      // Set custom audio settings
      await settingsManager.setMusicVolume(0.5);
      await settingsManager.setSfxVolume(0.8);
      await settingsManager.setMusicEnabled(false);
      
      // Update game settings
      await game.updateSettings();
      
      // Verify audio settings are applied
      expect(settingsManager.musicVolume, 0.5);
      expect(settingsManager.sfxVolume, 0.8);
      expect(settingsManager.musicEnabled, false);
    });

    test('should auto-adjust quality based on performance', () async {
      // Enable auto quality adjustment
      await settingsManager.setAutoQualityAdjustment(true);
      await settingsManager.setGraphicsQuality(GraphicsQuality.auto);
      await settingsManager.setPerformanceMonitorEnabled(true);
      
      // Update game settings
      await game.updateSettings();
      
      // Verify auto adjustment is enabled
      expect(settingsManager.autoQualityAdjustment, true);
      expect(settingsManager.graphicsQuality, GraphicsQuality.auto);
    });

    test('should recommend quality based on performance score', () {
      // Test graphics quality recommendations
      expect(
        settingsManager.getRecommendedGraphicsQuality(0.9),
        GraphicsQuality.ultra,
      );
      expect(
        settingsManager.getRecommendedGraphicsQuality(0.3),
        GraphicsQuality.low,
      );

      // Test particle quality recommendations
      expect(
        settingsManager.getRecommendedParticleQuality(0.8),
        ParticleQuality.ultra,
      );
      expect(
        settingsManager.getRecommendedParticleQuality(0.2),
        ParticleQuality.low,
      );
    });

    test('should persist settings across game sessions', () async {
      // Set various settings
      await settingsManager.setDifficultyLevel(DifficultyLevel.easy);
      await settingsManager.setGraphicsQuality(GraphicsQuality.high);
      await settingsManager.setTapSensitivity(0.7);
      
      // Create new game instance (simulating app restart)
      final newGame = NeonPulseGame();
      await newGame.onLoad();
      
      // Verify settings are persisted
      expect(newGame.settingsManager.difficultyLevel, DifficultyLevel.easy);
      expect(newGame.settingsManager.graphicsQuality, GraphicsQuality.high);
      expect(newGame.settingsManager.tapSensitivity, 0.7);
    });

    test('should validate setting bounds', () async {
      // Test tap sensitivity bounds
      await settingsManager.setTapSensitivity(3.0); // Above max
      expect(settingsManager.tapSensitivity, 2.0);
      
      await settingsManager.setTapSensitivity(0.1); // Below min
      expect(settingsManager.tapSensitivity, 0.5);
      
      // Test double-tap timing bounds
      await settingsManager.setDoubleTapTiming(600.0); // Above max
      expect(settingsManager.doubleTapTiming, 500.0);
      
      await settingsManager.setDoubleTapTiming(100.0); // Below min
      expect(settingsManager.doubleTapTiming, 200.0);
      
      // Test volume bounds
      await settingsManager.setMusicVolume(1.5); // Above max
      expect(settingsManager.musicVolume, 1.0);
      
      await settingsManager.setMusicVolume(-0.5); // Below min
      expect(settingsManager.musicVolume, 0.0);
    });
  });
}