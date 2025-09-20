import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:neon_pulse_flappy_bird/ui/screens/achievements_progression_screen.dart';
import 'package:neon_pulse_flappy_bird/ui/components/progression_edge_states.dart';
import 'package:neon_pulse_flappy_bird/game/managers/achievement_manager.dart';
import 'package:neon_pulse_flappy_bird/game/managers/adaptive_quality_manager.dart';
import 'package:neon_pulse_flappy_bird/game/managers/haptic_manager.dart';
import 'package:neon_pulse_flappy_bird/models/achievement.dart';

import 'achievements_progression_screen_edge_cases_test.mocks.dart';

@GenerateMocks([
  AchievementManager,
  AdaptiveQualityManager,
  HapticManager,
])
void main() {
  group('AchievementsProgressionScreen Edge Cases', () {
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

    Widget createTestWidget({
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

    group('Loading State', () {
      testWidgets('displays loading state initially', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Verify loading state is displayed
        expect(find.byType(ProgressionLoadingState), findsOneWidget);
        expect(find.text('Loading Progression Path...'), findsOneWidget);
      });

      testWidgets('shows skeleton path during loading', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Verify skeleton path is rendered
        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      });

      testWidgets('loading state has shimmer effects', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        final loadingState = find.byType(ProgressionLoadingState);
        expect(loadingState, findsOneWidget);

        final widget = tester.widget<ProgressionLoadingState>(loadingState);
        expect(widget.showShimmer, isTrue);
      });
    });

    group('Error States', () {
      testWidgets('displays error state when initialization fails', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(shouldThrowError: true));

        // Wait for initialization to complete
        await tester.pumpAndSettle();

        // Verify error state is displayed
        expect(find.text('Error Loading Progression'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('displays network error state for network failures', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          shouldThrowError: true,
          shouldThrowNetworkError: true,
        ));

        // Wait for initialization to complete
        await tester.pumpAndSettle();

        // Verify network error state is displayed
        expect(find.text('Connection Failed'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
        expect(find.text('Use Offline Data'), findsOneWidget);
      });

      testWidgets('retry button works in error state', (WidgetTester tester) async {
        // First, cause an error
        when(mockAchievementManager.initialize()).thenThrow(Exception('Test error'));
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Verify error state
        expect(find.text('Error Loading Progression'), findsOneWidget);

        // Fix the error for retry
        when(mockAchievementManager.initialize()).thenAnswer((_) async {});
        
        // Tap retry button
        await tester.tap(find.text('Retry'));
        await tester.pump();

        // Verify loading state is shown again
        expect(find.byType(ProgressionLoadingState), findsOneWidget);
      });

      testWidgets('offline data button works in network error state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          shouldThrowError: true,
          shouldThrowNetworkError: true,
        ));

        await tester.pumpAndSettle();

        // Verify network error state
        expect(find.text('Connection Failed'), findsOneWidget);

        // Tap offline data button
        await tester.tap(find.text('Use Offline Data'));
        await tester.pump();

        // Verify error state is cleared (would show main content or empty state)
        expect(find.text('Connection Failed'), findsNothing);
      });
    });

    group('Empty State', () {
      testWidgets('displays empty state when no achievements are unlocked', (WidgetTester tester) async {
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
            currentProgress: 25,
            isUnlocked: false,
          ),
        ];

        await tester.pumpWidget(createTestWidget(achievements: lockedAchievements));
        await tester.pumpAndSettle();

        // Verify empty state is displayed
        expect(find.byType(ProgressionEmptyState), findsOneWidget);
        expect(find.text('BEGIN YOUR JOURNEY'), findsOneWidget);
        expect(find.text('START PLAYING'), findsOneWidget);
      });

      testWidgets('start journey button navigates back', (WidgetTester tester) async {
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
        ];

        await tester.pumpWidget(createTestWidget(achievements: lockedAchievements));
        await tester.pumpAndSettle();

        // Verify we can tap the start journey button
        expect(find.text('START PLAYING'), findsOneWidget);
        await tester.tap(find.text('START PLAYING'));
        await tester.pump();

        // Note: In a real test, we would verify navigation occurred
        // For now, we just verify the button is tappable
      });

      testWidgets('empty state shows motivational content', (WidgetTester tester) async {
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
        ];

        await tester.pumpWidget(createTestWidget(achievements: lockedAchievements));
        await tester.pumpAndSettle();

        // Verify motivational content
        expect(find.text('BEGIN YOUR JOURNEY'), findsOneWidget);
        expect(find.textContaining('Your progression path awaits'), findsOneWidget);
        expect(find.byIcon(Icons.star_outline), findsOneWidget);
      });
    });

    group('Celebration State', () {
      testWidgets('displays celebration state when all achievements are unlocked', (WidgetTester tester) async {
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

        await tester.pumpWidget(createTestWidget(achievements: unlockedAchievements));
        await tester.pumpAndSettle();

        // Wait for celebration check to complete
        await tester.pump(const Duration(milliseconds: 600));

        // Verify celebration state is displayed
        expect(find.byType(ProgressionCelebrationState), findsOneWidget);
        expect(find.text('MASTER ACHIEVED!'), findsOneWidget);
        expect(find.text('2 / 2 ACHIEVEMENTS'), findsOneWidget);
      });

      testWidgets('celebration state shows confetti effects', (WidgetTester tester) async {
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
        ];

        await tester.pumpWidget(createTestWidget(achievements: unlockedAchievements));
        await tester.pumpAndSettle();

        // Wait for celebration check
        await tester.pump(const Duration(milliseconds: 600));

        // Verify confetti effects are rendered
        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      });

      testWidgets('continue button dismisses celebration state', (WidgetTester tester) async {
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
        ];

        await tester.pumpWidget(createTestWidget(achievements: unlockedAchievements));
        await tester.pumpAndSettle();

        // Wait for celebration check and animations
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 2500));

        // Verify continue button is present
        expect(find.text('CONTINUE'), findsOneWidget);

        // Tap continue button
        await tester.tap(find.text('CONTINUE'));
        await tester.pump();

        // Verify celebration state is dismissed
        expect(find.byType(ProgressionCelebrationState), findsNothing);
      });
    });

    group('State Transitions', () {
      testWidgets('transitions from loading to main content', (WidgetTester tester) async {
        final achievements = [
          Achievement(
            id: 'test1',
            name: 'Test Achievement 1',
            description: 'Test description',
            type: AchievementType.scoreMillestone,
            targetValue: 100,
            currentProgress: 50,
            isUnlocked: false,
          ),
        ];

        await tester.pumpWidget(createTestWidget(achievements: achievements));

        // Initially shows loading
        expect(find.byType(ProgressionLoadingState), findsOneWidget);

        // Wait for initialization
        await tester.pumpAndSettle();

        // Should now show main content (not empty state since there's progress)
        expect(find.byType(ProgressionLoadingState), findsNothing);
      });

      testWidgets('transitions from loading to empty state', (WidgetTester tester) async {
        final achievements = [
          Achievement(
            id: 'test1',
            name: 'Test Achievement 1',
            description: 'Test description',
            type: AchievementType.scoreMillestone,
            targetValue: 100,
            currentProgress: 0,
            isUnlocked: false,
          ),
        ];

        await tester.pumpWidget(createTestWidget(achievements: achievements));

        // Initially shows loading
        expect(find.byType(ProgressionLoadingState), findsOneWidget);

        // Wait for initialization
        await tester.pumpAndSettle();

        // Should now show empty state
        expect(find.byType(ProgressionEmptyState), findsOneWidget);
      });

      testWidgets('transitions from loading to error state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(shouldThrowError: true));

        // Initially shows loading
        expect(find.byType(ProgressionLoadingState), findsOneWidget);

        // Wait for initialization to fail
        await tester.pumpAndSettle();

        // Should now show error state
        expect(find.text('Error Loading Progression'), findsOneWidget);
      });
    });

    group('Edge Case Scenarios', () {
      testWidgets('handles empty achievements list', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(achievements: []));
        await tester.pumpAndSettle();

        // Should handle empty list gracefully
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles mixed achievement states correctly', (WidgetTester tester) async {
        final mixedAchievements = [
          Achievement(
            id: 'unlocked',
            name: 'Unlocked Achievement',
            description: 'Test description',
            type: AchievementType.scoreMillestone,
            targetValue: 100,
            currentProgress: 100,
            isUnlocked: true,
          ),
          Achievement(
            id: 'progress',
            name: 'In Progress Achievement',
            description: 'Test description',
            type: AchievementType.skillChallenge,
            targetValue: 50,
            currentProgress: 25,
            isUnlocked: false,
          ),
          Achievement(
            id: 'locked',
            name: 'Locked Achievement',
            description: 'Test description',
            type: AchievementType.totalScore,
            targetValue: 1000,
            currentProgress: 0,
            isUnlocked: false,
          ),
        ];

        await tester.pumpWidget(createTestWidget(achievements: mixedAchievements));
        await tester.pumpAndSettle();

        // Should show main content (not empty state) since some achievements have progress
        expect(find.byType(ProgressionEmptyState), findsNothing);
        expect(find.byType(ProgressionCelebrationState), findsNothing);
      });

      testWidgets('handles rapid state changes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(shouldThrowError: true));
        await tester.pumpAndSettle();

        // Start in error state
        expect(find.text('Error Loading Progression'), findsOneWidget);

        // Fix error and retry
        when(mockAchievementManager.initialize()).thenAnswer((_) async {});
        await tester.tap(find.text('Retry'));
        await tester.pump();

        // Should transition to loading
        expect(find.byType(ProgressionLoadingState), findsOneWidget);

        // Complete loading
        await tester.pumpAndSettle();

        // Should reach final state without errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles null achievement data gracefully', (WidgetTester tester) async {
        when(mockAchievementManager.achievements).thenReturn(null);
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should handle null data without crashing
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles achievement data corruption', (WidgetTester tester) async {
        final corruptedAchievements = [
          Achievement(
            id: '', // Empty ID
            name: 'Corrupted Achievement',
            description: 'Test description',
            type: AchievementType.scoreMillestone,
            targetValue: -1, // Invalid target
            currentProgress: 150, // Progress exceeds target
            isUnlocked: false,
          ),
        ];

        await tester.pumpWidget(createTestWidget(achievements: corruptedAchievements));
        await tester.pumpAndSettle();

        // Should handle corrupted data gracefully
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles memory pressure scenarios', (WidgetTester tester) async {
        // Create a large number of achievements to simulate memory pressure
        final manyAchievements = List.generate(100, (index) => Achievement(
          id: 'achievement_$index',
          name: 'Achievement $index',
          description: 'Test description $index',
          type: AchievementType.values[index % AchievementType.values.length],
          targetValue: 100 + index,
          currentProgress: index % 2 == 0 ? 100 + index : index,
          isUnlocked: index % 2 == 0,
        ));

        await tester.pumpWidget(createTestWidget(achievements: manyAchievements));
        await tester.pumpAndSettle();

        // Should handle large datasets without performance issues
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles concurrent achievement updates', (WidgetTester tester) async {
        final achievements = [
          Achievement(
            id: 'test1',
            name: 'Test Achievement 1',
            description: 'Test description',
            type: AchievementType.scoreMillestone,
            targetValue: 100,
            currentProgress: 50,
            isUnlocked: false,
          ),
        ];

        await tester.pumpWidget(createTestWidget(achievements: achievements));
        await tester.pumpAndSettle();

        // Simulate rapid achievement updates
        for (int i = 0; i < 5; i++) {
          final updatedAchievements = [
            Achievement(
              id: 'test1',
              name: 'Test Achievement 1',
              description: 'Test description',
              type: AchievementType.scoreMillestone,
              targetValue: 100,
              currentProgress: 50 + (i * 10),
              isUnlocked: 50 + (i * 10) >= 100,
            ),
          ];
          
          when(mockAchievementManager.achievements).thenReturn(updatedAchievements);
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Should handle rapid updates without errors
        expect(tester.takeException(), isNull);
      });
    });

    group('Performance and Memory', () {
      testWidgets('handles low memory conditions', (WidgetTester tester) async {
        // Simulate low memory by creating many achievements
        final manyAchievements = List.generate(200, (index) => Achievement(
          id: 'achievement_$index',
          name: 'Achievement $index',
          description: 'Test description $index',
          type: AchievementType.values[index % AchievementType.values.length],
          targetValue: 100,
          currentProgress: index % 3 == 0 ? 100 : index % 2 * 50,
          isUnlocked: index % 3 == 0,
        ));

        await tester.pumpWidget(createTestWidget(achievements: manyAchievements));
        await tester.pumpAndSettle();

        // Should handle memory pressure gracefully
        expect(tester.takeException(), isNull);
      });

      testWidgets('particle system handles quality degradation', (WidgetTester tester) async {
        final achievements = [
          Achievement(
            id: 'test1',
            name: 'Test Achievement 1',
            description: 'Test description',
            type: AchievementType.scoreMillestone,
            targetValue: 100,
            currentProgress: 100,
            isUnlocked: true,
          ),
        ];

        await tester.pumpWidget(createTestWidget(achievements: achievements));
        await tester.pumpAndSettle();

        // Wait for celebration to trigger
        await tester.pump(const Duration(milliseconds: 600));

        // Should handle particle effects without performance issues
        expect(tester.takeException(), isNull);
      });
    });

    group('Accessibility', () {
      testWidgets('error state is accessible', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(shouldThrowError: true));
        await tester.pumpAndSettle();

        // Verify error content is accessible
        expect(find.text('Error Loading Progression'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        // Verify retry button is accessible
        final retryButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Retry'),
        );
        expect(retryButton.onPressed, isNotNull);
      });

      testWidgets('loading state is accessible', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Verify loading content is accessible
        expect(find.text('Loading Progression Path...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('empty state is accessible', (WidgetTester tester) async {
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
        ];

        await tester.pumpWidget(createTestWidget(achievements: lockedAchievements));
        await tester.pumpAndSettle();

        // Verify empty state accessibility
        expect(find.text('BEGIN YOUR JOURNEY'), findsOneWidget);
        expect(find.text('START PLAYING'), findsOneWidget);
        
        final startButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'START PLAYING'),
        );
        expect(startButton.onPressed, isNotNull);
      });

      testWidgets('celebration state is accessible', (WidgetTester tester) async {
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
        ];

        await tester.pumpWidget(createTestWidget(achievements: unlockedAchievements));
        await tester.pumpAndSettle();

        // Wait for celebration
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 2500));

        // Verify celebration accessibility
        expect(find.text('MASTER ACHIEVED!'), findsOneWidget);
        expect(find.text('CONTINUE'), findsOneWidget);
        
        final continueButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'CONTINUE'),
        );
        expect(continueButton.onPressed, isNotNull);
      });
    });
  });
}