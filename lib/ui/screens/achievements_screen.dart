import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/achievement.dart';
import '../../game/managers/achievement_manager.dart';
import '../theme/neon_theme.dart';
import '../components/neon_button.dart';

/// Screen displaying achievements and progress
class AchievementsScreen extends StatefulWidget {
  final AchievementManager achievementManager;

  const AchievementsScreen({
    super.key,
    required this.achievementManager,
  });

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  AchievementType _selectedFilter = AchievementType.score;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ACHIEVEMENTS',
          style: NeonTheme.headingStyle.copyWith(
            color: NeonTheme.primaryNeon,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: NeonTheme.primaryNeon,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: NeonTheme.primaryNeon,
          labelColor: NeonTheme.primaryNeon,
          unselectedLabelColor: NeonTheme.textSecondary,
          tabs: const [
            Tab(text: 'ACHIEVEMENTS'),
            Tab(text: 'LEADERBOARD'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAchievementsTab(),
          _buildLeaderboardTab(),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    return Column(
      children: [
        // Filter buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AchievementType.values.map((type) {
              final isSelected = _selectedFilter == type;
              return FilterChip(
                label: Text(_getTypeDisplayName(type)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = type;
                  });
                },
                backgroundColor: Colors.transparent,
                selectedColor: NeonTheme.primaryNeon.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? NeonTheme.primaryNeon : NeonTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? NeonTheme.primaryNeon : NeonTheme.textSecondary,
                ),
              );
            }).toList(),
          ),
        ),
        // Achievements list
        Expanded(
          child: _buildAchievementsList(),
        ),
      ],
    );
  }

  Widget _buildAchievementsList() {
    final achievements = widget.achievementManager
        .getAchievementsByType(_selectedFilter);

    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: NeonTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No achievements in this category',
              style: NeonTheme.bodyStyle.copyWith(
                color: NeonTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _buildAchievementCard(achievement, index);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement, int index) {
    final isUnlocked = achievement.isUnlocked;
    final progress = achievement.progressPercentage;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: NeonTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? achievement.iconColor : NeonTheme.textSecondary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: achievement.iconColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Achievement icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isUnlocked 
                    ? achievement.iconColor.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isUnlocked ? achievement.iconColor : Colors.grey,
                  width: 2,
                ),
              ),
              child: Icon(
                achievement.icon,
                color: isUnlocked ? achievement.iconColor : Colors.grey,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            // Achievement details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.name,
                    style: NeonTheme.headingStyle.copyWith(
                      fontSize: 18,
                      color: isUnlocked ? NeonTheme.textPrimary : NeonTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: NeonTheme.bodyStyle.copyWith(
                      color: NeonTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  if (!isUnlocked) ...[
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              achievement.iconColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${achievement.currentProgress}/${achievement.targetValue}',
                          style: NeonTheme.bodyStyle.copyWith(
                            color: NeonTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: achievement.iconColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'UNLOCKED',
                          style: NeonTheme.bodyStyle.copyWith(
                            color: achievement.iconColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (achievement.rewardSkinId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: achievement.iconColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: achievement.iconColor,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'SKIN REWARD',
                              style: NeonTheme.bodyStyle.copyWith(
                                color: achievement.iconColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Share button for unlocked achievements
            if (isUnlocked)
              IconButton(
                icon: Icon(
                  Icons.share,
                  color: achievement.iconColor,
                ),
                onPressed: () => _shareAchievement(achievement),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
  }

  Widget _buildLeaderboardTab() {
    final leaderboardEntries = widget.achievementManager.getPersonalBestScores();
    final stats = widget.achievementManager.gameStatistics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal stats summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: NeonTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: NeonTheme.primaryNeon,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: NeonTheme.primaryNeon.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERSONAL STATS',
                  style: NeonTheme.headingStyle.copyWith(
                    color: NeonTheme.primaryNeon,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatRow('High Score', stats['highScore'] ?? 0),
                _buildStatRow('Total Score', stats['totalScore'] ?? 0),
                _buildStatRow('Games Played', stats['gamesPlayed'] ?? 0),
                _buildStatRow('Pulse Usage', stats['pulseUsage'] ?? 0),
                _buildStatRow('Power-ups Collected', stats['powerUpsCollected'] ?? 0),
                _buildStatRow('Total Survival Time', 
                    Duration(seconds: stats['totalSurvivalTime'] ?? 0).inMinutes),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Share buttons
          Row(
            children: [
              Expanded(
                child: NeonButton(
                  text: 'SHARE HIGH SCORE',
                  onPressed: () => _shareHighScore(),
                  color: NeonTheme.secondaryNeon,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: NeonButton(
                  text: 'SHARE STATS',
                  onPressed: () => _shareStats(),
                  color: NeonTheme.accentNeon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Leaderboard entries
          Text(
            'PERSONAL BESTS',
            style: NeonTheme.headingStyle.copyWith(
              color: NeonTheme.primaryNeon,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          ...leaderboardEntries.map((entry) => _buildLeaderboardEntry(entry)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: NeonTheme.bodyStyle.copyWith(
              color: NeonTheme.textSecondary,
            ),
          ),
          Text(
            value.toString(),
            style: NeonTheme.bodyStyle.copyWith(
              color: NeonTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: NeonTheme.textSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: NeonTheme.primaryNeon.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: NeonTheme.primaryNeon,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: NeonTheme.bodyStyle.copyWith(
                  color: NeonTheme.primaryNeon,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.category,
                  style: NeonTheme.bodyStyle.copyWith(
                    color: NeonTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  entry.playerName,
                  style: NeonTheme.bodyStyle.copyWith(
                    color: NeonTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            entry.formattedScore,
            style: NeonTheme.headingStyle.copyWith(
              color: NeonTheme.primaryNeon,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeDisplayName(AchievementType type) {
    switch (type) {
      case AchievementType.score:
        return 'Score';
      case AchievementType.totalScore:
        return 'Total';
      case AchievementType.gamesPlayed:
        return 'Games';
      case AchievementType.pulseUsage:
        return 'Pulse';
      case AchievementType.powerUps:
        return 'Power-ups';
      case AchievementType.survival:
        return 'Survival';
    }
  }

  void _shareAchievement(Achievement achievement) {
    widget.achievementManager.shareAchievement(achievement);
  }

  void _shareHighScore() {
    final highScore = widget.achievementManager.gameStatistics['highScore'] ?? 0;
    widget.achievementManager.shareHighScore(score: highScore);
  }

  void _shareStats() {
    final stats = widget.achievementManager.gameStatistics;
    final message = 'Check out my Neon Pulse stats! 🎮✨\n'
        '🏆 High Score: ${stats['highScore']}\n'
        '📊 Total Score: ${stats['totalScore']}\n'
        '🎯 Games Played: ${stats['gamesPlayed']}\n'
        '⚡ Pulse Usage: ${stats['pulseUsage']}\n'
        '🔋 Power-ups: ${stats['powerUpsCollected']}\n'
        '#NeonPulse #Gaming';
    
    widget.achievementManager.shareHighScore(
      score: stats['highScore'] ?? 0,
      customMessage: message,
    );
  }
}