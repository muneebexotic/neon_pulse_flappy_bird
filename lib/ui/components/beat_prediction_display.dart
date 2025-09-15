import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../game/managers/audio_manager.dart';

/// Widget that displays upcoming beat predictions for obstacle spawns
class BeatPredictionDisplay extends StatefulWidget {
  final AudioManager audioManager;
  final bool isVisible;
  final int predictionsToShow;
  
  const BeatPredictionDisplay({
    super.key,
    required this.audioManager,
    this.isVisible = true,
    this.predictionsToShow = 4,
  });
  
  @override
  State<BeatPredictionDisplay> createState() => _BeatPredictionDisplayState();
}

class _BeatPredictionDisplayState extends State<BeatPredictionDisplay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  List<BeatPrediction> _predictions = [];
  double _currentTime = 0.0;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start pulse animation loop
    _pulseController.repeat(reverse: true);
    
    // Listen to beat events to update predictions
    widget.audioManager.beatStream.listen(_onBeatDetected);
    
    // Initialize predictions
    _updatePredictions();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  void _onBeatDetected(BeatEvent beatEvent) {
    if (!mounted) return;
    
    setState(() {
      _currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      _updatePredictions();
    });
  }
  
  void _updatePredictions() {
    if (widget.audioManager.currentBpm <= 0) return;
    
    final beatInterval = 60.0 / widget.audioManager.currentBpm;
    final nextBeatTime = widget.audioManager.getNextBeatTime();
    
    if (nextBeatTime == null) return;
    
    final baseTime = nextBeatTime.millisecondsSinceEpoch / 1000.0;
    
    _predictions.clear();
    for (int i = 0; i < widget.predictionsToShow; i++) {
      final predictionTime = baseTime + (i * beatInterval);
      final timeUntilBeat = predictionTime - _currentTime;
      
      if (timeUntilBeat > 0) {
        _predictions.add(BeatPrediction(
          timeUntilBeat: timeUntilBeat,
          beatNumber: i + 1,
          confidence: _calculateConfidence(timeUntilBeat),
        ));
      }
    }
  }
  
  double _calculateConfidence(double timeUntilBeat) {
    // Confidence decreases with distance in time
    if (timeUntilBeat <= 2.0) return 1.0;
    if (timeUntilBeat <= 4.0) return 0.8;
    if (timeUntilBeat <= 6.0) return 0.6;
    return 0.4;
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible || _predictions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      top: 100,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.cyan.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.cyan,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'BEAT PREDICTION',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Predictions list
            ..._predictions.map((prediction) => _buildPredictionItem(prediction)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPredictionItem(BeatPrediction prediction) {
    final isImminent = prediction.timeUntilBeat <= 1.0;
    final color = _getPredictionColor(prediction);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Beat indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isImminent ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: isImminent ? [
                      BoxShadow(
                        color: color.withOpacity(0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ] : null,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          
          // Time display
          Text(
            '${prediction.timeUntilBeat.toStringAsFixed(1)}s',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          
          // Confidence bar
          Container(
            width: 30,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1.5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: prediction.confidence,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getPredictionColor(BeatPrediction prediction) {
    if (prediction.timeUntilBeat <= 1.0) {
      return Colors.red; // Imminent
    } else if (prediction.timeUntilBeat <= 2.0) {
      return Colors.orange; // Soon
    } else if (prediction.timeUntilBeat <= 4.0) {
      return Colors.yellow; // Upcoming
    } else {
      return Colors.green; // Future
    }
  }
}

/// Represents a beat prediction
class BeatPrediction {
  final double timeUntilBeat;
  final int beatNumber;
  final double confidence;
  
  BeatPrediction({
    required this.timeUntilBeat,
    required this.beatNumber,
    required this.confidence,
  });
}

/// Widget for displaying obstacle spawn predictions
class ObstacleSpawnPredictor extends StatefulWidget {
  final AudioManager audioManager;
  final bool isVisible;
  
  const ObstacleSpawnPredictor({
    super.key,
    required this.audioManager,
    this.isVisible = true,
  });
  
  @override
  State<ObstacleSpawnPredictor> createState() => _ObstacleSpawnPredictorState();
}

class _ObstacleSpawnPredictorState extends State<ObstacleSpawnPredictor>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  
  List<SpawnPrediction> _spawnPredictions = [];
  
  @override
  void initState() {
    super.initState();
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
    
    _waveController.repeat();
    
    // Listen to beat events
    widget.audioManager.beatStream.listen(_onBeatDetected);
  }
  
  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }
  
  void _onBeatDetected(BeatEvent beatEvent) {
    if (!mounted) return;
    
    setState(() {
      _updateSpawnPredictions();
    });
  }
  
  void _updateSpawnPredictions() {
    // Predict obstacle spawns based on beat patterns
    // This is a simplified prediction - in reality, it would use
    // the obstacle manager's spawn patterns
    
    final nextBeatTime = widget.audioManager.getNextBeatTime();
    if (nextBeatTime == null) return;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final beatTime = nextBeatTime.millisecondsSinceEpoch / 1000.0;
    
    _spawnPredictions.clear();
    
    // Predict spawns on every 2nd beat (example pattern)
    for (int i = 0; i < 3; i++) {
      final spawnTime = beatTime + (i * 2 * 60.0 / widget.audioManager.currentBpm);
      final timeUntilSpawn = spawnTime - currentTime;
      
      if (timeUntilSpawn > 0 && timeUntilSpawn <= 8.0) {
        _spawnPredictions.add(SpawnPrediction(
          timeUntilSpawn: timeUntilSpawn,
          spawnType: i % 2 == 0 ? 'Barrier' : 'Platform',
          confidence: timeUntilSpawn <= 4.0 ? 0.9 : 0.7,
        ));
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible || _spawnPredictions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      bottom: 100,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.purple.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.purple,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'OBSTACLE SPAWN',
                  style: TextStyle(
                    color: Colors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Spawn predictions
            ..._spawnPredictions.map((prediction) => _buildSpawnItem(prediction)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSpawnItem(SpawnPrediction prediction) {
    final isImminent = prediction.timeUntilSpawn <= 2.0;
    final color = isImminent ? Colors.red : Colors.purple;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: AnimatedBuilder(
        animation: _waveAnimation,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Spawn type icon
              Transform.scale(
                scale: isImminent ? (1.0 + _waveAnimation.value * 0.2) : 1.0,
                child: Icon(
                  prediction.spawnType == 'Barrier' ? Icons.stop : Icons.view_module,
                  color: color,
                  size: 12,
                ),
              ),
              const SizedBox(width: 6),
              
              // Time and type
              Text(
                '${prediction.spawnType} in ${prediction.timeUntilSpawn.toStringAsFixed(1)}s',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Represents an obstacle spawn prediction
class SpawnPrediction {
  final double timeUntilSpawn;
  final String spawnType;
  final double confidence;
  
  SpawnPrediction({
    required this.timeUntilSpawn,
    required this.spawnType,
    required this.confidence,
  });
}