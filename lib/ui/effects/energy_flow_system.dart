import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/progression_path_models.dart';
import '../../game/effects/particle_system.dart';
import '../painters/path_renderer.dart';

/// Energy flow particle for path-based effects
class EnergyFlowParticle {
  final Vector2 position;
  final Vector2 velocity;
  final Color color;
  final double size;
  final double alpha;
  final double life;
  final double maxLife;
  final String pathId;

  const EnergyFlowParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.alpha,
    required this.life,
    required this.maxLife,
    required this.pathId,
  });

  /// Create a copy with updated properties
  EnergyFlowParticle copyWith({
    Vector2? position,
    Vector2? velocity,
    double? alpha,
    double? life,
  }) {
    return EnergyFlowParticle(
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      color: color,
      size: size,
      alpha: alpha ?? this.alpha,
      life: life ?? this.life,
      maxLife: maxLife,
      pathId: pathId,
    );
  }

  /// Check if particle is still alive
  bool get isAlive => life > 0;
}

/// System for managing energy flow particles along progression paths
class EnergyFlowSystem {
  final ParticleSystem _particleSystem;
  final List<EnergyFlowParticle> _energyParticles = [];
  final Map<String, PathFlowState> _pathFlowStates = {};
  
  // Configuration
  final int maxEnergyParticles;
  final double particleSpawnRate;
  final double baseParticleSpeed;
  final double particleLifetime;
  
  // Animation state
  double _lastSpawnTime = 0.0;
  double _currentTime = 0.0;
  
  // Performance settings
  bool _enableEnergyFlow = true;
  double _qualityScale = 1.0;

  EnergyFlowSystem({
    required ParticleSystem particleSystem,
    this.maxEnergyParticles = 50,
    this.particleSpawnRate = 2.0, // particles per second
    this.baseParticleSpeed = 80.0,
    this.particleLifetime = 3.0,
  }) : _particleSystem = particleSystem;

  /// Update energy flow system
  void update(double dt, List<PathSegment> pathSegments) {
    if (!_enableEnergyFlow) return;
    
    _currentTime += dt;
    
    // Update existing particles
    _updateEnergyParticles(dt);
    
    // Spawn new particles on completed paths
    _spawnEnergyParticles(dt, pathSegments);
    
    // Update path flow states
    _updatePathFlowStates(pathSegments);
    
    // Clean up dead particles
    _cleanupDeadParticles();
  }

  /// Update existing energy particles
  void _updateEnergyParticles(double dt) {
    for (int i = _energyParticles.length - 1; i >= 0; i--) {
      final particle = _energyParticles[i];
      final updatedParticle = _updateEnergyParticle(particle, dt);
      
      if (updatedParticle.isAlive) {
        _energyParticles[i] = updatedParticle;
      } else {
        _energyParticles.removeAt(i);
      }
    }
  }

  /// Update individual energy particle
  EnergyFlowParticle _updateEnergyParticle(EnergyFlowParticle particle, double dt) {
    // Update position
    final newPosition = particle.position + (particle.velocity * dt);
    
    // Update life
    final newLife = particle.life - dt;
    
    // Update alpha based on life
    final lifeRatio = newLife / particle.maxLife;
    final newAlpha = _calculateParticleAlpha(lifeRatio);
    
    // Add slight random movement for organic feel
    final randomOffset = Vector2(
      (math.Random().nextDouble() - 0.5) * 10.0 * dt,
      (math.Random().nextDouble() - 0.5) * 10.0 * dt,
    );
    
    return particle.copyWith(
      position: newPosition + randomOffset,
      alpha: newAlpha,
      life: newLife,
    );
  }

  /// Calculate particle alpha based on life ratio
  double _calculateParticleAlpha(double lifeRatio) {
    // Fade in quickly, stay bright, then fade out
    if (lifeRatio > 0.8) {
      // Fade in
      return (1.0 - lifeRatio) * 5.0;
    } else if (lifeRatio > 0.2) {
      // Stay bright
      return 1.0;
    } else {
      // Fade out
      return lifeRatio * 5.0;
    }
  }

  /// Spawn new energy particles on completed paths
  void _spawnEnergyParticles(double dt, List<PathSegment> pathSegments) {
    if (_energyParticles.length >= maxEnergyParticles) return;
    
    final timeSinceLastSpawn = _currentTime - _lastSpawnTime;
    final spawnInterval = 1.0 / (particleSpawnRate * _qualityScale);
    
    if (timeSinceLastSpawn < spawnInterval) return;
    
    // Spawn particles on completed path segments
    for (final segment in pathSegments) {
      if (segment.completionPercentage > 0) {
        _spawnParticlesOnSegment(segment);
      }
    }
    
    _lastSpawnTime = _currentTime;
  }

  /// Spawn particles on a specific path segment
  void _spawnParticlesOnSegment(PathSegment segment) {
    if (_energyParticles.length >= maxEnergyParticles) return;
    
    final flowState = _getOrCreateFlowState(segment.id);
    final particleCount = _calculateParticleCount(segment);
    
    for (int i = 0; i < particleCount; i++) {
      if (_energyParticles.length >= maxEnergyParticles) break;
      
      final particle = _createEnergyParticle(segment, flowState);
      if (particle != null) {
        _energyParticles.add(particle);
      }
    }
  }

  /// Calculate number of particles to spawn based on segment properties
  int _calculateParticleCount(PathSegment segment) {
    final baseCount = segment.isMainPath ? 2 : 1;
    final completionFactor = segment.completionPercentage;
    final qualityFactor = _qualityScale;
    
    return (baseCount * completionFactor * qualityFactor).round().clamp(0, 3);
  }

  /// Create a new energy particle for a path segment
  EnergyFlowParticle? _createEnergyParticle(PathSegment segment, PathFlowState flowState) {
    if (segment.pathPoints.length < 2) return null;
    
    // Choose random position along completed portion of path
    final spawnProgress = math.Random().nextDouble() * segment.completionPercentage;
    final spawnPosition = segment.getPointAtPercentage(spawnProgress);
    
    // Calculate velocity along path direction
    final velocity = _calculateParticleVelocity(segment, spawnProgress);
    
    // Create particle with segment color
    return EnergyFlowParticle(
      position: spawnPosition,
      velocity: velocity,
      color: segment.neonColor,
      size: _calculateParticleSize(segment),
      alpha: 0.0, // Will fade in
      life: particleLifetime * _qualityScale,
      maxLife: particleLifetime * _qualityScale,
      pathId: segment.id,
    );
  }

  /// Calculate particle velocity along path
  Vector2 _calculateParticleVelocity(PathSegment segment, double progress) {
    // Get direction from current position to next position
    final currentPoint = segment.getPointAtPercentage(progress);
    final nextProgress = math.min(progress + 0.1, segment.completionPercentage);
    final nextPoint = segment.getPointAtPercentage(nextProgress);
    
    final direction = (nextPoint - currentPoint).normalized();
    final speed = baseParticleSpeed * (segment.isMainPath ? 1.2 : 0.8);
    
    // Add some random variation
    final randomFactor = 0.8 + math.Random().nextDouble() * 0.4;
    
    return direction * speed * randomFactor;
  }

  /// Calculate particle size based on segment properties
  double _calculateParticleSize(PathSegment segment) {
    final baseSize = segment.isMainPath ? 3.0 : 2.0;
    final widthFactor = (segment.width / 8.0).clamp(0.5, 2.0);
    return baseSize * widthFactor * _qualityScale;
  }

  /// Get or create flow state for a path segment
  PathFlowState _getOrCreateFlowState(String pathId) {
    return _pathFlowStates.putIfAbsent(pathId, () => PathFlowState(pathId: pathId));
  }

  /// Update path flow states
  void _updatePathFlowStates(List<PathSegment> pathSegments) {
    // Remove states for segments that no longer exist
    final activePathIds = pathSegments.map((s) => s.id).toSet();
    _pathFlowStates.removeWhere((id, state) => !activePathIds.contains(id));
    
    // Update existing states
    for (final segment in pathSegments) {
      final state = _getOrCreateFlowState(segment.id);
      state.update(segment);
    }
  }

  /// Clean up dead particles
  void _cleanupDeadParticles() {
    _energyParticles.removeWhere((particle) => !particle.isAlive);
  }

  /// Add explosion effect at specific position
  void addExplosionEffect({
    required Vector2 position,
    required Color color,
    int particleCount = 15,
    double speed = 120.0,
  }) {
    // Use existing particle system for explosion
    _particleSystem.addExplosion(
      position: position,
      color: color,
      particleCount: (particleCount * _qualityScale).round(),
      speed: speed,
      life: 1.2,
    );
    
    // Add energy particles for extra effect
    for (int i = 0; i < (particleCount * 0.3 * _qualityScale).round(); i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final velocity = Vector2(
        math.cos(angle) * speed * 0.7,
        math.sin(angle) * speed * 0.7,
      );
      
      final energyParticle = EnergyFlowParticle(
        position: position.clone(),
        velocity: velocity,
        color: color,
        size: 4.0 * _qualityScale,
        alpha: 1.0,
        life: 1.5,
        maxLife: 1.5,
        pathId: 'explosion_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      if (_energyParticles.length < maxEnergyParticles) {
        _energyParticles.add(energyParticle);
      }
    }
  }

  /// Add pulse effect along a path segment
  void addPulseEffect(PathSegment segment, {double intensity = 1.0}) {
    if (segment.pathPoints.length < 2) return;
    
    final pulseCount = (5 * intensity * _qualityScale).round();
    
    for (int i = 0; i < pulseCount; i++) {
      final progress = i / pulseCount * segment.completionPercentage;
      final position = segment.getPointAtPercentage(progress);
      
      // Create pulse particle
      final pulseParticle = EnergyFlowParticle(
        position: position,
        velocity: Vector2.zero(),
        color: segment.neonColor.withOpacity(0.8),
        size: 6.0 * _qualityScale,
        alpha: 1.0,
        life: 0.8,
        maxLife: 0.8,
        pathId: 'pulse_${segment.id}_$i',
      );
      
      if (_energyParticles.length < maxEnergyParticles) {
        _energyParticles.add(pulseParticle);
      }
    }
  }

  /// Get current energy particles for rendering
  List<EnergyFlowParticle> get energyParticles => List.unmodifiable(_energyParticles);

  /// Set quality scale for performance adjustment
  void setQualityScale(double scale) {
    _qualityScale = scale.clamp(0.1, 1.0);
  }

  /// Enable or disable energy flow
  void setEnergyFlowEnabled(bool enabled) {
    _enableEnergyFlow = enabled;
    if (!enabled) {
      _energyParticles.clear();
    }
  }

  /// Clear all energy particles
  void clearAllParticles() {
    _energyParticles.clear();
    _pathFlowStates.clear();
  }

  /// Get system statistics
  Map<String, dynamic> getStats() {
    return {
      'energyParticles': _energyParticles.length,
      'maxEnergyParticles': maxEnergyParticles,
      'pathFlowStates': _pathFlowStates.length,
      'qualityScale': _qualityScale,
      'enableEnergyFlow': _enableEnergyFlow,
      'particleSpawnRate': particleSpawnRate,
      'utilization': (_energyParticles.length / maxEnergyParticles * 100).toStringAsFixed(1) + '%',
    };
  }
}

/// State tracking for energy flow on a specific path
class PathFlowState {
  final String pathId;
  double lastCompletionPercentage = 0.0;
  double flowIntensity = 1.0;
  double lastUpdateTime = 0.0;
  
  PathFlowState({required this.pathId});

  /// Update state based on path segment
  void update(PathSegment segment) {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    // Detect completion changes
    if (segment.completionPercentage > lastCompletionPercentage) {
      // Path progress increased - boost flow intensity
      flowIntensity = math.min(2.0, flowIntensity + 0.5);
    }
    
    // Gradually reduce flow intensity over time
    final timeDelta = currentTime - lastUpdateTime;
    flowIntensity = math.max(0.5, flowIntensity - timeDelta * 0.2);
    
    lastCompletionPercentage = segment.completionPercentage;
    lastUpdateTime = currentTime;
  }
}