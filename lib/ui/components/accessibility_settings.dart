import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../theme/accessibility_theme.dart';
import '../../game/managers/accessibility_manager.dart';
import '../../game/managers/haptic_manager.dart';
import '../../game/managers/settings_manager.dart';

/// Accessibility settings widget with comprehensive options
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
  late AccessibilityTheme _accessibilityTheme;

  @override
  void initState() {
    super.initState();
    _accessibilityTheme = AccessibilityTheme(widget.accessibilityManager);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Haptic Feedback'),
          _buildHapticSettings(),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Visual Accessibility'),
          _buildVisualSettings(),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Color Accessibility'),
          _buildColorSettings(),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Audio Accessibility'),
          _buildAudioSettings(),
          const SizedBox(height: 24),
          
          _buildSectionHeader('UI Scaling'),
          _buildScalingSettings(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: _accessibilityTheme.textStyles.heading.copyWith(
          fontSize: 20,
          color: _accessibilityTheme.colors.electricBlue,
        ),
      ),
    );
  }

  Widget _buildHapticSettings() {
    return Column(
      children: [
        _buildSettingTile(
          title: 'Haptic Feedback',
          subtitle: 'Feel vibrations for game actions',
          value: widget.settingsManager.hapticEnabled,
          onChanged: (value) async {
            await widget.settingsManager.setHapticEnabled(value);
            widget.hapticManager.setHapticEnabled(value);
            widget.onSettingsChanged?.call();
            
            if (value) {
              await widget.hapticManager.lightImpact();
            }
            
            setState(() {});
          },
        ),
        _buildSettingTile(
          title: 'Vibration Patterns',
          subtitle: 'Enhanced vibration for different events',
          value: widget.settingsManager.vibrationEnabled,
          enabled: widget.hapticManager.deviceSupportsVibration,
          onChanged: (value) async {
            await widget.settingsManager.setVibrationEnabled(value);
            widget.hapticManager.setVibrationEnabled(value);
            widget.onSettingsChanged?.call();
            
            if (value) {
              await widget.hapticManager.uiFeedback();
            }
            
            setState(() {});
          },
        ),
        if (!widget.hapticManager.deviceSupportsVibration)
          _buildInfoCard(
            'Vibration not supported on this device',
            Icons.info_outline,
            _accessibilityTheme.colors.colorBlindFriendly.info,
          ),
      ],
    );
  }

  Widget _buildVisualSettings() {
    return Column(
      children: [
        _buildSettingTile(
          title: 'High Contrast Mode',
          subtitle: 'Increase contrast for better visibility',
          value: widget.accessibilityManager.highContrastMode,
          onChanged: (value) async {
            await widget.accessibilityManager.setHighContrastMode(value);
            await widget.settingsManager.setHighContrastMode(value);
            widget.onSettingsChanged?.call();
            setState(() {
              _accessibilityTheme = AccessibilityTheme(widget.accessibilityManager);
            });
          },
        ),
        _buildSettingTile(
          title: 'Reduced Motion',
          subtitle: 'Minimize animations and effects',
          value: widget.accessibilityManager.reducedMotion,
          onChanged: (value) async {
            await widget.accessibilityManager.setReducedMotion(value);
            await widget.settingsManager.setReducedMotion(value);
            widget.onSettingsChanged?.call();
            setState(() {
              _accessibilityTheme = AccessibilityTheme(widget.accessibilityManager);
            });
          },
        ),
        _buildSettingTile(
          title: 'Large Text',
          subtitle: 'Increase text size for better readability',
          value: widget.accessibilityManager.largeText,
          onChanged: (value) async {
            await widget.accessibilityManager.setLargeText(value);
            await widget.settingsManager.setLargeText(value);
            widget.onSettingsChanged?.call();
            setState(() {
              _accessibilityTheme = AccessibilityTheme(widget.accessibilityManager);
            });
          },
        ),
      ],
    );
  }

  Widget _buildColorSettings() {
    return Column(
      children: [
        _buildSettingTile(
          title: 'Color Blind Friendly',
          subtitle: 'Use colors that work for color vision deficiency',
          value: widget.accessibilityManager.colorBlindFriendly,
          onChanged: (value) async {
            await widget.accessibilityManager.setColorBlindFriendly(value);
            await widget.settingsManager.setColorBlindFriendly(value);
            widget.onSettingsChanged?.call();
            setState(() {
              _accessibilityTheme = AccessibilityTheme(widget.accessibilityManager);
            });
          },
        ),
        if (widget.accessibilityManager.colorBlindFriendly)
          _buildColorBlindTypeSelector(),
        _buildColorPreview(),
      ],
    );
  }

  Widget _buildColorBlindTypeSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: AccessibilityDecorations(widget.accessibilityManager)
          .getNeonBorder(_accessibilityTheme.colors.electricBlue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color Vision Type',
            style: _accessibilityTheme.textStyles.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...ColorBlindType.values.map((type) => RadioListTile<ColorBlindType>(
            title: Text(
              type.displayName,
              style: _accessibilityTheme.textStyles.body,
            ),
            subtitle: Text(
              type.description,
              style: _accessibilityTheme.textStyles.body.copyWith(
                fontSize: 12,
                color: _accessibilityTheme.colors.textSecondary,
              ),
            ),
            value: type,
            groupValue: widget.accessibilityManager.colorBlindType,
            activeColor: _accessibilityTheme.colors.electricBlue,
            onChanged: (value) async {
              if (value != null) {
                await widget.accessibilityManager.setColorBlindType(value);
                widget.onSettingsChanged?.call();
                setState(() {});
              }
            },
          )),
        ],
      ),
    );
  }

  Widget _buildColorPreview() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: AccessibilityDecorations(widget.accessibilityManager)
          .getNeonBorder(_accessibilityTheme.colors.electricBlue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color Preview',
            style: _accessibilityTheme.textStyles.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildColorSwatch('Success', _accessibilityTheme.colors.colorBlindFriendly.success),
              _buildColorSwatch('Warning', _accessibilityTheme.colors.colorBlindFriendly.warning),
              _buildColorSwatch('Danger', _accessibilityTheme.colors.colorBlindFriendly.danger),
              _buildColorSwatch('Info', _accessibilityTheme.colors.colorBlindFriendly.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: _accessibilityTheme.textStyles.body.copyWith(fontSize: 10),
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
            await widget.settingsManager.setSoundBasedFeedback(value);
            widget.onSettingsChanged?.call();
            
            if (value) {
              await widget.accessibilityManager.playSoundFeedback(
                SoundFeedbackType.scoreIncrement,
              );
            }
            
            setState(() {});
          },
        ),
        if (widget.accessibilityManager.soundBasedFeedback)
          _buildInfoCard(
            'Audio cues will play for obstacles, power-ups, and score changes',
            Icons.volume_up,
            _accessibilityTheme.colors.colorBlindFriendly.info,
          ),
      ],
    );
  }

  Widget _buildScalingSettings() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AccessibilityDecorations(widget.accessibilityManager)
              .getNeonBorder(_accessibilityTheme.colors.electricBlue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UI Scale: ${(widget.accessibilityManager.uiScale * 100).round()}%',
                style: _accessibilityTheme.textStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Slider(
                value: widget.accessibilityManager.uiScale,
                min: 0.8,
                max: 1.5,
                divisions: 14,
                activeColor: _accessibilityTheme.colors.electricBlue,
                inactiveColor: _accessibilityTheme.colors.electricBlue.withOpacity(0.3),
                onChanged: (value) async {
                  await widget.accessibilityManager.setUiScale(value);
                  await widget.settingsManager.setUiScale(value);
                  widget.onSettingsChanged?.call();
                  setState(() {
                    _accessibilityTheme = AccessibilityTheme(widget.accessibilityManager);
                  });
                },
              ),
              Text(
                'Adjust the size of UI elements',
                style: _accessibilityTheme.textStyles.body.copyWith(
                  fontSize: 12,
                  color: _accessibilityTheme.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AccessibilityDecorations(widget.accessibilityManager)
          .getButtonDecoration(_accessibilityTheme.colors.electricBlue),
      child: SwitchListTile(
        title: Text(
          title,
          style: _accessibilityTheme.textStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: enabled ? null : _accessibilityTheme.colors.textSecondary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: _accessibilityTheme.textStyles.body.copyWith(
            fontSize: 12,
            color: enabled 
                ? _accessibilityTheme.colors.textSecondary 
                : _accessibilityTheme.colors.textSecondary.withOpacity(0.5),
          ),
        ),
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: _accessibilityTheme.colors.electricBlue,
        activeTrackColor: _accessibilityTheme.colors.electricBlue.withOpacity(0.3),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withOpacity(0.3),
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
              style: _accessibilityTheme.textStyles.body.copyWith(
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