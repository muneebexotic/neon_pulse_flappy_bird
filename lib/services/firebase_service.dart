import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'connectivity_service.dart';

/// Service class for Firebase initialization and configuration
class FirebaseService {
  static FirebaseFirestore? _firestore;
  static bool _initialized = false;

  /// Check if Firebase is initialized and available
  static bool get isInitialized => _initialized;

  /// Get Firestore instance (null if not initialized)
  static FirebaseFirestore? get firestore => _firestore;

  /// Initialize Firebase services
  static Future<bool> initialize() async {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
        _initialized = true;
        return true;
      }
      
      // Firebase not initialized - app will work in offline mode
      return false;
    } catch (e) {
      print('Firebase service initialization failed: $e');
      return false;
    }
  }

  /// Configure Firestore settings
  static Future<void> configureFirestore() async {
    if (_firestore == null) return;

    try {
      // Enable offline persistence
      await _firestore!.enablePersistence();
      
      // Configure cache settings for better offline support
      final settings = Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      _firestore!.settings = settings;
      
      print('Firestore configured with offline persistence');
    } catch (e) {
      print('Failed to enable Firestore persistence: $e');
    }
  }

  /// Check if device is online and Firebase is available
  static bool get isOnline => _initialized && _firestore != null && ConnectivityService.isOnline;

  /// Check if Firebase is available but device might be offline
  static bool get isAvailable => _initialized && _firestore != null;

  /// Perform a network operation with retry mechanism
  static Future<T?> performNetworkOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    if (!isOnline) {
      print('Device is offline - operation will be queued');
      return null;
    }

    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        print('Network operation failed (attempt $attempts/$maxRetries): $e');
        
        if (attempts >= maxRetries) {
          print('Max retries reached - operation failed');
          return null;
        }
        
        // Wait before retrying
        await Future.delayed(retryDelay);
        
        // Check if we're still online before retrying
        if (!ConnectivityService.isOnline) {
          print('Device went offline during retry - aborting operation');
          return null;
        }
      }
    }
    
    return null;
  }

  /// Test Firebase connectivity
  static Future<bool> testConnectivity() async {
    if (!isAvailable) {
      return false;
    }

    try {
      // Try to read from a test collection with a timeout
      await _firestore!
          .collection('connectivity_test')
          .limit(1)
          .get()
          .timeout(Duration(seconds: 5));
      return true;
    } catch (e) {
      print('Firebase connectivity test failed: $e');
      return false;
    }
  }
}