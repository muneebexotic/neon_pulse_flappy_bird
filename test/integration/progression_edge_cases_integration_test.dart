import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:neon_pulse_flappy_bird/ui/screens/achievements_progression_screen.dart';
import 'package:neon_pulse_flappy_bird/ui/components/progression_edge_states.dart';
import 'package:neon_pulse_flappy_bird/game/managers/achievement_manager.dart';
import 'package:neon_pulse_flappy_bird/game/managers/adaptive_quality_manager.dart';
import 'package:neon_pulse_flappy_bird/game/managers/haptic_manager.dart';
import 'package:neon_pulse_flappy_bird/models/achievement.dart';

import 'progression_edge_cases_integration_test.mocks.dart';

@GenerateMocks([
  AchievementManager,
  AdaptiveQualityManager,
  HapticManager,
])
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Progression Edge Cases Integration Tests', () {
    late MockAchievementManager mockAchievementManager;
    late MockAdaptiveQualityManager mockAdaptiveQualityManager;
    late MockHapticManager mockHapticManager;

    setUp(() {
      mockAchievementManager = MockAchievementManager();
      mockAdaptiveQualityManager = MockAdaptiveQualityManager();
      mockHapticManager = MockHapticManager();

      // Setup default mock behaviors
      when(mockAchievementManager.initialize()).thenAnswer((_) async {});
      when(mockAchievementManager.achievements).thenReturn([]);
      when(mockAchievementManager.onAchievementUnlocked).thenReturn(null);
      when(mockAchievementManager.onSkinUnlocked).thenReturn(null);
    });

    Widget createTestApp({
      List<Achievement>? achievements,
      bool shouldThrowError = false,
      bool shouldThrowNetworkError = false,
    }) {
      if (achievements != null) {
        when(mockAchievementManager.achievements).thenReturn(achievements);
      }

      if (shouldThrowError) {
        when(mockAchievementManager.initialize()).thenThrow(
          shouldThrowNetworkError 
            ? Exception('Network connection failed')
            : Exception('General error'),
        );
      }

      return MaterialApp(
        home: AchievementsProgressionScreen(
          achievementManager: mockAchievementManager,
          adaptiveQualityManager: mockAdaptiveQualityManager,
          hapticManager: mockHapticManager,
        ),
      );
    }

    group('Loading State Integration', () {
      testWidgets('loading state displays and animates correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        // Verify loading state is displayed
        expect(find.byType(ProgressionLoadingState), findsOneWidget);
        expect(find.text('Loading Progression Path...'), findsOneWidget);

        // Verify loading indicator is present and animating
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Pump a few frames to ensure animations are running
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }

        // Verify no exceptions during animation
        expect(tester.takeException(), isNull);
      });

      testWidgets('loading state transitions to main content', (WidgetTester tester) async {
        final achievements = [
          Achievement(
            id: 'test1',
            name: 'Test Achievement',
            description: 'Test description',
            type: AchievementType.scoreMillestone,
            targetValue: 100,
            currentProgress: 50,
            isUnlocked: false,
          ),
        ];

        await tester.pumpWidget(createTestApp(achievements: achievements));

        // Initially shows loading
        expect(find.byType(ProgressionLoadingState), findsOneWidget);

        // Wait for initialization to complete
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Should transition away from loading state
        expect(find.byType(ProgressionLoadingState), findsNothing);
      });
    });

    group('Error State Integration', () {
      testWidgets('error state displays and retry works', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(shouldThrowError: true));

        // Wait for error to occur
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Verify error state is displayed
        expect(find.text('Error Loading Progression'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        // Fix the error for retry
        when(mockAchievementManager.initialize()).thenAnswer((_) async {});

        // Tap retry button
        await tester.tap(find.text('Retry'));
        await tester.pump();

        // Verify loading state is shown again
        expect(find.byType(ProgressionLoadingState), findsOneWidget);

        // Wait for retry to complete
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Should reach a stable state
        expect(tester.takeException(), isNull);
      });

      testWidgets('network error state shows offline option', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(
          shouldThrowError: true,
          shouldThrowNetworkError: true,
        ));

        // Wait for error to occur
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Verify network error state
        expect(find.text('Connection Failed'), findsOneWidget);
        expect(find.text('Use Offline Data'), findsOneWidget);

        // Tap offline data button
        await tester.tap(find.text('Use Offline Data'));
        await tester.pump();

        // Should dismiss error state
        expect(find.text('Connection Failed'), findsNothing);
      });
    });

    group('Empty State Integration', () {
      testWidgets('empty state displays for no unlocked achievements', (WidgetTester tester) async {
        final lockedAchievements = [
          Achievement(
            id: 'test1',
            name: 'Test Achievement 1',
            description: 'Test description',
            type: AchievementType.scoreMillestone,
            targetValue: 100,
            currentProgress: 0,
            isUnlocked: false,
          ),
          Achievement(
            id: 'test2',
            name: 'Test Achievement 2',
            description: 'Test description',
            type: AchievementType.skillChallenge,
            targetValue: 50,
            currentProgress: 0,
            isUnlocked: false,
          ),
        ];

        await tester.pumpWidget(createTestApp(achievements: lockedAchievements));

        // Wait for initialization
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Verify empty state is displayed
        expect(find.byType(ProgressionEmptyState), findsOneWidget);
        expect(find.text('BEGIN YOUR JOURNEY'), findsOneWidget);
        expect(find.text('START PLAYING'), findsOneWidget);

        // Verify animations are running
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(tester.takeException(), isNull);
      });

      testWidgets('empty state start journey button works', (WidgetTester tester) async {
        final lockedAchievements = [
          Achievement(
            id: 'test1',
            name: 'Test Achievement',
            description: 'Test description',
            type: AchievementType.scoreMillestone,
            targetValue: 100,
            currentProgress: 0,
            isUnlocked: false,
          ),
        ];

        await tester.pumpWidget(createTestApp(achievements: lockedAchievements));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Verify button is present and tappable
        expect(find.text('START PLAYING'), findsOneWidget);
        
        // Tap the button (in real app this would navigate)
        await tester.tap(find.text('START PLAYING'));
        await tester.pump();

        // Verify no exceptions
        expect(tester.takeException(), isNull);
      });
    });

    group('Celebration State Integration', () {
      testWidgets('celebration state displays for 100% completion', (WidgetTester tester) async {
        final unlockedAchievements = [
          Achievement(
            id: 'test1',
            name: 'Test Achievement 1',
            description: 'Test description',
            type: AchievementType.scoreMillestone,
            targetValue: 100,
            currentProgress: 100,
            isUnlocked: true,
          ),
          Achievement(
            id: 'test2',
            name: 'Test Achievement 2',
            description: 'Test description',
            type: AchievementType.skillChallenge,
            targetValue: 50,
            currentProgress: 50,
            isUnlocked: true,
          ),
        ];

        await tester.pumpWidget(createTestApp(achievements: unlockedAchievements));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Wait for celebration check
        await tester.pump(const Duration(milliseconds: 600));

        // Verify celebration state is displayed
        expect(find.byType(ProgressionCelebrationState), findsOneWidget);
        expect(find.text('MASTER ACHIEVED!'), findsOneWidget);
        expect(find.text('2 / 2 ACHIEVEMENTS'), findsOneWidget);

        // Let celebration animations run
        for (int i = 0; i < 50; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(tester.takeException(), isNull);
      });

      testWidgets('celebration state continue button works', (WidgetTester tester) async {
        final unlockedAchievements = [
          Achievement(
            id: 'test1',
            name: 'Test Achievement',
            description: 'Test description',
            type: AchievementType.scoreMillestone,
            targetValue: 100,
            currentProgress: 100,
            isUnlocked: true,
          ),
        ];

        await tester.pumpWidget(createTestApp(achievements: unlockedAchievements));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Wait for celebration check and animations
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(seconds: 3));

        // Verify continue button appears
        expect(find.text('CONTINUE'), findsOneWidget);

        // Tap continue button
        await tester.tap(find.text('CONTINUE'));
        await tester.pump();

        // Verify celebration state is dismissed
        expect(find.byType(ProgressionCelebrationState), findsNothing);
      });
    });

    group('State Transition Integration', () {
      testWidgets('complete flow from loading to empty state', (WidgetTester tester) async {
        final lockedAchievements = [
          Achievement(
            id: 'test1',
            name: 'Test Achievement',
            description: 'Test description',
            type: AchievementType.scoreMillestone,
            targetValue: 100,
            currentProgress: 0,
            isUnlocked: false,
          ),
        ];

        await tester.pumpWidget(createTestApp(achievements: lockedAchievements));

        // Start in loading state
        expect(find.byType(ProgressionLoadingState), findsOneWidget);

        // Wait for transition
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // End in empty state
        expect(find.byType(ProgressionEmptyState), findsOneWidget);
        expect(find.text('BEGIN YOUR JOURNEY'), findsOneWidget);
      });

      testWidgets('complete flow from loading to celebration state', (WidgetTester tester) async {
        final unlockedAchievements = [
          Achievement(
            id: 'test1',
            name: 'Test Achievement',
            description: 'Test description',
            type: AchievementType.scoreMillestone,
            targetValue: 100,
            currentProgress: 100,
            isUnlocked: true,
          ),
        ];

        await tester.pumpWidget(createTestApp(achievements: unlockedAchievements));

        // Start in loading state
        expect(find.byType(ProgressionLoadingState), findsOneWidget);

        // Wait for transition
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Wait for celebration check
        await tester.pump(const Duration(milliseconds: 600));

        // End in celebration state
        expect(find.byType(ProgressionCelebrationState), findsOneWidget);
        expect(find.text('MASTER ACHIEVED!'), findsOneWidget);
      });

      testWidgets('error recovery flow works end-to-end', (WidgetTester tester) async {
        // Start with error
        await tester.pumpWidget(createTestApp(shouldThrowError: true));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Verify error state
        expect(find.text('Error Loading Progression'), findsOneWidget);

        // Fix error and add achievements
        when(mockAchievementManager.initialize()).thenAnswer((_) async {});
        when(mockAchievementManager.achievements).thenReturn([
          Achievement(
            id: 'test1',
            name: 'Test Achievement',
            description: 'Test description',
            type: AchievementType.scoreMillestone,
            targetValue: 100,
            currentProgress: 0,
            isUnlocked: false,
          ),
        ]);

        // Retry
        await tester.tap(find.text('Retry'));
        await tester.pump();

        // Should go through loading
        expect(find.byType(ProgressionLoadingState), findsOneWidget);

        // Wait for completion
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Should reach empty state
        expect(find.byType(ProgressionEmptyState), findsOneWidget);
      });
    });

    group('Performance Integration', () {
      testWidgets('loading state animations perform well', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        // Run animations for extended period
        for (int i = 0; i < 100; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }

        // Verify no performance issues or exceptions
        expect(tester.takeException(), isNull);
      });

      testWidgets('celebration state complex animations perform well', (WidgetTester tester) async {
        final unlockedAchievements = [
          Achievement(
            id: 'test1',
            name: 'Test Achievement',
            description: 'Test description',
            type: AchievementType.scoreMillestone,
            targetValue: 100,
            currentProgress: 100,
            isUnlocked: true,
          ),
        ];

        await tester.pumpWidget(createTestApp(achievements: unlockedAchievements));
        await tester.pumpAndSettle(const Duration(seconds: 5));
        await tester.pump(const Duration(milliseconds: 600));

        // Run celebration animations for extended period
        for (int i = 0; i < 200; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }

        // Verify no performance issues
        expect(tester.takeException(), isNull);
      });

      testWidgets('rapid state changes handle well', (WidgetTester tester) async {
        // Start with error
        await tester.pumpWidget(createTestApp(shouldThrowError: true));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Rapidly fix and retry multiple times
        for (int i = 0; i < 3; i++) {
          when(mockAchievementManager.initialize()).thenAnswer((_) async {});
          await tester.tap(find.text('Retry'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          // Cause error again
          when(mockAchievementManager.initialize()).thenThrow(Exception('Test error'));
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }

        // Final fix
        when(mockAchievementManager.initialize()).thenAnswer((_) async {});
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Should handle rapid changes without issues
        expect(tester.takeException(), isNull);
      });
    });

    group('Accessibility Integration', () {
      testWidgets('all edge states are accessible', (WidgetTester tester) async {
        // Test loading state accessibility
        await tester.pumpWidget(createTestApp());
        expect(find.text('Loading Progression Path...'), findsOneWidget);

        // Test error state accessibility
        when(mockAchievementManager.initialize()).thenThrow(Exception('Test error'));
        await tester.pumpWidget(createTestApp(shouldThrowError: true));
        await tester.pumpAndSettle(const Duration(seconds: 5));
        expect(find.text('Error Loading Progression'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        // Test empty state accessibility
        when(mockAchievementManager.initialize()).thenAnswer((_) async {});
        when(mockAchievementManager.achievements).thenReturn([
          Achievement(
            id: 'test1',
            name: 'Test Achievement',
            description: 'Test description',
            type: AchievementType.scoreMillestone,
            targetValue: 100,
            currentProgress: 0,
            isUnlocked: false,
          ),
        ]);
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle(const Duration(seconds: 5));
        expect(find.text('BEGIN YOUR JOURNEY'), findsOneWidget);
        expect(find.text('START PLAYING'), findsOneWidget);

        // All states should be accessible without exceptions
        expect(tester.takeException(), isNull);
      });
    });
  });
}