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
import '../painters/path_renderer.dart';
import '../widgets/achievement_node.dart';
import '../components/achievement_detail_overlay.dart';
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
    _integrationController.dispose();
    _scrollController.dispose();
    _scanLineController.dispose();
    _backgroundGame.onRemove();
    super.dispose();
  }

  /// Initialize all components and controllers
  void _initializeComponents() {
    try {
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
      
      // Initialize particle system
      final baseParticleSystem = ParticleSystem();
      _particleSystem = ProgressionParticleSystem(
        baseParticleSystem: baseParticleSystem,
      );
      
      // Initialize integration controller
      await _integrationController.initialize(this);
      
      // Initialize scan line controller
      _scanLineController.initialize(this);
      
      // Set initial quality based on adaptive quality manager
      _updateQualitySettings();
      
      // Start performance monitoring
      _startPerformanceMonitoring();
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
      
      // Start reveal animation
      _startRevealAnimation();
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize screen: $e';
        _isLoading = false;
      });
    }
  }

  /// Update quality settings based on adaptive quality manager
  void _updateQualitySettings() {
    if (widget.adaptiveQualityManager != null) {
      final particleQuality = widget.adaptiveQualityManager!.currentParticleQuality;
      _currentQualityScale = _getQualityScale(particleQuality);
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

  /// Build loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(NeonTheme.primaryNeon),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading Progression Path...',
            style: TextStyle(
              color: NeonTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: NeonTheme.warningOrange,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Progression',
            style: TextStyle(
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
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _isLoading = true;
              });
              _initializeScreen();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NeonTheme.primaryNeon.withValues(alpha: 0.1),
              foregroundColor: NeonTheme.primaryNeon,
              side: BorderSide(color: NeonTheme.primaryNeon),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
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
        
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Main progression path canvas
            SliverToBoxAdapter(
              child: SizedBox(
                height: _calculateContentHeight(achievements, nodePositions),
                child: Stack(
                  children: [
                    // Path renderer
                    CustomPaint(
                      size: Size.infinite,
                      painter: PathRenderer(
                        pathSegments: pathSegments,
                        energyParticles: _getEnergyParticles(),
                        animationProgress: 1.0,
                        enableGlowEffects: true,
                        glowIntensity: _currentQualityScale,
                        qualityScale: _currentQualityScale,
                      ),
                    ),
                    
                    // Achievement nodes
                    ...achievements.map<Widget>((achievement) {
                      final nodePosition = nodePositions[achievement.id];
                      if (nodePosition == null) return const SizedBox.shrink();
                      
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