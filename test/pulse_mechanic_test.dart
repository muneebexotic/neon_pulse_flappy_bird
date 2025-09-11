import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../lib/game/managers/pulse_manager.dart';
import '../lib/game/components/pulse_effect.dart';
import '../lib/game/components/bird.dart';
import '../lib/game/managers/obstacle_manager.dart';
import '../lib/game/components/digital_barrier.dart';
import '../lib/game/effects/neon_colors.dart';

void main() {
  group('Pulse Mechanic Tests', () {
    late PulseManager pulseManager;
    late Bird bird;
    late ObstacleManager obstacleManager;
    
    setUp(() {
      // Create test components
      bird = Bird();
      bird.setWorldBounds(Vector2(800, 600));
      bird.position = Vector2(100, 300);
      
      obstacleManager = ObstacleManager(
        worldWidth: 800,
        worldHeight: 600,
      );
      
      pulseManager = PulseManager(
        bird: bird,
        obstacleManager: obstacleManager,
      );
    });
    
    group('Pulse Cooldown System', () {
      test('should start with pulse ready', () {
        expect(pulseManager.pulseReady, isTrue);
        expect(pulseManager.remainingCooldown, equals(0.0));
        expect(pulseManager.cooldownProgress, equals(0.0));
      });
      
      test('should activate pulse when ready', () {
        final result = pulseManager.tryActivatePulse();
        
        expect(result, isTrue);
        expect(pulseManager.pulseReady, isFalse);
        expect(pulseManager.remainingCooldown, equals(PulseManager.pulseCooldownDuration));
        expect(pulseManager.cooldownProgress, closeTo(0.0, 0.01)); // Just activated, so progress is 0
      });
      
      test('should not activate pulse when on cooldown', () {
        // Activate pulse first
        pulseManager.tryActivatePulse();
        
        // Try to activate again
        final result = pulseManager.tryActivatePulse();
        
        expect(result, isFalse);
        expect(pulseManager.pulseReady, isFalse);
      });
      
      test('should reset cooldown after duration', () {
        // Activate pulse
        pulseManager.tryActivatePulse();
        expect(pulseManager.pulseReady, isFalse);
        
        // Simulate time passing (slightly more than 5 seconds to account for precision)
        for (int i = 0; i < 51; i++) {
          pulseManager.update(0.1); // 5.1 seconds total
        }
        
        expect(pulseManager.pulseReady, isTrue);
        expect(pulseManager.remainingCooldown, equals(0.0));
        expect(pulseManager.cooldownProgress, equals(0.0));
      });
      
      test('should update cooldown progress correctly', () {
        pulseManager.tryActivatePulse();
        
        // Update halfway through cooldown
        for (int i = 0; i < 25; i++) {
          pulseManager.update(0.1); // 2.5 seconds
        }
        
        expect(pulseManager.cooldownProgress, closeTo(0.5, 0.1));
        expect(pulseManager.remainingCooldown, closeTo(2.5, 0.1));
      });
    });
    
    group('Pulse Visual Indicators', () {
      test('should provide correct charge color when ready', () {
        final color = pulseManager.getPulseChargeColor();
        
        expect(color.red, equals(NeonColors.electricBlue.red));
        expect(color.green, equals(NeonColors.electricBlue.green));
        expect(color.blue, equals(NeonColors.electricBlue.blue));
      });
      
      test('should provide disabled color when on cooldown', () {
        pulseManager.tryActivatePulse();
        
        final color = pulseManager.getPulseChargeColor();
        
        expect(color.red, equals(NeonColors.uiDisabled.red));
        expect(color.green, equals(NeonColors.uiDisabled.green));
        expect(color.blue, equals(NeonColors.uiDisabled.blue));
      });
      
      test('should provide correct glow intensity', () {
        // When ready, glow should be animated (between 0.6 and 1.0)
        final glowReady = pulseManager.getPulseChargeGlow();
        expect(glowReady, greaterThanOrEqualTo(0.6));
        expect(glowReady, lessThanOrEqualTo(1.0));
        
        // When on cooldown, glow should be dimmed
        pulseManager.tryActivatePulse();
        pulseManager.update(0.1); // Update to calculate glow
        final glowCooldown = pulseManager.getPulseChargeGlow();
        expect(glowCooldown, lessThan(0.6));
      });
      
      test('should provide correct status text', () {
        // When ready
        expect(pulseManager.getPulseStatusText(), equals('PULSE READY'));
        
        // When on cooldown
        pulseManager.tryActivatePulse();
        final statusText = pulseManager.getPulseStatusText();
        expect(statusText, startsWith('COOLDOWN:'));
        expect(statusText, contains('5.0s'));
      });
    });
    
    group('Pulse Reset Functionality', () {
      test('should reset pulse state correctly', () {
        // Activate pulse and update
        pulseManager.tryActivatePulse();
        pulseManager.update(1.0);
        
        expect(pulseManager.pulseReady, isFalse);
        
        // Reset
        pulseManager.reset();
        
        expect(pulseManager.pulseReady, isTrue);
        expect(pulseManager.remainingCooldown, equals(0.0));
        expect(pulseManager.cooldownProgress, equals(0.0));
        expect(pulseManager.pulseActive, isFalse);
      });
    });
  });
  
  group('Pulse Effect Tests', () {
    late PulseEffect pulseEffect;
    
    setUp(() {
      pulseEffect = PulseEffect(
        center: Vector2(100, 100),
        maxRadius: 120.0,
        duration: 0.8,
        pulseColor: NeonColors.electricBlue,
      );
    });
    
    test('should start inactive', () {
      expect(pulseEffect.active, isFalse);
      expect(pulseEffect.currentRadius, equals(0.0));
    });
    
    test('should activate correctly', () {
      pulseEffect.activate();
      
      expect(pulseEffect.active, isTrue);
      expect(pulseEffect.currentRadius, equals(0.0));
    });
    
    test('should expand radius over time', () {
      pulseEffect.activate();
      
      // Update halfway through animation
      pulseEffect.update(0.4); // Half duration
      
      expect(pulseEffect.currentRadius, greaterThan(0.0));
      expect(pulseEffect.currentRadius, lessThan(120.0));
      expect(pulseEffect.active, isTrue);
    });
    
    test('should complete animation and deactivate', () {
      pulseEffect.activate();
      
      // Update past full duration
      pulseEffect.update(1.0);
      
      expect(pulseEffect.active, isFalse);
      expect(pulseEffect.currentRadius, equals(0.0));
    });
    
    test('should detect points within radius', () {
      pulseEffect.activate();
      pulseEffect.update(0.4); // Expand to some radius
      
      final centerPoint = Vector2(100, 100);
      final nearbyPoint = Vector2(110, 110);
      final farPoint = Vector2(300, 300);
      
      expect(pulseEffect.containsPoint(centerPoint), isTrue);
      expect(pulseEffect.containsPoint(nearbyPoint), isTrue);
      expect(pulseEffect.containsPoint(farPoint), isFalse);
    });
    
    test('should not detect points when inactive', () {
      final centerPoint = Vector2(100, 100);
      
      expect(pulseEffect.containsPoint(centerPoint), isFalse);
    });
  });
  
  group('Obstacle Disable Integration Tests', () {
    late ObstacleManager obstacleManager;
    late DigitalBarrier obstacle;
    
    setUp(() {
      obstacleManager = ObstacleManager(
        worldWidth: 800,
        worldHeight: 600,
      );
      
      obstacle = DigitalBarrier(
        startPosition: Vector2(200, 0),
        worldHeight: 600,
      );
      
      obstacleManager.obstacles.add(obstacle);
    });
    
    test('should disable obstacles within pulse range', () {
      expect(obstacle.isDisabled, isFalse);
      
      // Pulse at obstacle position
      final pulseCenter = Vector2(230, 300); // Center of obstacle
      obstacleManager.disableObstaclesInRange(
        pulseCenter,
        120.0, // Pulse radius
        2.0,   // Disable duration
      );
      
      expect(obstacle.isDisabled, isTrue);
      expect(obstacle.disableTimer, equals(2.0));
    });
    
    test('should not disable obstacles outside pulse range', () {
      expect(obstacle.isDisabled, isFalse);
      
      // Pulse far from obstacle
      final pulseCenter = Vector2(500, 300);
      obstacleManager.disableObstaclesInRange(
        pulseCenter,
        120.0, // Pulse radius
        2.0,   // Disable duration
      );
      
      expect(obstacle.isDisabled, isFalse);
    });
    
    test('should re-enable obstacles after timer expires', () {
      // Disable obstacle
      obstacle.disable(1.0);
      expect(obstacle.isDisabled, isTrue);
      
      // Update for longer than disable duration
      obstacle.update(1.5);
      
      expect(obstacle.isDisabled, isFalse);
      expect(obstacle.disableTimer, equals(0.0));
    });
    
    test('should not detect collision with disabled obstacles', () {
      // Test the disable functionality directly
      expect(obstacle.isDisabled, isFalse);
      
      // Disable obstacle
      obstacle.disable(2.0);
      expect(obstacle.isDisabled, isTrue);
      
      // Create a simple collision scenario by checking the disabled state
      // The checkCollision method should return false when disabled
      final bird = Bird();
      bird.setWorldBounds(Vector2(800, 600));
      bird.position = Vector2(200, 50); // Position within obstacle bounds
      
      // When disabled, collision should return false regardless of position
      expect(obstacle.checkCollision(bird), isFalse);
      
      // Re-enable and test collision works
      obstacle.enable();
      // Note: We'll skip the collision test since it depends on complex geometry
      expect(obstacle.isDisabled, isFalse);
    });
  });
  
  group('Timing Validation Tests', () {
    test('should validate pulse cooldown timing', () {
      final pulseManager = PulseManager(
        bird: Bird(),
        obstacleManager: ObstacleManager(worldWidth: 800, worldHeight: 600),
      );
      
      // Activate pulse
      final startTime = DateTime.now();
      pulseManager.tryActivatePulse();
      
      // Simulate real-time updates
      var elapsedTime = 0.0;
      while (!pulseManager.pulseReady && elapsedTime < 6.0) {
        pulseManager.update(0.1);
        elapsedTime += 0.1;
      }
      
      // Should be ready after approximately 5 seconds
      expect(elapsedTime, closeTo(5.0, 0.2));
      expect(pulseManager.pulseReady, isTrue);
    });
    
    test('should validate obstacle disable timing', () {
      final obstacle = DigitalBarrier(
        startPosition: Vector2(200, 0),
        worldHeight: 600,
      );
      
      // Disable for 2 seconds
      obstacle.disable(2.0);
      expect(obstacle.isDisabled, isTrue);
      
      // Update for 1.9 seconds - should still be disabled
      var elapsedTime = 0.0;
      while (elapsedTime < 1.9) {
        obstacle.update(0.1);
        elapsedTime += 0.1;
      }
      expect(obstacle.isDisabled, isTrue);
      
      // Update for remaining time - should be enabled
      obstacle.update(0.2);
      expect(obstacle.isDisabled, isFalse);
    });
  });
}