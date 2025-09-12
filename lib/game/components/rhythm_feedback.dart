import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../effects/neon_colors.dart';
import '../managers/audio_manager.dart';

/// Component that provides visual feedback for rhythm accuracy
class RhythmFeedback extends Component {
  final AudioManager audioManager;
  
  // Feedback tracking
  final List<RhythmAccuracyEvent> _recentEvents = [];
  final List<AccuracyIndicator> _accuracyIndicators = [];
  
  // Timing windows (in seconds)
  static const double perfectWindow = 0.1;
  static const double goodWindow = 0.2;
  static const double okWindow = 0.3;
  
  // Animation properties
  double _animationTime = 0.0;
  
  RhythmFeedback({required this.audioManager});
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    debugPrint('Rhythm feedback system loaded');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    _animationTime += dt;
    
    // Clean up old events (keep last 10 seconds)
    _recentEvents.removeWhere((event) => 
        _animationTime - event.timestamp > 10.0);
    
    // Update accuracy indicators
    _updateAccuracyIndicators(dt);
  }
  
  /// Record a player action (jump, pulse, etc.) for rhythm analysis
  void recordPlayerAction(PlayerAction action, {Vector2? position}) {
    final actionTime = _animationTime;
    final nextBeatTime = audioManager.getNextBeatTime();
    
    if (nextBeatTime == null) return;
    
    // Calculate timing accuracy
    final expectedTime = nextBeatTime.millisecondsSinceEpoch / 1000.0;
    final timingError = (actionTime - expectedTime).abs();
    
    // Determine accuracy level
    final accuracy = _calculateAccuracy(timingError);
    
    // Record the event
    final event = RhythmAccuracyEvent(
      timestamp: actionTime,
      action: action,
      accuracy: accuracy,
      timingError: timingError,
      position: position ?? Vector2(400, 300), // Default center position
    );
    
    _recentEvents.add(event);
    
    // Create visual indicator
    _createAccuracyIndicator(event);
    
    debugPrint('Rhythm accuracy: ${accuracy.name} (error: ${timingError.toStringAsFixed(3)}s)');
  }
  
  RhythmAccuracy _calculateAccuracy(double timingError) {
    if (timingError <= perfectWindow) {
      return RhythmAccuracy.perfect;
    } else if (timingError <= goodWindow) {
      return RhythmAccuracy.good;
    } else if (timingError <= okWindow) {
      return RhythmAccuracy.ok;
    } else {
      return RhythmAccuracy.miss;
    }
  }
  
  void _createAccuracyIndicator(RhythmAccuracyEvent event) {
    _accuracyIndicators.add(AccuracyIndicator(
      startTime: _animationTime,
      position: event.position,
      accuracy: event.accuracy,
      duration: 2.0,
    ));
  }
  
  void _updateAccuracyIndicators(double dt) {
    _accuracyIndicators.removeWhere((indicator) => 
        _animationTime - indicator.startTime > indicator.duration);
    
    for (final indicator in _accuracyIndicators) {
      indicator.update(_animationTime);
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Render accuracy indicators
    for (final indicator in _accuracyIndicators) {
      _renderAccuracyIndicator(canvas, indicator);
    }
    
    // Render rhythm streak indicator
    _renderRhythmStreak(canvas);
  }
  
  void _renderAccuracyIndicator(Canvas canvas, AccuracyIndicator indicator) {
    final progress = indicator.progress;
    final opacity = (1.0 - progress) * 0.8;
    
    // Get color based on accuracy
    final color = _getAccuracyColor(indicator.accuracy);
    
    // Draw accuracy text
    final textPainter = TextPainter(
      text: TextSpan(
        text: _getAccuracyText(indicator.accuracy),
        style: TextStyle(
          color: color.withOpacity(opacity),
          fontSize: 16 + (1.0 - progress) * 8,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 6.0,
              color: color.withOpacity(opacity * 0.5),
              offset: const Offset(0, 0),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // Animate position (float upward)
    final animatedY = indicator.position.y - progress * 50;
    final textOffset = Offset(
      indicator.position.x - textPainter.width / 2,
      animatedY - textPainter.height / 2,
    );
    
    textPainter.paint(canvas, textOffset);
    
    // Draw accuracy ring
    final paint = Paint()
      ..color = color.withOpacity(opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(
      Offset(indicator.position.x, animatedY),
      20.0 + progress * 10.0,
      paint,
    );
  }
  
  void _renderRhythmStreak(Canvas canvas) {
    final streak = getCurrentStreak();
    if (streak < 3) return; // Only show for streaks of 3+
    
    final size = Size(800, 600);
    final streakText = 'RHYTHM STREAK: $streak';
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: streakText,
        style: TextStyle(
          color: NeonColors.neonGreen,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 10.0,
              color: NeonColors.neonGreen,
              offset: const Offset(0, 0),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    final textOffset = Offset(
      size.width / 2 - textPainter.width / 2,
      50,
    );
    
    textPainter.paint(canvas, textOffset);
  }
  
  Color _getAccuracyColor(RhythmAccuracy accuracy) {
    switch (accuracy) {
      case RhythmAccuracy.perfect:
        return NeonColors.neonGreen;
      case RhythmAccuracy.good:
        return NeonColors.electricBlue;
      case RhythmAccuracy.ok:
        return NeonColors.warningOrange;
      case RhythmAccuracy.miss:
        return Colors.red;
    }
  }
  
  String _getAccuracyText(RhythmAccuracy accuracy) {
    switch (accuracy) {
      case RhythmAccuracy.perfect:
        return 'PERFECT!';
      case RhythmAccuracy.good:
        return 'GOOD';
      case RhythmAccuracy.ok:
        return 'OK';
      case RhythmAccuracy.miss:
        return 'MISS';
    }
  }
  
  /// Get current rhythm accuracy streak
  int getCurrentStreak() {
    if (_recentEvents.isEmpty) return 0;
    
    int streak = 0;
    for (int i = _recentEvents.length - 1; i >= 0; i--) {
      final event = _recentEvents[i];
      if (event.accuracy == RhythmAccuracy.perfect || 
          event.accuracy == RhythmAccuracy.good) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
  
  /// Get overall rhythm accuracy percentage
  double getAccuracyPercentage() {
    if (_recentEvents.isEmpty) return 0.0;
    
    final goodEvents = _recentEvents.where((event) => 
        event.accuracy == RhythmAccuracy.perfect || 
        event.accuracy == RhythmAccuracy.good).length;
    
    return goodEvents / _recentEvents.length;
  }
  
  /// Check if player is currently in sync with the beat
  bool isInSync() {
    if (_recentEvents.length < 3) return false;
    
    final recentEvents = _recentEvents.take(3).toList();
    return recentEvents.every((event) => 
        event.accuracy == RhythmAccuracy.perfect || 
        event.accuracy == RhythmAccuracy.good);
  }
}

/// Represents a player action for rhythm analysis
enum PlayerAction {
  jump,
  pulse,
  navigation,
}

/// Rhythm accuracy levels
enum RhythmAccuracy {
  perfect,
  good,
  ok,
  miss,
}

/// Represents a rhythm accuracy event
class RhythmAccuracyEvent {
  final double timestamp;
  final PlayerAction action;
  final RhythmAccuracy accuracy;
  final double timingError;
  final Vector2 position;
  
  RhythmAccuracyEvent({
    required this.timestamp,
    required this.action,
    required this.accuracy,
    required this.timingError,
    required this.position,
  });
}

/// Visual indicator for accuracy feedback
class AccuracyIndicator {
  final double startTime;
  final Vector2 position;
  final RhythmAccuracy accuracy;
  final double duration;
  double progress = 0.0;
  
  AccuracyIndicator({
    required this.startTime,
    required this.position,
    required this.accuracy,
    required this.duration,
  });
  
  void update(double currentTime) {
    final elapsed = currentTime - startTime;
    progress = (elapsed / duration).clamp(0.0, 1.0);
  }
}