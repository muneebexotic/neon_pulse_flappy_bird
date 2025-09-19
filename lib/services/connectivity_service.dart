import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';
import 'leaderboard_service.dart';

/// Enum for connectivity status
enum ConnectivityStatus {
  online,
  offline,
  unknown,
}

/// Service class for managing network connectivity and offline support
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static ConnectivityStatus _status = ConnectivityStatus.unknown;
  static StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  static final StreamController<ConnectivityStatus> _statusController = 
      StreamController<ConnectivityStatus>.broadcast();

  /// Current connectivity status
  static ConnectivityStatus get status => _status;

  /// Stream of connectivity status changes
  static Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Check if device is currently online
  static bool get isOnline => _status == ConnectivityStatus.online;

  /// Check if device is currently offline
  static bool get isOffline => _status == ConnectivityStatus.offline;

  /// Initialize connectivity monitoring
  static Future<void> initialize() async {
    try {
      // Check initial connectivity status
      await _updateConnectivityStatus();

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (ConnectivityResult result) async {
          await _updateConnectivityStatus();
        },
      );

      print('Connectivity service initialized. Status: $_status');
    } catch (e) {
      print('Failed to initialize connectivity service: $e');
      _status = ConnectivityStatus.unknown;
      _statusController.add(_status);
    }
  }

  /// Update connectivity status based on current network state
  static Future<void> _updateConnectivityStatus() async {
    try {
      final ConnectivityResult connectivityResult = 
          await _connectivity.checkConnectivity();
      
      final bool hasConnection = connectivityResult != ConnectivityResult.none;

      final ConnectivityStatus newStatus = hasConnection 
          ? ConnectivityStatus.online 
          : ConnectivityStatus.offline;

      if (newStatus != _status) {
        final ConnectivityStatus previousStatus = _status;
        _status = newStatus;
        _statusController.add(_status);

        print('Connectivity status changed: $previousStatus -> $_status');

        // Handle connectivity restoration
        if (previousStatus == ConnectivityStatus.offline && 
            newStatus == ConnectivityStatus.online) {
          await _onConnectivityRestored();
        }
      }
    } catch (e) {
      print('Error updating connectivity status: $e');
      _status = ConnectivityStatus.unknown;
      _statusController.add(_status);
    }
  }

  /// Handle connectivity restoration - sync offline data
  static Future<void> _onConnectivityRestored() async {
    try {
      print('Connectivity restored - starting background sync');
      
      // Process queued leaderboard scores
      await LeaderboardService.processOfflineScores();
      
      // Process any other queued operations
      await _processQueuedOperations();
      
      print('Background sync completed');
    } catch (e) {
      print('Error during connectivity restoration sync: $e');
    }
  }

  /// Process any queued operations that were stored while offline
  static Future<void> _processQueuedOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Process queued authentication operations
      await _processQueuedAuthOperations(prefs);
      
      // Process queued user profile updates
      await _processQueuedProfileUpdates(prefs);
      
    } catch (e) {
      print('Error processing queued operations: $e');
    }
  }

  /// Process queued authentication operations
  static Future<void> _processQueuedAuthOperations(SharedPreferences prefs) async {
    try {
      final queuedAuthJson = prefs.getString('queued_auth_operations');
      if (queuedAuthJson == null) return;

      final queuedOperations = jsonDecode(queuedAuthJson) as List;
      if (queuedOperations.isEmpty) return;

      final failedOperations = <Map<String, dynamic>>[];

      for (final operation in queuedOperations) {
        try {
          final operationType = operation['type'] as String?;
          
          switch (operationType) {
            case 'profile_update':
              // Handle profile update operations
              print('Processing queued profile update');
              break;
            case 'settings_sync':
              // Handle settings synchronization
              print('Processing queued settings sync');
              break;
            default:
              print('Unknown queued operation type: $operationType');
          }
        } catch (e) {
          print('Failed to process queued auth operation: $e');
          failedOperations.add(operation);
        }
      }

      // Update queue with failed operations
      await prefs.setString('queued_auth_operations', jsonEncode(failedOperations));
    } catch (e) {
      print('Error processing queued auth operations: $e');
    }
  }

  /// Process queued profile updates
  static Future<void> _processQueuedProfileUpdates(SharedPreferences prefs) async {
    try {
      final queuedUpdatesJson = prefs.getString('queued_profile_updates');
      if (queuedUpdatesJson == null) return;

      final queuedUpdates = jsonDecode(queuedUpdatesJson) as List;
      if (queuedUpdates.isEmpty) return;

      final failedUpdates = <Map<String, dynamic>>[];

      for (final update in queuedUpdates) {
        try {
          // Process profile update
          print('Processing queued profile update: ${update['type']}');
          // Implementation would depend on specific profile update types
        } catch (e) {
          print('Failed to process queued profile update: $e');
          failedUpdates.add(update);
        }
      }

      // Update queue with failed updates
      await prefs.setString('queued_profile_updates', jsonEncode(failedUpdates));
    } catch (e) {
      print('Error processing queued profile updates: $e');
    }
  }

  /// Queue an operation for later execution when connectivity is restored
  static Future<void> queueOperation({
    required String type,
    required Map<String, dynamic> data,
    String queueKey = 'queued_operations',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queuedOperationsJson = prefs.getString(queueKey) ?? '[]';
      final queuedOperations = jsonDecode(queuedOperationsJson) as List;

      // Add new operation to queue
      queuedOperations.add({
        'type': type,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Keep only the latest 100 operations to prevent storage bloat
      if (queuedOperations.length > 100) {
        queuedOperations.removeRange(0, queuedOperations.length - 100);
      }

      // Save back to storage
      await prefs.setString(queueKey, jsonEncode(queuedOperations));
      print('Operation queued for later execution: $type');
    } catch (e) {
      print('Error queuing operation: $e');
    }
  }

  /// Get the number of queued operations
  static Future<int> getQueuedOperationsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Count leaderboard scores
      final scoresJson = prefs.getString('queued_leaderboard_scores') ?? '[]';
      final scores = jsonDecode(scoresJson) as List;
      
      // Count other operations
      final operationsJson = prefs.getString('queued_operations') ?? '[]';
      final operations = jsonDecode(operationsJson) as List;
      
      // Count auth operations
      final authJson = prefs.getString('queued_auth_operations') ?? '[]';
      final authOps = jsonDecode(authJson) as List;
      
      // Count profile updates
      final profileJson = prefs.getString('queued_profile_updates') ?? '[]';
      final profileOps = jsonDecode(profileJson) as List;
      
      return scores.length + operations.length + authOps.length + profileOps.length;
    } catch (e) {
      print('Error getting queued operations count: $e');
      return 0;
    }
  }

  /// Clear all queued operations (use with caution)
  static Future<void> clearQueuedOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('queued_leaderboard_scores');
      await prefs.remove('queued_operations');
      await prefs.remove('queued_auth_operations');
      await prefs.remove('queued_profile_updates');
      print('All queued operations cleared');
    } catch (e) {
      print('Error clearing queued operations: $e');
    }
  }

  /// Manually trigger connectivity check
  static Future<void> checkConnectivity() async {
    await _updateConnectivityStatus();
  }

  /// Manually trigger sync of offline data
  static Future<void> syncOfflineData() async {
    if (isOnline) {
      await _onConnectivityRestored();
    } else {
      print('Cannot sync offline data - device is offline');
    }
  }

  /// Get connectivity status as a human-readable string
  static String getStatusString() {
    switch (_status) {
      case ConnectivityStatus.online:
        return 'Online';
      case ConnectivityStatus.offline:
        return 'Offline';
      case ConnectivityStatus.unknown:
        return 'Unknown';
    }
  }

  /// Dispose of resources
  static Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _statusController.close();
  }
}