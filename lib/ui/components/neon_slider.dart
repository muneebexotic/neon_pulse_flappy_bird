import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// A reusable neon-styled slider component for consistent UI across all settings tabs
class NeonSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final Color? thumbColor;
  final double? thumbRadius;
  final double? trackHeight;
  final String? label;
  final String? valueDisplay;
  final bool showPercentage;
  final bool showValueLabel;

  const NeonSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.onChanged,
    this.onChangeEnd,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.thumbRadius,
    this.trackHeight,
    this.label,
    this.valueDisplay,
    this.showPercentage = false,
    this.showValueLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label and value display
        if (label != null || showValueLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 14,
                    color: NeonTheme.neonGreen.withOpacity(0.8),
                  ),
                ),
              if (showValueLabel)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (activeTrackColor ?? NeonTheme.electricBlue).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (activeTrackColor ?? NeonTheme.electricBlue).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    valueDisplay ?? _getDefaultValueDisplay(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: activeTrackColor ?? NeonTheme.electricBlue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: activeTrackColor ?? NeonTheme.electricBlue,
            inactiveTrackColor: inactiveTrackColor ?? NeonTheme.charcoal,
            thumbColor: thumbColor ?? NeonTheme.hotPink,
            overlayColor: (thumbColor ?? NeonTheme.hotPink).withOpacity(0.2),
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: thumbRadius ?? 10,
            ),
            trackHeight: trackHeight ?? 6,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }

  String _getDefaultValueDisplay() {
    if (showPercentage) {
      return '${((value - min) / (max - min) * 100).round()}%';
    }
    return value.toStringAsFixed(1);
  }
}

/// A specialized slider for percentage values (0.0 to 1.0)
class NeonPercentageSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String? label;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final Color? thumbColor;
  final int? divisions;

  const NeonPercentageSlider({
    super.key,
    required this.value,
    this.onChanged,
    this.onChangeEnd,
    this.label,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.divisions = 20,
  });

  @override
  Widget build(BuildContext context) {
    return NeonSlider(
      value: value,
      min: 0.0,
      max: 1.0,
      divisions: divisions,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      label: label,
      showPercentage: true,
      activeTrackColor: activeTrackColor,
      inactiveTrackColor: inactiveTrackColor,
      thumbColor: thumbColor,
    );
  }
}

/// A specialized slider for intensity values with test button
class NeonIntensitySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final VoidCallback? onTest;
  final String title;
  final String subtitle;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final Color? thumbColor;

  const NeonIntensitySlider({
    super.key,
    required this.value,
    required this.title,
    required this.subtitle,
    this.onChanged,
    this.onChangeEnd,
    this.onTest,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.thumbColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonTheme.charcoal.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (activeTrackColor ?? NeonTheme.electricBlue).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: activeTrackColor ?? NeonTheme.electricBlue,
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
              if (onTest != null)
                IconButton(
                  onPressed: onTest,
                  icon: Icon(
                    Icons.play_arrow,
                    color: activeTrackColor ?? NeonTheme.electricBlue,
                  ),
                  tooltip: 'Test $title',
                ),
            ],
          ),
          const SizedBox(height: 12),
          NeonPercentageSlider(
            value: value,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
            activeTrackColor: activeTrackColor,
            inactiveTrackColor: inactiveTrackColor,
            thumbColor: thumbColor,
          ),
        ],
      ),
    );
  }
}

