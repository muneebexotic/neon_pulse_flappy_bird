import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'dart:math' as math;
import '../../models/progression_path_models.dart';
import '../../models/achievement.dart';
import '../../game/effects/particle_system.dart';
import '../painters/path_renderer.dart';
import '../effects/energy_flow_system.dart';

/// Demo widget showing the PathRenderer and EnergyFlowSystem in action
class ProgressionPathDemo extends StatefulWidget {
  const ProgressionPathDemo({super.key});

  @override
  State<ProgressionPathDemo> createState() => _ProgressionPathDemoState();
}

class _ProgressionPathDemoState extends State<ProgressionPathDemo>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanLineController;
  late EnergyFlowSystem _energyFlowSystem;
  late ParticleSystem _particleSystem;
  
  List<PathSegment> _pathSegments = [];
  List<EnergyFlowParticle> _energyParticles = [];
  
  double _completionProgress = 0.5;
  bool _showScanLine = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _scanLineController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _particleSystem = ParticleSystem();
    _energyFlowSystem = EnergyFlowSystem(
      particleSystem: _particleSystem,
      maxEnergyParticles: 30,
      particleSpawnRate: 3.0,
    );
    
    _initializePathSegments();
    _startEnergyFlowUpdates();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  void _initializePathSegments() {
    _pathSegments = [
      // Main path (score achievements)
      PathSegment(
        id: 'main_path',
        category: AchievementType.score,
        pathPoints: [
          Vector2(50, 100),
          Vector2(150, 120),
          Vector2(250, 140),
          Vector2(350, 160),
          Vector2(450, 180),
          Vector2(550, 200),
        ],
        neonColor: const Color(0xFFFF1493), // Hot pink
        width: 8.0,
        isMainPath: true,
        completionPercentage: _completionProgress,
        achievementIds: ['score_1', 'score_2', 'score_3'],
      ),
      // Branch path (pulse usage)
      PathSegment(
        id: 'pulse_branch',
        category: AchievementType.pulseUsage,
        pathPoints: [
          Vector2(250, 140),
          Vector2(280, 100),
          Vector2(320, 80),
          Vector2(360, 70),
        ],
        neonColor: const Color(0xFF9932CC), // Purple
        width: 6.0,
        isMainPath: false,
        completionPercentage: _completionProgress * 0.8,
        achievementIds: ['pulse_1', 'pulse_2'],
      ),
      // Another branch (games played)
      PathSegment(
        id: 'games_branch',
        category: AchievementType.gamesPlayed,
        pathPoints: [
          Vector2(150, 120),
          Vector2(120, 160),
          Vector2(100, 200),
          Vector2(90, 240),
        ],
        neonColor: const Color(0xFF00FFFF), // Cyan
        width: 5.0,
        isMainPath: false,
        completionPercentage: _completionProgress * 0.6,
        achievementIds: ['games_1', 'games_2'],
      ),
    ];
  }

  void _startEnergyFlowUpdates() {
    // Update energy flow system periodically
    Future.doWhile(() async {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 16)); // ~60fps
        _energyFlowSystem.update(0.016, _pathSegments);
        if (mounted) {
          setState(() {
            _energyParticles = _energyFlowSystem.energyParticles;
          });
        }
        return true;
      }
      return false;
    });
  }

  void _updateCompletion(double value) {
    setState(() {
      _completionProgress = value;
      _initializePathSegments();
    });
  }

  void _triggerScanLine() {
    setState(() {
      _showScanLine = true;
    });
    _scanLineController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _showScanLine = false;
        });
        _scanLineController.reset();
      }
    });
  }

  void _addExplosion() {
    final center = Vector2(300, 150);
    _energyFlowSystem.addExplosionEffect(
      position: center,
      color: const Color(0xFFFFD700), // Gold
      particleCount: 20,
    );
  }

  void _addPulse() {
    if (_pathSegments.isNotEmpty) {
      _energyFlowSystem.addPulseEffect(_pathSegments.first, intensity: 1.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Progression Path Demo'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A2E),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Completion: ', style: TextStyle(color: Colors.white)),
                    Expanded(
                      child: Slider(
                        value: _completionProgress,
                        onChanged: _updateCompletion,
                        activeColor: const Color(0xFFFF1493),
                        inactiveColor: Colors.grey,
                      ),
                    ),
                    Text(
                      '${(_completionProgress * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _triggerScanLine,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FFFF),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Scan Line'),
                    ),
                    ElevatedButton(
                      onPressed: _addExplosion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Explosion'),
                    ),
                    ElevatedButton(
                      onPressed: _addPulse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9932CC),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Pulse'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Path visualization
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseController, _scanLineController]),
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: PathRenderer(
                    pathSegments: _pathSegments,
                    energyParticles: _energyParticles,
                    animationProgress: 1.0,
                    enableGlowEffects: true,
                    glowIntensity: 1.0,
                    pulsePhase: _pulseController.value,
                    showScanLine: _showScanLine,
                    scanLinePosition: _scanLineController.value,
                    enableAntiAliasing: true,
                    qualityScale: 1.0,
                  ),
                );
              },
            ),
          ),
          // Statistics
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A2E),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistics:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatRow('Path Segments', _pathSegments.length.toString()),
                _buildStatRow('Energy Particles', _energyParticles.length.toString()),
                _buildStatRow('Main Path Progress', '${(_completionProgress * 100).toInt()}%'),
                _buildStatRow('Pulse Phase', '${(_pulseController.value * 100).toInt()}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00FFFF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}