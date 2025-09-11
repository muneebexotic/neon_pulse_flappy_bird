import 'package:flutter/material.dart';

/// Represents different visual appearances for the bird
class BirdSkin {
  final String id;
  final String name;
  final Color primaryColor;
  final Color trailColor;
  final String description;
  final int unlockScore;
  final bool isUnlocked;

  const BirdSkin({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.trailColor,
    required this.description,
    required this.unlockScore,
    this.isUnlocked = false,
  });

  /// Create a copy of this skin with updated unlock status
  BirdSkin copyWith({bool? isUnlocked}) {
    return BirdSkin(
      id: id,
      name: name,
      primaryColor: primaryColor,
      trailColor: trailColor,
      description: description,
      unlockScore: unlockScore,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primaryColor': primaryColor.toARGB32(),
      'trailColor': trailColor.toARGB32(),
      'description': description,
      'unlockScore': unlockScore,
      'isUnlocked': isUnlocked,
    };
  }

  /// Create from JSON
  factory BirdSkin.fromJson(Map<String, dynamic> json) {
    return BirdSkin(
      id: json['id'],
      name: json['name'],
      primaryColor: Color(json['primaryColor']),
      trailColor: Color(json['trailColor']),
      description: json['description'],
      unlockScore: json['unlockScore'],
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }
}

/// Default bird skins available in the game
class DefaultBirdSkins {
  static const List<BirdSkin> skins = [
    BirdSkin(
      id: 'default',
      name: 'Cyber Bird',
      primaryColor: Colors.cyan,
      trailColor: Colors.cyan,
      description: 'The classic neon bird',
      unlockScore: 0,
      isUnlocked: true,
    ),
    BirdSkin(
      id: 'pink_pulse',
      name: 'Pink Pulse',
      primaryColor: Colors.pink,
      trailColor: Colors.pink,
      description: 'Hot pink energy',
      unlockScore: 50,
    ),
    BirdSkin(
      id: 'neon_green',
      name: 'Neon Green',
      primaryColor: Color(0xFF39FF14),
      trailColor: Color(0xFF39FF14),
      description: 'Electric green glow',
      unlockScore: 100,
    ),
    BirdSkin(
      id: 'warning_orange',
      name: 'Warning Orange',
      primaryColor: Color(0xFFFF4500),
      trailColor: Color(0xFFFF4500),
      description: 'Danger zone aesthetic',
      unlockScore: 200,
    ),
  ];
}