import 'package:flutter/material.dart';
import 'neon_theme.dart';
import '../../game/managers/accessibility_manager.dart';

/// Accessibility-enhanced theme that adapts based on user preferences
class AccessibilityTheme {
  final AccessibilityManager _accessibilityManager;
  
  AccessibilityTheme(this._accessibilityManager);

  /// Get color palette adjusted for accessibility needs
  AccessibilityColorPalette get colors => AccessibilityColorPalette(_accessibilityManager);

  /// Get text styles adjusted for accessibility needs
  AccessibilityTextStyles get textStyles => AccessibilityTextStyles(_accessibilityManager);

  /// Get animation durations adjusted for reduced motion
  AccessibilityAnimations get animations => AccessibilityAnimations(_accessibilityManager);
}

/// Color palette with accessibility adjustments
class AccessibilityColorPalette {
  final AccessibilityManager _accessibilityManager;
  
  AccessibilityColorPalette(this._accessibilityManager);

  /// Primary neon colors with accessibility adjustments
  Color get electricBlue => _getAccessibleColor(NeonTheme.electricBlue);
  Color get hotPink => _getAccessibleColor(NeonTheme.hotPink);
  Color get neonGreen => _getAccessibleColor(NeonTheme.neonGreen);
  Color get warningOrange => _getAccessibleColor(NeonTheme.warningOrange);

  /// Background colors with high contrast support
  Color get deepSpace => _getBackgroundColor(NeonTheme.deepSpace);
  Color get darkPurple => _getBackgroundColor(NeonTheme.darkPurple);
  Color get charcoal => _getBackgroundColor(NeonTheme.charcoal);

  /// Text colors with high contrast support
  Color get textPrimary => _getTextColor(NeonTheme.textPrimary);
  Color get textSecondary => _getTextColor(NeonTheme.textSecondary);

  /// Color blind friendly palette
  ColorBlindPalette get colorBlindFriendly => ColorBlindPalette(_accessibilityManager);

  Color _getAccessibleColor(Color originalColor) {
    Color color = _accessibilityManager.getAccessibleColor(originalColor);
    return _accessibilityManager.getHighContrastColor(color);
  }

  Color _getBackgroundColor(Color originalColor) {
    if (_accessibilityManager.highContrastMode) {
      // Make backgrounds darker for better contrast
      return Color.fromARGB(
        originalColor.alpha,
        (originalColor.red * 0.5).round(),
        (originalColor.green * 0.5).round(),
        (originalColor.blue * 0.5).round(),
      );
    }
    return originalColor;
  }

  Color _getTextColor(Color originalColor) {
    if (_accessibilityManager.highContrastMode) {
      // Make text brighter for better contrast
      return Colors.white;
    }
    return originalColor;
  }
}

/// Color blind friendly color palette
class ColorBlindPalette {
  final AccessibilityManager _accessibilityManager;
  
  ColorBlindPalette(this._accessibilityManager);

  /// Safe colors that work for all types of color blindness
  Color get safeBlue => const Color(0xFF0066CC);
  Color get safeOrange => const Color(0xFFFF8800);
  Color get safePurple => const Color(0xFF8800CC);
  Color get safeYellow => const Color(0xFFFFDD00);
  Color get safeGreen => const Color(0xFF00AA44);
  Color get safeRed => const Color(0xFFCC0000);

  /// Get success color (safe for color blind users)
  Color get success => _accessibilityManager.colorBlindFriendly ? safeBlue : NeonTheme.neonGreen;

  /// Get warning color (safe for color blind users)
  Color get warning => _accessibilityManager.colorBlindFriendly ? safeOrange : NeonTheme.warningOrange;

  /// Get danger color (safe for color blind users)
  Color get danger => _accessibilityManager.colorBlindFriendly ? safeRed : NeonTheme.hotPink;

  /// Get info color (safe for color blind users)
  Color get info => _accessibilityManager.colorBlindFriendly ? safePurple : NeonTheme.electricBlue;
}

/// Text styles with accessibility adjustments
class AccessibilityTextStyles {
  final AccessibilityManager _accessibilityManager;
  
  AccessibilityTextStyles(this._accessibilityManager);

  double get _scaleFactor => _accessibilityManager.getTextScaleFactor();

  TextStyle get heading => NeonTheme.headingStyle.copyWith(
    fontSize: NeonTheme.headingStyle.fontSize! * _scaleFactor,
    fontWeight: _accessibilityManager.highContrastMode ? FontWeight.w900 : FontWeight.bold,
  );

  TextStyle get body => NeonTheme.bodyStyle.copyWith(
    fontSize: NeonTheme.bodyStyle.fontSize! * _scaleFactor,
    fontWeight: _accessibilityManager.highContrastMode ? FontWeight.w600 : FontWeight.normal,
  );

  TextStyle get button => NeonTheme.buttonStyle.copyWith(
    fontSize: NeonTheme.buttonStyle.fontSize! * _scaleFactor,
    fontWeight: _accessibilityManager.highContrastMode ? FontWeight.w800 : FontWeight.bold,
  );

  /// Get score text style with large text support
  TextStyle get score => TextStyle(
    fontSize: 48 * _scaleFactor,
    fontWeight: FontWeight.w900,
    color: _accessibilityManager.highContrastMode ? Colors.white : NeonTheme.electricBlue,
    letterSpacing: 2.0,
    shadows: _accessibilityManager.highContrastMode 
      ? [const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))]
      : NeonTheme.getNeonGlow(NeonTheme.electricBlue),
  );

  /// Get UI element text style
  TextStyle get uiElement => TextStyle(
    fontSize: 16 * _scaleFactor,
    fontWeight: _accessibilityManager.highContrastMode ? FontWeight.w700 : FontWeight.w500,
    color: _accessibilityManager.highContrastMode ? Colors.white : NeonTheme.textPrimary,
  );
}

/// Animation settings with reduced motion support
class AccessibilityAnimations {
  final AccessibilityManager _accessibilityManager;
  
  AccessibilityAnimations(this._accessibilityManager);

  double get _durationMultiplier => _accessibilityManager.getAnimationDurationMultiplier();

  /// Standard animation duration
  Duration get standard => Duration(milliseconds: (300 * _durationMultiplier).round());

  /// Fast animation duration
  Duration get fast => Duration(milliseconds: (150 * _durationMultiplier).round());

  /// Slow animation duration
  Duration get slow => Duration(milliseconds: (500 * _durationMultiplier).round());

  /// Particle animation duration
  Duration get particle => Duration(milliseconds: (1000 * _durationMultiplier).round());

  /// UI transition duration
  Duration get uiTransition => Duration(milliseconds: (250 * _durationMultiplier).round());

  /// Get curve for animations (linear for reduced motion)
  Curve get curve => _accessibilityManager.reducedMotion ? Curves.linear : Curves.easeInOut;

  /// Get fade curve for animations
  Curve get fadeCurve => _accessibilityManager.reducedMotion ? Curves.linear : Curves.easeIn;
}

/// Accessibility-aware decoration helpers
class AccessibilityDecorations {
  final AccessibilityManager _accessibilityManager;
  
  AccessibilityDecorations(this._accessibilityManager);

  /// Get neon border with accessibility adjustments
  BoxDecoration getNeonBorder(Color color, {double borderWidth = 2.0}) {
    if (_accessibilityManager.highContrastMode) {
      return BoxDecoration(
        border: Border.all(
          color: Colors.white,
          width: borderWidth * 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      );
    }
    
    return NeonTheme.getNeonBorder(
      _accessibilityManager.getAccessibleColor(color),
      borderWidth: borderWidth,
    );
  }

  /// Get button decoration with accessibility support
  BoxDecoration getButtonDecoration(Color color, {bool isPressed = false}) {
    if (_accessibilityManager.highContrastMode) {
      return BoxDecoration(
        color: isPressed ? Colors.grey[800] : Colors.grey[900],
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isPressed ? null : [
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      );
    }

    return BoxDecoration(
      color: color.withOpacity(isPressed ? 0.3 : 0.1),
      border: Border.all(
        color: _accessibilityManager.getAccessibleColor(color),
        width: 2,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: _accessibilityManager.getAccessibleColor(color).withOpacity(0.3),
          blurRadius: isPressed ? 5 : 15,
          spreadRadius: isPressed ? 1 : 2,
        ),
      ],
    );
  }
}