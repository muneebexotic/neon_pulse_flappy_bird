import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/game/managers/audio_manager.dart';

void main() {
  group('Audio System Tests', () {
    test('should define all required sound effects', () {
      // Test that all sound effects are defined
      expect(SoundEffect.values.length, equals(5));
      expect(SoundEffect.values, contains(SoundEffect.jump));
      expect(SoundEffect.values, contains(SoundEffect.collision));
      expect(SoundEffect.values, contains(SoundEffect.pulse));
      expect(SoundEffect.values, contains(SoundEffect.score));
      expect(SoundEffect.values, contains(SoundEffect.powerUp));
    });


    test('should validate sound effect enum completeness', () {
      final effectNames = SoundEffect.values.map((e) => e.name).toList();
      
      expect(effectNames, contains('jump'));
      expect(effectNames, contains('collision'));
      expect(effectNames, contains('pulse'));
      expect(effectNames, contains('score'));
      expect(effectNames, contains('powerUp'));
    });
  });
}