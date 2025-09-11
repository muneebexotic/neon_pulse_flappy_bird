import 'package:flutter/material.dart';

/// Handles all input events for the game
class InputHandler {
  // Double tap detection
  double lastTapTime = 0.0;
  static const double doubleTapThreshold = 0.3; // 300ms for double tap
  
  // Callbacks for different input events
  VoidCallback? onSingleTap;
  VoidCallback? onDoubleTap;
  Function(Offset)? onTapPosition;

  /// Reset input state
  void reset() {
    lastTapTime = 0.0;
  }
}