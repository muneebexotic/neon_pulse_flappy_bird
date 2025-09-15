import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/achievement.dart';
import '../../models/bird_skin.dart';
import '../theme/neon_theme.dart';

/// Widget that displays achievement unlock notifications
class AchievementNotification extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const AchievementNotification({
    super.key,
    required this.achievement,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achievement.iconColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: achievement.iconColor.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Achievement icon with glow effect
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: achievement.iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: achievement.iconColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: achievement.iconColor.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              achievement.icon,
              color: achievement.iconColor,
              size: 30,
            ),
          ).animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2000.ms, color: achievement.iconColor.withOpacity(0.5)),
          
          const SizedBox(width: 16),
          
          // Achievement details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ACHIEVEMENT UNLOCKED!',
                  style: NeonTheme.bodyStyle.copyWith(
                    color: achievement.iconColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.name,
                  style: NeonTheme.headingStyle.copyWith(
                    color: NeonTheme.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: NeonTheme.bodyStyle.copyWith(
                    color: NeonTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (achievement.rewardSkinId != null) ...[
                  const SizedBox(height: 8),
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
                      '🎨 SKIN REWARD UNLOCKED',
                      style: NeonTheme.bodyStyle.copyWith(
                        color: achievement.iconColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Dismiss button
          if (onDismiss != null)
            IconButton(
              icon: Icon(
                Icons.close,
                color: NeonTheme.textSecondary,
                size: 20,
              ),
              onPressed: onDismiss,
            ),
        ],
      ),
    ).animate()
        .slideX(begin: 1.0, end: 0.0, duration: 500.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 300.ms);
  }
}

/// Widget that displays skin unlock notifications
class SkinUnlockNotification extends StatelessWidget {
  final BirdSkin skin;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const SkinUnlockNotification({
    super.key,
    required this.skin,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: skin.primaryColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: skin.primaryColor.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Skin preview with glow effect
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: skin.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: skin.primaryColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: skin.primaryColor.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.pets, // Bird icon
              color: skin.primaryColor,
              size: 30,
            ),
          ).animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2000.ms, color: skin.primaryColor.withOpacity(0.5)),
          
          const SizedBox(width: 16),
          
          // Skin details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NEW SKIN UNLOCKED!',
                  style: NeonTheme.bodyStyle.copyWith(
                    color: skin.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  skin.name,
                  style: NeonTheme.headingStyle.copyWith(
                    color: NeonTheme.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  skin.description,
                  style: NeonTheme.bodyStyle.copyWith(
                    color: NeonTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: skin.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: skin.primaryColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'TAP TO EQUIP',
                    style: NeonTheme.bodyStyle.copyWith(
                      color: skin.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Dismiss button
          if (onDismiss != null)
            IconButton(
              icon: Icon(
                Icons.close,
                color: NeonTheme.textSecondary,
                size: 20,
              ),
              onPressed: onDismiss,
            ),
        ],
      ),
    ).animate()
        .slideX(begin: 1.0, end: 0.0, duration: 500.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 300.ms);
  }
}

/// Overlay widget that manages and displays achievement notifications
class AchievementNotificationOverlay extends StatefulWidget {
  final List<Achievement> achievements;
  final List<BirdSkin> skins;
  final VoidCallback? onAllDismissed;
  final Function(BirdSkin)? onSkinTapped;

  const AchievementNotificationOverlay({
    super.key,
    required this.achievements,
    required this.skins,
    this.onAllDismissed,
    this.onSkinTapped,
  });

  @override
  State<AchievementNotificationOverlay> createState() => 
      _AchievementNotificationOverlayState();
}

class _AchievementNotificationOverlayState 
    extends State<AchievementNotificationOverlay> {
  late List<Achievement> _achievements;
  late List<BirdSkin> _skins;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _achievements = List.from(widget.achievements);
    _skins = List.from(widget.skins);
    
    // Auto-dismiss after 5 seconds if not interacted with
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _dismissAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_achievements.isEmpty && _skins.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Column(
          children: [
            // Show current achievement
            if (_currentIndex < _achievements.length)
              GestureDetector(
                onTap: () => _dismissCurrent(),
                child: AchievementNotification(
                  achievement: _achievements[_currentIndex],
                  onDismiss: () => _dismissCurrent(),
                ),
              ),
            
            // Show current skin unlock
            if (_achievements.isEmpty && _currentIndex < _skins.length)
              GestureDetector(
                onTap: () {
                  widget.onSkinTapped?.call(_skins[_currentIndex]);
                  _dismissCurrent();
                },
                child: SkinUnlockNotification(
                  skin: _skins[_currentIndex],
                  onTap: () {
                    widget.onSkinTapped?.call(_skins[_currentIndex]);
                    _dismissCurrent();
                  },
                  onDismiss: () => _dismissCurrent(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _dismissCurrent() {
    setState(() {
      if (_currentIndex < _achievements.length) {
        _achievements.removeAt(_currentIndex);
      } else if (_achievements.isEmpty && _currentIndex < _skins.length) {
        _skins.removeAt(_currentIndex);
      }
      
      // Reset index if we've gone past the end
      if (_currentIndex >= _achievements.length + _skins.length) {
        _currentIndex = 0;
      }
    });

    // Check if all notifications are dismissed
    if (_achievements.isEmpty && _skins.isEmpty) {
      widget.onAllDismissed?.call();
    }
  }

  void _dismissAll() {
    setState(() {
      _achievements.clear();
      _skins.clear();
    });
    widget.onAllDismissed?.call();
  }
}