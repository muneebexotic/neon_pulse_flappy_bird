import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/ui/components/progression_edge_states.dart';

void main() {
  group('ProgressionEdgeStates', () {
    const testScreenSize = Size(400, 800);

    group('ProgressionLoadingState', () {
      testWidgets('displays loading indicator and text', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressionLoadingState(
                screenSize: testScreenSize,
                showShimmer: true,
              ),
            ),
          ),
        );

        // Verify loading elements are present
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading Progression Path...'), findsOneWidget);
        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      });

      testWidgets('shimmer animation works correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressionLoadingState(
                screenSize: testScreenSize,
                showShimmer: true,
              ),
            ),
          ),
        );

        // Pump a few frames to test animation
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 1000));

        // Should not throw any exceptions during animation
        expect(tester.takeException(), isNull);
      });

      testWidgets('can disable shimmer effect', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressionLoadingState(
                screenSize: testScreenSize,
                showShimmer: false,
              ),
            ),
          ),
        );

        final loadingState = tester.widget<ProgressionLoadingState>(
          find.byType(ProgressionLoadingState),
        );
        expect(loadingState.showShimmer, isFalse);
      });

      testWidgets('handles different screen sizes', (WidgetTester tester) async {
        const smallScreen = Size(200, 400);
        const largeScreen = Size(800, 1200);

        // Test small screen
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressionLoadingState(
                screenSize: smallScreen,
                showShimmer: true,
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);

        // Test large screen
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressionLoadingState(
                screenSize: largeScreen,
                showShimmer: true,
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    });

    group('ProgressionEmptyState', () {
      testWidgets('displays motivational content', (WidgetTester tester) async {
        bool journeyStarted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressionEmptyState(
                screenSize: testScreenSize,
                onStartJourney: () {
                  journeyStarted = true;
                },
              ),
            ),
          ),
        );

        // Verify motivational content
        expect(find.text('BEGIN YOUR JOURNEY'), findsOneWidget);
        expect(find.text('START PLAYING'), findsOneWidget);
        expect(find.byIcon(Icons.star_outline), findsOneWidget);
        expect(find.textContaining('Your progression path awaits'), findsOneWidget);
      });

      testWidgets('start journey button works', (WidgetTester tester) async {
        bool journeyStarted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: testScreenSize.width,
                height: testScreenSize.height,
                child: ProgressionEmptyState(
                  screenSize: testScreenSize,
                  onStartJourney: () {
                    journeyStarted = true;
                  },
                ),
              ),
            ),
          ),
        );

        // Wait for animations to settle
        await tester.pumpAndSettle();

        // Tap the start journey button with warnIfMissed: false to handle positioning issues
        await tester.tap(find.text('START PLAYING'), warnIfMissed: false);
        await tester.pump();

        expect(journeyStarted, isTrue);
      });

      testWidgets('animations work correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressionEmptyState(
                screenSize: testScreenSize,
                onStartJourney: () {},
              ),
            ),
          ),
        );

        // Pump several animation frames
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Should not throw any exceptions during animations
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles null callback gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressionEmptyState(
                screenSize: testScreenSize,
                onStartJourney: null,
              ),
            ),
          ),
        );

        // Should not show button when callback is null
        expect(find.text('START PLAYING'), findsNothing);
      });
    });

    group('ProgressionCelebrationState', () {
      testWidgets('displays celebration content', (WidgetTester tester) async {
        bool continued = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressionCelebrationState(
                screenSize: testScreenSize,
                totalAchievements: 10,
                onContinue: () {
                  continued = true;
                },
              ),
            ),
          ),
        );

        // Wait for animations to start
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 2000));

        // Verify celebration content
        expect(find.text('MASTER ACHIEVED!'), findsOneWidget);
        expect(find.text('10 / 10 ACHIEVEMENTS'), findsOneWidget);
        expect(find.byIcon(Icons.emoji_events), findsOneWidget);
        expect(find.textContaining('Congratulations'), findsOneWidget);
      });

      testWidgets('continue button works', (WidgetTester tester) async {
        bool continued = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: testScreenSize.width,
                height: testScreenSize.height,
                child: ProgressionCelebrationState(
                  screenSize: testScreenSize,
                  totalAchievements: 5,
                  onContinue: () {
                    continued = true;
                  },
                ),
              ),
            ),
          ),
        );

        // Wait for animations to complete
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // Tap continue button with warnIfMissed: false to handle positioning issues
        await tester.tap(find.text('CONTINUE'), warnIfMissed: false);
        await tester.pump();

        expect(continued, isTrue);
      });

      testWidgets('celebration animations work correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressionCelebrationState(
                screenSize: testScreenSize,
                totalAchievements: 3,
                onContinue: () {},
              ),
            ),
          ),
        );

        // Test animation sequence
        await tester.pump(); // Initial frame
        await tester.pump(const Duration(milliseconds: 300)); // Confetti start
        await tester.pump(const Duration(milliseconds: 800)); // Scale animation
        await tester.pump(const Duration(milliseconds: 1300)); // Text animation
        await tester.pump(const Duration(milliseconds: 2500)); // Complete

        // Should not throw any exceptions during animations
        expect(tester.takeException(), isNull);
      });

      testWidgets('confetti particles render correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressionCelebrationState(
                screenSize: testScreenSize,
                totalAchievements: 1,
                onContinue: () {},
              ),
            ),
          ),
        );

        // Wait for confetti to start and settle all timers
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Verify confetti painter is present
        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles different achievement counts', (WidgetTester tester) async {
        // Test with different achievement counts
        final counts = [1, 5, 10, 25, 100];

        for (final count in counts) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ProgressionCelebrationState(
                  screenSize: testScreenSize,
                  totalAchievements: count,
                  onContinue: () {},
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 2500));

          // Verify achievement count is displayed correctly
          expect(find.text('$count / $count ACHIEVEMENTS'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('handles null callback gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressionCelebrationState(
                screenSize: testScreenSize,
                totalAchievements: 5,
                onContinue: null,
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 2500));

        // Should not show button when callback is null
        expect(find.text('CONTINUE'), findsNothing);
      });
    });

    group('Edge Cases and Error Handling', () {
      testWidgets('handles zero screen size', (WidgetTester tester) async {
        const zeroSize = Size.zero;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressionLoadingState(
                screenSize: zeroSize,
                showShimmer: true,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('handles negative screen dimensions', (WidgetTester tester) async {
        const negativeSize = Size(-100, -200);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressionEmptyState(
                screenSize: negativeSize,
                onStartJourney: () {},
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('handles extremely large screen sizes', (WidgetTester tester) async {
        const largeSize = Size(10000, 20000);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressionCelebrationState(
                screenSize: largeSize,
                totalAchievements: 1,
                onContinue: () {},
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles rapid widget rebuilds', (WidgetTester tester) async {
        for (int i = 0; i < 10; i++) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ProgressionLoadingState(
                  screenSize: Size(400 + i * 10, 800 + i * 20),
                  showShimmer: i % 2 == 0,
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(tester.takeException(), isNull);
      });
    });

    group('Performance Tests', () {
      testWidgets('loading state performs well with animations', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressionLoadingState(
                screenSize: testScreenSize,
                showShimmer: true,
              ),
            ),
          ),
        );

        // Run animations for a while to test performance
        for (int i = 0; i < 100; i++) {
          await tester.pump(const Duration(milliseconds: 16)); // ~60fps
        }

        expect(tester.takeException(), isNull);
      });

      testWidgets('celebration state handles particle effects efficiently', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressionCelebrationState(
                screenSize: testScreenSize,
                totalAchievements: 50, // Large number to stress test
                onContinue: () {},
              ),
            ),
          ),
        );

        // Run particle animations
        for (int i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }

        expect(tester.takeException(), isNull);
      });
    });
  });
}