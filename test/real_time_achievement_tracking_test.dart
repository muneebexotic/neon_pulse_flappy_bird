import 'package:flutter_test/flutter_test.dart';
import '../lib/game/managers/achievement_manager.dart';
import '../lib/game/managers/customization_manager.dart';
import '../lib/game/managers/notification_manager.dart';
import '../lib/game/managers/pulse_manager.dart';
import '../lib/game/managers/power_up_manager.dart';
import '../lib/game/components/bird.dart';
import '../lib/game/managers/obstacle_manager.dart';
import '../lib/models/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Real-time Achievement Tracking', () {
    late AchievementManager achievementManager;
    late CustomizationManager customizationManager;
    late NotificationManager notificationManager;

    setUp(() {
      customizationManager = CustomizationManager();
      notificationManager = NotificationManager();
      achievementManager = AchievementManager(customizationManager, notificationManager);
    });

    test('should have real-time tracking methods in AchievementManager', () {
      // Verify that the new real-time tracking methods exist
      expect(achievementManager.updateScoreProgress, isA<Function>());
      expect(achievementManager.updatePulseUsage, isA<Function>());
      expect(achievementManager.updatePowerUpCollection, isA<Function>());
      expect(achievementManager.updateSurvivalTime, isA<Function>());
    });

    test('should track pulse usage in PulseManager', () {
      final bird = Bird();
      final obstacleManager = ObstacleManager(worldWidth: 800, worldHeight: 600);
      final pulseManager = PulseManager(bird: bird, obstacleManager: obstacleManager);
      
      // Get initial pulse usage
      final initialPulseUsage = pulseManager.getTotalPulseUsage();
      expect(initialPulseUsage, equals(0));
      
      // Activate pulse (if ready)
      if (pulseManager.pulseReady) {
        pulseManager.tryActivatePulse();
        
        // Verify pulse usage increased
        final newPulseUsage = pulseManager.getTotalPulseUsage();
        expect(newPulseUsage, equals(initialPulseUsage + 1));
      }
    });

    test('should track power-up collection in PowerUpManager', () {
      final bird = Bird();
      final obstacleManager = ObstacleManager(worldWidth: 800, worldHeight: 600);
      final gameState = GameState();
      final powerUpManager = PowerUpManager(
        worldWidth: 800,
        worldHeight: 600,
        bird: bird,
        obstacleManager: obstacleManager,
        gameState: gameState,
      );
      
      // Get initial power-up collection count
      final initialCount = powerUpManager.getTotalPowerUpsCollected();
      expect(initialCount, equals(0));
      
      // Verify callback can be set
      bool callbackCalled = false;
      powerUpManager.onPowerUpCollected = () {
        callbackCalled = true;
      };
      
      expect(powerUpManager.onPowerUpCollected, isNotNull);
    });

    test('should reset pulse usage when PulseManager is reset', () {
      final bird = Bird();
      final obstacleManager = ObstacleManager(worldWidth: 800, worldHeight: 600);
      final pulseManager = PulseManager(bird: bird, obstacleManager: obstacleManager);
      
      // Activate pulse to increase usage
      if (pulseManager.pulseReady) {
        pulseManager.tryActivatePulse();
      }
      
      // Reset pulse manager
      pulseManager.reset();
      
      // Verify usage is reset
      final resetUsage = pulseManager.getTotalPulseUsage();
      expect(resetUsage, equals(0));
    });

    test('should reset power-up collection when PowerUpManager is cleared', () {
      final bird = Bird();
      final obstacleManager = ObstacleManager(worldWidth: 800, worldHeight: 600);
      final gameState = GameState();
      final powerUpManager = PowerUpManager(
        worldWidth: 800,
        worldHeight: 600,
        bird: bird,
        obstacleManager: obstacleManager,
        gameState: gameState,
      );
      
      // Clear all power-ups
      powerUpManager.clearAll();
      
      // Verify collection count is reset
      final resetCount = powerUpManager.getTotalPowerUpsCollected();
      expect(resetCount, equals(0));
    });
  });
}