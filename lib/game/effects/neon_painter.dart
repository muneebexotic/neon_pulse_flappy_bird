import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter for creating neon glow effects
class NeonPainter extends CustomPainter {
  final Color color;
  final double glowIntensity;
  final double animationValue;
  final BlurStyle blurStyle;
  final double blurRadius;

  const NeonPainter({
    required this.color,
    this.glowIntensity = 1.0,
    this.animationValue = 0.0,
    this.blurStyle = BlurStyle.outer,
    this.blurRadius = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create animated glow intensity
    final animatedIntensity = glowIntensity * 
        (0.7 + 0.3 * math.sin(animationValue * 2.0));

    // Create multiple glow layers for depth
    _drawGlowLayer(canvas, size, blurRadius * 2, 0.1 * animatedIntensity);
    _drawGlowLayer(canvas, size, blurRadius * 1.5, 0.2 * animatedIntensity);
    _drawGlowLayer(canvas, size, blurRadius, 0.4 * animatedIntensity);
    
    // Draw the core bright element
    _drawCore(canvas, size);
  }

  void _drawGlowLayer(Canvas canvas, Size size, double radius, double opacity) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(blurStyle, radius);

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paint);
  }

  void _drawCore(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant NeonPainter oldDelegate) {
    return oldDelegate.color != color ||
           oldDelegate.glowIntensity != glowIntensity ||
           oldDelegate.animationValue != animationValue ||
           oldDelegate.blurStyle != blurStyle ||
           oldDelegate.blurRadius != blurRadius;
  }
}

/// Custom painter for neon text effects
class NeonTextPainter extends CustomPainter {
  final String text;
  final TextStyle textStyle;
  final Color glowColor;
  final double glowIntensity;
  final double animationValue;

  const NeonTextPainter({
    required this.text,
    required this.textStyle,
    required this.glowColor,
    this.glowIntensity = 1.0,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final animatedIntensity = glowIntensity * 
        (0.8 + 0.2 * math.sin(animationValue * 3.0));

    // Create text painter
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Center the text
    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );

    // Draw glow layers
    _drawTextGlow(canvas, textPainter, offset, 15.0, 0.1 * animatedIntensity);
    _drawTextGlow(canvas, textPainter, offset, 10.0, 0.2 * animatedIntensity);
    _drawTextGlow(canvas, textPainter, offset, 5.0, 0.4 * animatedIntensity);

    // Draw main text
    textPainter.paint(canvas, offset);
  }

  void _drawTextGlow(Canvas canvas, TextPainter textPainter, Offset offset, 
                     double blurRadius, double opacity) {
    final glowStyle = textStyle.copyWith(
      foreground: Paint()
        ..color = glowColor.withOpacity(opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, blurRadius),
    );

    final glowTextPainter = TextPainter(
      text: TextSpan(text: text, style: glowStyle),
      textDirection: TextDirection.ltr,
    );
    glowTextPainter.layout();
    glowTextPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant NeonTextPainter oldDelegate) {
    return oldDelegate.text != text ||
           oldDelegate.textStyle != textStyle ||
           oldDelegate.glowColor != glowColor ||
           oldDelegate.glowIntensity != glowIntensity ||
           oldDelegate.animationValue != animationValue;
  }
}

/// Custom painter for neon shapes (circles, lines, etc.)
class NeonShapePainter extends CustomPainter {
  final Color color;
  final double glowIntensity;
  final double animationValue;
  final ShapeType shapeType;
  final double strokeWidth;

  const NeonShapePainter({
    required this.color,
    this.glowIntensity = 1.0,
    this.animationValue = 0.0,
    this.shapeType = ShapeType.circle,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final animatedIntensity = glowIntensity * 
        (0.7 + 0.3 * math.sin(animationValue * 2.5));

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw glow layers
    _drawShapeGlow(canvas, center, radius, 15.0, 0.1 * animatedIntensity);
    _drawShapeGlow(canvas, center, radius, 10.0, 0.2 * animatedIntensity);
    _drawShapeGlow(canvas, center, radius, 5.0, 0.4 * animatedIntensity);

    // Draw main shape
    _drawMainShape(canvas, center, radius);
  }

  void _drawShapeGlow(Canvas canvas, Offset center, double radius, 
                      double blurRadius, double opacity) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, blurRadius);

    switch (shapeType) {
      case ShapeType.circle:
        canvas.drawCircle(center, radius, paint);
        break;
      case ShapeType.rectangle:
        final rect = Rect.fromCenter(center: center, width: radius * 2, height: radius * 2);
        canvas.drawRect(rect, paint);
        break;
    }
  }

  void _drawMainShape(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    switch (shapeType) {
      case ShapeType.circle:
        canvas.drawCircle(center, radius, paint);
        break;
      case ShapeType.rectangle:
        final rect = Rect.fromCenter(center: center, width: radius * 2, height: radius * 2);
        canvas.drawRect(rect, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant NeonShapePainter oldDelegate) {
    return oldDelegate.color != color ||
           oldDelegate.glowIntensity != glowIntensity ||
           oldDelegate.animationValue != animationValue ||
           oldDelegate.shapeType != shapeType ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}

enum ShapeType {
  circle,
  rectangle,
}