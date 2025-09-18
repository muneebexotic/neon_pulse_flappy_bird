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
  bool _soundBasedFeedback = false;

  /// Initialize accessibility manager
  Future<void> initialize({AudioManager? audioManager}) async {
    _audioManager = audioManager;
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  /// Load accessibility settings from storage
  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    _soundBasedFeedback = _prefs!.getBool('sound_based_feedback') ?? false;
  }

  // Sound Based Feedback
  bool get soundBasedFeedback => _soundBasedFeedback;
  Future<void> setSoundBasedFeedback(bool enabled) async {
    _soundBasedFeedback = enabled;
    await _prefs?.setBool('sound_based_feedback', enabled);
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

}

/// Types of sound feedback for visual cues
enum SoundFeedbackType {
  obstacleApproaching,
  powerUpAvailable,
  pulseReady,
  scoreIncrement,
  dangerZone,
}