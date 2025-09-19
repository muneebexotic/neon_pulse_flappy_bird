import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'dart:math' as math;

import 'package:neon_pulse_flappy_bird/ui/effects/progression_particle_system.dart';
import 'package:neon_pulse_flappy_bird/game/effects/particle_system.dart';
import 'package:neon_pulse_flappy_bird/models/progression_path_models.dart';
import 'package:neon_pulse_flappy_bird/models/achievement.dart';

void main() {
  group('ProgressionParticleSystem', () {
    late ProgressionParticleSystem progressionParticleSystem;
    late ParticleSystem baseParticleSystem;

    setUp(() {
      baseParticleSystem = ParticleSystem();
      progressionParticleSystem = ProgressionParticleSystem(
        baseParticleSystem: baseParticleSystem,
        maxConfettiParticles: 50,
        maxPulseParticles: 10,
        celebrationDuration: 3.0,
      );
    });

    group('Initialization', () {
      test('should initialize with correct default values', () {
        expect(progressionParticleSystem.baseParticleSystem, equals(baseParticleSystem));
        
        final stats = progressionParticleSystem.getStats();
        expect(stats['confettiParticles'], equals(0));
        expect(stats['pulseParticles'], equals(0));
        expect(stats['qualityScale'], equals(1.0));
        expect(stats['celebrationEffectsEnabled'], isTrue);
        expect(stats['pulseEffectsEnabled'], isTrue);
      });

      test('should initialize with custom parameters', () {
        final customSystem = ProgressionParticleSystem(
          baseParticleSystem: baseParticleSystem,
          maxConfettiParticles: 100,
          maxPulseParticles: 20,
          celebrationDuration: 5.0,
        );

        expect(customSystem.baseParticleSystem, equals(baseParticleSystem));
        
        final stats = customSystem.getStats();
        expect(stats['maxConfettiParticles'], equals(100));
        expect(stats['maxPulseParticles'], equals(20));
      });
    });

    group('Node Unlock Explosion Effects', () {
      test('should add node unlock explosion with correct parameters', () {
        final position = Vector2(100, 200);
        final color = const Color(0xFFFF1493);
        
        progressionParticleSystem.addNodeUnlockExplosion(
          position: position,
          primaryColor: color,
          intensity: 1.0,
        );

        // Verify that particles were added (pulse particles should be created)
        final stats = progressionParticleSystem.getStats();
        expect(stats['pulseParticles'], greaterThan(0));
      });

      test('should scale explosion intensity correctly', () {
        final position = Vector2(100, 200);
        final color = const Color(0xFFFF1493);
        
        // Add explosion with low intensity
        progressionParticleSystem.addNodeUnlockExplosion(
          position: position,
          primaryColor: color,
          intensity: 0.5,
        );
        
        final lowIntensityStats = progressionParticleSystem.getStats();
        final lowIntensityCount = lowIntensityStats['pulseParticles'] as int;
        
        // Clear and add explosion with high intensity
        progressionParticleSystem.clearAllParticles();
        progressionParticleSystem.addNodeUnlockExplosion(
          position: position,
          primaryColor: color,
          intensity: 2.0,
        );
        
        final highIntensityStats = progressionParticleSystem.getStats();
        final highIntensityCount = highIntensityStats['pulseParticles'] as int;
        
        expect(highIntensityCount, greaterThan(lowIntensityCount));
      });

      test('should respect quality scaling for explosions', () {
        final position = Vector2(100, 200);
        final color = const Color(0xFFFF1493);
        
        // Set low quality
        progressionParticleSystem.setQualityScale(0.5);
        progressionParticleSystem.addNodeUnlockExplosion(
          position: position,
          primaryColor: color,
          intensity: 1.0,
        );
        
        final lowQualityStats = progressionParticleSystem.getStats();
        final lowQualityCount = lowQualityStats['pulseParticles'] as int;
        
        // Clear and set high quality
        progressionParticleSystem.clearAllParticles();
        progressionParticleSystem.setQualityScale(1.0);
        progressionParticleSystem.addNodeUnlockExplosion(
          position: position,
          primaryColor: color,
          intensity: 1.0,
        );
        
        final highQualityStats = progressionParticleSystem.getStats();
        final highQualityCount = highQualityStats['pulseParticles'] as int;
        
        expect(highQualityCount, greaterThanOrEqualTo(lowQualityCount));
      });
    });

    group('Progress Pulse Animations', () {
      test('should add progress pulse along path segment', () {
        final pathSegment = PathSegment(
          id: 'test_segment',
          category: AchievementType.score,
          pathPoints: [
            Vector2(0, 0),
            Vector2(100, 0),
            Vector2(200, 0),
          ],
          neonColor: const Color(0xFFFF1493),
          width: 8.0,
          isMainPath: true,
          completionPercentage: 0.8,
          achievementIds: ['achievement_1'],
        );

        progressionParticleSystem.addProgressPulse(
          segment: pathSegment,
          intensity: 1.0,
        );

        final stats = progressionParticleSystem.getStats();
        expect(stats['pulseParticles'], greaterThan(0));
      });

      test('should scale pulse count based on path complexity', () {
        final simpleSegment = PathSegment(
          id: 'simple_segment',
          category: AchievementType.score,
          pathPoints: [Vector2(0, 0), Vector2(100, 0)],
          neonColor: const Color(0xFFFF1493),
          width: 8.0,
          isMainPath: true,
          completionPercentage: 1.0,
          achievementIds: ['achievement_1'],
        );

        final complexSegment = PathSegment(
          id: 'complex_segment',
          category: AchievementType.score,
          pathPoints: [
            Vector2(0, 0),
            Vector2(50, 0),
            Vector2(100, 50),
            Vector2(150, 50),
            Vector2(200, 100),
          ],
          neonColor: const Color(0xFFFF1493),
          width: 8.0,
          isMainPath: true,
          completionPercentage: 1.0,
          achievementIds: ['achievement_1'],
        );

        progressionParticleSystem.addProgressPulse(segment: simpleSegment);
        final simpleStats = progressionParticleSystem.getStats();
        final simpleCount = simpleStats['pulseParticles'] as int;

        progressionParticleSystem.clearAllParticles();
        progressionParticleSystem.addProgressPulse(segment: complexSegment);
        final complexStats = progressionParticleSystem.getStats();
        final complexCount = complexStats['pulseParticles'] as int;

        expect(complexCount, greaterThanOrEqualTo(simpleCount));
      });
    });

    group('Celebration Confetti Effects', () {
      test('should add celebration confetti with default colors', () {
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);

        progressionParticleSystem.addCelebrationConfetti(
          centerPosition: centerPosition,
          screenSize: screenSize,
        );

        final stats = progressionParticleSystem.getStats();
        expect(stats['confettiParticles'], greaterThan(0));
      });

      test('should add celebration confetti with custom colors', () {
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);
        final customColors = [
          Colors.red,
          Colors.blue,
          Colors.green,
        ];

        progressionParticleSystem.addCelebrationConfetti(
          centerPosition: centerPosition,
          screenSize: screenSize,
          colors: customColors,
        );

        final stats = progressionParticleSystem.getStats();
        expect(stats['confettiParticles'], greaterThan(0));
      });

      test('should respect max confetti particle limit', () {
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);

        // Add confetti multiple times
        for (int i = 0; i < 5; i++) {
          progressionParticleSystem.addCelebrationConfetti(
            centerPosition: centerPosition,
            screenSize: screenSize,
          );
        }

        final stats = progressionParticleSystem.getStats();
        final confettiCount = stats['confettiParticles'] as int;
        expect(confettiCount, lessThanOrEqualTo(50)); // maxConfettiParticles
      });

      test('should not add confetti when celebration effects are disabled', () {
        progressionParticleSystem.setCelebrationEffectsEnabled(false);
        
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);

        progressionParticleSystem.addCelebrationConfetti(
          centerPosition: centerPosition,
          screenSize: screenSize,
        );

        final stats = progressionParticleSystem.getStats();
        expect(stats['confettiParticles'], equals(0));
        expect(stats['celebrationEffectsEnabled'], isFalse);
      });
    });

    group('Particle Updates and Lifecycle', () {
      test('should update confetti particles correctly', () {
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);

        progressionParticleSystem.addCelebrationConfetti(
          centerPosition: centerPosition,
          screenSize: screenSize,
        );

        final initialStats = progressionParticleSystem.getStats();
        final initialCount = initialStats['confettiParticles'] as int;
        expect(initialCount, greaterThan(0));

        // Update particles multiple times
        final pathSegments = <PathSegment>[];
        for (int i = 0; i < 10; i++) {
          progressionParticleSystem.update(0.1, pathSegments);
        }

        // Particles should still exist but may have different properties
        final updatedStats = progressionParticleSystem.getStats();
        expect(updatedStats['confettiParticles'], greaterThan(0));
      });

      test('should remove dead particles during cleanup', () {
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);

        // Create short-lived confetti by setting a very short celebration duration
        final shortLivedSystem = ProgressionParticleSystem(
          baseParticleSystem: baseParticleSystem,
          celebrationDuration: 0.05, // Very short duration
        );

        shortLivedSystem.addCelebrationConfetti(
          centerPosition: centerPosition,
          screenSize: screenSize,
        );

        final initialStats = shortLivedSystem.getStats();
        expect(initialStats['confettiParticles'], greaterThan(0));

        // Update for longer than particle lifetime
        final pathSegments = <PathSegment>[];
        for (int i = 0; i < 30; i++) {
          shortLivedSystem.update(0.1, pathSegments); // Total 3 seconds
        }

        final finalStats = shortLivedSystem.getStats();
        // Particles should be significantly reduced or eliminated
        expect(finalStats['confettiParticles'], lessThan(initialStats['confettiParticles'] as int));
      });
    });

    group('Quality and Performance Management', () {
      test('should adjust quality scale correctly', () {
        progressionParticleSystem.setQualityScale(0.5);
        
        final stats = progressionParticleSystem.getStats();
        expect(stats['qualityScale'], equals(0.5));
      });

      test('should clamp quality scale to valid range', () {
        progressionParticleSystem.setQualityScale(-0.5);
        expect(progressionParticleSystem.getStats()['qualityScale'], equals(0.1));

        progressionParticleSystem.setQualityScale(2.0);
        expect(progressionParticleSystem.getStats()['qualityScale'], equals(1.0));
      });

      test('should calculate memory usage correctly', () {
        final memoryUsage = progressionParticleSystem.getMemoryUsageKB();
        expect(memoryUsage, isA<double>());
        expect(memoryUsage, greaterThanOrEqualTo(0));

        // Add some particles and verify memory usage increases
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);
        progressionParticleSystem.addCelebrationConfetti(
          centerPosition: centerPosition,
          screenSize: screenSize,
        );

        final newMemoryUsage = progressionParticleSystem.getMemoryUsageKB();
        expect(newMemoryUsage, greaterThan(memoryUsage));
      });

      test('should provide comprehensive statistics', () {
        final stats = progressionParticleSystem.getStats();
        
        expect(stats, containsPair('baseParticleSystem', isA<Map<String, dynamic>>()));
        expect(stats, containsPair('energyFlowSystem', isA<Map<String, dynamic>>()));
        expect(stats, containsPair('confettiParticles', isA<int>()));
        expect(stats, containsPair('pulseParticles', isA<int>()));
        expect(stats, containsPair('maxConfettiParticles', isA<int>()));
        expect(stats, containsPair('maxPulseParticles', isA<int>()));
        expect(stats, containsPair('qualityScale', isA<double>()));
        expect(stats, containsPair('celebrationEffectsEnabled', isA<bool>()));
        expect(stats, containsPair('pulseEffectsEnabled', isA<bool>()));
        expect(stats, containsPair('totalActiveParticles', isA<int>()));
      });
    });

    group('Effect Control', () {
      test('should enable and disable celebration effects', () {
        expect(progressionParticleSystem.getStats()['celebrationEffectsEnabled'], isTrue);

        progressionParticleSystem.setCelebrationEffectsEnabled(false);
        expect(progressionParticleSystem.getStats()['celebrationEffectsEnabled'], isFalse);

        progressionParticleSystem.setCelebrationEffectsEnabled(true);
        expect(progressionParticleSystem.getStats()['celebrationEffectsEnabled'], isTrue);
      });

      test('should enable and disable pulse effects', () {
        expect(progressionParticleSystem.getStats()['pulseEffectsEnabled'], isTrue);

        progressionParticleSystem.setPulseEffectsEnabled(false);
        expect(progressionParticleSystem.getStats()['pulseEffectsEnabled'], isFalse);

        progressionParticleSystem.setPulseEffectsEnabled(true);
        expect(progressionParticleSystem.getStats()['pulseEffectsEnabled'], isTrue);
      });

      test('should clear all particles', () {
        // Add various types of particles
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);
        progressionParticleSystem.addCelebrationConfetti(
          centerPosition: centerPosition,
          screenSize: screenSize,
        );

        progressionParticleSystem.addNodeUnlockExplosion(
          position: centerPosition,
          primaryColor: Colors.red,
        );

        // Verify particles exist
        final beforeStats = progressionParticleSystem.getStats();
        expect(beforeStats['totalActiveParticles'], greaterThan(0));

        // Clear all particles
        progressionParticleSystem.clearAllParticles();

        // Verify all particles are cleared
        final afterStats = progressionParticleSystem.getStats();
        expect(afterStats['confettiParticles'], equals(0));
        expect(afterStats['pulseParticles'], equals(0));
      });
    });
  });

  group('ConfettiParticle', () {
    test('should create confetti particle with correct properties', () {
      final particle = ConfettiParticle(
        position: Vector2(100, 200),
        velocity: Vector2(50, -100),
        color: Colors.red,
        size: 5.0,
        rotation: math.pi / 4,
        rotationSpeed: 2.0,
        alpha: 0.8,
        life: 3.0,
        maxLife: 3.0,
        shape: ConfettiShape.rectangle,
      );

      expect(particle.position, equals(Vector2(100, 200)));
      expect(particle.velocity, equals(Vector2(50, -100)));
      expect(particle.color, equals(Colors.red));
      expect(particle.size, equals(5.0));
      expect(particle.rotation, equals(math.pi / 4));
      expect(particle.rotationSpeed, equals(2.0));
      expect(particle.alpha, equals(0.8));
      expect(particle.life, equals(3.0));
      expect(particle.maxLife, equals(3.0));
      expect(particle.shape, equals(ConfettiShape.rectangle));
      expect(particle.isAlive, isTrue);
    });

    test('should copy with updated properties', () {
      final original = ConfettiParticle(
        position: Vector2(100, 200),
        velocity: Vector2(50, -100),
        color: Colors.red,
        size: 5.0,
        rotation: 0.0,
        rotationSpeed: 2.0,
        alpha: 1.0,
        life: 3.0,
        maxLife: 3.0,
        shape: ConfettiShape.circle,
      );

      final updated = original.copyWith(
        position: Vector2(150, 250),
        alpha: 0.5,
        life: 2.0,
      );

      expect(updated.position, equals(Vector2(150, 250)));
      expect(updated.alpha, equals(0.5));
      expect(updated.life, equals(2.0));
      expect(updated.velocity, equals(original.velocity)); // Unchanged
      expect(updated.color, equals(original.color)); // Unchanged
    });

    test('should correctly report alive status', () {
      final aliveParticle = ConfettiParticle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        size: 5.0,
        rotation: 0.0,
        rotationSpeed: 0.0,
        alpha: 1.0,
        life: 1.0,
        maxLife: 3.0,
        shape: ConfettiShape.circle,
      );

      final deadParticle = ConfettiParticle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        size: 5.0,
        rotation: 0.0,
        rotationSpeed: 0.0,
        alpha: 1.0,
        life: 0.0,
        maxLife: 3.0,
        shape: ConfettiShape.circle,
      );

      expect(aliveParticle.isAlive, isTrue);
      expect(deadParticle.isAlive, isFalse);
    });
  });

  group('PulseParticle', () {
    test('should create pulse particle with correct properties', () {
      final particle = PulseParticle(
        position: Vector2(100, 200),
        baseSize: 20.0,
        color: Colors.blue,
        life: 2.0,
        maxLife: 2.0,
        size: 25.0,
        alpha: 0.7,
        delay: 0.5,
      );

      expect(particle.position, equals(Vector2(100, 200)));
      expect(particle.baseSize, equals(20.0));
      expect(particle.color, equals(Colors.blue));
      expect(particle.life, equals(2.0));
      expect(particle.maxLife, equals(2.0));
      expect(particle.size, equals(25.0));
      expect(particle.alpha, equals(0.7));
      expect(particle.delay, equals(0.5));
      expect(particle.isAlive, isTrue);
      expect(particle.isDelayed, isTrue);
    });

    test('should copy with updated properties', () {
      final original = PulseParticle(
        position: Vector2(100, 200),
        baseSize: 20.0,
        color: Colors.blue,
        life: 2.0,
        maxLife: 2.0,
      );

      final updated = original.copyWith(
        size: 30.0,
        alpha: 0.5,
        life: 1.0,
      );

      expect(updated.size, equals(30.0));
      expect(updated.alpha, equals(0.5));
      expect(updated.life, equals(1.0));
      expect(updated.position, equals(original.position)); // Unchanged
      expect(updated.baseSize, equals(original.baseSize)); // Unchanged
    });

    test('should correctly report delay status', () {
      final delayedParticle = PulseParticle(
        position: Vector2.zero(),
        baseSize: 20.0,
        color: Colors.blue,
        life: 2.0,
        maxLife: 2.0,
        delay: 0.5,
      );

      final activeParticle = PulseParticle(
        position: Vector2.zero(),
        baseSize: 20.0,
        color: Colors.blue,
        life: 1.0,
        maxLife: 2.0,
        delay: 0.5,
      );

      expect(delayedParticle.isDelayed, isTrue);
      expect(activeParticle.isDelayed, isFalse);
    });
  });
}