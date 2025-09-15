import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../managers/audio_manager.dart';

/// Manages accessibility features for the game
class AccessibilityManager {
  static final AccessibilityManager _instance = AccessibilityManager._internal();
  factory AccessibilityManager() => _instance;
  AccessibilityManager._internal();

  SharedPreferences? _prefs;
  AudioManager? _audioManager;

  // Accessibility settings
  bool _highContrastMode = false;
  bool _reducedMotion = false;
  bool _colorBlindFriendly = false;
  bool _soundBasedFeedback = false;
  bool _largeText = false;
  double _uiScale = 1.0;
  ColorBlindType _colorBlindType = ColorBlindType.none;

  /// Initialize accessibility manager
  Future<void> initialize({AudioManager? audioManager}) async {
    _audioManager = audioManager;
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  /// Load accessibility settings from storage
  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    _highContrastMode = _prefs!.getBool('high_contrast_mode') ?? false;
    _reducedMotion = _prefs!.getBool('reduced_motion') ?? false;
    _colorBlindFriendly = _prefs!.getBool('color_blind_friendly') ?? false;
    _soundBasedFeedback = _prefs!.getBool('sound_based_feedback') ?? false;
    _largeText = _prefs!.getBool('large_text') ?? false;
    _uiScale = _prefs!.getDouble('ui_scale') ?? 1.0;
    
    final colorBlindIndex = _prefs!.getInt('color_blind_type') ?? ColorBlindType.none.index;
    _colorBlindType = ColorBlindType.values[colorBlindIndex];
  }

  // High Contrast Mode
  bool get highContrastMode => _highContrastMode;
  Future<void> setHighContrastMode(bool enabled) async {
    _highContrastMode = enabled;
    await _prefs?.setBool('high_contrast_mode', enabled);
  }

  // Reduced Motion
  bool get reducedMotion => _reducedMotion;
  Future<void> setReducedMotion(bool enabled) async {
    _reducedMotion = enabled;
    await _prefs?.setBool('reduced_motion', enabled);
  }

  // Color Blind Friendly
  bool get colorBlindFriendly => _colorBlindFriendly;
  Future<void> setColorBlindFriendly(bool enabled) async {
    _colorBlindFriendly = enabled;
    await _prefs?.setBool('color_blind_friendly', enabled);
  }

  // Color Blind Type
  ColorBlindType get colorBlindType => _colorBlindType;
  Future<void> setColorBlindType(ColorBlindType type) async {
    _colorBlindType = type;
    await _prefs?.setInt('color_blind_type', type.index);
  }

  // Sound Based Feedback
  bool get soundBasedFeedback => _soundBasedFeedback;
  Future<void> setSoundBasedFeedback(bool enabled) async {
    _soundBasedFeedback = enabled;
    await _prefs?.setBool('sound_based_feedback', enabled);
  }

  // Large Text
  bool get largeText => _largeText;
  Future<void> setLargeText(bool enabled) async {
    _largeText = enabled;
    await _prefs?.setBool('large_text', enabled);
  }

  // UI Scale
  double get uiScale => _uiScale;
  Future<void> setUiScale(double scale) async {
    _uiScale = scale.clamp(0.8, 1.5);
    await _prefs?.setDouble('ui_scale', _uiScale);
  }

  /// Get text scale factor based on accessibility settings
  double getTextScaleFactor() {
    double scale = _uiScale;
    if (_largeText) {
      scale *= 1.2;
    }
    return scale;
  }

  /// Get animation duration multiplier based on reduced motion setting
  double getAnimationDurationMultiplier() {
    return _reducedMotion ? 0.3 : 1.0;
  }

  /// Play sound feedback for visual cues (for hearing impaired)
  Future<void> playSoundFeedback(SoundFeedbackType type) async {
    if (!_soundBasedFeedback || _audioManager == null) return;

    switch (type) {
      case SoundFeedbackType.obstacleApproaching:
        await _audioManager!.playBeep(frequency: 800, duration: 200);
        break;
      case SoundFeedbackType.powerUpAvailable:
        await _audioManager!.playBeep(frequency: 1200, duration: 150);
        break;
      case SoundFeedbackType.pulseReady:
        await _audioManager!.playBeep(frequency: 600, duration: 100);
        break;
      case SoundFeedbackType.scoreIncrement:
        await _audioManager!.playBeep(frequency: 1000, duration: 100);
        break;
      case SoundFeedbackType.dangerZone:
        await _audioManager!.playBeep(frequency: 400, duration: 300);
        break;
    }
  }

  /// Get color adjusted for color blind accessibility
  Color getAccessibleColor(Color originalColor) {
    if (!_colorBlindFriendly) return originalColor;

    switch (_colorBlindType) {
      case ColorBlindType.protanopia:
        return _adjustForProtanopia(originalColor);
      case ColorBlindType.deuteranopia:
        return _adjustForDeuteranopia(originalColor);
      case ColorBlindType.tritanopia:
        return _adjustForTritanopia(originalColor);
      case ColorBlindType.none:
        return originalColor;
    }
  }

  /// Adjust color for protanopia (red-blind)
  Color _adjustForProtanopia(Color color) {
    // Convert red elements to more distinguishable colors
    if (color.red > 200 && color.green < 100 && color.blue < 100) {
      // Red -> Orange/Yellow
      return Color.fromARGB(color.alpha, 255, 165, 0);
    }
    return color;
  }

  /// Adjust color for deuteranopia (green-blind)
  Color _adjustForDeuteranopia(Color color) {
    // Convert green elements to more distinguishable colors
    if (color.green > 200 && color.red < 100 && color.blue < 100) {
      // Green -> Blue/Cyan
      return Color.fromARGB(color.alpha, 0, 191, 255);
    }
    return color;
  }

  /// Adjust color for tritanopia (blue-blind)
  Color _adjustForTritanopia(Color color) {
    // Convert blue elements to more distinguishable colors
    if (color.blue > 200 && color.red < 100 && color.green < 100) {
      // Blue -> Purple/Magenta
      return Color.fromARGB(color.alpha, 255, 0, 255);
    }
    return color;
  }

  /// Get high contrast version of a color
  Color getHighContrastColor(Color color) {
    if (!_highContrastMode) return color;

    // Convert to high contrast by increasing saturation and brightness
    HSVColor hsv = HSVColor.fromColor(color);
    return hsv.withSaturation(1.0).withValue(1.0).toColor();
  }

  /// Check if device has accessibility features enabled
  bool hasSystemAccessibilityEnabled(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.accessibleNavigation ||
           mediaQuery.boldText ||
           mediaQuery.highContrast ||
           mediaQuery.textScaleFactor > 1.0;
  }

  /// Get semantic label for game elements
  String getSemanticLabel(GameElement element, {Map<String, dynamic>? context}) {
    switch (element) {
      case GameElement.bird:
        return 'Cyberpunk bird at ${context?['position'] ?? 'center'} of screen';
      case GameElement.obstacle:
        return 'Digital barrier obstacle ${context?['distance'] ?? 'ahead'}';
      case GameElement.powerUp:
        return '${context?['type'] ?? 'Power-up'} available for collection';
      case GameElement.score:
        return 'Current score: ${context?['score'] ?? '0'}';
      case GameElement.pulseIndicator:
        final ready = context?['ready'] ?? false;
        return ready ? 'Energy pulse ready - double tap to activate' : 'Energy pulse charging';
    }
  }
}

/// Types of color blindness
enum ColorBlindType {
  none('None', 'No color vision deficiency'),
  protanopia('Protanopia', 'Red-blind (cannot see red light)'),
  deuteranopia('Deuteranopia', 'Green-blind (cannot see green light)'),
  tritanopia('Tritanopia', 'Blue-blind (cannot see blue light)');

  const ColorBlindType(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// Types of sound feedback for visual cues
enum SoundFeedbackType {
  obstacleApproaching,
  powerUpAvailable,
  pulseReady,
  scoreIncrement,
  dangerZone,
}

/// Game elements for semantic labeling
enum GameElement {
  bird,
  obstacle,
  powerUp,
  score,
  pulseIndicator,
}