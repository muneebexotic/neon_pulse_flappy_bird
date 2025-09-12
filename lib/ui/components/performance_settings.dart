import 'package:flutter/material.dart';
import '../../game/managers/settings_manager.dart';
import '../../game/utils/performance_monitor.dart';
import '../theme/neon_theme.dart';

/// Performance monitoring and debug settings widget
class PerformanceSettings extends StatefulWidget {
  final SettingsManager settingsManager;
  final PerformanceMonitor performanceMonitor;
  final Function(bool)? onPerformanceMonitorToggled;
  
  const PerformanceSettings({
    super.key,
    required this.settingsManager,
    required this.performanceMonitor,
    this.onPerformanceMonitorToggled,
  });

  @override
  State<PerformanceSettings> createState() => _PerformanceSettingsState();
}

class _PerformanceSettingsState extends State<PerformanceSettings> {
  bool _showDetailedStats = false;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Text(
                'Performance & Debug',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: NeonTheme.electricBlue,
                  shadows: NeonTheme.getNeonGlow(NeonTheme.electricBlue),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showDetailedStats = !_showDetailedStats),
                icon: Icon(
                  _showDetailedStats ? Icons.expand_less : Icons.expand_more,
                  color: NeonTheme.neonGreen,
                ),
                tooltip: 'Toggle Detailed Stats',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Performance Monitor Toggle
          _buildPerformanceMonitorToggle(),
          const SizedBox(height: 20),

          // Current Performance Stats
          _buildCurrentPerformanceStats(),
          
          if (_showDetailedStats) ...[
            const SizedBox(height: 20),
            _buildDetailedStats(),
          ],
          
          const SizedBox(height: 20),
          
          // Performance Tips
          _buildPerformanceTips(),
        ],
      ),
    );
  }

  Widget _buildPerformanceMonitorToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonTheme.charcoal.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.settingsManager.performanceMonitorEnabled 
            ? NeonTheme.neonGreen.withOpacity(0.5)
            : NeonTheme.charcoal.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.settingsManager.performanceMonitorEnabled 
                ? NeonTheme.neonGreen.withOpacity(0.2)
                : NeonTheme.charcoal.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.speed,
              color: widget.settingsManager.performanceMonitorEnabled 
                ? NeonTheme.neonGreen
                : NeonTheme.white.withOpacity(0.5),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Monitor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: NeonTheme.white,
                  ),
                ),
                Text(
                  'Show FPS and performance info during gameplay',
                  style: TextStyle(
                    fontSize: 12,
                    color: NeonTheme.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: widget.settingsManager.performanceMonitorEnabled,
            onChanged: (value) async {
              await widget.settingsManager.setPerformanceMonitorEnabled(value);
              widget.onPerformanceMonitorToggled?.call(value);
              setState(() {});
            },
            activeColor: NeonTheme.neonGreen,
            activeTrackColor: NeonTheme.neonGreen.withOpacity(0.3),
            inactiveThumbColor: NeonTheme.charcoal,
            inactiveTrackColor: NeonTheme.charcoal.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPerformanceStats() {
    final stats = widget.performanceMonitor.getStats();
    final fps = double.tryParse(stats['averageFps']) ?? 0.0;
    final frameTime = double.tryParse(stats['frameTimeMs']) ?? 0.0;
    final quality = double.tryParse(stats['quality']) ?? 0.0;
    final isGood = stats['performanceGood'] as bool;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonTheme.deepSpace.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isGood 
            ? NeonTheme.neonGreen.withOpacity(0.5)
            : NeonTheme.warningOrange.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGood ? Icons.check_circle : Icons.warning,
                color: isGood ? NeonTheme.neonGreen : NeonTheme.warningOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Performance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isGood ? NeonTheme.neonGreen : NeonTheme.warningOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'FPS',
                  fps.toStringAsFixed(1),
                  _getFpsColor(fps),
                  Icons.speed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Frame Time',
                  '${frameTime.toStringAsFixed(1)}ms',
                  NeonTheme.electricBlue,
                  Icons.timer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Quality',
                  '${(quality * 100).toInt()}%',
                  NeonTheme.hotPink,
                  Icons.auto_awesome,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Performance bar
          LinearProgressIndicator(
            value: quality,
            backgroundColor: NeonTheme.charcoal,
            valueColor: AlwaysStoppedAnimation<Color>(_getFpsColor(fps)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: NeonTheme.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    final stats = widget.performanceMonitor.getStats();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonTheme.charcoal.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: NeonTheme.electricBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: NeonTheme.electricBlue,
            ),
          ),
          const SizedBox(height: 12),
          
          ...stats.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatStatKey(entry.key),
                  style: TextStyle(
                    fontSize: 14,
                    color: NeonTheme.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  entry.value.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: NeonTheme.neonGreen,
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  widget.performanceMonitor.reset();
                  setState(() {});
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset Stats'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeonTheme.charcoal,
                  foregroundColor: NeonTheme.neonGreen,
                  side: BorderSide(
                    color: NeonTheme.neonGreen.withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonTheme.warningOrange.withOpacity(0.1),
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
                Icons.lightbulb_outline,
                color: NeonTheme.warningOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Performance Tips',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: NeonTheme.warningOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildTipItem(
            'If FPS drops below 45, try reducing graphics or particle quality',
            Icons.trending_down,
          ),
          _buildTipItem(
            'Enable auto quality adjustment for optimal performance',
            Icons.auto_fix_high,
          ),
          _buildTipItem(
            'Close other apps to free up memory and improve performance',
            Icons.memory,
          ),
          _buildTipItem(
            'Performance monitor adds slight overhead - disable when not needed',
            Icons.info_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: NeonTheme.warningOrange.withOpacity(0.7),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 12,
                color: NeonTheme.white.withOpacity(0.8),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getFpsColor(double fps) {
    if (fps >= 55) return NeonTheme.neonGreen;
    if (fps >= 45) return NeonTheme.warningOrange;
    return Colors.red;
  }

  String _formatStatKey(String key) {
    switch (key) {
      case 'averageFps':
        return 'Average FPS';
      case 'frameTimeMs':
        return 'Frame Time (ms)';
      case 'frameCount':
        return 'Total Frames';
      case 'performanceGood':
        return 'Performance Good';
      case 'quality':
        return 'Quality Score';
      default:
        return key;
    }
  }
}