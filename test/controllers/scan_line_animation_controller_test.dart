import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/controllers/scan_line_animation_controller.dart';

void main() {
  group('ScanLineAnimationController', () {
    late ScanLineAnimationController controller;

    setUp(() {
      controller = ScanLineAnimationController();
    });

    tearDown(() {
      controller.dispose();
    });

    group('Initialization', () {
      test('should initialize with default values', () {
        expect(controller.scanLinePosition, equals(0.0));
        expect(controller.revealProgress, equals(0.0));
        expect(controller.glowIntensity, equals(0.0));
        expect(controller.isAnimating, isFalse);
        expect(controller.isInitialized, isFalse);
      });

      test('should have correct default configuration', () {
        expect(controller.scanLineColor, equals(const Color(0xFF00FFFF)));
        expect(controller.scanLineWidth, equals(3.0));
        expect(controller.glowRadius, equals(20.0));
      });

      test('should accept custom configuration', () {
        final customController = ScanLineAnimationController(
          scanDuration: const Duration(milliseconds: 1000),
          scanLineColor: Colors.red,
          scanLineWidth: 5.0,
          glowRadius: 30.0,
        );

        expect(customController.scanLineColor, equals(Colors.red));
        expect(customController.scanLineWidth, equals(5.0));
        expect(customController.glowRadius, equals(30.0));

        customController.dispose();
      });

      testWidgets('should initialize with ticker provider', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                controller.initialize(tester);
                return Container();
              },
            ),
          ),
        );

        expect(controller.isInitialized, isTrue);
      });
    });

    group('Animation Control', () {
      testWidgets('should start reveal animation', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                controller.initialize(tester);
                return Container();
              },
            ),
          ),
        );

        expect(controller.isAnimating, isFalse);

        // Start animation
        final animationFuture = controller.startRevealAnimation();
        expect(controller.isAnimating, isTrue);

        // Let animation run for a bit
        await tester.pump(const Duration(milliseconds: 100));
        expect(controller.scanLinePosition, greaterThan(0.0));

        // Complete animation
        await tester.pumpAndSettle();
        await animationFuture;

        expect(controller.isAnimating, isFalse);
        expect(controller.scanLinePosition, equals(1.0));
        expect(controller.revealProgress, equals(1.0));
      });

      testWidgets('should reset animation', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                controller.initialize(tester);
                return Container();
              },
            ),
          ),
        );

        // Start and partially complete animation
        controller.startRevealAnimation();
        await tester.pump(const Duration(milliseconds: 100));

        expect(controller.scanLinePosition, greaterThan(0.0));

        // Reset animation
        controller.reset();

        expect(controller.scanLinePosition, equals(0.0));
        expect(controller.revealProgress, equals(0.0));
        expect(controller.glowIntensity, equals(0.0));
        expect(controller.isAnimating, isFalse);
      });

      testWidgets('should stop animation', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                controller.initialize(tester);
                return Container();
              },
            ),
          ),
        );

        // Start animation
        controller.startRevealAnimation();
        await tester.pump(const Duration(milliseconds: 100));

        expect(controller.isAnimating, isTrue);

        // Stop animation
        controller.stop();

        expect(controller.isAnimating, isFalse);
      });

      testWidgets('should not start animation if already animating', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                controller.initialize(tester);
                return Container();
              },
            ),
          ),
        );

        // Start first animation
        controller.startRevealAnimation();
        expect(controller.isAnimating, isTrue);

        // Try to start second animation
        await controller.startRevealAnimation();
        
        // Should still be animating the first one
        expect(controller.isAnimating, isTrue);
      });
    });

    group('Position Calculations', () {
      testWidgets('should calculate scan line Y position correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                controller.initialize(tester);
                return Container();
              },
            ),
          ),
        );

        const screenHeight = 800.0;

        // Test at different animation positions
        controller.startRevealAnimation();
        
        // At start
        await tester.pump(Duration.zero);
        expect(controller.getScanLineY(screenHeight), equals(0.0));

        // Partway through
        await tester.pump(const Duration(milliseconds: 500));
        final midPosition = controller.getScanLineY(screenHeight);
        expect(midPosition, greaterThan(0.0));
        expect(midPosition, lessThan(screenHeight));

        // Complete animation
        await tester.pumpAndSettle();
        expect(controller.getScanLineY(screenHeight), equals(screenHeight));
      });

      testWidgets('should determine reveal status correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                controller.initialize(tester);
                return Container();
              },
            ),
          ),
        );

        const screenHeight = 800.0;
        const testY = 400.0; // Middle of screen

        // Before animation starts
        expect(controller.shouldRevealPoint(testY, screenHeight), isFalse);

        // Start animation
        controller.startRevealAnimation();
        await tester.pump(const Duration(milliseconds: 100));

        // Point above scan line should not be revealed yet
        expect(controller.shouldRevealPoint(testY + 200, screenHeight), isFalse);

        // Complete animation - all points should be revealed
        await tester.pumpAndSettle();
        expect(controller.shouldRevealPoint(testY, screenHeight), isTrue);
      });

      testWidgets('should calculate reveal opacity correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                controller.initialize(tester);
                return Container();
              },
            ),
          ),
        );

        const screenHeight = 800.0;
        const testY = 400.0;

        // Before animation
        expect(controller.getRevealOpacity(testY, screenHeight), equals(0.0));

        // Start animation
        controller.startRevealAnimation();
        await tester.pump(const Duration(milliseconds: 500));

        final opacity = controller.getRevealOpacity(testY, screenHeight);
        expect(opacity, greaterThanOrEqualTo(0.0));
        expect(opacity, lessThanOrEqualTo(1.0));

        // Complete animation
        await tester.pumpAndSettle();
        expect(controller.getRevealOpacity(testY, screenHeight), equals(1.0));
      });

      testWidgets('should calculate glow effect correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                controller.initialize(tester);
                return Container();
              },
            ),
          ),
        );

        const screenHeight = 800.0;

        controller.startRevealAnimation();
        await tester.pump(const Duration(milliseconds: 500));

        final scanY = controller.getScanLineY(screenHeight);
        
        // Point at scan line should have maximum glow
        final glowAtScan = controller.getScanLineGlow(scanY, screenHeight);
        expect(glowAtScan, greaterThan(0.0));

        // Point far from scan line should have no glow
        final glowFarAway = controller.getScanLineGlow(scanY + 100, screenHeight);
        expect(glowFarAway, lessThanOrEqualTo(glowAtScan));
      });
    });

    group('Custom Painter', () {
      testWidgets('should create scan line painter', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                controller.initialize(tester);
                return Container();
              },
            ),
          ),
        );

        const screenSize = Size(400, 800);
        final painter = controller.createScanLinePainter(screenSize);

        expect(painter, isA<ScanLinePainter>());
      });

      test('ScanLinePainter should repaint when values change', () {
        const screenSize = Size(400, 800);
        
        final painter1 = ScanLinePainter(
          scanLinePosition: 0.5,
          revealProgress: 0.5,
          glowIntensity: 0.5,
          scanLineColor: Colors.cyan,
          scanLineWidth: 3.0,
          glowRadius: 20.0,
          screenSize: screenSize,
        );

        final painter2 = ScanLinePainter(
          scanLinePosition: 0.6,
          revealProgress: 0.5,
          glowIntensity: 0.5,
          scanLineColor: Colors.cyan,
          scanLineWidth: 3.0,
          glowRadius: 20.0,
          screenSize: screenSize,
        );

        expect(painter1.shouldRepaint(painter2), isTrue);

        final painter3 = ScanLinePainter(
          scanLinePosition: 0.5,
          revealProgress: 0.5,
          glowIntensity: 0.5,
          scanLineColor: Colors.cyan,
          scanLineWidth: 3.0,
          glowRadius: 20.0,
          screenSize: screenSize,
        );

        expect(painter1.shouldRepaint(painter3), isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle initialization without ticker provider gracefully', () {
        expect(() => controller.startRevealAnimation(), returnsNormally);
        expect(controller.isAnimating, isFalse);
      });

      test('should handle multiple initialization calls', () {
        testWidgets('multiple init calls', (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  controller.initialize(tester);
                  controller.initialize(tester); // Second call should be ignored
                  return Container();
                },
              ),
            ),
          );

          expect(controller.isInitialized, isTrue);
        });
      });

      testWidgets('should handle animation errors gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                controller.initialize(tester);
                return Container();
              },
            ),
          ),
        );

        // This should not throw even if animation is interrupted
        expect(() => controller.startRevealAnimation(), returnsNormally);
      });
    });

    group('Disposal', () {
      testWidgets('should dispose cleanly when initialized', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                controller.initialize(tester);
                return Container();
              },
            ),
          ),
        );

        expect(() => controller.dispose(), returnsNormally);
      });

      test('should dispose cleanly when not initialized', () {
        expect(() => controller.dispose(), returnsNormally);
      });

      testWidgets('should dispose cleanly during animation', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                controller.initialize(tester);
                return Container();
              },
            ),
          ),
        );

        controller.startRevealAnimation();
        await tester.pump(const Duration(milliseconds: 100));

        expect(() => controller.dispose(), returnsNormally);
      });
    });

    group('Change Notification', () {
      testWidgets('should notify listeners during animation', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                controller.initialize(tester);
                return Container();
              },
            ),
          ),
        );

        int notificationCount = 0;
        controller.addListener(() => notificationCount++);

        controller.startRevealAnimation();
        await tester.pump(const Duration(milliseconds: 100));

        expect(notificationCount, greaterThan(0));
      });

      testWidgets('should notify listeners on reset', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                controller.initialize(tester);
                return Container();
              },
            ),
          ),
        );

        int notificationCount = 0;
        controller.addListener(() => notificationCount++);

        controller.reset();
        expect(notificationCount, equals(1));
      });
    });
  });
}