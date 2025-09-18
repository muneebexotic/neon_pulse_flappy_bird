import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

/// Helper class for testing Firebase connectivity
class FirebaseTestHelper {
  /// Test basic Firestore connectivity
  static Future<bool> testFirestoreConnection() async {
    try {
      if (!FirebaseService.isOnline) {
        print('Firebase is not initialized or offline');
        return false;
      }

      // Try to read from a test collection
      final testDoc = await FirebaseService.firestore!
          .collection('test')
          .doc('connection')
          .get();

      print('Firestore connection test successful');
      print('Test document exists: ${testDoc.exists}');
      
      return true;
    } catch (e) {
      print('Firestore connection test failed: $e');
      return false;
    }
  }

  /// Test writing to Firestore (requires authentication for real collections)
  static Future<bool> testFirestoreWrite() async {
    try {
      if (!FirebaseService.isOnline) {
        print('Firebase is not initialized or offline');
        return false;
      }

      // Write a test document
      await FirebaseService.firestore!
          .collection('test')
          .doc('write_test')
          .set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Test write successful',
        'app_version': '1.0.0',
      });

      print('Firestore write test successful');
      return true;
    } catch (e) {
      print('Firestore write test failed: $e');
      return false;
    }
  }

  /// Run all Firebase tests
  static Future<void> runAllTests() async {
    print('=== Firebase Connection Tests ===');
    
    print('\n1. Testing Firebase initialization...');
    if (FirebaseService.isInitialized) {
      print('✅ Firebase is initialized');
    } else {
      print('❌ Firebase is not initialized');
      return;
    }

    print('\n2. Testing Firestore connection...');
    final connectionTest = await testFirestoreConnection();
    if (connectionTest) {
      print('✅ Firestore connection successful');
    } else {
      print('❌ Firestore connection failed');
    }

    print('\n3. Testing Firestore write...');
    final writeTest = await testFirestoreWrite();
    if (writeTest) {
      print('✅ Firestore write successful');
    } else {
      print('❌ Firestore write failed');
    }

    print('\n=== Test Summary ===');
    print('Firebase initialized: ${FirebaseService.isInitialized ? "✅" : "❌"}');
    print('Firestore connection: ${connectionTest ? "✅" : "❌"}');
    print('Firestore write: ${writeTest ? "✅" : "❌"}');
    
    if (FirebaseService.isInitialized && connectionTest && writeTest) {
      print('\n🎉 All Firebase tests passed! Your setup is working correctly.');
    } else {
      print('\n⚠️  Some tests failed. Check the setup instructions.');
    }
  }
}