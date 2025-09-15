import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Manages haptic feedback and vibration patterns for game events
class HapticManager {
  static final HapticManager _instance = HapticManager._internal();
  factory HapticManager() => _instance;
  HapticManager._internal();

  bool _hapticEnabled = true;
  bool _vibrationEnabled = true;
  bool _deviceSupportsVibration = false;

  /// Initialize haptic manager and check device capabilities
  Future<void> initialize() async {
    _deviceSupportsVibration = await Vibration.hasVibrator() ?? false;
  }

  /// Enable or disable haptic feedback
  void setHapticEnabled(bool enabled) {
    _hapticEnabled = enabled;
  }

  /// Enable or disable vibration
  void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
  }

  /// Get haptic enabled status
  bool get hapticEnabled => _hapticEnabled;

  /// Get vibration enabled status
  bool get vibrationEnabled => _vibrationEnabled;

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
      // Short-long-short pattern for pulse
      await Vibration.vibrate(pattern: [0, 100, 50, 200, 50, 100]);
    } catch (e) {
      // Silently handle vibration errors
    }
  }

  /// Vibration pattern for collision
  Future<void> collisionVibration() async {
    if (!_vibrationEnabled || !_deviceSupportsVibration) return;
    
    try {
      // Strong vibration for collision
      await Vibration.vibrate(duration: 500);
    } catch (e) {
      // Silently handle vibration errors
    }
  }

  /// Vibration pattern for power-up collection
  Future<void> powerUpVibration() async {
    if (!_vibrationEnabled || !_deviceSupportsVibration) return;
    
    try {
      // Quick double vibration for power-up
      await Vibration.vibrate(pattern: [0, 80, 40, 80]);
    } catch (e) {
      // Silently handle vibration errors
    }
  }

  /// Vibration pattern for score milestone
  Future<void> scoreMilestoneVibration() async {
    if (!_vibrationEnabled || !_deviceSupportsVibration) return;
    
    try {
      // Triple vibration for milestone
      await Vibration.vibrate(pattern: [0, 60, 30, 60, 30, 60]);
    } catch (e) {
      // Silently handle vibration errors
    }
  }

  /// Light vibration for UI feedback
  Future<void> uiFeedback() async {
    if (!_vibrationEnabled || !_deviceSupportsVibration) return;
    
    try {
      // Very light vibration for UI
      await Vibration.vibrate(duration: 50);
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
}