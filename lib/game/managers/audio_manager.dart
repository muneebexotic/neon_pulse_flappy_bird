import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages all audio functionality including music and sound effects
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // Audio players
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  
  // Volume settings
  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;
  bool _isMusicEnabled = true;
  bool _isSfxEnabled = true;
  
  // Audio caching
  final Map<String, String> _cachedSounds = {};
  
  // Getters
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSfxEnabled => _isSfxEnabled;

  /// Initialize the audio manager and load settings
  Future<void> initialize() async {
    print('AudioManager: Starting initialization...');
    await _loadSettings();
    print('AudioManager: Settings loaded - Music: $_isMusicEnabled, SFX: $_isSfxEnabled');
    await _preloadSounds();
    _setupAudioPlayers();
    print('AudioManager: Initialization complete');
  }

  /// Load audio settings from shared preferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _musicVolume = prefs.getDouble('music_volume') ?? 0.7;
    _sfxVolume = prefs.getDouble('sfx_volume') ?? 0.8;
    _isMusicEnabled = prefs.getBool('music_enabled') ?? true;
    _isSfxEnabled = prefs.getBool('sfx_enabled') ?? true;
  }

  /// Save audio settings to shared preferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume', _musicVolume);
    await prefs.setDouble('sfx_volume', _sfxVolume);
    await prefs.setBool('music_enabled', _isMusicEnabled);
    await prefs.setBool('sfx_enabled', _isSfxEnabled);
  }

  /// Setup audio player configurations
  void _setupAudioPlayers() {
    print('AudioManager: Setting up audio players...');
    try {
      _musicPlayer.setReleaseMode(ReleaseMode.loop);
      _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      print('AudioManager: Audio players configured successfully');
    } catch (e) {
      print('AudioManager: Error setting up audio players: $e');
    }
  }

  /// Preload commonly used sound effects
  Future<void> _preloadSounds() async {
    final soundFiles = [
      'jump.wav',
      'collision.wav',
      'pulse.wav',
      'score.wav',
      'power_up.wav',
    ];
    
    for (final sound in soundFiles) {
      _cachedSounds[sound] = 'audio/sfx/$sound';
    }
    
    print('AudioManager: Preloaded ${soundFiles.length} sound effect paths');
    print('AudioManager: Note - Some files may be placeholders and will fail to play');
  }

  /// Start playing background music with beat detection and fade-in
  Future<void> playBackgroundMusic(String musicFile, {bool fadeIn = false, Duration fadeDuration = const Duration(milliseconds: 1000)}) async {
    print('AudioManager: Attempting to play background music: $musicFile');
    print('AudioManager: Music enabled: $_isMusicEnabled, Volume: $_musicVolume');
    
    if (!_isMusicEnabled) {
      print('AudioManager: Music is disabled, skipping playback');
      return;
    }
    
    try {
      // Set initial volume (0 if fading in, normal if not)
      final initialVolume = fadeIn ? 0.0 : _musicVolume;
      await _musicPlayer.setVolume(initialVolume);
      
      final assetPath = 'audio/music/$musicFile';
      print('AudioManager: Playing asset: $assetPath');
      
      // Try to play the audio with explicit source
      final source = AssetSource(assetPath);
      print('AudioManager: Created AssetSource: $source');
      
      await _musicPlayer.play(source);
      
      print('AudioManager: Music playback started successfully');
      
      // Fade in if requested
      if (fadeIn) {
        await _fadeInMusic(fadeDuration);
      }
      
    } catch (e) {
      print('AudioManager: Error playing background music: $e');
      print('AudioManager: This is likely because the audio file is missing or invalid');
      print('AudioManager: The game will continue with sound effects only');
      print('AudioManager: See AUDIO_SETUP.md for instructions on adding music files');
    }
  }

  /// Fade in the background music
  Future<void> _fadeInMusic(Duration duration) async {
    const steps = 20;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    final volumeStep = _musicVolume / steps;
    
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);
      await _musicPlayer.setVolume(volumeStep * i);
    }
  }

  /// Fade out the background music
  Future<void> _fadeOutMusic(Duration duration) async {
    const steps = 20;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    final currentVolume = _musicVolume;
    final volumeStep = currentVolume / steps;
    
    for (int i = steps - 1; i >= 0; i--) {
      await Future.delayed(stepDuration);
      await _musicPlayer.setVolume(volumeStep * i);
    }
  }

  /// Stop background music with optional fade-out
  Future<void> stopBackgroundMusic({bool fadeOut = false, Duration fadeDuration = const Duration(milliseconds: 1000)}) async {
    if (fadeOut && _musicPlayer.state == PlayerState.playing) {
      await _fadeOutMusic(fadeDuration);
    }
    await _musicPlayer.stop();
  }

  /// Play a sound effect
  Future<void> playSoundEffect(SoundEffect effect) async {
    print('AudioManager: Attempting to play sound effect: $effect');
    print('AudioManager: SFX enabled: $_isSfxEnabled, Volume: $_sfxVolume');
    
    if (!_isSfxEnabled) {
      print('AudioManager: SFX is disabled, skipping playback');
      return;
    }
    
    final soundFile = _getSoundFile(effect);
    print('AudioManager: Sound file path: $soundFile');
    
    if (soundFile != null) {
      try {
        print('AudioManager: Setting volume to $_sfxVolume');
        await _sfxPlayer.setVolume(_sfxVolume);
        
        print('AudioManager: Creating AssetSource for: $soundFile');
        final source = AssetSource(soundFile);
        
        print('AudioManager: Playing audio...');
        await _sfxPlayer.play(source);
        print('AudioManager: SFX $effect played successfully');
      } catch (e) {
        print('AudioManager: Error playing sound effect $effect: ${e.toString()}');
        print('AudioManager: Error type: ${e.runtimeType}');
        if (e.toString().contains('asset does not exist') || e.toString().contains('empty data')) {
          print('AudioManager: Sound file $soundFile appears to be missing or invalid (likely a placeholder)');
        } else if (e.toString().contains('PlatformException')) {
          print('AudioManager: Platform-specific audio error - this may be a Windows desktop issue');
          print('AudioManager: Try checking Windows audio settings or running on mobile device');
        }
        // Continue silently - don't spam the console with stack traces for missing audio
      }
    } else {
      print('AudioManager: Sound file not found for effect: $effect');
    }
  }

  /// Get the sound file path for a sound effect
  String? _getSoundFile(SoundEffect effect) {
    switch (effect) {
      case SoundEffect.jump:
        return _cachedSounds['jump.wav'];
      case SoundEffect.collision:
        return _cachedSounds['collision.wav'];
      case SoundEffect.pulse:
        return _cachedSounds['pulse.wav'];
      case SoundEffect.score:
        // Fallback: use pulse sound for score if score.wav is missing
        return _cachedSounds['score.wav'] ?? _cachedSounds['pulse.wav'];
      case SoundEffect.powerUp:
        return _cachedSounds['power_up.wav'];
    }
  }


  /// Update music volume
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _musicPlayer.setVolume(_musicVolume);
    await _saveSettings();
  }

  /// Update sound effects volume
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    await _saveSettings();
  }

  /// Toggle music on/off
  Future<void> toggleMusic() async {
    _isMusicEnabled = !_isMusicEnabled;
    if (!_isMusicEnabled) {
      await stopBackgroundMusic();
    } else {
      // Restart background music when enabled
      try {
        await playBackgroundMusic('cyberpunk_theme.mp3');
      } catch (e) {
        print('AudioManager: Failed to restart music after toggle: $e');
      }
    }
    await _saveSettings();
  }

  /// Toggle sound effects on/off
  Future<void> toggleSfx() async {
    _isSfxEnabled = !_isSfxEnabled;
    await _saveSettings();
  }


  /// Check if background music is currently playing
  bool get isMusicPlaying => _musicPlayer.state == PlayerState.playing;
  

  /// Play a beep sound for accessibility feedback
  Future<void> playBeep({required double frequency, required int duration}) async {
    if (!_isSfxEnabled) return;
    
    try {
      // Generate a simple beep tone
      // Note: This is a simplified implementation
      // In a real app, you might want to use a tone generator or pre-recorded beep sounds
      await _sfxPlayer.play(AssetSource('audio/beep.wav'), volume: _sfxVolume * 0.5);
    } catch (e) {
      print('AudioManager: Failed to play beep: $e');
    }
  }

  /// Test audio system functionality
  Future<void> testAudioSystem() async {
    print('AudioManager: Testing audio system...');
    print('AudioManager: Music enabled: $_isMusicEnabled, Volume: $_musicVolume');
    print('AudioManager: SFX enabled: $_isSfxEnabled, Volume: $_sfxVolume');
    
    // Test a simple sound effect
    print('AudioManager: Testing jump sound effect...');
    await playSoundEffect(SoundEffect.jump);
    
    print('AudioManager: Audio system test complete');
  }

  /// Dispose of resources
  void dispose() {
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
  }
}


/// Available sound effects
enum SoundEffect {
  jump,
  collision,
  pulse,
  score,
  powerUp,
}