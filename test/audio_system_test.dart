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

    test('should create beat event with correct properties', () {
      final timestamp = DateTime.now();
      const bpm = 128.0;
      final beatEvent = BeatEvent(timestamp, bpm);
      
      expect(beatEvent.timestamp, equals(timestamp));
      expect(beatEvent.bpm, equals(bpm));
    });

    test('should handle beat event creation with different BPM values', () {
      final now = DateTime.now();
      
      final slowBeat = BeatEvent(now, 60.0);
      expect(slowBeat.bpm, equals(60.0));
      
      final fastBeat = BeatEvent(now, 180.0);
      expect(fastBeat.bpm, equals(180.0));
      
      final normalBeat = BeatEvent(now, 120.0);
      expect(normalBeat.bpm, equals(120.0));
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