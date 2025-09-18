import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    } catch (e) {
      print('Failed to enable Firestore persistence: $e');
    }
  }

  /// Check if device is online and Firebase is available
  static bool get isOnline => _initialized && _firestore != null;
}