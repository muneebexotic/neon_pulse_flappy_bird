import 'package:flutter/material.dart';

/// Handles all input events for the game
class InputHandler {
  // Double tap detection
  double lastTapTime = 0.0;
  static const double doubleTapThreshold = 0.3; // 300ms for double tap
  bool isWaitingForSecondTap = false;
  
  // Callbacks for different input events
  VoidCallback? onSingleTap;
  VoidCallback? onDoubleTap;
  Function(Offset)? onTapPosition;

  /// Process a tap input with immediate single tap response
  void processTap([Offset? position]) {
    // Call position callback if provided
    if (position != null && onTapPosition != null) {
      onTapPosition!(position);
    }
    
    // Always call single tap immediately for responsive gameplay
    if (onSingleTap != null) {
      onSingleTap!();
    }
    
    debugPrint('Tap processed immediately');
  }

  /// Reset input state
  void reset() {
    lastTapTime = 0.0;
    isWaitingForSecondTap = false;
  }
  
  /// Check if currently waiting for a potential second tap
  bool get waitingForSecondTap => isWaitingForSecondTap;
}