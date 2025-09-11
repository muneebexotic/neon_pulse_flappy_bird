import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:neon_pulse_flappy_bird/game/components/power_up.dart';
import 'package:neon_pulse_flappy_bird/game/components/bird.dart';
import 'package:neon_pulse_flappy_bird/game/managers/power_up_manager.dart';
import 'package:neon_pulse_flappy_bird/game/managers/obstacle_manager.dart';
import 'package:neon_pulse_flappy_bird/models/game_state.dart';

void main() {
  group('PowerUp Tests', () {
    test('ShieldPowerUp should have correct properties', () {
      final powerUp = ShieldPowerUp(startPosition: Vector2(100, 200));
      
      expect(powerUp.type, PowerUpType.shield);
      expect(powerUp.duration, 3.0);
      expect(powerUp.position.x, 100);
      expect(powerUp.position.y, 200);
      expect(powerUp.isCollected, false);
      expect(powerUp.shouldRemove, false);
      expect(powerUp.effectDescription, "Invulnerable for 3 seconds");
    });
    
    test('ScoreMultiplierPowerUp should have correct properties', () {
      final powerUp = ScoreMultiplierPowerUp(startPosition: Vector2(150, 250));
      
      expect(powerUp.type, PowerUpType.scoreMultiplier);
      expect(powerUp.duration, 10.0);
      expect(powerUp.position.x, 150);
      expect(powerUp.position.y, 250);
      expect(powerUp.effectDescription, "2x Score for 10 seconds");
    });
    
    test('SlowMotionPowerUp should have correct properties', () {
      final powerUp = SlowMotionPowerUp(startPosition: Vector2(200, 300));
      
      expect(powerUp.type, PowerUpType.slowMotion);
      expect(powerUp.duration, 5.0);
      expect(powerUp.position.x, 200);
      expect(powerUp.position.y, 300);
      expect(powerUp.effectDescription, "Slow Motion for 5 seconds");
    });
    
    test('PowerUp should move left over time', () {
      final powerUp = ShieldPowerUp(startPosition: Vector2(100, 200));
      final initialX = powerUp.position.x;
      
      // Update for 1 second
      powerUp.update(1.0);
      
      // Should have moved left by moveSpeed (150 pixels/second)
      expect(powerUp.position.x, initialX - PowerUp.moveSpeed);
    });
    
    test('PowerUp should be marked for removal when off-screen', () {
      final powerUp = ShieldPowerUp(startPosition: Vector2(-50, 200));
      
      powerUp.update(0.1);
      
      expect(powerUp.shouldRemove, true);
    });
    
    test('PowerUp collision detection should work correctly', () {
      final powerUp = ShieldPowerUp(startPosition: Vector2(100, 200));
      final bird = Bird();
      
      // Set up bird position to overlap with power-up
      bird.position = Vector2(110, 210);
      bird.size = Vector2(40, 30);
      
      expect(powerUp.checkCollision(bird), true);
      
      // Move bird away
      bird.position = Vector2(200, 300);
      expect(powerUp.checkCollision(bird), false);
    });
    
    test('PowerUp should be collectable', () {
      final powerUp = ShieldPowerUp(startPosition: Vector2(100, 200));
      
      expect(powerUp.isCollected, false);
      
      powerUp.collect();
      
      expect(powerUp.isCollected, true);
      expect(powerUp.shouldRemove, true);
    });
    
    test('Collected PowerUp should not detect collisions', () {
      final powerUp = ShieldPowerUp(startPosition: Vector2(100, 200));
      final bird = Bird();
      bird.position = Vector2(110, 210);
      bird.size = Vector2(40, 30);
      
      // Should detect collision before collection
      expect(powerUp.checkCollision(bird), true);
      
      // Collect the power-up
      powerUp.collect();
      
      // Should not detect collision after collection
      expect(powerUp.checkCollision(bird), false);
    });
  });
  
  group('ActivePowerUpEffect Tests', () {
    test('ActivePowerUpEffect should track remaining time correctly', () {
      final effect = ActivePowerUpEffect(
        type: PowerUpType.shield,
        duration: 5.0,
        remainingTime: 5.0,
      );
      
      expect(effect.progress, 1.0);
      expect(effect.isAboutToExpire, false);
      
      // Simulate 3 seconds passing
      effect.remainingTime = 2.0;
      
      expect(effect.progress, 0.4);
      expect(effect.isAboutToExpire, false);
      
      // Simulate 1 more second
      effect.remainingTime = 1.0;
      
      expect(effect.progress, 0.2);
      expect(effect.isAboutToExpire, true);
    });
    
    test('ActivePowerUpEffect should have correct descriptions and colors', () {
      final shieldEffect = ActivePowerUpEffect(
        type: PowerUpType.shield,
        duration: 3.0,
        remainingTime: 3.0,
      );
      
      expect(shieldEffect.description, "Shield");
      expect(shieldEffect.color, Colors.lightBlueAccent);
      
      final scoreEffect = ActivePowerUpEffect(
        type: PowerUpType.scoreMultiplier,
        duration: 10.0,
        remainingTime: 10.0,
      );
      
      expect(scoreEffect.description, "2x Score");
      expect(scoreEffect.color, Colors.greenAccent);
      
      final slowEffect = ActivePowerUpEffect(
        type: PowerUpType.slowMotion,
        duration: 5.0,
        remainingTime: 5.0,
      );
      
      expect(slowEffect.description, "Slow Motion");
      expect(slowEffect.color, Colors.pinkAccent);
    });
  });
  
  group('PowerUpManager Tests', () {
    late PowerUpManager powerUpManager;
    late Bird bird;
    late ObstacleManager obstacleManager;
    late GameState gameState;
    
    setUp(() {
      bird = Bird();
      obstacleManager = ObstacleManager(
        worldWidth: 800,
        worldHeight: 600,
      );
      gameState = GameState();
      
      powerUpManager = PowerUpManager(
        worldWidth: 800,
        worldHeight: 600,
        bird: bird,
        obstacleManager: obstacleManager,
        gameState: gameState,
      );
    });
    
    test('PowerUpManager should initialize with correct default values', () {
      expect(powerUpManager.activePowerUpCount, 0);
      expect(powerUpManager.activeEffectCount, 0);
      expect(powerUpManager.isBirdInvulnerable, false);
      expect(powerUpManager.scoreMultiplier, 1.0);
      expect(powerUpManager.gameSpeedMultiplier, 1.0);
    });
    
    test('PowerUpManager should track active effects correctly', () {
      // Simulate collecting a shield power-up
      final shieldPowerUp = ShieldPowerUp(startPosition: Vector2(100, 200));
      powerUpManager.activePowerUps.add(shieldPowerUp);
      
      // Simulate collection
      shieldPowerUp.collect();
      powerUpManager.activePowerUps.remove(shieldPowerUp);
      
      // Manually add effect (simulating activation)
      final effect = ActivePowerUpEffect(
        type: PowerUpType.shield,
        duration: 3.0,
        remainingTime: 3.0,
      );
      powerUpManager.activeEffects.add(effect);
      
      expect(powerUpManager.isPowerUpActive(PowerUpType.shield), true);
      expect(powerUpManager.isBirdInvulnerable, true);
      expect(powerUpManager.getPowerUpRemainingTime(PowerUpType.shield), 3.0);
    });
    
    test('PowerUpManager should handle multiple effects correctly', () {
      // Add shield effect
      final shieldEffect = ActivePowerUpEffect(
        type: PowerUpType.shield,
        duration: 3.0,
        remainingTime: 3.0,
      );
      powerUpManager.activeEffects.add(shieldEffect);
      
      // Add score multiplier effect
      final scoreEffect = ActivePowerUpEffect(
        type: PowerUpType.scoreMultiplier,
        duration: 10.0,
        remainingTime: 10.0,
      );
      powerUpManager.activeEffects.add(scoreEffect);
      
      expect(powerUpManager.activeEffectCount, 2);
      expect(powerUpManager.isBirdInvulnerable, true);
      expect(powerUpManager.scoreMultiplier, 2.0);
      expect(powerUpManager.gameSpeedMultiplier, 1.0);
    });
    
    test('PowerUpManager should remove expired effects', () {
      // Add an effect that's about to expire
      final effect = ActivePowerUpEffect(
        type: PowerUpType.shield,
        duration: 3.0,
        remainingTime: 0.1,
      );
      powerUpManager.activeEffects.add(effect);
      
      expect(powerUpManager.activeEffectCount, 1);
      
      // Update for longer than remaining time
      powerUpManager.update(0.2);
      
      expect(powerUpManager.activeEffectCount, 0);
      expect(powerUpManager.isBirdInvulnerable, false);
    });
    
    test('PowerUpManager should clear all power-ups and effects', () {
      // Add some power-ups and effects
      final powerUp = ShieldPowerUp(startPosition: Vector2(100, 200));
      powerUpManager.activePowerUps.add(powerUp);
      
      final effect = ActivePowerUpEffect(
        type: PowerUpType.shield,
        duration: 3.0,
        remainingTime: 3.0,
      );
      powerUpManager.activeEffects.add(effect);
      
      expect(powerUpManager.activePowerUpCount, 1);
      expect(powerUpManager.activeEffectCount, 1);
      
      powerUpManager.clearAll();
      
      expect(powerUpManager.activePowerUpCount, 0);
      expect(powerUpManager.activeEffectCount, 0);
    });
    
    test('PowerUpManager should refresh effect duration when same type collected', () {
      // Add initial shield effect with 1 second remaining
      final initialEffect = ActivePowerUpEffect(
        type: PowerUpType.shield,
        duration: 3.0,
        remainingTime: 1.0,
      );
      powerUpManager.activeEffects.add(initialEffect);
      
      expect(powerUpManager.getPowerUpRemainingTime(PowerUpType.shield), 1.0);
      
      // Simulate collecting another shield power-up
      final newShieldPowerUp = ShieldPowerUp(startPosition: Vector2(100, 200));
      
      // Manually simulate activation (normally done by _activatePowerUp)
      powerUpManager.activeEffects.removeWhere((e) => e.type == PowerUpType.shield);
      final newEffect = ActivePowerUpEffect(
        type: PowerUpType.shield,
        duration: 3.0,
        remainingTime: 3.0,
      );
      powerUpManager.activeEffects.add(newEffect);
      
      // Should have refreshed to full duration
      expect(powerUpManager.getPowerUpRemainingTime(PowerUpType.shield), 3.0);
      expect(powerUpManager.activeEffectCount, 1); // Should still be only 1 effect
    });
  });
  
  group('PowerUp Integration Tests', () {
    test('Score multiplier should affect game state correctly', () {
      final gameState = GameState();
      
      // Normal scoring
      gameState.incrementScore();
      expect(gameState.currentScore, 1);
      
      // With score multiplier
      gameState.scoreMultiplier = 2.0;
      gameState.incrementScore();
      expect(gameState.currentScore, 3); // 1 + (1 * 2.0)
      
      // Reset multiplier
      gameState.scoreMultiplier = 1.0;
      gameState.incrementScore();
      expect(gameState.currentScore, 4); // 3 + (1 * 1.0)
    });
    
    test('Game state should track power-up effects correctly', () {
      final gameState = GameState();
      
      expect(gameState.scoreMultiplier, 1.0);
      expect(gameState.isInvulnerable, false);
      expect(gameState.gameSpeedMultiplier, 1.0);
      
      gameState.updatePowerUpEffects(
        newScoreMultiplier: 2.0,
        newIsInvulnerable: true,
        newGameSpeedMultiplier: 0.5,
      );
      
      expect(gameState.scoreMultiplier, 2.0);
      expect(gameState.isInvulnerable, true);
      expect(gameState.gameSpeedMultiplier, 0.5);
    });
    
    test('Game state reset should clear power-up effects', () {
      final gameState = GameState();
      
      // Set some power-up effects
      gameState.updatePowerUpEffects(
        newScoreMultiplier: 2.0,
        newIsInvulnerable: true,
        newGameSpeedMultiplier: 0.5,
      );
      
      // Reset game state
      gameState.reset();
      
      expect(gameState.scoreMultiplier, 1.0);
      expect(gameState.isInvulnerable, false);
      expect(gameState.gameSpeedMultiplier, 1.0);
    });
  });
}