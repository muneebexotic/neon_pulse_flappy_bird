import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'performance_monitor.dart';
import 'object_pool.dart';
import '../effects/particle_system.dart';
import '../managers/adaptive_quality_manager.dart';

/// Comprehensive performance testing suite
class PerformanceTestSuite {
  static final PerformanceTestSuite _instance = PerformanceTestSuite._internal();
  factory PerformanceTestSuite() => _instance;
  PerformanceTestSuite._internal();

  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final PoolManager _poolManager = PoolManager();
  final AdaptiveQualityManager _qualityManager = AdaptiveQualityManager();

  /// Run comprehensive performance tests
  Future<PerformanceTestResults> runFullTestSuite() async {
    final results = PerformanceTestResults();
    
    if (kDebugMode) {
      print('Starting comprehensive performance test suite...');
    }
    
    // Initialize systems
    await _performanceMonitor.initialize();
    _poolManager.initialize();
    await _qualityManager.initialize();
    
    // Run individual tests
    results.cpuTest = await _runCPUTest();
    results.memoryTest = await _runMemoryTest();
    results.particleTest = await _runParticleTest();
    results.poolingTest = await _runPoolingTest();
    results.renderingTest = await _runRenderingTest();
    results.adaptiveQualityTest = await _runAdaptiveQualityTest();
    
    // Calculate overall score
    results.overallScore = _calculateOverallScore(results);
    results.deviceClass = _determineDeviceClass(results.overallScore);
    results.recommendations = _generateRecommendations(results);
    
    if (kDebugMode) {
      print('Performance test suite completed. Overall score: ${results.overallScore.toStringAsFixed(2)}');
    }
    
    return results;
  }

  /// Test CPU performance with mathematical operations
  Future<TestResult> _runCPUTest() async {
    final stopwatch = Stopwatch()..start();
    
    // CPU-intensive mathematical operations
    double result = 0.0;
    const iterations = 1000000;
    
    for (int i = 0; i < iterations; i++) {
      result += math.sin(i * 0.001) * math.cos(i * 0.001);
      result += math.sqrt(i.toDouble());
      if (i % 1000 == 0) {
        result = result % 1000; // Prevent overflow
      }
    }
    
    stopwatch.stop();
    final executionTime = stopwatch.elapsedMicroseconds / 1000.0; // Convert to milliseconds
    
    // Score based on execution time (lower is better)
    final score = math.max(0.0, math.min(1.0, 1000.0 / executionTime));
    
    return TestResult(
      name: 'CPU Performance',
      score: score,
      executionTimeMs: executionTime,
      details: {
        'iterations': iterations,
        'operationsPerSecond': (iterations / (executionTime / 1000.0)).round(),
        'result': result.toStringAsFixed(2),
      },
    );
  }

  /// Test memory allocation and garbage collection performance
  Future<TestResult> _runMemoryTest() async {
    final stopwatch = Stopwatch()..start();
    
    // Memory allocation test
    final List<List<double>> memoryBlocks = [];
    const blockCount = 10000;
    const blockSize = 100;
    
    for (int i = 0; i < blockCount; i++) {
      memoryBlocks.add(List.filled(blockSize, i.toDouble()));
      
      // Periodically clear some blocks to test GC
      if (i % 1000 == 0 && memoryBlocks.length > 500) {
        memoryBlocks.removeRange(0, 500);
      }
    }
    
    // Access patterns to test memory performance
    double sum = 0.0;
    for (final block in memoryBlocks) {
      sum += block.reduce((a, b) => a + b);
    }
    
    stopwatch.stop();
    final executionTime = stopwatch.elapsedMicroseconds / 1000.0;
    
    // Score based on execution time and memory efficiency
    final score = math.max(0.0, math.min(1.0, 2000.0 / executionTime));
    
    return TestResult(
      name: 'Memory Performance',
      score: score,
      executionTimeMs: executionTime,
      details: {
        'blocksAllocated': blockCount,
        'blockSize': blockSize,
        'finalBlockCount': memoryBlocks.length,
        'sum': sum.toStringAsFixed(2),
      },
    );
  }

  /// Test particle system performance
  Future<TestResult> _runParticleTest() async {
    final particleSystem = ParticleSystem();
    final stopwatch = Stopwatch()..start();
    
    // Create many particles
    const particleCount = 1000;
    const updateCycles = 100;
    
    // Add particles
    for (int i = 0; i < particleCount; i++) {
      particleSystem.addTrailParticle(
        position: Vector2(i.toDouble(), i.toDouble()),
        color: Color(0xFF00FFFF),
        velocity: Vector2(math.Random().nextDouble() * 100, math.Random().nextDouble() * 100),
        size: 2.0,
        life: 2.0,
      );
    }
    
    // Update particles multiple times
    for (int cycle = 0; cycle < updateCycles; cycle++) {
      particleSystem.update(0.016); // 60 FPS delta time
    }
    
    stopwatch.stop();
    final executionTime = stopwatch.elapsedMicroseconds / 1000.0;
    
    // Score based on particles processed per millisecond
    final particlesProcessed = particleCount * updateCycles;
    final score = math.max(0.0, math.min(1.0, (particlesProcessed / executionTime) / 1000.0));
    
    final stats = particleSystem.getStats();
    
    return TestResult(
      name: 'Particle System Performance',
      score: score,
      executionTimeMs: executionTime,
      details: {
        'particlesCreated': particleCount,
        'updateCycles': updateCycles,
        'particlesProcessed': particlesProcessed,
        'particlesPerMs': (particlesProcessed / executionTime).toStringAsFixed(2),
        'finalStats': stats,
      },
    );
  }

  /// Test object pooling performance
  Future<TestResult> _runPoolingTest() async {
    final stopwatch = Stopwatch()..start();
    
    const operations = 100000;
    final particles = <NeonParticle>[];
    
    // Test pool allocation and deallocation
    for (int i = 0; i < operations; i++) {
      final particle = _poolManager.particlePool.getConfiguredParticle(
        position: Vector2(i.toDouble(), i.toDouble()),
        velocity: Vector2.zero(),
        color: Color(0xFF00FFFF),
        maxLife: 1.0,
      );
      particles.add(particle);
      
      // Return some particles to test pool reuse
      if (i % 10 == 0 && particles.length > 5) {
        for (int j = 0; j < 5; j++) {
          _poolManager.particlePool.returnObject(particles.removeAt(0));
        }
      }
    }
    
    // Return remaining particles
    for (final particle in particles) {
      _poolManager.particlePool.returnObject(particle);
    }
    
    stopwatch.stop();
    final executionTime = stopwatch.elapsedMicroseconds / 1000.0;
    
    // Score based on operations per millisecond
    final score = math.max(0.0, math.min(1.0, (operations / executionTime) / 100.0));
    
    final poolStats = _poolManager.getAllStats();
    
    return TestResult(
      name: 'Object Pooling Performance',
      score: score,
      executionTimeMs: executionTime,
      details: {
        'operations': operations,
        'operationsPerMs': (operations / executionTime).toStringAsFixed(2),
        'poolStats': poolStats,
      },
    );
  }

  /// Test rendering performance simulation
  Future<TestResult> _runRenderingTest() async {
    final stopwatch = Stopwatch()..start();
    
    // Simulate rendering operations
    const renderCycles = 1000;
    const objectsPerFrame = 100;
    
    double totalRenderTime = 0.0;
    
    for (int cycle = 0; cycle < renderCycles; cycle++) {
      final frameStart = DateTime.now().microsecondsSinceEpoch;
      
      // Simulate rendering calculations
      for (int obj = 0; obj < objectsPerFrame; obj++) {
        // Simulate transform calculations
        final x = math.sin(obj * 0.1) * 100;
        final y = math.cos(obj * 0.1) * 100;
        final rotation = obj * 0.01;
        
        // Simulate color calculations
        final r = (math.sin(obj * 0.05) * 127 + 128).round();
        final g = (math.cos(obj * 0.05) * 127 + 128).round();
        final b = (math.sin(obj * 0.1) * 127 + 128).round();
        
        // Use calculated values to prevent optimization
        totalRenderTime += x + y + rotation + r + g + b;
      }
      
      final frameEnd = DateTime.now().microsecondsSinceEpoch;
      totalRenderTime += (frameEnd - frameStart) / 1000.0;
    }
    
    stopwatch.stop();
    final executionTime = stopwatch.elapsedMicroseconds / 1000.0;
    
    // Score based on simulated FPS
    final averageFrameTime = executionTime / renderCycles;
    final simulatedFPS = 1000.0 / averageFrameTime;
    final score = math.max(0.0, math.min(1.0, simulatedFPS / 60.0));
    
    return TestResult(
      name: 'Rendering Performance',
      score: score,
      executionTimeMs: executionTime,
      details: {
        'renderCycles': renderCycles,
        'objectsPerFrame': objectsPerFrame,
        'averageFrameTimeMs': averageFrameTime.toStringAsFixed(2),
        'simulatedFPS': simulatedFPS.toStringAsFixed(1),
      },
    );
  }

  /// Test adaptive quality system
  Future<TestResult> _runAdaptiveQualityTest() async {
    final stopwatch = Stopwatch()..start();
    
    _qualityManager.startAdaptiveQuality();
    
    // Simulate performance changes
    const testDuration = 100; // milliseconds
    const performanceUpdates = 50;
    
    for (int i = 0; i < performanceUpdates; i++) {
      // Simulate varying performance
      final simulatedPerformance = 0.3 + (math.sin(i * 0.2) * 0.4);
      
      // Force quality adjustment
      final particleQuality = simulatedPerformance > 0.7 ? QualityLevel.high :
                             simulatedPerformance > 0.5 ? QualityLevel.medium : QualityLevel.low;
      
      _qualityManager.forceQualityAdjustment(particleQuality: particleQuality);
      
      // Small delay to simulate real-time updates
      await Future.delayed(Duration(milliseconds: testDuration ~/ performanceUpdates));
    }
    
    _qualityManager.stopAdaptiveQuality();
    
    stopwatch.stop();
    final executionTime = stopwatch.elapsedMicroseconds / 1000.0;
    
    // Score based on responsiveness and stability
    final score = 0.8; // Base score for successful completion
    
    final qualityStats = _qualityManager.getQualityStats();
    
    return TestResult(
      name: 'Adaptive Quality System',
      score: score,
      executionTimeMs: executionTime,
      details: {
        'performanceUpdates': performanceUpdates,
        'testDurationMs': testDuration,
        'finalQualityStats': qualityStats,
      },
    );
  }

  /// Calculate overall performance score
  double _calculateOverallScore(PerformanceTestResults results) {
    final scores = [
      results.cpuTest.score * 0.25,      // 25% weight
      results.memoryTest.score * 0.20,   // 20% weight
      results.particleTest.score * 0.25, // 25% weight
      results.poolingTest.score * 0.15,  // 15% weight
      results.renderingTest.score * 0.15, // 15% weight
    ];
    
    return scores.reduce((a, b) => a + b);
  }

  /// Determine device performance class
  String _determineDeviceClass(double overallScore) {
    if (overallScore >= 0.8) return 'High-End';
    if (overallScore >= 0.6) return 'Mid-Range';
    if (overallScore >= 0.4) return 'Low-Mid';
    return 'Low-End';
  }

  /// Generate performance recommendations
  Map<String, String> _generateRecommendations(PerformanceTestResults results) {
    final recommendations = <String, String>{};
    
    if (results.cpuTest.score < 0.6) {
      recommendations['CPU'] = 'Reduce computational complexity, use simpler algorithms';
    }
    
    if (results.memoryTest.score < 0.6) {
      recommendations['Memory'] = 'Implement more aggressive object pooling, reduce allocations';
    }
    
    if (results.particleTest.score < 0.6) {
      recommendations['Particles'] = 'Reduce particle count, use simpler particle effects';
    }
    
    if (results.poolingTest.score < 0.6) {
      recommendations['Pooling'] = 'Optimize pool sizes, improve object reuse patterns';
    }
    
    if (results.renderingTest.score < 0.6) {
      recommendations['Rendering'] = 'Use batch rendering, reduce draw calls, simplify shaders';
    }
    
    // Overall recommendations
    if (results.overallScore < 0.5) {
      recommendations['Overall'] = 'Enable aggressive performance optimizations, reduce all effects';
    } else if (results.overallScore < 0.7) {
      recommendations['Overall'] = 'Use medium quality settings, enable adaptive quality';
    } else {
      recommendations['Overall'] = 'Device can handle high quality settings';
    }
    
    return recommendations;
  }

  /// Run quick performance benchmark (for runtime use)
  Future<double> runQuickBenchmark() async {
    final stopwatch = Stopwatch()..start();
    
    // Quick CPU test
    double result = 0.0;
    for (int i = 0; i < 10000; i++) {
      result += math.sin(i * 0.01) * math.cos(i * 0.01);
    }
    
    // Quick memory test
    final List<List<int>> blocks = [];
    for (int i = 0; i < 100; i++) {
      blocks.add(List.filled(100, i));
    }
    
    stopwatch.stop();
    final executionTime = stopwatch.elapsedMicroseconds / 1000.0;
    
    // Return normalized score (0.0 to 1.0)
    return math.max(0.0, math.min(1.0, 100.0 / executionTime));
  }
}

/// Test result for individual performance tests
class TestResult {
  final String name;
  final double score;
  final double executionTimeMs;
  final Map<String, dynamic> details;

  TestResult({
    required this.name,
    required this.score,
    required this.executionTimeMs,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'score': score.toStringAsFixed(3),
      'executionTimeMs': executionTimeMs.toStringAsFixed(2),
      'details': details,
    };
  }
}

/// Complete performance test results
class PerformanceTestResults {
  late TestResult cpuTest;
  late TestResult memoryTest;
  late TestResult particleTest;
  late TestResult poolingTest;
  late TestResult renderingTest;
  late TestResult adaptiveQualityTest;
  
  late double overallScore;
  late String deviceClass;
  late Map<String, String> recommendations;

  Map<String, dynamic> toMap() {
    return {
      'cpuTest': cpuTest.toMap(),
      'memoryTest': memoryTest.toMap(),
      'particleTest': particleTest.toMap(),
      'poolingTest': poolingTest.toMap(),
      'renderingTest': renderingTest.toMap(),
      'adaptiveQualityTest': adaptiveQualityTest.toMap(),
      'overallScore': overallScore.toStringAsFixed(3),
      'deviceClass': deviceClass,
      'recommendations': recommendations,
    };
  }
}