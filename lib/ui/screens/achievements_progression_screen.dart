import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../models/achievement.dart';
import '../../models/bird_skin.dart';
import '../../models/progression_path_models.dart';
import '../../game/managers/achievement_manager.dart';
import '../../game/managers/adaptive_quality_manager.dart';
import '../../game/managers/haptic_manager.dart';
import '../../game/components/cyberpunk_background.dart';
import '../../game/effects/particle_system.dart';
import '../../controllers/progression_integration_controller.dart';
import '../../controllers/progression_path_controller.dart';
import '../../controllers/progression_scroll_controller.dart';
import '../../controllers/scan_line_animation_controller.dart';
import '../../controllers/progression_performance_controller.dart';
import '../painters/path_renderer.dart';
import '../widgets/achievement_node.dart';
import '../components/achievement_detail_overlay.dart';
import '../components/progression_edge_states.dart';
import '../effects/progression_particle_system.dart';
import '../theme/neon_theme.dart';

/// Main achievements progression screen that orchestrates all components
class AchievementsProgressionScreen extends StatefulWidget {
  final AchievementManager achievementManager;
  final AdaptiveQualityManager? adaptiveQualityManager;
  final HapticManager? hapticManager;

  const AchievementsProgressionScreen({
    super.key,
    required this.achievementManager,
    this.adaptiveQualityManager,
    this.hapticManager,
  });

  @override
  State<AchievementsProgressionScreen> createState() => _AchievementsProgressionScreenState();
}

class _AchievementsProgressionScreenState extends State<AchievementsProgressionScreen>
    with TickerProviderStateMixin {
  
  // Core controllers
  late ProgressionIntegrationController _integrationController;
  late ProgressionScrollController _scrollController;
  late ScanLineAnimationController _scanLineController;
  late ProgressionPerformanceController _performanceController;
  
  // Background and effects
  late GameWidget<FlameGame> _backgroundWidget;
  late FlameGame _backgroundGame;
  late CyberpunkBackground _cyberpunkBackground;
  late ProgressionParticleSystem _particleSystem;
  
  // State management
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _errorMessage;
  Size _screenSize = Size.zero;
  bool _hasNetworkError = false;
  bool _showCelebration = false;
  
  // Animation and visual state
  double _currentQualityScale = 1.0;
  bool _showScanLine = false;
  Achievement? _selectedAchievement;
  BirdSkin? _selectedRewardSkin;
  
  // Performance tracking
  Timer? _performanceTimer;
  DateTime _lastFrameTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  @override
  void dispose() {
    _performanceTimer?.cancel();
    _performanceController.dispose();
    _integrationController.dispose();
    _scrollController.dispose();
    _scanLineController.dispose();
    _backgroundGame.onRemove();
    super.dispose();
  }

  /// Initialize all components and controllers
  void _initializeComponents() {
    try {
      // Initialize performance controller first
      _performanceController = ProgressionPerformanceController();
      
      // Initialize core controllers
      final pathController = ProgressionPathController();
      _integrationController = ProgressionIntegrationController(
        achievementManager: widget.achievementManager,
        pathController: pathController,
      );
      
      _scrollController = ProgressionScrollController();
      _scanLineController = ScanLineAnimationController();
      
      // Initialize background game
      _initializeBackgroundGame();
      
      // Setup performance monitoring
      _setupPerformanceMonitoring();
      
      // Setup scroll callbacks
      _setupScrollCallbacks();
      
      // Initialize screen after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeScreen();
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize screen: $e';
        _isLoading = false;
      });
    }
  }

  /// Initialize the background game with cyberpunk effects
  void _initializeBackgroundGame() {
    _backgroundGame = FlameGame();
    _cyberpunkBackground = CyberpunkBackground();
    
    // Tone down the parallax scrolling for progression screen
    _cyberpunkBackground.setGridAnimationSpeed(0.1); // Reduced from default
    _cyberpunkBackground.setColorShiftSpeed(0.05); // Reduced from default
    
    _backgroundGame.add(_cyberpunkBackground);
    _backgroundWidget = GameWidget(game: _backgroundGame);
  }

  /// Setup performance monitoring and optimization
  void _setupPerformanceMonitoring() {
    // Register for quality change callbacks
    _performanceController.onParticleQualityChanged((quality) {
      // Update particle system quality
      if (_particleSystem != null) {
        _particleSystem.setQualityScale(_performanceController.currentQualityScale);
      }
    });
    
    _performanceController.onGraphicsQualityChanged((quality) {
      // Update graphics quality settings
      setState(() {
        _currentQualityScale = _performanceController.currentQualityScale;
      });
    });
    
    _performanceController.onEffectsChanged((reduced) {
      // Update effects settings
      if (_particleSystem != null) {
        _particleSystem.setCelebrationEffectsEnabled(!reduced);
        _particleSystem.setPulseEffectsEnabled(!reduced);
      }
    });
    
    // Start performance monitoring
    _performanceTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final now = DateTime.now();
      final frameTime = now.difference(_lastFrameTime).inMicroseconds / 1000.0;
      _performanceController.recordFrame(frameTime);
      _lastFrameTime = now;
    });
  }

  /// Setup scroll controller callbacks
  void _setupScrollCallbacks() {
    _scrollController.setOnScrollStart(() {
      // Haptic feedback on scroll start
      widget.hapticManager?.lightImpact();
    });
    
    _scrollController.setOnScrollEnd(() {
      // Optional: Add completion haptic feedback
    });
    
    _scrollController.setOnProgressChanged((progress) {
      // Update any progress-dependent UI elements
      setState(() {
        // Progress updates handled by integration controller
      });
    });
  }

  /// Initialize the screen after layout is available
  Future<void> _initializeScreen() async {
    try {
      // Get screen size
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        _screenSize = renderBox.size;
      } else {
        _screenSize = MediaQuery.of(context).size;
      }
      
      // Initialize performance controller
      await _performanceController.initialize();
      _performanceController.startOptimization();
      
      // Initialize particle system with performance controller
      final baseParticleSystem = ParticleSystem();
      _particleSystem = ProgressionParticleSystem(
        baseParticleSystem: baseParticleSystem,
        performanceController: _performanceController,
      );
      
      // Initialize integration controller
      await _integrationController.initialize(this);
      
      // Setup achievement update listener
      _setupAchievementUpdateListener();
      
      // Initialize scan line controller
      _scanLineController.initialize(this);
      
      // Set initial quality based on performance controller
      _updateQualitySettings();
      
      // Start performance monitoring
      _startPerformanceMonitoring();
      
      // Check for celebration state
      _checkCelebrationState();
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
        _hasNetworkError = false;
      });
      
      // Start reveal animation
      _startRevealAnimation();
      
    } catch (e) {
      final isNetworkError = e.toString().contains('network') || 
                           e.toString().contains('connection') ||
                           e.toString().contains('timeout');
      
      setState(() {
        _errorMessage = isNetworkError 
            ? 'Network connection failed. Please check your internet connection and try again.'
            : 'Failed to initialize screen: $e';
        _isLoading = false;
        _hasNetworkError = isNetworkError;
      });
    }
  }

  /// Update quality settings based on performance controller
  void _updateQualitySettings() {
    _currentQualityScale = _performanceController.currentQualityScale;
    if (_particleSystem != null) {
      _particleSystem.setQualityScale(_currentQualityScale);
    }
  }

  /// Convert quality enum to scale factor
  double _getQualityScale(dynamic quality) {
    // Convert QualityLevel enum to scale factor
    final qualityString = quality.toString().toLowerCase();
    if (qualityString.contains('low')) return 0.5;
    if (qualityString.contains('medium')) return 0.7;
    if (qualityString.contains('high')) return 0.9;
    if (qualityString.contains('ultra')) return 1.0;
    return 1.0; // default
  }

  /// Start performance monitoring
  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final deltaTime = now.difference(_lastFrameTime).inMilliseconds;
      
      if (deltaTime >= 1000) {
        _lastFrameTime = now;
        
        // Update quality settings based on current performance
        if (widget.adaptiveQualityManager != null) {
          _updateQualitySettings();
        }
      }
    });
  }

  /// Start the reveal animation sequence
  Future<void> _startRevealAnimation() async {
    setState(() {
      _showScanLine = true;
    });
    
    // Start scan line animation
    await _scanLineController.startRevealAnimation();
    
    // Auto-scroll to current progress after reveal
    if (_integrationController.isInitialized) {
      await _scrollToCurrentProgress();
    }
    
    setState(() {
      _showScanLine = false;
    });
  }

  /// Auto-scroll to current player progress
  Future<void> _scrollToCurrentProgress() async {
    final achievements = _integrationController.currentAchievements;
    final nodePositions = _integrationController.pathController.nodePositions;
    
    await _scrollController.animateToCurrentProgress(
      achievements: achievements,
      nodePositions: nodePositions,
      screenSize: _screenSize,
    );
  }

  /// Handle achievement node tap
  void _handleNodeTap(Achievement achievement) {
    widget.hapticManager?.selectionClick();
    
    // Get reward skin if available
    BirdSkin? rewardSkin;
    if (achievement.rewardSkinId != null) {
      // Get skin from achievement manager or customization manager
      // This would need to be implemented based on your skin management system
    }
    
    setState(() {
      _selectedAchievement = achievement;
      _selectedRewardSkin = rewardSkin;
    });
  }

  /// Handle achievement detail overlay close
  void _handleOverlayClose() {
    setState(() {
      _selectedAchievement = null;
      _selectedRewardSkin = null;
    });
  }

  /// Handle achievement sharing
  void _handleAchievementShare(Achievement achievement) {
    _integrationController.shareAchievement(achievement);
    widget.hapticManager?.mediumImpact(); // Use existing method
  }

  /// Check if all achievements are completed for celebration state
  void _checkCelebrationState() {
    final achievements = _integrationController.currentAchievements;
    if (achievements.isNotEmpty && achievements.every((a) => a.isUnlocked)) {
      setState(() {
        _showCelebration = true;
      });
    }
  }

  /// Handle start journey action from empty state
  void _handleStartJourney() {
    Navigator.of(context).pop(); // Return to main game
  }

  /// Handle continue from celebration state
  void _handleCelebrationContinue() {
    setState(() {
      _showCelebration = false;
    });
  }

  /// Check if achievements list is empty (no unlocked achievements)
  bool _hasNoUnlockedAchievements() {
    final achievements = _integrationController.currentAchievements;
    return achievements.isNotEmpty && achievements.every((a) => !a.isUnlocked);
  }

  /// Setup listener for achievement updates to trigger celebration
  void _setupAchievementUpdateListener() {
    _integrationController.addListener(() {
      if (_isInitialized && !_showCelebration && mounted) {
        _handleAchievementUpdate();
      }
    });
  }

  /// Handle achievement updates with debouncing to prevent rapid state changes
  void _handleAchievementUpdate() {
    final achievements = _integrationController.currentAchievements;
    
    // Check for celebration state (all achievements unlocked)
    if (achievements.isNotEmpty && achievements.every((a) => a.isUnlocked)) {
      // Debounce celebration trigger to prevent rapid state changes
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_showCelebration) {
          setState(() {
            _showCelebration = true;
          });
          
          // Add haptic feedback for celebration
          widget.hapticManager?.heavyImpact();
        }
      });
    }
    
    // Handle newly unlocked achievements
    _handleNewlyUnlockedAchievements(achievements);
  }

  /// Handle newly unlocked achievements with particle effects
  void _handleNewlyUnlockedAchievements(List<Achievement> achievements) {
    // This would track previously unlocked achievements and trigger effects for new ones
    // For now, we'll just ensure the particle system is updated
    if (_particleSystem != null) {
      for (final achievement in achievements) {
        if (achievement.isUnlocked) {
          final nodePosition = _integrationController.pathController.nodePositions[achievement.id];
          if (nodePosition != null) {
            // Add subtle unlock effect
            _particleSystem.addNodeUnlockExplosion(
              position: nodePosition.position,
              primaryColor: _getAchievementColor(achievement.type),
              intensity: 0.5,
            );
          }
        }
      }
    }
  }

  /// Get color for achievement type
  Color _getAchievementColor(AchievementType type) {
    switch (type) {
      case AchievementType.score:
        return NeonTheme.primaryNeon;
      case AchievementType.totalScore:
        return const Color(0xFF00FFFF); // Cyan
      case AchievementType.gamesPlayed:
        return const Color(0xFFFFFF00); // Yellow
      case AchievementType.pulseUsage:
        return const Color(0xFF00FF00); // Green
      case AchievementType.powerUps:
        return const Color(0xFFFF4500); // Orange-red
      case AchievementType.survival:
        return const Color(0xFF9932CC); // Purple
    }
  }

  /// Retry initialization after error
  Future<void> _retryInitialization() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _hasNetworkError = false;
    });
    
    try {
      // Add haptic feedback for retry action
      widget.hapticManager?.lightImpact();
      
      // Reinitialize components if needed
      if (!_integrationController.isInitialized) {
        await _integrationController.initialize(this);
      } else {
        await _integrationController.refreshData();
      }
      
      // Reinitialize screen
      await _initializeScreen();
      
    } catch (e) {
      final isNetworkError = e.toString().contains('network') || 
                           e.toString().contains('connection') ||
                           e.toString().contains('timeout');
      
      setState(() {
        _errorMessage = isNetworkError 
            ? 'Network connection failed. Please check your internet connection and try again.'
            : 'Retry failed: ${e.toString()}';
        _isLoading = false;
        _hasNetworkError = isNetworkError;
      });
    }
  }

  /// Use offline/cached data when network is unavailable
  void _useOfflineData() {
    setState(() {
      _errorMessage = null;
      _hasNetworkError = false;
      _isLoading = false;
      _isInitialized = true;
    });
    
    // Show a brief message about using cached data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Using cached data. Some information may be outdated.',
          style: TextStyle(color: NeonTheme.textPrimary),
        ),
        backgroundColor: NeonTheme.warningOrange.withValues(alpha: 0.1),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonTheme.backgroundColor,
      body: Stack(
        children: [
          // Background layer
          _buildBackgroundLayer(),
          
          // Main content
          if (_isLoading)
            _buildLoadingState()
          else if (_errorMessage != null)
            _buildErrorState()
          else if (_showCelebration)
            _buildCelebrationState()
          else if (_isInitialized && _hasNoUnlockedAchievements())
            _buildEmptyState()
          else if (_isInitialized)
            _buildMainContent()
          else
            _buildLoadingState(),
          
          // Scan line overlay
          if (_showScanLine && _scanLineController.isInitialized)
            _buildScanLineOverlay(),
          
          // Achievement detail overlay
          if (_selectedAchievement != null)
            _buildAchievementDetailOverlay(),
          
          // App bar
          _buildAppBar(),
        ],
      ),
    );
  }

  /// Build the cyberpunk background layer
  Widget _buildBackgroundLayer() {
    return Positioned.fill(
      child: _backgroundWidget,
    );
  }

  /// Build loading state with skeleton path and shimmer effects
  Widget _buildLoadingState() {
    return ProgressionLoadingState(
      screenSize: _screenSize.isEmpty ? MediaQuery.of(context).size : _screenSize,
      showShimmer: true,
    );
  }

  /// Build error state with retry functionality
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _hasNetworkError ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color: NeonTheme.warningOrange,
            ),
            const SizedBox(height: 16),
            Text(
              _hasNetworkError ? 'Connection Failed' : 'Error Loading Progression',
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: NeonTheme.warningOrange,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: TextStyle(
                color: NeonTheme.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _retryInitialization,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NeonTheme.primaryNeon.withValues(alpha: 0.1),
                    foregroundColor: NeonTheme.primaryNeon,
                    side: BorderSide(color: NeonTheme.primaryNeon),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 18),
                      const SizedBox(width: 8),
                      const Text('Retry'),
                    ],
                  ),
                ),
                if (_hasNetworkError) ...[
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: _useOfflineData,
                    style: TextButton.styleFrom(
                      foregroundColor: NeonTheme.textSecondary,
                    ),
                    child: const Text('Use Offline Data'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state for players with no unlocked achievements
  Widget _buildEmptyState() {
    return ProgressionEmptyState(
      screenSize: _screenSize.isEmpty ? MediaQuery.of(context).size : _screenSize,
      onStartJourney: _handleStartJourney,
    );
  }

  /// Build celebration state for 100% completion
  Widget _buildCelebrationState() {
    final achievements = _integrationController.currentAchievements;
    return ProgressionCelebrationState(
      screenSize: _screenSize.isEmpty ? MediaQuery.of(context).size : _screenSize,
      totalAchievements: achievements.length,
      onContinue: _handleCelebrationContinue,
    );
  }

  /// Build main progression content
  Widget _buildMainContent() {
    return AnimatedBuilder(
      animation: _integrationController,
      builder: (context, child) {
        final achievements = _integrationController.currentAchievements;
        final nodePositions = _integrationController.pathController.nodePositions;
        final pathSegments = _integrationController.pathController.pathSegments;
        
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // Update viewport for culling
            if (notification is ScrollUpdateNotification) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                final viewport = Rect.fromLTWH(
                  0,
                  notification.metrics.pixels,
                  renderBox.size.width,
                  renderBox.size.height,
                );
                _performanceController.updateViewport(viewport);
              }
            }
            return false;
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Main progression path canvas
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _calculateContentHeight(achievements, nodePositions),
                  child: Stack(
                    children: [
                      // Path renderer with performance optimization
                      CustomPaint(
                        size: Size.infinite,
                        painter: PathRenderer(
                          pathSegments: pathSegments,
                          energyParticles: _getEnergyParticles(),
                          animationProgress: 1.0,
                          enableGlowEffects: !_performanceController.areEffectsReduced,
                          glowIntensity: _currentQualityScale,
                          qualityScale: _currentQualityScale,
                          performanceController: _performanceController,
                        ),
                      ),
                      
                      // Achievement nodes with viewport culling
                      ...achievements.map<Widget>((achievement) {
                        final nodePosition = nodePositions[achievement.id];
                        if (nodePosition == null) return const SizedBox.shrink();
                        
                        // Check if node is visible before rendering
                        if (!_performanceController.isNodeVisible(nodePosition)) {
                          return const SizedBox.shrink();
                        }
                        
                        return Positioned(
                          left: nodePosition.position.x - 22, // Center the 44dp node
                          top: nodePosition.position.y - 22,
                          child: AchievementNode(
                            achievement: achievement,
                            visualState: nodePosition.visualState,
                            onTap: () => _handleNodeTap(achievement),
                            size: 44.0,
                            enableAnimations: _currentQualityScale > 0.5,
                          ),
                        );
                      }),
                      
                      // Particle system overlay
                      CustomPaint(
                        size: Size.infinite,
                        painter: _ParticleSystemPainter(_particleSystem),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Calculate the total content height needed
  double _calculateContentHeight(List<Achievement> achievements, Map<String, NodePosition> nodePositions) {
    if (nodePositions.isEmpty) return _screenSize.height * 2; // Default height
    
    double maxY = 0;
    for (final position in nodePositions.values) {
      maxY = math.max(maxY, position.position.y);
    }
    
    // Add padding at bottom
    return maxY + 200;
  }

  /// Get energy particles for path renderer
  List<EnergyFlowParticle> _getEnergyParticles() {
    // This would get particles from the particle system
    // For now, return empty list as the particle system handles its own rendering
    return [];
  }

  /// Build scan line overlay
  Widget _buildScanLineOverlay() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _scanLineController,
        builder: (context, child) {
          return CustomPaint(
            painter: _scanLineController.createScanLinePainter(_screenSize),
            size: _screenSize,
          );
        },
      ),
    );
  }

  /// Build achievement detail overlay
  Widget _buildAchievementDetailOverlay() {
    return AchievementDetailOverlay(
      achievement: _selectedAchievement!,
      rewardSkin: _selectedRewardSkin,
      achievementManager: widget.achievementManager,
      onClose: _handleOverlayClose,
      onShare: () => _handleAchievementShare(_selectedAchievement!),
    );
  }

  /// Build app bar
  Widget _buildAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).padding.top + 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              NeonTheme.backgroundColor.withValues(alpha: 0.9),
              NeonTheme.backgroundColor.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: NeonTheme.primaryNeon,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'PROGRESSION PATH',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: NeonTheme.primaryNeon,
                    letterSpacing: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: NeonTheme.primaryNeon,
                ),
                onPressed: () async {
                  widget.hapticManager?.lightImpact();
                  await _integrationController.refreshData();
                  await _scrollToCurrentProgress();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for particle system rendering
class _ParticleSystemPainter extends CustomPainter {
  final ProgressionParticleSystem particleSystem;

  _ParticleSystemPainter(this.particleSystem);

  @override
  void paint(Canvas canvas, Size size) {
    particleSystem.render(canvas);
  }

  @override
  bool shouldRepaint(_ParticleSystemPainter oldDelegate) {
    return true; // Always repaint for particle animations
  }
}