import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/game/managers/haptic_manager.dart';
import 'package:neon_pulse_flappy_bird/game/managers/accessibility_manager.dart';
import 'package:neon_pulse_flappy_bird/game/managers/settings_manager.dart';

void main() {
  group('Accessibility Features Tests', () {
    late HapticManager hapticManager;
    late AccessibilityManager accessibilityManager;
    late SettingsManager settingsManager;

    setUp(() {
      hapticManager = HapticManager();
      accessibilityManager = AccessibilityManager();
      settingsManager = SettingsManager();
    });

    group('HapticManager Tests', () {
      test('should initialize with default settings', () {
        expect(hapticManager.hapticEnabled, isTrue);
        expect(hapticManager.vibrationEnabled, isTrue);
      });

      test('should allow enabling/disabling haptic feedback', () {
        hapticManager.setHapticEnabled(false);
        expect(hapticManager.hapticEnabled, isFalse);

        hapticManager.setHapticEnabled(true);
        expect(hapticManager.hapticEnabled, isTrue);
      });

      test('should allow enabling/disabling vibration', () {
        hapticManager.setVibrationEnabled(false);
        expect(hapticManager.vibrationEnabled, isFalse);

        hapticManager.setVibrationEnabled(true);
        expect(hapticManager.vibrationEnabled, isTrue);
      });

      test('should handle haptic feedback calls gracefully when disabled', () async {
        hapticManager.setHapticEnabled(false);
        
        // These should not throw exceptions
        await hapticManager.lightImpact();
        await hapticManager.mediumImpact();
        await hapticManager.heavyImpact();
        await hapticManager.selectionClick();
      });

      test('should handle vibration calls gracefully when disabled', () async {
        hapticManager.setVibrationEnabled(false);
        
        // These should not throw exceptions
        await hapticManager.pulseActivation();
        await hapticManager.collisionVibration();
        await hapticManager.powerUpVibration();
        await hapticManager.scoreMilestoneVibration();
        await hapticManager.uiFeedback();
      });
    });

    group('AccessibilityManager Tests', () {
      test('should initialize with default settings', () {
        expect(accessibilityManager.highContrastMode, isFalse);
        expect(accessibilityManager.reducedMotion, isFalse);
        expect(accessibilityManager.colorBlindFriendly, isFalse);
        expect(accessibilityManager.soundBasedFeedback, isFalse);
        expect(accessibilityManager.largeText, isFalse);
        expect(accessibilityManager.uiScale, equals(1.0));
      });

      test('should allow toggling high contrast mode', () async {
        await accessibilityManager.setHighContrastMode(true);
        expect(accessibilityManager.highContrastMode, isTrue);

        await accessibilityManager.setHighContrastMode(false);
        expect(accessibilityManager.highContrastMode, isFalse);
      });

      test('should allow toggling reduced motion', () async {
        await accessibilityManager.setReducedMotion(true);
        expect(accessibilityManager.reducedMotion, isTrue);

        await accessibilityManager.setReducedMotion(false);
        expect(accessibilityManager.reducedMotion, isFalse);
      });

      test('should allow toggling color blind friendly mode', () async {
        await accessibilityManager.setColorBlindFriendly(true);
        expect(accessibilityManager.colorBlindFriendly, isTrue);

        await accessibilityManager.setColorBlindFriendly(false);
        expect(accessibilityManager.colorBlindFriendly, isFalse);
      });

      test('should allow setting color blind type', () async {
        await accessibilityManager.setColorBlindType(ColorBlindType.protanopia);
        expect(accessibilityManager.colorBlindType, equals(ColorBlindType.protanopia));

        await accessibilityManager.setColorBlindType(ColorBlindType.deuteranopia);
        expect(accessibilityManager.colorBlindType, equals(ColorBlindType.deuteranopia));

        await accessibilityManager.setColorBlindType(ColorBlindType.tritanopia);
        expect(accessibilityManager.colorBlindType, equals(ColorBlindType.tritanopia));
      });

      test('should allow toggling sound based feedback', () async {
        await accessibilityManager.setSoundBasedFeedback(true);
        expect(accessibilityManager.soundBasedFeedback, isTrue);

        await accessibilityManager.setSoundBasedFeedback(false);
        expect(accessibilityManager.soundBasedFeedback, isFalse);
      });

      test('should allow toggling large text', () async {
        await accessibilityManager.setLargeText(true);
        expect(accessibilityManager.largeText, isTrue);

        await accessibilityManager.setLargeText(false);
        expect(accessibilityManager.largeText, isFalse);
      });

      test('should clamp UI scale to valid range', () async {
        await accessibilityManager.setUiScale(0.5); // Below minimum
        expect(accessibilityManager.uiScale, equals(0.8));

        await accessibilityManager.setUiScale(2.0); // Above maximum
        expect(accessibilityManager.uiScale, equals(1.5));

        await accessibilityManager.setUiScale(1.2); // Valid value
        expect(accessibilityManager.uiScale, equals(1.2));
      });

      test('should calculate correct text scale factor', () async {
        // Default settings
        expect(accessibilityManager.getTextScaleFactor(), equals(1.0));

        // With large text enabled
        await accessibilityManager.setLargeText(true);
        expect(accessibilityManager.getTextScaleFactor(), equals(1.2));

        // With UI scale changed
        await accessibilityManager.setUiScale(1.5);
        expect(accessibilityManager.getTextScaleFactor(), equals(1.8)); // 1.5 * 1.2
      });

      test('should calculate correct animation duration multiplier', () async {
        // Default settings
        expect(accessibilityManager.getAnimationDurationMultiplier(), equals(1.0));

        // With reduced motion enabled
        await accessibilityManager.setReducedMotion(true);
        expect(accessibilityManager.getAnimationDurationMultiplier(), equals(0.3));
      });

      test('should handle sound feedback calls gracefully when disabled', () async {
        await accessibilityManager.setSoundBasedFeedback(false);
        
        // These should not throw exceptions
        await accessibilityManager.playSoundFeedback(SoundFeedbackType.obstacleApproaching);
        await accessibilityManager.playSoundFeedback(SoundFeedbackType.powerUpAvailable);
        await accessibilityManager.playSoundFeedback(SoundFeedbackType.pulseReady);
        await accessibilityManager.playSoundFeedback(SoundFeedbackType.scoreIncrement);
        await accessibilityManager.playSoundFeedback(SoundFeedbackType.dangerZone);
      });
    });

    group('SettingsManager Accessibility Integration Tests', () {
      test('should persist haptic settings', () async {
        await settingsManager.setHapticEnabled(false);
        expect(settingsManager.hapticEnabled, isFalse);

        await settingsManager.setVibrationEnabled(false);
        expect(settingsManager.vibrationEnabled, isFalse);
      });

      test('should persist accessibility settings', () async {
        await settingsManager.setHighContrastMode(true);
        expect(settingsManager.highContrastMode, isTrue);

        await settingsManager.setReducedMotion(true);
        expect(settingsManager.reducedMotion, isTrue);

        await settingsManager.setColorBlindFriendly(true);
        expect(settingsManager.colorBlindFriendly, isTrue);

        await settingsManager.setSoundBasedFeedback(true);
        expect(settingsManager.soundBasedFeedback, isTrue);

        await settingsManager.setLargeText(true);
        expect(settingsManager.largeText, isTrue);

        await settingsManager.setUiScale(1.3);
        expect(settingsManager.uiScale, equals(1.3));
      });

      test('should clamp UI scale in settings manager', () async {
        await settingsManager.setUiScale(0.5); // Below minimum
        expect(settingsManager.uiScale, equals(0.8));

        await settingsManager.setUiScale(2.0); // Above maximum
        expect(settingsManager.uiScale, equals(1.5));
      });
    });

    group('Color Accessibility Tests', () {
      test('should return original color when color blind friendly is disabled', () {
        const testColor = Color(0xFFFF0000); // Red
        accessibilityManager.setColorBlindFriendly(false);
        
        final result = accessibilityManager.getAccessibleColor(testColor);
        expect(result, equals(testColor));
      });

      test('should adjust colors for protanopia', () async {
        const redColor = Color(0xFFFF0000); // Pure red
        await accessibilityManager.setColorBlindFriendly(true);
        await accessibilityManager.setColorBlindType(ColorBlindType.protanopia);
        
        final result = accessibilityManager.getAccessibleColor(redColor);
        // Should be converted to orange/yellow
        expect(result, isNot(equals(redColor)));
      });

      test('should adjust colors for deuteranopia', () async {
        const greenColor = Color(0xFF00FF00); // Pure green
        await accessibilityManager.setColorBlindFriendly(true);
        await accessibilityManager.setColorBlindType(ColorBlindType.deuteranopia);
        
        final result = accessibilityManager.getAccessibleColor(greenColor);
        // Should be converted to blue/cyan
        expect(result, isNot(equals(greenColor)));
      });

      test('should adjust colors for tritanopia', () async {
        const blueColor = Color(0xFF0000FF); // Pure blue
        await accessibilityManager.setColorBlindFriendly(true);
        await accessibilityManager.setColorBlindType(ColorBlindType.tritanopia);
        
        final result = accessibilityManager.getAccessibleColor(blueColor);
        // Should be converted to purple/magenta
        expect(result, isNot(equals(blueColor)));
      });
    });

    group('Semantic Labels Tests', () {
      test('should provide appropriate semantic labels for game elements', () {
        final birdLabel = accessibilityManager.getSemanticLabel(
          GameElement.bird,
          context: {'position': 'center'},
        );
        expect(birdLabel, contains('Cyberpunk bird'));
        expect(birdLabel, contains('center'));

        final obstacleLabel = accessibilityManager.getSemanticLabel(
          GameElement.obstacle,
          context: {'distance': 'nearby'},
        );
        expect(obstacleLabel, contains('Digital barrier'));
        expect(obstacleLabel, contains('nearby'));

        final scoreLabel = accessibilityManager.getSemanticLabel(
          GameElement.score,
          context: {'score': 42},
        );
        expect(scoreLabel, contains('Current score: 42'));

        final pulseReadyLabel = accessibilityManager.getSemanticLabel(
          GameElement.pulseIndicator,
          context: {'ready': true},
        );
        expect(pulseReadyLabel, contains('Energy pulse ready'));
        expect(pulseReadyLabel, contains('double tap'));

        final pulseChargingLabel = accessibilityManager.getSemanticLabel(
          GameElement.pulseIndicator,
          context: {'ready': false},
        );
        expect(pulseChargingLabel, contains('Energy pulse charging'));
      });
    });
  });
}