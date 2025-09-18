import 'package:flutter/material.dart';
import '../../game/managers/audio_manager.dart';
import '../theme/neon_theme.dart';
import 'neon_slider.dart';

/// Audio settings widget for controlling music, sound effects, and beat sync
class AudioSettings extends StatefulWidget {
  final AudioManager audioManager;
  final VoidCallback? onSettingsChanged;
  
  const AudioSettings({
    super.key,
    required this.audioManager,
    this.onSettingsChanged,
  });

  @override
  State<AudioSettings> createState() => _AudioSettingsState();
}

class _AudioSettingsState extends State<AudioSettings> {
  late double _musicVolume;
  late double _sfxVolume;
  late bool _isMusicEnabled;
  late bool _isSfxEnabled;
  late bool _beatDetectionEnabled;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    _musicVolume = widget.audioManager.musicVolume;
    _sfxVolume = widget.audioManager.sfxVolume;
    _isMusicEnabled = widget.audioManager.isMusicEnabled;
    _isSfxEnabled = widget.audioManager.isSfxEnabled;
    _beatDetectionEnabled = widget.audioManager.beatDetectionEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeonTheme.darkPurple.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: NeonTheme.electricBlue.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: NeonTheme.electricBlue.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Audio Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: NeonTheme.electricBlue,
              shadows: [
                Shadow(
                  color: NeonTheme.electricBlue.withOpacity(0.8),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Music Controls
          _buildSectionTitle('Music'),
          _buildToggleRow(
            'Enable Music',
            _isMusicEnabled,
            (value) async {
              setState(() => _isMusicEnabled = value);
              await widget.audioManager.toggleMusic();
              widget.onSettingsChanged?.call();
            },
          ),
          if (_isMusicEnabled) ...[
            const SizedBox(height: 10),
            _buildVolumeSlider(
              'Music Volume',
              _musicVolume,
              (value) async {
                setState(() => _musicVolume = value);
                await widget.audioManager.setMusicVolume(value);
              },
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Sound Effects Controls
          _buildSectionTitle('Sound Effects'),
          _buildToggleRow(
            'Enable Sound Effects',
            _isSfxEnabled,
            (value) async {
              setState(() => _isSfxEnabled = value);
              await widget.audioManager.toggleSfx();
              widget.onSettingsChanged?.call();
            },
          ),
          if (_isSfxEnabled) ...[
            const SizedBox(height: 10),
            _buildVolumeSlider(
              'SFX Volume',
              _sfxVolume,
              (value) async {
                setState(() => _sfxVolume = value);
                await widget.audioManager.setSfxVolume(value);
              },
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Beat Synchronization
          _buildSectionTitle('Beat Synchronization'),
          _buildToggleRow(
            'Enable Beat Sync',
            _beatDetectionEnabled,
            (value) async {
              setState(() => _beatDetectionEnabled = value);
              await widget.audioManager.toggleBeatDetection();
              widget.onSettingsChanged?.call();
            },
          ),
          if (_beatDetectionEnabled) ...[
            const SizedBox(height: 10),
            _buildInfoRow('Current BPM', '${widget.audioManager.currentBpm.toStringAsFixed(1)}'),
          ],
          
          const SizedBox(height: 20),
          
          // Test Buttons
          _buildSectionTitle('Test Audio'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTestButton('Jump', () => widget.audioManager.playSoundEffect(SoundEffect.jump)),
              _buildTestButton('Pulse', () => widget.audioManager.playSoundEffect(SoundEffect.pulse)),
              _buildTestButton('Score', () => widget.audioManager.playSoundEffect(SoundEffect.score)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: NeonTheme.hotPink,
          shadows: [
            Shadow(
              color: NeonTheme.hotPink.withOpacity(0.6),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: NeonTheme.neonGreen,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: NeonTheme.electricBlue,
          activeTrackColor: NeonTheme.electricBlue.withOpacity(0.3),
          inactiveThumbColor: NeonTheme.charcoal,
          inactiveTrackColor: NeonTheme.charcoal.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildVolumeSlider(String label, double value, Function(double) onChanged) {
    return NeonPercentageSlider(
      value: value,
      label: label,
      divisions: 20,
      onChanged: onChanged,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: NeonTheme.neonGreen.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: NeonTheme.electricBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildTestButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: NeonTheme.charcoal,
        foregroundColor: NeonTheme.neonGreen,
        side: BorderSide(
          color: NeonTheme.neonGreen.withOpacity(0.5),
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}