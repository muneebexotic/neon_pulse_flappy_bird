import 'package:flutter/material.dart';
import '../../game/managers/settings_manager.dart';
import '../theme/neon_theme.dart';

/// Control customization settings widget
class ControlSettings extends StatefulWidget {
  final SettingsManager settingsManager;
  final Function(double)? onTapSensitivityChanged;
  final Function(double)? onDoubleTapTimingChanged;
  
  const ControlSettings({
    super.key,
    required this.settingsManager,
    this.onTapSensitivityChanged,
    this.onDoubleTapTimingChanged,
  });

  @override
  State<ControlSettings> createState() => _ControlSettingsState();
}

class _ControlSettingsState extends State<ControlSettings> {
  late double _tapSensitivity;
  late double _doubleTapTiming;
  bool _showTestArea = false;
  int _tapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _tapSensitivity = widget.settingsManager.tapSensitivity;
    _doubleTapTiming = widget.settingsManager.doubleTapTiming;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeonTheme.darkPurple.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: NeonTheme.hotPink.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: NeonTheme.hotPink.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Text(
                'Control Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: NeonTheme.hotPink,
                  shadows: NeonTheme.getNeonGlow(NeonTheme.hotPink),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showTestArea = !_showTestArea),
                icon: Icon(
                  _showTestArea ? Icons.touch_app_outlined : Icons.touch_app,
                  color: NeonTheme.electricBlue,
                ),
                tooltip: 'Toggle Test Area',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tap Sensitivity
          _buildTapSensitivitySlider(),
          const SizedBox(height: 25),

          // Double-tap Timing
          _buildDoubleTapTimingSlider(),
          const SizedBox(height: 25),

          // Test Area
          if (_showTestArea) ...[
            _buildTestArea(),
            const SizedBox(height: 20),
          ],

          // Control Guide
          _buildControlGuide(),
        ],
      ),
    );
  }

  Widget _buildTapSensitivitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tap Sensitivity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: NeonTheme.electricBlue,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: NeonTheme.electricBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: NeonTheme.electricBlue.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                '${(_tapSensitivity * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: NeonTheme.electricBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        Text(
          _getSensitivityDescription(_tapSensitivity),
          style: TextStyle(
            fontSize: 14,
            color: NeonTheme.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: NeonTheme.electricBlue,
            inactiveTrackColor: NeonTheme.charcoal,
            thumbColor: NeonTheme.hotPink,
            overlayColor: NeonTheme.hotPink.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 6,
          ),
          child: Slider(
            value: _tapSensitivity,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: (value) {
              setState(() => _tapSensitivity = value);
            },
            onChangeEnd: (value) async {
              await widget.settingsManager.setTapSensitivity(value);
              widget.onTapSensitivityChanged?.call(value);
            },
          ),
        ),
        
        // Sensitivity markers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMarkerText('Gentle', NeonTheme.neonGreen),
            _buildMarkerText('Normal', NeonTheme.electricBlue),
            _buildMarkerText('Responsive', NeonTheme.warningOrange),
          ],
        ),
      ],
    );
  }

  Widget _buildDoubleTapTimingSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Double-tap Timing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: NeonTheme.neonGreen,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: NeonTheme.neonGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: NeonTheme.neonGreen.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                '${_doubleTapTiming.toInt()}ms',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: NeonTheme.neonGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        Text(
          _getTimingDescription(_doubleTapTiming),
          style: TextStyle(
            fontSize: 14,
            color: NeonTheme.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: NeonTheme.neonGreen,
            inactiveTrackColor: NeonTheme.charcoal,
            thumbColor: NeonTheme.hotPink,
            overlayColor: NeonTheme.hotPink.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 6,
          ),
          child: Slider(
            value: _doubleTapTiming,
            min: 200.0,
            max: 500.0,
            divisions: 15,
            onChanged: (value) {
              setState(() => _doubleTapTiming = value);
            },
            onChangeEnd: (value) async {
              await widget.settingsManager.setDoubleTapTiming(value);
              widget.onDoubleTapTimingChanged?.call(value);
            },
          ),
        ),
        
        // Timing markers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMarkerText('Fast', NeonTheme.warningOrange),
            _buildMarkerText('Normal', NeonTheme.electricBlue),
            _buildMarkerText('Slow', NeonTheme.neonGreen),
          ],
        ),
      ],
    );
  }

  Widget _buildMarkerText(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: color.withOpacity(0.8),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTestArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeonTheme.deepSpace.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NeonTheme.electricBlue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Test Your Controls',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: NeonTheme.electricBlue,
            ),
          ),
          const SizedBox(height: 15),
          
          GestureDetector(
            onTap: _handleTestTap,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: NeonTheme.hotPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: NeonTheme.hotPink.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 32,
                      color: NeonTheme.hotPink,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap here to test',
                      style: TextStyle(
                        fontSize: 16,
                        color: NeonTheme.hotPink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Taps: $_tapCount',
                      style: TextStyle(
                        fontSize: 14,
                        color: NeonTheme.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 15),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() => _tapCount = 0),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeonTheme.charcoal,
                  foregroundColor: NeonTheme.neonGreen,
                  side: BorderSide(
                    color: NeonTheme.neonGreen.withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
              Text(
                'Try single and double taps',
                style: TextStyle(
                  fontSize: 12,
                  color: NeonTheme.white.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonTheme.charcoal.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: NeonTheme.warningOrange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: NeonTheme.warningOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Control Guide',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: NeonTheme.warningOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildGuideItem(
            Icons.touch_app,
            'Single Tap',
            'Make the bird jump upward',
            NeonTheme.electricBlue,
          ),
          const SizedBox(height: 8),
          
          _buildGuideItem(
            Icons.double_arrow,
            'Double Tap',
            'Activate energy pulse to disable obstacles',
            NeonTheme.hotPink,
          ),
          const SizedBox(height: 12),
          
          Text(
            'Tip: Adjust sensitivity based on your device and playing style. Higher sensitivity means lighter taps are registered.',
            style: TextStyle(
              fontSize: 12,
              color: NeonTheme.white.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(IconData icon, String title, String description, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: NeonTheme.white,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: NeonTheme.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getSensitivityDescription(double sensitivity) {
    if (sensitivity < 0.8) return 'Gentle taps required - good for precise control';
    if (sensitivity > 1.3) return 'Light taps registered - good for quick reactions';
    return 'Balanced sensitivity - standard tap pressure';
  }

  String _getTimingDescription(double timing) {
    if (timing < 250) return 'Fast double-tap detection - requires quick taps';
    if (timing > 400) return 'Slow double-tap detection - more forgiving timing';
    return 'Standard double-tap timing - balanced detection';
  }

  void _handleTestTap() {
    final now = DateTime.now();
    
    if (_lastTapTime != null) {
      final timeDiff = now.difference(_lastTapTime!).inMilliseconds;
      if (timeDiff <= _doubleTapTiming) {
        // Double tap detected
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Double-tap detected! (${timeDiff}ms)'),
            backgroundColor: NeonTheme.hotPink,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
    
    setState(() {
      _tapCount++;
      _lastTapTime = now;
    });
  }
}