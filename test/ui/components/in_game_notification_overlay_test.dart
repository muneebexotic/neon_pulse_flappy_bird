import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/ui/components/in_game_notification_overlay.dart';
import 'package:neon_pulse_flappy_bird/models/achievement.dart';
import 'package:neon_pulse_flappy_bird/models/bird_skin.dart';
import 'package:neon_pulse_flappy_bird/game/effects/neon_colors.dart';

void main() {
  group('InGameNotificationOverlay', () {
    testWidgets('should display notification overlay when visible', (WidgetTester tester) async {
      final overlayKey = InGameNotificationOverlay.createKey();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.black),
                InGameNotificationOverlay(
                  key: overlayKey,
                  isVisible: true,
                ),
              ],
            ),
          ),
        ),
      );

      // Initially no notifications should be visible
      expect(find.byType(InGameNotificationOverlay), findsOneWidget);
    });

    testWidgets('should show achievement unlock notification', (WidgetTester tester) async {
      final overlayKey = InGameNotificationOverlay.createKey();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.black),
                InGameNotificationOverlay(
                  key: overlayKey,
                  isVisible: true,
                ),
              ],
            ),
          ),
        ),
      );

      // Create a test achievement
      final achievement = Achievement(
        id: 'test_achievement',
        name: 'Test Achievement',
        description: 'A test achievement for unit testing',
        icon: Icons.star,
        iconColor: NeonColors.electricBlue,
        targetValue: 100,
        currentProgress: 100,
        type: AchievementType.score,
        isUnlocked: true,
      );

      // Show the achievement notification
      overlayKey.showAchievementUnlock(achievement);
      
      // Pump the widget to trigger animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the notification is displayed
      expect(find.text('Test Achievement'), findsOneWidget);
      expect(find.text('A test achievement for unit testing'), findsOneWidget);
    });

    testWidgets('should show progress milestone notification', (WidgetTester tester) async {
      final overlayKey = InGameNotificationOverlay.createKey();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.black),
                InGameNotificationOverlay(
                  key: overlayKey,
                  isVisible: true,
                ),
              ],
            ),
          ),
        ),
      );

      // Create a test achievement
      final achievement = Achievement(
        id: 'test_progress',
        name: 'Progress Achievement',
        description: 'A progress achievement for testing',
        icon: Icons.trending_up,
        iconColor: NeonColors.neonGreen,
        targetValue: 100,
        currentProgress: 50,
        type: AchievementType.score,
        isUnlocked: false,
      );

      // Show the progress milestone notification (50%)
      overlayKey.showProgressMilestone(achievement, 0.5);
      
      // Pump the widget to trigger animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the milestone notification is displayed
      expect(find.text('50% Progress'), findsOneWidget);
      expect(find.text('Progress Achievement'), findsOneWidget);
    });

    testWidgets('should show skin unlock notification', (WidgetTester tester) async {
      final overlayKey = InGameNotificationOverlay.createKey();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.black),
                InGameNotificationOverlay(
                  key: overlayKey,
                  isVisible: true,
                ),
              ],
            ),
          ),
        ),
      );

      // Create a test skin
      final skin = BirdSkin(
        id: 'test_skin',
        name: 'Test Skin',
        description: 'A test skin for unit testing',
        primaryColor: NeonColors.hotPink,
        trailColor: NeonColors.electricBlue,
        unlockScore: 0,
        isUnlocked: true,
      );

      // Show the skin unlock notification
      overlayKey.showSkinUnlock(skin);
      
      // Pump the widget to trigger animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the skin notification is displayed
      expect(find.text('New Skin Unlocked!'), findsOneWidget);
      expect(find.text('Test Skin'), findsOneWidget);
    });

    testWidgets('should limit simultaneous notifications', (WidgetTester tester) async {
      final overlayKey = InGameNotificationOverlay.createKey();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.black),
                InGameNotificationOverlay(
                  key: overlayKey,
                  isVisible: true,
                  maxSimultaneousNotifications: 2,
                ),
              ],
            ),
          ),
        ),
      );

      // Create multiple test achievements
      final achievements = List.generate(5, (index) => Achievement(
        id: 'test_achievement_$index',
        name: 'Test Achievement $index',
        description: 'Test description $index',
        icon: Icons.star,
        iconColor: NeonColors.electricBlue,
        targetValue: 100,
        currentProgress: 100,
        type: AchievementType.score,
        isUnlocked: true,
      ));

      // Show all achievements
      for (final achievement in achievements) {
        overlayKey.showAchievementUnlock(achievement);
      }
      
      // Pump the widget to trigger animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should only show maximum 2 notifications simultaneously
      expect(find.text('Test Achievement 0'), findsOneWidget);
      expect(find.text('Test Achievement 1'), findsOneWidget);
      expect(find.text('Test Achievement 2'), findsNothing);
    });

    testWidgets('should dismiss notifications on tap', (WidgetTester tester) async {
      final overlayKey = InGameNotificationOverlay.createKey();
      bool notificationTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.black),
                InGameNotificationOverlay(
                  key: overlayKey,
                  isVisible: true,
                  onNotificationTapped: (notification) {
                    notificationTapped = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Create a test achievement
      final achievement = Achievement(
        id: 'test_tap',
        name: 'Tap Test',
        description: 'Test tapping functionality',
        icon: Icons.touch_app,
        iconColor: NeonColors.neonYellow,
        targetValue: 100,
        currentProgress: 100,
        type: AchievementType.score,
        isUnlocked: true,
      );

      // Show the achievement notification
      overlayKey.showAchievementUnlock(achievement);
      
      // Pump the widget to trigger animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on the notification
      await tester.tap(find.text('Tap Test'));
      await tester.pump();

      // Verify the callback was called
      expect(notificationTapped, isTrue);
    });
  });
}