import 'package:flutter/material.dart';

/// Represents an achievement that can be unlocked in the game
class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color iconColor;
  final int targetValue;
  final AchievementType type;
  final AchievementTrackingType trackingType;
  final bool resetsOnFailure;
  final String? rewardSkinId;
  final bool isUnlocked;
  final int currentProgress;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.targetValue,
    required this.type,
    required this.trackingType,
    this.resetsOnFailure = false,
    this.rewardSkinId,
    this.isUnlocked = false,
    this.currentProgress = 0,
  });

  /// Create a copy with updated progress
  Achievement copyWith({
    bool? isUnlocked,
    int? currentProgress,
  }) {
    return Achievement(
      id: id,
      name: name,
      description: description,
      icon: icon,
      iconColor: iconColor,
      targetValue: targetValue,
      type: type,
      trackingType: trackingType,
      resetsOnFailure: resetsOnFailure,
      rewardSkinId: rewardSkinId,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      currentProgress: currentProgress ?? this.currentProgress,
    );
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (targetValue == 0) return 1.0;
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }

  /// Check if achievement is completed
  bool get isCompleted {
    return currentProgress >= targetValue;
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconColor': iconColor.toARGB32(),
      'targetValue': targetValue,
      'type': type.toString(),
      'trackingType': trackingType.toString(),
      'resetsOnFailure': resetsOnFailure,
      'rewardSkinId': rewardSkinId,
      'isUnlocked': isUnlocked,
      'currentProgress': currentProgress,
    };
  }

  /// Create from JSON
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: IconData(
        json['iconCodePoint'],
        fontFamily: json['iconFontFamily'],
      ),
      iconColor: Color(json['iconColor']),
      targetValue: json['targetValue'],
      type: AchievementType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      trackingType: AchievementTrackingType.values.firstWhere(
        (e) => e.toString() == json['trackingType'],
        orElse: () => AchievementTrackingType.cumulative, // Default for backward compatibility
      ),
      resetsOnFailure: json['resetsOnFailure'] ?? false,
      rewardSkinId: json['rewardSkinId'],
      isUnlocked: json['isUnlocked'] ?? false,
      currentProgress: json['currentProgress'] ?? 0,
    );
  }
}

/// Types of achievements available
enum AchievementType {
  score,        // Based on single game score
  totalScore,   // Based on cumulative score
  gamesPlayed,  // Based on number of games
  pulseUsage,   // Based on pulse mechanic usage
  powerUps,     // Based on power-up collection
  survival,     // Based on survival time
}

/// Achievement tracking behavior types
enum AchievementTrackingType {
  cumulative,   // Progress persists across runs (e.g., total score, games played)
  singleRun,    // Progress resets on failure (e.g., single game score, survival time)
  milestone,    // One-time unlock (e.g., first achievement)
  streak,       // Consecutive achievement (e.g., win streak)
}

/// Default achievements available in the game
class DefaultAchievements {
  static const List<Achievement> achievements = [
    Achievement(
      id: 'first_flight',
      name: 'First Flight',
      description: 'Score your first point',
      icon: Icons.flight_takeoff,
      iconColor: Colors.cyan,
      targetValue: 1,
      type: AchievementType.score,
      trackingType: AchievementTrackingType.singleRun,
      resetsOnFailure: true,
    ),
    Achievement(
      id: 'pulse_master',
      name: 'Pulse Master',
      description: 'Use pulse mechanic 50 times',
      icon: Icons.flash_on,
      iconColor: Colors.yellow,
      targetValue: 50,
      type: AchievementType.pulseUsage,
      trackingType: AchievementTrackingType.cumulative,
      rewardSkinId: 'pulse_master_skin',
    ),
    Achievement(
      id: 'century_club',
      name: 'Century Club',
      description: 'Score 100 points in a single game',
      icon: Icons.star,
      iconColor: Color(0xFFFFD700), // Gold color
      targetValue: 100,
      type: AchievementType.score,
      trackingType: AchievementTrackingType.singleRun,
      resetsOnFailure: true,
      rewardSkinId: 'golden_bird',
    ),
    Achievement(
      id: 'power_collector',
      name: 'Power Collector',
      description: 'Collect 25 power-ups',
      icon: Icons.battery_charging_full,
      iconColor: Colors.green,
      targetValue: 25,
      type: AchievementType.powerUps,
      trackingType: AchievementTrackingType.cumulative,
      rewardSkinId: 'energy_bird',
    ),
    Achievement(
      id: 'marathon_runner',
      name: 'Marathon Runner',
      description: 'Play 100 games',
      icon: Icons.directions_run,
      iconColor: Colors.orange,
      targetValue: 100,
      type: AchievementType.gamesPlayed,
      trackingType: AchievementTrackingType.cumulative,
      rewardSkinId: 'endurance_bird',
    ),
  ];
}