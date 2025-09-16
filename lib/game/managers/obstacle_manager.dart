import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../components/obstacle.dart';
import '../components/digital_barrier.dart';
import '../components/laser_grid.dart';
import '../components/floating_platform.dart';
import '../components/bird.dart';
import 'difficulty_manager.dart';
import 'settings_manager.dart';
import '../neon_pulse_game.dart';

/// Manages obstacle spawning, movement, and removal in the game
class ObstacleManager extends Component {
  // Obstacle spawning properties - increased for better performance
  static const double spawnInterval =
      3.5; // seconds between obstacles (increased)
  static const double spawnDistance =
      400.0; // distance from right edge to spawn
  double spawnTimer = 0.0;

  // World properties
  late double worldWidth;
  late double worldHeight;

  // Obstacle tracking
  final List<Obstacle> obstacles = [];
  final List<Obstacle> passedObstacles = []; // For scoring

  // Difficulty scaling
  double currentGameSpeed = 1.0;
  int difficultyLevel = 1;
  DifficultyLevel? settingsDifficultyLevel;

  // Beat synchronization
  bool beatSyncEnabled = true;
  double lastBeatTime = 0.0;
  double currentBpm = 128.0;
  bool waitingForBeat = false;

  ObstacleManager({required this.worldWidth, required this.worldHeight});

  @override
  void update(double dt) {
    super.update(dt);

    // Check if game is paused - don't update if paused
    final game = findGame() as NeonPulseGame?;
    if (game != null && game.gameState.isPaused) {
      return;
    }

    // Update spawn timer
    spawnTimer += dt;

    // Spawn new obstacles at regular intervals or on beat
    if (_shouldSpawnObstacle()) {
      _spawnObstacle();
      spawnTimer = 0.0;
      waitingForBeat = false;
    }

    // Update all obstacles
    _updateObstacles(dt);

    // Remove off-screen obstacles
    _removeOffScreenObstacles();
  }

  /// Spawn obstacles based on current difficulty level
  void _spawnObstacle() {
    final simultaneousCount = DifficultyManager.calculateSimultaneousObstacles(
      difficultyLevel,
    );

    // Spawn multiple obstacles if difficulty allows
    for (int i = 0; i < simultaneousCount; i++) {
      final obstacleType = DifficultyManager.selectObstacleType(
        difficultyLevel,
      );
      final xOffset = i * 150.0; // Space between simultaneous obstacles

      final obstacle = _createObstacle(
        obstacleType,
        Vector2(worldWidth + spawnDistance + xOffset, 0),
      );

      if (obstacle != null) {
        obstacles.add(obstacle);
        parent?.add(obstacle);

        debugPrint(
          'Spawned ${obstacleType.name} obstacle at x: ${obstacle.position.x}',
        );
      }
    }
  }

  /// Create obstacle of specified type
  Obstacle? _createObstacle(ObstacleType type, Vector2 startPosition) {
    // Get gap size multiplier from current difficulty level
    final gapSizeMultiplier = _getGapSizeMultiplier();

    switch (type) {
      case ObstacleType.digitalBarrier:
        return DigitalBarrier(
          startPosition: startPosition,
          worldHeight: worldHeight,
          gapSizeMultiplier: gapSizeMultiplier,
        );
      case ObstacleType.laserGrid:
        return LaserGrid(
          startPosition: startPosition,
          worldHeight: worldHeight,
          gapSizeMultiplier: gapSizeMultiplier,
        );
      case ObstacleType.floatingPlatform:
        return FloatingPlatform(
          startPosition: startPosition,
          worldHeight: worldHeight,
          gapSizeMultiplier: gapSizeMultiplier,
        );
    }
  }

  /// Update all obstacles (movement, timers, etc.)
  void _updateObstacles(double dt) {
    for (final obstacle in obstacles) {
      obstacle.update(dt);
    }
  }

  /// Remove obstacles that have moved off-screen
  void _removeOffScreenObstacles() {
    final obstaclesToRemove = <Obstacle>[];

    for (final obstacle in obstacles) {
      if (obstacle.shouldRemove) {
        obstaclesToRemove.add(obstacle);
      }
    }

    // Remove obstacles from game and list
    for (final obstacle in obstaclesToRemove) {
      obstacles.remove(obstacle);
      obstacle.removeFromParent();
      debugPrint('Removed off-screen obstacle');
    }
  }

  /// Check collisions between bird and all obstacles
  bool checkCollisions(Bird bird) {
    for (final obstacle in obstacles) {
      if (obstacle.checkCollision(bird)) {
        debugPrint(
          'Collision detected with obstacle at x: ${obstacle.position.x}',
        );
        return true;
      }
    }
    return false;
  }

  /// Check if bird has passed any obstacles (for scoring)
  List<Obstacle> checkPassedObstacles(Bird bird) {
    final newlyPassedObstacles = <Obstacle>[];

    for (final obstacle in obstacles) {
      if (!passedObstacles.contains(obstacle) && obstacle.hasBirdPassed(bird)) {
        newlyPassedObstacles.add(obstacle);
        passedObstacles.add(obstacle);
        debugPrint('Bird passed obstacle - Score point!');
      }
    }

    return newlyPassedObstacles;
  }

  /// Update difficulty settings
  void updateDifficulty(
    double gameSpeed,
    int difficultyLevel, [
    DifficultyLevel? settingsDifficulty,
  ]) {
    currentGameSpeed = gameSpeed;
    this.difficultyLevel = difficultyLevel;
    settingsDifficultyLevel = settingsDifficulty;
  }

  /// Get gap size multiplier based on settings difficulty
  double _getGapSizeMultiplier() {
    return settingsDifficultyLevel?.gapSizeMultiplier ?? 1.0;
  }

  /// Get spawn interval adjusted for current difficulty
  double _getAdjustedSpawnInterval() {
    return DifficultyManager.calculateSpawnInterval(difficultyLevel);
  }

  /// Disable obstacles within pulse range (for pulse mechanic)
  void disableObstaclesInRange(
    Vector2 pulseCenter,
    double pulseRadius,
    double duration,
  ) {
    for (final obstacle in obstacles) {
      if (_circleIntersectsRect(
        pulseCenter,
        pulseRadius,
        obstacle.collisionRect,
      )) {
        obstacle.disable(duration);
        debugPrint('Obstacle disabled by pulse');
      }
    }
  }

  /// Helper to check if circle intersects rectangle
  bool _circleIntersectsRect(Vector2 center, double radius, Rect rect) {
    final cx = center.x;
    final cy = center.y;
    final rx = rect.left;
    final ry = rect.top;
    final rw = rect.width;
    final rh = rect.height;

    final closestX = math.max(rx, math.min(cx, rx + rw));
    final closestY = math.max(ry, math.min(cy, ry + rh));

    final dx = cx - closestX;
    final dy = cy - closestY;

    return (dx * dx + dy * dy) <= (radius * radius);
  }

  /// Clear all obstacles (for game reset)
  void clearAllObstacles() {
    for (final obstacle in obstacles) {
      obstacle.removeFromParent();
    }
    obstacles.clear();
    passedObstacles.clear();
    spawnTimer = 0.0;
    debugPrint('All obstacles cleared');
  }

  /// Get count of active obstacles
  int get obstacleCount => obstacles.length;

  /// Get count of passed obstacles (for scoring)
  int get passedObstacleCount => passedObstacles.length;

  /// Check if any obstacles are currently disabled
  bool get hasDisabledObstacles {
    return obstacles.any((obstacle) => obstacle.isDisabled);
  }

  /// Handle beat detection for synchronized spawning
  void onBeatDetected(double bpm) {
    currentBpm = bpm;
    lastBeatTime = spawnTimer;

    if (beatSyncEnabled &&
        waitingForBeat &&
        spawnTimer >= _getMinSpawnInterval()) {
      _spawnObstacle();
      spawnTimer = 0.0;
      waitingForBeat = false;
    }
  }

  /// Check if obstacle should be spawned based on timing and beat sync
  bool _shouldSpawnObstacle() {
    final adjustedInterval = _getAdjustedSpawnInterval();

    if (!beatSyncEnabled) {
      // Normal time-based spawning
      return spawnTimer >= adjustedInterval;
    }

    // Beat-synchronized spawning
    if (spawnTimer >= adjustedInterval) {
      waitingForBeat = true;
    }

    // Allow spawning if we've waited too long (fallback)
    return spawnTimer >= adjustedInterval * 1.5;
  }

  /// Get minimum spawn interval to prevent obstacles from being too close
  double _getMinSpawnInterval() {
    return spawnInterval * 0.7; // Minimum 70% of base interval
  }

  /// Enable or disable beat synchronization
  void setBeatSyncEnabled(bool enabled) {
    beatSyncEnabled = enabled;
    waitingForBeat = false;
  }
}
