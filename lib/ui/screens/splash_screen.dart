import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/authentication_provider.dart';
import 'main_menu_screen.dart';
import 'authentication_screen.dart';
import '../utils/startup_sequence_manager.dart';
import '../utils/animation_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  
  double _loadingProgress = 0.0;
  String _currentLoadingStep = 'Initializing...';
  StartupStep _currentStep = StartupStep.systemInit;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _logoController = AnimationController(
      duration: AnimationConfig.slow,
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: AnimationConfig.neonPulse,
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: AnimationConfig.verySlow,
      vsync: this,
    );
    
    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // Start logo animation
    _logoController.forward();
    
    // Start glow animation with delay
    await Future.delayed(AnimationConfig.medium);
    _glowController.repeat(reverse: true);
    
    // Start particle animation
    await Future.delayed(AnimationConfig.standard);
    _particleController.forward();
    
    // Initialize authentication system
    if (mounted) {
      setState(() {
        _currentLoadingStep = 'Initializing authentication...';
        _loadingProgress = 0.1;
      });
      
      try {
        print('Initializing authentication...');
        final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
        await authProvider.initialize();
        
        print('Authentication initialized. State: ${authProvider.state}');
        print('Current user: ${authProvider.currentUser}');
        
        if (mounted) {
          setState(() {
            _currentLoadingStep = 'Authentication ready';
            _loadingProgress = 0.3;
          });
        }
        
        // If no user is authenticated, show authentication screen
        // Otherwise, user will be automatically restored from persistence
        
      } catch (e) {
        print('Authentication initialization failed: $e');
        if (mounted) {
          setState(() {
            _currentLoadingStep = 'Authentication error (continuing...)';
            _loadingProgress = 0.3;
          });
        }
      }
    }
    
    // Execute startup sequence with progress tracking
    await StartupSequenceManager().executeStartupSequence(
      onProgress: (progress, step, stepType) {
        if (mounted) {
          setState(() {
            _loadingProgress = 0.3 + (progress * 0.7); // Reserve first 30% for auth
            _currentLoadingStep = step;
            _currentStep = stepType;
          });
        }
      },
      onError: (error, failedStep) {
        print('Startup failed at step $failedStep: $error');
        // Continue anyway - show error but don't block
        if (mounted) {
          setState(() {
            _currentLoadingStep = 'Error: $error (continuing...)';
          });
        }
      },
    );
    
    // Wait for minimum splash duration
    await Future.delayed(AnimationConfig.verySlow);
    
    // Navigate based on authentication state
    if (mounted) {
      await _navigateBasedOnAuthState();
    }
  }



  Future<void> _navigateBasedOnAuthState() async {
    final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
    
    print('Authentication State Check:');
    print('  - isAuthenticated: ${authProvider.isAuthenticated}');
    print('  - isGuest: ${authProvider.isGuest}');
    print('  - state: ${authProvider.state}');
    print('  - currentUser: ${authProvider.currentUser}');
    
    // Fade out current screen
    await _logoController.reverse();
    
    if (mounted) {
      // Check authentication state and navigate accordingly
      if (authProvider.isAuthenticated || authProvider.isGuest) {
        // User is already authenticated or in guest mode, go to main menu
        print('Navigating to main menu (authenticated/guest)');
        await _navigateToMainMenu();
      } else {
        // User needs to authenticate, show authentication screen
        print('Navigating to authentication screen');
        await _navigateToAuthScreen();
      }
    }
  }

  Future<void> _navigateToMainMenu() async {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainMenuScreen(),
          transitionDuration: AnimationConfig.slow,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: AnimationConfig.standardEase,
              ),
              child: child,
            );
          },
        ),
      );
    }
  }

  Future<void> _navigateToAuthScreen() async {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AuthenticationScreen(),
          transitionDuration: AnimationConfig.slow,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: AnimationConfig.standardEase,
              ),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _particleController.dispose();
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
              Color(0xFF0B0B1F), // Deep space
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            _buildBackgroundParticles(),
            
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  _buildAnimatedLogo(),
                  
                  const SizedBox(height: 60),
                  
                  // Loading indicator
                  _buildLoadingIndicator(),
                  
                  const SizedBox(height: 40),
                  
                  // Status text
                  _buildStatusText(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoController.value,
          child: Opacity(
            opacity: _logoController.value,
            child: Column(
              children: [
                // Main title with glow effect
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Text(
                      'NEON PULSE',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Colors.cyan,
                        shadows: [
                          Shadow(
                            blurRadius: 20.0 + (_glowController.value * 10),
                            color: Colors.cyan.withOpacity(0.8),
                            offset: const Offset(0, 0),
                          ),
                          Shadow(
                            blurRadius: 40.0 + (_glowController.value * 20),
                            color: Colors.cyan.withOpacity(0.4),
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'FLAPPY BIRD',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                    color: Colors.pink.withOpacity(0.9),
                    shadows: [
                      Shadow(
                        blurRadius: 15.0,
                        color: Colors.pink.withOpacity(0.6),
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlesPainter(_particleController.value),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 200,
      height: 4,
      child: LinearProgressIndicator(
        value: _loadingProgress,
        backgroundColor: Colors.grey.withOpacity(0.3),
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.cyan.withOpacity(0.8),
        ),
      ),
    ).animate().fadeIn(duration: AnimationConfig.slow.inMilliseconds.ms).slideX(begin: -0.5, end: 0);
  }

  Widget _buildStatusText() {
    return Text(
      _currentLoadingStep,
      style: TextStyle(
        fontSize: 16,
        color: Colors.white.withOpacity(0.7),
        letterSpacing: 1,
      ),
    ).animate().fadeIn(delay: AnimationConfig.slow.inMilliseconds.ms, duration: AnimationConfig.medium.inMilliseconds.ms);
  }
}

class ParticlesPainter extends CustomPainter {
  final double animationValue;
  
  ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    // Draw floating particles
    for (int i = 0; i < 20; i++) {
      final x = (size.width * (i / 20)) + 
                (50 * (animationValue * 2 - 1)) * (i % 2 == 0 ? 1 : -1);
      final y = (size.height * 0.2) + 
                (size.height * 0.6 * (i / 20)) +
                (30 * (animationValue * 2 - 1));
      
      final radius = 2.0 + (animationValue * 3);
      
      canvas.drawCircle(
        Offset(x % size.width, y % size.height),
        radius,
        paint,
      );
    }
    
    // Draw energy lines
    final linePaint = Paint()
      ..color = Colors.pink.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 5; i++) {
      final startX = -100 + (animationValue * size.width * 1.5);
      final startY = size.height * (i / 5);
      final endX = startX + 200;
      final endY = startY + 50;
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}