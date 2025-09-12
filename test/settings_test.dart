import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/game/managers/settings_manager.dart';

void main() {
  group('SettingsManager Tests', () {
    late SettingsManager settingsManager;

    setUp(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      settingsManager = SettingsManager();
      await settingsManager.initialize();
    });

    group('Graphics Settings', () {
      test('should set and get graphics quality', () async {
        await settingsManager.setGraphicsQuality(GraphicsQuality.high);
        expect(settingsManager.graphicsQuality, GraphicsQuality.high);
      });

      test('should set and get particle quality', () async {
        await settingsManager.setParticleQuality(ParticleQuality.ultra);
        expect(settingsManager.particleQuality, ParticleQuality.ultra);
      });

      test('should recommend graphics quality based on performance', () {
        expect(
          settingsManager.getRecommendedGraphicsQuality(0.9),
          GraphicsQuality.ultra,
        );
        expect(
          settingsManager.getRecommendedGraphicsQuality(0.7),
          GraphicsQuality.high,
        );
        expect(
          settingsManager.getRecommendedGraphicsQuality(0.5),
          GraphicsQuality.medium,
        );
        expect(
          settingsManager.getRecommendedGraphicsQuality(0.3),
          GraphicsQuality.low,
        );
      });

      test('should recommend particle quality based on performance', () {
        expect(
          settingsManager.getRecommendedParticleQuality(0.8),
          ParticleQuality.ultra,
        );
        expect(
          settingsManager.getRecommendedParticleQuality(0.6),
          ParticleQuality.high,
        );
        expect(
          settingsManager.getRecommendedParticleQuality(0.4),
          ParticleQuality.medium,
        );
        expect(
          settingsManager.getRecommendedParticleQuality(0.2),
          ParticleQuality.low,
        );
      });
    });

    group('Difficulty Settings', () {
      test('should set and get difficulty level', () async {
        await settingsManager.setDifficultyLevel(DifficultyLevel.hard);
        expect(settingsManager.difficultyLevel, DifficultyLevel.hard);
      });

      test('should provide correct speed multipliers', () {
        expect(DifficultyLevel.easy.speedMultiplier, 0.8);
        expect(DifficultyLevel.normal.speedMultiplier, 1.0);
        expect(DifficultyLevel.hard.speedMultiplier, 1.3);
      });

      test('should provide correct gap size multipliers', () {
        expect(DifficultyLevel.easy.gapSizeMultiplier, 1.3);
        expect(DifficultyLevel.normal.gapSizeMultiplier, 1.0);
        expect(DifficultyLevel.hard.gapSizeMultiplier, 0.8);
      });
    });

    group('Control Settings', () {
      test('should set and get tap sensitivity within bounds', () async {
        await settingsManager.setTapSensitivity(1.5);
        expect(settingsManager.tapSensitivity, 1.5);

        // Test clamping
        await settingsManager.setTapSensitivity(3.0);
        expect(settingsManager.tapSensitivity, 2.0);

        await settingsManager.setTapSensitivity(0.1);
        expect(settingsManager.tapSensitivity, 0.5);
      });

      test('should set and get double-tap timing within bounds', () async {
        await settingsManager.setDoubleTapTiming(350.0);
        expect(settingsManager.doubleTapTiming, 350.0);

        // Test clamping
        await settingsManager.setDoubleTapTiming(600.0);
        expect(settingsManager.doubleTapTiming, 500.0);

        await settingsManager.setDoubleTapTiming(100.0);
        expect(settingsManager.doubleTapTiming, 200.0);
      });
    });

    group('Performance Settings', () {
      test('should set and get performance monitor enabled', () async {
        await settingsManager.setPerformanceMonitorEnabled(true);
        expect(settingsManager.performanceMonitorEnabled, true);

        await settingsManager.setPerformanceMonitorEnabled(false);
        expect(settingsManager.performanceMonitorEnabled, false);
      });

      test('should set and get auto quality adjustment', () async {
        await settingsManager.setAutoQualityAdjustment(false);
        expect(settingsManager.autoQualityAdjustment, false);

        await settingsManager.setAutoQualityAdjustment(true);
        expect(settingsManager.autoQualityAdjustment, true);
      });
    });

    group('Audio Settings Persistence', () {
      test('should set and get music volume within bounds', () async {
        await settingsManager.setMusicVolume(0.5);
        expect(settingsManager.musicVolume, 0.5);

        // Test clamping
        await settingsManager.setMusicVolume(1.5);
        expect(settingsManager.musicVolume, 1.0);

        await settingsManager.setMusicVolume(-0.5);
        expect(settingsManager.musicVolume, 0.0);
      });

      test('should set and get SFX volume within bounds', () async {
        await settingsManager.setSfxVolume(0.8);
        expect(settingsManager.sfxVolume, 0.8);

        // Test clamping
        await settingsManager.setSfxVolume(2.0);
        expect(settingsManager.sfxVolume, 1.0);

        await settingsManager.setSfxVolume(-1.0);
        expect(settingsManager.sfxVolume, 0.0);
      });

      test('should set and get audio enabled flags', () async {
        await settingsManager.setMusicEnabled(false);
        expect(settingsManager.musicEnabled, false);

        await settingsManager.setSfxEnabled(false);
        expect(settingsManager.sfxEnabled, false);

        await settingsManager.setBeatSyncEnabled(false);
        expect(settingsManager.beatSyncEnabled, false);
      });
    });

    group('Particle Quality Enum', () {
      test('should provide correct max particles for each quality', () {
        expect(ParticleQuality.low.maxParticles, 50);
        expect(ParticleQuality.medium.maxParticles, 150);
        expect(ParticleQuality.high.maxParticles, 300);
        expect(ParticleQuality.ultra.maxParticles, 500);
      });

      test('should have correct display names and descriptions', () {
        expect(ParticleQuality.low.displayName, 'Low');
        expect(ParticleQuality.low.description, 'Minimal particles (50)');
        
        expect(ParticleQuality.medium.displayName, 'Medium');
        expect(ParticleQuality.medium.description, 'Moderate particles (150)');
        
        expect(ParticleQuality.high.displayName, 'High');
        expect(ParticleQuality.high.description, 'Rich particle effects (300)');
        
        expect(ParticleQuality.ultra.displayName, 'Ultra');
        expect(ParticleQuality.ultra.description, 'Maximum particles (500)');
      });
    });

    group('Graphics Quality Enum', () {
      test('should have correct display names and descriptions', () {
        expect(GraphicsQuality.low.displayName, 'Low');
        expect(GraphicsQuality.low.description, 'Minimal effects for best performance');
        
        expect(GraphicsQuality.medium.displayName, 'Medium');
        expect(GraphicsQuality.medium.description, 'Balanced quality and performance');
        
        expect(GraphicsQuality.high.displayName, 'High');
        expect(GraphicsQuality.high.description, 'Enhanced visuals with good performance');
        
        expect(GraphicsQuality.ultra.displayName, 'Ultra');
        expect(GraphicsQuality.ultra.description, 'Maximum quality for high-end devices');
        
        expect(GraphicsQuality.auto.displayName, 'Auto');
        expect(GraphicsQuality.auto.description, 'Automatically adjust based on performance');
      });
    });

    group('Difficulty Level Enum', () {
      test('should have correct display names and descriptions', () {
        expect(DifficultyLevel.easy.displayName, 'Easy');
        expect(DifficultyLevel.easy.description, 'Slower speed, larger gaps, more forgiving');
        
        expect(DifficultyLevel.normal.displayName, 'Normal');
        expect(DifficultyLevel.normal.description, 'Standard Flappy Bird difficulty');
        
        expect(DifficultyLevel.hard.displayName, 'Hard');
        expect(DifficultyLevel.hard.description, 'Faster speed, smaller gaps, challenging');
      });
    });

    group('Settings Persistence', () {
      test('should persist settings across initialization', () async {
        // Set some values
        await settingsManager.setGraphicsQuality(GraphicsQuality.ultra);
        await settingsManager.setDifficultyLevel(DifficultyLevel.hard);
        await settingsManager.setTapSensitivity(1.5);
        await settingsManager.setPerformanceMonitorEnabled(true);

        // Create new instance and initialize
        final newSettingsManager = SettingsManager();
        await newSettingsManager.initialize();

        // Values should be loaded from storage
        expect(newSettingsManager.graphicsQuality, GraphicsQuality.ultra);
        expect(newSettingsManager.difficultyLevel, DifficultyLevel.hard);
        expect(newSettingsManager.tapSensitivity, 1.5);
        expect(newSettingsManager.performanceMonitorEnabled, true);
      });
    });
  });
}