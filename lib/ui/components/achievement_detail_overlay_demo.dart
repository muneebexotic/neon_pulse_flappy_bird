import 'package:flutter/material.dart';
import '../../models/achievement.dart';
import '../../models/bird_skin.dart';
import '../../game/managers/achievement_manager.dart';
import '../../game/managers/customization_manager.dart';
import '../../game/managers/notification_manager.dart';
import 'achievement_detail_overlay.dart';

/// Demo screen showing how to use the AchievementDetailOverlay
class AchievementDetailOverlayDemo extends StatefulWidget {
  const AchievementDetailOverlayDemo({super.key});

  @override
  State<AchievementDetailOverlayDemo> createState() => _AchievementDetailOverlayDemoState();
}

class _AchievementDetailOverlayDemoState extends State<AchievementDetailOverlayDemo> {
  late AchievementManager achievementManager;
  
  // Sample achievements for demo
  final List<Achievement> sampleAchievements = [
    const Achievement(
      id: 'first_flight',
      name: 'First Flight',
      description: 'Score your first point in the neon cyberpunk world',
      icon: Icons.flight_takeoff,
      iconColor: Colors.cyan,
      targetValue: 1,
      type: AchievementType.score,
      trackingType: AchievementTrackingType.milestone,
      isUnlocked: true,
      currentProgress: 1,
    ),
    const Achievement(
      id: 'pulse_master',
      name: 'Pulse Master',
      description: 'Master the pulse mechanic by using it 50 times to navigate through obstacles',
      icon: Icons.flash_on,
      iconColor: Colors.yellow,
      targetValue: 50,
      type: AchievementType.pulseUsage,
      trackingType: AchievementTrackingType.cumulative,
      rewardSkinId: 'pulse_master_skin',
      isUnlocked: false,
      currentProgress: 25,
    ),
    const Achievement(
      id: 'century_club',
      name: 'Century Club',
      description: 'Achieve the legendary score of 100 points in a single epic flight',
      icon: Icons.star,
      iconColor: Color(0xFFFFD700),
      targetValue: 100,
      trackingType: AchievementTrackingType.singleRun,
      resetsOnFailure: true,
      type: AchievementType.score,
      rewardSkinId: 'golden_bird',
      isUnlocked: false,
      currentProgress: 75,
    ),
  ];

  // Sample bird skins for demo
  final Map<String, BirdSkin> sampleSkins = {
    'pulse_master_skin': const BirdSkin(
      id: 'pulse_master_skin',
      name: 'Pulse Master',
      primaryColor: Colors.yellow,
      trailColor: Colors.orange,
      description: 'Electrifying yellow energy with pulsing effects',
      unlockScore: 0,
      isUnlocked: true,
    ),
    'golden_bird': const BirdSkin(
      id: 'golden_bird',
      name: 'Golden Phoenix',
      primaryColor: Color(0xFFFFD700),
      trailColor: Color(0xFFFF8C00),
      description: 'Legendary golden bird with majestic trail effects',
      unlockScore: 100,
      isUnlocked: false,
    ),
  };

  @override
  void initState() {
    super.initState();
    achievementManager = AchievementManager(CustomizationManager(), NotificationManager());
  }

  void _showAchievementOverlay(Achievement achievement) {
    final rewardSkin = achievement.rewardSkinId != null 
        ? sampleSkins[achievement.rewardSkinId!] 
        : null;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AchievementDetailOverlay(
        achievement: achievement,
        rewardSkin: rewardSkin,
        achievementManager: achievementManager,
        onClose: () => Navigator.of(context).pop(),
        onShare: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Achievement shared!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B1F),
      appBar: AppBar(
        title: const Text(
          'Achievement Detail Overlay Demo',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: Colors.cyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A0B2E),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tap any achievement to view its detailed overlay:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: sampleAchievements.length,
                itemBuilder: (context, index) {
                  final achievement = sampleAchievements[index];
                  return _buildAchievementCard(achievement);
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Features demonstrated:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Zoom-in animations with elastic effects\n'
              '• Progress visualization with animated bars\n'
              '• Bird skin preview integration\n'
              '• Different achievement types and states\n'
              '• Neon cyberpunk styling\n'
              '• Particle effects for unlocked achievements\n'
              '• Responsive layout and accessibility',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final progressPercentage = (achievement.progressPercentage * 100).toInt();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF2D2D2D),
      child: InkWell(
        onTap: () => _showAchievementOverlay(achievement),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Achievement icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: achievement.iconColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: achievement.iconColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  achievement.icon,
                  color: achievement.iconColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Achievement info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Progress indicator
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: achievement.progressPercentage,
                            backgroundColor: Colors.grey[800],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              achievement.iconColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$progressPercentage%',
                          style: TextStyle(
                            color: achievement.iconColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: achievement.isUnlocked 
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  border: Border.all(
                    color: achievement.isUnlocked ? Colors.green : Colors.orange,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  achievement.isUnlocked ? 'UNLOCKED' : 'IN PROGRESS',
                  style: TextStyle(
                    color: achievement.isUnlocked ? Colors.green : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}