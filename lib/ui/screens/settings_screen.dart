import 'package:flutter/material.dart';
import '../components/audio_settings.dart';
import '../components/graphics_settings.dart';
import '../components/difficulty_settings.dart';
import '../components/control_settings.dart';
import '../components/performance_settings.dart';
import '../components/accessibility_settings.dart';
import '../theme/neon_theme.dart';
import '../../game/managers/audio_manager.dart';
import '../../game/managers/settings_manager.dart';
import '../../game/managers/accessibility_manager.dart';
import '../../game/managers/haptic_manager.dart';
import '../../game/utils/performance_monitor.dart';

/// Enhanced settings screen with comprehensive game settings
class SettingsScreen extends StatefulWidget {
  final AudioManager? audioManager;
  final SettingsManager? settingsManager;
  final PerformanceMonitor? performanceMonitor;
  final AccessibilityManager? accessibilityManager;
  final HapticManager? hapticManager;
  final VoidCallback? onSettingsChanged;
  
  const SettingsScreen({
    super.key,
    this.audioManager,
    this.settingsManager,
    this.performanceMonitor,
    this.accessibilityManager,
    this.hapticManager,
    this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late SettingsManager _settingsManager;
  late PerformanceMonitor _performanceMonitor;
  late AccessibilityManager _accessibilityManager;
  late HapticManager _hapticManager;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _settingsManager = widget.settingsManager ?? SettingsManager();
    _performanceMonitor = widget.performanceMonitor ?? PerformanceMonitor();
    _accessibilityManager = widget.accessibilityManager ?? AccessibilityManager();
    _hapticManager = widget.hapticManager ?? HapticManager();
    
    // Initialize managers if not provided
    if (widget.settingsManager == null) {
      _settingsManager.initialize();
    }
    if (widget.accessibilityManager == null) {
      _accessibilityManager.initialize(audioManager: widget.audioManager);
    }
    if (widget.hapticManager == null) {
      _hapticManager.initialize();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0B1F), // Deep space
              Color(0xFF1A0B2E), // Dark purple
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              
              // Tab Bar
              _buildTabBar(),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGraphicsTab(),
                    _buildGameplayTab(),
                    _buildControlsTab(),
                    _buildAudioTab(),
                    _buildAccessibilityTab(),
                    _buildPerformanceTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: NeonTheme.electricBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'SETTINGS',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: NeonTheme.electricBlue,
              letterSpacing: 3,
              shadows: NeonTheme.getNeonGlow(NeonTheme.electricBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: NeonTheme.charcoal.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NeonTheme.electricBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: NeonTheme.electricBlue,
        indicatorWeight: 3,
        labelColor: NeonTheme.electricBlue,
        unselectedLabelColor: NeonTheme.white.withOpacity(0.6),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.auto_awesome, size: 20),
            text: 'Graphics',
          ),
          Tab(
            icon: Icon(Icons.gamepad, size: 20),
            text: 'Gameplay',
          ),
          Tab(
            icon: Icon(Icons.touch_app, size: 20),
            text: 'Controls',
          ),
          Tab(
            icon: Icon(Icons.volume_up, size: 20),
            text: 'Audio',
          ),
          Tab(
            icon: Icon(Icons.accessibility, size: 20),
            text: 'Accessibility',
          ),
          Tab(
            icon: Icon(Icons.speed, size: 20),
            text: 'Performance',
          ),
        ],
      ),
    );
  }

  Widget _buildGraphicsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: GraphicsSettings(
        settingsManager: _settingsManager,
        performanceMonitor: _performanceMonitor,
        onGraphicsQualityChanged: (quality) {
          // Notify game of settings change
          widget.onSettingsChanged?.call();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Graphics quality set to ${quality.displayName}'),
              backgroundColor: NeonTheme.neonGreen,
            ),
          );
        },
        onParticleQualityChanged: (quality) {
          // Notify game of settings change
          widget.onSettingsChanged?.call();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Particle quality set to ${quality.displayName}'),
              backgroundColor: NeonTheme.hotPink,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameplayTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: DifficultySettings(
        settingsManager: _settingsManager,
        onDifficultyChanged: (difficulty) {
          // Notify game of settings change
          widget.onSettingsChanged?.call();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Difficulty set to ${difficulty.displayName}'),
              backgroundColor: NeonTheme.warningOrange,
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ControlSettings(
        settingsManager: _settingsManager,
        onTapSensitivityChanged: (sensitivity) {
          // Notify game of settings change
          widget.onSettingsChanged?.call();
        },
        onDoubleTapTimingChanged: (timing) {
          // Notify game of settings change
          widget.onSettingsChanged?.call();
        },
      ),
    );
  }

  Widget _buildAudioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: widget.audioManager != null
          ? AudioSettings(audioManager: widget.audioManager!)
          : _buildAudioUnavailable(),
    );
  }

  Widget _buildAccessibilityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: AccessibilitySettings(
        accessibilityManager: _accessibilityManager,
        hapticManager: _hapticManager,
        settingsManager: _settingsManager,
        onSettingsChanged: () {
          widget.onSettingsChanged?.call();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Accessibility settings updated'),
              backgroundColor: NeonTheme.neonGreen,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: PerformanceSettings(
        settingsManager: _settingsManager,
        performanceMonitor: _performanceMonitor,
        onPerformanceMonitorToggled: (enabled) {
          // Notify game of settings change
          widget.onSettingsChanged?.call();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                enabled 
                  ? 'Performance monitor enabled' 
                  : 'Performance monitor disabled'
              ),
              backgroundColor: NeonTheme.electricBlue,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAudioUnavailable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeonTheme.darkPurple.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: NeonTheme.warningOrange.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.volume_off,
            size: 48,
            color: NeonTheme.warningOrange,
          ),
          const SizedBox(height: 16),
          Text(
            'Audio Unavailable',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: NeonTheme.warningOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Audio manager not initialized',
            style: TextStyle(
              fontSize: 16,
              color: NeonTheme.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }


}