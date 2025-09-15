import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../effects/neon_colors.dart';

/// Cyberpunk background component with animated gradient and effects
class CyberpunkBackground extends Component {
  double animationTime = 0.0;
  Paint? backgroundPaint;
  Paint? gridPaint;
  
  // Animation properties
  double gridAnimationSpeed = 0.2; // Reduced for performance
  double colorShiftSpeed = 0.1; // Reduced for performance
  
  // Grid properties
  static const double gridSize = 100.0; // Larger grid for fewer lines
  static const double gridOpacity = 0.05; // Reduced opacity
  
  // Performance optimization
  double _lastUpdateTime = 0.0;
  static const double _updateInterval = 0.1; // Update every 100ms instead of every frame
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Initialize paints
    _initializePaints();
    
    debugPrint('Cyberpunk background loaded');
  }
  
  void _initializePaints() {
    // Background gradient paint
    backgroundPaint = Paint()
      ..style = PaintingStyle.fill;
    
    // Grid line paint
    gridPaint = Paint()
      ..color = NeonColors.electricBlue.withOpacity(gridOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update animation time
    animationTime += dt;
    
    // Only update visual properties periodically for performance
    if (animationTime - _lastUpdateTime >= _updateInterval) {
      _updateBackgroundGradient();
      _updateGridAnimation();
      _lastUpdateTime = animationTime;
    }
  }
  
  void _updateBackgroundGradient() {
    // Create animated color shifts
    final colorShift = math.sin(animationTime * colorShiftSpeed) * 0.1;
    
    final startColor = Color.lerp(
      NeonColors.gradientStart,
      NeonColors.darkPurple,
      (colorShift + 1.0) / 2.0,
    ) ?? NeonColors.gradientStart;
    
    final endColor = Color.lerp(
      NeonColors.gradientEnd,
      NeonColors.charcoal,
      (colorShift + 1.0) / 2.0,
    ) ?? NeonColors.gradientEnd;
    
    // Note: We'll apply the gradient in the render method
    // since we need the canvas size
  }
  
  void _updateGridAnimation() {
    // Animate grid opacity for subtle pulsing effect
    final pulseIntensity = 0.5 + 0.5 * math.sin(animationTime * 2.0);
    gridPaint?.color = NeonColors.electricBlue.withOpacity(
      gridOpacity * pulseIntensity
    );
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Get the game size (we'll use a reasonable default if not available)
    final size = Size(800, 600); // Default game world size
    
    // Draw animated background gradient
    _drawBackgroundGradient(canvas, size);
    
    // Draw animated grid overlay
    _drawGridOverlay(canvas, size);
    
    // Draw subtle atmospheric effects
    _drawAtmosphericEffects(canvas, size);
  }
  
  void _drawBackgroundGradient(Canvas canvas, Size size) {
    // Create animated gradient colors
    final colorShift = math.sin(animationTime * colorShiftSpeed) * 0.1;
    
    final startColor = Color.lerp(
      NeonColors.gradientStart,
      NeonColors.darkPurple,
      (colorShift + 1.0) / 2.0,
    ) ?? NeonColors.gradientStart;
    
    final midColor = Color.lerp(
      NeonColors.gradientMid,
      NeonColors.charcoal,
      (colorShift + 1.0) / 2.0,
    ) ?? NeonColors.gradientMid;
    
    final endColor = Color.lerp(
      NeonColors.gradientEnd,
      NeonColors.darkGray,
      (colorShift + 1.0) / 2.0,
    ) ?? NeonColors.gradientEnd;
    
    // Create gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [startColor, midColor, endColor],
      stops: const [0.0, 0.5, 1.0],
    );
    
    // Apply gradient to paint
    backgroundPaint?.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height)
    );
    
    // Draw background
    if (backgroundPaint != null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        backgroundPaint!,
      );
    }
  }
  
  void _drawGridOverlay(Canvas canvas, Size size) {
    // Animated grid offset for subtle movement
    final gridOffset = (animationTime * gridAnimationSpeed * gridSize) % gridSize;
    
    if (gridPaint != null) {
      // Draw vertical grid lines
      for (double x = -gridOffset; x <= size.width + gridSize; x += gridSize) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          gridPaint!,
        );
      }
      
      // Draw horizontal grid lines
      for (double y = -gridOffset; y <= size.height + gridSize; y += gridSize) {
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          gridPaint!,
        );
      }
    }
  }
  
  void _drawAtmosphericEffects(Canvas canvas, Size size) {
    // Draw subtle light rays
    _drawLightRays(canvas, size);
    
    // Draw floating particles/dust
    _drawFloatingParticles(canvas, size);
  }
  
  void _drawLightRays(Canvas canvas, Size size) {
    final rayPaint = Paint()
      ..color = NeonColors.electricBlue.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    
    // Create diagonal light rays
    for (int i = 0; i < 3; i++) {
      final rayOffset = (animationTime * 20.0 + i * 200.0) % (size.width + 200.0);
      final rayWidth = 100.0;
      
      final path = Path();
      path.moveTo(rayOffset - rayWidth, 0);
      path.lineTo(rayOffset, 0);
      path.lineTo(rayOffset - rayWidth * 0.5, size.height);
      path.lineTo(rayOffset - rayWidth * 1.5, size.height);
      path.close();
      
      canvas.drawPath(path, rayPaint);
    }
  }
  
  void _drawFloatingParticles(Canvas canvas, Size size) {
    final particlePaint = Paint()
      ..color = NeonColors.electricBlue.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    // Draw fewer floating particles for better performance
    for (int i = 0; i < 8; i++) {
      final seed = i * 123.456;
      final x = (math.sin(animationTime * 0.3 + seed) * 0.5 + 0.5) * size.width;
      final y = (math.cos(animationTime * 0.2 + seed * 1.5) * 0.5 + 0.5) * size.height;
      final particleSize = 1.0 + math.sin(animationTime * 1.0 + seed) * 0.3;
      
      canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
    }
  }
  
  /// Set animation speed for grid movement
  void setGridAnimationSpeed(double speed) {
    gridAnimationSpeed = speed;
  }
  
  /// Set color shift animation speed
  void setColorShiftSpeed(double speed) {
    colorShiftSpeed = speed;
  }
  
  /// Get current grid animation speed
  double getGridAnimationSpeed() {
    return gridAnimationSpeed;
  }
  
  /// Get current animation time for synchronization
  double get currentAnimationTime => animationTime;
}