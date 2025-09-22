import 'package:flutter/material.dart';
import '../../game/managers/notification_manager.dart';
import '../../game/managers/achievement_manager.dart';
import '../theme/neon_theme.dart';

/// Notification settings component for the settings screen
class NotificationSettings extends StatefulWidget {
  final NotificationManager? notificationManager;
  final AchievementManager? achievementManager;
  final VoidCallback? onSettingsChanged;

  const NotificationSettings({
    super.key,
    this.notificationManager,
    this.achievementManager,
    this.onSettingsChanged,
  });

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  NotificationManager? _notificationManager;
  AchievementManager? _achievementManager;
  bool _isInitialized = false;
  bool _permissionsGranted = false;
  
  // Settings state
  bool _notificationsEnabled = true;
  bool _achievementNotifications = true;
  bool _milestoneNotifications = true;

  @override
  void initState() {
    super.initState();
    _notificationManager = widget.notificationManager;
    _achievementManager = widget.achievementManager;
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    if (_notificationManager != null) {
      await _notificationManager!.initialize();
      _permissionsGranted = await _notificationManager!.areNotificationsEnabled();
      
      final settings = _notificationManager!.notificationSettings;
      setState(() {
        _notificationsEnabled = settings['notifications_enabled'] ?? true;
        _achievementNotifications = settings['achievement_notifications'] ?? true;
        _milestoneNotifications = settings['milestone_notifications'] ?? true;
        _isInitialized = true;
      });
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (_notificationManager != null) {
      final granted = await _notificationManager!.requestPermissions();
      setState(() {
        _permissionsGranted = granted;
      });
      
      if (!granted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeonTheme.charcoal,
        title: Text(
          'Notification Permissions',
          style: TextStyle(
            color: NeonTheme.electricBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'To receive achievement and milestone notifications, please enable notifications in your device settings.',
          style: TextStyle(color: NeonTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: NeonTheme.electricBlue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'NOTIFICATION SETTINGS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: NeonTheme.electricBlue,
              letterSpacing: 2,
              shadows: NeonTheme.getNeonGlow(NeonTheme.electricBlue),
            ),
          ),
          const SizedBox(height: 30),

          // Permission status
          if (_notificationManager != null) ...[
            _buildPermissionStatus(),
            const SizedBox(height: 30),
          ],

          // Main notification toggle
          if (_notificationManager != null) ...[
            _buildNotificationToggle(
              title: 'Enable Notifications',
              subtitle: 'Allow the app to send notifications',
              value: _notificationsEnabled,
              onChanged: _permissionsGranted ? (value) async {
                await _notificationManager!.setNotificationsEnabled(value);
                setState(() {
                  _notificationsEnabled = value;
                });
                widget.onSettingsChanged?.call();
              } : null,
            ),
            const SizedBox(height: 20),
          ],

          // Achievement notifications
          if (_notificationManager != null) ...[
            _buildNotificationToggle(
              title: 'Achievement Notifications',
              subtitle: 'Get notified when you unlock achievements',
              value: _achievementNotifications && _notificationsEnabled,
              onChanged: _permissionsGranted && _notificationsEnabled ? (value) async {
                await _notificationManager!.setAchievementNotificationsEnabled(value);
                setState(() {
                  _achievementNotifications = value;
                });
                widget.onSettingsChanged?.call();
              } : null,
            ),
            const SizedBox(height: 20),
          ],

          // Milestone notifications
          if (_notificationManager != null) ...[
            _buildNotificationToggle(
              title: 'Milestone Notifications',
              subtitle: 'Get notified for score milestones and high scores',
              value: _milestoneNotifications && _notificationsEnabled,
              onChanged: _permissionsGranted && _notificationsEnabled ? (value) async {
                await _notificationManager!.setMilestoneNotificationsEnabled(value);
                setState(() {
                  _milestoneNotifications = value;
                });
                widget.onSettingsChanged?.call();
              } : null,
            ),
            const SizedBox(height: 30),
          ],

          // Test notification button
          if (_notificationManager != null && _permissionsGranted && _notificationsEnabled) ...[
            _buildTestNotificationButton(),
            const SizedBox(height: 20),
          ],

          // Clear all notifications button
          if (_notificationManager != null) ...[
            _buildClearNotificationsButton(),
          ],

          // Notification unavailable message
          if (_notificationManager == null) ...[
            _buildUnavailableMessage(),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonTheme.charcoal.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _permissionsGranted ? NeonTheme.neonGreen : NeonTheme.hotPink,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _permissionsGranted ? Icons.check_circle : Icons.warning,
            color: _permissionsGranted ? NeonTheme.neonGreen : NeonTheme.hotPink,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _permissionsGranted ? 'Notifications Enabled' : 'Permissions Required',
                  style: TextStyle(
                    color: _permissionsGranted ? NeonTheme.neonGreen : NeonTheme.hotPink,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _permissionsGranted 
                      ? 'You will receive notifications for achievements and milestones'
                      : 'Tap to grant notification permissions',
                  style: TextStyle(
                    color: NeonTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (!_permissionsGranted) ...[
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _requestPermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: NeonTheme.hotPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Grant'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonTheme.charcoal.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NeonTheme.electricBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: NeonTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: NeonTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: NeonTheme.electricBlue,
            activeTrackColor: NeonTheme.electricBlue.withOpacity(0.3),
            inactiveThumbColor: NeonTheme.textSecondary,
            inactiveTrackColor: NeonTheme.charcoal,
          ),
        ],
      ),
    );
  }

  Widget _buildTestNotificationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await _notificationManager!.showProgressionNotification(
            title: '🧪 Test Notification',
            message: 'This is a test notification from Neon Pulse!',
            payload: 'test',
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Test notification sent!',
                style: TextStyle(color: NeonTheme.textPrimary),
              ),
              backgroundColor: NeonTheme.charcoal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: NeonTheme.electricBlue.withOpacity(0.2),
          foregroundColor: NeonTheme.electricBlue,
          side: BorderSide(color: NeonTheme.electricBlue),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Send Test Notification',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildClearNotificationsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await _notificationManager!.cancelAllNotifications();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'All notifications cleared!',
                style: TextStyle(color: NeonTheme.textPrimary),
              ),
              backgroundColor: NeonTheme.charcoal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: NeonTheme.hotPink.withOpacity(0.2),
          foregroundColor: NeonTheme.hotPink,
          side: BorderSide(color: NeonTheme.hotPink),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Clear All Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildUnavailableMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeonTheme.charcoal.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NeonTheme.textSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off,
            color: NeonTheme.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Notifications Unavailable',
            style: TextStyle(
              color: NeonTheme.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notification system is not available on this device or configuration.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: NeonTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}