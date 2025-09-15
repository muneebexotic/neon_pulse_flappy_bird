import 'package:flutter/material.dart';

/// Neon color theme for the cyberpunk aesthetic
class NeonTheme {
  // Primary neon colors
  static const Color electricBlue = Color(0xFF00FFFF);
  static const Color hotPink = Color(0xFFFF1493);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color warningOrange = Color(0xFFFF4500);
  
  // Background colors
  static const Color deepSpace = Color(0xFF0B0B1F);
  static const Color darkPurple = Color(0xFF1A0B2E);
  static const Color charcoal = Color(0xFF2D2D2D);
  
  // Utility colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  // Theme colors for UI components
  static const Color primaryNeon = electricBlue;
  static const Color secondaryNeon = hotPink;
  static const Color accentNeon = neonGreen;
  static const Color successNeon = neonGreen;
  static const Color warningNeon = warningOrange;
  static const Color backgroundColor = deepSpace;
  static const Color cardBackground = charcoal;
  static const Color cardColor = charcoal;
  static const Color textColor = white;
  static const Color textPrimary = white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  
  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: white,
    letterSpacing: 2.0,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    color: white,
    letterSpacing: 1.0,
  );
  
  static const TextStyle buttonStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
  );
  
  /// Get a neon glow shadow for text
  static List<Shadow> getNeonGlow(Color color, {double blurRadius = 10.0}) {
    return [
      Shadow(
        color: color.withOpacity(0.8),
        blurRadius: blurRadius,
      ),
      Shadow(
        color: color.withOpacity(0.4),
        blurRadius: blurRadius * 2,
      ),
    ];
  }
  
  /// Get a neon border decoration
  static BoxDecoration getNeonBorder(Color color, {double borderWidth = 2.0}) {
    return BoxDecoration(
      border: Border.all(
        color: color.withOpacity(0.8),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 15,
          spreadRadius: 2,
        ),
      ],
    );
  }
}