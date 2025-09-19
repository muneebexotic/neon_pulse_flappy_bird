import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../ui/theme/neon_theme.dart';

/// Utility class for handling network errors gracefully
class NetworkErrorHandler {
  /// Show a user-friendly error message for network issues
  static void showNetworkError(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onRetry,
    bool showOfflineIndicator = true,
  }) {
    final String message = customMessage ?? _getDefaultErrorMessage();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              ConnectivityService.isOffline ? Icons.wifi_off : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: ConnectivityService.isOffline 
            ? NeonTheme.warningOrange 
            : Colors.red,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show a dialog for critical network errors
  static Future<void> showNetworkErrorDialog(
    BuildContext context, {
    String? title,
    String? message,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: NeonTheme.deepSpace,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: NeonTheme.electricBlue.withOpacity(0.3)),
          ),
          title: Row(
            children: [
              Icon(
                ConnectivityService.isOffline ? Icons.wifi_off : Icons.error_outline,
                color: ConnectivityService.isOffline 
                    ? NeonTheme.warningOrange 
                    : Colors.red,
              ),
              const SizedBox(width: 12),
              Text(
                title ?? 'Connection Error',
                style: TextStyle(
                  color: NeonTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message ?? _getDefaultErrorMessage(),
            style: TextStyle(color: NeonTheme.textSecondary),
          ),
          actions: [
            if (onCancel != null)
              TextButton(
                onPressed: onCancel,
                child: Text(
                  'Cancel',
                  style: TextStyle(color: NeonTheme.textSecondary),
                ),
              ),
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeonTheme.electricBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            if (onRetry == null)
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeonTheme.electricBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
          ],
        );
      },
    );
  }

  /// Show a bottom sheet with detailed network information
  static Future<void> showNetworkInfoBottomSheet(BuildContext context) async {
    final queuedOperations = await ConnectivityService.getQueuedOperationsCount();
    
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: NeonTheme.deepSpace,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: NeonTheme.electricBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Network Status',
                    style: TextStyle(
                      color: NeonTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoRow(
                'Connection Status',
                ConnectivityService.getStatusString(),
                ConnectivityService.isOnline 
                    ? NeonTheme.neonGreen 
                    : NeonTheme.warningOrange,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Queued Operations',
                '$queuedOperations',
                queuedOperations > 0 
                    ? NeonTheme.electricBlue 
                    : NeonTheme.textSecondary,
              ),
              const SizedBox(height: 20),
              if (ConnectivityService.isOffline)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NeonTheme.warningOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: NeonTheme.warningOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline Mode',
                        style: TextStyle(
                          color: NeonTheme.warningOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your scores and progress are being saved locally. '
                        'They will be synchronized when you reconnect to the internet.',
                        style: TextStyle(
                          color: NeonTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await ConnectivityService.checkConnectivity();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NeonTheme.electricBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Check Connection'),
                    ),
                  ),
                  if (ConnectivityService.isOnline && queuedOperations > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await ConnectivityService.syncOfflineData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NeonTheme.neonGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Sync Now'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: NeonTheme.textSecondary,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Get default error message based on connectivity status
  static String _getDefaultErrorMessage() {
    if (ConnectivityService.isOffline) {
      return 'You are currently offline. Your progress is being saved locally '
             'and will be synchronized when you reconnect.';
    } else {
      return 'You are currently offline. Your progress is being saved locally '
             'and will be synchronized when you reconnect.';
    }
  }

  /// Handle network operation with automatic error handling
  static Future<T?> handleNetworkOperation<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? errorMessage,
    bool showErrorDialog = false,
    VoidCallback? onRetry,
  }) async {
    try {
      return await operation();
    } catch (e) {
      print('Network operation failed: $e');
      
      if (showErrorDialog) {
        await showNetworkErrorDialog(
          context,
          message: errorMessage,
          onRetry: onRetry,
        );
      } else {
        showNetworkError(
          context,
          customMessage: errorMessage,
          onRetry: onRetry,
        );
      }
      
      return null;
    }
  }

  /// Check if an error is network-related
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('unreachable') ||
           errorString.contains('socket') ||
           errorString.contains('failed to connect') ||
           errorString.contains('no internet') ||
           errorString.contains('connection refused') ||
           errorString.contains('connection timed out');
  }

  /// Get user-friendly error message from exception
  static String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (isNetworkError(error)) {
      return _getDefaultErrorMessage();
    }
    
    // Handle other specific error types
    if (errorString.contains('permission')) {
      return 'Permission denied. Please check your account permissions.';
    } else if (errorString.contains('quota')) {
      return 'Service quota exceeded. Please try again later.';
    } else if (errorString.contains('auth')) {
      return 'Authentication error. Please sign in again.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }
}