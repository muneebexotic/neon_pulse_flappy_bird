import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/bird_skin.dart';
import '../../models/achievement.dart';

/// Manages bird skin unlocking, selection, and achievement tracking
class CustomizationManager {
  static const String _unlockedSkinsKey = 'unlocked_skins';
  static const String _selectedSkinKey = 'selected_skin';
  static const String _achievementsKey = 'achievements';
  static const String _statisticsKey = 'game_statistics';

  List<BirdSkin> _availableSkins = [];
  List<Achievement> _achievements = [];
  BirdSkin? _selectedSkin;
  Map<String, int> _gameStatistics = {};

  /// Initialize the customization manager
  Future<void> initialize() async {
    await _loadSkins();
    await _loadAchievements();
    await _loadSelectedSkin();
    await _loadStatistics();
  }

  /// Get all available skins
  List<BirdSkin> get availableSkins => List.unmodifiable(_availableSkins);

  /// Get unlocked skins only
  List<BirdSkin> get unlockedSkins => 
      _availableSkins.where((skin) => skin.isUnlocked).toList();

  /// Get currently selected skin
  BirdSkin get selectedSkin => 
      _selectedSkin ?? _availableSkins.first;

  /// Get all achievements
  List<Achievement> get achievements => List.unmodifiable(_achievements);

  /// Get unlocked achievements
  List<Achievement> get unlockedAchievements =>
      _achievements.where((achievement) => achievement.isUnlocked).toList();

  /// Get game statistics
  Map<String, int> get gameStatistics => Map.unmodifiable(_gameStatistics);

  /// Check if a skin is unlocked based on score
  bool isSkinUnlockedByScore(String skinId, int currentScore) {
    final skin = _availableSkins.firstWhere(
      (s) => s.id == skinId,
      orElse: () => _availableSkins.first,
    );
    return currentScore >= skin.unlockScore;
  }

  /// Unlock skins based on current score
  Future<List<BirdSkin>> checkAndUnlockSkins(int currentScore) async {
    final newlyUnlocked = <BirdSkin>[];
    
    for (int i = 0; i < _availableSkins.length; i++) {
      final skin = _availableSkins[i];
      if (!skin.isUnlocked && currentScore >= skin.unlockScore) {
        _availableSkins[i] = skin.copyWith(isUnlocked: true);
        newlyUnlocked.add(_availableSkins[i]);
      }
    }
    
    if (newlyUnlocked.isNotEmpty) {
      await _saveSkins();
    }
    
    return newlyUnlocked;
  }

  /// Select a skin (must be unlocked)
  Future<bool> selectSkin(String skinId) async {
    final skin = _availableSkins.firstWhere(
      (s) => s.id == skinId,
      orElse: () => _availableSkins.first,
    );
    
    if (!skin.isUnlocked) {
      return false;
    }
    
    _selectedSkin = skin;
    await _saveSelectedSkin();
    return true;
  }

  /// Update game statistics and check achievements
  Future<List<Achievement>> updateStatistics({
    int? score,
    int? gamesPlayed,
    int? pulseUsage,
    int? powerUpsCollected,
    int? survivalTime,
  }) async {
    // Update statistics
    if (score != null) {
      _gameStatistics['totalScore'] = 
          (_gameStatistics['totalScore'] ?? 0) + score;
      _gameStatistics['highScore'] = 
          (_gameStatistics['highScore'] ?? 0) < score ? score : 
          (_gameStatistics['highScore'] ?? 0);
    }
    
    if (gamesPlayed != null) {
      _gameStatistics['gamesPlayed'] = 
          (_gameStatistics['gamesPlayed'] ?? 0) + gamesPlayed;
    }
    
    if (pulseUsage != null) {
      _gameStatistics['pulseUsage'] = 
          (_gameStatistics['pulseUsage'] ?? 0) + pulseUsage;
    }
    
    if (powerUpsCollected != null) {
      _gameStatistics['powerUpsCollected'] = 
          (_gameStatistics['powerUpsCollected'] ?? 0) + powerUpsCollected;
    }
    
    if (survivalTime != null) {
      _gameStatistics['totalSurvivalTime'] = 
          (_gameStatistics['totalSurvivalTime'] ?? 0) + survivalTime;
    }
    
    await _saveStatistics();
    
    // Check and unlock achievements
    return await _checkAchievements();
  }

  /// Check achievements and unlock them
  Future<List<Achievement>> _checkAchievements() async {
    final newlyUnlocked = <Achievement>[];
    
    for (int i = 0; i < _achievements.length; i++) {
      final achievement = _achievements[i];
      if (achievement.isUnlocked) continue;
      
      int currentProgress = _calculateAchievementProgress(achievement);
      
      // Update progress based on tracking type
      int newProgress = currentProgress;
      
      switch (achievement.trackingType) {
        case AchievementTrackingType.cumulative:
          // For cumulative achievements, always use the calculated progress
          newProgress = currentProgress;
          break;
        case AchievementTrackingType.singleRun:
          // For single-run achievements, only update if the new progress is higher
          // This prevents overriding manual resets and allows progress during gameplay
          if (currentProgress > achievement.currentProgress) {
            newProgress = currentProgress;
          } else {
            // Keep existing progress (don't override resets)
            newProgress = achievement.currentProgress;
          }
          break;
        case AchievementTrackingType.milestone:
          // For milestone achievements, it's either 0 or target value
          newProgress = currentProgress >= achievement.targetValue 
              ? achievement.targetValue 
              : 0;
          break;
        case AchievementTrackingType.streak:
          // For streak achievements, use calculated progress
          // (streak logic would be implemented in the calling code)
          newProgress = currentProgress;
          break;
      }
      
      // Update progress
      _achievements[i] = achievement.copyWith(
        currentProgress: newProgress,
        isUnlocked: newProgress >= achievement.targetValue,
      );
      
      // Check if newly unlocked
      if (_achievements[i].isUnlocked && !achievement.isUnlocked) {
        newlyUnlocked.add(_achievements[i]);
        
        // Unlock reward skin if available
        if (achievement.rewardSkinId != null) {
          await _unlockRewardSkin(achievement.rewardSkinId!);
        }
      }
    }
    
    if (newlyUnlocked.isNotEmpty) {
      await _saveAchievements();
    }
    
    return newlyUnlocked;
  }

  /// Calculate achievement progress based on achievement type
  int _calculateAchievementProgress(Achievement achievement) {
    switch (achievement.type) {
      case AchievementType.score:
        return _gameStatistics['highScore'] ?? 0;
      case AchievementType.totalScore:
        return _gameStatistics['totalScore'] ?? 0;
      case AchievementType.gamesPlayed:
        return _gameStatistics['gamesPlayed'] ?? 0;
      case AchievementType.pulseUsage:
        return _gameStatistics['pulseUsage'] ?? 0;
      case AchievementType.powerUps:
        return _gameStatistics['powerUpsCollected'] ?? 0;
      case AchievementType.survival:
        return _gameStatistics['totalSurvivalTime'] ?? 0;
    }
  }

  /// Unlock a reward skin from achievement
  Future<void> _unlockRewardSkin(String skinId) async {
    // Add special reward skins if they don't exist
    if (!_availableSkins.any((skin) => skin.id == skinId)) {
      final rewardSkin = _createRewardSkin(skinId);
      if (rewardSkin != null) {
        _availableSkins.add(rewardSkin);
      }
    }
    
    // Unlock the skin
    for (int i = 0; i < _availableSkins.length; i++) {
      if (_availableSkins[i].id == skinId) {
        _availableSkins[i] = _availableSkins[i].copyWith(isUnlocked: true);
        break;
      }
    }
    
    await _saveSkins();
  }

  /// Create special reward skins
  BirdSkin? _createRewardSkin(String skinId) {
    switch (skinId) {
      case 'pulse_master_skin':
        return const BirdSkin(
          id: 'pulse_master_skin',
          name: 'Pulse Master',
          primaryColor: Color(0xFFFFD700), // Gold
          trailColor: Color(0xFFFFD700),
          description: 'Master of the pulse mechanic',
          unlockScore: 0,
          isUnlocked: true,
        );
      case 'golden_bird':
        return const BirdSkin(
          id: 'golden_bird',
          name: 'Golden Phoenix',
          primaryColor: Color(0xFFFFD700), // Gold
          trailColor: Color(0xFFFFA500), // Orange
          description: 'Legendary golden bird',
          unlockScore: 0,
          isUnlocked: true,
        );
      case 'energy_bird':
        return const BirdSkin(
          id: 'energy_bird',
          name: 'Energy Collector',
          primaryColor: Color(0xFF00FF00), // Bright green
          trailColor: Color(0xFF32CD32), // Lime green
          description: 'Powered by collected energy',
          unlockScore: 0,
          isUnlocked: true,
        );
      case 'endurance_bird':
        return const BirdSkin(
          id: 'endurance_bird',
          name: 'Marathon Runner',
          primaryColor: Color(0xFFFF6347), // Tomato
          trailColor: Color(0xFFFF4500), // Orange red
          description: 'Built for endurance',
          unlockScore: 0,
          isUnlocked: true,
        );
      default:
        return null;
    }
  }

  /// Load skins from storage
  Future<void> _loadSkins() async {
    final prefs = await SharedPreferences.getInstance();
    final skinsJson = prefs.getString(_unlockedSkinsKey);
    
    if (skinsJson != null) {
      final skinsList = jsonDecode(skinsJson) as List;
      _availableSkins = skinsList
          .map((json) => BirdSkin.fromJson(json))
          .toList();
    } else {
      // Initialize with default skins
      _availableSkins = DefaultBirdSkins.skins.toList();
      await _saveSkins();
    }
  }

  /// Save skins to storage
  Future<void> _saveSkins() async {
    final prefs = await SharedPreferences.getInstance();
    final skinsJson = jsonEncode(_availableSkins.map((s) => s.toJson()).toList());
    await prefs.setString(_unlockedSkinsKey, skinsJson);
  }

  /// Load selected skin from storage
  Future<void> _loadSelectedSkin() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedSkinId = prefs.getString(_selectedSkinKey);
    
    if (selectedSkinId != null) {
      _selectedSkin = _availableSkins.firstWhere(
        (skin) => skin.id == selectedSkinId,
        orElse: () => _availableSkins.first,
      );
    } else {
      _selectedSkin = _availableSkins.first;
    }
  }

  /// Save selected skin to storage
  Future<void> _saveSelectedSkin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedSkinKey, _selectedSkin?.id ?? '');
  }

  /// Load achievements from storage
  Future<void> _loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = prefs.getString(_achievementsKey);
    
    if (achievementsJson != null) {
      final achievementsList = jsonDecode(achievementsJson) as List;
      _achievements = achievementsList
          .map((json) => Achievement.fromJson(json))
          .toList();
    } else {
      // Initialize with default achievements
      _achievements = DefaultAchievements.achievements.toList();
      await _saveAchievements();
    }
  }

  /// Update achievement progress directly
  void updateAchievementProgress(String achievementId, int newProgress) {
    for (int i = 0; i < _achievements.length; i++) {
      if (_achievements[i].id == achievementId) {
        _achievements[i] = _achievements[i].copyWith(
          currentProgress: newProgress,
          isUnlocked: newProgress >= _achievements[i].targetValue,
        );
        break;
      }
    }
  }

  /// Save achievements to storage (made public for AchievementManager)
  Future<void> saveAchievements() async {
    await _saveAchievements();
  }

  /// Save achievements to storage
  Future<void> _saveAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = jsonEncode(_achievements.map((a) => a.toJson()).toList());
    await prefs.setString(_achievementsKey, achievementsJson);
  }

  /// Load statistics from storage
  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final statisticsJson = prefs.getString(_statisticsKey);
    
    if (statisticsJson != null) {
      final stats = jsonDecode(statisticsJson) as Map<String, dynamic>;
      _gameStatistics = stats.map((key, value) => MapEntry(key, value as int));
    } else {
      _gameStatistics = {
        'totalScore': 0,
        'highScore': 0,
        'gamesPlayed': 0,
        'pulseUsage': 0,
        'powerUpsCollected': 0,
        'totalSurvivalTime': 0,
      };
    }
  }

  /// Save statistics to storage
  Future<void> _saveStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final statisticsJson = jsonEncode(_gameStatistics);
    await prefs.setString(_statisticsKey, statisticsJson);
  }

  /// Reset all customization data (for testing or reset functionality)
  Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_unlockedSkinsKey);
    await prefs.remove(_selectedSkinKey);
    await prefs.remove(_achievementsKey);
    await prefs.remove(_statisticsKey);
    
    await initialize();
  }
}