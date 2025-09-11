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
  }

  /// Start playing background music with beat detection
  Future<void> playBackgroundMusic(String musicFile) async {
    if (!_isMusicEnabled) return;
    
    try {
      await _musicPlayer.setVolume(_musicVolume);
      await _musicPlayer.play(AssetSource('audio/music/$musicFile'));
      
      if (_beatDetectionEnabled) {
        _startBeatDetection();
      }
    } catch (e) {
      print('Error playing background music: $e');
      _fallbackBeatGeneration();
    }
  }

  /// Stop background music and beat detection
  Future<void> stopBackgroundMusic() async {
    await _musicPlayer.stop();
    _stopBeatDetection();
  }

  /// Play a sound effect
  Future<void> playSoundEffect(SoundEffect effect) async {
    if (!_isSfxEnabled) return;
    
    final soundFile = _getSoundFile(effect);
    if (soundFile != null) {
      try {
        await _sfxPlayer.setVolume(_sfxVolume);
        await _sfxPlayer.play(AssetSource(soundFile));
      } catch (e) {
        print('Error playing sound effect: $e');
      }
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
        return _cachedSounds['score.wav'];
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
  void _fallbackBeatGeneration() {
    if (!_beatDetectionEnabled) return;
    
    // Use predetermined BPM for consistent gameplay
    _currentBpm = 128.0;
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