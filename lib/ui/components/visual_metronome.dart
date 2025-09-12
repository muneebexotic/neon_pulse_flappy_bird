import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../game/managers/audio_manager.dart';

/// Visual metronome widget that helps players follow the beat
class VisualMetronome extends StatefulWidget {
  final AudioManager audioManager;
  final bool isVisible;
  final double size;
  final Alignment alignment;
  
  const VisualMetronome({
    super.key,
    required this.audioManager,
    this.isVisible = true,
    this.size = 60.0,
    this.alignment = Alignment.topCenter,
  });
  
  @override
  State<VisualMetronome> createState() => _VisualMetronomeState();
}

class _VisualMetronomeState extends State<VisualMetronome>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  double _currentBpm = 128.0;
  bool _beatDetected = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    // Start rotation animation
    _rotationController.repeat();
    
    // Listen to beat events
    widget.audioManager.beatStream.listen(_onBeatDetected);
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
  
  void _onBeatDetected(BeatEvent beatEvent) {
    if (!mounted) return;
    
    setState(() {
      _currentBpm = beatEvent.bpm;
      _beatDetected = true;
    });
    
    // Trigger pulse animation
    _pulseController.forward().then((_) {
      if (mounted) {
        _pulseController.reverse();
      }
    });
    
    // Update rotation speed based on BPM
    final rotationDuration = Duration(milliseconds: (60000 / _currentBpm * 4).round());
    _rotationController.duration = rotationDuration;
    
    // Reset beat detection flag after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _beatDetected = false;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }
    
    return Align(
      alignment: widget.alignment,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: MetronomePainter(
                    beatDetected: _beatDetected,
                    bpm: _currentBpm,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter for the visual metronome
class MetronomePainter extends CustomPainter {
  final bool beatDetected;
  final double bpm;
  
  MetronomePainter({
    required this.beatDetected,
    required this.bpm,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw outer ring
    _drawOuterRing(canvas, center, radius);
    
    // Draw BPM indicators
    _drawBpmIndicators(canvas, center, radius);
    
    // Draw center circle
    _drawCenterCircle(canvas, center, radius);
    
    // Draw beat indicator
    if (beatDetected) {
      _drawBeatIndicator(canvas, center, radius);
    }
    
    // Draw BPM text
    _drawBpmText(canvas, center);
  }
  
  void _drawOuterRing(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // Add glow effect
    final glowPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    
    canvas.drawCircle(center, radius - 5, glowPaint);
    canvas.drawCircle(center, radius - 5, paint);
  }
  
  void _drawBpmIndicators(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    // Draw 4 beat indicators (quarter notes)
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - math.pi / 2;
      final x = center.dx + (radius - 15) * math.cos(angle);
      final y = center.dy + (radius - 15) * math.sin(angle);
      
      canvas.drawCircle(Offset(x, y), 3.0, paint);
    }
  }
  
  void _drawCenterCircle(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = beatDetected ? Colors.pink : Colors.blue
      ..style = PaintingStyle.fill;
    
    // Add glow effect for beat detection
    if (beatDetected) {
      final glowPaint = Paint()
        ..color = Colors.pink.withOpacity(0.5)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      
      canvas.drawCircle(center, 12.0, glowPaint);
    }
    
    canvas.drawCircle(center, 8.0, paint);
  }
  
  void _drawBeatIndicator(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.pink.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Draw expanding circle for beat indication
    canvas.drawCircle(center, radius - 2, paint);
  }
  
  void _drawBpmText(Canvas canvas, Offset center) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${bpm.round()}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy + 15,
    );
    
    textPainter.paint(canvas, textOffset);
  }
  
  @override
  bool shouldRepaint(covariant MetronomePainter oldDelegate) {
    return oldDelegate.beatDetected != beatDetected || 
           oldDelegate.bpm != bpm;
  }
}