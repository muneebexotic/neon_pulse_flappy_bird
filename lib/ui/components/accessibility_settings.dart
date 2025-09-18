import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../../game/managers/accessibility_manager.dart';
import '../../game/managers/haptic_manager.dart';
import '../../game/managers/settings_manager.dart';

/// Accessibility settings widget with haptic and audio feedback options
class AccessibilitySettings extends StatefulWidget {
  final AccessibilityManager accessibilityManager;
  final HapticManager hapticManager;
  final SettingsManager settingsManager;
  final VoidCallback? onSettingsChanged;

  const AccessibilitySettings({
    super.key,
    required this.accessibilityManager,
    required this.hapticManager,
    required this.settingsManager,
    this.onSettingsChanged,
  });

  @override
  State<AccessibilitySettings> createState() => _AccessibilitySettingsState();
}

class _AccessibilitySettingsState extends State<AccessibilitySettings> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Haptic Feedback'),
          _buildHapticSettings(),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Audio Accessibility'),
          _buildAudioSettings(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: NeonTheme.electricBlue,
        ),
      ),
    );
  }

  Widget _buildHapticSettings() {
    return Column(
      children: [
        _buildSettingTile(
          title: 'Haptic Feedback',
          subtitle: 'Vibration patterns for game events',
          value: widget.settingsManager.hapticEnabled,
          onChanged: (value) async {
            await widget.settingsManager.setHapticEnabled(value);
            widget.onSettingsChanged?.call();
            setState(() {});
          },
        ),
        _buildSettingTile(
          title: 'Vibration Intensity',
          subtitle: 'Adjust vibration strength',
          value: widget.settingsManager.vibrationEnabled,
          onChanged: (value) async {
            await widget.settingsManager.setVibrationEnabled(value);
            widget.onSettingsChanged?.call();
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildAudioSettings() {
    return Column(
      children: [
        _buildSettingTile(
          title: 'Sound-Based Feedback',
          subtitle: 'Audio cues for visual elements',
          value: widget.accessibilityManager.soundBasedFeedback,
          onChanged: (value) async {
            await widget.accessibilityManager.setSoundBasedFeedback(value);
            widget.onSettingsChanged?.call();
            setState(() {});
          },
        ),
        _buildInfoCard(
          'Sound-based feedback provides audio cues for visual game elements, helping players with visual impairments.',
          Icons.info_outline,
          NeonTheme.electricBlue,
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonTheme.charcoal.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NeonTheme.electricBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: NeonTheme.textSecondary,
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
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String message, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}