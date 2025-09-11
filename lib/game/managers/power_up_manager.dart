import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../components/power_up.dart';
import '../components/bird.dart';
import '../managers/obstacle_manager.dart';
import '../../models/game_state.dart';

/// Manages power-up spawning, collection, and effects
class PowerUpManager extends Component {
  // Spawning properties
  static const double spawnInterval = 15.0; // seconds between power-ups
  static const double spawnChance = 0.3; // 30% chance to spawn when interval reached
  double spawnTimer = 0.0;
  
  // World properties
  late double worldWidth;
  late double worldHeight;
  
  // Power-up tracking
  final List<PowerUp> activePowerUps = [];
  final List<ActivePowerUpEffect> activeEffects = [];
  
  // References to other game components
  late Bird bird;
  late ObstacleManager obstacleManager;
  late GameState gameState;
  
  // Random number generator
  final math.Random _random = math.Random();
  
  PowerUpManager({
    required this.worldWidth,
    required this.worldHeight,
    required this.bird,
    required this.obstacleManager,
    required this.gameState,
  });
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update spawn timer
    spawnTimer += dt;
    
    // Spawn new power-ups
    if (_shouldSpawnPowerUp()) {
      _spawnPowerUp();
      spawnTimer = 0.0;
    }
    
    // Update all power-ups
    _updatePowerUps(dt);
    
    // Check for power-up collections
    _checkCollections();
    
    // Update active effects
    _updateActiveEffects(dt);
    
    // Remove expired power-ups
    _removeExpiredPowerUps();
  }
  
  /// Check if a power-up should be spawned
  bool _shouldSpawnPowerUp() {
    return spawnTimer >= spawnInterval && _random.nextDouble() < spawnChance;
  }
  
  /// Spawn a new power-up between obstacles
  void _spawnPowerUp() {
    // Find a safe position between obstacles
    final spawnPosition = _findSafeSpawnPosition();
    if (spawnPosition == null) {
      debugPrint('No safe spawn position found for power-up');
      return;
    }
    
    // Select random power-up type
    final powerUpType = _selectRandomPowerUpType();
    
    // Create power-up
    final powerUp = _createPowerUp(powerUpType, spawnPosition);
    if (powerUp != null) {
      activePowerUps.add(powerUp);
      parent?.add(powerUp);
      debugPrint('Spawned ${powerUpType.name} power-up at ${spawnPosition}');
    }
  }
  
  /// Find a safe position to spawn power-up (between obstacles)
  Vector2? _findSafeSpawnPosition() {
    final spawnX = worldWidth + 50.0; // Spawn off-screen to the right
    
    // Try different Y positions to find one that's safe
    for (int attempt = 0; attempt < 10; attempt++) {
      final spawnY = 100.0 + _random.nextDouble() * (worldHeight - 200.0);
      final testPosition = Vector2(spawnX, spawnY);
      
      // Check if position is safe (not too close to obstacles)
      if (_isPositionSafe(testPosition)) {
        return testPosition;
      }
    }
    
    // If no safe position found, use center Y
    return Vector2(spawnX, worldHeight / 2);
  }
  
  /// Check if a position is safe for power-up spawning
  bool _isPositionSafe(Vector2 position) {
    const safeDistance = 80.0; // Minimum distance from obstacles
    
    // Check distance from all obstacles
    for (final obstacle in obstacleManager.obstacles) {
      final obstacleCenter = Vector2(
        obstacle.position.x + obstacle.size.x / 2,
        obstacle.position.y + obstacle.size.y / 2,
      );
      
      final distance = position.distanceTo(obstacleCenter);
      if (distance < safeDistance) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Select a random power-up type
  PowerUpType _selectRandomPowerUpType() {
    final types = PowerUpType.values;
    return types[_random.nextInt(types.length)];
  }
  
  /// Create a power-up of the specified type
  PowerUp? _createPowerUp(PowerUpType type, Vector2 position) {
    switch (type) {
      case PowerUpType.shield:
        return ShieldPowerUp(startPosition: position);
      case PowerUpType.scoreMultiplier:
        return ScoreMultiplierPowerUp(startPosition: position);
      case PowerUpType.slowMotion:
        return SlowMotionPowerUp(startPosition: position);
    }
  }
  
  /// Update all active power-ups
  void _updatePowerUps(double dt) {
    for (final powerUp in activePowerUps) {
      powerUp.update(dt);
    }
  }
  
  /// Check for power-up collections
  void _checkCollections() {
    final collectedPowerUps = <PowerUp>[];
    
    for (final powerUp in activePowerUps) {
      if (powerUp.checkCollision(bird)) {
        powerUp.collect();
        collectedPowerUps.add(powerUp);
        _activatePowerUp(powerUp);
      }
    }
    
    // Remove collected power-ups
    for (final powerUp in collectedPowerUps) {
      activePowerUps.remove(powerUp);
      powerUp.removeFromParent();
    }
  }
  
  /// Activate a collected power-up
  void _activatePowerUp(PowerUp powerUp) {
    final effect = ActivePowerUpEffect(
      type: powerUp.type,
      duration: powerUp.duration,
      remainingTime: powerUp.duration,
    );
    
    // Remove any existing effect of the same type (refresh duration)
    activeEffects.removeWhere((e) => e.type == powerUp.type);
    
    // Add new effect
    activeEffects.add(effect);
    
    debugPrint('Activated ${powerUp.type.name} power-up for ${powerUp.duration} seconds');
  }
  
  /// Update active power-up effects
  void _updateActiveEffects(double dt) {
    final expiredEffects = <ActivePowerUpEffect>[];
    
    for (final effect in activeEffects) {
      effect.remainingTime -= dt;
      
      if (effect.remainingTime <= 0) {
        expiredEffects.add(effect);
      }
    }
    
    // Remove expired effects
    for (final effect in expiredEffects) {
      activeEffects.remove(effect);
      debugPrint('${effect.type.name} power-up effect expired');
    }
  }
  
  /// Remove expired power-ups
  void _removeExpiredPowerUps() {
    final powerUpsToRemove = <PowerUp>[];
    
    for (final powerUp in activePowerUps) {
      if (powerUp.shouldRemove) {
        powerUpsToRemove.add(powerUp);
      }
    }
    
    // Remove expired power-ups
    for (final powerUp in powerUpsToRemove) {
      activePowerUps.remove(powerUp);
      powerUp.removeFromParent();
    }
  }
  
  /// Check if a specific power-up effect is active
  bool isPowerUpActive(PowerUpType type) {
    return activeEffects.any((effect) => effect.type == type);
  }
  
  /// Get remaining time for a specific power-up effect
  double getPowerUpRemainingTime(PowerUpType type) {
    final effect = activeEffects.where((e) => e.type == type).firstOrNull;
    return effect?.remainingTime ?? 0.0;
  }
  
  /// Check if bird is invulnerable (shield effect)
  bool get isBirdInvulnerable => isPowerUpActive(PowerUpType.shield);
  
  /// Get score multiplier (1.0 = normal, 2.0 = double points)
  double get scoreMultiplier {
    return isPowerUpActive(PowerUpType.scoreMultiplier) ? 2.0 : 1.0;
  }
  
  /// Get game speed multiplier (1.0 = normal, 0.5 = slow motion)
  double get gameSpeedMultiplier {
    return isPowerUpActive(PowerUpType.slowMotion) ? 0.5 : 1.0;
  }
  
  /// Get all active power-up effects for UI display
  List<ActivePowerUpEffect> get allActiveEffects => List.unmodifiable(activeEffects);
  
  /// Clear all power-ups and effects (for game reset)
  void clearAll() {
    // Remove all power-ups from game
    for (final powerUp in activePowerUps) {
      powerUp.removeFromParent();
    }
    
    // Clear lists
    activePowerUps.clear();
    activeEffects.clear();
    
    // Reset spawn timer
    spawnTimer = 0.0;
    
    debugPrint('All power-ups and effects cleared');
  }
  
  /// Get count of active power-ups on screen
  int get activePowerUpCount => activePowerUps.length;
  
  /// Get count of active effects
  int get activeEffectCount => activeEffects.length;
}

/// Represents an active power-up effect
class ActivePowerUpEffect {
  final PowerUpType type;
  final double duration;
  double remainingTime;
  
  ActivePowerUpEffect({
    required this.type,
    required this.duration,
    required this.remainingTime,
  });
  
  /// Get progress as a percentage (0.0 to 1.0)
  double get progress => remainingTime / duration;
  
  /// Check if effect is about to expire (less than 2 seconds remaining)
  bool get isAboutToExpire => remainingTime < 2.0;
  
  /// Get effect description for UI
  String get description {
    switch (type) {
      case PowerUpType.shield:
        return "Shield";
      case PowerUpType.scoreMultiplier:
        return "2x Score";
      case PowerUpType.slowMotion:
        return "Slow Motion";
    }
  }
  
  /// Get effect color for UI
  Color get color {
    switch (type) {
      case PowerUpType.shield:
        return Colors.lightBlueAccent;
      case PowerUpType.scoreMultiplier:
        return Colors.greenAccent;
      case PowerUpType.slowMotion:
        return Colors.pinkAccent;
    }
  }
}