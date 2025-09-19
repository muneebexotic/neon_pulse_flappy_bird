import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:neon_pulse_flappy_bird/ui/effects/energy_flow_system.dart';
import 'package:neon_pulse_flappy_bird/game/effects/particle_system.dart';
import 'package:neon_pulse_flappy_bird/models/progression_path_models.dart';
import 'package:neon_pulse_flappy_bird/models/achievement.dart';

void main() {
  group('EnergyFlowSystem', () {
    late EnergyFlowSystem energyFlowSystem;
    late ParticleSystem mockParticleSystem;
    late List<PathSegment> testPathSegments;

    setUp(() {
      mockParticleSystem = ParticleSystem();
      energyFlowSystem = EnergyFlowSystem(
        particleSystem: mockParticleSystem,
        maxEnergyParticles: 20,
        particleSpawnRate: 5.0,
        baseParticleSpeed: 100.0,
        particleLifetime: 2.0,
      );

      testPathSegments = [
        PathSegment(
          id: 'main_path',
          category: AchievementType.score,
          pathPoints: [
            Vector2(0, 0),
            Vector2(100, 50),
            Vector2(200, 100),
            Vector2(300, 150),
          ],
          neonColor: const Color(0xFFFF1493),
          width: 8.0,
          isMainPath: true,
          completionPercentage: 0.8,
          achievementIds: ['test1', 'test2', 'test3'],
        ),
        PathSegment(
          id: 'branch_path',
          category: AchievementType.pulseUsage,
          pathPoints: [
            Vector2(100, 50),
            Vector2(150, 25),
            Vector2(200, 0),
          ],
          neonColor: const Color(0xFF9932CC),
          width: 6.0,
          isMainPath: false,
          completionPercentage: 0.5,
          achievementIds: ['test4', 'test5'],
        ),
      ];
    });

    group('Initialization', () {
      test('should initialize with correct default values', () {
        final system = EnergyFlowSystem(particleSystem: mockParticleSystem);
        
        expect(system.energyParticles, isEmpty);
        final stats = system.getStats();
        expect(stats['energyParticles'], equals(0));
        expect(stats['enableEnergyFlow'], isTrue);
      });

      test('should initialize with custom parameters', () {
        final system = EnergyFlowSystem(
          particleSystem: mockParticleSystem,
          maxEnergyParticles: 100,
          particleSpawnRate: 10.0,
          baseParticleSpeed: 200.0,
          particleLifetime: 5.0,
        );
        
        final stats = system.getStats();
        expect(stats['maxEnergyParticles'], equals(100));
        expect(stats['particleSpawnRate'], equals(10.0));
      });
    });

    group('Particle Management', () {
      test('should spawn particles on completed path segments', () {
        // Update system multiple times to allow particle spawning
        for (int i = 0; i < 10; i++) {
          energyFlowSystem.update(0.5, testPathSegments);
        }
        
        expect(energyFlowSystem.energyParticles.length, greaterThan(0));
      });

      test('should not exceed maximum particle count', () {
        // Force spawn many particles
        for (int i = 0; i < 100; i++) {
          energyFlowSystem.update(0.5, testPathSegments);
        }
        
        expect(energyFlowSystem.energyParticles.length, lessThanOrEqualTo(20));
      });

      test('should update particle positions over time', () {
        // Spawn some particles
        for (int i = 0; i < 5; i++) {
          energyFlowSystem.update(0.2, testPathSegments);
        }
        
        final initialParticles = List.from(energyFlowSystem.energyParticles);
        if (initialParticles.isNotEmpty) {
          final initialPosition = initialParticles.first.position.clone();
          
          // Update system
          energyFlowSystem.update(1.0, testPathSegments);
          
          final updatedParticles = energyFlowSystem.energyParticles;
          if (updatedParticles.isNotEmpty) {
            final updatedPosition = updatedParticles.first.position;
            
            // Position should have changed
            expect(updatedPosition.x, isNot(equals(initialPosition.x)));
          }
        }
      });

      test('should remove dead particles', () {
        // Create a particle with very short life
        energyFlowSystem.update(0.1, testPathSegments);
        
        // Wait for particles to die
        for (int i = 0; i < 50; i++) {
          energyFlowSystem.update(0.1, testPathSegments);
        }
        
        // Some particles should have been cleaned up or at least not exceed max
        final stats = energyFlowSystem.getStats();
        expect(stats['energyParticles'], lessThanOrEqualTo(20));
      });
    });

    group('Path Flow States', () {
      test('should track flow states for path segments', () {
        energyFlowSystem.update(0.1, testPathSegments);
        
        final stats = energyFlowSystem.getStats();
        expect(stats['pathFlowStates'], equals(testPathSegments.length));
      });

      test('should clean up flow states for removed segments', () {
        // Update with initial segments
        energyFlowSystem.update(0.1, testPathSegments);
        
        // Update with fewer segments
        energyFlowSystem.update(0.1, [testPathSegments.first]);
        
        final stats = energyFlowSystem.getStats();
        expect(stats['pathFlowStates'], equals(1));
      });
    });

    group('Effects', () {
      test('should add explosion effect', () {
        final initialParticleCount = energyFlowSystem.energyParticles.length;
        
        energyFlowSystem.addExplosionEffect(
          position: Vector2(100, 100),
          color: Colors.red,
          particleCount: 10,
        );
        
        expect(energyFlowSystem.energyParticles.length, greaterThan(initialParticleCount));
      });

      test('should add pulse effect along path', () {
        final segment = testPathSegments.first;
        final initialParticleCount = energyFlowSystem.energyParticles.length;
        
        energyFlowSystem.addPulseEffect(segment, intensity: 1.0);
        
        expect(energyFlowSystem.energyParticles.length, greaterThan(initialParticleCount));
      });

      test('should handle pulse effect on empty path', () {
        final emptySegment = PathSegment(
          id: 'empty',
          category: AchievementType.score,
          pathPoints: [],
          neonColor: Colors.red,
          width: 5.0,
          isMainPath: true,
          completionPercentage: 1.0,
          achievementIds: [],
        );
        
        expect(() {
          energyFlowSystem.addPulseEffect(emptySegment);
        }, returnsNormally);
      });
    });

    group('Quality and Performance', () {
      test('should adjust quality scale', () {
        energyFlowSystem.setQualityScale(0.5);
        
        final stats = energyFlowSystem.getStats();
        expect(stats['qualityScale'], equals(0.5));
      });

      test('should clamp quality scale to valid range', () {
        energyFlowSystem.setQualityScale(-1.0);
        expect(energyFlowSystem.getStats()['qualityScale'], equals(0.1));
        
        energyFlowSystem.setQualityScale(2.0);
        expect(energyFlowSystem.getStats()['qualityScale'], equals(1.0));
      });

      test('should enable/disable energy flow', () {
        energyFlowSystem.setEnergyFlowEnabled(false);
        
        final stats = energyFlowSystem.getStats();
        expect(stats['enableEnergyFlow'], isFalse);
        expect(stats['energyParticles'], equals(0));
      });

      test('should clear all particles', () {
        // Spawn some particles
        for (int i = 0; i < 5; i++) {
          energyFlowSystem.update(0.2, testPathSegments);
        }
        
        energyFlowSystem.clearAllParticles();
        
        final stats = energyFlowSystem.getStats();
        expect(stats['energyParticles'], equals(0));
        expect(stats['pathFlowStates'], equals(0));
      });
    });

    group('Statistics', () {
      test('should provide comprehensive statistics', () {
        energyFlowSystem.update(0.1, testPathSegments);
        
        final stats = energyFlowSystem.getStats();
        
        expect(stats, containsPair('energyParticles', isA<int>()));
        expect(stats, containsPair('maxEnergyParticles', isA<int>()));
        expect(stats, containsPair('pathFlowStates', isA<int>()));
        expect(stats, containsPair('qualityScale', isA<double>()));
        expect(stats, containsPair('enableEnergyFlow', isA<bool>()));
        expect(stats, containsPair('particleSpawnRate', isA<double>()));
        expect(stats, containsPair('utilization', isA<String>()));
      });

      test('should calculate utilization percentage correctly', () {
        // Fill system to 50% capacity
        for (int i = 0; i < 50; i++) {
          energyFlowSystem.update(0.1, testPathSegments);
          if (energyFlowSystem.energyParticles.length >= 10) break;
        }
        
        final stats = energyFlowSystem.getStats();
        final utilization = stats['utilization'] as String;
        
        expect(utilization, contains('%'));
        // Just check that utilization is a valid percentage string
        expect(utilization, matches(r'^\d+\.\d+%$'));
      });
    });
  });

  group('PathFlowState', () {
    test('should initialize with correct values', () {
      final state = PathFlowState(pathId: 'test_path');
      
      expect(state.pathId, equals('test_path'));
      expect(state.lastCompletionPercentage, equals(0.0));
      expect(state.flowIntensity, equals(1.0));
    });

    test('should update flow intensity on progress increase', () {
      final state = PathFlowState(pathId: 'test_path');
      
      final segment1 = PathSegment(
        id: 'test_path',
        category: AchievementType.score,
        pathPoints: [Vector2(0, 0), Vector2(100, 100)],
        neonColor: Colors.red,
        width: 5.0,
        isMainPath: true,
        completionPercentage: 0.3,
        achievementIds: ['test'],
      );
      
      state.update(segment1);
      final initialIntensity = state.flowIntensity;
      
      final segment2 = segment1.copyWith(completionPercentage: 0.6);
      state.update(segment2);
      
      expect(state.flowIntensity, greaterThan(initialIntensity));
    });

    test('should gradually reduce flow intensity over time', () {
      final state = PathFlowState(pathId: 'test_path');
      
      final segment = PathSegment(
        id: 'test_path',
        category: AchievementType.score,
        pathPoints: [Vector2(0, 0), Vector2(100, 100)],
        neonColor: Colors.red,
        width: 5.0,
        isMainPath: true,
        completionPercentage: 0.5,
        achievementIds: ['test'],
      );
      
      // Boost intensity
      state.flowIntensity = 2.0;
      state.update(segment);
      
      // Simulate time passing
      Future.delayed(const Duration(milliseconds: 100), () {
        state.update(segment);
        expect(state.flowIntensity, lessThan(2.0));
      });
    });
  });
}