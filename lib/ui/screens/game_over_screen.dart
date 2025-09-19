import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../game/managers/achievement_manager.dart';
import '../../services/leaderboard_integration_service.dart';
import '../../providers/authentication_provider.dart';
import '../components/celebration_overlay.dart';
import '../components/score_submission_dialog.dart';
import '../theme/neon_theme.dart';
import 'leaderboard_screen.dart';

/// Game over screen that displays final score, high score, and restart button
class GameOverScreen extends StatefulWidget {
  final int finalScore;
  final int highScore;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;
  final AchievementManager? achievementManager;
  final GlobalKey? screenshotKey;
  final GameSession? gameSession;

  const GameOverScreen({
    super.key,
    required this.finalScore,
    required this.highScore,
    required this.onRestart,
    required this.onMainMenu,
    this.achievementManager,
    this.screenshotKey,
    this.gameSession,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  bool _isSubmittingScore = false;
  bool _hasSubmittedScore = false;
  ScoreSubmissionResult? _submissionResult;
  int? _leaderboardPosition;
  CelebrationLevel? _celebrationLevel;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _handleScoreSubmission();
  }

  Future<void> _handleScoreSubmission() async {
    final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
    
    // Submit score for all users (authenticated and guest)
    if (!authProvider.isAuthenticated) {
      return;
    }

    // Don't submit if already submitted
    if (_hasSubmittedScore) return;

    setState(() {
      _isSubmittingScore = true;
    });

    try {
      // Create game session if not provided
      final gameSession = widget.gameSession ?? GameSession(
        startTime: DateTime.now().subtract(const Duration(minutes: 1)),
        endTime: DateTime.now(),
        finalScore: widget.finalScore,
        jumpCount: widget.finalScore * 2, // Estimate
        pulseUsage: widget.finalScore ~/ 5, // Estimate
        powerUpsCollected: widget.finalScore ~/ 10, // Estimate
        survivalTime: widget.finalScore * 1.5, // Estimate
        sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      // Submit score
      final result = await LeaderboardIntegrationService.submitScore(
        score: widget.finalScore,
        gameSession: gameSession,
        user: authProvider.currentUser,
      );

      // Get leaderboard position if successful
      int? position;
      if (result == ScoreSubmissionResult.success) {
        position = await LeaderboardIntegrationService.getUserLeaderboardPosition(
          userId: authProvider.currentUser!.uid!,
          score: widget.finalScore,
        );
      }

      // Determine celebration level
      final isPersonalBest = widget.finalScore == widget.highScore && widget.finalScore > 0;
      final celebrationLevel = await LeaderboardIntegrationService.getCelebrationLevel(
        score: widget.finalScore,
        isPersonalBest: isPersonalBest,
      );

      setState(() {
        _isSubmittingScore = false;
        _hasSubmittedScore = true;
        _submissionResult = result;
        _leaderboardPosition = position;
        _celebrationLevel = celebrationLevel;
        _showCelebration = celebrationLevel == CelebrationLevel.legendary || 
                         celebrationLevel == CelebrationLevel.epic;
      });

      // Show celebration overlay for top achievements
      if (_showCelebration) {
        _showCelebrationOverlay();
      }

      // Update user statistics
      await authProvider.recordGameResult(widget.finalScore);

    } catch (e) {
      print('Error handling score submission: $e');
      setState(() {
        _isSubmittingScore = false;
        _submissionResult = ScoreSubmissionResult.failed;
      });
    }
  }

  void _showCelebrationOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CelebrationOverlay(
        level: _celebrationLevel!,
        score: widget.finalScore,
        leaderboardPosition: _leaderboardPosition,
        isPersonalBest: widget.finalScore == widget.highScore && widget.finalScore > 0,
        onComplete: () {
          Navigator.of(context).pop();
          _showScoreSubmissionDialog();
        },
      ),
    );
  }

  void _showScoreSubmissionDialog() {
    if (_submissionResult == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ScoreSubmissionDialog(
        score: widget.finalScore,
        result: _submissionResult!,
        leaderboardPosition: _leaderboardPosition,
        isPersonalBest: widget.finalScore == widget.highScore && widget.finalScore > 0,
        onViewLeaderboard: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const LeaderboardScreen(),
            ),
          );
        },
        onRetry: () {
          Navigator.of(context).pop();
          setState(() {
            _hasSubmittedScore = false;
          });
          _handleScoreSubmission();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNewHighScore = widget.finalScore == widget.highScore && widget.finalScore > 0;
    
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0B0B1F),
            border: Border.all(
              color: Colors.cyan,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Game Over Title
              Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.red,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // New High Score indicator (if applicable)
              if (isNewHighScore) ...[
                Text(
                  'NEW HIGH SCORE!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                    shadows: [
                      Shadow(
                        blurRadius: 8.0,
                        color: Colors.yellow,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Final Score
              _buildScoreRow('SCORE', widget.finalScore, Colors.cyan),
              
              const SizedBox(height: 12),
              
              // High Score
              _buildScoreRow('HIGH SCORE', widget.highScore, Colors.green),
              
              // Leaderboard position (if available)
              if (_leaderboardPosition != null) ...[
                const SizedBox(height: 12),
                _buildScoreRow('GLOBAL RANK', _leaderboardPosition!, Colors.yellow),
              ],
              
              // Score submission status
              if (_isSubmittingScore) ...[
                const SizedBox(height: 16),
                _buildSubmissionStatus(),
              ],
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Restart Button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildActionButton(
                        'RESTART',
                        Icons.refresh,
                        Colors.cyan,
                        widget.onRestart,
                      ),
                    ),
                  ),
                  
                  // Main Menu Button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildActionButton(
                        'MENU',
                        Icons.home,
                        Colors.orange,
                        widget.onMainMenu,
                      ),
                    ),
                  ),
                  
                  // Leaderboard Button (if score was submitted)
                  if (_submissionResult == ScoreSubmissionResult.success)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildActionButton(
                          'BOARD',
                          Icons.leaderboard,
                          Colors.yellow,
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LeaderboardScreen(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Share Score Button (only if achievement manager is available)
                  if (widget.achievementManager != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildActionButton(
                          'SHARE',
                          Icons.share,
                          NeonTheme.secondaryNeon,
                          () => _shareScore(),
                        ),
                      ),
                    ),
                  
                  // Score Status Button (show submission dialog)
                  if (_submissionResult != null && 
                      _submissionResult != ScoreSubmissionResult.success &&
                      _submissionResult != ScoreSubmissionResult.notBestScore)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildActionButton(
                          'STATUS',
                          Icons.info,
                          _getStatusColor(),
                          _showScoreSubmissionDialog,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Tap to restart hint
              Text(
                'Tap RESTART to play again',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, int score, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          score.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [
              Shadow(
                blurRadius: 8.0,
                color: color,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(0, 48),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }



  Widget _buildSubmissionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        border: Border.all(color: Colors.orange, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Submitting score...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_submissionResult) {
      case ScoreSubmissionResult.success:
        return Colors.green;
      case ScoreSubmissionResult.queued:
        return Colors.orange;
      case ScoreSubmissionResult.failed:
      case ScoreSubmissionResult.networkError:
        return Colors.red;
      case ScoreSubmissionResult.invalidScore:
        return Colors.orange;
      case ScoreSubmissionResult.notAuthenticated:
        return Colors.blue;
      case ScoreSubmissionResult.notBestScore:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _shareScore() {
    if (widget.achievementManager != null) {
      final isNewHighScore = widget.finalScore == widget.highScore && widget.finalScore > 0;
      String message = isNewHighScore
          ? 'NEW HIGH SCORE! Just scored ${widget.finalScore} points in Neon Pulse! 🚀✨ Can you beat my cyberpunk bird skills? #NeonPulse #NewRecord'
          : 'Just scored ${widget.finalScore} points in Neon Pulse! 🚀✨ My high score is ${widget.highScore}. Can you beat it? #NeonPulse #Gaming';
      
      // Add leaderboard position if available
      if (_leaderboardPosition != null) {
        message += '\n🏆 Global Rank: #$_leaderboardPosition';
      }
      
      widget.achievementManager!.shareHighScore(
        score: widget.finalScore,
        customMessage: message,
      );
    }
  }


}