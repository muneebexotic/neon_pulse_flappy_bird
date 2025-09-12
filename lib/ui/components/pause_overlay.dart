import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// Pause overlay that appears when the game is paused
class PauseOverlay extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onSettings;
  final VoidCallback onMainMenu;
  final bool isVisible;

  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onSettings,
    required this.onMainMenu,
    this.isVisible = true,
  });

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(PauseOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: Colors.black.withOpacity(0.8 * _fadeAnimation.value),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: _buildPauseMenu(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPauseMenu() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NeonTheme.deepSpace.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NeonTheme.electricBlue.withOpacity(0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: NeonTheme.electricBlue.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: NeonTheme.hotPink.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pause title
          Text(
            'GAME PAUSED',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: NeonTheme.electricBlue,
              letterSpacing: 3.0,
              shadows: NeonTheme.getNeonGlow(NeonTheme.electricBlue),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Menu buttons
          _buildMenuButton(
            icon: Icons.play_arrow,
            label: 'RESUME',
            color: NeonTheme.neonGreen,
            onPressed: widget.onResume,
          ),
          
          const SizedBox(height: 16),
          
          _buildMenuButton(
            icon: Icons.refresh,
            label: 'RESTART',
            color: NeonTheme.warningOrange,
            onPressed: widget.onRestart,
          ),
          
          const SizedBox(height: 16),
          
          _buildMenuButton(
            icon: Icons.settings,
            label: 'SETTINGS',
            color: NeonTheme.hotPink,
            onPressed: widget.onSettings,
          ),
          
          const SizedBox(height: 16),
          
          _buildMenuButton(
            icon: Icons.home,
            label: 'MAIN MENU',
            color: NeonTheme.electricBlue,
            onPressed: widget.onMainMenu,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: color.withOpacity(0.6),
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1.5,
                shadows: NeonTheme.getNeonGlow(color, blurRadius: 6.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}