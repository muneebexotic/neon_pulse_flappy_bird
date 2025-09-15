import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../components/pulse_effect.dart';
import '../components/bird.dart';
import '../managers/obstacle_manager.dart';
import '../managers/haptic_manager.dart';
import '../managers/accessibility_manager.dart';
import '../effects/neon_colors.dart';
import '../neon_pulse_game.dart';

/// Manages the pulse mechanic system including cooldown, effects, and collision detection
class PulseManager extends Component {
  // Pulse mechanic constants
  static const double pulseCooldownDuration = 5.0; // 5 seconds cooldown
  static const double pulseRadius = 120.0; // Pulse effect radius
  static const double pulseAnimationDuration = 0.8; // Animation duration
  static const double obstacleDisableDuration = 2.0; // How long obstacles stay disabled
  
  // Pulse state
  bool isPulseReady = true;
  double cooldownTimer = 0.0;
  bool isPulseActive = false;
  
  // Visual indicators
  double pulseChargeGlow = 1.0; // Glow intensity for ready indicator
  double glowAnimationTime = 0.0;
  
  // References to other game components
  late Bird bird;
  late ObstacleManager obstacleManager;
  
  // Current active pulse effect
  PulseEffect? activePulseEffect;
  
  // Usage tracking
  int totalPulseUsage = 0;
  
  PulseManager({required this.bird, required this.obstacleManager});
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Check if game is paused - don't update if paused
    final game = findGame() as NeonPulseGame?;
    if (game != null && game.gameState.isPaused) {
      return;
    }
    
    // Update glow animation time
    glowAnimationTime += dt;
    
    // Update cooldown timer
    if (!isPulseReady) {
      cooldownTimer -= dt;
      
      if (cooldownTimer <= 0.0) {
        _resetPulseCooldown();
      }
    }
    
    // Update pulse charge glow effect
    _updatePulseChargeGlow(dt);
    
    // Update active pulse effect
    if (activePulseEffect != null && !activePulseEffect!.active) {
      activePulseEffect = null;
      isPulseActive = false;
    }
  }
  
  /// Attempt to activate the pulse mechanic
  bool tryActivatePulse() {
    if (!isPulseReady || isPulseActive) {
      debugPrint('Pulse not ready - Cooldown: ${cooldownTimer.toStringAsFixed(1)}s');
      return false;
    }
    
    _activatePulse();
    return true;
  }
  
  /// Activate the pulse effect
  void _activatePulse() {
    isPulseReady = false;
    isPulseActive = true;
    cooldownTimer = pulseCooldownDuration;
    
    // Add haptic feedback for pulse activation
    HapticManager().mediumImpact();
    HapticManager().pulseActivation();
    
    // Add accessibility sound feedback
    AccessibilityManager().playSoundFeedback(SoundFeedbackType.pulseReady);
    
    // Track pulse usage
    totalPulseUsage++;
    
    // Get pulse center position (bird's position)
    final pulseCenter = Vector2(
      bird.position.x + bird.size.x / 2,
      bird.position.y + bird.size.y / 2,
    );
    
    // Create pulse visual effect
    activePulseEffect = PulseEffect(
      center: pulseCenter,
      maxRadius: pulseRadius,
      duration: pulseAnimationDuration,
      pulseColor: NeonColors.electricBlue,
    );
    
    // Add pulse effect to game
    parent?.add(activePulseEffect!);
    activePulseEffect!.activate();
    
    // Disable obstacles within pulse range
    obstacleManager.disableObstaclesInRange(
      pulseCenter,
      pulseRadius,
      obstacleDisableDuration,
    );
    
    debugPrint('Pulse activated at position: $pulseCenter (Total usage: $totalPulseUsage)');
  }
  
  /// Reset pulse cooldown
  void _resetPulseCooldown() {
    isPulseReady = true;
    cooldownTimer = 0.0;
    pulseChargeGlow = 1.0;
    debugPrint('Pulse ready!');
  }
  
  /// Update pulse charge glow effect
  void _updatePulseChargeGlow(double dt) {
    if (isPulseReady) {
      // Pulsing glow when ready
      pulseChargeGlow = 0.6 + 0.4 * math.sin(glowAnimationTime * 3.0);
    } else {
      // Dimmed glow during cooldown
      final cooldownProgress = (pulseCooldownDuration - cooldownTimer) / pulseCooldownDuration;
      pulseChargeGlow = 0.2 + (0.4 * cooldownProgress);
    }
  }
  
  /// Get pulse charge indicator color for bird rendering
  Color getPulseChargeColor() {
    if (isPulseReady) {
      return NeonColors.electricBlue.withOpacity(pulseChargeGlow);
    } else {
      return NeonColors.uiDisabled.withOpacity(pulseChargeGlow);
    }
  }
  
  /// Get pulse charge glow intensity for bird rendering
  double getPulseChargeGlow() {
    return pulseChargeGlow;
  }
  
  /// Check if pulse is currently ready to use
  bool get pulseReady => isPulseReady;
  
  /// Get remaining cooldown time
  double get remainingCooldown => math.max(0.0, cooldownTimer);
  
  /// Get cooldown progress (0.0 = ready, 1.0 = just used)
  double get cooldownProgress {
    if (isPulseReady) return 0.0;
    return (pulseCooldownDuration - cooldownTimer) / pulseCooldownDuration;
  }
  
  /// Check if pulse effect is currently active
  bool get pulseActive => isPulseActive;
  
  /// Reset pulse manager state (for game restart)
  void reset() {
    isPulseReady = true;
    cooldownTimer = 0.0;
    isPulseActive = false;
    pulseChargeGlow = 1.0;
    glowAnimationTime = 0.0;
    
    // Reset usage tracking for new game
    totalPulseUsage = 0;
    
    // Remove active pulse effect if any
    if (activePulseEffect != null) {
      activePulseEffect!.removeFromParent();
      activePulseEffect = null;
    }
    
    debugPrint('Pulse manager reset');
  }
  
  /// Get pulse status for UI display
  String getPulseStatusText() {
    if (isPulseReady) {
      return 'PULSE READY';
    } else {
      return 'COOLDOWN: ${remainingCooldown.toStringAsFixed(1)}s';
    }
  }
  
  /// Check if a point would be affected by the current pulse
  bool wouldAffectPoint(Vector2 point) {
    if (activePulseEffect == null || !activePulseEffect!.active) {
      return false;
    }
    
    return activePulseEffect!.containsPoint(point);
  }
  
  /// Get current pulse effect radius (for debugging/visualization)
  double get currentPulseRadius {
    if (activePulseEffect == null || !activePulseEffect!.active) {
      return 0.0;
    }
    
    return activePulseEffect!.currentRadius;
  }
  
  /// Get total pulse usage for this game session
  int getTotalPulseUsage() => totalPulseUsage;
}