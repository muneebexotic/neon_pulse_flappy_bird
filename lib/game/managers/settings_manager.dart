import 'package:shared_preferences/shared_preferences.dart';

/// Manages all game settings with persistence
class SettingsManager {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

  SharedPreferences? _prefs;
  
  // Graphics settings
  GraphicsQuality _graphicsQuality = GraphicsQuality.auto;
  ParticleQuality _particleQuality = ParticleQuality.high;
  
  // Difficulty settings
  DifficultyLevel _difficultyLevel = DifficultyLevel.normal;
  
  // Control settings
  double _tapSensitivity = 1.0;
  double _doubleTapTiming = 300.0; // milliseconds
  
  // Performance settings
  bool _performanceMonitorEnabled = false;
  bool _autoQualityAdjustment = true;
  
  // Audio settings (managed by AudioManager but stored here)
  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  
  // Haptic settings
  bool _hapticEnabled = true;
  bool _vibrationEnabled = true;
  double _hapticIntensity = 1.0;
  double _vibrationIntensity = 1.0;

  /// Initialize settings from shared preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    // Graphics settings
    final graphicsIndex = _prefs!.getInt('graphics_quality') ?? GraphicsQuality.auto.index;
    _graphicsQuality = GraphicsQuality.values[graphicsIndex];
    
    final particleIndex = _prefs!.getInt('particle_quality') ?? ParticleQuality.high.index;
    _particleQuality = ParticleQuality.values[particleIndex];
    
    // Difficulty settings
    final difficultyIndex = _prefs!.getInt('difficulty_level') ?? DifficultyLevel.normal.index;
    _difficultyLevel = DifficultyLevel.values[difficultyIndex];
    
    // Control settings
    _tapSensitivity = _prefs!.getDouble('tap_sensitivity') ?? 1.0;
    _doubleTapTiming = _prefs!.getDouble('double_tap_timing') ?? 300.0;
    
    // Performance settings
    _performanceMonitorEnabled = _prefs!.getBool('performance_monitor') ?? false;
    _autoQualityAdjustment = _prefs!.getBool('auto_quality') ?? true;
    
    // Audio settings
    _musicVolume = _prefs!.getDouble('music_volume') ?? 0.7;
    _sfxVolume = _prefs!.getDouble('sfx_volume') ?? 0.8;
    _musicEnabled = _prefs!.getBool('music_enabled') ?? true;
    _sfxEnabled = _prefs!.getBool('sfx_enabled') ?? true;
    
    // Haptic settings
    _hapticEnabled = _prefs!.getBool('haptic_enabled') ?? true;
    _vibrationEnabled = _prefs!.getBool('vibration_enabled') ?? true;
    _hapticIntensity = _prefs!.getDouble('haptic_intensity') ?? 1.0;
    _vibrationIntensity = _prefs!.getDouble('vibration_intensity') ?? 1.0;
  }

  // Graphics Quality
  GraphicsQuality get graphicsQuality => _graphicsQuality;
  Future<void> setGraphicsQuality(GraphicsQuality quality) async {
    _graphicsQuality = quality;
    await _prefs?.setInt('graphics_quality', quality.index);
  }

  // Particle Quality
  ParticleQuality get particleQuality => _particleQuality;
  Future<void> setParticleQuality(ParticleQuality quality) async {
    _particleQuality = quality;
    await _prefs?.setInt('particle_quality', quality.index);
  }

  // Difficulty Level
  DifficultyLevel get difficultyLevel => _difficultyLevel;
  Future<void> setDifficultyLevel(DifficultyLevel level) async {
    _difficultyLevel = level;
    await _prefs?.setInt('difficulty_level', level.index);
  }

  // Control Settings
  double get tapSensitivity => _tapSensitivity;
  Future<void> setTapSensitivity(double sensitivity) async {
    _tapSensitivity = sensitivity.clamp(0.5, 2.0);
    await _prefs?.setDouble('tap_sensitivity', _tapSensitivity);
  }

  double get doubleTapTiming => _doubleTapTiming;
  Future<void> setDoubleTapTiming(double timing) async {
    _doubleTapTiming = timing.clamp(200.0, 500.0);
    await _prefs?.setDouble('double_tap_timing', _doubleTapTiming);
  }

  // Performance Settings
  bool get performanceMonitorEnabled => _performanceMonitorEnabled;
  Future<void> setPerformanceMonitorEnabled(bool enabled) async {
    _performanceMonitorEnabled = enabled;
    await _prefs?.setBool('performance_monitor', enabled);
  }

  bool get autoQualityAdjustment => _autoQualityAdjustment;
  Future<void> setAutoQualityAdjustment(bool enabled) async {
    _autoQualityAdjustment = enabled;
    await _prefs?.setBool('auto_quality', enabled);
  }

  // Audio Settings (for persistence)
  double get musicVolume => _musicVolume;
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _prefs?.setDouble('music_volume', _musicVolume);
  }

  double get sfxVolume => _sfxVolume;
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    await _prefs?.setDouble('sfx_volume', _sfxVolume);
  }

  bool get musicEnabled => _musicEnabled;
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    await _prefs?.setBool('music_enabled', enabled);
  }

  bool get sfxEnabled => _sfxEnabled;
  Future<void> setSfxEnabled(bool enabled) async {
    _sfxEnabled = enabled;
    await _prefs?.setBool('sfx_enabled', enabled);
  }


  // Haptic Settings
  bool get hapticEnabled => _hapticEnabled;
  Future<void> setHapticEnabled(bool enabled) async {
    _hapticEnabled = enabled;
    await _prefs?.setBool('haptic_enabled', enabled);
  }

  bool get vibrationEnabled => _vibrationEnabled;
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _prefs?.setBool('vibration_enabled', enabled);
  }

  double get hapticIntensity => _hapticIntensity;
  Future<void> setHapticIntensity(double intensity) async {
    _hapticIntensity = intensity.clamp(0.0, 1.0);
    await _prefs?.setDouble('haptic_intensity', _hapticIntensity);
  }

  double get vibrationIntensity => _vibrationIntensity;
  Future<void> setVibrationIntensity(double intensity) async {
    _vibrationIntensity = intensity.clamp(0.0, 1.0);
    await _prefs?.setDouble('vibration_intensity', _vibrationIntensity);
  }


  /// Get recommended graphics quality based on device performance
  GraphicsQuality getRecommendedGraphicsQuality(double performanceScore) {
    if (performanceScore >= 0.9) return GraphicsQuality.ultra;
    if (performanceScore >= 0.7) return GraphicsQuality.high;
    if (performanceScore >= 0.5) return GraphicsQuality.medium;
    return GraphicsQuality.low;
  }

  /// Get recommended particle quality based on device performance
  ParticleQuality getRecommendedParticleQuality(double performanceScore) {
    if (performanceScore >= 0.8) return ParticleQuality.ultra;
    if (performanceScore >= 0.6) return ParticleQuality.high;
    if (performanceScore >= 0.4) return ParticleQuality.medium;
    return ParticleQuality.low;
  }
}

/// Graphics quality levels
enum GraphicsQuality {
  low('Low', 'Minimal effects for best performance'),
  medium('Medium', 'Balanced quality and performance'),
  high('High', 'Enhanced visuals with good performance'),
  ultra('Ultra', 'Maximum quality for high-end devices'),
  auto('Auto', 'Automatically adjust based on performance');

  const GraphicsQuality(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// Particle quality levels
enum ParticleQuality {
  low('Low', 'Minimal particles (50)'),
  medium('Medium', 'Moderate particles (150)'),
  high('High', 'Rich particle effects (300)'),
  ultra('Ultra', 'Maximum particles (500)');

  const ParticleQuality(this.displayName, this.description);
  final String displayName;
  final String description;

  /// Get maximum particle count for this quality level
  int get maxParticles {
    switch (this) {
      case ParticleQuality.low:
        return 50;
      case ParticleQuality.medium:
        return 150;
      case ParticleQuality.high:
        return 300;
      case ParticleQuality.ultra:
        return 500;
    }
  }
}

/// Difficulty levels
enum DifficultyLevel {
  easy('Easy', 'Slower speed, larger gaps, more forgiving'),
  normal('Normal', 'Standard Flappy Bird difficulty'),
  hard('Hard', 'Faster speed, smaller gaps, challenging');

  const DifficultyLevel(this.displayName, this.description);
  final String displayName;
  final String description;

  /// Get speed multiplier for this difficulty
  double get speedMultiplier {
    switch (this) {
      case DifficultyLevel.easy:
        return 0.8;
      case DifficultyLevel.normal:
        return 1.0;
      case DifficultyLevel.hard:
        return 1.3;
    }
  }

  /// Get gap size multiplier for this difficulty
  double get gapSizeMultiplier {
    switch (this) {
      case DifficultyLevel.easy:
        return 1.3;
      case DifficultyLevel.normal:
        return 1.0;
      case DifficultyLevel.hard:
        return 0.8;
    }
  }
}