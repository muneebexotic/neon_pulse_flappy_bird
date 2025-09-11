import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flame/components.dart';
import '../lib/game/neon_pulse_game.dart';
import '../lib/game/components/digital_barrier.dart';
import '../lib/game/components/pulse_effect.dart';
import '../lib/game/effects/neon_colors.dart';

void main() {
  group('Performance Tests', () {
    test('should handle multiple obstacles without significant lag', () async {
      final game = NeonPulseGame();
      await game.onLoad();
      
      // Create multiple obstacles to simulate heavy load
      final obstacles = <DigitalBarrier>[];
      for (int i = 0; i < 5; i++) {
        final obstacle = DigitalBarrier(
          startPosition: Vector2(400.0 + i * 200, 0),
          worldHeight: 600,
        );
        obstacles.add(obstacle);
        game.add(obstacle);
      }
      
      // Measure update performance
      final stopwatch = Stopwatch()..start();
      
      // Simulate 60 frames (1 second at 60fps)
      for (int frame = 0; frame < 60; frame++) {
        game.update(1.0 / 60.0);
      }
      
      stopwatch.stop();
      
      // Should complete 60 frames in reasonable time (less than 100ms for tests)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      
      // Clean up
      for (final obstacle in obstacles) {
        obstacle.removeFromParent();
      }
    });
    
    test('should handle pulse effects efficiently', () async {
      final game = NeonPulseGame();
      await game.onLoad();
      
      // Create multiple pulse effects
      final pulseEffects = <PulseEffect>[];
      for (int i = 0; i < 3; i++) {
        final pulse = PulseEffect(
          center: Vector2(100.0 + i * 50, 300),
          maxRadius: 120.0,
          duration: 0.8,
          pulseColor: NeonColors.electricBlue,
        );
        pulse.activate();
        pulseEffects.add(pulse);
        game.add(pulse);
      }
      
      // Measure update performance
      final stopwatch = Stopwatch()..start();
      
      // Simulate 30 frames
      for (int frame = 0; frame < 30; frame++) {
        game.update(1.0 / 60.0);
      }
      
      stopwatch.stop();
      
      // Should complete efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      
      // Clean up
      for (final pulse in pulseEffects) {
        pulse.removeFromParent();
      }
    });
    
    test('should maintain stable frame rate with full game simulation', () async {
      final game = NeonPulseGame();
      await game.onLoad();
      
      // Start the game
      game.startGame();
      
      // Add some obstacles
      for (int i = 0; i < 3; i++) {
        final obstacle = DigitalBarrier(
          startPosition: Vector2(600.0 + i * 300, 0),
          worldHeight: 600,
        );
        game.add(obstacle);
        game.obstacleManager.obstacles.add(obstacle);
      }
      
      // Measure performance over multiple frames
      final frameTimes = <double>[];
      
      for (int frame = 0; frame < 120; frame++) { // 2 seconds at 60fps
        final frameStart = DateTime.now();
        
        game.update(1.0 / 60.0);
        
        final frameEnd = DateTime.now();
        final frameTime = frameEnd.difference(frameStart).inMicroseconds / 1000.0;
        frameTimes.add(frameTime);
      }
      
      // Calculate average frame time
      final averageFrameTime = frameTimes.reduce((a, b) => a + b) / frameTimes.length;
      
      // Should maintain reasonable frame times (less than 16.67ms for 60fps)
      expect(averageFrameTime, lessThan(16.67));
      
      // Check for frame time consistency (no major spikes)
      final maxFrameTime = frameTimes.reduce((a, b) => a > b ? a : b);
      expect(maxFrameTime, lessThan(33.33)); // No frame should take longer than 30fps
      
      debugPrint('Average frame time: ${averageFrameTime.toStringAsFixed(2)}ms');
      debugPrint('Max frame time: ${maxFrameTime.toStringAsFixed(2)}ms');
    });
    
    test('should handle obstacle spawning without performance drops', () async {
      final game = NeonPulseGame();
      await game.onLoad();
      
      game.startGame();
      
      // Measure performance during obstacle spawning
      final spawnTimes = <double>[];
      
      for (int i = 0; i < 10; i++) {
        final spawnStart = DateTime.now();
        
        // Manually trigger obstacle spawn
        final obstacle = DigitalBarrier(
          startPosition: Vector2(800.0, 0),
          worldHeight: 600,
        );
        game.add(obstacle);
        game.obstacleManager.obstacles.add(obstacle);
        
        // Update game for a few frames after spawn
        for (int frame = 0; frame < 5; frame++) {
          game.update(1.0 / 60.0);
        }
        
        final spawnEnd = DateTime.now();
        final spawnTime = spawnEnd.difference(spawnStart).inMicroseconds / 1000.0;
        spawnTimes.add(spawnTime);
      }
      
      // Calculate average spawn time
      final averageSpawnTime = spawnTimes.reduce((a, b) => a + b) / spawnTimes.length;
      
      // Obstacle spawning should be fast (less than 5ms including 5 frame updates)
      expect(averageSpawnTime, lessThan(5.0));
      
      debugPrint('Average obstacle spawn time: ${averageSpawnTime.toStringAsFixed(2)}ms');
    });
    
    test('should handle particle system efficiently', () async {
      final game = NeonPulseGame();
      await game.onLoad();
      
      game.startGame();
      
      // Trigger particle creation through bird jumps
      final particleTestTimes = <double>[];
      
      for (int i = 0; i < 20; i++) {
        final testStart = DateTime.now();
        
        // Make bird jump (creates particles)
        game.bird.jump();
        
        // Update for a few frames to process particles
        for (int frame = 0; frame < 3; frame++) {
          game.update(1.0 / 60.0);
        }
        
        final testEnd = DateTime.now();
        final testTime = testEnd.difference(testStart).inMicroseconds / 1000.0;
        particleTestTimes.add(testTime);
      }
      
      // Calculate average particle processing time
      final averageParticleTime = particleTestTimes.reduce((a, b) => a + b) / particleTestTimes.length;
      
      // Particle processing should be efficient
      expect(averageParticleTime, lessThan(3.0));
      
      debugPrint('Average particle processing time: ${averageParticleTime.toStringAsFixed(2)}ms');
    });
  });
}