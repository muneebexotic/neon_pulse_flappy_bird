import 'package:flutter/material.dart';

/// Neon color palette for the cyberpunk theme
class NeonColors {
  // Primary neon colors
  static const Color electricBlue = Color(0xFF00FFFF);
  static const Color hotPink = Color(0xFFFF1493);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color warningOrange = Color(0xFFFF4500);
  static const Color neonPurple = Color(0xFFBF00FF);
  static const Color neonYellow = Color(0xFFFFFF00);
  
  // Background colors
  static const Color deepSpace = Color(0xFF0B0B1F);
  static const Color darkPurple = Color(0xFF1A0B2E);
  static const Color charcoal = Color(0xFF2D2D2D);
  static const Color darkGray = Color(0xFF1A1A1A);
  
  // Gradient colors
  static const Color gradientStart = Color(0xFF0B0B1F);
  static const Color gradientMid = Color(0xFF1A0B2E);
  static const Color gradientEnd = Color(0xFF2D1B3D);
  
  // Performance-based colors
  static const Color performanceGood = neonGreen;
  static const Color performanceWarning = neonYellow;
  static const Color performanceDanger = warningOrange;
  
  // UI element colors
  static const Color uiPrimary = electricBlue;
  static const Color uiSecondary = hotPink;
  static const Color uiAccent = neonGreen;
  static const Color uiDisabled = Color(0xFF333333);
  
  /// Get a random neon color
  static Color getRandomNeon() {
    final colors = [
      electricBlue,
      hotPink,
      neonGreen,
      neonPurple,
      neonYellow,
    ];
    return colors[(DateTime.now().millisecondsSinceEpoch % colors.length)];
  }
  
  /// Get performance color based on value (0.0 to 1.0)
  static Color getPerformanceColor(double performance) {
    if (performance >= 0.8) return performanceGood;
    if (performance >= 0.5) return performanceWarning;
    return performanceDanger;
  }
  
  /// Create a cyberpunk background gradient
  static LinearGradient createCyberpunkGradient({
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [
        gradientStart,
        gradientMid,
        gradientEnd,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }
  
  /// Create a neon glow gradient for UI elements
  static RadialGradient createNeonGlow({
    required Color color,
    double intensity = 1.0,
  }) {
    return RadialGradient(
      colors: [
        color.withOpacity(intensity),
        color.withOpacity(intensity * 0.7),
        color.withOpacity(intensity * 0.3),
        color.withOpacity(0.0),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
  }
  
  /// Get a color with animated intensity
  static Color getAnimatedColor(Color baseColor, double animationValue, {
    double minIntensity = 0.6,
    double maxIntensity = 1.0,
  }) {
    final intensity = minIntensity + 
        (maxIntensity - minIntensity) * 
        (0.5 + 0.5 * (animationValue % 1.0));
    
    return Color.lerp(
      baseColor.withOpacity(minIntensity),
      baseColor.withOpacity(maxIntensity),
      intensity,
    ) ?? baseColor;
  }
  
  /// Create a pulsing color effect
  static Color getPulsingColor(Color baseColor, double time, {
    double frequency = 2.0,
    double minOpacity = 0.5,
    double maxOpacity = 1.0,
  }) {
    final opacity = minOpacity + 
        (maxOpacity - minOpacity) * 
        (0.5 + 0.5 * (time * frequency % 1.0));
    
    return baseColor.withOpacity(opacity);
  }
}