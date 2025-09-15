import 'dart:collection';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../effects/particle_system.dart';
import '../components/obstacle.dart';
import '../components/power_up.dart';

/// Generic object pool for memory optimization
abstract class ObjectPool<T> {
  final Queue<T> _availableObjects = Queue<T>();
  final Set<T> _activeObjects = <T>{};
  final int maxPoolSize;
  int _totalCreated = 0;

  ObjectPool({this.maxPoolSize = 100});

  /// Create a new object instance
  T createObject();

  /// Reset an object to its initial state
  void resetObject(T object);

  /// Get an object from the pool or create a new one
  T getObject() {
    T object;
    
    if (_availableObjects.isNotEmpty) {
      object = _availableObjects.removeFirst();
      resetObject(object);
    } else {
      object = createObject();
      _totalCreated++;
    }
    
    _activeObjects.add(object);
    return object;
  }

  /// Return an object to the pool
  void returnObject(T object) {
    if (_activeObjects.remove(object)) {
      if (_availableObjects.length < maxPoolSize) {
        _availableObjects.add(object);
      }
    }
  }

  /// Get pool statistics
  Map<String, int> getStats() {
    return {
      'available': _availableObjects.length,
      'active': _activeObjects.length,
      'totalCreated': _totalCreated,
      'maxPoolSize': maxPoolSize,
    };
  }

  /// Clear all objects from the pool
  void clear() {
    _availableObjects.clear();
    _activeObjects.clear();
  }

  /// Get current pool utilization (0.0 to 1.0)
  double get utilization => _activeObjects.length / maxPoolSize;
}

/// Particle pool for NeonParticle objects
class NeonParticlePool extends ObjectPool<NeonParticle> {
  NeonParticlePool({super.maxPoolSize = 500});

  @override
  NeonParticle createObject() {
    return NeonParticle(
      position: Vector2.zero(),
      velocity: Vector2.zero(),
      color: const Color(0xFF00FFFF),
      maxLife: 1.0,
    );
  }

  @override
  void resetObject(NeonParticle particle) {
    particle.position.setZero();
    particle.velocity.setZero();
    particle.life = particle.maxLife;
    particle.alpha = 1.0;
    particle.size = 2.0;
  }

  /// Get a configured particle
  NeonParticle getConfiguredParticle({
    required Vector2 position,
    required Vector2 velocity,
    required Color color,
    required double maxLife,
    double size = 2.0,
    ParticleType type = ParticleType.trail,
  }) {
    final particle = getObject();
    particle.position = position.clone();
    particle.velocity = velocity.clone();
    particle.color = color;
    particle.life = maxLife;
    particle.maxLife = maxLife;
    particle.size = size;
    particle.alpha = 1.0;
    particle.type = type;
    return particle;
  }
}

/// Vector2 pool for frequently used Vector2 objects
class Vector2Pool extends ObjectPool<Vector2> {
  Vector2Pool({super.maxPoolSize = 200});

  @override
  Vector2 createObject() {
    return Vector2.zero();
  }

  @override
  void resetObject(Vector2 vector) {
    vector.setZero();
  }

  /// Get a configured Vector2
  Vector2 getVector2(double x, double y) {
    final vector = getObject();
    vector.setValues(x, y);
    return vector;
  }
}

/// Component pool for reusable game components
class ComponentPool<T extends Component> extends ObjectPool<T> {
  final T Function() _factory;

  ComponentPool(this._factory, {super.maxPoolSize = 50});

  @override
  T createObject() {
    return _factory();
  }

  @override
  void resetObject(T component) {
    // Reset component to initial state - this is a generic implementation
    // Specific component types should override this method for proper reset
    
    // Remove from parent if attached
    if (component.isMounted) {
      component.removeFromParent();
    }
  }
}

/// Centralized pool manager for all object pools
class PoolManager {
  static final PoolManager _instance = PoolManager._internal();
  factory PoolManager() => _instance;
  PoolManager._internal();

  late final NeonParticlePool particlePool;
  late final Vector2Pool vector2Pool;
  // late final ComponentPool<PowerUp> powerUpPool;
  
  bool _initialized = false;

  /// Initialize all pools with performance-based sizing
  void initialize({
    int particlePoolSize = 500,
    int vector2PoolSize = 200,
    int powerUpPoolSize = 20,
  }) {
    if (_initialized) return;

    particlePool = NeonParticlePool(maxPoolSize: particlePoolSize);
    vector2Pool = Vector2Pool(maxPoolSize: vector2PoolSize);
    // Note: PowerUp pool would need a proper factory method
    // For now, we'll comment this out since PowerUp constructor needs specific parameters
    // powerUpPool = ComponentPool<PowerUp>(
    //   () => PowerUp(type: PowerUpType.shield, position: Vector2.zero()),
    //   maxPoolSize: powerUpPoolSize,
    // );

    _initialized = true;
  }

  /// Adjust pool sizes based on performance
  void adjustPoolSizes(double performanceQuality) {
    if (!_initialized) return;

    // Reduce pool sizes on lower performance devices
    final particleMultiplier = performanceQuality.clamp(0.3, 1.0);
    final newParticleSize = (500 * particleMultiplier).round();
    
    // Note: In a real implementation, you would need to implement
    // dynamic pool resizing or recreate pools with new sizes
    // For now, we'll just track the recommended sizes
  }

  /// Get comprehensive pool statistics
  Map<String, dynamic> getAllStats() {
    if (!_initialized) return {'error': 'Not initialized'};

    return {
      'particlePool': particlePool.getStats(),
      'vector2Pool': vector2Pool.getStats(),
      // 'powerUpPool': powerUpPool.getStats(),
      'totalMemoryEstimate': _estimateMemoryUsage(),
    };
  }

  /// Estimate total memory usage of all pools (in KB)
  double _estimateMemoryUsage() {
    if (!_initialized) return 0.0;

    // Rough estimates based on object sizes
    final particleMemory = particlePool.getStats()['totalCreated']! * 0.1; // ~100 bytes per particle
    final vectorMemory = vector2Pool.getStats()['totalCreated']! * 0.016; // ~16 bytes per Vector2
    // final powerUpMemory = powerUpPool.getStats()['totalCreated']! * 0.5; // ~500 bytes per PowerUp
    final powerUpMemory = 0.0; // Disabled for now
    
    return particleMemory + vectorMemory + powerUpMemory;
  }

  /// Clear all pools
  void clearAll() {
    if (!_initialized) return;

    particlePool.clear();
    vector2Pool.clear();
    // powerUpPool.clear();
  }

  /// Check if any pools are under memory pressure
  bool get isUnderMemoryPressure {
    if (!_initialized) return false;

    return particlePool.utilization > 0.9 || 
           vector2Pool.utilization > 0.9;
           // || powerUpPool.utilization > 0.9;
  }
}