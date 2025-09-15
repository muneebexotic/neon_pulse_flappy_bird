import 'package:flutter/material.dart';

/// Centralized animation configuration for consistent timing and easing
class AnimationConfig {
  // Private constructor to prevent instantiation
  AnimationConfig._();

  // ============================================================================
  // DURATION CONSTANTS
  // ============================================================================
  
  /// Ultra-fast animations (UI feedback, micro-interactions)
  static const Duration ultraFast = Duration(milliseconds: 100);
  
  /// Fast animations (button presses, quick transitions)
  static const Duration fast = Duration(milliseconds: 150);
  
  /// Standard animations (most UI transitions)
  static const Duration standard = Duration(milliseconds: 300);
  
  /// Medium animations (screen transitions, complex animations)
  static const Duration medium = Duration(milliseconds: 500);
  
  /// Slow animations (splash screen, dramatic effects)
  static const Duration slow = Duration(milliseconds: 800);
  
  /// Very slow animations (loading screens, major transitions)
  static const Duration verySlow = Duration(milliseconds: 1200);

  // ============================================================================
  // EASING CURVES
  // ============================================================================
  
  /// Standard easing for most animations
  static const Curve standardEase = Curves.easeOutCubic;
  
  /// Fast easing for quick interactions
  static const Curve fastEase = Curves.easeOutQuart;
  
  /// Slow easing for dramatic effects
  static const Curve slowEase = Curves.easeInOutCubic;
  
  /// Bounce easing for playful interactions
  static const Curve bounceEase = Curves.elasticOut;
  
  /// Sharp easing for immediate feedback
  static const Curve sharpEase = Curves.easeOutExpo;
  
  /// Smooth easing for continuous animations
  static const Curve smoothEase = Curves.easeInOutSine;

  // ============================================================================
  // GAME-SPECIFIC ANIMATIONS
  // ============================================================================
  
  /// Bird jump animation timing
  static const Duration birdJump = Duration(milliseconds: 200);
  
  /// Pulse effect duration
  static const Duration pulseEffect = Duration(milliseconds: 800);
  
  /// Particle animation duration
  static const Duration particleLife = Duration(milliseconds: 2000);
  
  /// Power-up collection animation
  static const Duration powerUpCollection = Duration(milliseconds: 400);
  
  /// Obstacle spawn animation
  static const Duration obstacleSpawn = Duration(milliseconds: 300);
  
  /// Game over transition
  static const Duration gameOverTransition = Duration(milliseconds: 1000);

  // ============================================================================
  // UI ANIMATIONS
  // ============================================================================
  
  /// Menu button hover/press animation
  static const Duration buttonPress = ultraFast;
  
  /// Screen transition duration
  static const Duration screenTransition = standard;
  
  /// Modal/dialog appearance
  static const Duration modalAppear = medium;
  
  /// Loading indicator animation
  static const Duration loadingIndicator = Duration(milliseconds: 1500);
  
  /// Notification appearance/disappearance
  static const Duration notification = medium;
  
  /// Tooltip appearance
  static const Duration tooltip = fast;

  // ============================================================================
  // NEON EFFECTS
  // ============================================================================
  
  /// Neon glow pulse duration
  static const Duration neonPulse = Duration(milliseconds: 1500);
  
  /// Neon trail fade duration
  static const Duration neonTrailFade = Duration(milliseconds: 800);
  
  /// Neon text shimmer duration
  static const Duration neonShimmer = Duration(milliseconds: 2000);
  
  /// Neon button glow animation
  static const Duration neonButtonGlow = Duration(milliseconds: 1000);

  // ============================================================================
  // STAGGER DELAYS
  // ============================================================================
  
  /// Delay between staggered list items
  static const Duration staggerDelay = Duration(milliseconds: 100);
  
  /// Delay between menu button animations
  static const Duration menuButtonDelay = Duration(milliseconds: 150);
  
  /// Delay between achievement notifications
  static const Duration achievementDelay = Duration(milliseconds: 300);

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Get animation duration based on complexity
  static Duration getDurationForComplexity(AnimationComplexity complexity) {
    switch (complexity) {
      case AnimationComplexity.simple:
        return fast;
      case AnimationComplexity.medium:
        return standard;
      case AnimationComplexity.complex:
        return medium;
      case AnimationComplexity.veryComplex:
        return slow;
    }
  }
  
  /// Get easing curve based on animation type
  static Curve getCurveForType(AnimationType type) {
    switch (type) {
      case AnimationType.entrance:
        return standardEase;
      case AnimationType.exit:
        return fastEase;
      case AnimationType.emphasis:
        return bounceEase;
      case AnimationType.transition:
        return smoothEase;
      case AnimationType.feedback:
        return sharpEase;
    }
  }
  
  /// Create a staggered delay for index-based animations
  static Duration getStaggeredDelay(int index, {Duration baseDelay = staggerDelay}) {
    return baseDelay * index;
  }
  
  /// Get responsive duration based on screen size
  static Duration getResponsiveDuration(BuildContext context, Duration baseDuration) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Adjust animation speed based on screen size
    if (screenWidth < 600) {
      // Mobile - slightly faster animations
      return Duration(milliseconds: (baseDuration.inMilliseconds * 0.8).round());
    } else if (screenWidth > 1200) {
      // Desktop - slightly slower animations
      return Duration(milliseconds: (baseDuration.inMilliseconds * 1.2).round());
    } else {
      // Tablet - standard duration
      return baseDuration;
    }
  }
  
  /// Create a curved animation with standard settings
  static CurvedAnimation createStandardCurvedAnimation(
    AnimationController controller, {
    Curve curve = standardEase,
  }) {
    return CurvedAnimation(
      parent: controller,
      curve: curve,
    );
  }
  
  /// Create a tween animation with standard settings
  static Animation<T> createTweenAnimation<T>(
    AnimationController controller,
    T begin,
    T end, {
    Curve curve = standardEase,
  }) {
    return Tween<T>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }
}

/// Animation complexity levels for duration selection
enum AnimationComplexity {
  simple,
  medium,
  complex,
  veryComplex,
}

/// Animation types for curve selection
enum AnimationType {
  entrance,
  exit,
  emphasis,
  transition,
  feedback,
}

/// Predefined animation configurations for common use cases
class AnimationPresets {
  AnimationPresets._();
  
  /// Fade in animation configuration
  static const fadeIn = AnimationPreset(
    duration: AnimationConfig.standard,
    curve: AnimationConfig.standardEase,
  );
  
  /// Slide in from right configuration
  static const slideInRight = AnimationPreset(
    duration: AnimationConfig.standard,
    curve: AnimationConfig.standardEase,
  );
  
  /// Scale up animation configuration
  static const scaleUp = AnimationPreset(
    duration: AnimationConfig.medium,
    curve: AnimationConfig.bounceEase,
  );
  
  /// Button press feedback configuration
  static const buttonPress = AnimationPreset(
    duration: AnimationConfig.ultraFast,
    curve: AnimationConfig.sharpEase,
  );
  
  /// Loading pulse configuration
  static const loadingPulse = AnimationPreset(
    duration: AnimationConfig.loadingIndicator,
    curve: AnimationConfig.smoothEase,
  );
  
  /// Neon glow configuration
  static const neonGlow = AnimationPreset(
    duration: AnimationConfig.neonPulse,
    curve: AnimationConfig.smoothEase,
  );
}

/// Animation preset data class
class AnimationPreset {
  final Duration duration;
  final Curve curve;
  
  const AnimationPreset({
    required this.duration,
    required this.curve,
  });
}