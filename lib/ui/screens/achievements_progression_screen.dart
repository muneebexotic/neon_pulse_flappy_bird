import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/achievement.dart';
import '../../game/managers/achievement_manager.dart';
import '../../game/managers/adaptive_quality_manager.dart';
import '../../game/managers/haptic_manager.dart';
import '../../game/managers/achievement_event_manager.dart';

/// Main achievements progression screen that orchestrates all components
class AchievementsProgressionScreen extends StatefulWidget {
  final AchievementManager achievementManager;
  final AdaptiveQualityManager? adaptiveQualityManager;
  final HapticManager? hapticManager;

  const AchievementsProgressionScreen({
    super.key,
    required this.achievementManager,
    this.adaptiveQualityManager,
    this.hapticManager,
  });

  @override
  State<AchievementsProgressionScreen> createState() => _AchievementsProgressionScreenState();
}

class _AchievementsProgressionScreenState extends State<AchievementsProgressionScreen> {
  bool _isLoading = true;
  List<Achievement> _achievements = [];
  StreamSubscription<AchievementEvent>? _achievementSubscription;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
    _listenToAchievementUpdates();
  }

  @override
  void dispose() {
    _achievementSubscription?.cancel();
    super.dispose();
  }

  void _loadAchievements() async {
    // Simple initialization without complex controllers
    await Future.delayed(const Duration(milliseconds: 100)); // Brief delay to simulate loading
    
    if (mounted) {
      setState(() {
        _achievements = widget.achievementManager.achievements;
        _isLoading = false;
      });
    }
  }

  /// Subscribe to achievement events for real-time updates
  void _listenToAchievementUpdates() {
    _achievementSubscription = AchievementEventManager.instance.achievementEvents.listen(
      _handleAchievementEvent,
      onError: (error) {
        // Handle stream errors gracefully
        debugPrint('Achievement event stream error: $error');
      },
    );
  }

  /// Process real-time achievement updates
  void _handleAchievementEvent(AchievementEvent event) {
    if (!mounted) return;

    // Handle different types of achievement events
    if (event is AchievementProgressEvent) {
      _updateAchievementDisplay(event.achievement);
    } else if (event is AchievementUnlockedEvent) {
      _updateAchievementDisplay(event.achievement);
    } else if (event is StatisticsUpdatedEvent) {
      // Refresh all achievements when statistics change
      _refreshAllAchievements();
    }
  }

  /// Refresh UI with new achievement data
  void _updateAchievementDisplay(Achievement updatedAchievement) {
    if (!mounted) return;

    setState(() {
      // Find and update the specific achievement in the list
      final index = _achievements.indexWhere((a) => a.id == updatedAchievement.id);
      if (index != -1) {
        _achievements[index] = updatedAchievement;
      }
    });
  }

  /// Refresh all achievements from the manager
  void _refreshAllAchievements() {
    if (!mounted) return;

    setState(() {
      _achievements = widget.achievementManager.achievements;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B1F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF1493)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'PROGRESSION PATH',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF1493),
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading ? _buildLoadingState() : _buildMainContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1493)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading Progression Path...',
            style: TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 16,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_achievements.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B0B1F),
            Color(0xFF1A0B2E),
          ],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final achievement = _achievements[index];
                  return _buildAchievementCard(achievement, index);
                },
                childCount: _achievements.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF1493), width: 2),
              color: const Color(0xFFFF1493).withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.star_outline,
              size: 40,
              color: Color(0xFFFF1493),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'BEGIN YOUR JOURNEY',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF1493),
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Your progression path awaits! Start playing to unlock achievements and discover new bird skins.',
              style: TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, int index) {
    final isUnlocked = achievement.isUnlocked;
    final progress = achievement.progressPercentage;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? const Color(0xFFFF1493) : const Color(0xFF333333),
          width: 2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isUnlocked ? const Color(0xFFFF1493) : const Color(0xFF333333)).withValues(alpha: 0.1),
            (isUnlocked ? const Color(0xFFFF1493) : const Color(0xFF333333)).withValues(alpha: 0.05),
          ],
        ),
        boxShadow: isUnlocked ? [
          BoxShadow(
            color: const Color(0xFFFF1493).withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked ? const Color(0xFFFF1493) : const Color(0xFF333333),
                ),
                child: Icon(
                  isUnlocked ? Icons.check : Icons.lock,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.name,
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? const Color(0xFFFF1493) : const Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isUnlocked && progress > 0) ...[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress: ${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFF333333),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF1493)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}