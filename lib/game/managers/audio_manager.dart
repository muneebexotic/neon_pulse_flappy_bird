import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages all audio functionality including music, sound effects, and beat detection
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
  
  // Beat detection
  bool _beatDetectionEnabled = true;
  double _currentBpm = 128.0; // Default BPM
  DateTime? _lastBeatTime;
  Timer? _beatTimer;
  final List<double> _beatIntervals = [];
  
  // Audio caching
  final Map<String, String> _cachedSounds = {};
  
  // Beat synchronization
  final StreamController<BeatEvent> _beatController = StreamController<BeatEvent>.broadcast();
  Stream<BeatEvent> get beatStream => _beatController.stream;
  
  // Getters
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSfxEnabled => _isSfxEnabled;
  bool get beatDetectionEnabled => _beatDetectionEnabled;
  double get currentBpm => _currentBpm;

  /// Initialize the audio manager and load settings
  Future<void> initialize() async {
    await _loadSettings();
    await _preloadSounds();
    _setupAudioPlayers();
  }

  /// Load audio settings from shared preferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _musicVolume = prefs.getDouble('music_volume') ?? 0.7;
    _sfxVolume = prefs.getDouble('sfx_volume') ?? 0.8;
    _isMusicEnabled = prefs.getBool('music_enabled') ?? true;
    _isSfxEnabled = prefs.getBool('sfx_enabled') ?? true;
    _beatDetectionEnabled = prefs.getBool('beat_detection_enabled') ?? true;
  }

  /// Save audio settings to shared preferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume', _musicVolume);
    await prefs.setDouble('sfx_volume', _sfxVolume);
    await prefs.setBool('music_enabled', _isMusicEnabled);
    await prefs.setBool('sfx_enabled', _isSfxEnabled);
    await prefs.setBool('beat_detection_enabled', _beatDetectionEnabled);
  }

  /// Setup audio player configurations
  void _setupAudioPlayers() {
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _sfxPlayer.setReleaseMode(ReleaseMode.stop);
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
      
      if (_beatDetectionEnabled) {
        print('AudioManager: Starting beat detection');
        _startBeatDetection();
      } else {
        print('AudioManager: Beat detection is disabled');
      }
    } catch (e) {
      print('AudioManager: Error playing background music: $e');
      print('AudioManager: This is likely because the audio file is missing or invalid');
      print('AudioManager: The game will continue with sound effects only');
      print('AudioManager: See AUDIO_SETUP.md for instructions on adding music files');
      startBeatGenerationWithoutMusic();
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

  /// Stop background music and beat detection with optional fade-out
  Future<void> stopBackgroundMusic({bool fadeOut = false, Duration fadeDuration = const Duration(milliseconds: 1000)}) async {
    if (fadeOut && _musicPlayer.state == PlayerState.playing) {
      await _fadeOutMusic(fadeDuration);
    }
    await _musicPlayer.stop();
    _stopBeatDetection();
  }

  /// Play a sound effect
  Future<void> playSoundEffect(SoundEffect effect) async {
    print('AudioManager: Attempting to play sound effect: $effect');
    
    if (!_isSfxEnabled) {
      print('AudioManager: SFX is disabled, skipping playback');
      return;
    }
    
    final soundFile = _getSoundFile(effect);
    if (soundFile != null) {
      try {
        await _sfxPlayer.setVolume(_sfxVolume);
        await _sfxPlayer.play(AssetSource(soundFile));
        print('AudioManager: SFX $effect played successfully');
      } catch (e) {
        print('AudioManager: Error playing sound effect $effect: ${e.toString()}');
        if (e.toString().contains('asset does not exist') || e.toString().contains('empty data')) {
          print('AudioManager: Sound file $soundFile appears to be missing or invalid (likely a placeholder)');
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

  /// Start beat detection algorithm
  void _startBeatDetection() {
    _lastBeatTime = DateTime.now();
    
    // Simple beat detection based on BPM
    final beatInterval = Duration(milliseconds: (60000 / _currentBpm).round());
    
    _beatTimer = Timer.periodic(beatInterval, (timer) {
      final now = DateTime.now();
      if (_lastBeatTime != null) {
        final interval = now.difference(_lastBeatTime!).inMilliseconds.toDouble();
        _beatIntervals.add(interval);
        
        // Keep only recent intervals for BPM calculation
        if (_beatIntervals.length > 10) {
          _beatIntervals.removeAt(0);
        }
        
        // Calculate average BPM
        if (_beatIntervals.isNotEmpty) {
          final avgInterval = _beatIntervals.reduce((a, b) => a + b) / _beatIntervals.length;
          _currentBpm = 60000 / avgInterval;
        }
      }
      
      _lastBeatTime = now;
      _beatController.add(BeatEvent(now, _currentBpm));
    });
  }

  /// Stop beat detection
  void _stopBeatDetection() {
    _beatTimer?.cancel();
    _beatTimer = null;
    _beatIntervals.clear();
  }

  /// Fallback beat generation when audio analysis fails
  void startBeatGenerationWithoutMusic() {
    print('AudioManager: Starting fallback beat generation');
    
    if (!_beatDetectionEnabled) {
      print('AudioManager: Beat detection is disabled, skipping fallback');
      return;
    }
    
    // Use predetermined BPM for consistent gameplay
    _currentBpm = 128.0;
    print('AudioManager: Using fallback BPM: $_currentBpm');
    _startBeatDetection();
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
    }
    await _saveSettings();
  }

  /// Toggle sound effects on/off
  Future<void> toggleSfx() async {
    _isSfxEnabled = !_isSfxEnabled;
    await _saveSettings();
  }

  /// Toggle beat detection on/off
  Future<void> toggleBeatDetection() async {
    _beatDetectionEnabled = !_beatDetectionEnabled;
    if (!_beatDetectionEnabled) {
      _stopBeatDetection();
    } else if (_musicPlayer.state == PlayerState.playing) {
      _startBeatDetection();
    }
    await _saveSettings();
  }

  /// Check if background music is currently playing
  bool get isMusicPlaying => _musicPlayer.state == PlayerState.playing;
  
  /// Get the next predicted beat time
  DateTime? getNextBeatTime() {
    if (_lastBeatTime == null) return null;
    
    final beatInterval = Duration(milliseconds: (60000 / _currentBpm).round());
    return _lastBeatTime!.add(beatInterval);
  }

  /// Check if a beat is expected within the given time window
  bool isBeatExpected(Duration timeWindow) {
    final nextBeat = getNextBeatTime();
    if (nextBeat == null) return false;
    
    final now = DateTime.now();
    final timeToBeat = nextBeat.difference(now);
    
    return timeToBeat.abs() <= timeWindow;
  }

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

  /// Dispose of resources
  void dispose() {
    _beatTimer?.cancel();
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
    _beatController.close();
  }
}

/// Represents a beat event for synchronization
class BeatEvent {
  final DateTime timestamp;
  final double bpm;
  
  const BeatEvent(this.timestamp, this.bpm);
}

/// Available sound effects
enum SoundEffect {
  jump,
  collision,
  pulse,
  score,
  powerUp,
}