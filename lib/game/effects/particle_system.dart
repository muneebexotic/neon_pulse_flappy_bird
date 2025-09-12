import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'skin_trail_effects.dart';

/// Base particle class for neon effects
class NeonParticle {
  Vector2 position;
  Vector2 velocity;
  Color color;
  double life;
  double maxLife;
  double size;
  double alpha;
  ParticleType type;

  NeonParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.maxLife,
    this.size = 2.0,
    this.type = ParticleType.trail,
  }) : life = maxLife, alpha = 1.0;

  /// Update particle physics and lifecycle
  void update(double dt) {
    // Update position
    position += velocity * dt;
    
    // Update life
    life -= dt;
    
    // Update alpha based on remaining life
    alpha = (life / maxLife).clamp(0.0, 1.0);
    
    // Apply particle-specific updates
    switch (type) {
      case ParticleType.trail:
        _updateTrail(dt);
        break;
      case ParticleType.explosion:
        _updateExplosion(dt);
        break;
      case ParticleType.spark:
        _updateSpark(dt);
        break;
      case ParticleType.pulse:
        _updatePulse(dt);
        break;
      case ParticleType.fire:
        _updateFire(dt);
        break;
      case ParticleType.glow:
        _updateGlow(dt);
        break;
      case ParticleType.energy:
        _updateEnergy(dt);
        break;
    }
  }

  void _updateTrail(double dt) {
    // Trail particles fade and slow down over time
    velocity *= 0.98;
    size *= 0.995;
  }

  void _updateExplosion(double dt) {
    // Explosion particles expand and fade quickly
    velocity *= 0.95;
    size += dt * 10.0;
  }

  void _updateSpark(double dt) {
    // Spark particles have gravity and fade
    velocity.y += 200.0 * dt; // gravity
    velocity *= 0.99;
  }

  void _updatePulse(double dt) {
    // Pulse particles expand and fade
    velocity *= 0.96;
    size += dt * 15.0;
  }

  void _updateFire(double dt) {
    // Fire particles rise and flicker
    velocity.y -= 50.0 * dt; // upward drift
    velocity *= 0.97;
    size *= 0.998;
  }

  void _updateGlow(double dt) {
    // Glow particles are stable but fade slowly
    velocity *= 0.99;
    size += dt * 2.0;
  }

  void _updateEnergy(double dt) {
    // Energy particles have erratic movement
    velocity.x += (math.Random().nextDouble() - 0.5) * 20.0 * dt;
    velocity.y += (math.Random().nextDouble() - 0.5) * 20.0 * dt;
    velocity *= 0.98;
  }

  /// Check if particle is still alive
  bool get isAlive => life > 0;

  /// Render the particle
  void render(Canvas canvas) {
    if (!isAlive) return;

    final paint = Paint()
      ..color = color.withOpacity(alpha)
      ..style = PaintingStyle.fill;

    // Add glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(alpha * 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, size * 2);

    // Draw glow
    canvas.drawCircle(Offset(position.x, position.y), size * 2, glowPaint);
    
    // Draw core particle
    canvas.drawCircle(Offset(position.x, position.y), size, paint);
  }
}

/// Particle pool for performance optimization
class ParticlePool {
  final List<NeonParticle> _availableParticles = [];
  final int maxPoolSize;

  ParticlePool({this.maxPoolSize = 100});

  /// Get a particle from the pool or create a new one
  NeonParticle getParticle({
    required Vector2 position,
    required Vector2 velocity,
    required Color color,
    required double maxLife,
    double size = 2.0,
    ParticleType type = ParticleType.trail,
  }) {
    NeonParticle particle;
    
    if (_availableParticles.isNotEmpty) {
      // Reuse existing particle
      particle = _availableParticles.removeLast();
      particle.position = position.clone();
      particle.velocity = velocity.clone();
      particle.color = color;
      particle.life = maxLife;
      particle.maxLife = maxLife;
      particle.size = size;
      particle.alpha = 1.0;
      particle.type = type;
    } else {
      // Create new particle
      particle = NeonParticle(
        position: position.clone(),
        velocity: velocity.clone(),
        color: color,
        maxLife: maxLife,
        size: size,
        type: type,
      );
    }
    
    return particle;
  }

  /// Return a particle to the pool
  void returnParticle(NeonParticle particle) {
    if (_availableParticles.length < maxPoolSize) {
      _availableParticles.add(particle);
    }
  }

  /// Get current pool statistics
  int get availableCount => _availableParticles.length;
  int get usedCount => maxPoolSize - _availableParticles.length;
}

/// Main particle system component
class ParticleSystem extends Component {
  final List<NeonParticle> _activeParticles = [];
  final ParticlePool _particlePool = ParticlePool(maxPoolSize: 200);
  
  // Performance settings - reduced for better performance
  int maxParticles = 50;
  bool qualityAdjustment = true;
  double currentQuality = 0.7;

  @override
  void update(double dt) {
    super.update(dt);
    
    // Update all active particles
    for (int i = _activeParticles.length - 1; i >= 0; i--) {
      final particle = _activeParticles[i];
      particle.update(dt);
      
      // Remove dead particles and return to pool
      if (!particle.isAlive) {
        _activeParticles.removeAt(i);
        _particlePool.returnParticle(particle);
      }
    }
    
    // Adjust quality based on performance if enabled
    if (qualityAdjustment) {
      _adjustQuality();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Render all active particles
    for (final particle in _activeParticles) {
      particle.render(canvas);
    }
  }

  /// Add a trail particle
  void addTrailParticle({
    required Vector2 position,
    required Color color,
    Vector2? velocity,
    double size = 2.0,
    double life = 1.0,
  }) {
    if (_activeParticles.length >= maxParticles) return;
    
    final particle = _particlePool.getParticle(
      position: position,
      velocity: velocity ?? Vector2(
        (math.Random().nextDouble() - 0.5) * 50,
        (math.Random().nextDouble() - 0.5) * 50,
      ),
      color: color,
      maxLife: life * currentQuality,
      size: size * currentQuality,
      type: ParticleType.trail,
    );
    
    _activeParticles.add(particle);
  }

  /// Add explosion particles
  void addExplosion({
    required Vector2 position,
    required Color color,
    int particleCount = 10,
    double speed = 100.0,
    double life = 0.8,
  }) {
    final adjustedCount = (particleCount * currentQuality).round();
    
    for (int i = 0; i < adjustedCount && _activeParticles.length < maxParticles; i++) {
      final angle = (i / adjustedCount) * 2 * math.pi;
      final velocity = Vector2(
        math.cos(angle) * speed,
        math.sin(angle) * speed,
      );
      
      final particle = _particlePool.getParticle(
        position: position,
        velocity: velocity,
        color: color,
        maxLife: life,
        size: 3.0 * currentQuality,
        type: ParticleType.explosion,
      );
      
      _activeParticles.add(particle);
    }
  }

  /// Add spark particles
  void addSparks({
    required Vector2 position,
    required Color color,
    int sparkCount = 5,
    double speed = 80.0,
    double life = 1.2,
  }) {
    final adjustedCount = (sparkCount * currentQuality).round();
    
    for (int i = 0; i < adjustedCount && _activeParticles.length < maxParticles; i++) {
      final angle = math.Random().nextDouble() * 2 * math.pi;
      final velocity = Vector2(
        math.cos(angle) * speed * (0.5 + math.Random().nextDouble() * 0.5),
        math.sin(angle) * speed * (0.5 + math.Random().nextDouble() * 0.5),
      );
      
      final particle = _particlePool.getParticle(
        position: position,
        velocity: velocity,
        color: color,
        maxLife: life,
        size: 1.5 * currentQuality,
        type: ParticleType.spark,
      );
      
      _activeParticles.add(particle);
    }
  }

  /// Adjust quality based on performance
  void _adjustQuality() {
    final particleRatio = _activeParticles.length / maxParticles;
    
    if (particleRatio > 0.9) {
      // High particle count, reduce quality
      currentQuality = math.max(0.3, currentQuality - 0.01);
    } else if (particleRatio < 0.5) {
      // Low particle count, can increase quality
      currentQuality = math.min(1.0, currentQuality + 0.005);
    }
  }

  /// Clear all particles
  void clearAllParticles() {
    for (final particle in _activeParticles) {
      _particlePool.returnParticle(particle);
    }
    _activeParticles.clear();
  }

  /// Set quality level manually (0.0 to 1.0)
  void setQuality(double quality) {
    currentQuality = quality.clamp(0.0, 1.0);
    maxParticles = (50 * currentQuality).round().clamp(10, 50);
  }
  
  /// Set maximum particle count directly
  void setMaxParticles(int count) {
    maxParticles = count.clamp(10, 500);
    currentQuality = maxParticles / 50.0; // Update quality to match
  }

  /// Add a custom particle (for skin trail effects)
  void addCustomParticle(Particle customParticle) {
    if (_activeParticles.length >= maxParticles) return;
    
    // Convert custom particle to NeonParticle
    final neonParticle = _particlePool.getParticle(
      position: Vector2(customParticle.position.dx, customParticle.position.dy),
      velocity: Vector2(customParticle.velocity.dx, customParticle.velocity.dy),
      color: customParticle.color,
      maxLife: customParticle.lifetime,
      size: customParticle.size,
      type: customParticle.type,
    );
    
    _activeParticles.add(neonParticle);
  }

  /// Get current particle statistics
  Map<String, dynamic> getStats() {
    return {
      'activeParticles': _activeParticles.length,
      'maxParticles': maxParticles,
      'poolAvailable': _particlePool.availableCount,
      'poolUsed': _particlePool.usedCount,
      'currentQuality': currentQuality,
    };
  }
}

enum ParticleType {
  trail,
  explosion,
  spark,
  pulse,
  fire,
  glow,
  energy,
}