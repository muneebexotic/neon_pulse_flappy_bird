import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'dart:math' as math;

import '../../game/effects/particle_system.dart';
import '../../models/progression_path_models.dart';
import '../../models/achievement.dart';
import 'progression_particle_system.dart';

/// Example integration showing how to use ProgressionParticleSystem
/// with achievement progression events
class ParticleIntegrationExample {
  final ProgressionParticleSystem _progressionParticleSystem;
  
  ParticleIntegrationExample({
    required ParticleSystem baseParticleSystem,
  }) : _progressionParticleSystem = ProgressionParticleSystem(
         baseParticleSystem: baseParticleSystem,
         maxConfettiParticles: 150,
         maxPulseParticles: 30,
         celebrationDuration: 4.0,
       );

  /// Handle achievement unlock event
  void onAchievementUnlocked({
    required Achievement achievement,
    required Vector2 nodePosition,
  }) {
    // Get achievement category color
    final branchingLogic = BranchingLogic.defaultConfig();
    final branchConfig = branchingLogic.getBranchConfig(achievement.type);
    final color = branchConfig?.neonColor ?? const Color(0xFFFF1493);
    
    // Add unlock explosion effect
    _progressionParticleSystem.addNodeUnlockExplosion(
      position: nodePosition,
      primaryColor: color,
      intensity: 1.5, // Extra intensity for achievement unlocks
    );
    
    print('Achievement unlocked: ${achievement.title} at position $nodePosition');
  }

  /// Handle progress update on a path segment
  void onProgressUpdate({
    required PathSegment segment,
    required double previousCompletion,
  }) {
    // Only add pulse effect if progress actually increased
    if (segment.completionPercentage > previousCompletion) {
      final progressIncrease = segment.completionPercentage - previousCompletion;
      
      _progressionParticleSystem.addProgressPulse(
        segment: segment,
        intensity: progressIncrease * 2.0, // Scale intensity with progress increase
      );
      
      print('Progress updated on ${segment.id}: ${(segment.completionPercentage * 100).toStringAsFixed(1)}%');
    }
  }

  /// Handle 100% completion celebration
  void onFullCompletion({
    required Vector2 centerPosition,
    required Size screenSize,
  }) {
    // Add celebration confetti with all achievement colors
    final celebrationColors = [
      const Color(0xFFFF1493), // Hot pink
      const Color(0xFF9932CC), // Purple
      const Color(0xFF00FFFF), // Cyan
      const Color(0xFFFFFF00), // Yellow
      const Color(0xFF00FF00), // Green
      const Color(0xFFFF4500), // Orange-red
    ];
    
    _progressionParticleSystem.addCelebrationConfetti(
      centerPosition: centerPosition,
      screenSize: screenSize,
      colors: celebrationColors,
    );
    
    print('Full completion celebration triggered!');
  }

  /// Update particle system (call from main update loop)
  void update(double dt, List<PathSegment> pathSegments) {
    _progressionParticleSystem.update(dt, pathSegments);
  }

  /// Render particles (call from main render loop)
  void render(Canvas canvas) {
    _progressionParticleSystem.render(canvas);
  }

  /// Adjust quality based on performance
  void adjustQuality(double qualityScale) {
    _progressionParticleSystem.setQualityScale(qualityScale);
    print('Particle quality adjusted to: ${(qualityScale * 100).toStringAsFixed(0)}%');
  }

  /// Enable/disable effects based on user preferences
  void setEffectsEnabled({
    bool? celebrationEffects,
    bool? pulseEffects,
  }) {
    if (celebrationEffects != null) {
      _progressionParticleSystem.setCelebrationEffectsEnabled(celebrationEffects);
    }
    if (pulseEffects != null) {
      _progressionParticleSystem.setPulseEffectsEnabled(pulseEffects);
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return _progressionParticleSystem.getStats();
  }

  /// Get memory usage
  double getMemoryUsageKB() {
    return _progressionParticleSystem.getMemoryUsageKB();
  }

  /// Clear all particles (useful for screen transitions)
  void clearAllParticles() {
    _progressionParticleSystem.clearAllParticles();
  }

  /// Example usage in a progression screen
  static void exampleUsage() {
    // This is a conceptual example showing how to integrate the particle system
    
    // 1. Initialize with base particle system
    final baseParticleSystem = ParticleSystem();
    final integration = ParticleIntegrationExample(
      baseParticleSystem: baseParticleSystem,
    );
    
    // 2. Create sample path segments
    final pathSegments = [
      PathSegment(
        id: 'main_path',
        category: AchievementType.score,
        pathPoints: [
          Vector2(100, 100),
          Vector2(200, 150),
          Vector2(300, 200),
        ],
        neonColor: const Color(0xFFFF1493),
        width: 8.0,
        isMainPath: true,
        completionPercentage: 0.6,
        achievementIds: ['score_100', 'score_500'],
      ),
      PathSegment(
        id: 'skill_branch',
        category: AchievementType.pulseUsage,
        pathPoints: [
          Vector2(200, 150),
          Vector2(250, 100),
          Vector2(300, 80),
        ],
        neonColor: const Color(0xFFFFFF00),
        width: 5.0,
        isMainPath: false,
        completionPercentage: 0.3,
        achievementIds: ['pulse_master'],
      ),
    ];
    
    // 3. Simulate achievement unlock
    final unlockedAchievement = Achievement(
      id: 'score_100',
      title: 'First Century',
      description: 'Score 100 points in a single game',
      type: AchievementType.score,
      targetValue: 100,
      currentValue: 100,
      isUnlocked: true,
      unlockedAt: DateTime.now(),
      rewardType: RewardType.birdSkin,
      rewardId: 'neon_blue',
    );
    
    integration.onAchievementUnlocked(
      achievement: unlockedAchievement,
      nodePosition: Vector2(200, 150),
    );
    
    // 4. Simulate progress update
    final updatedSegment = pathSegments[0].copyWith(completionPercentage: 0.8);
    integration.onProgressUpdate(
      segment: updatedSegment,
      previousCompletion: 0.6,
    );
    
    // 5. Simulate full completion
    integration.onFullCompletion(
      centerPosition: Vector2(400, 300),
      screenSize: const Size(800, 600),
    );
    
    // 6. Update and render loop (would be called from main game loop)
    integration.update(0.016, pathSegments); // 60 FPS
    // integration.render(canvas); // Would be called in paint method
    
    // 7. Monitor performance
    final stats = integration.getPerformanceStats();
    print('Particle system stats: $stats');
    print('Memory usage: ${integration.getMemoryUsageKB().toStringAsFixed(2)} KB');
  }
}

/// Helper class for managing particle effects in achievement screens
class AchievementParticleManager {
  final ProgressionParticleSystem _particleSystem;
  final Map<String, double> _lastCompletionPercentages = {};
  
  AchievementParticleManager(this._particleSystem);
  
  /// Process achievement data changes and trigger appropriate effects
  void processAchievementUpdates({
    required List<Achievement> achievements,
    required List<PathSegment> pathSegments,
    required Map<String, Vector2> nodePositions,
    required Size screenSize,
  }) {
    // Check for newly unlocked achievements
    for (final achievement in achievements) {
      if (achievement.isUnlocked && achievement.unlockedAt != null) {
        final timeSinceUnlock = DateTime.now().difference(achievement.unlockedAt!);
        
        // Only trigger effect for recently unlocked achievements (within last 5 seconds)
        if (timeSinceUnlock.inSeconds < 5) {
          final nodePosition = nodePositions[achievement.id];
          if (nodePosition != null) {
            _triggerUnlockEffect(achievement, nodePosition);
          }
        }
      }
    }
    
    // Check for progress updates on path segments
    for (final segment in pathSegments) {
      final lastCompletion = _lastCompletionPercentages[segment.id] ?? 0.0;
      if (segment.completionPercentage > lastCompletion) {
        _triggerProgressEffect(segment, lastCompletion);
      }
      _lastCompletionPercentages[segment.id] = segment.completionPercentage;
    }
    
    // Check for full completion
    final totalCompletion = _calculateTotalCompletion(pathSegments);
    if (totalCompletion >= 1.0) {
      _triggerCelebrationEffect(screenSize);
    }
  }
  
  void _triggerUnlockEffect(Achievement achievement, Vector2 position) {
    final branchingLogic = BranchingLogic.defaultConfig();
    final branchConfig = branchingLogic.getBranchConfig(achievement.type);
    final color = branchConfig?.neonColor ?? const Color(0xFFFF1493);
    
    _particleSystem.addNodeUnlockExplosion(
      position: position,
      primaryColor: color,
      intensity: 1.2,
    );
  }
  
  void _triggerProgressEffect(PathSegment segment, double previousCompletion) {
    final progressIncrease = segment.completionPercentage - previousCompletion;
    _particleSystem.addProgressPulse(
      segment: segment,
      intensity: math.min(progressIncrease * 3.0, 2.0),
    );
  }
  
  void _triggerCelebrationEffect(Size screenSize) {
    _particleSystem.addCelebrationConfetti(
      centerPosition: Vector2(screenSize.width / 2, screenSize.height / 2),
      screenSize: screenSize,
    );
  }
  
  double _calculateTotalCompletion(List<PathSegment> segments) {
    if (segments.isEmpty) return 0.0;
    
    final totalCompletion = segments
        .map((s) => s.completionPercentage)
        .reduce((a, b) => a + b);
    
    return totalCompletion / segments.length;
  }
}