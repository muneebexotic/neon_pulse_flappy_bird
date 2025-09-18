/// User game statistics model
class UserGameStats {
  final int totalGamesPlayed;
  final int bestScore;
  final int totalScore;
  final double averageScore;
  final DateTime? lastPlayed;
  final Map<String, int> achievementProgress;

  const UserGameStats({
    this.totalGamesPlayed = 0,
    this.bestScore = 0,
    this.totalScore = 0,
    this.averageScore = 0.0,
    this.lastPlayed,
    this.achievementProgress = const {},
  });

  factory UserGameStats.fromJson(Map<String, dynamic> json) {
    return UserGameStats(
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
      bestScore: json['bestScore'] ?? 0,
      totalScore: json['totalScore'] ?? 0,
      averageScore: (json['averageScore'] ?? 0.0).toDouble(),
      lastPlayed: json['lastPlayed'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['lastPlayed'])
          : null,
      achievementProgress: Map<String, int>.from(json['achievementProgress'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalGamesPlayed': totalGamesPlayed,
      'bestScore': bestScore,
      'totalScore': totalScore,
      'averageScore': averageScore,
      'lastPlayed': lastPlayed?.millisecondsSinceEpoch,
      'achievementProgress': achievementProgress,
    };
  }

  UserGameStats copyWith({
    int? totalGamesPlayed,
    int? bestScore,
    int? totalScore,
    double? averageScore,
    DateTime? lastPlayed,
    Map<String, int>? achievementProgress,
  }) {
    return UserGameStats(
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      bestScore: bestScore ?? this.bestScore,
      totalScore: totalScore ?? this.totalScore,
      averageScore: averageScore ?? this.averageScore,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      achievementProgress: achievementProgress ?? this.achievementProgress,
    );
  }
}

/// Enhanced user model for Firebase authentication and game data
class User {
  final String? uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final bool isGuest;
  final DateTime? lastSignIn;
  final UserGameStats gameStats;

  const User({
    this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    required this.isGuest,
    this.lastSignIn,
    required this.gameStats,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'],
      displayName: json['displayName'] ?? 'Player',
      email: json['email'] ?? '',
      photoURL: json['photoURL'],
      isGuest: json['isGuest'] ?? true,
      lastSignIn: json['lastSignIn'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['lastSignIn'])
          : null,
      gameStats: UserGameStats.fromJson(json['gameStats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'isGuest': isGuest,
      'lastSignIn': lastSignIn?.millisecondsSinceEpoch,
      'gameStats': gameStats.toJson(),
    };
  }

  User copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoURL,
    bool? isGuest,
    DateTime? lastSignIn,
    UserGameStats? gameStats,
  }) {
    return User(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      isGuest: isGuest ?? this.isGuest,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      gameStats: gameStats ?? this.gameStats,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'User(uid: $uid, displayName: $displayName, isGuest: $isGuest)';
  }
}

/// Simple player model for game statistics and preferences (legacy - kept for compatibility)
class GamePlayer {
  final String id;
  final String displayName;
  final DateTime createdAt;
  final int highScore;
  final int totalGames;
  final int totalFlights;
  final Map<String, dynamic> preferences;

  const GamePlayer({
    required this.id,
    required this.displayName,
    required this.createdAt,
    this.highScore = 0,
    this.totalGames = 0,
    this.totalFlights = 0,
    this.preferences = const {},
  });

  /// Create a new player with default values
  factory GamePlayer.create({String? displayName}) {
    final now = DateTime.now();
    return GamePlayer(
      id: 'player_${now.millisecondsSinceEpoch}',
      displayName: displayName ?? 'Player',
      createdAt: now,
    );
  }

  /// Create a player from stored data
  factory GamePlayer.fromMap(Map<String, dynamic> data) {
    return GamePlayer(
      id: data['id'] as String,
      displayName: data['displayName'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      highScore: data['highScore'] as int? ?? 0,
      totalGames: data['totalGames'] as int? ?? 0,
      totalFlights: data['totalFlights'] as int? ?? 0,
      preferences: Map<String, dynamic>.from(data['preferences'] as Map? ?? {}),
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'highScore': highScore,
      'totalGames': totalGames,
      'totalFlights': totalFlights,
      'preferences': preferences,
    };
  }

  /// Create a copy with updated fields
  GamePlayer copyWith({
    String? id,
    String? displayName,
    DateTime? createdAt,
    int? highScore,
    int? totalGames,
    int? totalFlights,
    Map<String, dynamic>? preferences,
  }) {
    return GamePlayer(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      highScore: highScore ?? this.highScore,
      totalGames: totalGames ?? this.totalGames,
      totalFlights: totalFlights ?? this.totalFlights,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GamePlayer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GamePlayer(id: $id, displayName: $displayName, highScore: $highScore)';
  }
}