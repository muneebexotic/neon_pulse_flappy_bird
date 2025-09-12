import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../effects/neon_colors.dart';
import '../managers/audio_manager.dart';

/// Visual component that displays beat synchronization cues
class BeatVisualizer extends Component {
  final AudioManager audioManager;
  
  // Beat visualization properties
  double _beatIntensity = 0.0;
  double _lastBeatTime = 0.0;
  double _nextBeatPrediction = 0.0;
  bool _beatDetected = false;
  
  // Visual elements
  final List<BeatPulse> _beatPulses = [];
  final List<BeatRing> _beatRings = [];
  
  // Animation properties
  double _animationTime = 0.0;
  
  // Configuration
  static const double maxBeatPulses = 5;
  static const double beatPulseDuration = 1.0;
  static const double beatRingDuration = 0.8;
  
  BeatVisualizer({required this.audioManager});
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Listen to beat events
    audioManager.beatStream.listen(_onBeatDetected);
    
    debugPrint('Beat visualizer loaded');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    _animationTime += dt;
    
    // Update beat intensity (fade out over time)
    if (_beatIntensity > 0.0) {
      _beatIntensity = math.max(0.0, _beatIntensity - dt * 2.0);
    }
    
    // Update beat prediction
    _updateBeatPrediction();
    
    // Update beat pulses
    _updateBeatPulses(dt);
    
    // Update beat rings
    _updateBeatRings(dt);
  }
  
  void _onBeatDetected(BeatEvent beatEvent) {
    _beatDetected = true;
    _beatIntensity = 1.0;
    _lastBeatTime = _animationTime;
    
    // Create new beat pulse
    _createBeatPulse();
    
    // Create beat ring effect
    _createBeatRing();
  }
  
  void _updateBeatPrediction() {
    if (audioManager.currentBpm > 0) {
      final beatInterval = 60.0 / audioManager.currentBpm;
      _nextBeatPrediction = _lastBeatTime + beatInterval;
    }
  }
  
  void _createBeatPulse() {
    // Remove old pulses if we have too many
    while (_beatPulses.length >= maxBeatPulses) {
      _beatPulses.removeAt(0);
    }
    
    _beatPulses.add(BeatPulse(
      startTime: _animationTime,
      duration: beatPulseDuration,
    ));
  }
  
  void _createBeatRing() {
    _beatRings.add(BeatRing(
      startTime: _animationTime,
      duration: beatRingDuration,
    ));
  }
  
  void _updateBeatPulses(double dt) {
    _beatPulses.removeWhere((pulse) => 
        _animationTime - pulse.startTime > pulse.duration);
    
    for (final pulse in _beatPulses) {
      pulse.update(_animationTime);
    }
  }
  
  void _updateBeatRings(double dt) {
    _beatRings.removeWhere((ring) => 
        _animationTime - ring.startTime > ring.duration);
    
    for (final ring in _beatRings) {
      ring.update(_animationTime);
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final size = Size(800, 600); // Game world size
    
    // Render beat pulses in background
    _renderBeatPulses(canvas, size);
    
    // Render beat rings
    _renderBeatRings(canvas, size);
    
    // Render beat prediction indicator
    _renderBeatPrediction(canvas, size);
  }
  
  void _renderBeatPulses(Canvas canvas, Size size) {
    for (final pulse in _beatPulses) {
      final progress = pulse.progress;
      final opacity = (1.0 - progress) * 0.3;
      
      final paint = Paint()
        ..color = NeonColors.electricBlue.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      // Create expanding circle effect
      final radius = progress * size.width * 0.8;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        radius,
        paint,
      );
    }
  }
  
  void _renderBeatRings(Canvas canvas, Size size) {
    for (final ring in _beatRings) {
      final progress = ring.progress;
      final opacity = (1.0 - progress) * 0.6;
      
      final paint = Paint()
        ..color = NeonColors.hotPink.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      // Create expanding ring effect
      final radius = progress * 100.0 + 20.0;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        radius,
        paint,
      );
    }
  }
  
  void _renderBeatPrediction(Canvas canvas, Size size) {
    if (_nextBeatPrediction <= 0) return;
    
    final timeToBeat = _nextBeatPrediction - _animationTime;
    if (timeToBeat <= 0 || timeToBeat > 2.0) return;
    
    // Show prediction indicator
    final progress = 1.0 - (timeToBeat / 2.0);
    final opacity = math.sin(progress * math.pi) * 0.5;
    
    final paint = Paint()
      ..color = NeonColors.neonGreen.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Draw prediction circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      30.0 + progress * 10.0,
      paint,
    );
  }
  
  /// Get current beat intensity for other components to use
  double get beatIntensity => _beatIntensity;
  
  /// Check if a beat was recently detected
  bool get recentBeatDetected => _beatDetected;
  
  /// Reset beat detection flag
  void resetBeatDetection() {
    _beatDetected = false;
  }
}

/// Represents a beat pulse visual effect
class BeatPulse {
  final double startTime;
  final double duration;
  double progress = 0.0;
  
  BeatPulse({
    required this.startTime,
    required this.duration,
  });
  
  void update(double currentTime) {
    final elapsed = currentTime - startTime;
    progress = (elapsed / duration).clamp(0.0, 1.0);
  }
}

/// Represents a beat ring visual effect
class BeatRing {
  final double startTime;
  final double duration;
  double progress = 0.0;
  
  BeatRing({
    required this.startTime,
    required this.duration,
  });
  
  void update(double currentTime) {
    final elapsed = currentTime - startTime;
    progress = (elapsed / duration).clamp(0.0, 1.0);
  }
}