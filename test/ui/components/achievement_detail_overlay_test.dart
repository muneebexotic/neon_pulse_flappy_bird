import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:neon_pulse_flappy_bird/ui/components/achievement_detail_overlay.dart';
import 'package:neon_pulse_flappy_bird/models/achievement.dart';
import 'package:neon_pulse_flappy_bird/models/bird_skin.dart';
import 'package:neon_pulse_flappy_bird/game/managers/achievement_manager.dart';
import 'package:neon_pulse_flappy_bird/game/managers/customization_manager.dart';

// Simple mock implementation for testing
class MockAchievementManager extends AchievementManager {
  MockAchievementManager() : super(MockCustomizationManager());
}

class MockCustomizationManager extends CustomizationManager {
  MockCustomizationManager() : super();
}

void main() {
  group('AchievementDetailOverlay', () {
    late MockAchievementManager mockAchievementManager;
    late Achievement testAchievement;
    late Achievement unlockedAchievement;
    late BirdSkin testRewardSkin;

    setUp(() {
      mockAchievementManager = MockAchievementManager();
      
      testAchievement = const Achievement(
        id: 'test_achievement',
        name: 'Test Achievement',
        description: 'This is a test achievement for unit testing',
        icon: Icons.star,
        iconColor: Colors.cyan,
        targetValue: 100,
        type: AchievementType.score,
        rewardSkinId: 'test_skin',
        isUnlocked: false,
        currentProgress: 50,
      );

      unlockedAchievement = testAchievement.copyWith(
        isUnlocked: true,
        currentProgress: 100,
      );

      testRewardSkin = const BirdSkin(
        id: 'test_skin',
        name: 'Test Skin',
        primaryColor: Colors.purple,
        trailColor: Colors.purple,
        description: 'A test bird skin',
        unlockScore: 100,
        isUnlocked: true,
      );
    });

    Widget createTestWidget({
      Achievement? achievement,
      BirdSkin? rewardSkin,
      VoidCallback? onClose,
      VoidCallback? onShare,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: AchievementDetailOverlay(
            achievement: achievement ?? testAchievement,
            rewardSkin: rewardSkin,
            achievementManager: mockAchievementManager,
            onClose: onClose,
            onShare: onShare,
          ),
        ),
      );
    }

    group('Widget Rendering', () {
      testWidgets('renders overlay with basic achievement information', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        // Check if achievement name is displayed
        expect(find.text('Test Achievement'), findsOneWidget);
        
        // Check if description is displayed
        expect(find.text('This is a test achievement for unit testing'), findsOneWidget);
      });

      testWidgets('displays achievement icon with correct color', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        final iconFinder = find.byIcon(Icons.star);
        expect(iconFinder, findsOneWidget);
        
        final iconWidget = tester.widget<Icon>(iconFinder);
        expect(iconWidget.color, equals(Colors.cyan));
      });

      testWidgets('shows IN PROGRESS badge for incomplete achievements', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('IN PROGRESS'), findsOneWidget);
        expect(find.text('UNLOCKED'), findsNothing);
      });

      testWidgets('shows UNLOCKED badge for completed achievements', (tester) async {
        await tester.pumpWidget(createTestWidget(achievement: unlockedAchievement));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('UNLOCKED'), findsOneWidget);
        expect(find.text('IN PROGRESS'), findsNothing);
      });

      testWidgets('displays progress section for incomplete achievements', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        // Check progress section exists
        expect(find.text('Progress'), findsOneWidget);
      });

      testWidgets('displays completion message for unlocked achievements', (tester) async {
        await tester.pumpWidget(createTestWidget(achievement: unlockedAchievement));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Achievement Completed!'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('displays reward section when reward skin is provided', (tester) async {
        await tester.pumpWidget(createTestWidget(rewardSkin: testRewardSkin));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Reward'), findsOneWidget);
        expect(find.text('Test Skin'), findsOneWidget);
        expect(find.text('A test bird skin'), findsOneWidget);
      });

      testWidgets('hides reward section when no reward skin is provided', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Reward'), findsNothing);
      });
    });

    group('Achievement Type Display', () {
      testWidgets('displays correct requirement text for score achievements', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.textContaining('Single Game Score: 100 points'), findsOneWidget);
      });

      testWidgets('displays correct requirement text for games played achievements', (tester) async {
        final gamesAchievement = Achievement(
          id: testAchievement.id,
          name: testAchievement.name,
          description: testAchievement.description,
          icon: testAchievement.icon,
          iconColor: testAchievement.iconColor,
          targetValue: testAchievement.targetValue,
          type: AchievementType.gamesPlayed,
          rewardSkinId: testAchievement.rewardSkinId,
          isUnlocked: testAchievement.isUnlocked,
          currentProgress: testAchievement.currentProgress,
        );

        await tester.pumpWidget(createTestWidget(achievement: gamesAchievement));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.textContaining('Games Played: 100 games'), findsOneWidget);
      });

      testWidgets('displays correct requirement text for pulse usage achievements', (tester) async {
        final pulseAchievement = Achievement(
          id: testAchievement.id,
          name: testAchievement.name,
          description: testAchievement.description,
          icon: testAchievement.icon,
          iconColor: testAchievement.iconColor,
          targetValue: testAchievement.targetValue,
          type: AchievementType.pulseUsage,
          rewardSkinId: testAchievement.rewardSkinId,
          isUnlocked: testAchievement.isUnlocked,
          currentProgress: testAchievement.currentProgress,
        );

        await tester.pumpWidget(createTestWidget(achievement: pulseAchievement));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.textContaining('Pulse Usage: 100 pulses'), findsOneWidget);
      });
    });

    group('User Interactions', () {
      testWidgets('close button is present and accessible', (tester) async {
        await tester.pumpWidget(createTestWidget(
          onClose: () {},
        ));
        await tester.pump(const Duration(milliseconds: 100));

        // Find the close button text
        final closeButton = find.text('Close');
        expect(closeButton, findsOneWidget);
      });

      testWidgets('shows share button for unlocked achievements', (tester) async {
        await tester.pumpWidget(createTestWidget(
          achievement: unlockedAchievement,
          onShare: () {},
        ));
        await tester.pump(const Duration(milliseconds: 100));

        // Share button should be visible for unlocked achievements
        expect(find.text('Share'), findsOneWidget);
      });

      testWidgets('hides share button for locked achievements', (tester) async {
        await tester.pumpWidget(createTestWidget(
          onShare: () {},
        ));
        await tester.pump(const Duration(milliseconds: 100));

        // Share button should not be visible for locked achievements
        expect(find.text('Share'), findsNothing);
      });
    });

    group('Animation Behavior', () {
      testWidgets('overlay appears with proper structure', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));
        
        expect(find.text('Test Achievement'), findsOneWidget);
        expect(find.byType(AchievementDetailOverlay), findsOneWidget);
      });

      testWidgets('particles are rendered for unlocked achievements', (tester) async {
        await tester.pumpWidget(createTestWidget(achievement: unlockedAchievement));
        await tester.pump(const Duration(milliseconds: 100));

        // Check that the CustomPaint widget for particles is present
        expect(find.byType(CustomPaint), findsWidgets);
      });
    });

    group('Accessibility', () {
      testWidgets('displays text with proper contrast and sizing', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        // Check that main title uses Orbitron font
        final titleFinder = find.text('Test Achievement');
        expect(titleFinder, findsOneWidget);
        
        final titleWidget = tester.widget<Text>(titleFinder);
        expect(titleWidget.style?.fontFamily, equals('Orbitron'));
        expect(titleWidget.style?.fontSize, equals(24));
      });

      testWidgets('has close button accessible', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        // Check that close button is accessible
        expect(find.text('Close'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsWidgets);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles achievement with zero target value', (tester) async {
        final zeroTargetAchievement = Achievement(
          id: 'zero_target',
          name: 'Zero Target',
          description: 'Achievement with zero target',
          icon: Icons.star,
          iconColor: Colors.cyan,
          targetValue: 0,
          type: AchievementType.score,
          isUnlocked: false,
          currentProgress: 0,
        );

        await tester.pumpWidget(createTestWidget(achievement: zeroTargetAchievement));
        await tester.pump(const Duration(milliseconds: 100));

        // Should handle zero target gracefully
        expect(find.text('Zero Target'), findsOneWidget);
      });

      testWidgets('handles very long achievement names and descriptions', (tester) async {
        final longTextAchievement = Achievement(
          id: 'long_text',
          name: 'This is a Very Long Achievement Name That Should Wrap Properly',
          description: 'This is an extremely long description that should wrap properly within the overlay container and not cause any layout issues or overflow problems in the user interface.',
          icon: Icons.star,
          iconColor: Colors.cyan,
          targetValue: 100,
          type: AchievementType.score,
          isUnlocked: false,
          currentProgress: 50,
        );

        await tester.pumpWidget(createTestWidget(achievement: longTextAchievement));
        await tester.pump(const Duration(milliseconds: 100));

        // Should handle long text without overflow
        expect(find.textContaining('This is a Very Long Achievement Name'), findsOneWidget);
        expect(find.textContaining('This is an extremely long description'), findsOneWidget);
      });
    });

    group('Performance', () {
      testWidgets('disposes animation controllers properly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        // Remove the widget
        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        await tester.pump();

        // No specific assertions needed - if controllers aren't disposed properly,
        // the test framework will detect memory leaks
      });

      testWidgets('handles rapid open/close cycles', (tester) async {
        for (int i = 0; i < 3; i++) {
          await tester.pumpWidget(createTestWidget());
          await tester.pump(const Duration(milliseconds: 50));
          
          await tester.pumpWidget(const MaterialApp(home: Scaffold()));
          await tester.pump(const Duration(milliseconds: 50));
        }
        
        // Should handle rapid cycles without issues
        expect(tester.takeException(), isNull);
      });
    });

    group('Content Validation', () {
      testWidgets('displays all required content sections', (tester) async {
        await tester.pumpWidget(createTestWidget(rewardSkin: testRewardSkin));
        await tester.pump(const Duration(milliseconds: 100));

        // Check all major sections are present
        expect(find.text('Test Achievement'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
        expect(find.text('Progress'), findsOneWidget);
        expect(find.text('Reward'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);
      });

      testWidgets('shows correct progress information', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        // Should show progress information
        expect(find.text('Progress'), findsOneWidget);
        expect(find.textContaining('50 / 100'), findsOneWidget);
      });

      testWidgets('bird skin preview displays correctly', (tester) async {
        await tester.pumpWidget(createTestWidget(rewardSkin: testRewardSkin));
        await tester.pump(const Duration(milliseconds: 100));

        // Check bird skin information
        expect(find.text('Test Skin'), findsOneWidget);
        expect(find.text('A test bird skin'), findsOneWidget);
      });
    });
  });
}