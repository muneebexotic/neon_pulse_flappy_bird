import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'dart:math' as math;

import 'package:neon_pulse_flappy_bird/ui/effects/progression_particle_system.dart';
import 'package:neon_pulse_flappy_bird/game/effects/particle_system.dart';
import 'package:neon_pulse_flappy_bird/models/progression_path_models.dart';
import 'package:neon_pulse_flappy_bird/models/achievement.dart';

void main() {
  group('Particle Performance Tests', () {
    late ProgressionParticleSystem progressionParticleSystem;
    late ParticleSystem baseParticleSystem;

    setUp(() {
      baseParticleSystem = ParticleSystem();
      progressionParticleSystem = ProgressionParticleSystem(
        baseParticleSystem: baseParticleSystem,
        maxConfettiParticles: 200,
        maxPulseParticles: 50,
        celebrationDuration: 5.0,
      );
    });

    group('Memory Usage Performance', () {
      test('should maintain reasonable memory usage with many particles', () {
        final initialMemory = progressionParticleSystem.getMemoryUsageKB();
        
        // Add maximum confetti particles
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);
        
        for (int i = 0; i < 5; i++) {
          progressionParticleSystem.addCelebrationConfetti(
            centerPosition: centerPosition,
            screenSize: screenSize,
          );
        }

        final maxParticleMemory = progressionParticleSystem.getMemoryUsageKB();
        final memoryIncrease = maxParticleMemory - initialMemory;
        
        // Memory increase should be reasonable (less than 100KB for test scenario)
        expect(memoryIncrease, lessThan(100.0));
        
        // Clear particles and verify memory is released
        progressionParticleSystem.clearAllParticles();
        final clearedMemory = progressionParticleSystem.getMemoryUsageKB();
        
        // Memory should be close to initial after clearing (allowing for some overhead)
        expect(clearedMemory, lessThan(initialMemory + 20.0));
      });

      test('should handle memory pressure gracefully', () {
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);
        
        // Add particles beyond the limit
        for (int i = 0; i < 10; i++) {
          progressionParticleSystem.addCelebrationConfetti(
            centerPosition: centerPosition,
            screenSize: screenSize,
          );
        }

        final stats = progressionParticleSystem.getStats();
        final confettiCount = stats['confettiParticles'] as int;
        
        // Should not exceed maximum particle limit
        expect(confettiCount, lessThanOrEqualTo(200));
      });
    });

    group('Update Performance', () {
      test('should update particles efficiently with large particle counts', () {
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);
        
        // Add many particles
        for (int i = 0; i < 3; i++) {
          progressionParticleSystem.addCelebrationConfetti(
            centerPosition: centerPosition,
            screenSize: screenSize,
          );
        }

        // Add pulse particles
        for (int i = 0; i < 10; i++) {
          progressionParticleSystem.addNodeUnlockExplosion(
            position: Vector2(i * 50.0, i * 50.0),
            primaryColor: Colors.red,
          );
        }

        final pathSegments = <PathSegment>[];
        final stopwatch = Stopwatch()..start();
        
        // Perform many updates
        for (int i = 0; i < 100; i++) {
          progressionParticleSystem.update(0.016, pathSegments); // 60 FPS
        }
        
        stopwatch.stop();
        
        // Update time should be reasonable (less than 100ms for 100 updates)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should maintain performance with quality scaling', () {
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);
        
        // Test with high quality
        progressionParticleSystem.setQualityScale(1.0);
        final highQualityStopwatch = Stopwatch()..start();
        
        progressionParticleSystem.addCelebrationConfetti(
          centerPosition: centerPosition,
          screenSize: screenSize,
        );
        
        final pathSegments = <PathSegment>[];
        for (int i = 0; i < 50; i++) {
          progressionParticleSystem.update(0.016, pathSegments);
        }
        
        highQualityStopwatch.stop();
        
        // Clear and test with low quality
        progressionParticleSystem.clearAllParticles();
        progressionParticleSystem.setQualityScale(0.3);
        final lowQualityStopwatch = Stopwatch()..start();
        
        progressionParticleSystem.addCelebrationConfetti(
          centerPosition: centerPosition,
          screenSize: screenSize,
        );
        
        for (int i = 0; i < 50; i++) {
          progressionParticleSystem.update(0.016, pathSegments);
        }
        
        lowQualityStopwatch.stop();
        
        // Low quality should be faster or similar
        expect(lowQualityStopwatch.elapsedMilliseconds, 
               lessThanOrEqualTo(highQualityStopwatch.elapsedMilliseconds + 10));
      });
    });

    group('Particle Lifecycle Performance', () {
      test('should efficiently clean up dead particles', () {
        // Create short-lived particles
        final shortLivedSystem = ProgressionParticleSystem(
          baseParticleSystem: baseParticleSystem,
          celebrationDuration: 0.1,
        );

        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);
        
        // Add particles
        shortLivedSystem.addCelebrationConfetti(
          centerPosition: centerPosition,
          screenSize: screenSize,
        );

        final initialStats = shortLivedSystem.getStats();
        final initialCount = initialStats['confettiParticles'] as int;
        expect(initialCount, greaterThan(0));

        final pathSegments = <PathSegment>[];
        final cleanupStopwatch = Stopwatch()..start();
        
        // Update until all particles are dead
        for (int i = 0; i < 50; i++) {
          shortLivedSystem.update(0.1, pathSegments);
        }
        
        cleanupStopwatch.stop();
        
        final finalStats = shortLivedSystem.getStats();
        expect(finalStats['confettiParticles'], equals(0));
        
        // Cleanup should be efficient (less than 50ms)
        expect(cleanupStopwatch.elapsedMilliseconds, lessThan(50));
      });

      test('should handle rapid particle creation and destruction', () {
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);
        final pathSegments = <PathSegment>[];
        
        final rapidCycleStopwatch = Stopwatch()..start();
        
        // Rapidly create and update particles
        for (int cycle = 0; cycle < 10; cycle++) {
          // Add particles
          progressionParticleSystem.addCelebrationConfetti(
            centerPosition: centerPosition,
            screenSize: screenSize,
          );
          
          // Update a few times
          for (int i = 0; i < 5; i++) {
            progressionParticleSystem.update(0.1, pathSegments);
          }
          
          // Clear particles
          progressionParticleSystem.clearAllParticles();
        }
        
        rapidCycleStopwatch.stop();
        
        // Rapid cycling should complete in reasonable time (less than 100ms)
        expect(rapidCycleStopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('Quality Scaling Performance', () {
      test('should reduce particle count with lower quality settings', () {
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);
        
        // Test with maximum quality
        progressionParticleSystem.setQualityScale(1.0);
        progressionParticleSystem.addCelebrationConfetti(
          centerPosition: centerPosition,
          screenSize: screenSize,
        );
        
        final maxQualityStats = progressionParticleSystem.getStats();
        final maxQualityCount = maxQualityStats['confettiParticles'] as int;
        
        // Clear and test with minimum quality
        progressionParticleSystem.clearAllParticles();
        progressionParticleSystem.setQualityScale(0.1);
        progressionParticleSystem.addCelebrationConfetti(
          centerPosition: centerPosition,
          screenSize: screenSize,
        );
        
        final minQualityStats = progressionParticleSystem.getStats();
        final minQualityCount = minQualityStats['confettiParticles'] as int;
        
        // Lower quality should result in fewer particles
        expect(minQualityCount, lessThan(maxQualityCount));
      });

      test('should maintain performance across quality levels', () {
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);
        final pathSegments = <PathSegment>[];
        
        final qualityLevels = [0.1, 0.3, 0.5, 0.7, 1.0];
        final performanceTimes = <double>[];
        
        for (final quality in qualityLevels) {
          progressionParticleSystem.clearAllParticles();
          progressionParticleSystem.setQualityScale(quality);
          
          final stopwatch = Stopwatch()..start();
          
          // Add particles and update
          progressionParticleSystem.addCelebrationConfetti(
            centerPosition: centerPosition,
            screenSize: screenSize,
          );
          
          for (int i = 0; i < 30; i++) {
            progressionParticleSystem.update(0.016, pathSegments);
          }
          
          stopwatch.stop();
          performanceTimes.add(stopwatch.elapsedMicroseconds.toDouble());
        }
        
        // Performance should not degrade significantly with higher quality
        // (allowing for some variance due to particle count differences)
        final minTime = performanceTimes.reduce(math.min);
        final maxTime = performanceTimes.reduce(math.max);
        
        expect(maxTime / minTime, lessThan(10.0)); // Max 10x difference (allowing for quality scaling impact)
      });
    });

    group('Complex Scenario Performance', () {
      test('should handle mixed particle effects efficiently', () {
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);
        
        final pathSegment = PathSegment(
          id: 'test_segment',
          category: AchievementType.score,
          pathPoints: [
            Vector2(0, 0),
            Vector2(100, 50),
            Vector2(200, 100),
            Vector2(300, 150),
          ],
          neonColor: const Color(0xFFFF1493),
          width: 8.0,
          isMainPath: true,
          completionPercentage: 0.8,
          achievementIds: ['achievement_1'],
        );

        final complexScenarioStopwatch = Stopwatch()..start();
        
        // Add mixed effects
        progressionParticleSystem.addCelebrationConfetti(
          centerPosition: centerPosition,
          screenSize: screenSize,
        );
        
        for (int i = 0; i < 5; i++) {
          progressionParticleSystem.addNodeUnlockExplosion(
            position: Vector2(i * 60.0, i * 40.0),
            primaryColor: Colors.red,
          );
        }
        
        progressionParticleSystem.addProgressPulse(segment: pathSegment);
        
        // Update with path segments
        final pathSegments = [pathSegment];
        for (int i = 0; i < 60; i++) {
          progressionParticleSystem.update(0.016, pathSegments);
        }
        
        complexScenarioStopwatch.stop();
        
        // Complex scenario should complete in reasonable time (less than 200ms)
        expect(complexScenarioStopwatch.elapsedMilliseconds, lessThan(200));
        
        // Verify all particle types are present
        final stats = progressionParticleSystem.getStats();
        expect(stats['totalActiveParticles'], greaterThan(0));
      });

      test('should maintain frame rate target with heavy particle load', () {
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);
        final pathSegments = <PathSegment>[];
        
        // Add heavy particle load
        for (int i = 0; i < 3; i++) {
          progressionParticleSystem.addCelebrationConfetti(
            centerPosition: centerPosition,
            screenSize: screenSize,
          );
        }

        // Simulate 60 FPS updates for 1 second
        final frameRateStopwatch = Stopwatch()..start();
        const targetFrameTime = 16.67; // ~60 FPS in milliseconds
        
        for (int frame = 0; frame < 60; frame++) {
          final frameStopwatch = Stopwatch()..start();
          
          progressionParticleSystem.update(0.016, pathSegments);
          
          frameStopwatch.stop();
          
          // Each frame should complete within target time
          expect(frameStopwatch.elapsedMicroseconds / 1000, 
                 lessThan(targetFrameTime));
        }
        
        frameRateStopwatch.stop();
        
        // Total time should be close to 1 second (allowing some overhead)
        expect(frameRateStopwatch.elapsedMilliseconds, lessThan(1200));
      });
    });

    group('Resource Management Performance', () {
      test('should efficiently manage particle pools', () {
        final centerPosition = Vector2(200, 300);
        final screenSize = const Size(400, 600);
        
        // Create and destroy particles multiple times
        for (int cycle = 0; cycle < 5; cycle++) {
          progressionParticleSystem.addCelebrationConfetti(
            centerPosition: centerPosition,
            screenSize: screenSize,
          );
          
          final stats = progressionParticleSystem.getStats();
          expect(stats['confettiParticles'], greaterThan(0));
          
          progressionParticleSystem.clearAllParticles();
          
          final clearedStats = progressionParticleSystem.getStats();
          expect(clearedStats['confettiParticles'], equals(0));
        }
        
        // Memory usage should remain stable
        final finalMemory = progressionParticleSystem.getMemoryUsageKB();
        expect(finalMemory, lessThan(50.0)); // Should not accumulate memory
      });

      test('should handle concurrent particle operations', () {
        final positions = [
          Vector2(100, 100),
          Vector2(200, 200),
          Vector2(300, 300),
        ];
        
        final colors = [Colors.red, Colors.green, Colors.blue];
        final screenSize = const Size(400, 600);
        
        final concurrentStopwatch = Stopwatch()..start();
        
        // Add multiple effects simultaneously
        for (int i = 0; i < positions.length; i++) {
          progressionParticleSystem.addCelebrationConfetti(
            centerPosition: positions[i],
            screenSize: screenSize,
            colors: [colors[i]],
          );
          
          progressionParticleSystem.addNodeUnlockExplosion(
            position: positions[i],
            primaryColor: colors[i],
          );
        }
        
        // Update all particles
        final pathSegments = <PathSegment>[];
        for (int i = 0; i < 30; i++) {
          progressionParticleSystem.update(0.016, pathSegments);
        }
        
        concurrentStopwatch.stop();
        
        // Concurrent operations should complete efficiently
        expect(concurrentStopwatch.elapsedMilliseconds, lessThan(100));
        
        final stats = progressionParticleSystem.getStats();
        expect(stats['totalActiveParticles'], greaterThan(0));
      });
    });
  });
}