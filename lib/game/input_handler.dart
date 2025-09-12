import 'package:flutter/material.dart';

/// Handles all input events for the game
class InputHandler {
  // Settings-based input configuration
  double _tapSensitivity;
  double _doubleTapTiming;
  
  // Double tap detection
  double lastTapTime = 0.0;
  bool isWaitingForSecondTap = false;
  
  // Callbacks for different input events
  VoidCallback? onSingleTap;
  VoidCallback? onDoubleTap;
  Function(Offset)? onTapPosition;
  
  /// Constructor with configurable settings
  InputHandler({
    double tapSensitivity = 1.0,
    double doubleTapTiming = 300.0,
  }) : _tapSensitivity = tapSensitivity,
       _doubleTapTiming = doubleTapTiming;

  /// Process a tap input with configurable sensitivity and double-tap detection
  void processTap([Offset? position]) {
    final currentTime = DateTime.now().millisecondsSinceEpoch.toDouble();
    
    // Call position callback if provided
    if (position != null && onTapPosition != null) {
      onTapPosition!(position);
    }
    
    // Check for double tap based on settings
    if (lastTapTime > 0 && (currentTime - lastTapTime) <= _doubleTapTiming) {
      // Double tap detected
      if (onDoubleTap != null) {
        onDoubleTap!();
      }
      lastTapTime = 0.0; // Reset to prevent triple tap
      isWaitingForSecondTap = false;
      debugPrint('Double tap detected (${currentTime - lastTapTime}ms)');
      return;
    }
    
    // Single tap - apply sensitivity (for future use in pressure-sensitive devices)
    if (onSingleTap != null) {
      onSingleTap!();
    }
    
    lastTapTime = currentTime;
    isWaitingForSecondTap = true;
    
    debugPrint('Single tap processed (sensitivity: $_tapSensitivity)');
  }

  /// Reset input state
  void reset() {
    lastTapTime = 0.0;
    isWaitingForSecondTap = false;
  }
  
  /// Update input settings from settings manager
  void updateSettings({
    required double tapSensitivity,
    required double doubleTapTiming,
  }) {
    _tapSensitivity = tapSensitivity;
    _doubleTapTiming = doubleTapTiming;
    debugPrint('Input settings updated - Sensitivity: $_tapSensitivity, Double-tap timing: ${_doubleTapTiming}ms');
  }
  
  /// Get current double-tap timing threshold
  double get doubleTapThreshold => _doubleTapTiming / 1000.0; // Convert to seconds
  
  /// Get current tap sensitivity
  double get tapSensitivity => _tapSensitivity;
  
  /// Check if currently waiting for a potential second tap
  bool get waitingForSecondTap => isWaitingForSecondTap;
}