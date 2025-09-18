import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_service.dart';
import 'services/firebase_test_helper.dart';
import 'ui/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
    
    // Initialize Firebase services
    await FirebaseService.initialize();
    await FirebaseService.configureFirestore();
    
    // Optional: Run Firebase tests (uncomment to test your setup)
    // await FirebaseTestHelper.runAllTests();
    
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Continue without Firebase - app will work in offline mode
  }
  
  // Set preferred orientations to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style for immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const NeonPulseFlappyBirdApp());
}