import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/audio_settings.dart';
import '../components/graphics_settings.dart';
import '../components/difficulty_settings.dart';
import '../components/control_settings.dart';
import '../components/accessibility_settings.dart';
import '../theme/neon_theme.dart';
import '../../game/managers/audio_manager.dart';
import '../../game/managers/settings_manager.dart';
import '../../game/managers/accessibility_manager.dart';
import '../../game/managers/haptic_manager.dart';
import '../../game/utils/performance_monitor.dart';
import '../../providers/authentication_provider.dart';

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
                    _buildAccountTab(),
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
            icon: Icon(Icons.account_circle, size: 20),
            text: 'Account',
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
          ? AudioSettings(
              audioManager: widget.audioManager!,
              onSettingsChanged: () async {
                // Synchronize SettingsManager with AudioManager when audio settings change
                await _settingsManager.setMusicEnabled(widget.audioManager!.isMusicEnabled);
                await _settingsManager.setSfxEnabled(widget.audioManager!.isSfxEnabled);
                await _settingsManager.setMusicVolume(widget.audioManager!.musicVolume);
                await _settingsManager.setSfxVolume(widget.audioManager!.sfxVolume);
                
                // Notify game of settings change
                widget.onSettingsChanged?.call();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Audio settings updated'),
                    backgroundColor: NeonTheme.electricBlue,
                  ),
                );
              },
            )
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

  Widget _buildAccountTab() {
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Info Section
              _buildAccountInfoSection(authProvider),
              
              const SizedBox(height: 30),
              
              // Account Actions Section
              _buildAccountActionsSection(authProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountInfoSection(AuthenticationProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeonTheme.darkPurple.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: NeonTheme.electricBlue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle,
                size: 32,
                color: NeonTheme.electricBlue,
              ),
              const SizedBox(width: 12),
              Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: NeonTheme.electricBlue,
                  shadows: NeonTheme.getNeonGlow(NeonTheme.electricBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // User Status
          _buildInfoRow(
            'Status',
            authProvider.isAuthenticated 
              ? (authProvider.isGuest ? 'Guest Player' : 'Authenticated')
              : 'Not Signed In',
            authProvider.isAuthenticated 
              ? (authProvider.isGuest ? NeonTheme.warningOrange : NeonTheme.neonGreen)
              : NeonTheme.warningOrange,
          ),
          
          if (authProvider.isAuthenticated) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Display Name',
              authProvider.getUserDisplayName(),
              NeonTheme.white,
            ),
            
            const SizedBox(height: 12),
            _buildInfoRow(
              'Best Score',
              authProvider.getUserBestScore().toString(),
              NeonTheme.hotPink,
            ),
            
            const SizedBox(height: 12),
            _buildInfoRow(
              'Games Played',
              authProvider.getUserTotalGames().toString(),
              NeonTheme.neonGreen,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: NeonTheme.white.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountActionsSection(AuthenticationProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeonTheme.darkPurple.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: NeonTheme.hotPink.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                size: 32,
                color: NeonTheme.hotPink,
              ),
              const SizedBox(width: 12),
              Text(
                'Account Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: NeonTheme.hotPink,
                  shadows: NeonTheme.getNeonGlow(NeonTheme.hotPink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (authProvider.isAuthenticated) ...[
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: authProvider.isLoading ? null : () => _handleLogout(authProvider),
                icon: authProvider.isLoading 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(NeonTheme.white),
                      ),
                    )
                  : Icon(Icons.logout, color: NeonTheme.white),
                label: Text(
                  authProvider.isLoading ? 'Signing Out...' : 'Sign Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NeonTheme.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeonTheme.warningOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: NeonTheme.warningOrange.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            
            if (authProvider.isGuest) ...[
              const SizedBox(height: 16),
              // Upgrade Account Button for Guest Users
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: authProvider.isLoading ? null : () => _handleUpgradeAccount(authProvider),
                  icon: Icon(Icons.upgrade, color: NeonTheme.white),
                  label: Text(
                    'Upgrade to Google Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: NeonTheme.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NeonTheme.neonGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: NeonTheme.neonGreen.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ] else ...[
            // Sign In Options for Non-Authenticated Users
            Text(
              'Sign in to save your progress and compete on leaderboards!',
              style: TextStyle(
                fontSize: 16,
                color: NeonTheme.white.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/authentication'),
                icon: Icon(Icons.login, color: NeonTheme.white),
                label: Text(
                  'Go to Sign In',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NeonTheme.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeonTheme.electricBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: NeonTheme.electricBlue.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
          
          // Temporary Notice
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NeonTheme.warningOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: NeonTheme.warningOrange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: NeonTheme.warningOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Note: This is a temporary location for account actions. These will be moved to a dedicated user profile screen in a future update.',
                    style: TextStyle(
                      fontSize: 12,
                      color: NeonTheme.warningOrange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(AuthenticationProvider authProvider) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeonTheme.darkPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: NeonTheme.warningOrange.withOpacity(0.5),
            width: 2,
          ),
        ),
        title: Text(
          'Confirm Sign Out',
          style: TextStyle(
            color: NeonTheme.warningOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out? You will lose access to your saved progress and leaderboard data.',
          style: TextStyle(
            color: NeonTheme.white.withOpacity(0.9),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: NeonTheme.white.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: NeonTheme.warningOrange,
            ),
            child: Text(
              'Sign Out',
              style: TextStyle(color: NeonTheme.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await authProvider.signOut();
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Successfully signed out'),
              backgroundColor: NeonTheme.neonGreen,
            ),
          );
          
          // Navigate back to main menu or authentication screen
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/main_menu',
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.getFormattedErrorMessage()),
              backgroundColor: NeonTheme.warningOrange,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleUpgradeAccount(AuthenticationProvider authProvider) async {
    final success = await authProvider.upgradeGuestToGoogle();
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account upgraded successfully!'),
            backgroundColor: NeonTheme.neonGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.getFormattedErrorMessage()),
            backgroundColor: NeonTheme.warningOrange,
          ),
        );
      }
    }
  }
}