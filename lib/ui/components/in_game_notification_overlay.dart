import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'dart:collection';
import '../../models/achievement.dart';
import '../../models/bird_skin.dart';
import '../theme/neon_theme.dart';
import '../../game/effects/neon_colors.dart';

/// Notification item that can be displayed in the overlay
abstract class NotificationItem {
  String get id;
  String get title;
  String get subtitle;
  Color get primaryColor;
  IconData get icon;
  Duration get displayDuration;
}

/// Achievement unlock notification item
class AchievementNotificationItem extends NotificationItem {
  final Achievement achievement;

  AchievementNotificationItem(this.achievement);

  @override
  String get id => 'achievement_${achievement.id}';

  @override
  String get title => achievement.name;

  @override
  String get subtitle => achievement.description;

  @override
  Color get primaryColor => achievement.iconColor;

  @override
  IconData get icon => achievement.icon;

  @override
  Duration get displayDuration => const Duration(seconds: 4);
}

/// Achievement progress milestone notification item
class ProgressMilestoneNotificationItem extends NotificationItem {
  final Achievement achievement;
  final double progress;

  ProgressMilestoneNotificationItem(this.achievement, this.progress);

  @override
  String get id => 'progress_${achievement.id}_${(progress * 100).round()}';

  @override
  String get title => '${(progress * 100).round()}% Progress';

  @override
  String get subtitle => achievement.name;

  @override
  Color get primaryColor => achievement.iconColor;

  @override
  IconData get icon => achievement.icon;

  @override
  Duration get displayDuration => const Duration(seconds: 2);
}

/// Skin unlock notification item
class SkinUnlockNotificationItem extends NotificationItem {
  final BirdSkin skin;

  SkinUnlockNotificationItem(this.skin);

  @override
  String get id => 'skin_${skin.id}';

  @override
  String get title => 'New Skin Unlocked!';

  @override
  String get subtitle => skin.name;

  @override
  Color get primaryColor => skin.primaryColor;

  @override
  IconData get icon => Icons.palette;

  @override
  Duration get displayDuration => const Duration(seconds: 4);
}

/// In-game notification overlay that displays achievement notifications during gameplay
class InGameNotificationOverlay extends StatefulWidget {
  /// Whether the overlay is currently visible
  final bool isVisible;

  /// Callback when a notification is tapped
  final Function(NotificationItem)? onNotificationTapped;

  /// Callback when all notifications are dismissed
  final VoidCallback? onAllNotificationsDismissed;

  /// Maximum number of notifications to show simultaneously
  final int maxSimultaneousNotifications;

  /// Whether to auto-dismiss notifications after their display duration
  final bool autoDismiss;

  const InGameNotificationOverlay({
    super.key,
    this.isVisible = true,
    this.onNotificationTapped,
    this.onAllNotificationsDismissed,
    this.maxSimultaneousNotifications = 3,
    this.autoDismiss = true,
  });

  @override
  State<InGameNotificationOverlay> createState() => InGameNotificationOverlayState();

  /// Create a global key for easy access to the overlay state
  static GlobalKey<InGameNotificationOverlayState> createKey() {
    return GlobalKey<InGameNotificationOverlayState>();
  }
}

class InGameNotificationOverlayState extends State<InGameNotificationOverlay>
    with TickerProviderStateMixin {
  
  /// Queue of pending notifications
  final Queue<NotificationItem> _notificationQueue = Queue<NotificationItem>();
  
  /// Currently displayed notifications with their items and controllers
  final Map<String, NotificationItem> _displayedNotificationItems = {};
  final Map<String, AnimationController> _displayedNotificationControllers = {};
  
  /// Timers for auto-dismissing notifications
  final Map<String, Timer> _dismissTimers = {};

  @override
  void dispose() {
    // Clean up all animation controllers and timers
    for (final controller in _displayedNotificationControllers.values) {
      controller.dispose();
    }
    for (final timer in _dismissTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  /// Add a new notification to the queue
  void showNotification(NotificationItem notification) {
    if (!mounted || !widget.isVisible) return;

    // Check if this notification is already displayed or queued
    if (_displayedNotificationItems.containsKey(notification.id) ||
        _notificationQueue.any((item) => item.id == notification.id)) {
      return;
    }

    setState(() {
      _notificationQueue.add(notification);
    });

    _processNotificationQueue();
  }

  /// Show achievement unlock notification
  void showAchievementUnlock(Achievement achievement) {
    showNotification(AchievementNotificationItem(achievement));
  }

  /// Show achievement progress milestone notification
  void showProgressMilestone(Achievement achievement, double progress) {
    // Only show milestones at 25%, 50%, 75%
    final percentage = (progress * 100).round();
    if (percentage == 25 || percentage == 50 || percentage == 75) {
      showNotification(ProgressMilestoneNotificationItem(achievement, progress));
    }
  }

  /// Show skin unlock notification
  void showSkinUnlock(BirdSkin skin) {
    showNotification(SkinUnlockNotificationItem(skin));
  }

  /// Process the notification queue and display notifications
  void _processNotificationQueue() {
    while (_notificationQueue.isNotEmpty && 
           _displayedNotificationItems.length < widget.maxSimultaneousNotifications) {
      
      final notification = _notificationQueue.removeFirst();
      _displayNotification(notification);
    }
  }

  /// Display a single notification
  void _displayNotification(NotificationItem notification) {
    if (!mounted) return;

    // Create animation controller for this notification
    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    setState(() {
      _displayedNotificationItems[notification.id] = notification;
      _displayedNotificationControllers[notification.id] = controller;
    });

    // Start the entrance animation
    controller.forward();

    // Set up auto-dismiss timer if enabled
    if (widget.autoDismiss) {
      _dismissTimers[notification.id] = Timer(notification.displayDuration, () {
        _dismissNotification(notification.id);
      });
    }
  }

  /// Dismiss a notification by ID
  void _dismissNotification(String notificationId) {
    if (!mounted || !_displayedNotificationControllers.containsKey(notificationId)) {
      return;
    }

    final controller = _displayedNotificationControllers[notificationId]!;
    
    // Animate out
    controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _displayedNotificationItems.remove(notificationId);
          _displayedNotificationControllers.remove(notificationId);
        });
        
        // Cancel timer if it exists
        _dismissTimers[notificationId]?.cancel();
        _dismissTimers.remove(notificationId);
        
        // Dispose controller
        controller.dispose();
        
        // Process more notifications from queue
        _processNotificationQueue();
        
        // Check if all notifications are dismissed
        if (_displayedNotificationItems.isEmpty && _notificationQueue.isEmpty) {
          widget.onAllNotificationsDismissed?.call();
        }
      }
    });
  }

  /// Dismiss all notifications
  void dismissAll() {
    final notificationIds = List<String>.from(_displayedNotificationControllers.keys);
    for (final id in notificationIds) {
      _dismissNotification(id);
    }
    
    setState(() {
      _notificationQueue.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible || _displayedNotificationItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 80, // Below game HUD
      left: 16,
      right: 16,
      child: IgnorePointer(
        ignoring: false,
        child: Column(
          children: _buildNotificationWidgets(),
        ),
      ),
    );
  }

  /// Build the list of notification widgets
  List<Widget> _buildNotificationWidgets() {
    final widgets = <Widget>[];
    
    int index = 0;
    for (final notificationId in _displayedNotificationItems.keys) {
      final notification = _displayedNotificationItems[notificationId]!;
      final controller = _displayedNotificationControllers[notificationId]!;
      
      widgets.add(
        Padding(
          padding: EdgeInsets.only(top: index * 8.0), // Slight stagger
          child: _InGameNotificationCard(
            notification: notification,
            controller: controller,
            onTap: () {
              widget.onNotificationTapped?.call(notification);
              _dismissNotification(notificationId);
            },
            onDismiss: () => _dismissNotification(notificationId),
          ),
        ),
      );
      index++;
    }
    
    return widgets;
  }
}

/// Individual notification card widget
class _InGameNotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final AnimationController controller;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _InGameNotificationCard({
    required this.notification,
    required this.controller,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            (1.0 - controller.value) * MediaQuery.of(context).size.width,
            0,
          ),
          child: Opacity(
            opacity: controller.value,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NeonColors.darkGray.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: notification.primaryColor.withOpacity(0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: notification.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with glow effect
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: notification.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: notification.primaryColor,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        notification.icon,
                        color: notification.primaryColor,
                        size: 20,
                      ),
                    ).animate(onPlay: (controller) => controller.repeat())
                        .shimmer(
                          duration: 1500.ms,
                          color: notification.primaryColor.withOpacity(0.4),
                        ),
                    
                    const SizedBox(width: 12),
                    
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notification.title,
                            style: NeonTheme.bodyStyle.copyWith(
                              color: notification.primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (notification.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              notification.subtitle,
                              style: NeonTheme.bodyStyle.copyWith(
                                color: NeonTheme.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Dismiss button
                    if (onDismiss != null)
                      GestureDetector(
                        onTap: onDismiss,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            color: NeonTheme.textSecondary,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}

/// Extension to make the overlay easier to use
extension InGameNotificationOverlayExtension on GlobalKey<InGameNotificationOverlayState> {
  /// Show an achievement unlock notification
  void showAchievementUnlock(Achievement achievement) {
    currentState?.showAchievementUnlock(achievement);
  }

  /// Show a progress milestone notification
  void showProgressMilestone(Achievement achievement, double progress) {
    currentState?.showProgressMilestone(achievement, progress);
  }

  /// Show a skin unlock notification
  void showSkinUnlock(BirdSkin skin) {
    currentState?.showSkinUnlock(skin);
  }

  /// Dismiss all notifications
  void dismissAll() {
    currentState?.dismissAll();
  }
}