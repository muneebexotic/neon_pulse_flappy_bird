import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/bird_skin.dart';
import 'particle_system.dart';

/// Simple particle class for skin trail effects
class Particle {
  final Offset position;
  final Offset velocity;
  final Color color;
  final double size;
  final double lifetime;
  final ParticleType type;

  const Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifetime,
    required this.type,
  });
}

/// Creates different particle trail effects based on bird skin
class SkinTrailEffects {
  /// Create trail particles based on the selected skin
  static List<Particle> createTrailParticles({
    required BirdSkin skin,
    required Offset position,
    required Offset velocity,
    required int particleCount,
  }) {
    switch (skin.id) {
      case 'default':
        return _createCyberTrail(position, velocity, skin.trailColor, particleCount);
      case 'pink_pulse':
        return _createPulseTrail(position, velocity, skin.trailColor, particleCount);
      case 'neon_green':
        return _createElectricTrail(position, velocity, skin.trailColor, particleCount);
      case 'warning_orange':
        return _createFireTrail(position, velocity, skin.trailColor, particleCount);
      case 'pulse_master_skin':
        return _createMasterTrail(position, velocity, skin.trailColor, particleCount);
      case 'golden_bird':
        return _createGoldenTrail(position, velocity, skin.trailColor, particleCount);
      case 'energy_bird':
        return _createEnergyTrail(position, velocity, skin.trailColor, particleCount);
      case 'endurance_bird':
        return _createEnduranceTrail(position, velocity, skin.trailColor, particleCount);
      default:
        return _createCyberTrail(position, velocity, skin.trailColor, particleCount);
    }
  }

  /// Get trail intensity based on skin
  static double getTrailIntensity(BirdSkin skin) {
    switch (skin.id) {
      case 'pulse_master_skin':
      case 'golden_bird':
        return 1.5; // Higher intensity for special skins
      case 'energy_bird':
        return 1.3;
      case 'endurance_bird':
        return 0.8; // Lower intensity for endurance theme
      default:
        return 1.0;
    }
  }

  /// Get trail particle lifetime based on skin
  static double getTrailLifetime(BirdSkin skin) {
    switch (skin.id) {
      case 'golden_bird':
        return 2.5; // Longer lasting golden particles
      case 'endurance_bird':
        return 3.0; // Longest lasting for endurance theme
      case 'energy_bird':
        return 1.8;
      default:
        return 2.0;
    }
  }

  /// Create cyber-themed trail (default)
  static List<Particle> _createCyberTrail(
    Offset position,
    Offset velocity,
    Color color,
    int count,
  ) {
    final particles = <Particle>[];
    final random = math.Random();
    
    for (int i = 0; i < count; i++) {
      particles.add(Particle(
        position: position + Offset(
          random.nextDouble() * 10 - 5,
          random.nextDouble() * 10 - 5,
        ),
        velocity: velocity * 0.3 + Offset(
          random.nextDouble() * 20 - 10,
          random.nextDouble() * 20 - 10,
        ),
        color: color,
        size: 2.0 + random.nextDouble() * 3.0,
        lifetime: 2.0,
        type: ParticleType.trail,
      ));
    }
    
    return particles;
  }

  /// Create pulsing trail effect
  static List<Particle> _createPulseTrail(
    Offset position,
    Offset velocity,
    Color color,
    int count,
  ) {
    final particles = <Particle>[];
    final random = math.Random();
    
    for (int i = 0; i < count; i++) {
      particles.add(Particle(
        position: position + Offset(
          random.nextDouble() * 8 - 4,
          random.nextDouble() * 8 - 4,
        ),
        velocity: velocity * 0.2 + Offset(
          random.nextDouble() * 15 - 7.5,
          random.nextDouble() * 15 - 7.5,
        ),
        color: color,
        size: 3.0 + random.nextDouble() * 4.0,
        lifetime: 2.2,
        type: ParticleType.pulse,
      ));
    }
    
    return particles;
  }

  /// Create electric/lightning trail effect
  static List<Particle> _createElectricTrail(
    Offset position,
    Offset velocity,
    Color color,
    int count,
  ) {
    final particles = <Particle>[];
    final random = math.Random();
    
    for (int i = 0; i < count; i++) {
      particles.add(Particle(
        position: position + Offset(
          random.nextDouble() * 12 - 6,
          random.nextDouble() * 12 - 6,
        ),
        velocity: velocity * 0.4 + Offset(
          random.nextDouble() * 25 - 12.5,
          random.nextDouble() * 25 - 12.5,
        ),
        color: color,
        size: 1.5 + random.nextDouble() * 2.5,
        lifetime: 1.8,
        type: ParticleType.spark,
      ));
    }
    
    return particles;
  }

  /// Create fire-like trail effect
  static List<Particle> _createFireTrail(
    Offset position,
    Offset velocity,
    Color color,
    int count,
  ) {
    final particles = <Particle>[];
    final random = math.Random();
    
    for (int i = 0; i < count; i++) {
      particles.add(Particle(
        position: position + Offset(
          random.nextDouble() * 6 - 3,
          random.nextDouble() * 6 - 3,
        ),
        velocity: velocity * 0.1 + Offset(
          random.nextDouble() * 10 - 5,
          -random.nextDouble() * 20 - 5, // Upward bias for fire effect
        ),
        color: Color.lerp(color, Colors.red, random.nextDouble() * 0.3)!,
        size: 2.5 + random.nextDouble() * 3.5,
        lifetime: 2.5,
        type: ParticleType.fire,
      ));
    }
    
    return particles;
  }

  /// Create master-level trail with complex effects
  static List<Particle> _createMasterTrail(
    Offset position,
    Offset velocity,
    Color color,
    int count,
  ) {
    final particles = <Particle>[];
    final random = math.Random();
    
    // Create multiple types of particles for complex effect
    for (int i = 0; i < count; i++) {
      // Main trail particles
      particles.add(Particle(
        position: position + Offset(
          random.nextDouble() * 8 - 4,
          random.nextDouble() * 8 - 4,
        ),
        velocity: velocity * 0.3 + Offset(
          random.nextDouble() * 15 - 7.5,
          random.nextDouble() * 15 - 7.5,
        ),
        color: color,
        size: 3.0 + random.nextDouble() * 4.0,
        lifetime: 2.5,
        type: ParticleType.trail,
      ));
      
      // Add sparkle effects
      if (random.nextDouble() < 0.3) {
        particles.add(Particle(
          position: position + Offset(
            random.nextDouble() * 15 - 7.5,
            random.nextDouble() * 15 - 7.5,
          ),
          velocity: Offset(
            random.nextDouble() * 30 - 15,
            random.nextDouble() * 30 - 15,
          ),
          color: Colors.white,
          size: 1.0 + random.nextDouble() * 2.0,
          lifetime: 1.5,
          type: ParticleType.spark,
        ));
      }
    }
    
    return particles;
  }

  /// Create golden trail with shimmering effect
  static List<Particle> _createGoldenTrail(
    Offset position,
    Offset velocity,
    Color color,
    int count,
  ) {
    final particles = <Particle>[];
    final random = math.Random();
    
    for (int i = 0; i < count; i++) {
      particles.add(Particle(
        position: position + Offset(
          random.nextDouble() * 10 - 5,
          random.nextDouble() * 10 - 5,
        ),
        velocity: velocity * 0.2 + Offset(
          random.nextDouble() * 12 - 6,
          random.nextDouble() * 12 - 6,
        ),
        color: Color.lerp(color, Colors.yellow, random.nextDouble() * 0.4)!,
        size: 3.5 + random.nextDouble() * 4.5,
        lifetime: 3.0,
        type: ParticleType.glow,
      ));
    }
    
    return particles;
  }

  /// Create energy-themed trail
  static List<Particle> _createEnergyTrail(
    Offset position,
    Offset velocity,
    Color color,
    int count,
  ) {
    final particles = <Particle>[];
    final random = math.Random();
    
    for (int i = 0; i < count; i++) {
      particles.add(Particle(
        position: position + Offset(
          random.nextDouble() * 12 - 6,
          random.nextDouble() * 12 - 6,
        ),
        velocity: velocity * 0.35 + Offset(
          random.nextDouble() * 20 - 10,
          random.nextDouble() * 20 - 10,
        ),
        color: Color.lerp(color, Colors.cyan, random.nextDouble() * 0.3)!,
        size: 2.0 + random.nextDouble() * 3.0,
        lifetime: 2.3,
        type: ParticleType.energy,
      ));
    }
    
    return particles;
  }

  /// Create endurance-themed trail (subtle, long-lasting)
  static List<Particle> _createEnduranceTrail(
    Offset position,
    Offset velocity,
    Color color,
    int count,
  ) {
    final particles = <Particle>[];
    final random = math.Random();
    
    // Fewer but longer-lasting particles
    final adjustedCount = (count * 0.7).round();
    
    for (int i = 0; i < adjustedCount; i++) {
      particles.add(Particle(
        position: position + Offset(
          random.nextDouble() * 6 - 3,
          random.nextDouble() * 6 - 3,
        ),
        velocity: velocity * 0.15 + Offset(
          random.nextDouble() * 8 - 4,
          random.nextDouble() * 8 - 4,
        ),
        color: color.withOpacity(0.8),
        size: 2.5 + random.nextDouble() * 2.0,
        lifetime: 3.5,
        type: ParticleType.trail,
      ));
    }
    
    return particles;
  }
}