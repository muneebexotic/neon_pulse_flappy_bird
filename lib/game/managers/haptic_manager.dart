import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages haptic feedback and vibration patterns for game events
class HapticManager {
  static final HapticManager _instance = HapticManager._internal();
  factory HapticManager() => _instance;
  HapticManager._internal();

  SharedPreferences? _prefs;
  bool _hapticEnabled = true;
  bool _vibrationEnabled = true;
  double _hapticIntensity = 1.0; // 0.0 to 1.0
  double _vibrationIntensity = 1.0; // 0.0 to 1.0
  bool _deviceSupportsVibration = false;

  /// Initialize haptic manager and check device capabilities
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _deviceSupportsVibration = await Vibration.hasVibrator() ?? false;
    await _loadSettings();
  }

  /// Load haptic settings from storage
  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    _hapticEnabled = _prefs!.getBool('haptic_enabled') ?? true;
    _vibrationEnabled = _prefs!.getBool('vibration_enabled') ?? true;
    _hapticIntensity = _prefs!.getDouble('haptic_intensity') ?? 1.0;
    _vibrationIntensity = _prefs!.getDouble('vibration_intensity') ?? 1.0;
  }

  /// Enable or disable haptic feedback
  Future<void> setHapticEnabled(bool enabled) async {
    _hapticEnabled = enabled;
    await _prefs?.setBool('haptic_enabled', enabled);
  }

  /// Enable or disable vibration
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _prefs?.setBool('vibration_enabled', enabled);
  }

  /// Set haptic intensity (0.0 to 1.0)
  Future<void> setHapticIntensity(double intensity) async {
    _hapticIntensity = intensity.clamp(0.0, 1.0);
    await _prefs?.setDouble('haptic_intensity', _hapticIntensity);
  }

  /// Set vibration intensity (0.0 to 1.0)
  Future<void> setVibrationIntensity(double intensity) async {
    _vibrationIntensity = intensity.clamp(0.0, 1.0);
    await _prefs?.setDouble('vibration_intensity', _vibrationIntensity);
  }

  /// Get haptic enabled status
  bool get hapticEnabled => _hapticEnabled;

  /// Get vibration enabled status
  bool get vibrationEnabled => _vibrationEnabled;

  /// Get haptic intensity
  double get hapticIntensity => _hapticIntensity;

  /// Get vibration intensity
  double get vibrationIntensity => _vibrationIntensity;

  /// Get device vibration support
  bool get deviceSupportsVibration => _deviceSupportsVibration;

  /// Light haptic feedback for bird jumps
  Future<void> lightImpact() async {
    if (!_hapticEnabled) return;
    
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Silently handle haptic feedback errors
    }
  }

  /// Medium haptic feedback for power-up collection
  Future<void> mediumImpact() async {
    if (!_hapticEnabled) return;
    
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Silently handle haptic feedback errors
    }
  }

  /// Heavy haptic feedback for collisions
  Future<void> heavyImpact() async {
    if (!_hapticEnabled) return;
    
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // Silently handle haptic feedback errors
    }
  }

  /// Selection haptic feedback for UI interactions
  Future<void> selectionClick() async {
    if (!_hapticEnabled) return;
    
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Silently handle haptic feedback errors
    }
  }

  /// Vibration pattern for pulse activation
  Future<void> pulseActivation() async {
    if (!_vibrationEnabled || !_deviceSupportsVibration) return;
    
    try {
      // Short-long-short pattern for pulse with intensity scaling
      final scaledPattern = _scaleVibrationPattern([0, 100, 50, 200, 50, 100]);
      await Vibration.vibrate(pattern: scaledPattern);
    } catch (e) {
      // Silently handle vibration errors
    }
  }

  /// Vibration pattern for collision
  Future<void> collisionVibration() async {
    if (!_vibrationEnabled || !_deviceSupportsVibration) return;
    
    try {
      // Strong vibration for collision with intensity scaling
      final scaledDuration = (500 * _vibrationIntensity).round();
      await Vibration.vibrate(duration: scaledDuration);
    } catch (e) {
      // Silently handle vibration errors
    }
  }

  /// Vibration pattern for power-up collection
  Future<void> powerUpVibration() async {
    if (!_vibrationEnabled || !_deviceSupportsVibration) return;
    
    try {
      // Quick double vibration for power-up with intensity scaling
      final scaledPattern = _scaleVibrationPattern([0, 80, 40, 80]);
      await Vibration.vibrate(pattern: scaledPattern);
    } catch (e) {
      // Silently handle vibration errors
    }
  }

  /// Vibration pattern for score milestone
  Future<void> scoreMilestoneVibration() async {
    if (!_vibrationEnabled || !_deviceSupportsVibration) return;
    
    try {
      // Triple vibration for milestone with intensity scaling
      final scaledPattern = _scaleVibrationPattern([0, 60, 30, 60, 30, 60]);
      await Vibration.vibrate(pattern: scaledPattern);
    } catch (e) {
      // Silently handle vibration errors
    }
  }

  /// Light vibration for UI feedback
  Future<void> uiFeedback() async {
    if (!_vibrationEnabled || !_deviceSupportsVibration) return;
    
    try {
      // Very light vibration for UI with intensity scaling
      final scaledDuration = (50 * _vibrationIntensity).round();
      await Vibration.vibrate(duration: scaledDuration);
    } catch (e) {
      // Silently handle vibration errors
    }
  }

  /// Cancel any ongoing vibration
  Future<void> cancelVibration() async {
    if (!_deviceSupportsVibration) return;
    
    try {
      await Vibration.cancel();
    } catch (e) {
      // Silently handle vibration errors
    }
  }

  /// Scale vibration pattern based on intensity
  List<int> _scaleVibrationPattern(List<int> pattern) {
    return pattern.map((duration) {
      if (duration == 0) return 0; // Keep delays as 0
      return (duration * _vibrationIntensity).round().clamp(1, 1000);
    }).toList();
  }

  /// Test haptic feedback with current intensity
  Future<void> testHapticFeedback() async {
    if (!_hapticEnabled) return;
    
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Silently handle haptic feedback errors
    }
  }

  /// Test vibration with current intensity
  Future<void> testVibration() async {
    if (!_vibrationEnabled || !_deviceSupportsVibration) return;
    
    try {
      final scaledDuration = (200 * _vibrationIntensity).round();
      await Vibration.vibrate(duration: scaledDuration);
    } catch (e) {
      // Silently handle vibration errors
    }
  }
}