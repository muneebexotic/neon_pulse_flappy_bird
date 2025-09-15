import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/achievement.dart';
import '../../models/bird_skin.dart';
import 'customization_manager.dart';

/// Manages achievement notifications, social sharing, and leaderboard functionality
class AchievementManager {
  final CustomizationManager _customizationManager;
  final List<Achievement> _pendingNotifications = [];
  final List<BirdSkin> _pendingUnlocks = [];
  
  // Callback for showing achievement notifications
  Function(Achievement)? onAchievementUnlocked;
  Function(BirdSkin)? onSkinUnlocked;
  
  AchievementManager(this._customizationManager);

  /// Initialize the achievement manager
  Future<void> initialize() async {
    // Achievement manager relies on customization manager being initialized
    // This should be called after customization manager initialization
  }

  /// Update game statistics and handle achievement unlocks
  Future<void> updateGameStatistics({
    int? score,
    int? gamesPlayed,
    int? pulseUsage,
    int? powerUpsCollected,
    int? survivalTime,
  }) async {
    // Update statistics through customization manager
    final newAchievements = await _customizationManager.updateStatistics(
      score: score,
      gamesPlayed: gamesPlayed,
      pulseUsage: pulseUsage,
      powerUpsCollected: powerUpsCollected,
      survivalTime: survivalTime,
    );

    // Check for newly unlocked skins based on score
    List<BirdSkin> newSkins = [];
    if (score != null) {
      newSkins = await _customizationManager.checkAndUnlockSkins(score);
    }

    // Queue notifications for newly unlocked achievements
    for (final achievement in newAchievements) {
      _pendingNotifications.add(achievement);
      onAchievementUnlocked?.call(achievement);
    }

    // Queue notifications for newly unlocked skins
    for (final skin in newSkins) {
      _pendingUnlocks.add(skin);
      onSkinUnlocked?.call(skin);
    }
  }

  /// Get all achievements with progress
  List<Achievement> get achievements => _customizationManager.achievements;

  /// Get unlocked achievements
  List<Achievement> get unlockedAchievements => 
      _customizationManager.unlockedAchievements;

  /// Get game statistics for leaderboard display
  Map<String, int> get gameStatistics => _customizationManager.gameStatistics;

  /// Get personal best scores for leaderboard
  List<LeaderboardEntry> getPersonalBestScores() {
    final stats = _customizationManager.gameStatistics;
    final highScore = stats['highScore'] ?? 0;
    final totalScore = stats['totalScore'] ?? 0;
    final gamesPlayed = stats['gamesPlayed'] ?? 0;
    
    return [
      LeaderboardEntry(
        rank: 1,
        playerName: 'You',
        score: highScore,
        category: 'High Score',
        isPersonalBest: true,
      ),
      LeaderboardEntry(
        rank: 1,
        playerName: 'You',
        score: totalScore,
        category: 'Total Score',
        isPersonalBest: true,
      ),
      LeaderboardEntry(
        rank: 1,
        playerName: 'You',
        score: gamesPlayed,
        category: 'Games Played',
        isPersonalBest: true,
      ),
    ];
  }

  /// Share high score with social media
  Future<void> shareHighScore({
    required int score,
    String? customMessage,
  }) async {
    final message = customMessage ?? 
        'Just scored $score points in Neon Pulse! 🚀✨ Can you beat my cyberpunk bird skills? #NeonPulse #FlappyBird #Gaming';
    
    try {
      await Share.share(
        message,
        subject: 'Check out my Neon Pulse high score!',
      );
    } catch (e) {
      debugPrint('Error sharing high score: $e');
    }
  }

  /// Share achievement unlock
  Future<void> shareAchievement(Achievement achievement) async {
    final message = 'Just unlocked "${achievement.name}" in Neon Pulse! 🏆 '
        '${achievement.description} #NeonPulse #Achievement #Gaming';
    
    try {
      await Share.share(
        message,
        subject: 'New achievement unlocked in Neon Pulse!',
      );
    } catch (e) {
      debugPrint('Error sharing achievement: $e');
    }
  }

  /// Capture and share screenshot of gameplay
  Future<void> shareScreenshot({
    required GlobalKey screenshotKey,
    String? customMessage,
    int? score,
  }) async {
    try {
      // Capture screenshot
      final RenderRepaintBoundary boundary = 
          screenshotKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        debugPrint('Failed to capture screenshot');
        return;
      }

      // Save to temporary file
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/neon_pulse_screenshot.png');
      await file.writeAsBytes(pngBytes);

      // Create share message
      final message = customMessage ?? 
          (score != null 
              ? 'Check out my epic Neon Pulse gameplay! Scored $score points! 🎮✨ #NeonPulse #Gaming'
              : 'Amazing cyberpunk vibes in Neon Pulse! 🚀✨ #NeonPulse #Gaming');

      // Share with image
      await Share.shareXFiles(
        [XFile(file.path)],
        text: message,
        subject: 'Neon Pulse Gameplay',
      );

      // Clean up temporary file
      await file.delete();
    } catch (e) {
      debugPrint('Error sharing screenshot: $e');
      // Fallback to text-only sharing
      await shareHighScore(score: score ?? 0, customMessage: customMessage);
    }
  }

  /// Get achievement progress for display
  double getAchievementProgress(String achievementId) {
    final achievement = achievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => achievements.first,
    );
    return achievement.progressPercentage;
  }

  /// Check if achievement is unlocked
  bool isAchievementUnlocked(String achievementId) {
    final achievement = achievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => achievements.first,
    );
    return achievement.isUnlocked;
  }

  /// Get next achievement to unlock
  Achievement? getNextAchievementToUnlock() {
    final lockedAchievements = achievements
        .where((a) => !a.isUnlocked)
        .toList();
    
    if (lockedAchievements.isEmpty) return null;
    
    // Sort by progress percentage (closest to completion first)
    lockedAchievements.sort((a, b) => 
        b.progressPercentage.compareTo(a.progressPercentage));
    
    return lockedAchievements.first;
  }

  /// Get achievements by category
  List<Achievement> getAchievementsByType(AchievementType type) {
    return achievements.where((a) => a.type == type).toList();
  }

  /// Clear pending notifications (call after showing them)
  void clearPendingNotifications() {
    _pendingNotifications.clear();
    _pendingUnlocks.clear();
  }

  /// Get pending achievement notifications
  List<Achievement> get pendingAchievementNotifications => 
      List.unmodifiable(_pendingNotifications);

  /// Get pending skin unlock notifications
  List<BirdSkin> get pendingSkinUnlocks => 
      List.unmodifiable(_pendingUnlocks);
}

/// Represents a leaderboard entry for personal bests
class LeaderboardEntry {
  final int rank;
  final String playerName;
  final int score;
  final String category;
  final bool isPersonalBest;
  final DateTime? achievedDate;

  const LeaderboardEntry({
    required this.rank,
    required this.playerName,
    required this.score,
    required this.category,
    this.isPersonalBest = false,
    this.achievedDate,
  });

  /// Format score for display
  String get formattedScore {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }
}