import 'dart:math' as math;

/// Manages progressive difficulty scaling based on player score
class DifficultyManager {
  // Base difficulty settings
  static const double baseGameSpeed = 1.0;
  static const double speedIncreasePerLevel = 0.05; // 5% increase per level
  static const int pointsPerLevel = 10; // Level up every 10 points
  
  // Difficulty plateau settings
  static const int maxDifficultyLevel = 20; // Cap at level 20
  static const double maxGameSpeed = 2.0; // Maximum 2x speed
  
  // Obstacle spawning settings
  static const double baseSpawnInterval = 2.0;
  static const double minSpawnInterval = 1.5; // Minimum time between obstacles
  static const double spawnIntervalReduction = 0.2; // Reduction per level
  
  // Multiple obstacle settings
  static const int multiObstacleStartLevel = 5; // Start spawning multiple obstacles at level 5
  static const int maxSimultaneousObstacles = 3; // Maximum obstacles at once
  
  /// Calculate current difficulty level based on score
  static int calculateDifficultyLevel(int score) {
    final level = (score ~/ pointsPerLevel) + 1;
    return math.min(level, maxDifficultyLevel);
  }
  
  /// Calculate game speed based on difficulty level
  static double calculateGameSpeed(int difficultyLevel) {
    final speed = baseGameSpeed + (difficultyLevel - 1) * speedIncreasePerLevel;
    return math.min(speed, maxGameSpeed);
  }
  
  /// Calculate obstacle spawn interval based on difficulty level
  static double calculateSpawnInterval(int difficultyLevel) {
    final interval = baseSpawnInterval - (difficultyLevel - 1) * spawnIntervalReduction;
    return math.max(interval, minSpawnInterval);
  }
  
  /// Determine if multiple obstacles should spawn based on difficulty level
  static bool shouldSpawnMultipleObstacles(int difficultyLevel) {
    return difficultyLevel >= multiObstacleStartLevel;
  }
  
  /// Calculate number of simultaneous obstacles based on difficulty level
  static int calculateSimultaneousObstacles(int difficultyLevel) {
    if (difficultyLevel < multiObstacleStartLevel) {
      return 1;
    }
    
    final extraObstacles = (difficultyLevel - multiObstacleStartLevel) ~/ 3;
    return math.min(1 + extraObstacles, maxSimultaneousObstacles);
  }
  
  /// Get obstacle type weights based on difficulty level
  static Map<ObstacleType, double> getObstacleTypeWeights(int difficultyLevel) {
    final weights = <ObstacleType, double>{};
    
    // Digital barriers are always available
    weights[ObstacleType.digitalBarrier] = 1.0;
    
    // Laser grids start appearing at level 3
    if (difficultyLevel >= 3) {
      weights[ObstacleType.laserGrid] = 0.3 + (difficultyLevel - 3) * 0.1;
    }
    
    // Floating platforms start appearing at level 6
    if (difficultyLevel >= 6) {
      weights[ObstacleType.floatingPlatform] = 0.2 + (difficultyLevel - 6) * 0.1;
    }
    
    return weights;
  }
  
  /// Select random obstacle type based on difficulty level weights
  static ObstacleType selectObstacleType(int difficultyLevel) {
    final weights = getObstacleTypeWeights(difficultyLevel);
    
    if (weights.isEmpty) {
      return ObstacleType.digitalBarrier;
    }
    
    // Calculate total weight
    final totalWeight = weights.values.reduce((a, b) => a + b);
    
    // Generate random value
    final random = math.Random().nextDouble() * totalWeight;
    
    // Select obstacle type based on weighted random
    double currentWeight = 0.0;
    for (final entry in weights.entries) {
      currentWeight += entry.value;
      if (random <= currentWeight) {
        return entry.key;
      }
    }
    
    // Fallback to digital barrier
    return ObstacleType.digitalBarrier;
  }
  
  /// Check if difficulty has plateaued (for UI feedback)
  static bool isDifficultyAtPlateau(int difficultyLevel) {
    return difficultyLevel >= maxDifficultyLevel;
  }
  
  /// Get difficulty progress as percentage (0.0 to 1.0)
  static double getDifficultyProgress(int difficultyLevel) {
    return math.min(difficultyLevel / maxDifficultyLevel, 1.0);
  }
  
  /// Get human-readable difficulty description
  static String getDifficultyDescription(int difficultyLevel) {
    if (difficultyLevel <= 2) {
      return 'Beginner';
    } else if (difficultyLevel <= 5) {
      return 'Easy';
    } else if (difficultyLevel <= 10) {
      return 'Medium';
    } else if (difficultyLevel <= 15) {
      return 'Hard';
    } else if (difficultyLevel < maxDifficultyLevel) {
      return 'Expert';
    } else {
      return 'Master';
    }
  }
  
  /// Calculate score needed for next difficulty level
  static int getScoreForNextLevel(int currentScore) {
    final currentLevel = calculateDifficultyLevel(currentScore);
    if (currentLevel >= maxDifficultyLevel) {
      return -1; // Already at max level
    }
    
    return currentLevel * pointsPerLevel;
  }
  
  /// Get difficulty statistics for debugging/UI
  static Map<String, dynamic> getDifficultyStats(int score) {
    final level = calculateDifficultyLevel(score);
    final speed = calculateGameSpeed(level);
    final spawnInterval = calculateSpawnInterval(level);
    final simultaneousObstacles = calculateSimultaneousObstacles(level);
    final progress = getDifficultyProgress(level);
    final description = getDifficultyDescription(level);
    final nextLevelScore = getScoreForNextLevel(score);
    
    return {
      'level': level,
      'speed': speed,
      'spawnInterval': spawnInterval,
      'simultaneousObstacles': simultaneousObstacles,
      'progress': progress,
      'description': description,
      'nextLevelScore': nextLevelScore,
      'isAtPlateau': isDifficultyAtPlateau(level),
    };
  }
}

/// Obstacle types available in the game
enum ObstacleType {
  digitalBarrier,
  laserGrid,
  floatingPlatform,
}