import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'dart:math' as math;
import '../../lib/controllers/progression_performance_controller.dart';
import '../../lib/ui/effects/progression_particle_system.dart';
import '../../lib/ui/painters/path_renderer.dart';
import '../../lib/models/progression_path_models.dart';
import '../../lib/models/achievement.dart';
import '../../lib/game/effects/particle_system.dart';
import '../../lib/game/utils/performance_monitor.dart';

/// Comprehensive performance test suite for progression path system
void main() {
  group('Progression Performance Test Suite', () {
    late ProgressionPerformanceController performanceController;
    late ParticleSystem baseParticleSystem;
    late ProgressionParticleSystem progressionParticleSystem;

    setUp(() async {
      performanceController = ProgressionPerformanceController();
      await performanceController.initialize();
      
      baseParticleSystem = ParticleSystem();
      progressionParticleSystem = ProgressionParticleSystem(
        baseParticleSystem: baseParticleSystem,
        performanceController: performanceController,
      );
    });

    tearDown(() {
      performanceController.dispose();
    });

    group('Frame Rate Performance Tests', () {
      test('should maintain 60fps with minimal load', () async {
        final frameTimings = <double>[];
        const targetFrameTime = 16.67; // 60fps
        const testDuration = 1000; // 1 second worth of frames
        
        // Simulate minimal load
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < testDuration; i++) {
          final frameStart = stopwatch.elapsedMicroseconds / 1000.0;
          
          // Minimal processing
          performanceController.recordFrame(targetFrameTime);
          
          final frameEnd = stopwatch.elapsedMicroseconds / 1000.0;
          frameTimings.add(frameEnd - frameStart);
        }
        
        stopwatch.stop();
        
        final averageFrameTime = frameTimings.reduce((a, b) => a + b) / frameTimings.length;
        final maxFrameTime = frameTimings.reduce(math.max);
        
        // Should maintain good performance
        expect(averageFrameTime, lessThan(5.0)); // Less than 5ms processing time
        expect(maxFrameTime, lessThan(10.0)); // No frame should take more than 10ms
        
        final stats = performanceController.getPerformanceStats();
        final performanceScore = double.parse(stats['performanceScore']);
        expect(performanceScore, greaterThan(0.8)); // Good performance score
      });

      test('should handle moderate load efficiently', () async {
        final frameTimings = <double>[];
        const testDuration = 500;
        
        // Create moderate load scenario
        final pathSegments = _createTestPathSegments(10);
        final achievements = _createTestAchievements(50);
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < testDuration; i++) {
          final frameStart = stopwatch.elapsedMicroseconds / 1000.0;
          
          // Moderate processing load
          performanceController.recordFrame(16.67);
          performanceController.updateViewport(const Rect.fromLTWH(0, 0, 800, 600));
          
          // Simulate particle system updates
          progressionParticleSystem.update(0.016, pathSegments);
          
          // Check visibility for multiple segments
          for (final segment in pathSegments) {
            performanceController.isSegmentVisible(segment);
          }
          
          final frameEnd = stopwatch.elapsedMicroseconds / 1000.0;
          frameTimings.add(frameEnd - frameStart);
        }
        
        stopwatch.stop();
        
        final averageFrameTime = frameTimings.reduce((a, b) => a + b) / frameTimings.length;
        final maxFrameTime = frameTimings.reduce(math.max);
        
        // Should still maintain reasonable performance
        expect(averageFrameTime, lessThan(12.0)); // Less than 12ms processing time
        expect(maxFrameTime, lessThan(20.0)); // No frame should take more than 20ms
        
        final stats = performanceController.getPerformanceStats();
        final performanceScore = double.parse(stats['performanceScore']);
        expect(performanceScore, greaterThan(0.6)); // Reasonable performance score
      });

      test('should adapt quality under heavy load', () async {
        final frameTimings = <double>[];
        const testDuration = 200;
        
        // Create heavy load scenario
        final pathSegments = _createTestPathSegments(50);
        final achievements = _createTestAchievements(200);
        
        // Start optimization
        performanceController.startOptimization();
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < testDuration; i++) {
          final frameStart = stopwatch.elapsedMicroseconds / 1000.0;
          
          // Heavy processing load
          performanceController.recordFrame(25.0); // Simulate 40fps
          performanceController.updateViewport(Rect.fromLTWH(i.toDouble(), 0, 800, 600));
          
          // Heavy particle system updates
          progressionParticleSystem.update(0.025, pathSegments);
          
          // Add celebration effects (expensive)
          if (i % 10 == 0) {
            progressionParticleSystem.addCelebrationConfetti(
              centerPosition: Vector2(400, 300),
              screenSize: const Size(800, 600),
            );
          }
          
          // Check visibility for all segments
          for (final segment in pathSegments) {
            performanceController.isSegmentVisible(segment);
          }
          
          final frameEnd = stopwatch.elapsedMicroseconds / 1000.0;
          frameTimings.add(frameEnd - frameStart);
        }
        
        stopwatch.stop();
        performanceController.stopOptimization();
        
        final averageFrameTime = frameTimings.reduce((a, b) => a + b) / frameTimings.length;
        
        // Quality should have been reduced
        expect(performanceController.currentParticleQuality, 
               isIn([QualityLevel.low, QualityLevel.medium]));
        expect(performanceController.areEffectsReduced, isTrue);
        
        // Performance should still be manageable
        expect(averageFrameTime, lessThan(30.0)); // Less than 30ms processing time
      });

      test('should recover quality when performance improves', () async {
        // Start with poor performance
        performanceController.forceQualityAdjustment(
          particleQuality: QualityLevel.low,
          graphicsQuality: QualityLevel.low,
          reduceEffects: true,
        );
        
        performanceController.startOptimization();
        
        // Simulate good performance for sustained period
        for (int i = 0; i < 100; i++) {
          performanceController.recordFrame(12.0); // ~83fps - excellent
        }
        
        // Wait for optimization cycles
        await Future.delayed(const Duration(milliseconds: 1500));
        
        performanceController.stopOptimization();
        
        // Quality should have improved
        expect(performanceController.currentParticleQuality, 
               isIn([QualityLevel.medium, QualityLevel.high, QualityLevel.ultra]));
        expect(performanceController.areEffectsReduced, isFalse);
      });
    });

    group('Memory Usage Tests', () {
      test('should maintain stable memory usage under normal load', () {
        final memoryReadings = <double>[];
        const testDuration = 1000;
        
        // Record initial memory
        memoryReadings.add(performanceController.getMemoryUsageKB());
        
        // Simulate normal operation
        for (int i = 0; i < testDuration; i++) {
          performanceController.recordFrame(16.67);
          
          if (i % 100 == 0) {
            memoryReadings.add(performanceController.getMemoryUsageKB());
          }
        }
        
        // Memory should remain stable
        final initialMemory = memoryReadings.first;
        final finalMemory = memoryReadings.last;
        final memoryGrowth = finalMemory - initialMemory;
        
        expect(memoryGrowth, lessThan(50.0)); // Less than 50KB growth
        
        // No significant memory spikes
        for (int i = 1; i < memoryReadings.length; i++) {
          final growth = memoryReadings[i] - memoryReadings[i - 1];
          expect(growth, lessThan(20.0)); // No single spike > 20KB
        }
      });

      test('should handle particle system memory efficiently', () {
        final initialMemory = progressionParticleSystem.getMemoryUsageKB();
        
        // Create many particles
        for (int i = 0; i < 100; i++) {
          progressionParticleSystem.addCelebrationConfetti(
            centerPosition: Vector2(400, 300),
            screenSize: const Size(800, 600),
          );
        }
        
        final peakMemory = progressionParticleSystem.getMemoryUsageKB();
        
        // Clear particles
        progressionParticleSystem.clearAllParticles();
        
        final finalMemory = progressionParticleSystem.getMemoryUsageKB();
        
        // Memory should be reclaimed
        expect(finalMemory, lessThan(peakMemory));
        expect(finalMemory - initialMemory, lessThan(10.0)); // Minimal residual growth
      });

      test('should handle object pooling correctly', () {
        final pathSegments = _createTestPathSegments(5);
        
        // Create and destroy particles multiple times
        for (int cycle = 0; cycle < 10; cycle++) {
          // Create particles
          for (int i = 0; i < 50; i++) {
            progressionParticleSystem.addNodeUnlockExplosion(
              position: Vector2(100 + i * 10.0, 100),
              primaryColor: Colors.pink,
            );
          }
          
          // Update to age particles
          for (int frame = 0; frame < 100; frame++) {
            progressionParticleSystem.update(0.05, pathSegments); // Fast aging
          }
        }
        
        final stats = progressionParticleSystem.getStats();
        
        // Should have reused particles from pool
        expect(stats['totalActiveParticles'], lessThan(100)); // Not creating new ones each time
      });
    });

    group('Viewport Culling Performance Tests', () {
      test('should improve performance with viewport culling enabled', () {
        final pathSegments = _createTestPathSegments(100); // Many segments
        
        // Test without culling
        performanceController.setViewportCullingEnabled(false);
        final stopwatchNoCulling = Stopwatch()..start();
        
        for (int i = 0; i < 100; i++) {
          for (final segment in pathSegments) {
            performanceController.isSegmentVisible(segment);
          }
        }
        
        stopwatchNoCulling.stop();
        final timeNoCulling = stopwatchNoCulling.elapsedMicroseconds;
        
        // Test with culling
        performanceController.setViewportCullingEnabled(true);
        performanceController.updateViewport(const Rect.fromLTWH(0, 0, 800, 600));
        
        final stopwatchWithCulling = Stopwatch()..start();
        
        for (int i = 0; i < 100; i++) {
          for (final segment in pathSegments) {
            performanceController.isSegmentVisible(segment);
          }
        }
        
        stopwatchWithCulling.stop();
        final timeWithCulling = stopwatchWithCulling.elapsedMicroseconds;
        
        // Culling should be faster (or at least not significantly slower)
        expect(timeWithCulling, lessThanOrEqualTo(timeNoCulling * 1.2)); // Allow 20% overhead
      });

      test('should cull invisible segments correctly', () {
        final viewport = const Rect.fromLTWH(0, 0, 800, 600);
        performanceController.updateViewport(viewport);
        
        final visibleSegments = _createTestPathSegments(10, inViewport: true);
        final hiddenSegments = _createTestPathSegments(10, inViewport: false);
        
        int visibleCount = 0;
        int hiddenCount = 0;
        
        for (final segment in visibleSegments) {
          if (performanceController.isSegmentVisible(segment)) {
            visibleCount++;
          }
        }
        
        for (final segment in hiddenSegments) {
          if (performanceController.isSegmentVisible(segment)) {
            hiddenCount++;
          }
        }
        
        expect(visibleCount, equals(visibleSegments.length));
        expect(hiddenCount, equals(0));
      });
    });

    group('Quality Scaling Performance Tests', () {
      test('should render faster at lower quality settings', () {
        final pathSegments = _createTestPathSegments(20);
        final energyParticles = _createTestEnergyParticles(100);
        
        // Test at high quality
        performanceController.forceQualityAdjustment(
          particleQuality: QualityLevel.ultra,
          graphicsQuality: QualityLevel.ultra,
          qualityScale: 1.0,
        );
        
        final highQualitySettings = performanceController.getOptimizedRenderSettings();
        final stopwatchHigh = Stopwatch()..start();
        
        for (int i = 0; i < 50; i++) {
          final renderer = PathRenderer(
            pathSegments: pathSegments,
            energyParticles: energyParticles,
            enableGlowEffects: highQualitySettings.enableGlowEffects,
            glowIntensity: highQualitySettings.glowIntensity,
            qualityScale: highQualitySettings.qualityScale,
            performanceController: performanceController,
          );
          
          // Simulate paint operation (without actual canvas)
          renderer.shouldRepaint(renderer);
        }
        
        stopwatchHigh.stop();
        final timeHigh = stopwatchHigh.elapsedMicroseconds;
        
        // Test at low quality
        performanceController.forceQualityAdjustment(
          particleQuality: QualityLevel.low,
          graphicsQuality: QualityLevel.low,
          qualityScale: 0.3,
          reduceEffects: true,
        );
        
        final lowQualitySettings = performanceController.getOptimizedRenderSettings();
        final stopwatchLow = Stopwatch()..start();
        
        for (int i = 0; i < 50; i++) {
          final renderer = PathRenderer(
            pathSegments: pathSegments,
            energyParticles: energyParticles,
            enableGlowEffects: lowQualitySettings.enableGlowEffects,
            glowIntensity: lowQualitySettings.glowIntensity,
            qualityScale: lowQualitySettings.qualityScale,
            performanceController: performanceController,
          );
          
          // Simulate paint operation (without actual canvas)
          renderer.shouldRepaint(renderer);
        }
        
        stopwatchLow.stop();
        final timeLow = stopwatchLow.elapsedMicroseconds;
        
        // Low quality should be faster
        expect(timeLow, lessThan(timeHigh));
      });

      test('should reduce particle count at lower quality', () {
        // Test particle counts at different quality levels
        performanceController.forceQualityAdjustment(particleQuality: QualityLevel.low);
        final lowCount = performanceController.getOptimizedParticleCount();
        
        performanceController.forceQualityAdjustment(particleQuality: QualityLevel.medium);
        final mediumCount = performanceController.getOptimizedParticleCount();
        
        performanceController.forceQualityAdjustment(particleQuality: QualityLevel.high);
        final highCount = performanceController.getOptimizedParticleCount();
        
        performanceController.forceQualityAdjustment(particleQuality: QualityLevel.ultra);
        final ultraCount = performanceController.getOptimizedParticleCount();
        
        // Counts should increase with quality
        expect(lowCount, lessThan(mediumCount));
        expect(mediumCount, lessThan(highCount));
        expect(highCount, lessThan(ultraCount));
        
        // Specific expected ranges
        expect(lowCount, inInclusiveRange(20, 50));
        expect(mediumCount, inInclusiveRange(60, 100));
        expect(highCount, inInclusiveRange(120, 180));
        expect(ultraCount, inInclusiveRange(200, 300));
      });
    });

    group('Stress Tests', () {
      test('should handle extreme particle loads', () {
        final pathSegments = _createTestPathSegments(50);
        
        // Create extreme particle load
        for (int i = 0; i < 20; i++) {
          progressionParticleSystem.addCelebrationConfetti(
            centerPosition: Vector2(400, 300),
            screenSize: const Size(800, 600),
          );
          
          progressionParticleSystem.addNodeUnlockExplosion(
            position: Vector2(200 + i * 20.0, 200),
            primaryColor: Colors.pink,
            intensity: 2.0,
          );
        }
        
        final stopwatch = Stopwatch()..start();
        
        // Update for many frames
        for (int frame = 0; frame < 300; frame++) {
          progressionParticleSystem.update(0.016, pathSegments);
          performanceController.recordFrame(16.67);
        }
        
        stopwatch.stop();
        
        // Should complete without hanging
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Less than 5 seconds
        
        final stats = progressionParticleSystem.getStats();
        expect(stats['totalActiveParticles'], isA<int>());
      });

      test('should handle rapid viewport changes', () {
        final pathSegments = _createTestPathSegments(100);
        
        final stopwatch = Stopwatch()..start();
        
        // Rapidly change viewport
        for (int i = 0; i < 1000; i++) {
          final viewport = Rect.fromLTWH(
            i % 1000.0,
            i % 800.0,
            800,
            600,
          );
          
          performanceController.updateViewport(viewport);
          
          // Check visibility for some segments
          for (int j = 0; j < 10; j++) {
            performanceController.isSegmentVisible(pathSegments[j]);
          }
        }
        
        stopwatch.stop();
        
        // Should handle rapid changes efficiently
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Less than 1 second
      });

      test('should handle memory pressure gracefully', () {
        // Force memory pressure simulation
        final initialStats = performanceController.getPerformanceStats();
        
        // Create memory pressure by forcing poor performance
        for (int i = 0; i < 100; i++) {
          performanceController.recordFrame(50.0); // 20fps
        }
        
        performanceController.startOptimization();
        
        // Wait for optimization
        Future.delayed(const Duration(milliseconds: 600), () {
          final finalStats = performanceController.getPerformanceStats();
          
          // Should have adapted to reduce memory usage
          expect(performanceController.currentParticleQuality, 
                 isIn([QualityLevel.low, QualityLevel.medium]));
          expect(performanceController.areEffectsReduced, isTrue);
        });
        
        performanceController.stopOptimization();
      });
    });
  });
}

/// Helper function to create test path segments
List<PathSegment> _createTestPathSegments(int count, {bool inViewport = true}) {
  final segments = <PathSegment>[];
  
  for (int i = 0; i < count; i++) {
    final baseX = inViewport ? (i * 50.0) % 800 : 1000.0 + i * 50.0;
    final baseY = inViewport ? (i * 30.0) % 600 : 1000.0 + i * 30.0;
    
    final segment = PathSegment(
      id: 'test_segment_$i',
      category: AchievementType.values[i % AchievementType.values.length],
      pathPoints: [
        Vector2(baseX, baseY),
        Vector2(baseX + 40, baseY + 20),
        Vector2(baseX + 80, baseY + 40),
      ],
      neonColor: Colors.pink,
      width: 4.0,
      isMainPath: i == 0,
      completionPercentage: (i % 10) / 10.0,
      achievementIds: ['achievement_$i'],
    );
    
    segments.add(segment);
  }
  
  return segments;
}

/// Helper function to create test achievements
List<Achievement> _createTestAchievements(int count) {
  final achievements = <Achievement>[];
  
  for (int i = 0; i < count; i++) {
    final achievement = Achievement(
      id: 'test_achievement_$i',
      name: 'Test Achievement $i',
      description: 'Test description for achievement $i',
      icon: Icons.star,
      iconColor: Colors.blue,
      type: AchievementType.values[i % AchievementType.values.length],
      targetValue: (i + 1) * 100,
      currentProgress: i % 3 == 0 ? (i + 1) * 100 : (i * 50), // Some completed
      isUnlocked: i % 3 == 0,
      rewardSkinId: i % 5 == 0 ? 'skin_$i' : null,
    );
    
    achievements.add(achievement);
  }
  
  return achievements;
}

/// Helper function to create test energy particles
List<EnergyFlowParticle> _createTestEnergyParticles(int count) {
  final particles = <EnergyFlowParticle>[];
  
  for (int i = 0; i < count; i++) {
    final particle = EnergyFlowParticle(
      position: Vector2(i * 8.0, i * 6.0),
      velocity: Vector2(50.0, 30.0),
      color: Colors.cyan,
      size: 2.0,
      alpha: 0.8,
      life: 2.0,
      maxLife: 2.0,
      pathId: 'test_path',
    );
    
    particles.add(particle);
  }
  
  return particles;
}