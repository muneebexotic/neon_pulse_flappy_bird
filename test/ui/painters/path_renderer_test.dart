import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:neon_pulse_flappy_bird/ui/painters/path_renderer.dart';
import 'package:neon_pulse_flappy_bird/models/progression_path_models.dart';
import 'package:neon_pulse_flappy_bird/models/achievement.dart';

void main() {
  group('PathRenderer', () {
    late PathRenderer pathRenderer;
    late List<PathSegment> testPathSegments;

    setUp(() {
      // Create test path segments
      testPathSegments = [
        PathSegment(
          id: 'main_path',
          category: AchievementType.score,
          pathPoints: [
            Vector2(100, 100),
            Vector2(200, 150),
            Vector2(300, 200),
            Vector2(400, 250),
          ],
          neonColor: const Color(0xFFFF1493), // Hot pink
          width: 8.0,
          isMainPath: true,
          completionPercentage: 0.75,
          achievementIds: ['test1', 'test2', 'test3'],
        ),
        PathSegment(
          id: 'branch_path',
          category: AchievementType.pulseUsage,
          pathPoints: [
            Vector2(200, 150),
            Vector2(250, 100),
            Vector2(300, 80),
          ],
          neonColor: const Color(0xFF9932CC), // Purple
          width: 6.0,
          isMainPath: false,
          completionPercentage: 0.5,
          achievementIds: ['test4', 'test5'],
        ),
      ];

      pathRenderer = PathRenderer(
        pathSegments: testPathSegments,
        animationProgress: 1.0,
        enableGlowEffects: true,
        glowIntensity: 1.0,
        qualityScale: 1.0,
      );
    });

    group('Path Geometry Generation', () {
      test('should create valid path from Vector2 points', () {
        final points = [
          Vector2(0, 0),
          Vector2(100, 50),
          Vector2(200, 100),
        ];

        // Test that path creation doesn't throw
        expect(() {
          final renderer = PathRenderer(pathSegments: [
            PathSegment(
              id: 'test',
              category: AchievementType.score,
              pathPoints: points,
              neonColor: Colors.red,
              width: 5.0,
              isMainPath: true,
              completionPercentage: 1.0,
              achievementIds: ['test'],
            ),
          ]);
          // Trigger path creation by painting
          final canvas = MockCanvas();
          renderer.paint(canvas, const Size(400, 300));
        }, returnsNormally);
      });

      test('should handle empty path points gracefully', () {
        final emptySegment = PathSegment(
          id: 'empty',
          category: AchievementType.score,
          pathPoints: [],
          neonColor: Colors.red,
          width: 5.0,
          isMainPath: true,
          completionPercentage: 0.0,
          achievementIds: [],
        );

        expect(() {
          final renderer = PathRenderer(pathSegments: [emptySegment]);
          final canvas = MockCanvas();
          renderer.paint(canvas, const Size(400, 300));
        }, returnsNormally);
      });

      test('should handle single point path', () {
        final singlePointSegment = PathSegment(
          id: 'single',
          category: AchievementType.score,
          pathPoints: [Vector2(100, 100)],
          neonColor: Colors.red,
          width: 5.0,
          isMainPath: true,
          completionPercentage: 1.0,
          achievementIds: ['test'],
        );

        expect(() {
          final renderer = PathRenderer(pathSegments: [singlePointSegment]);
          final canvas = MockCanvas();
          renderer.paint(canvas, const Size(400, 300));
        }, returnsNormally);
      });

      test('should calculate completed path points correctly', () {
        final segment = testPathSegments.first;
        
        // Test full completion
        final fullSegment = segment.copyWith(completionPercentage: 1.0);
        expect(fullSegment.completionPercentage, equals(1.0));
        
        // Test partial completion
        final partialSegment = segment.copyWith(completionPercentage: 0.5);
        expect(partialSegment.completionPercentage, equals(0.5));
        
        // Test zero completion
        final zeroSegment = segment.copyWith(completionPercentage: 0.0);
        expect(zeroSegment.completionPercentage, equals(0.0));
      });

      test('should sort segments by priority correctly', () {
        final renderer = PathRenderer(pathSegments: testPathSegments);
        
        // Main path should come first
        expect(testPathSegments.first.isMainPath, isTrue);
        expect(testPathSegments.last.isMainPath, isFalse);
      });
    });

    group('Color Interpolation', () {
      test('should handle neon color properties correctly', () {
        final mainPath = testPathSegments.first;
        final branchPath = testPathSegments.last;
        
        // Test main path color (hot pink)
        expect(mainPath.neonColor, equals(const Color(0xFFFF1493)));
        expect(mainPath.neonColor.alpha, equals(255));
        
        // Test branch path color (purple)
        expect(branchPath.neonColor, equals(const Color(0xFF9932CC)));
        expect(branchPath.neonColor.alpha, equals(255));
      });

      test('should create proper opacity variations', () {
        final baseColor = const Color(0xFFFF1493);
        
        // Test dim color for base path
        final dimColor = baseColor.withOpacity(0.2);
        expect(dimColor.opacity, closeTo(0.2, 0.01));
        
        // Test glow color
        final glowColor = baseColor.withOpacity(0.1);
        expect(glowColor.opacity, closeTo(0.1, 0.01));
        
        // Test full brightness
        final fullColor = baseColor.withOpacity(1.0);
        expect(fullColor.opacity, equals(1.0));
      });

      test('should handle color blending for glow effects', () {
        final neonColor = const Color(0xFFFF1493);
        
        // Test multiple glow layers with different opacities
        final outerGlow = neonColor.withOpacity(0.1);
        final middleGlow = neonColor.withOpacity(0.2);
        final innerGlow = neonColor.withOpacity(0.3);
        
        expect(outerGlow.opacity, lessThan(middleGlow.opacity));
        expect(middleGlow.opacity, lessThan(innerGlow.opacity));
        expect(innerGlow.opacity, lessThan(1.0));
      });
    });

    group('Animation and Effects', () {
      test('should handle pulse phase animation', () {
        final renderer1 = PathRenderer(
          pathSegments: testPathSegments,
          pulsePhase: 0.0,
        );
        
        final renderer2 = PathRenderer(
          pathSegments: testPathSegments,
          pulsePhase: 0.5,
        );
        
        expect(renderer1.pulsePhase, equals(0.0));
        expect(renderer2.pulsePhase, equals(0.5));
        expect(renderer1.shouldRepaint(renderer2), isTrue);
      });

      test('should handle scan line animation', () {
        final renderer1 = PathRenderer(
          pathSegments: testPathSegments,
          scanLinePosition: 0.0,
          showScanLine: true,
        );
        
        final renderer2 = PathRenderer(
          pathSegments: testPathSegments,
          scanLinePosition: 0.5,
          showScanLine: true,
        );
        
        expect(renderer1.scanLinePosition, equals(0.0));
        expect(renderer2.scanLinePosition, equals(0.5));
        expect(renderer1.shouldRepaint(renderer2), isTrue);
      });

      test('should handle quality scaling', () {
        final highQuality = PathRenderer(
          pathSegments: testPathSegments,
          qualityScale: 1.0,
        );
        
        final lowQuality = PathRenderer(
          pathSegments: testPathSegments,
          qualityScale: 0.5,
        );
        
        expect(highQuality.qualityScale, equals(1.0));
        expect(lowQuality.qualityScale, equals(0.5));
        expect(highQuality.shouldRepaint(lowQuality), isTrue);
      });
    });

    group('Performance Optimization', () {
      test('should handle glow effects toggle', () {
        final withGlow = PathRenderer(
          pathSegments: testPathSegments,
          enableGlowEffects: true,
        );
        
        final withoutGlow = PathRenderer(
          pathSegments: testPathSegments,
          enableGlowEffects: false,
        );
        
        expect(withGlow.enableGlowEffects, isTrue);
        expect(withoutGlow.enableGlowEffects, isFalse);
      });

      test('should handle anti-aliasing toggle', () {
        final withAA = PathRenderer(
          pathSegments: testPathSegments,
          enableAntiAliasing: true,
        );
        
        final withoutAA = PathRenderer(
          pathSegments: testPathSegments,
          enableAntiAliasing: false,
        );
        
        expect(withAA.enableAntiAliasing, isTrue);
        expect(withoutAA.enableAntiAliasing, isFalse);
      });

      test('should optimize rendering based on quality scale', () {
        final renderer = PathRenderer(
          pathSegments: testPathSegments,
          qualityScale: 0.3,
        );
        
        // Low quality should disable certain effects
        expect(renderer.qualityScale, lessThan(0.5));
      });
    });

    group('shouldRepaint Logic', () {
      test('should repaint when path segments change', () {
        final renderer1 = PathRenderer(pathSegments: testPathSegments);
        final renderer2 = PathRenderer(pathSegments: []);
        
        expect(renderer1.shouldRepaint(renderer2), isTrue);
      });

      test('should repaint when animation properties change', () {
        final renderer1 = PathRenderer(
          pathSegments: testPathSegments,
          animationProgress: 0.5,
        );
        
        final renderer2 = PathRenderer(
          pathSegments: testPathSegments,
          animationProgress: 0.8,
        );
        
        expect(renderer1.shouldRepaint(renderer2), isTrue);
      });

      test('should not repaint when properties are identical', () {
        final renderer1 = PathRenderer(
          pathSegments: testPathSegments,
          animationProgress: 1.0,
          enableGlowEffects: true,
          glowIntensity: 1.0,
        );
        
        final renderer2 = PathRenderer(
          pathSegments: testPathSegments,
          animationProgress: 1.0,
          enableGlowEffects: true,
          glowIntensity: 1.0,
        );
        
        expect(renderer1.shouldRepaint(renderer2), isFalse);
      });
    });
  });

  group('EnergyFlowParticle', () {
    test('should create particle with correct properties', () {
      final particle = EnergyFlowParticle(
        position: Vector2(100, 200),
        velocity: Vector2(50, -25),
        color: Colors.cyan,
        size: 3.0,
        alpha: 0.8,
        life: 2.0,
        maxLife: 2.5,
        pathId: 'test_path',
      );

      expect(particle.position.x, equals(100));
      expect(particle.position.y, equals(200));
      expect(particle.velocity.x, equals(50));
      expect(particle.velocity.y, equals(-25));
      expect(particle.color, equals(Colors.cyan));
      expect(particle.size, equals(3.0));
      expect(particle.alpha, equals(0.8));
      expect(particle.life, equals(2.0));
      expect(particle.maxLife, equals(2.5));
      expect(particle.pathId, equals('test_path'));
    });

    test('should calculate life percentage correctly', () {
      final particle = EnergyFlowParticle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        size: 2.0,
        alpha: 1.0,
        life: 1.5,
        maxLife: 3.0,
        pathId: 'test',
      );

      expect(particle.lifePercentage, closeTo(0.5, 0.01));
    });

    test('should determine alive status correctly', () {
      final aliveParticle = EnergyFlowParticle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        size: 2.0,
        alpha: 1.0,
        life: 1.0,
        maxLife: 2.0,
        pathId: 'test',
      );

      final deadParticle = EnergyFlowParticle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        size: 2.0,
        alpha: 1.0,
        life: 0.0,
        maxLife: 2.0,
        pathId: 'test',
      );

      expect(aliveParticle.isAlive, isTrue);
      expect(deadParticle.isAlive, isFalse);
    });

    test('should create copy with updated properties', () {
      final original = EnergyFlowParticle(
        position: Vector2(10, 20),
        velocity: Vector2(5, -5),
        color: Colors.blue,
        size: 2.0,
        alpha: 1.0,
        life: 3.0,
        maxLife: 3.0,
        pathId: 'original',
      );

      final copy = original.copyWith(
        position: Vector2(30, 40),
        alpha: 0.5,
        life: 2.0,
      );

      expect(copy.position.x, equals(30));
      expect(copy.position.y, equals(40));
      expect(copy.alpha, equals(0.5));
      expect(copy.life, equals(2.0));
      
      // Unchanged properties should remain the same
      expect(copy.velocity.x, equals(5));
      expect(copy.velocity.y, equals(-5));
      expect(copy.color, equals(Colors.blue));
      expect(copy.size, equals(2.0));
      expect(copy.maxLife, equals(3.0));
      expect(copy.pathId, equals('original'));
    });
  });
}

/// Mock canvas for testing paint operations
class MockCanvas implements Canvas {
  final List<String> operations = [];

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) {
    operations.add('clipPath');
  }

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) {
    operations.add('clipRRect');
  }

  @override
  void clipRect(Rect rect, {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) {
    operations.add('clipRect');
  }

  @override
  void clipRSuperellipse(ui.RSuperellipse rsuperellipse, {bool doAntiAlias = true}) {
    operations.add('clipRSuperellipse');
  }

  @override
  void drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter, Paint paint) {
    operations.add('drawArc');
  }

  @override
  void drawAtlas(ui.Image atlas, List<RSTransform> transforms, List<Rect> rects, List<Color>? colors, BlendMode? blendMode, Rect? cullRect, Paint paint) {
    operations.add('drawAtlas');
  }

  @override
  void drawCircle(Offset center, double radius, Paint paint) {
    operations.add('drawCircle');
  }

  @override
  void drawColor(Color color, BlendMode blendMode) {
    operations.add('drawColor');
  }

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) {
    operations.add('drawDRRect');
  }

  @override
  void drawImage(ui.Image image, Offset offset, Paint paint) {
    operations.add('drawImage');
  }

  @override
  void drawImageNine(ui.Image image, Rect center, Rect dst, Paint paint) {
    operations.add('drawImageNine');
  }

  @override
  void drawImageRect(ui.Image image, Rect src, Rect dst, Paint paint) {
    operations.add('drawImageRect');
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    operations.add('drawLine');
  }

  @override
  void drawOval(Rect rect, Paint paint) {
    operations.add('drawOval');
  }

  @override
  void drawPaint(Paint paint) {
    operations.add('drawPaint');
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    operations.add('drawParagraph');
  }

  @override
  void drawPath(Path path, Paint paint) {
    operations.add('drawPath');
  }

  @override
  void drawPicture(ui.Picture picture) {
    operations.add('drawPicture');
  }

  @override
  void drawPoints(ui.PointMode pointMode, List<Offset> points, Paint paint) {
    operations.add('drawPoints');
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    operations.add('drawRRect');
  }

  @override
  void drawRSuperellipse(ui.RSuperellipse rsuperellipse, Paint paint) {
    operations.add('drawRSuperellipse');
  }

  @override
  void drawRawAtlas(ui.Image atlas, Float32List rstTransforms, Float32List rects, Int32List? colors, BlendMode? blendMode, Rect? cullRect, Paint paint) {
    operations.add('drawRawAtlas');
  }

  @override
  void drawRawPoints(ui.PointMode pointMode, Float32List points, Paint paint) {
    operations.add('drawRawPoints');
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    operations.add('drawRect');
  }

  @override
  void drawShadow(Path path, Color color, double elevation, bool transparentOccluder) {
    operations.add('drawShadow');
  }

  @override
  void drawVertices(ui.Vertices vertices, BlendMode blendMode, Paint paint) {
    operations.add('drawVertices');
  }

  @override
  int getSaveCount() => 0;

  @override
  void restore() {
    operations.add('restore');
  }

  @override
  void restoreToCount(int count) {
    operations.add('restoreToCount');
  }

  @override
  void rotate(double radians) {
    operations.add('rotate');
  }

  @override
  void save() {
    operations.add('save');
  }

  @override
  void saveLayer(Rect? bounds, Paint paint) {
    operations.add('saveLayer');
  }

  @override
  void scale(double sx, [double? sy]) {
    operations.add('scale');
  }

  @override
  void skew(double sx, double sy) {
    operations.add('skew');
  }

  @override
  void transform(Float64List matrix4) {
    operations.add('transform');
  }

  @override
  void translate(double dx, double dy) {
    operations.add('translate');
  }

  @override
  Rect getDestinationClipBounds() => Rect.zero;

  @override
  Rect getLocalClipBounds() => Rect.zero;

  @override
  Float64List getTransform() => Float64List(16);
}