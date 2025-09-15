import 'package:flutter/material.dart';
import '../../game/neon_pulse_game.dart';
import '../../game/utils/performance_test_suite.dart';
import '../../game/utils/performance_monitor.dart';
import '../theme/neon_theme.dart';

/// Performance monitoring and testing screen
class PerformanceScreen extends StatefulWidget {
  final NeonPulseGame game;

  const PerformanceScreen({Key? key, required this.game}) : super(key: key);

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  PerformanceTestResults? _testResults;
  bool _isRunningTest = false;
  Map<String, dynamic>? _currentStats;

  @override
  void initState() {
    super.initState();
    _updateStats();
    
    // Update stats periodically
    Future.delayed(const Duration(seconds: 1), _updateStatsLoop);
  }

  void _updateStatsLoop() {
    if (mounted) {
      _updateStats();
      Future.delayed(const Duration(seconds: 1), _updateStatsLoop);
    }
  }

  void _updateStats() {
    if (mounted) {
      setState(() {
        _currentStats = widget.game.getPerformanceStats();
      });
    }
  }

  Future<void> _runPerformanceTest() async {
    setState(() {
      _isRunningTest = true;
    });

    try {
      final results = await widget.game.runPerformanceBenchmark();
      setState(() {
        _testResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Performance test failed: $e')),
      );
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }

  void _forceCleanup() {
    widget.game.forcePerformanceCleanup();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Performance cleanup completed')),
    );
    _updateStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Performance Monitor',
          style: NeonTheme.headingStyle,
        ),
        backgroundColor: NeonTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: NeonTheme.primaryNeon),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Real-time Performance Stats
            _buildStatsCard(),
            const SizedBox(height: 16),
            
            // Performance Test Section
            _buildTestCard(),
            const SizedBox(height: 16),
            
            // Test Results
            if (_testResults != null) _buildResultsCard(),
            
            // Actions
            const SizedBox(height: 16),
            _buildActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      color: NeonTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-time Performance',
              style: NeonTheme.headingStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            if (_currentStats != null) ...[
              _buildStatRow('FPS', _currentStats!['monitor']['averageFps'] ?? 'N/A'),
              _buildStatRow('Frame Time', '${_currentStats!['monitor']['frameTimeMs'] ?? 'N/A'} ms'),
              _buildStatRow('Performance Quality', _currentStats!['monitor']['quality'] ?? 'N/A'),
              _buildStatRow('Active Particles', _currentStats!['particleSystem']['activeParticles']?.toString() ?? 'N/A'),
              _buildStatRow('Pool Utilization', _currentStats!['particleSystem']['poolUtilization'] ?? 'N/A'),
              _buildStatRow('Adaptive Quality', _currentStats!['adaptiveQuality']['particleQuality'] ?? 'N/A'),
            ] else
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard() {
    return Card(
      color: NeonTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Benchmark',
              style: NeonTheme.headingStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text(
              'Run comprehensive performance tests to evaluate device capabilities.',
              style: NeonTheme.bodyStyle,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRunningTest ? null : _runPerformanceTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeonTheme.primaryNeon,
                  foregroundColor: NeonTheme.backgroundColor,
                ),
                child: _isRunningTest
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Running Tests...'),
                        ],
                      )
                    : const Text('Run Performance Test'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      color: NeonTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Results',
              style: NeonTheme.headingStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            _buildStatRow('Overall Score', _testResults!.overallScore.toStringAsFixed(2)),
            _buildStatRow('Device Class', _testResults!.deviceClass),
            const SizedBox(height: 12),
            Text(
              'Individual Tests:',
              style: NeonTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTestResult('CPU', _testResults!.cpuTest),
            _buildTestResult('Memory', _testResults!.memoryTest),
            _buildTestResult('Particles', _testResults!.particleTest),
            _buildTestResult('Pooling', _testResults!.poolingTest),
            _buildTestResult('Rendering', _testResults!.renderingTest),
            
            if (_testResults!.recommendations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Recommendations:',
                style: NeonTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._testResults!.recommendations.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${entry.key}: ${entry.value}',
                    style: NeonTheme.bodyStyle.copyWith(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      color: NeonTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Actions',
              style: NeonTheme.headingStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _forceCleanup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeonTheme.secondaryNeon,
                  foregroundColor: NeonTheme.backgroundColor,
                ),
                child: const Text('Force Memory Cleanup'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Toggle adaptive quality
                  final isEnabled = widget.game.adaptiveQualityManager.currentParticleQuality != QualityLevel.low;
                  if (isEnabled) {
                    widget.game.adaptiveQualityManager.forceQualityAdjustment(
                      particleQuality: QualityLevel.low,
                      graphicsQuality: QualityLevel.low,
                    );
                  } else {
                    widget.game.adaptiveQualityManager.forceQualityAdjustment(
                      particleQuality: QualityLevel.high,
                      graphicsQuality: QualityLevel.high,
                    );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Quality ${isEnabled ? 'reduced' : 'restored'}')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeonTheme.secondaryNeon,
                  foregroundColor: NeonTheme.backgroundColor,
                ),
                child: const Text('Toggle Quality Mode'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: NeonTheme.bodyStyle),
          Text(
            value,
            style: NeonTheme.bodyStyle.copyWith(
              color: NeonTheme.accentNeon,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResult(String name, TestResult result) {
    final color = result.score >= 0.7
        ? Colors.green
        : result.score >= 0.4
            ? Colors.orange
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: NeonTheme.bodyStyle.copyWith(fontSize: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color, width: 1),
            ),
            child: Text(
              result.score.toStringAsFixed(2),
              style: NeonTheme.bodyStyle.copyWith(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}