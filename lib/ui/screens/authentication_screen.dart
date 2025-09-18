import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/authentication_provider.dart';
import '../components/neon_button.dart';
import '../components/neon_container.dart';
import '../utils/animation_config.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  
  @override
  void initState() {
    super.initState();
    
    _backgroundController = AnimationController(
      duration: AnimationConfig.verySlow,
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: AnimationConfig.slow,
      vsync: this,
    );
    
    _startAnimations();
  }
  
  void _startAnimations() async {
    _backgroundController.repeat();
    await Future.delayed(AnimationConfig.medium);
    _contentController.forward();
  }
  
  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B0B1F), // Deep space
              Color(0xFF1A0B2E), // Dark purple
              Color(0xFF2D1B3D), // Purple
              Color(0xFF1A0B2E), // Dark purple
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background
            _buildAnimatedBackground(),
            
            // Main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),
                    
                    // Content
                    Expanded(
                      child: _buildContent(),
                    ),
                    
                    // Footer
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return CustomPaint(
          painter: AuthBackgroundPainter(_backgroundController.value),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
  
  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - _contentController.value)),
          child: Opacity(
            opacity: _contentController.value,
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Logo
                Text(
                  'NEON PULSE',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: Colors.cyan,
                    shadows: [
                      Shadow(
                        blurRadius: 20.0,
                        color: Colors.cyan.withOpacity(0.8),
                        offset: const Offset(0, 0),
                      ),
                      Shadow(
                        blurRadius: 40.0,
                        color: Colors.cyan.withOpacity(0.4),
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'FLAPPY BIRD',
                  style: TextStyle(
                    fontSize: 18,
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
                
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildContent() {
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) {
        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Welcome message
                _buildWelcomeMessage(),
                
                const SizedBox(height: 40),
                
                // Authentication options
                _buildAuthenticationOptions(authProvider),
                
                const SizedBox(height: 30),
                
                // Error message
                if (authProvider.hasError)
                  _buildErrorMessage(authProvider),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildWelcomeMessage() {
    return NeonContainer(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.security,
              size: 48,
              color: Colors.cyan.withOpacity(0.8),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Welcome to Neon Pulse',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.cyan.withOpacity(0.5),
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Sign in to save your progress, compete on global leaderboards, and unlock exclusive features.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 800.ms).slideY(begin: 0.3, end: 0);
  }
  
  Widget _buildAuthenticationOptions(AuthenticationProvider authProvider) {
    return Column(
      children: [
        // Google Sign-In Button
        SizedBox(
          width: double.infinity,
          child: NeonButton(
            text: 'Sign in with Google',
            icon: Icons.login,
            onPressed: authProvider.isLoading ? null : () => _signInWithGoogle(authProvider),
            isLoading: authProvider.isLoading,
            isEnabled: !authProvider.isLoading,
          ),
        ).animate().fadeIn(delay: 700.ms, duration: 600.ms).slideX(begin: -0.3, end: 0),
        
        const SizedBox(height: 16),
        
        // Guest Mode Button
        SizedBox(
          width: double.infinity,
          child: NeonButton(
            text: 'Continue as Guest',
            icon: Icons.person_outline,
            color: Colors.pink.withOpacity(0.8),
            onPressed: authProvider.isLoading ? null : () => _signInAsGuest(authProvider),
            isEnabled: !authProvider.isLoading,
          ),
        ).animate().fadeIn(delay: 900.ms, duration: 600.ms).slideX(begin: 0.3, end: 0),
        
        const SizedBox(height: 24),
        
        // Info text
        Text(
          'Guest mode: Play offline with limited features.\nSign in to unlock the full experience.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
            height: 1.4,
          ),
        ).animate().fadeIn(delay: 1100.ms, duration: 600.ms),
      ],
    );
  }
  
  Widget _buildErrorMessage(AuthenticationProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              authProvider.getFormattedErrorMessage(),
              style: TextStyle(
                color: Colors.red.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () => authProvider.clearError(),
            child: Text(
              'Dismiss',
              style: TextStyle(
                color: Colors.red.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).shake();
  }
  
  Widget _buildFooter() {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _contentController.value)),
          child: Opacity(
            opacity: _contentController.value,
            child: Column(
              children: [
                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                    height: 1.3,
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _signInWithGoogle(AuthenticationProvider authProvider) async {
    final success = await authProvider.signInWithGoogle();
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/main-menu');
    }
  }
  
  Future<void> _signInAsGuest(AuthenticationProvider authProvider) async {
    final success = await authProvider.signInAsGuest();
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/main-menu');
    }
  }
}

class AuthBackgroundPainter extends CustomPainter {
  final double animationValue;
  
  AuthBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    // Draw floating orbs
    for (int i = 0; i < 8; i++) {
      final angle = (animationValue * 2 * 3.14159) + (i * 0.785); // 45 degrees apart
      final radius = 100 + (i * 20);
      final x = size.width * 0.5 + (radius * 0.8 * (animationValue * 2 - 1));
      final y = size.height * 0.5 + (radius * 0.6 * (animationValue * 2 - 1));
      
      final orbRadius = 3.0 + (animationValue * 2);
      
      canvas.drawCircle(
        Offset(x, y),
        orbRadius,
        paint,
      );
    }
    
    // Draw energy grid
    final gridPaint = Paint()
      ..color = Colors.pink.withOpacity(0.05)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    final gridSize = 50.0;
    final offsetX = (animationValue * gridSize) % gridSize;
    final offsetY = (animationValue * gridSize * 0.7) % gridSize;
    
    for (double x = -gridSize + offsetX; x < size.width + gridSize; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    
    for (double y = -gridSize + offsetY; y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(AuthBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}