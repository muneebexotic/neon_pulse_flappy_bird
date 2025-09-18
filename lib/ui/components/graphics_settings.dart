import 'package:flutter/material.dart';
import '../../game/managers/settings_manager.dart';
import '../theme/neon_theme.dart';
import 'neon_container.dart';

/// Graphics settings widget with real-time preview
class GraphicsSettings extends StatefulWidget {
  final SettingsManager settingsManager;
  final Function(GraphicsQuality)? onGraphicsQualityChanged;
  final Function(ParticleQuality)? onParticleQualityChanged;
  
  const GraphicsSettings({
    super.key,
    required this.settingsManager,
    this.onGraphicsQualityChanged,
    this.onParticleQualityChanged,
  });

  @override
  State<GraphicsSettings> createState() => _GraphicsSettingsState();
}

class _GraphicsSettingsState extends State<GraphicsSettings> {
  late GraphicsQuality _selectedGraphicsQuality;
  late ParticleQuality _selectedParticleQuality;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _selectedGraphicsQuality = widget.settingsManager.graphicsQuality;
    _selectedParticleQuality = widget.settingsManager.particleQuality;
  }

  @override
  Widget build(BuildContext context) {
    return NeonContainer.settings(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graphics Quality Selection
          _buildSectionTitle('Graphics Quality'),
          const SizedBox(height: 20),
          _buildGraphicsQualitySelector(),
          const SizedBox(height: 20),

          // Particle Quality Selection
          _buildSectionTitle('Particle Effects'),
          _buildParticleQualitySlider(),
          const SizedBox(height: 20),

          // Preview Section
          if (_showPreview) ...[
            _buildSectionTitle('Preview'),
            _buildPreviewSection(),
            const SizedBox(height: 20),
          ],

          // Auto-adjustment toggle
          _buildAutoAdjustmentToggle(),
        ],
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: NeonTheme.hotPink,
        shadows: NeonTheme.getNeonGlow(NeonTheme.hotPink),
      ),
    );
  }

  Widget _buildGraphicsQualitySelector() {
    return Column(
      children: GraphicsQuality.values.map((quality) {
        final isSelected = quality == _selectedGraphicsQuality;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _selectGraphicsQuality(quality),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                  ? NeonTheme.electricBlue.withOpacity(0.2)
                  : NeonTheme.charcoal.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected 
                    ? NeonTheme.electricBlue
                    : NeonTheme.charcoal.withOpacity(0.5),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<GraphicsQuality>(
                    value: quality,
                    groupValue: _selectedGraphicsQuality,
                    onChanged: (value) => _selectGraphicsQuality(value!),
                    activeColor: NeonTheme.electricBlue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quality.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? NeonTheme.electricBlue : NeonTheme.white,
                          ),
                        ),
                        Text(
                          quality.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: NeonTheme.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildParticleQualitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedParticleQuality.displayName} (${_selectedParticleQuality.maxParticles} particles)',
              style: TextStyle(
                fontSize: 14,
                color: NeonTheme.electricBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _selectedParticleQuality.description,
              style: TextStyle(
                fontSize: 12,
                color: NeonTheme.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: NeonTheme.hotPink,
            inactiveTrackColor: NeonTheme.charcoal,
            thumbColor: NeonTheme.electricBlue,
            overlayColor: NeonTheme.electricBlue.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 6,
          ),
          child: Slider(
            value: _selectedParticleQuality.index.toDouble(),
            min: 0,
            max: ParticleQuality.values.length - 1.0,
            divisions: ParticleQuality.values.length - 1,
            onChanged: (value) {
              final newQuality = ParticleQuality.values[value.toInt()];
              _selectParticleQuality(newQuality);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: NeonTheme.deepSpace,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: NeonTheme.electricBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 40,
              color: NeonTheme.hotPink,
            ),
            const SizedBox(height: 8),
            Text(
              'Graphics Preview',
              style: TextStyle(
                fontSize: 16,
                color: NeonTheme.electricBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Quality: ${_selectedGraphicsQuality.displayName}',
              style: TextStyle(
                fontSize: 12,
                color: NeonTheme.white.withOpacity(0.7),
              ),
            ),
            Text(
              'Particles: ${_selectedParticleQuality.displayName}',
              style: TextStyle(
                fontSize: 12,
                color: NeonTheme.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoAdjustmentToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auto Quality Adjustment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: NeonTheme.white,
                ),
              ),
              Text(
                'Automatically adjust quality based on performance',
                style: TextStyle(
                  fontSize: 12,
                  color: NeonTheme.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: widget.settingsManager.autoQualityAdjustment,
          onChanged: (value) async {
            await widget.settingsManager.setAutoQualityAdjustment(value);
            setState(() {});
          },
          activeColor: NeonTheme.neonGreen,
          activeTrackColor: NeonTheme.neonGreen.withOpacity(0.3),
          inactiveThumbColor: NeonTheme.charcoal,
          inactiveTrackColor: NeonTheme.charcoal.withOpacity(0.3),
        ),
      ],
    );
  }

  void _selectGraphicsQuality(GraphicsQuality quality) async {
    setState(() => _selectedGraphicsQuality = quality);
    await widget.settingsManager.setGraphicsQuality(quality);
    widget.onGraphicsQualityChanged?.call(quality);
  }

  void _selectParticleQuality(ParticleQuality quality) async {
    setState(() => _selectedParticleQuality = quality);
    await widget.settingsManager.setParticleQuality(quality);
    widget.onParticleQualityChanged?.call(quality);
  }
}