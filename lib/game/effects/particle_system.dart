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

/// Enhanced particle pool with better memory management
class ParticlePool {
  final List<NeonParticle> _availableParticles = [];
  final Set<NeonParticle> _activeParticles = <NeonParticle>{};
  int maxPoolSize;
  int _totalCreated = 0;

  ParticlePool({this.maxPoolSize = 200});

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
      _totalCreated++;
    }
    
    _activeParticles.add(particle);
    return particle;
  }

  /// Return a particle to the pool
  void returnParticle(NeonParticle particle) {
    if (_activeParticles.remove(particle)) {
      if (_availableParticles.length < maxPoolSize) {
        _availableParticles.add(particle);
      }
    }
  }

  /// Adjust pool size dynamically
  void adjustPoolSize(int newSize) {
    maxPoolSize = newSize;
    
    // If new size is smaller, remove excess particles
    while (_availableParticles.length > maxPoolSize) {
      _availableParticles.removeLast();
    }
  }

  /// Get current pool statistics
  int get availableCount => _availableParticles.length;
  int get activeCount => _activeParticles.length;
  int get totalCreated => _totalCreated;
  double get utilization => activeCount / maxPoolSize;
  
  /// Check if pool is under pressure
  bool get isUnderPressure => utilization > 0.9;
  
  /// Clear all particles
  void clear() {
    _availableParticles.clear();
    _activeParticles.clear();
  }
}

/// Main particle system component with adaptive quality
class ParticleSystem extends Component {
  final List<NeonParticle> _activeParticles = [];
  final ParticlePool _particlePool = ParticlePool(maxPoolSize: 300);
  
  // Performance settings with adaptive quality
  int maxParticles = 150;
  bool qualityAdjustment = true;
  double currentQuality = 1.0;
  
  // Batch rendering optimization
  final List<NeonParticle> _batchedParticles = [];
  bool _enableBatching = true;
  
  // Performance monitoring
  int _framesSinceLastCleanup = 0;
  static const int _cleanupInterval = 300; // Clean up every 5 seconds at 60fps
  
  // Quality levels
  static const Map<String, int> _qualityParticleCounts = {
    'low': 50,
    'medium': 150,
    'high': 300,
    'ultra': 500,
  };

  @override
  void update(double dt) {
    super.update(dt);
    
    // Update all active particles with optimized loop
    _updateParticles(dt);
    
    // Periodic cleanup and optimization
    _framesSinceLastCleanup++;
    if (_framesSinceLastCleanup >= _cleanupInterval) {
      _performCleanup();
      _framesSinceLastCleanup = 0;
    }
    
    // Adjust quality based on performance if enabled
    if (qualityAdjustment) {
      _adjustQuality();
    }
  }

  /// Optimized particle update loop
  void _updateParticles(double dt) {
    for (int i = _activeParticles.length - 1; i >= 0; i--) {
      final particle = _activeParticles[i];
      particle.update(dt);
      
      // Remove dead particles and return to pool
      if (!particle.isAlive) {
        _activeParticles.removeAt(i);
        _particlePool.returnParticle(particle);
      }
    }
  }

  /// Perform periodic cleanup and optimization
  void _performCleanup() {
    // Remove particles that are barely visible to free up resources
    for (int i = _activeParticles.length - 1; i >= 0; i--) {
      final particle = _activeParticles[i];
      if (particle.alpha < 0.05 || particle.size < 0.5) {
        _activeParticles.removeAt(i);
        _particlePool.returnParticle(particle);
      }
    }
    
    // Adjust pool size if needed
    if (_particlePool.isUnderPressure) {
      _reduceParticleCount();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    if (_enableBatching && _activeParticles.length > 10) {
      _renderBatched(canvas);
    } else {
      _renderIndividual(canvas);
    }
  }

  /// Render particles individually (for small counts)
  void _renderIndividual(Canvas canvas) {
    for (final particle in _activeParticles) {
      particle.render(canvas);
    }
  }

  /// Render particles in batches for better performance
  void _renderBatched(Canvas canvas) {
    // Group particles by similar properties for batch rendering
    final Map<String, List<NeonParticle>> batches = {};
    
    for (final particle in _activeParticles) {
      final key = '${particle.color.value}_${particle.size.round()}';
      batches.putIfAbsent(key, () => []).add(particle);
    }
    
    // Render each batch
    for (final batch in batches.values) {
      if (batch.isNotEmpty) {
        _renderParticleBatch(canvas, batch);
      }
    }
  }

  /// Render a batch of similar particles
  void _renderParticleBatch(Canvas canvas, List<NeonParticle> particles) {
    if (particles.isEmpty) return;
    
    final firstParticle = particles.first;
    final paint = Paint()
      ..color = firstParticle.color
      ..style = PaintingStyle.fill;
    
    final glowPaint = Paint()
      ..color = firstParticle.color.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, firstParticle.size * 2);
    
    // Draw all particles in the batch
    for (final particle in particles) {
      if (!particle.isAlive) continue;
      
      final adjustedPaint = paint..color = particle.color.withOpacity(particle.alpha);
      final adjustedGlowPaint = glowPaint..color = particle.color.withOpacity(particle.alpha * 0.3);
      
      // Draw glow
      canvas.drawCircle(Offset(particle.position.x, particle.position.y), particle.size * 2, adjustedGlowPaint);
      
      // Draw core particle
      canvas.drawCircle(Offset(particle.position.x, particle.position.y), particle.size, adjustedPaint);
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

  /// Adjust quality based on performance with enhanced logic
  void _adjustQuality() {
    final particleRatio = _activeParticles.length / maxParticles;
    final poolPressure = _particlePool.utilization;
    
    // More aggressive quality reduction under pressure
    if (particleRatio > 0.95 || poolPressure > 0.9) {
      currentQuality = math.max(0.2, currentQuality - 0.02);
      _reduceParticleCount();
    } else if (particleRatio > 0.8 || poolPressure > 0.7) {
      currentQuality = math.max(0.3, currentQuality - 0.01);
    } else if (particleRatio < 0.4 && poolPressure < 0.5) {
      // Can increase quality when performance is good
      currentQuality = math.min(1.0, currentQuality + 0.005);
    }
    
    // Adjust batching based on particle count
    _enableBatching = _activeParticles.length > 20;
  }

  /// Reduce particle count when under pressure
  void _reduceParticleCount() {
    final targetReduction = (_activeParticles.length * 0.2).round();
    
    // Remove oldest/weakest particles first
    final particlesToRemove = <int>[];
    for (int i = 0; i < _activeParticles.length && particlesToRemove.length < targetReduction; i++) {
      final particle = _activeParticles[i];
      if (particle.alpha < 0.3 || particle.life < particle.maxLife * 0.2) {
        particlesToRemove.add(i);
      }
    }
    
    // Remove particles in reverse order to maintain indices
    for (int i = particlesToRemove.length - 1; i >= 0; i--) {
      final index = particlesToRemove[i];
      final particle = _activeParticles.removeAt(index);
      _particlePool.returnParticle(particle);
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
    maxParticles = (300 * currentQuality).round().clamp(20, 500);
    _particlePool.adjustPoolSize((maxParticles * 1.5).round());
  }
  
  /// Set maximum particle count directly
  void setMaxParticles(int count) {
    maxParticles = count.clamp(20, 500);
    currentQuality = maxParticles / 300.0; // Update quality to match
    _particlePool.adjustPoolSize((maxParticles * 1.5).round());
  }

  /// Set quality by name (low, medium, high, ultra)
  void setQualityByName(String qualityName) {
    final particleCount = _qualityParticleCounts[qualityName.toLowerCase()] ?? 150;
    setMaxParticles(particleCount);
  }

  /// Enable or disable batch rendering
  void setBatchRendering(bool enabled) {
    _enableBatching = enabled;
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

  /// Get comprehensive particle statistics
  Map<String, dynamic> getStats() {
    return {
      'activeParticles': _activeParticles.length,
      'maxParticles': maxParticles,
      'poolAvailable': _particlePool.availableCount,
      'poolActive': _particlePool.activeCount,
      'poolTotal': _particlePool.totalCreated,
      'poolUtilization': (_particlePool.utilization * 100).toStringAsFixed(1) + '%',
      'currentQuality': (currentQuality * 100).toStringAsFixed(1) + '%',
      'batchRenderingEnabled': _enableBatching,
      'framesSinceCleanup': _framesSinceLastCleanup,
      'isUnderPressure': _particlePool.isUnderPressure,
    };
  }

  /// Get memory usage estimate in KB
  double getMemoryUsageKB() {
    final activeMemory = _activeParticles.length * 0.1; // ~100 bytes per particle
    final poolMemory = _particlePool.availableCount * 0.1;
    return activeMemory + poolMemory;
  }

  /// Force cleanup of all particles
  void forceCleanup() {
    clearAllParticles();
    _particlePool.clear();
    _framesSinceLastCleanup = 0;
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