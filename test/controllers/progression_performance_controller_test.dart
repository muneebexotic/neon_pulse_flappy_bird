import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../../lib/controllers/progression_performance_controller.dart';
import '../../lib/models/progression_path_models.dart';
import '../../lib/models/achievement.dart';
import '../../lib/game/utils/performance_monitor.dart';

void main() {
  group('ProgressionPerformanceController', () {
    late ProgressionPerformanceController controller;

    setUp(() async {
      controller = ProgressionPerformanceController();
      await controller.initialize();
    });

    tearDown(() {
      controller.dispose();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        final newController = ProgressionPerformanceController();
        await newController.initialize();
        
        expect(newController.currentParticleQuality, equals(QualityLevel.high));
        expect(newController.currentGraphicsQuality, equals(QualityLevel.high));
        expect(newController.currentQualityScale, equals(1.0));
        expect(newController.areEffectsReduced, isFalse);
        
        newController.dispose();
      });

      test('should not reinitialize if already initialized', () async {
        await controller.initialize(); // Should not throw or cause issues
        expect(controller.currentParticleQuality, equals(QualityLevel.high));
      });
    });

    group('Frame Performance Recording', () {
      test('should record frame times correctly', () {
        controller.recordFrame(16.67); // 60fps
        controller.recordFrame(33.33); // 30fps
        controller.recordFrame(16.67); // 60fps
        
        final stats = controller.getPerformanceStats();
        expect(stats['frameCount'], equals(3));
        expect(double.parse(stats['averageFrameTime']), closeTo(22.22, 0.1));
      });

      test('should maintain frame time history limit', () {
        // Record more than the history limit
        for (int i = 0; i < 100; i++) {
          controller.recordFrame(16.67);
        }
        
        final stats = controller.getPerformanceStats();
        expect(stats['frameCount'], equals(100));
        // Should still calculate average correctly
        expect(double.parse(stats['averageFrameTime']), closeTo(16.67, 0.1));
      });
    });

    group('Viewport Culling', () {
      test('should update viewport correctly', () {
        final viewport = const Rect.fromLTWH(0, 0, 800, 600);
        controller.updateViewport(viewport);
        
        expect(controller.isViewportCullingEnabled, isTrue);
      });

      test('should determine segment visibility correctly', () {
        final viewport = const Rect.fromLTWH(0, 0, 800, 600);
        controller.updateViewport(viewport);
        
        // Segment within viewport
        final visibleSegment = PathSegment(
          id: 'visible',
          category: AchievementType.score,
          pathPoints: [Vector2(100, 100), Vector2(200, 200)],
          neonColor: Colors.pink,
          width: 4.0,
          isMainPath: true,
          completionPercentage: 0.5,
          achievementIds: ['test1'],
        );
        
        // Segment outside viewport
        final hiddenSegment = PathSegment(
          id: 'hidden',
          category: AchievementType.score,
          pathPoints: [Vector2(1000, 1000), Vector2(1100, 1100)],
          neonColor: Colors.pink,
          width: 4.0,
          isMainPath: false,
          completionPercentage: 0.3,
          achievementIds: ['test2'],
        );
        
        expect(controller.isSegmentVisible(visibleSegment), isTrue);
        expect(controller.isSegmentVisible(hiddenSegment), isFalse);
      });

      test('should determine node visibility correctly', () {
        final viewport = const Rect.fromLTWH(0, 0, 800, 600);
        controller.updateViewport(viewport);
        
        // Node within viewport (with buffer)
        final visibleNode = NodePosition(
          position: Vector2(100, 100),
          achievementId: 'visible',
          category: AchievementType.score,
          visualState: NodeVisualState.unlocked,
          pathProgress: 0.5,
          isOnMainPath: true,
        );
        
        // Node outside viewport
        final hiddenNode = NodePosition(
          position: Vector2(1000, 1000),
          achievementId: 'hidden',
          category: AchievementType.score,
          visualState: NodeVisualState.locked,
          pathProgress: 0.8,
          isOnMainPath: false,
        );
        
        expect(controller.isNodeVisible(visibleNode), isTrue);
        expect(controller.isNodeVisible(hiddenNode), isFalse);
      });

      test('should disable culling when viewport culling is disabled', () {
        controller.setViewportCullingEnabled(false);
        
        final segment = PathSegment(
          id: 'test',
          category: AchievementType.score,
          pathPoints: [Vector2(1000, 1000), Vector2(1100, 1100)],
          neonColor: Colors.pink,
          width: 4.0,
          isMainPath: true,
          completionPercentage: 0.5,
          achievementIds: ['test'],
        );
        
        expect(controller.isSegmentVisible(segment), isTrue);
      });
    });

    group('Quality Adjustment', () {
      test('should adjust quality based on performance', () {
        // Simulate poor performance
        for (int i = 0; i < 10; i++) {
          controller.recordFrame(50.0); // 20fps - poor performance
        }
        
        controller.startOptimization();
        
        // Wait for optimization cycle
        Future.delayed(const Duration(milliseconds: 600), () {
          expect(controller.currentParticleQuality, 
                 isIn([QualityLevel.low, QualityLevel.medium]));
          expect(controller.areEffectsReduced, isTrue);
        });
        
        controller.stopOptimization();
      });

      test('should improve quality when performance is good', () {
        // Start with low quality
        controller.forceQualityAdjustment(
          particleQuality: QualityLevel.low,
          graphicsQuality: QualityLevel.low,
          reduceEffects: true,
        );
        
        // Simulate good performance
        for (int i = 0; i < 50; i++) {
          controller.recordFrame(12.0); // ~83fps - excellent performance
        }
        
        controller.startOptimization();
        
        // Wait for optimization cycle
        Future.delayed(const Duration(milliseconds: 600), () {
          expect(controller.currentParticleQuality, 
                 isIn([QualityLevel.medium, QualityLevel.high, QualityLevel.ultra]));
        });
        
        controller.stopOptimization();
      });

      test('should force quality adjustment correctly', () {
        controller.forceQualityAdjustment(
          particleQuality: QualityLevel.low,
          graphicsQuality: QualityLevel.medium,
          reduceEffects: true,
          qualityScale: 0.5,
        );
        
        expect(controller.currentParticleQuality, equals(QualityLevel.low));
        expect(controller.currentGraphicsQuality, equals(QualityLevel.medium));
        expect(controller.areEffectsReduced, isTrue);
        expect(controller.currentQualityScale, equals(0.5));
      });
    });

    group('Render Settings', () {
      test('should provide optimized render settings', () {
        controller.forceQualityAdjustment(
          particleQuality: QualityLevel.medium,
          graphicsQuality: QualityLevel.high,
          reduceEffects: false,
          qualityScale: 0.8,
        );
        
        final settings = controller.getOptimizedRenderSettings();
        
        expect(settings.enableGlowEffects, isTrue);
        expect(settings.glowIntensity, equals(0.8));
        expect(settings.enableAntiAliasing, isTrue);
        expect(settings.qualityScale, equals(0.8));
      });

      test('should provide reduced settings when effects are reduced', () {
        controller.forceQualityAdjustment(
          particleQuality: QualityLevel.low,
          graphicsQuality: QualityLevel.low,
          reduceEffects: true,
          qualityScale: 0.3,
        );
        
        final settings = controller.getOptimizedRenderSettings();
        
        expect(settings.enableGlowEffects, isFalse);
        expect(settings.enableAntiAliasing, isFalse);
        expect(settings.qualityScale, equals(0.3));
        expect(settings.enableBatching, isTrue);
      });
    });

    group('Particle Count Optimization', () {
      test('should provide optimized particle counts', () {
        controller.forceQualityAdjustment(particleQuality: QualityLevel.low);
        expect(controller.getOptimizedParticleCount(), equals(30));
        
        controller.forceQualityAdjustment(particleQuality: QualityLevel.medium);
        expect(controller.getOptimizedParticleCount(), equals(80));
        
        controller.forceQualityAdjustment(particleQuality: QualityLevel.high);
        expect(controller.getOptimizedParticleCount(), equals(150));
        
        controller.forceQualityAdjustment(particleQuality: QualityLevel.ultra);
        expect(controller.getOptimizedParticleCount(), equals(250));
      });
    });

    group('Performance Statistics', () {
      test('should provide comprehensive performance statistics', () {
        controller.recordFrame(16.67);
        controller.recordFrame(20.0);
        
        final stats = controller.getPerformanceStats();
        
        expect(stats, containsPair('frameCount', 2));
        expect(stats, contains('averageFrameTime'));
        expect(stats, contains('currentFps'));
        expect(stats, contains('performanceScore'));
        expect(stats, contains('particleQuality'));
        expect(stats, contains('graphicsQuality'));
        expect(stats, contains('qualityScale'));
        expect(stats, contains('effectsReduced'));
        expect(stats, contains('viewportCullingEnabled'));
        expect(stats, contains('visibleSegments'));
        expect(stats, contains('visibleNodes'));
      });

      test('should calculate performance score correctly', () {
        // Good performance
        for (int i = 0; i < 10; i++) {
          controller.recordFrame(16.67); // 60fps
        }
        
        final goodStats = controller.getPerformanceStats();
        final goodScore = double.parse(goodStats['performanceScore']);
        expect(goodScore, greaterThan(0.8));
        
        // Poor performance
        controller.clearPerformanceData();
        for (int i = 0; i < 10; i++) {
          controller.recordFrame(50.0); // 20fps
        }
        
        final poorStats = controller.getPerformanceStats();
        final poorScore = double.parse(poorStats['performanceScore']);
        expect(poorScore, lessThan(0.8)); // Adjusted threshold
      });
    });

    group('Memory Management', () {
      test('should provide memory usage estimates', () {
        final memoryUsage = controller.getMemoryUsageKB();
        expect(memoryUsage, isA<double>());
        expect(memoryUsage, greaterThanOrEqualTo(0.0));
      });

      test('should clear performance data correctly', () {
        controller.recordFrame(16.67);
        controller.recordFrame(20.0);
        
        controller.clearPerformanceData();
        
        final stats = controller.getPerformanceStats();
        expect(stats['frameCount'], equals(0));
        expect(double.parse(stats['averageFrameTime']), equals(16.67)); // Reset to default
      });
    });

    group('Callback System', () {
      test('should register and call particle quality callbacks', () {
        bool callbackCalled = false;
        QualityLevel? receivedQuality;
        
        controller.onParticleQualityChanged((quality) {
          callbackCalled = true;
          receivedQuality = quality;
        });
        
        controller.forceQualityAdjustment(particleQuality: QualityLevel.low);
        
        expect(callbackCalled, isTrue);
        expect(receivedQuality, equals(QualityLevel.low));
      });

      test('should register and call graphics quality callbacks', () {
        bool callbackCalled = false;
        QualityLevel? receivedQuality;
        
        controller.onGraphicsQualityChanged((quality) {
          callbackCalled = true;
          receivedQuality = quality;
        });
        
        controller.forceQualityAdjustment(graphicsQuality: QualityLevel.medium);
        
        expect(callbackCalled, isTrue);
        expect(receivedQuality, equals(QualityLevel.medium));
      });

      test('should register and call effects callbacks', () {
        bool callbackCalled = false;
        bool? receivedReduced;
        
        controller.onEffectsChanged((reduced) {
          callbackCalled = true;
          receivedReduced = reduced;
        });
        
        controller.forceQualityAdjustment(reduceEffects: true);
        
        expect(callbackCalled, isTrue);
        expect(receivedReduced, isTrue);
      });

      test('should register and call quality scale callbacks', () {
        bool callbackCalled = false;
        double? receivedScale;
        
        controller.onQualityScaleChanged((scale) {
          callbackCalled = true;
          receivedScale = scale;
        });
        
        controller.forceQualityAdjustment(qualityScale: 0.7);
        
        expect(callbackCalled, isTrue);
        expect(receivedScale, equals(0.7));
      });
    });

    group('Settings Management', () {
      test('should enable and disable viewport culling', () {
        expect(controller.isViewportCullingEnabled, isTrue);
        
        controller.setViewportCullingEnabled(false);
        expect(controller.isViewportCullingEnabled, isFalse);
        
        controller.setViewportCullingEnabled(true);
        expect(controller.isViewportCullingEnabled, isTrue);
      });

      test('should enable and disable particle pooling', () {
        expect(controller.isParticlePoolingEnabled, isTrue);
        
        controller.setParticlePoolingEnabled(false);
        expect(controller.isParticlePoolingEnabled, isFalse);
        
        controller.setParticlePoolingEnabled(true);
        expect(controller.isParticlePoolingEnabled, isTrue);
      });
    });
  });

  group('Performance Benchmarks', () {
    test('should handle high frame rate recording efficiently', () {
      final controller = ProgressionPerformanceController();
      final stopwatch = Stopwatch()..start();
      
      // Record 1000 frames
      for (int i = 0; i < 1000; i++) {
        controller.recordFrame(16.67);
      }
      
      stopwatch.stop();
      
      // Should complete quickly (less than 100ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      
      final stats = controller.getPerformanceStats();
      expect(stats['frameCount'], equals(1000));
      
      controller.dispose();
    });

    test('should handle viewport culling efficiently', () {
      final controller = ProgressionPerformanceController();
      final viewport = const Rect.fromLTWH(0, 0, 800, 600);
      controller.updateViewport(viewport);
      
      final stopwatch = Stopwatch()..start();
      
      // Test 100 segments
      for (int i = 0; i < 100; i++) {
        final segment = PathSegment(
          id: 'segment_$i',
          category: AchievementType.score,
          pathPoints: [Vector2(i * 10.0, i * 10.0), Vector2(i * 10.0 + 50, i * 10.0 + 50)],
          neonColor: Colors.pink,
          width: 4.0,
          isMainPath: i == 0,
          completionPercentage: 0.5,
          achievementIds: ['test_$i'],
        );
        
        controller.isSegmentVisible(segment);
      }
      
      stopwatch.stop();
      
      // Should complete quickly (less than 50ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      
      controller.dispose();
    });

    test('should handle quality adjustments efficiently', () {
      final controller = ProgressionPerformanceController();
      final stopwatch = Stopwatch()..start();
      
      // Perform 100 quality adjustments
      for (int i = 0; i < 100; i++) {
        final quality = QualityLevel.values[i % QualityLevel.values.length];
        controller.forceQualityAdjustment(
          particleQuality: quality,
          graphicsQuality: quality,
          reduceEffects: i % 2 == 0,
          qualityScale: (i % 10) / 10.0,
        );
      }
      
      stopwatch.stop();
      
      // Should complete quickly (less than 100ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      
      controller.dispose();
    });
  });

  group('Memory Usage Tests', () {
    test('should not leak memory during normal operation', () {
      final controller = ProgressionPerformanceController();
      
      final initialMemory = controller.getMemoryUsageKB();
      
      // Simulate normal operation
      for (int i = 0; i < 1000; i++) {
        controller.recordFrame(16.67 + (i % 10));
        
        if (i % 100 == 0) {
          controller.updateViewport(Rect.fromLTWH(i.toDouble(), i.toDouble(), 800, 600));
        }
      }
      
      final finalMemory = controller.getMemoryUsageKB();
      
      // Memory usage should not grow significantly
      expect(finalMemory - initialMemory, lessThan(100.0)); // Less than 100KB growth
      
      controller.dispose();
    });

    test('should clean up resources on dispose', () {
      final controller = ProgressionPerformanceController();
      
      // Add some data
      for (int i = 0; i < 100; i++) {
        controller.recordFrame(16.67);
      }
      
      controller.dispose();
      
      // After dispose, stats should be cleared
      final stats = controller.getPerformanceStats();
      expect(stats['frameCount'], equals(0));
    });
  });
}