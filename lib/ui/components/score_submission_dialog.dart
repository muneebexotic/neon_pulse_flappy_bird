import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/leaderboard_integration_service.dart';
import '../theme/neon_theme.dart';

/// Dialog that shows score submission status and results
class ScoreSubmissionDialog extends StatefulWidget {
  final int score;
  final ScoreSubmissionResult result;
  final int? leaderboardPosition;
  final bool isPersonalBest;
  final VoidCallback? onClose;
  final VoidCallback? onViewLeaderboard;
  final VoidCallback? onRetry;

  const ScoreSubmissionDialog({
    super.key,
    required this.score,
    required this.result,
    this.leaderboardPosition,
    this.isPersonalBest = false,
    this.onClose,
    this.onViewLeaderboard,
    this.onRetry,
  });

  @override
  State<ScoreSubmissionDialog> createState() => _ScoreSubmissionDialogState();
}

class _ScoreSubmissionDialogState extends State<ScoreSubmissionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0B1F),
                      border: Border.all(
                        color: _getStatusColor(),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor().withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status icon and title
                        _buildStatusHeader(),
                        
                        const SizedBox(height: 20),
                        
                        // Score display
                        _buildScoreDisplay(),
                        
                        const SizedBox(height: 16),
                        
                        // Status message
                        _buildStatusMessage(),
                        
                        // Leaderboard position (if available)
                        if (widget.leaderboardPosition != null) ...[
                          const SizedBox(height: 12),
                          _buildLeaderboardPosition(),
                        ],
                        
                        // Personal best badge (if applicable)
                        if (widget.isPersonalBest) ...[
                          const SizedBox(height: 12),
                          _buildPersonalBestBadge(),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Action buttons
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader() {
    final config = _getStatusConfig();
    
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: config.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: config.color, width: 2),
          ),
          child: Icon(
            config.icon,
            color: config.color,
            size: 30,
          ),
        ).animate().scale(
          duration: const Duration(milliseconds: 600),
          curve: Curves.bounceOut,
        ),
        
        const SizedBox(height: 12),
        
        Text(
          config.title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: config.color,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: config.color,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.cyan.withValues(alpha: 0.1),
        border: Border.all(color: Colors.cyan, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${widget.score}',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.cyan,
          shadows: [
            Shadow(
              blurRadius: 8.0,
              color: Colors.cyan,
              offset: const Offset(0, 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    final config = _getStatusConfig();
    
    return Text(
      config.message,
      style: TextStyle(
        fontSize: 16,
        color: Colors.white.withValues(alpha: 0.9),
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLeaderboardPosition() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.yellow.withValues(alpha: 0.1),
        border: Border.all(color: Colors.yellow, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.leaderboard,
            color: Colors.yellow,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Global Rank: #${widget.leaderboardPosition}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.yellow,
            ),
          ),
        ],
      ),
    ).animate().slideY(
      begin: 0.5,
      duration: const Duration(milliseconds: 800),
      curve: Curves.bounceOut,
    );
  }

  Widget _buildPersonalBestBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        border: Border.all(color: Colors.green, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: Colors.green,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Personal Best!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    ).animate().slideY(
      begin: 0.5,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.bounceOut,
    ).shimmer(
      duration: const Duration(seconds: 2),
      color: Colors.green.withValues(alpha: 0.5),
    );
  }

  Widget _buildActionButtons() {
    final buttons = <Widget>[];
    
    // Always show close button
    buttons.add(
      Expanded(
        child: _buildActionButton(
          'CLOSE',
          Icons.close,
          Colors.grey,
          widget.onClose ?? () => Navigator.of(context).pop(),
        ),
      ),
    );
    
    // Show view leaderboard button for successful submissions
    if (widget.result == ScoreSubmissionResult.success && widget.onViewLeaderboard != null) {
      buttons.insert(0, 
        Expanded(
          child: _buildActionButton(
            'LEADERBOARD',
            Icons.leaderboard,
            Colors.cyan,
            widget.onViewLeaderboard!,
          ),
        ),
      );
    }
    
    // Show retry button for failed submissions
    if ((widget.result == ScoreSubmissionResult.failed || 
         widget.result == ScoreSubmissionResult.networkError) && 
        widget.onRetry != null) {
      buttons.insert(0,
        Expanded(
          child: _buildActionButton(
            'RETRY',
            Icons.refresh,
            Colors.orange,
            widget.onRetry!,
          ),
        ),
      );
    }
    
    return Row(
      children: buttons
          .expand((button) => [button, if (button != buttons.last) const SizedBox(width: 8)])
          .toList(),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        side: BorderSide(color: color, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    return _getStatusConfig().color;
  }

  StatusConfig _getStatusConfig() {
    switch (widget.result) {
      case ScoreSubmissionResult.success:
        return StatusConfig(
          title: 'Score Submitted!',
          message: 'Your score has been successfully submitted to the global leaderboard.',
          icon: Icons.check_circle,
          color: Colors.green,
        );
      case ScoreSubmissionResult.queued:
        return StatusConfig(
          title: 'Score Queued',
          message: 'Your score has been saved and will be submitted when you\'re back online.',
          icon: Icons.schedule,
          color: Colors.orange,
        );
      case ScoreSubmissionResult.failed:
        return StatusConfig(
          title: 'Submission Failed',
          message: 'Failed to submit your score. Please try again later.',
          icon: Icons.error,
          color: Colors.red,
        );
      case ScoreSubmissionResult.invalidScore:
        return StatusConfig(
          title: 'Invalid Score',
          message: 'This score could not be validated. Please play again.',
          icon: Icons.warning,
          color: Colors.orange,
        );
      case ScoreSubmissionResult.notAuthenticated:
        return StatusConfig(
          title: 'Sign In Required',
          message: 'Please sign in with Google to submit scores to the leaderboard.',
          icon: Icons.account_circle,
          color: Colors.blue,
        );
      case ScoreSubmissionResult.networkError:
        return StatusConfig(
          title: 'Network Error',
          message: 'Unable to connect to the server. Check your internet connection.',
          icon: Icons.wifi_off,
          color: Colors.red,
        );
      case ScoreSubmissionResult.notBestScore:
        return StatusConfig(
          title: 'Score Not Submitted',
          message: 'This score was not submitted because you already have a better score on the leaderboard.',
          icon: Icons.info,
          color: Colors.grey,
        );
    }
  }
}

/// Configuration for different submission statuses
class StatusConfig {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  StatusConfig({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });
}