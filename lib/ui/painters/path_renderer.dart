import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../models/progression_path_models.dart';
import '../../game/effects/particle_system.dart';
import '../../controllers/progression_performance_controller.dart';

/// Custom painter for rendering neon progression paths with glow effects
class PathRenderer extends CustomPainter {
  final List<PathSegment> pathSegments;
  final List<EnergyFlowParticle> energyParticles;
  final double animationProgress;
  final bool enableGlowEffects;
  final double glowIntensity;
  final Color backgroundColor;
  final ProgressionPerformanceController? performanceController;
  
  // Animation and visual state
  final double scanLinePosition;
  final bool showScanLine;
  final double pulsePhase;
  
  // Performance settings
  final bool enableAntiAliasing;
  final double qualityScale;
  
  // Viewport culling
  Rect? _currentViewport;

  PathRenderer({
    required this.pathSegments,
    this.energyParticles = const [],
    this.animationProgress = 1.0,
    this.enableGlowEffects = true,
    this.glowIntensity = 1.0,
    this.backgroundColor = const Color(0xFF0A0A0A),
    this.scanLinePosition = 0.0,
    this.showScanLine = false,
    this.pulsePhase = 0.0,
    this.enableAntiAliasing = true,
    this.qualityScale = 1.0,
    this.performanceController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Update viewport for culling
    _currentViewport = Rect.fromLTWH(0, 0, size.width, size.height);
    performanceController?.updateViewport(_currentViewport!);
    
    // Get optimized render settings
    final renderSettings = performanceController?.getOptimizedRenderSettings() ?? 
        PathRenderSettings(
          enableGlowEffects: enableGlowEffects,
          glowIntensity: glowIntensity,
          enableAntiAliasing: enableAntiAliasing,
          qualityScale: qualityScale,
          enableBatching: false,
        );

    // Set up canvas for high-quality rendering
    if (renderSettings.enableAntiAliasing) {
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    // Draw background grid if needed (skip if effects are reduced)
    if (!(performanceController?.areEffectsReduced ?? false)) {
      _drawBackgroundGrid(canvas, size, renderSettings);
    }

    // Draw path segments with viewport culling
    final sortedSegments = _sortSegmentsByPriority();
    final visibleSegments = _cullSegments(sortedSegments);
    
    for (final segment in visibleSegments) {
      _drawPathSegment(canvas, size, segment, renderSettings);
    }

    // Draw energy flow particles with culling
    _drawEnergyParticles(canvas, size, renderSettings);

    // Draw scan line reveal effect
    if (showScanLine && renderSettings.enableGlowEffects) {
      _drawScanLine(canvas, size, renderSettings);
    }
  }

  /// Sort segments to draw main path first, then branches by priority
  List<PathSegment> _sortSegmentsByPriority() {
    final segments = List<PathSegment>.from(pathSegments);
    segments.sort((a, b) {
      if (a.isMainPath && !b.isMainPath) return -1;
      if (!a.isMainPath && b.isMainPath) return 1;
      return 0; // Keep original order for same priority
    });
    return segments;
  }

  /// Cull segments that are not visible in the current viewport
  List<PathSegment> _cullSegments(List<PathSegment> segments) {
    if (performanceController == null || !performanceController!.isViewportCullingEnabled) {
      return segments;
    }

    return segments.where((segment) => 
        performanceController!.isSegmentVisible(segment)).toList();
  }

  /// Draw subtle background grid for cyberpunk atmosphere
  void _drawBackgroundGrid(Canvas canvas, Size size, PathRenderSettings settings) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1A1A2E).withOpacity(0.3 * settings.qualityScale)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const gridSpacing = 40.0;
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  /// Draw a single path segment with neon effects
  void _drawPathSegment(Canvas canvas, Size size, PathSegment segment, PathRenderSettings settings) {
    if (segment.pathPoints.length < 2) return;

    final path = _createPathFromPoints(segment.pathPoints);
    final completedPath = _createCompletedPath(segment);
    
    // Draw base path (dim)
    _drawBasePath(canvas, path, segment, settings);
    
    // Draw completed portion with full glow
    if (segment.completionPercentage > 0) {
      _drawCompletedPath(canvas, completedPath, segment, settings);
    }
    
    // Draw pulsing animation on active segments (skip if effects reduced)
    if (segment.completionPercentage > 0 && 
        segment.completionPercentage < 1.0 && 
        settings.enableGlowEffects) {
      _drawPulsingEffect(canvas, completedPath, segment, settings);
    }
  }

  /// Create Flutter Path from Vector2 points
  Path _createPathFromPoints(List<Vector2> points) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points.first.x, points.first.y);
    
    // Create smooth curves using quadratic bezier curves
    for (int i = 1; i < points.length; i++) {
      if (i == points.length - 1) {
        // Last point - draw straight line
        path.lineTo(points[i].x, points[i].y);
      } else {
        // Create smooth curve to next point
        final current = points[i];
        final next = points[i + 1];
        final controlPoint = Vector2(
          (current.x + next.x) / 2,
          (current.y + next.y) / 2,
        );
        path.quadraticBezierTo(
          current.x, current.y,
          controlPoint.x, controlPoint.y,
        );
      }
    }
    
    return path;
  }

  /// Create path representing completed portion
  Path _createCompletedPath(PathSegment segment) {
    if (segment.completionPercentage <= 0 || segment.pathPoints.length < 2) {
      return Path();
    }

    final completedPoints = _getCompletedPathPoints(segment);
    return _createPathFromPoints(completedPoints);
  }

  /// Get points representing completed portion of path
  List<Vector2> _getCompletedPathPoints(PathSegment segment) {
    if (segment.completionPercentage >= 1.0) {
      return segment.pathPoints;
    }

    final completedPoints = <Vector2>[];
    final targetLength = segment.pathLength * segment.completionPercentage;
    
    double currentLength = 0.0;
    completedPoints.add(segment.pathPoints.first);
    
    for (int i = 1; i < segment.pathPoints.length; i++) {
      final segmentLength = segment.pathPoints[i].distanceTo(segment.pathPoints[i - 1]);
      
      if (currentLength + segmentLength <= targetLength) {
        // Include entire segment
        completedPoints.add(segment.pathPoints[i]);
        currentLength += segmentLength;
      } else {
        // Include partial segment
        final remainingLength = targetLength - currentLength;
        final ratio = remainingLength / segmentLength;
        final partialPoint = Vector2(
          segment.pathPoints[i - 1].x + (segment.pathPoints[i].x - segment.pathPoints[i - 1].x) * ratio,
          segment.pathPoints[i - 1].y + (segment.pathPoints[i].y - segment.pathPoints[i - 1].y) * ratio,
        );
        completedPoints.add(partialPoint);
        break;
      }
    }
    
    return completedPoints;
  }

  /// Draw base path with dim appearance
  void _drawBasePath(Canvas canvas, Path path, PathSegment segment, PathRenderSettings settings) {
    final baseColor = segment.neonColor.withOpacity(0.2 * settings.qualityScale);
    
    // Draw path stroke
    final strokePaint = Paint()
      ..color = baseColor
      ..strokeWidth = segment.width * settings.qualityScale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);
    
    // Add subtle glow if enabled
    if (settings.enableGlowEffects && settings.qualityScale > 0.5) {
      final glowPaint = Paint()
        ..color = baseColor.withOpacity(0.1 * settings.glowIntensity)
        ..strokeWidth = segment.width * 3 * settings.qualityScale
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, segment.width * settings.qualityScale);

      canvas.drawPath(path, glowPaint);
    }
  }

  /// Draw completed path with full neon glow
  void _drawCompletedPath(Canvas canvas, Path path, PathSegment segment, PathRenderSettings settings) {
    final neonColor = segment.neonColor;
    
    // Draw multiple glow layers for intense neon effect
    if (settings.enableGlowEffects) {
      _drawNeonGlowLayers(canvas, path, segment, neonColor, settings);
    }
    
    // Draw core path
    final corePaint = Paint()
      ..color = neonColor
      ..strokeWidth = segment.width * settings.qualityScale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, corePaint);
  }

  /// Draw multiple glow layers for neon effect
  void _drawNeonGlowLayers(Canvas canvas, Path path, PathSegment segment, Color neonColor, PathRenderSettings settings) {
    // Reduce glow layers for better performance on lower quality settings
    final layerCount = settings.qualityScale > 0.7 ? 3 : (settings.qualityScale > 0.4 ? 2 : 1);
    
    final glowLayers = [
      // Outer glow
      (width: segment.width * 8, opacity: 0.1, blur: segment.width * 2),
      // Middle glow
      (width: segment.width * 4, opacity: 0.2, blur: segment.width * 1.5),
      // Inner glow
      (width: segment.width * 2, opacity: 0.3, blur: segment.width),
    ].take(layerCount).toList();

    for (final layer in glowLayers) {
      final glowPaint = Paint()
        ..color = neonColor.withOpacity(layer.opacity * settings.glowIntensity * settings.qualityScale)
        ..strokeWidth = layer.width * settings.qualityScale
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, layer.blur * settings.qualityScale);

      canvas.drawPath(path, glowPaint);
    }
  }

  /// Draw pulsing effect on active path segments
  void _drawPulsingEffect(Canvas canvas, Path path, PathSegment segment, PathRenderSettings settings) {
    if (!settings.enableGlowEffects || settings.qualityScale < 0.5) return;

    final pulseIntensity = (math.sin(pulsePhase * 2 * math.pi) * 0.5 + 0.5);
    final pulseColor = segment.neonColor.withOpacity(0.4 * pulseIntensity * settings.glowIntensity);
    
    final pulsePaint = Paint()
      ..color = pulseColor
      ..strokeWidth = segment.width * 3 * settings.qualityScale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, segment.width * 1.5 * settings.qualityScale);

    canvas.drawPath(path, pulsePaint);
  }

  /// Draw energy flow particles along completed paths
  void _drawEnergyParticles(Canvas canvas, Size size, PathRenderSettings settings) {
    if (!settings.enableGlowEffects || energyParticles.isEmpty) return;

    // Cull particles outside viewport for performance
    final visibleParticles = _cullParticles(energyParticles);

    for (final particle in visibleParticles) {
      _drawEnergyParticle(canvas, particle, settings);
    }
  }

  /// Cull particles that are not visible in the current viewport
  List<EnergyFlowParticle> _cullParticles(List<EnergyFlowParticle> particles) {
    if (_currentViewport == null || 
        performanceController == null || 
        !performanceController!.isViewportCullingEnabled) {
      return particles;
    }

    final buffer = 50.0; // Buffer around viewport
    final expandedViewport = _currentViewport!.inflate(buffer);

    return particles.where((particle) => 
        expandedViewport.contains(Offset(particle.position.x, particle.position.y))).toList();
  }

  /// Draw individual energy particle
  void _drawEnergyParticle(Canvas canvas, EnergyFlowParticle particle, PathRenderSettings settings) {
    final position = Offset(particle.position.x, particle.position.y);
    final size = particle.size * settings.qualityScale;
    final alpha = particle.alpha * settings.qualityScale;
    
    // Draw particle glow (skip if effects reduced)
    if (settings.enableGlowEffects) {
      final glowPaint = Paint()
        ..color = particle.color.withOpacity(alpha * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, size * 2);

      canvas.drawCircle(position, size * 2, glowPaint);
    }
    
    // Draw particle core
    final corePaint = Paint()
      ..color = particle.color.withOpacity(alpha)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, size, corePaint);
    
    // Draw particle trail if moving fast and effects enabled
    if (particle.velocity.length > 50.0 && settings.enableGlowEffects) {
      _drawParticleTrail(canvas, particle, settings);
    }
  }

  /// Draw trail behind fast-moving particles
  void _drawParticleTrail(Canvas canvas, EnergyFlowParticle particle, PathRenderSettings settings) {
    final trailLength = math.min(particle.velocity.length * 0.1, 20.0 * settings.qualityScale);
    final trailDirection = particle.velocity.normalized() * -trailLength;
    
    final trailStart = particle.position;
    final trailEnd = particle.position + trailDirection;
    
    final trailPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(trailStart.x, trailStart.y),
        Offset(trailEnd.x, trailEnd.y),
        [
          particle.color.withOpacity(particle.alpha * 0.8 * settings.qualityScale),
          particle.color.withOpacity(0.0),
        ],
      )
      ..strokeWidth = particle.size * 0.5 * settings.qualityScale
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(trailStart.x, trailStart.y),
      Offset(trailEnd.x, trailEnd.y),
      trailPaint,
    );
  }

  /// Draw scan line reveal effect
  void _drawScanLine(Canvas canvas, Size size, PathRenderSettings settings) {
    if (!settings.enableGlowEffects) return;

    final scanY = size.height * scanLinePosition;
    
    // Draw scan line
    final scanPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.8 * settings.qualityScale)
      ..strokeWidth = 2.0 * settings.qualityScale
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, scanY),
      Offset(size.width, scanY),
      scanPaint,
    );
    
    // Draw scan line glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.3 * settings.qualityScale)
      ..strokeWidth = 8.0 * settings.qualityScale
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 4.0 * settings.qualityScale);

    canvas.drawLine(
      Offset(0, scanY),
      Offset(size.width, scanY),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant PathRenderer oldDelegate) {
    return pathSegments != oldDelegate.pathSegments ||
           energyParticles != oldDelegate.energyParticles ||
           animationProgress != oldDelegate.animationProgress ||
           scanLinePosition != oldDelegate.scanLinePosition ||
           pulsePhase != oldDelegate.pulsePhase ||
           glowIntensity != oldDelegate.glowIntensity ||
           qualityScale != oldDelegate.qualityScale;
  }
}

/// Represents an energy flow particle moving along paths
class EnergyFlowParticle {
  final Vector2 position;
  final Vector2 velocity;
  final Color color;
  final double size;
  final double alpha;
  final double life;
  final double maxLife;
  final String pathId;

  const EnergyFlowParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.alpha,
    required this.life,
    required this.maxLife,
    required this.pathId,
  });

  /// Create a copy with updated properties
  EnergyFlowParticle copyWith({
    Vector2? position,
    Vector2? velocity,
    double? alpha,
    double? life,
  }) {
    return EnergyFlowParticle(
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      color: color,
      size: size,
      alpha: alpha ?? this.alpha,
      life: life ?? this.life,
      maxLife: maxLife,
      pathId: pathId,
    );
  }

  /// Check if particle is still alive
  bool get isAlive => life > 0;

  /// Get life percentage (0.0 to 1.0)
  double get lifePercentage => life / maxLife;
}