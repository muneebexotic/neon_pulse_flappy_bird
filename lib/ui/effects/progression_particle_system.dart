import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../game/effects/particle_system.dart';
import '../../models/progression_path_models.dart';
import 'energy_flow_system.dart';

/// Enhanced particle system specifically for progression path effects
class ProgressionParticleSystem {
  final ParticleSystem _baseParticleSystem;
  final EnergyFlowSystem _energyFlowSystem;
  
  // Celebration effects
  final List<ConfettiParticle> _confettiParticles = [];
  final List<PulseParticle> _pulseParticles = [];
  
  // Configuration
  final int maxConfettiParticles;
  final int maxPulseParticles;
  final double celebrationDuration;
  
  // Performance tracking
  double _qualityScale = 1.0;
  bool _enableCelebrationEffects = true;
  bool _enablePulseEffects = true;

  ProgressionParticleSystem({
    required ParticleSystem baseParticleSystem,
    this.maxConfettiParticles = 100,
    this.maxPulseParticles = 20,
    this.celebrationDuration = 5.0,
  }) : _baseParticleSystem = baseParticleSystem,
       _energyFlowSystem = EnergyFlowSystem(particleSystem: baseParticleSystem);

  /// Update all progression particle effects
  void update(double dt, List<PathSegment> pathSegments) {
    // Update energy flow system
    _energyFlowSystem.update(dt, pathSegments);
    
    // Update celebration particles
    _updateConfettiParticles(dt);
    _updatePulseParticles(dt);
    
    // Clean up dead particles
    _cleanupDeadParticles();
  }

  /// Update confetti particles
  void _updateConfettiParticles(double dt) {
    for (int i = _confettiParticles.length - 1; i >= 0; i--) {
      final particle = _confettiParticles[i];
      final updatedParticle = _updateConfettiParticle(particle, dt);
      
      if (updatedParticle.isAlive) {
        _confettiParticles[i] = updatedParticle;
      } else {
        _confettiParticles.removeAt(i);
      }
    }
  }

  /// Update individual confetti particle
  ConfettiParticle _updateConfettiParticle(ConfettiParticle particle, double dt) {
    // Apply gravity
    final newVelocity = particle.velocity + Vector2(0, 300.0 * dt);
    
    // Apply air resistance
    final airResistance = newVelocity * -0.02;
    final finalVelocity = newVelocity + airResistance;
    
    // Update position
    final newPosition = particle.position + (finalVelocity * dt);
    
    // Update rotation
    final newRotation = particle.rotation + particle.rotationSpeed * dt;
    
    // Update life
    final newLife = particle.life - dt;
    final lifeRatio = newLife / particle.maxLife;
    
    // Update alpha with fade out
    final newAlpha = lifeRatio.clamp(0.0, 1.0);
    
    return particle.copyWith(
      position: newPosition,
      velocity: finalVelocity,
      rotation: newRotation,
      alpha: newAlpha,
      life: newLife,
    );
  }

  /// Update pulse particles
  void _updatePulseParticles(double dt) {
    for (int i = _pulseParticles.length - 1; i >= 0; i--) {
      final particle = _pulseParticles[i];
      final updatedParticle = _updatePulseParticle(particle, dt);
      
      if (updatedParticle.isAlive) {
        _pulseParticles[i] = updatedParticle;
      } else {
        _pulseParticles.removeAt(i);
      }
    }
  }

  /// Update individual pulse particle
  PulseParticle _updatePulseParticle(PulseParticle particle, double dt) {
    // Update life
    final newLife = particle.life - dt;
    final lifeRatio = newLife / particle.maxLife;
    
    // Calculate pulse size (grows then shrinks)
    final pulsePhase = 1.0 - lifeRatio;
    final newSize = particle.baseSize * (1.0 + math.sin(pulsePhase * math.pi * 2) * 0.5);
    
    // Calculate alpha (pulse effect)
    final newAlpha = (math.sin(pulsePhase * math.pi * 4) * 0.5 + 0.5) * lifeRatio;
    
    return particle.copyWith(
      size: newSize,
      alpha: newAlpha,
      life: newLife,
    );
  }

  /// Clean up dead particles
  void _cleanupDeadParticles() {
    _confettiParticles.removeWhere((particle) => !particle.isAlive);
    _pulseParticles.removeWhere((particle) => !particle.isAlive);
  }

  /// Add node unlock explosion effect
  void addNodeUnlockExplosion({
    required Vector2 position,
    required Color primaryColor,
    double intensity = 1.0,
  }) {
    // Base explosion using existing particle system
    _baseParticleSystem.addExplosion(
      position: position,
      color: primaryColor,
      particleCount: (20 * intensity * _qualityScale).round(),
      speed: 150.0,
      life: 1.5,
    );
    
    // Add energy flow explosion
    _energyFlowSystem.addExplosionEffect(
      position: position,
      color: primaryColor,
      particleCount: (15 * intensity * _qualityScale).round(),
      speed: 120.0,
    );
    
    // Add sparks for extra visual impact
    _baseParticleSystem.addSparks(
      position: position,
      color: primaryColor.withOpacity(0.8),
      sparkCount: (10 * intensity * _qualityScale).round(),
      speed: 100.0,
      life: 2.0,
    );
    
    // Add pulse rings
    _addPulseRings(position, primaryColor, intensity);
  }

  /// Add pulse rings around a position
  void _addPulseRings(Vector2 position, Color color, double intensity) {
    if (!_enablePulseEffects) return;
    
    final ringCount = (3 * intensity * _qualityScale).round();
    
    for (int i = 0; i < ringCount; i++) {
      if (_pulseParticles.length >= maxPulseParticles) break;
      
      final delay = i * 0.2; // Stagger the rings
      final baseSize = 20.0 + (i * 10.0);
      
      final pulseParticle = PulseParticle(
        position: position.clone(),
        baseSize: baseSize * _qualityScale,
        color: color.withOpacity(0.6),
        life: 1.5 + delay,
        maxLife: 1.5 + delay,
        delay: delay,
      );
      
      _pulseParticles.add(pulseParticle);
    }
  }

  /// Add progress pulse animation along a path segment
  void addProgressPulse({
    required PathSegment segment,
    double intensity = 1.0,
  }) {
    if (!_enablePulseEffects) return;
    
    // Use energy flow system for path-based pulse
    _energyFlowSystem.addPulseEffect(segment, intensity: intensity);
    
    // Add additional pulse particles at key points
    final pulseCount = (segment.pathPoints.length * 0.5 * intensity * _qualityScale).round();
    
    for (int i = 0; i < pulseCount; i++) {
      if (_pulseParticles.length >= maxPulseParticles) break;
      
      final progress = i / pulseCount * segment.completionPercentage;
      final position = segment.getPointAtPercentage(progress);
      
      final pulseParticle = PulseParticle(
        position: position,
        baseSize: 15.0 * _qualityScale,
        color: segment.neonColor.withOpacity(0.7),
        life: 1.0,
        maxLife: 1.0,
        delay: i * 0.1,
      );
      
      _pulseParticles.add(pulseParticle);
    }
  }

  /// Add celebration confetti effect for 100% completion
  void addCelebrationConfetti({
    required Vector2 centerPosition,
    required Size screenSize,
    List<Color>? colors,
  }) {
    if (!_enableCelebrationEffects) return;
    
    final celebrationColors = colors ?? [
      const Color(0xFFFF1493), // Hot pink
      const Color(0xFF9932CC), // Purple
      const Color(0xFF00FFFF), // Cyan
      const Color(0xFFFFFF00), // Yellow
      const Color(0xFF00FF00), // Green
      const Color(0xFFFF4500), // Orange-red
    ];
    
    final confettiCount = (80 * _qualityScale).round();
    
    for (int i = 0; i < confettiCount; i++) {
      if (_confettiParticles.length >= maxConfettiParticles) break;
      
      // Random spawn position near top of screen
      final spawnX = centerPosition.x + (math.Random().nextDouble() - 0.5) * screenSize.width * 0.8;
      final spawnY = centerPosition.y - screenSize.height * 0.3 - math.Random().nextDouble() * 100;
      
      // Random initial velocity (upward and outward)
      final angle = (math.Random().nextDouble() - 0.5) * math.pi * 0.8; // -72° to 72°
      final speed = 200.0 + math.Random().nextDouble() * 150.0;
      final velocity = Vector2(
        math.sin(angle) * speed,
        -(math.cos(angle).abs()) * speed, // Always upward initially
      );
      
      // Random confetti properties
      final color = celebrationColors[math.Random().nextInt(celebrationColors.length)];
      final size = 3.0 + math.Random().nextDouble() * 4.0;
      final rotationSpeed = (math.Random().nextDouble() - 0.5) * 10.0;
      final life = celebrationDuration + math.Random().nextDouble() * 2.0;
      
      final confetti = ConfettiParticle(
        position: Vector2(spawnX, spawnY),
        velocity: velocity,
        color: color,
        size: size * _qualityScale,
        rotation: math.Random().nextDouble() * 2 * math.pi,
        rotationSpeed: rotationSpeed,
        alpha: 1.0,
        life: life,
        maxLife: life,
        shape: math.Random().nextBool() ? ConfettiShape.rectangle : ConfettiShape.circle,
      );
      
      _confettiParticles.add(confetti);
    }
    
    // Add some extra sparkles using base particle system
    _baseParticleSystem.addSparks(
      position: centerPosition,
      color: celebrationColors[math.Random().nextInt(celebrationColors.length)],
      sparkCount: (30 * _qualityScale).round(),
      speed: 180.0,
      life: 3.0,
    );
  }

  /// Render all progression particles
  void render(Canvas canvas) {
    // Render confetti particles
    for (final particle in _confettiParticles) {
      _renderConfettiParticle(canvas, particle);
    }
    
    // Render pulse particles
    for (final particle in _pulseParticles) {
      _renderPulseParticle(canvas, particle);
    }
  }

  /// Render individual confetti particle
  void _renderConfettiParticle(Canvas canvas, ConfettiParticle particle) {
    if (!particle.isAlive || particle.alpha <= 0) return;
    
    canvas.save();
    canvas.translate(particle.position.x, particle.position.y);
    canvas.rotate(particle.rotation);
    
    final paint = Paint()
      ..color = particle.color.withOpacity(particle.alpha)
      ..style = PaintingStyle.fill;
    
    switch (particle.shape) {
      case ConfettiShape.rectangle:
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size * 0.6),
          paint,
        );
        break;
      case ConfettiShape.circle:
        canvas.drawCircle(Offset.zero, particle.size * 0.5, paint);
        break;
    }
    
    canvas.restore();
  }

  /// Render individual pulse particle
  void _renderPulseParticle(Canvas canvas, PulseParticle particle) {
    if (!particle.isAlive || particle.alpha <= 0 || particle.isDelayed) return;
    
    final paint = Paint()
      ..color = particle.color.withOpacity(particle.alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(
      Offset(particle.position.x, particle.position.y),
      particle.size,
      paint,
    );
  }

  /// Set quality scale for performance adjustment
  void setQualityScale(double scale) {
    _qualityScale = scale.clamp(0.1, 1.0);
    _energyFlowSystem.setQualityScale(scale);
    _baseParticleSystem.setQuality(scale);
  }

  /// Enable or disable celebration effects
  void setCelebrationEffectsEnabled(bool enabled) {
    _enableCelebrationEffects = enabled;
    if (!enabled) {
      _confettiParticles.clear();
    }
  }

  /// Enable or disable pulse effects
  void setPulseEffectsEnabled(bool enabled) {
    _enablePulseEffects = enabled;
    if (!enabled) {
      _pulseParticles.clear();
    }
  }

  /// Clear all progression particles
  void clearAllParticles() {
    _confettiParticles.clear();
    _pulseParticles.clear();
    _energyFlowSystem.clearAllParticles();
  }

  /// Get comprehensive statistics
  Map<String, dynamic> getStats() {
    final baseStats = _baseParticleSystem.getStats();
    final energyStats = _energyFlowSystem.getStats();
    
    return {
      'baseParticleSystem': baseStats,
      'energyFlowSystem': energyStats,
      'confettiParticles': _confettiParticles.length,
      'pulseParticles': _pulseParticles.length,
      'maxConfettiParticles': maxConfettiParticles,
      'maxPulseParticles': maxPulseParticles,
      'qualityScale': _qualityScale,
      'celebrationEffectsEnabled': _enableCelebrationEffects,
      'pulseEffectsEnabled': _enablePulseEffects,
      'totalActiveParticles': _confettiParticles.length + _pulseParticles.length + 
                             (energyStats['energyParticles'] as int),
    };
  }

  /// Get memory usage estimate in KB
  double getMemoryUsageKB() {
    final baseMemory = _baseParticleSystem.getMemoryUsageKB();
    final confettiMemory = _confettiParticles.length * 0.15; // ~150 bytes per confetti
    final pulseMemory = _pulseParticles.length * 0.1; // ~100 bytes per pulse
    return baseMemory + confettiMemory + pulseMemory;
  }

  /// Access to energy flow system for direct control
  EnergyFlowSystem get energyFlowSystem => _energyFlowSystem;
  
  /// Access to base particle system for direct control
  ParticleSystem get baseParticleSystem => _baseParticleSystem;
}

/// Confetti particle for celebration effects
class ConfettiParticle {
  final Vector2 position;
  final Vector2 velocity;
  final Color color;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final double alpha;
  final double life;
  final double maxLife;
  final ConfettiShape shape;

  const ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.alpha,
    required this.life,
    required this.maxLife,
    required this.shape,
  });

  /// Create a copy with updated properties
  ConfettiParticle copyWith({
    Vector2? position,
    Vector2? velocity,
    double? rotation,
    double? alpha,
    double? life,
  }) {
    return ConfettiParticle(
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      color: color,
      size: size,
      rotation: rotation ?? this.rotation,
      rotationSpeed: rotationSpeed,
      alpha: alpha ?? this.alpha,
      life: life ?? this.life,
      maxLife: maxLife,
      shape: shape,
    );
  }

  /// Check if particle is still alive
  bool get isAlive => life > 0;
}

/// Pulse particle for progress and unlock effects
class PulseParticle {
  final Vector2 position;
  final double baseSize;
  final Color color;
  final double size;
  final double alpha;
  final double life;
  final double maxLife;
  final double delay;

  const PulseParticle({
    required this.position,
    required this.baseSize,
    required this.color,
    required this.life,
    required this.maxLife,
    this.size = 0.0,
    this.alpha = 1.0,
    this.delay = 0.0,
  });

  /// Create a copy with updated properties
  PulseParticle copyWith({
    double? size,
    double? alpha,
    double? life,
  }) {
    return PulseParticle(
      position: position,
      baseSize: baseSize,
      color: color,
      size: size ?? this.size,
      alpha: alpha ?? this.alpha,
      life: life ?? this.life,
      maxLife: maxLife,
      delay: delay,
    );
  }

  /// Check if particle is still alive
  bool get isAlive => life > 0;
  
  /// Check if particle is still in delay phase
  bool get isDelayed => (maxLife - life) < delay;
}

/// Shape options for confetti particles
enum ConfettiShape {
  rectangle,
  circle,
}