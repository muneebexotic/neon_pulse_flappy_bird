import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:neon_pulse_flappy_bird/game/managers/audio_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AudioManager Tests', () {
    late AudioManager audioManager;

    setUp(() {
      audioManager = AudioManager();
    });

    test('should initialize with default settings', () {
      expect(audioManager.musicVolume, equals(0.7));
      expect(audioManager.sfxVolume, equals(0.8));
      expect(audioManager.isMusicEnabled, isTrue);
      expect(audioManager.isSfxEnabled, isTrue);
      expect(audioManager.beatDetectionEnabled, isTrue);
      expect(audioManager.currentBpm, equals(128.0));
    });

    test('should update music volume within valid range', () async {
      await audioManager.setMusicVolume(0.5);
      expect(audioManager.musicVolume, equals(0.5));
      
      // Test clamping
      await audioManager.setMusicVolume(1.5);
      expect(audioManager.musicVolume, equals(1.0));
      
      await audioManager.setMusicVolume(-0.5);
      expect(audioManager.musicVolume, equals(0.0));
    });

    test('should update sfx volume within valid range', () async {
      await audioManager.setSfxVolume(0.3);
      expect(audioManager.sfxVolume, equals(0.3));
      
      // Test clamping
      await audioManager.setSfxVolume(2.0);
      expect(audioManager.sfxVolume, equals(1.0));
      
      await audioManager.setSfxVolume(-1.0);
      expect(audioManager.sfxVolume, equals(0.0));
    });

    test('should toggle music enabled state', () async {
      final initialState = audioManager.isMusicEnabled;
      await audioManager.toggleMusic();
      expect(audioManager.isMusicEnabled, equals(!initialState));
      
      await audioManager.toggleMusic();
      expect(audioManager.isMusicEnabled, equals(initialState));
    });

    test('should toggle sfx enabled state', () async {
      final initialState = audioManager.isSfxEnabled;
      await audioManager.toggleSfx();
      expect(audioManager.isSfxEnabled, equals(!initialState));
      
      await audioManager.toggleSfx();
      expect(audioManager.isSfxEnabled, equals(initialState));
    });

    test('should toggle beat detection enabled state', () async {
      final initialState = audioManager.beatDetectionEnabled;
      await audioManager.toggleBeatDetection();
      expect(audioManager.beatDetectionEnabled, equals(!initialState));
      
      await audioManager.toggleBeatDetection();
      expect(audioManager.beatDetectionEnabled, equals(initialState));
    });

    test('should predict next beat time correctly', () {
      // This test would need to be more sophisticated in a real implementation
      // For now, we test that it returns null when no beat has been detected
      expect(audioManager.getNextBeatTime(), isNull);
    });

    test('should check if beat is expected within time window', () {
      // When no beat has been detected, should return false
      expect(audioManager.isBeatExpected(const Duration(milliseconds: 100)), isFalse);
    });

    test('should handle beat events through stream', () async {
      final beatEvents = <BeatEvent>[];
      final subscription = audioManager.beatStream.listen((event) {
        beatEvents.add(event);
      });

      // Test that beat stream is available
      expect(audioManager.beatStream, isNotNull);
      
      // Test current BPM default value
      expect(audioManager.currentBpm, equals(128.0));
      
      await subscription.cancel();
    });

    test('should handle sound effect enum correctly', () {
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

    tearDown(() {
      audioManager.dispose();
    });
  });

  group('BeatEvent Tests', () {
    test('should create beat event with timestamp and bpm', () {
      final now = DateTime.now();
      const bpm = 120.0;
      final event = BeatEvent(now, bpm);
      
      expect(event.timestamp, equals(now));
      expect(event.bpm, equals(bpm));
    });
  });

  group('SoundEffect Tests', () {
    test('should have all required sound effects', () {
      final effects = SoundEffect.values;
      
      expect(effects, contains(SoundEffect.jump));
      expect(effects, contains(SoundEffect.collision));
      expect(effects, contains(SoundEffect.pulse));
      expect(effects, contains(SoundEffect.score));
      expect(effects, contains(SoundEffect.powerUp));
    });
  });
}