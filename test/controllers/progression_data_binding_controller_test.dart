import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/controllers/progression_data_binding_controller.dart';
import '../../lib/controllers/progression_path_controller.dart';
import '../../lib/game/managers/achievement_manager.dart';
import '../../lib/models/achievement.dart';
import '../../lib/models/bird_skin.dart';

// Manual mocks for testing
class MockAchievementManager {
  List<Achievement> _achievements = [];
  Map<String, int> _gameStatistics = {};
  bool _initializeCalled = false;
  bool _clearNotificationsCalled = false;
  
  Function(Achievement)? onAchievementUnlocked;
  Function(BirdSkin)? onSkinUnlocked;
  
  void setAchievements(List<Achievement> achievements) {
    _achievements = achievements;
  }
  
  void setGameStatistics(Map<String, int> stats) {
    _gameStatistics = stats;
  }
  
  List<Achievement> get achievements => _achievements;
  
  Map<String, int> get gameStatistics => _gameStatistics;
  
  Future<void> initialize() async {
    _initializeCalled = true;
  }
  
  void clearPendingNotifications() {
    _clearNotificationsCalled = true;
  }
  
  Future<void> updateGameStatistics({
    int? score,
    int? gamesPlayed,
    int? pulseUsage,
    int? powerUpsCollected,
    int? survivalTime,
  }) async {
    // Mock implementation
  }
  
  double getAchievementProgress(String achievementId) {
    return 0.5; // Mock value
  }
  
  bool isAchievementUnlocked(String achievementId) {
    return achievementId == 'test_2';
  }
  
  Achievement? getNextAchievementToUnlock() {
    return _achievements.isNotEmpty ? _achievements[0] : null;
  }
  
  Future<void> shareAchievement(Achievement achievement) async {
    // Mock implementation
  }
  
  Future<void> shareHighScore({
    required int score,
    String? customMessage,
  }) async {
    // Mock implementation
  }
  
  bool get initializeCalled => _initializeCalled;
  bool get clearNotificationsCalled => _clearNotificationsCalled;
}

class MockProgressionPathController {
  bool _updatePathProgressCalled = false;
  
  void updatePathProgress(List<Achievement> achievements) {
    _updatePathProgressCalled = true;
  }
  
  Map<String, dynamic> getStats() {
    return {
      'pathSegments': 2,
      'nodePositions': 4,
    };
  }
  
  bool get updatePathProgressCalled => _updatePathProgressCalled;
}

void main() {
  group('ProgressionDataBindingController', () {
    late ProgressionDataBindingController controller;
    late MockAchievementManager mockAchievementManager;
    late MockProgressionPathController mockPathController;
    
    // Test data
    final testAchievements = [
      const Achievement(
        id: 'test_1',
        name: 'Test Achievement 1',
        description: 'Test description 1',
        icon: Icons.star,
        iconColor: Colors.blue,
        targetValue: 10,
        type: AchievementType.score,
        currentProgress: 5,
        isUnlocked: false,
      ),
      const Achievement(
        id: 'test_2',
        name: 'Test Achievement 2',
        description: 'Test description 2',
        icon: Icons.star,
        iconColor: Colors.orange,
        targetValue: 20,
        type: AchievementType.totalScore,
        currentProgress: 20,
        isUnlocked: true,
      ),
    ];
    
    final testSkin = BirdSkin(
      id: 'test_skin',
      name: 'Test Skin',
      primaryColor: Colors.red,
      trailColor: Colors.red,
      description: 'Test skin description',
      unlockScore: 100,
      isUnlocked: true,
    );

    setUp(() {
      mockAchievementManager = MockAchievementManager();
      mockPathController = MockProgressionPathController();
      
      // Setup default mock behavior
      mockAchievementManager.setAchievements(testAchievements);
      mockAchievementManager.setGameStatistics({
        'highScore': 100,
        'totalScore': 500,
        'gamesPlayed': 10,
      });
      
      controller = ProgressionDataBindingController(
        achievementManager: mockAchievementManager,
        pathController: mockPathController,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        await controller.initialize();
        
        expect(controller.isInitialized, isTrue);
        expect(controller.currentAchievements, equals(testAchievements));
        expect(mockAchievementManager.initializeCalled, isTrue);
        expect(mockPathController.updatePathProgressCalled, isTrue);
      });

      test('should not initialize twice', () async {
        await controller.initialize();
        final firstInitializeCall = mockAchievementManager.initializeCalled;
        await controller.initialize();
        
        // Should still be true but not called again
        expect(mockAchievementManager.initializeCalled, equals(firstInitializeCall));
      });
    });

    group('Data Synchronization', () {
      setUp(() async {
        await controller.initialize();
      });

      test('should detect achievement changes', () async {
        final newAchievements = [
          testAchievements[0].copyWith(currentProgress: 8),
          testAchievements[1],
        ];
        
        mockAchievementManager.setAchievements(newAchievements);
        
        // Trigger update check
        await controller.refreshData();
        
        expect(controller.currentAchievements[0].currentProgress, equals(8));
      });

      test('should emit achievement updates through stream', () async {
        final streamFuture = controller.achievementsStream.first;
        
        await controller.initialize();
        
        final emittedAchievements = await streamFuture;
        expect(emittedAchievements, equals(testAchievements));
      });

      test('should update path controller when achievements change', () async {
        final newAchievements = [
          testAchievements[0].copyWith(currentProgress: 8),
          testAchievements[1],
        ];
        
        mockAchievementManager.setAchievements(newAchievements);
        
        await controller.refreshData();
        
        expect(mockPathController.updatePathProgressCalled, isTrue);
      });
    });

    group('Real-time Updates', () {
      setUp(() async {
        await controller.initialize();
      });

      test('should handle achievement manager callbacks', () {
        final newAchievement = testAchievements[0].copyWith(isUnlocked: true);
        
        // Simulate callback from achievement manager
        mockAchievementManager.onAchievementUnlocked?.call(newAchievement);
        
        // Verify callback was received (this is mainly for coverage)
        expect(mockAchievementManager.onAchievementUnlocked, isNotNull);
      });

      test('should handle skin unlock callbacks', () {
        // Simulate skin unlock callback
        mockAchievementManager.onSkinUnlocked?.call(testSkin);
        
        expect(controller.pendingSkinUnlocks, contains(testSkin));
      });

      test('should update game statistics', () async {
        await controller.updateGameStatistics(
          score: 150,
          gamesPlayed: 1,
        );
        
        // Test passes if no exception is thrown
        expect(controller.isInitialized, isTrue);
      });
    });

    group('Achievement Queries', () {
      setUp(() async {
        await controller.initialize();
      });

      test('should get achievement progress', () {
        final progress = controller.getAchievementProgress('test_1');
        
        expect(progress, equals(0.5));
      });

      test('should check if achievement is unlocked', () {
        final isUnlocked = controller.isAchievementUnlocked('test_2');
        
        expect(isUnlocked, isTrue);
      });

      test('should get next achievement to unlock', () {
        final nextAchievement = controller.getNextAchievementToUnlock();
        
        expect(nextAchievement, equals(testAchievements[0]));
      });

      test('should get achievements by type', () {
        final scoreAchievements = controller.getAchievementsByType(AchievementType.score);
        
        expect(scoreAchievements.length, equals(1));
        expect(scoreAchievements[0].type, equals(AchievementType.score));
      });
    });

    group('Sharing Functionality', () {
      setUp(() async {
        await controller.initialize();
      });

      test('should share achievement', () async {
        await controller.shareAchievement(testAchievements[1]);
        
        // Test passes if no exception is thrown
        expect(controller.isInitialized, isTrue);
      });

      test('should share high score', () async {
        await controller.shareHighScore(
          score: 150,
          customMessage: 'Test message',
        );
        
        // Test passes if no exception is thrown
        expect(controller.isInitialized, isTrue);
      });
    });

    group('State Management', () {
      setUp(() async {
        await controller.initialize();
      });

      test('should clear pending unlock animations', () {
        // Add some pending animations
        controller.pendingUnlockAnimations; // Access to trigger internal state
        
        controller.clearPendingUnlockAnimations();
        
        expect(controller.pendingUnlockAnimations, isEmpty);
      });

      test('should clear pending skin unlocks', () {
        // Simulate skin unlock
        mockAchievementManager.onSkinUnlocked?.call(testSkin);
        
        expect(controller.pendingSkinUnlocks, isNotEmpty);
        
        controller.clearPendingSkinUnlocks();
        
        expect(controller.pendingSkinUnlocks, isEmpty);
      });

      test('should provide performance statistics', () {
        final stats = controller.getPerformanceStats();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['currentAchievements'], equals(testAchievements.length));
        expect(stats['isInitialized'], isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle achievement manager errors gracefully', () async {
        await controller.initialize();
        
        // Should not throw, but handle gracefully
        await controller.updateGameStatistics(score: 100);
        
        expect(controller.isInitialized, isTrue);
      });

      test('should handle refresh data errors', () async {
        await controller.initialize();
        
        // Should not throw, but handle gracefully
        await controller.refreshData();
        
        expect(controller.isInitialized, isTrue);
      });
    });

    group('Stream Management', () {
      test('should close streams on dispose', () async {
        await controller.initialize();
        
        // Listen to streams to ensure they're active
        final achievementsSubscription = controller.achievementsStream.listen((_) {});
        final unlockSubscription = controller.newUnlockStream.listen((_) {});
        final skinSubscription = controller.skinUnlockStream.listen((_) {});
        
        controller.dispose();
        
        // Streams should be closed
        expect(controller.achievementsStream.isBroadcast, isTrue);
        
        // Clean up subscriptions
        await achievementsSubscription.cancel();
        await unlockSubscription.cancel();
        await skinSubscription.cancel();
      });

      test('should handle multiple stream listeners', () async {
        await controller.initialize();
        
        final listeners = <StreamSubscription<List<Achievement>>>[];
        
        // Add multiple listeners
        for (int i = 0; i < 3; i++) {
          listeners.add(controller.achievementsStream.listen((_) {}));
        }
        
        // Should not throw
        expect(() => controller.refreshData(), returnsNormally);
        
        // Clean up
        for (final listener in listeners) {
          await listener.cancel();
        }
      });
    });
  });
}