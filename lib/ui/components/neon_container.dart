import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// A reusable neon-styled container widget for consistent UI across settings tabs
class NeonContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Color? shadowColor;
  final double? borderWidth;
  final double? borderRadius;
  final double? blurRadius;
  final double? spreadRadius;
  final Color? backgroundColor;

  const NeonContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderColor,
    this.shadowColor,
    this.borderWidth,
    this.borderRadius,
    this.blurRadius,
    this.spreadRadius,
    this.backgroundColor,
  });

  /// Creates a neon container with default styling for settings tabs
  factory NeonContainer.settings({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? borderColor,
    Color? shadowColor,
  }) {
    return NeonContainer(
      key: key,
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin,
      borderColor: borderColor ?? NeonTheme.neonGreen.withOpacity(0.5),
      shadowColor: shadowColor ?? NeonTheme.neonGreen.withOpacity(0.3),
      borderWidth: 2,
      borderRadius: 15,
      blurRadius: 20,
      spreadRadius: 2,
      backgroundColor: NeonTheme.darkPurple.withOpacity(0.9),
      child: child,
    );
  }

  /// Creates a neon container with hot pink styling (for control settings)
  factory NeonContainer.hotPink({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return NeonContainer(
      key: key,
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin,
      borderColor: NeonTheme.hotPink.withOpacity(0.5),
      shadowColor: NeonTheme.hotPink.withOpacity(0.3),
      borderWidth: 2,
      borderRadius: 15,
      blurRadius: 20,
      spreadRadius: 2,
      backgroundColor: NeonTheme.darkPurple.withOpacity(0.9),
      child: child,
    );
  }

  /// Creates a neon container with electric blue styling (for accessibility settings)
  factory NeonContainer.electricBlue({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return NeonContainer(
      key: key,
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin,
      borderColor: NeonTheme.electricBlue.withOpacity(0.5),
      shadowColor: NeonTheme.electricBlue.withOpacity(0.3),
      borderWidth: 2,
      borderRadius: 15,
      blurRadius: 20,
      spreadRadius: 2,
      backgroundColor: NeonTheme.darkPurple.withOpacity(0.9),
      child: child,
    );
  }

  /// Creates a neon container with warning orange styling (for difficulty settings)
  factory NeonContainer.warningOrange({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return NeonContainer(
      key: key,
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin,
      borderColor: NeonTheme.warningOrange.withOpacity(0.5),
      shadowColor: NeonTheme.warningOrange.withOpacity(0.3),
      borderWidth: 2,
      borderRadius: 15,
      blurRadius: 20,
      spreadRadius: 2,
      backgroundColor: NeonTheme.darkPurple.withOpacity(0.9),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? NeonTheme.darkPurple.withOpacity(0.9),
        borderRadius: BorderRadius.circular(borderRadius ?? 15),
        border: Border.all(
          color: borderColor ?? NeonTheme.neonGreen.withOpacity(0.5),
          width: borderWidth ?? 2,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? NeonTheme.neonGreen.withOpacity(0.3),
            blurRadius: blurRadius ?? 20,
            spreadRadius: spreadRadius ?? 2,
          ),
        ],
      ),
      child: child,
    );
  }
}
