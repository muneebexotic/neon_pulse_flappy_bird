import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Handles all input events for the game
class InputHandler {
  // Double tap detection
  double _lastTapTime = 0.0;
  static const double doubleTapThreshold = 0.3; // 300ms for double tap
  
  // Callbacks for different input events
  VoidCallback? onSingleTap;
  VoidCallback? onDoubleTap;
  Function(Vector2)? onTapPosition;

  /// Process tap input and determine if it's single or double tap
  bool processTap(TapDownInfo info) {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final globalPos = info.eventPosition.global;
    final tapPosition = Vector2(globalPos.dx, globalPos.dy);
    
    // Notify about tap position
    onTapPosition?.call(tapPosition);
    
    // Check for double tap
    if (currentTime - _lastTapTime < doubleTapThreshold) {
      _handleDoubleTap();
    } else {
      _handleSingleTap();
    }
    
    _lastTapTime = currentTime;
    return true;
  }

  /// Handle single tap
  void _handleSingleTap() {
    onSingleTap?.call();
  }

  /// Handle double tap
  void _handleDoubleTap() {
    onDoubleTap?.call();
  }

  /// Reset input state
  void reset() {
    _lastTapTime = 0.0;
  }
}