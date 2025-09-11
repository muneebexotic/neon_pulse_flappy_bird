import 'package:flutter/material.dart';

/// Neon color theme for the cyberpunk aesthetic
class NeonTheme {
  // Primary neon colors
  static const Color electricBlue = Color(0x00FFFF);
  static const Color hotPink = Color(0xFF1493);
  static const Color neonGreen = Color(0x39FF14);
  static const Color warningOrange = Color(0xFF4500);
  
  // Background colors
  static const Color deepSpace = Color(0x0B0B1F);
  static const Color darkPurple = Color(0x1A0B2E);
  static const Color charcoal = Color(0x2D2D2D);
  
  // Utility colors
  static const Color white = Color(0xFFFFFF);
  static const Color black = Color(0x000000);
  
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