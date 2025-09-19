import 'package:flutter/material.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_cache_service.dart';
import '../theme/neon_theme.dart';

/// Widget that displays connectivity status and offline indicators
class ConnectivityIndicator extends StatefulWidget {
  final bool showWhenOnline;
  final bool showQueuedOperations;
  final EdgeInsets padding;

  const ConnectivityIndicator({
    super.key,
    this.showWhenOnline = false,
    this.showQueuedOperations = true,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  State<ConnectivityIndicator> createState() => _ConnectivityIndicatorState();
}

class _ConnectivityIndicatorState extends State<ConnectivityIndicator> {
  ConnectivityStatus _status = ConnectivityStatus.unknown;
  int _queuedOperations = 0;
  bool _hasCachedData = false;

  @override
  void initState() {
    super.initState();
    _initializeStatus();
    _listenToConnectivityChanges();
  }

  void _initializeStatus() async {
    _status = ConnectivityService.status;
    _queuedOperations = await ConnectivityService.getQueuedOperationsCount();
    _hasCachedData = await OfflineCacheService.hasCachedLeaderboardData();
    
    if (mounted) {
      setState(() {});
    }
  }

  void _listenToConnectivityChanges() {
    ConnectivityService.statusStream.listen((status) async {
      _status = status;
      _queuedOperations = await ConnectivityService.getQueuedOperationsCount();
      _hasCachedData = await OfflineCacheService.hasCachedLeaderboardData();
      
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if online and showWhenOnline is false
    if (_status == ConnectivityStatus.online && !widget.showWhenOnline) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIndicator(),
          if (widget.showQueuedOperations && _queuedOperations > 0)
            const SizedBox(height: 4),
          if (widget.showQueuedOperations && _queuedOperations > 0)
            _buildQueuedOperationsIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    IconData icon;
    Color color;
    String text;

    switch (_status) {
      case ConnectivityStatus.online:
        icon = Icons.wifi;
        color = NeonTheme.neonGreen;
        text = 'Online';
        break;
      case ConnectivityStatus.offline:
        icon = Icons.wifi_off;
        color = NeonTheme.warningOrange;
        text = _hasCachedData ? 'Offline (Cached data available)' : 'Offline';
        break;
      case ConnectivityStatus.unknown:
        icon = Icons.help_outline;
        color = Colors.grey;
        text = 'Connection status unknown';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueuedOperationsIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: NeonTheme.electricBlue.withOpacity(0.1),
        border: Border.all(color: NeonTheme.electricBlue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sync,
            size: 14,
            color: NeonTheme.electricBlue,
          ),
          const SizedBox(width: 4),
          Text(
            '$_queuedOperations queued',
            style: TextStyle(
              color: NeonTheme.electricBlue,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple connectivity status badge for minimal UI space
class ConnectivityBadge extends StatefulWidget {
  final double size;

  const ConnectivityBadge({
    super.key,
    this.size = 20,
  });

  @override
  State<ConnectivityBadge> createState() => _ConnectivityBadgeState();
}

class _ConnectivityBadgeState extends State<ConnectivityBadge> {
  ConnectivityStatus _status = ConnectivityStatus.unknown;

  @override
  void initState() {
    super.initState();
    _status = ConnectivityService.status;
    _listenToConnectivityChanges();
  }

  void _listenToConnectivityChanges() {
    ConnectivityService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _status = status;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_status == ConnectivityStatus.online) {
      return const SizedBox.shrink();
    }

    IconData icon;
    Color color;

    switch (_status) {
      case ConnectivityStatus.offline:
        icon = Icons.wifi_off;
        color = NeonTheme.warningOrange;
        break;
      case ConnectivityStatus.unknown:
        icon = Icons.help_outline;
        color = Colors.grey;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Icon(
        icon,
        size: widget.size * 0.6,
        color: color,
      ),
    );
  }
}

/// Connectivity status banner for full-width notifications
class ConnectivityBanner extends StatefulWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onSync;

  const ConnectivityBanner({
    super.key,
    this.onRetry,
    this.onSync,
  });

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  ConnectivityStatus _status = ConnectivityStatus.unknown;
  int _queuedOperations = 0;

  @override
  void initState() {
    super.initState();
    _initializeStatus();
    _listenToConnectivityChanges();
  }

  void _initializeStatus() async {
    _status = ConnectivityService.status;
    _queuedOperations = await ConnectivityService.getQueuedOperationsCount();
    
    if (mounted) {
      setState(() {});
    }
  }

  void _listenToConnectivityChanges() {
    ConnectivityService.statusStream.listen((status) async {
      _status = status;
      _queuedOperations = await ConnectivityService.getQueuedOperationsCount();
      
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_status == ConnectivityStatus.online && _queuedOperations == 0) {
      return const SizedBox.shrink();
    }

    Color backgroundColor;
    Color textColor;
    String message;
    List<Widget> actions = [];

    if (_status == ConnectivityStatus.offline) {
      backgroundColor = NeonTheme.warningOrange.withOpacity(0.1);
      textColor = NeonTheme.warningOrange;
      message = _queuedOperations > 0 
          ? 'Offline - $_queuedOperations operations queued'
          : 'You are currently offline';
      
      if (widget.onRetry != null) {
        actions.add(
          TextButton(
            onPressed: widget.onRetry,
            child: Text(
              'Retry',
              style: TextStyle(color: textColor),
            ),
          ),
        );
      }
    } else if (_queuedOperations > 0) {
      backgroundColor = NeonTheme.electricBlue.withOpacity(0.1);
      textColor = NeonTheme.electricBlue;
      message = '$_queuedOperations operations pending sync';
      
      if (widget.onSync != null) {
        actions.add(
          TextButton(
            onPressed: widget.onSync,
            child: Text(
              'Sync Now',
              style: TextStyle(color: textColor),
            ),
          ),
        );
      }
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: textColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _status == ConnectivityStatus.offline ? Icons.wifi_off : Icons.sync,
            color: textColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}