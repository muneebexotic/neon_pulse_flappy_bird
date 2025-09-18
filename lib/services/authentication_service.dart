import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_models;
import 'firebase_service.dart';

/// Service class for handling user authentication
class AuthenticationService {
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Get current user
  static firebase_auth.User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  static bool get isSignedIn => currentUser != null;

  /// Check if user is guest (anonymous)
  static bool get isGuest => currentUser?.isAnonymous ?? true;

  /// Stream of authentication state changes
  static Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google
  static Future<app_models.User?> signInWithGoogle() async {
    try {
      if (!FirebaseService.isInitialized) {
        throw Exception('Firebase not initialized');
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final firebase_auth.UserCredential userCredential = await _auth.signInWithCredential(credential);
      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Create app user model
        final appUser = app_models.User(
          uid: firebaseUser.uid,
          displayName: firebaseUser.displayName ?? 'Player',
          email: firebaseUser.email ?? '',
          photoURL: firebaseUser.photoURL,
          isGuest: false,
          lastSignIn: DateTime.now(),
          gameStats: app_models.UserGameStats(),
        );

        // Save user profile to Firestore
        await _saveUserProfile(appUser);

        return appUser;
      }

      return null;
    } catch (e) {
      print('Google sign-in failed: $e');
      return null;
    }
  }

  /// Sign in as guest (anonymous)
  static Future<app_models.User?> signInAsGuest() async {
    try {
      if (!FirebaseService.isInitialized) {
        // Create offline guest user
        return app_models.User(
          uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
          displayName: 'Guest Player',
          email: '',
          photoURL: null,
          isGuest: true,
          lastSignIn: DateTime.now(),
          gameStats: app_models.UserGameStats(),
        );
      }

      final firebase_auth.UserCredential userCredential = await _auth.signInAnonymously();
      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        return app_models.User(
          uid: firebaseUser.uid,
          displayName: 'Guest Player',
          email: '',
          photoURL: null,
          isGuest: true,
          lastSignIn: DateTime.now(),
          gameStats: app_models.UserGameStats(),
        );
      }

      return null;
    } catch (e) {
      print('Guest sign-in failed: $e');
      // Return offline guest user as fallback
      return app_models.User(
        uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Guest Player',
        email: '',
        photoURL: null,
        isGuest: true,
        lastSignIn: DateTime.now(),
        gameStats: app_models.UserGameStats(),
      );
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      if (FirebaseService.isInitialized) {
        await _googleSignIn.signOut();
        await _auth.signOut();
      }
    } catch (e) {
      print('Sign out failed: $e');
    }
  }

  /// Convert guest account to Google account
  static Future<app_models.User?> upgradeGuestToGoogle() async {
    try {
      if (!FirebaseService.isInitialized || currentUser == null || !currentUser!.isAnonymous) {
        return null;
      }

      // Trigger Google sign-in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link the anonymous account with Google credential
      final firebase_auth.UserCredential userCredential = await currentUser!.linkWithCredential(credential);
      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final appUser = app_models.User(
          uid: firebaseUser.uid,
          displayName: firebaseUser.displayName ?? 'Player',
          email: firebaseUser.email ?? '',
          photoURL: firebaseUser.photoURL,
          isGuest: false,
          lastSignIn: DateTime.now(),
          gameStats: app_models.UserGameStats(),
        );

        await _saveUserProfile(appUser);
        return appUser;
      }

      return null;
    } catch (e) {
      print('Account upgrade failed: $e');
      return null;
    }
  }

  /// Save user profile to Firestore
  static Future<void> _saveUserProfile(app_models.User user) async {
    try {
      if (!FirebaseService.isOnline) return;

      await FirebaseService.firestore!
          .collection('users')
          .doc(user.uid)
          .set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      print('Failed to save user profile: $e');
    }
  }

  /// Load user profile from Firestore
  static Future<app_models.User?> loadUserProfile(String uid) async {
    try {
      if (!FirebaseService.isOnline) return null;

      final doc = await FirebaseService.firestore!
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return app_models.User.fromJson(doc.data()!);
      }

      return null;
    } catch (e) {
      print('Failed to load user profile: $e');
      return null;
    }
  }
}