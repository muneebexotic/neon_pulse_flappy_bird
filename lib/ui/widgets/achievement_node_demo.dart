import 'package:flutter/material.dart';
import '../../models/achievement.dart';
import '../../models/progression_path_models.dart';
import '../theme/neon_theme.dart';
import 'achievement_node.dart';

/// Demo widget showcasing AchievementNode in different visual states
class AchievementNodeDemo extends StatelessWidget {
  const AchievementNodeDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Achievement Node Demo',
          style: NeonTheme.headingStyle.copyWith(
            shadows: NeonTheme.getNeonGlow(NeonTheme.primaryNeon),
          ),
        ),
        backgroundColor: NeonTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Locked Achievement',
              'Achievement that hasn\'t been started yet',
              AchievementNode(
                achievement: const Achievement(
                  id: 'locked_achievement',
                  name: 'First Flight',
                  description: 'Score your first point',
                  icon: Icons.flight_takeoff,
                  iconColor: Colors.cyan,
                  targetValue: 1,
                  type: AchievementType.score,
                  currentProgress: 0,
                ),
                visualState: NodeVisualState.locked,
                size: 60.0,
                onTap: () => _showAchievementDetails(context, 'First Flight', 'Locked'),
              ),
            ),
            
            _buildSection(
              'In Progress Achievement',
              'Achievement with partial progress (50%)',
              AchievementNode(
                achievement: const Achievement(
                  id: 'progress_achievement',
                  name: 'Century Club',
                  description: 'Score 100 points in a single game',
                  icon: Icons.star,
                  iconColor: Color(0xFFFFD700),
                  targetValue: 100,
                  type: AchievementType.score,
                  currentProgress: 50,
                ),
                visualState: NodeVisualState.inProgress,
                size: 60.0,
                onTap: () => _showAchievementDetails(context, 'Century Club', 'In Progress (50%)'),
              ),
            ),
            
            _buildSection(
              'Unlocked Achievement',
              'Completed achievement without reward',
              AchievementNode(
                achievement: const Achievement(
                  id: 'unlocked_achievement',
                  name: 'Pulse Master',
                  description: 'Use pulse mechanic 50 times',
                  icon: Icons.flash_on,
                  iconColor: Colors.yellow,
                  targetValue: 50,
                  type: AchievementType.pulseUsage,
                  currentProgress: 50,
                  isUnlocked: true,
                ),
                visualState: NodeVisualState.unlocked,
                size: 60.0,
                onTap: () => _showAchievementDetails(context, 'Pulse Master', 'Unlocked'),
              ),
            ),
            
            _buildSection(
              'Reward Available Achievement',
              'Completed achievement with bird skin reward',
              AchievementNode(
                achievement: const Achievement(
                  id: 'reward_achievement',
                  name: 'Power Collector',
                  description: 'Collect 25 power-ups',
                  icon: Icons.battery_charging_full,
                  iconColor: Colors.green,
                  targetValue: 25,
                  type: AchievementType.powerUps,
                  rewardSkinId: 'energy_bird',
                  currentProgress: 25,
                  isUnlocked: true,
                ),
                visualState: NodeVisualState.rewardAvailable,
                size: 60.0,
                onTap: () => _showAchievementDetails(context, 'Power Collector', 'Reward Available'),
              ),
            ),
            
            const SizedBox(height: 40),
            
            Text(
              'Different Sizes',
              style: NeonTheme.headingStyle.copyWith(
                fontSize: 18,
                shadows: NeonTheme.getNeonGlow(NeonTheme.secondaryNeon),
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    AchievementNode(
                      achievement: const Achievement(
                        id: 'small_achievement',
                        name: 'Small',
                        description: 'Small size (44dp)',
                        icon: Icons.star,
                        iconColor: Colors.blue,
                        targetValue: 10,
                        type: AchievementType.score,
                        currentProgress: 10,
                        isUnlocked: true,
                      ),
                      visualState: NodeVisualState.unlocked,
                      size: 44.0,
                      onTap: () => _showAchievementDetails(context, 'Small Node', '44dp'),
                    ),
                    const SizedBox(height: 8),
                    const Text('44dp', style: TextStyle(color: Colors.white70)),
                  ],
                ),
                Column(
                  children: [
                    AchievementNode(
                      achievement: const Achievement(
                        id: 'medium_achievement',
                        name: 'Medium',
                        description: 'Medium size (60dp)',
                        icon: Icons.star,
                        iconColor: Colors.orange,
                        targetValue: 10,
                        type: AchievementType.score,
                        currentProgress: 5,
                      ),
                      visualState: NodeVisualState.inProgress,
                      size: 60.0,
                      onTap: () => _showAchievementDetails(context, 'Medium Node', '60dp'),
                    ),
                    const SizedBox(height: 8),
                    const Text('60dp', style: TextStyle(color: Colors.white70)),
                  ],
                ),
                Column(
                  children: [
                    AchievementNode(
                      achievement: const Achievement(
                        id: 'large_achievement',
                        name: 'Large',
                        description: 'Large size (80dp)',
                        icon: Icons.star,
                        iconColor: Colors.purple,
                        targetValue: 10,
                        type: AchievementType.score,
                        currentProgress: 0,
                      ),
                      visualState: NodeVisualState.locked,
                      size: 80.0,
                      onTap: () => _showAchievementDetails(context, 'Large Node', '80dp'),
                    ),
                    const SizedBox(height: 8),
                    const Text('80dp', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String description, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: NeonTheme.headingStyle.copyWith(
              fontSize: 18,
              shadows: NeonTheme.getNeonGlow(NeonTheme.secondaryNeon),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: NeonTheme.bodyStyle.copyWith(
              color: NeonTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Center(child: child),
        ],
      ),
    );
  }

  void _showAchievementDetails(BuildContext context, String name, String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeonTheme.cardBackground,
        title: Text(
          name,
          style: NeonTheme.headingStyle.copyWith(
            fontSize: 18,
            shadows: NeonTheme.getNeonGlow(NeonTheme.primaryNeon),
          ),
        ),
        content: Text(
          'Status: $status\n\nThis demonstrates the tap functionality of the AchievementNode widget.',
          style: NeonTheme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: NeonTheme.buttonStyle.copyWith(
                color: NeonTheme.primaryNeon,
              ),
            ),
          ),
        ],
      ),
    );
  }
}