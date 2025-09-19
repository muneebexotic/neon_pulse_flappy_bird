import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/leaderboard_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_cache_service.dart';
import '../../providers/authentication_provider.dart';
import '../../utils/network_error_handler.dart';
import '../components/connectivity_indicator.dart';
import '../utils/animation_config.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  LeaderboardData? _leaderboardData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isUsingCachedData = false;
  int _cacheAgeMinutes = 0;
  late Stream<List<LeaderboardEntry>> _leaderboardStream;

  @override
  void initState() {
    super.initState();
    _initializeLeaderboard();
  }

  void _initializeLeaderboard() {
    // Set up real-time leaderboard stream
    _leaderboardStream = LeaderboardService.getLeaderboardStream(limit: 100);
    
    // Load initial leaderboard data
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _isUsingCachedData = false;
      });

      final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
      final userId = authProvider.currentUser?.uid;

      // Check if we're offline and have cached data
      if (ConnectivityService.isOffline) {
        final cachedData = await OfflineCacheService.getCachedLeaderboardData();
        if (cachedData != null) {
          final cacheAge = await OfflineCacheService.getCacheAgeMinutes();
          if (mounted) {
            setState(() {
              _leaderboardData = cachedData;
              _isLoading = false;
              _isUsingCachedData = true;
              _cacheAgeMinutes = cacheAge;
            });
          }
          return;
        }
      }

      final leaderboardData = await LeaderboardService.getLeaderboard(
        limit: 100,
        userId: userId,
      );

      if (mounted) {
        setState(() {
          _leaderboardData = leaderboardData;
          _isLoading = false;
          _isUsingCachedData = false;
        });
      }
    } catch (e) {
      // Try to load cached data on error
      final cachedData = await OfflineCacheService.getCachedLeaderboardData();
      if (cachedData != null && mounted) {
        final cacheAge = await OfflineCacheService.getCacheAgeMinutes();
        setState(() {
          _leaderboardData = cachedData;
          _isLoading = false;
          _isUsingCachedData = true;
          _cacheAgeMinutes = cacheAge;
          _errorMessage = 'Using cached data due to connection error';
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = NetworkErrorHandler.getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadLeaderboard();
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
              _buildHeader(),
              Expanded(
                child: _buildLeaderboardContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Connectivity banner
        ConnectivityBanner(
          onRetry: () async {
            await ConnectivityService.checkConnectivity();
            if (ConnectivityService.isOnline) {
              _loadLeaderboard();
            }
          },
          onSync: () async {
            await ConnectivityService.syncOfflineData();
            _loadLeaderboard();
          },
        ),
        
        // Main header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  foregroundColor: Colors.cyan,
                  side: BorderSide(color: Colors.cyan.withOpacity(0.5)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'GLOBAL LEADERBOARD',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 24,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: AnimationConfig.medium.inMilliseconds.ms),
                    
                    // Cache indicator
                    if (_isUsingCachedData)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Cached data (${_cacheAgeMinutes}m ago)',
                          style: TextStyle(
                            color: Colors.orange.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Network status and info button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ConnectivityBadge(size: 24),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => NetworkErrorHandler.showNetworkInfoBottomSheet(context),
                    icon: const Icon(Icons.info_outline),
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.cyan.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _onRefresh,
      color: Colors.cyan,
      backgroundColor: const Color(0xFF1A0B2E),
      child: StreamBuilder<List<LeaderboardEntry>>(
        stream: _leaderboardStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(error: snapshot.error.toString());
          }

          final entries = snapshot.data ?? _leaderboardData?.topScores ?? [];
          
          if (entries.isEmpty) {
            return _buildEmptyState();
          }

          return _buildLeaderboardList(entries);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyan),
              strokeWidth: 3,
            ).animate().scale(
              duration: AnimationConfig.slow.inMilliseconds.ms,
              curve: Curves.easeInOut,
            ).then().scale(
              begin: const Offset(1.2, 1.2),
              end: const Offset(1.0, 1.0),
              duration: AnimationConfig.slow.inMilliseconds.ms,
              curve: Curves.easeInOut,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading leaderboard...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.cyan.withOpacity(0.8),
            ),
          ).animate().fadeIn(delay: AnimationConfig.medium.inMilliseconds.ms),
        ],
      ),
    );
  }

  Widget _buildErrorState({String? error}) {
    final displayError = error ?? _errorMessage ?? 'Unknown error occurred';
    final isNetworkError = NetworkErrorHandler.isNetworkError(displayError);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color: isNetworkError 
                  ? Colors.orange.withOpacity(0.8)
                  : Colors.red.withOpacity(0.8),
            ).animate().scale(duration: AnimationConfig.medium.inMilliseconds.ms),
            const SizedBox(height: 24),
            Text(
              isNetworkError ? 'Connection Error' : 'Failed to Load Leaderboard',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 20,
                color: isNetworkError 
                    ? Colors.orange.withOpacity(0.9)
                    : Colors.red.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: AnimationConfig.fast.inMilliseconds.ms),
            const SizedBox(height: 16),
            Text(
              displayError,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: AnimationConfig.medium.inMilliseconds.ms),
            const SizedBox(height: 32),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadLeaderboard,
                  icon: const Icon(Icons.refresh),
                  label: const Text('RETRY'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                if (isNetworkError) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => NetworkErrorHandler.showNetworkInfoBottomSheet(context),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('INFO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.cyan.withOpacity(0.8),
                      side: BorderSide(color: Colors.cyan.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ],
            ).animate().slideY(
              begin: 0.3,
              duration: AnimationConfig.medium.inMilliseconds.ms,
              delay: AnimationConfig.slow.inMilliseconds.ms,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 64,
              color: Colors.cyan.withOpacity(0.6),
            ).animate().scale(duration: AnimationConfig.medium.inMilliseconds.ms),
            const SizedBox(height: 24),
            Text(
              'No Scores Yet',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 20,
                color: Colors.cyan.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: AnimationConfig.fast.inMilliseconds.ms),
            const SizedBox(height: 16),
            Text(
              'Be the first to set a high score!\nPlay the game and compete with players worldwide.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: AnimationConfig.medium.inMilliseconds.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> entries) {
    final authProvider = Provider.of<AuthenticationProvider>(context);
    final currentUserId = authProvider.currentUser?.uid;

    return Column(
      children: [
        // User's best score section (if available and not in top list)
        if (_leaderboardData?.userBestScore != null && 
            !entries.any((e) => e.userId == currentUserId))
          _buildUserBestScoreCard(),
        
        // Top scores list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isCurrentUser = entry.userId == currentUserId;
              
              return _buildLeaderboardItem(
                entry,
                isCurrentUser: isCurrentUser,
                animationDelay: index * 50, // Stagger animations
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserBestScoreCard() {
    final userBestScore = _leaderboardData!.userBestScore!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Colors.cyan.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Best Score',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.cyan,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              _buildLeaderboardItem(
                userBestScore,
                isCurrentUser: true,
                showCard: false,
              ),
            ],
          ),
        ),
      ),
    ).animate().slideX(
      begin: -0.3,
      duration: AnimationConfig.medium.inMilliseconds.ms,
    );
  }  Widget 
_buildLeaderboardItem(
    LeaderboardEntry entry, {
    bool isCurrentUser = false,
    bool showCard = true,
    int animationDelay = 0,
  }) {
    final rankColor = _getRankColor(entry.rank);
    final isTopThree = entry.rank <= 3;
    
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Rank with special styling for top 3
          _buildRankWidget(entry.rank, rankColor, isTopThree),
          const SizedBox(width: 16),
          
          // Player avatar
          _buildPlayerAvatar(entry.photoURL, isCurrentUser),
          const SizedBox(width: 12),
          
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.playerName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                    color: isCurrentUser ? Colors.cyan : Colors.white,
                    shadows: isCurrentUser ? [
                      const Shadow(
                        blurRadius: 8.0,
                        color: Colors.cyan,
                        offset: Offset(0, 0),
                      ),
                    ] : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimestamp(entry.timestamp),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          
          // Score with neon effect
          _buildScoreWidget(entry.score, isCurrentUser, isTopThree),
        ],
      ),
    );

    if (showCard) {
      content = Card(
        color: isCurrentUser 
            ? Colors.cyan.withOpacity(0.1)
            : const Color(0xFF1A0B2E).withOpacity(0.6),
        elevation: isCurrentUser ? 12 : 4,
        shadowColor: isCurrentUser 
            ? Colors.cyan.withOpacity(0.3)
            : Colors.black.withOpacity(0.3),
        child: content,
      );
    }

    // Add special glow effect for top 3
    if (isTopThree && showCard) {
      content = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: rankColor.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: content,
      );
    }

    return content.animate().slideX(
      begin: 0.3,
      duration: AnimationConfig.medium.inMilliseconds.ms,
      delay: animationDelay.ms,
    ).fadeIn(
      duration: AnimationConfig.medium.inMilliseconds.ms,
      delay: animationDelay.ms,
    );
  }

  Widget _buildRankWidget(int rank, Color rankColor, bool isTopThree) {
    if (isTopThree) {
      // Special icons for top 3
      IconData icon;
      switch (rank) {
        case 1:
          icon = Icons.emoji_events; // Trophy
          break;
        case 2:
          icon = Icons.military_tech; // Medal
          break;
        case 3:
          icon = Icons.workspace_premium; // Award
          break;
        default:
          icon = Icons.star;
      }
      
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: rankColor.withOpacity(0.2),
          border: Border.all(color: rankColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: rankColor.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: rankColor,
          size: 20,
        ),
      );
    } else {
      // Regular rank number
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.cyan.withOpacity(0.1),
          border: Border.all(color: Colors.cyan.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            '#$rank',
            style: TextStyle(
              color: Colors.cyan,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildPlayerAvatar(String? photoURL, bool isCurrentUser) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrentUser ? Colors.cyan : Colors.white.withOpacity(0.3),
          width: isCurrentUser ? 2 : 1,
        ),
        boxShadow: isCurrentUser ? [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ] : null,
      ),
      child: ClipOval(
        child: photoURL != null && photoURL.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoURL,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.withOpacity(0.3),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.withOpacity(0.3),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              )
            : Container(
                color: Colors.grey.withOpacity(0.3),
                child: const Icon(
                  Icons.person,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
      ),
    );
  }

  Widget _buildScoreWidget(int score, bool isCurrentUser, bool isTopThree) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isCurrentUser 
            ? Colors.cyan.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        border: Border.all(
          color: isCurrentUser ? Colors.cyan : Colors.white.withOpacity(0.3),
        ),
      ),
      child: Text(
        _formatScore(score),
        style: TextStyle(
          color: isCurrentUser ? Colors.cyan : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isTopThree ? 16 : 14,
          shadows: isCurrentUser || isTopThree ? [
            Shadow(
              blurRadius: 6.0,
              color: isCurrentUser ? Colors.cyan : _getRankColor(1),
              offset: const Offset(0, 0),
            ),
          ] : null,
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.cyan;
    }
  }

  String _formatScore(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    } else {
      return score.toString();
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}