import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'animation_config.dart';

/// Manages consistent transitions and animations throughout the app
class TransitionManager {
  /// Standard easing curves for consistent animation feel
  static Duration get _defaultDuration => AnimationConfig.standard;
  static Duration get _slowDuration => AnimationConfig.medium;
  static Duration get _fastDuration => AnimationConfig.fast;
  
  static Curve get _standardEase => AnimationConfig.standardEase;
  static Curve get _fastEase => AnimationConfig.fastEase;
  static Curve get _slowEase => AnimationConfig.slowEase;

  /// Create a fade transition between screens
  static PageRouteBuilder<T> fadeTransition<T extends Object?>(
    Widget child, {
    Duration? duration,
    Curve? curve,
  }) {
    final finalDuration = duration ?? _defaultDuration;
    final finalCurve = curve ?? _standardEase;
    
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: finalDuration,
      reverseTransitionDuration: finalDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: finalCurve,
        );
        
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );
      },
    );
  }

  /// Create a slide transition from right to left
  static PageRouteBuilder<T> slideTransition<T extends Object?>(
    Widget child, {
    Duration? duration,
    Curve? curve,
    Offset begin = const Offset(1.0, 0.0),
  }) {
    final finalDuration = duration ?? _defaultDuration;
    final finalCurve = curve ?? _standardEase;
    
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: finalDuration,
      reverseTransitionDuration: finalDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: finalCurve,
        );
        
        final slideAnimation = Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).animate(curvedAnimation);
        
        return SlideTransition(
          position: slideAnimation,
          child: child,
        );
      },
    );
  }

  /// Create a scale transition with fade
  static PageRouteBuilder<T> scaleTransition<T extends Object?>(
    Widget child, {
    Duration? duration,
    Curve? curve,
    double beginScale = 0.8,
  }) {
    final finalDuration = duration ?? _defaultDuration;
    final finalCurve = curve ?? _standardEase;
    
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: finalDuration,
      reverseTransitionDuration: finalDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: finalCurve,
        );
        
        final scaleAnimation = Tween<double>(
          begin: beginScale,
          end: 1.0,
        ).animate(curvedAnimation);
        
        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Create a neon-themed transition with glow effects
  static PageRouteBuilder<T> neonTransition<T extends Object?>(
    Widget child, {
    Duration? duration,
    Color glowColor = Colors.cyan,
  }) {
    final finalDuration = duration ?? _slowDuration;
    
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: finalDuration,
      reverseTransitionDuration: finalDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: _slowEase,
        );
        
        return AnimatedBuilder(
          animation: curvedAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(curvedAnimation.value * 0.3),
                    blurRadius: 20 * curvedAnimation.value,
                    spreadRadius: 5 * curvedAnimation.value,
                  ),
                ],
              ),
              child: FadeTransition(
                opacity: curvedAnimation,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.9,
                    end: 1.0,
                  ).animate(curvedAnimation),
                  child: child,
                ),
              ),
            );
          },
          child: child,
        );
      },
    );
  }

  /// Animate a widget with neon glow effect
  static Widget neonGlow(
    Widget child, {
    Color glowColor = Colors.cyan,
    double intensity = 1.0,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return child.animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).shimmer(
      duration: duration,
      color: glowColor.withOpacity(0.3 * intensity),
    );
  }

  /// Create a pulsing animation for buttons
  static Widget pulseButton(
    Widget child, {
    Duration duration = const Duration(milliseconds: 1000),
    double scaleAmount = 0.05,
  }) {
    return child.animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).scale(
      duration: duration,
      begin: const Offset(1.0, 1.0),
      end: Offset(1.0 + scaleAmount, 1.0 + scaleAmount),
      curve: Curves.easeInOut,
    );
  }

  /// Create a floating animation for UI elements
  static Widget floatingAnimation(
    Widget child, {
    Duration duration = const Duration(milliseconds: 2000),
    double offset = 10.0,
  }) {
    return child.animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).moveY(
      duration: duration,
      begin: 0,
      end: -offset,
      curve: Curves.easeInOut,
    );
  }

  /// Create a typing animation for text
  static Widget typewriterText(
    String text, {
    Duration duration = const Duration(milliseconds: 50),
    TextStyle? style,
  }) {
    // Simplified text animation without typewriter effect
    return Text(text, style: style).animate().fadeIn(
      duration: duration * text.length,
    );
  }

  /// Create a slide-in animation for list items
  static Widget slideInListItem(
    Widget child, {
    int index = 0,
    Duration delay = const Duration(milliseconds: 100),
    Duration? duration,
  }) {
    final finalDuration = duration ?? _defaultDuration;
    
    return child.animate(
      delay: delay * index,
    ).slideX(
      duration: finalDuration,
      begin: 1.0,
      end: 0.0,
      curve: _standardEase,
    ).fadeIn(
      duration: finalDuration,
      curve: _standardEase,
    );
  }

  /// Create a staggered animation for multiple children
  static List<Widget> staggeredChildren(
    List<Widget> children, {
    Duration staggerDelay = const Duration(milliseconds: 100),
    Duration? duration,
  }) {
    final finalDuration = duration ?? _defaultDuration;
    
    return children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      
      return child.animate(
        delay: staggerDelay * index,
      ).fadeIn(
        duration: finalDuration,
        curve: _standardEase,
      ).slideY(
        duration: finalDuration,
        begin: 0.3,
        end: 0.0,
        curve: _standardEase,
      );
    }).toList();
  }

  /// Create a bounce animation for success feedback
  static Widget bounceSuccess(Widget child) {
    return child.animate().scale(
      duration: 200.ms,
      curve: Curves.elasticOut,
      begin: const Offset(1.0, 1.0),
      end: const Offset(1.2, 1.2),
    ).then().scale(
      duration: 300.ms,
      curve: Curves.elasticOut,
      begin: const Offset(1.2, 1.2),
      end: const Offset(1.0, 1.0),
    );
  }

  /// Create a shake animation for error feedback
  static Widget shakeError(Widget child) {
    return child.animate().shake(
      duration: 500.ms,
      hz: 4,
      offset: const Offset(5, 0),
    );
  }

  /// Create a loading shimmer effect
  static Widget loadingShimmer(
    Widget child, {
    Duration duration = const Duration(milliseconds: 1500),
    Color baseColor = const Color(0xFF2D2D2D),
    Color highlightColor = Colors.cyan,
  }) {
    return child.animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(
      duration: duration,
      color: highlightColor.withOpacity(0.3),
    );
  }

  /// Get standard animation durations
  static Duration get fastDuration => AnimationConfig.fast;
  static Duration get standardDuration => AnimationConfig.standard;
  static Duration get slowDuration => AnimationConfig.slow;
  
  /// Get standard animation curves
  static Curve get fastEase => AnimationConfig.fastEase;
  static Curve get standardEase => AnimationConfig.standardEase;
  static Curve get slowEase => AnimationConfig.slowEase;
}