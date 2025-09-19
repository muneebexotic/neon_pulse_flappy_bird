import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Controller for the scan line reveal animation that plays on screen load
class ScanLineAnimationController extends ChangeNotifier {
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _revealAnimation;
  late Animation<double> _glowAnimation;
  
  bool _isInitialized = false;
  bool _isAnimating = false;
  double _scanLinePosition = 0.0;
  double _revealProgress = 0.0;
  double _glowIntensity = 0.0;
  
  // Animation configuration
  final Duration _scanDuration;
  final Duration _revealDelay;
  final Curve _scanCurve;
  final Curve _revealCurve;
  final Color _scanLineColor;
  final double _scanLineWidth;
  final double _glowRadius;

  ScanLineAnimationController({
    Duration scanDuration = const Duration(milliseconds: 2000),
    Duration revealDelay = const Duration(milliseconds: 300),
    Curve scanCurve = Curves.easeInOutQuart,
    Curve revealCurve = Curves.easeOutCubic,
    Color scanLineColor = const Color(0xFF00FFFF), // Cyan scan line
    double scanLineWidth = 3.0,
    double glowRadius = 20.0,
  }) : _scanDuration = scanDuration,
       _revealDelay = revealDelay,
       _scanCurve = scanCurve,
       _revealCurve = revealCurve,
       _scanLineColor = scanLineColor,
       _scanLineWidth = scanLineWidth,
       _glowRadius = glowRadius;

  /// Initialize the animation controller
  void initialize(TickerProvider tickerProvider) {
    if (_isInitialized) return;

    _animationController = AnimationController(
      duration: _scanDuration + _revealDelay,
      vsync: tickerProvider,
    );

    // Scan line position animation (moves from top to bottom)
    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.8, curve: _scanCurve),
    ));

    // Reveal animation (reveals content behind scan line)
    _revealAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.2, 1.0, curve: _revealCurve),
    ));

    // Glow intensity animation (pulsing effect)
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));

    // Listen to animation updates
    _animationController.addListener(_updateAnimationValues);
    _animationController.addStatusListener(_handleAnimationStatus);

    _isInitialized = true;
  }

  /// Start the scan line reveal animation
  Future<void> startRevealAnimation() async {
    if (!_isInitialized || _isAnimating) return;

    _isAnimating = true;
    notifyListeners();

    try {
      await _animationController.forward();
    } catch (e) {
      // Handle animation interruption
      _isAnimating = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Reset the animation to initial state
  void reset() {
    if (!_isInitialized) return;

    _animationController.reset();
    _scanLinePosition = 0.0;
    _revealProgress = 0.0;
    _glowIntensity = 0.0;
    _isAnimating = false;
    notifyListeners();
  }

  /// Stop the animation
  void stop() {
    if (!_isInitialized) return;

    _animationController.stop();
    _isAnimating = false;
    notifyListeners();
  }

  /// Update animation values
  void _updateAnimationValues() {
    _scanLinePosition = _scanLineAnimation.value;
    _revealProgress = _revealAnimation.value;
    _glowIntensity = _calculateGlowIntensity(_glowAnimation.value);
    notifyListeners();
  }

  /// Handle animation status changes
  void _handleAnimationStatus(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.completed:
        _isAnimating = false;
        notifyListeners();
        break;
      case AnimationStatus.dismissed:
        _isAnimating = false;
        notifyListeners();
        break;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        break;
    }
  }

  /// Calculate glow intensity with pulsing effect
  double _calculateGlowIntensity(double animationValue) {
    // Create a pulsing effect that peaks in the middle of the scan
    final pulseValue = math.sin(animationValue * math.pi);
    return pulseValue * 0.8 + 0.2; // Keep minimum glow of 0.2
  }

  /// Get the current scan line position (0.0 to 1.0)
  double get scanLinePosition => _scanLinePosition;

  /// Get the current reveal progress (0.0 to 1.0)
  double get revealProgress => _revealProgress;

  /// Get the current glow intensity (0.0 to 1.0)
  double get glowIntensity => _glowIntensity;

  /// Check if animation is currently running
  bool get isAnimating => _isAnimating;

  /// Check if animation is initialized
  bool get isInitialized => _isInitialized;

  /// Get scan line color
  Color get scanLineColor => _scanLineColor;

  /// Get scan line width
  double get scanLineWidth => _scanLineWidth;

  /// Get glow radius
  double get glowRadius => _glowRadius;

  /// Calculate scan line Y position for given screen height
  double getScanLineY(double screenHeight) {
    return screenHeight * _scanLinePosition;
  }

  /// Check if a point should be revealed based on scan line position
  bool shouldRevealPoint(double y, double screenHeight) {
    final scanY = getScanLineY(screenHeight);
    return y <= scanY || _revealProgress >= 1.0;
  }

  /// Get reveal opacity for a point based on its position
  double getRevealOpacity(double y, double screenHeight) {
    if (_revealProgress >= 1.0) return 1.0;
    
    final scanY = getScanLineY(screenHeight);
    if (y > scanY) return 0.0;
    
    // Fade in effect behind the scan line
    final distanceBehindScan = scanY - y;
    final fadeDistance = screenHeight * 0.1; // 10% of screen height for fade
    
    if (distanceBehindScan <= fadeDistance) {
      return (distanceBehindScan / fadeDistance) * _revealProgress;
    }
    
    return _revealProgress;
  }

  /// Get glow effect for scan line area
  double getScanLineGlow(double y, double screenHeight) {
    final scanY = getScanLineY(screenHeight);
    final distance = (y - scanY).abs();
    
    if (distance > _glowRadius) return 0.0;
    
    final glowFactor = 1.0 - (distance / _glowRadius);
    return glowFactor * _glowIntensity;
  }

  /// Create a custom paint for the scan line effect
  CustomPainter createScanLinePainter(Size screenSize) {
    return ScanLinePainter(
      scanLinePosition: _scanLinePosition,
      revealProgress: _revealProgress,
      glowIntensity: _glowIntensity,
      scanLineColor: _scanLineColor,
      scanLineWidth: _scanLineWidth,
      glowRadius: _glowRadius,
      screenSize: screenSize,
    );
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _animationController.removeListener(_updateAnimationValues);
      _animationController.removeStatusListener(_handleAnimationStatus);
      _animationController.dispose();
    }
    super.dispose();
  }
}

/// Custom painter for the scan line reveal effect
class ScanLinePainter extends CustomPainter {
  final double scanLinePosition;
  final double revealProgress;
  final double glowIntensity;
  final Color scanLineColor;
  final double scanLineWidth;
  final double glowRadius;
  final Size screenSize;

  ScanLinePainter({
    required this.scanLinePosition,
    required this.revealProgress,
    required this.glowIntensity,
    required this.scanLineColor,
    required this.scanLineWidth,
    required this.glowRadius,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scanLinePosition <= 0.0) return;

    final scanY = size.height * scanLinePosition;
    
    // Draw glow effect
    _drawGlowEffect(canvas, size, scanY);
    
    // Draw scan line
    _drawScanLine(canvas, size, scanY);
    
    // Draw reveal mask
    _drawRevealMask(canvas, size, scanY);
  }

  /// Draw the glow effect around the scan line
  void _drawGlowEffect(Canvas canvas, Size size, double scanY) {
    if (glowIntensity <= 0.0) return;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          scanLineColor.withOpacity(glowIntensity * 0.6),
          scanLineColor.withOpacity(glowIntensity * 0.3),
          scanLineColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, scanY - glowRadius, size.width, glowRadius * 2));

    canvas.drawRect(
      Rect.fromLTWH(0, scanY - glowRadius, size.width, glowRadius * 2),
      glowPaint,
    );
  }

  /// Draw the main scan line
  void _drawScanLine(Canvas canvas, Size size, double scanY) {
    final linePaint = Paint()
      ..color = scanLineColor.withOpacity(glowIntensity)
      ..strokeWidth = scanLineWidth
      ..style = PaintingStyle.stroke;

    // Main scan line
    canvas.drawLine(
      Offset(0, scanY),
      Offset(size.width, scanY),
      linePaint,
    );

    // Add animated segments for more dynamic effect
    final segmentPaint = Paint()
      ..color = scanLineColor.withOpacity(glowIntensity * 1.5)
      ..strokeWidth = scanLineWidth * 0.5
      ..style = PaintingStyle.stroke;

    final segmentLength = size.width * 0.1;
    final animatedOffset = (scanLinePosition * size.width * 2) % (segmentLength * 2);

    for (double x = -segmentLength + animatedOffset; x < size.width + segmentLength; x += segmentLength * 2) {
      canvas.drawLine(
        Offset(x, scanY),
        Offset(x + segmentLength, scanY),
        segmentPaint,
      );
    }
  }

  /// Draw the reveal mask effect
  void _drawRevealMask(Canvas canvas, Size size, double scanY) {
    if (revealProgress <= 0.0) return;

    // Create gradient mask for smooth reveal
    final maskPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(revealProgress),
          Colors.white.withOpacity(revealProgress * 0.8),
          Colors.white.withOpacity(0.0),
        ],
        stops: [0.0, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, scanY + glowRadius));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, scanY + glowRadius),
      maskPaint,
    );
  }

  @override
  bool shouldRepaint(ScanLinePainter oldDelegate) {
    return scanLinePosition != oldDelegate.scanLinePosition ||
           revealProgress != oldDelegate.revealProgress ||
           glowIntensity != oldDelegate.glowIntensity;
  }
}