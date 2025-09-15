import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

class NeonPulseFlappyBirdApp extends StatelessWidget {
  const NeonPulseFlappyBirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Pulse Flappy Bird',
      debugShowCheckedModeBanner: false,
      theme: _buildNeonTheme(),
      home: const SplashScreen(),
    );
  }

  ThemeData _buildNeonTheme() {
    return ThemeData(
      // Cyberpunk color scheme
      primarySwatch: Colors.cyan,
      scaffoldBackgroundColor: const Color(0xFF0B0B1F),
      fontFamily: 'monospace', // Will be replaced with Orbitron later
      
      // Enhanced text theme with consistent neon styling
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Colors.cyan,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 10.0,
              color: Colors.cyan,
              offset: Offset(0, 0),
            ),
            Shadow(
              blurRadius: 20.0,
              color: Colors.cyan,
              offset: Offset(0, 0),
            ),
          ],
        ),
        displayMedium: TextStyle(
          color: Colors.cyan,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              blurRadius: 8.0,
              color: Colors.cyan,
              offset: Offset(0, 0),
            ),
          ],
        ),
        headlineLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 5.0,
              color: Colors.white,
              offset: Offset(0, 0),
            ),
          ],
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          color: Colors.cyan,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      
      // Enhanced button theme with neon effects
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.cyan,
          side: const BorderSide(color: Colors.cyan, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          shadowColor: Colors.cyan.withOpacity(0.5),
          elevation: 8,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Card theme for consistent styling
      cardTheme: CardThemeData(
        color: const Color(0xFF1A0B2E).withOpacity(0.8),
        shadowColor: Colors.cyan.withOpacity(0.3),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.cyan.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      
      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.cyan,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 10.0,
              color: Colors.cyan,
              offset: Offset(0, 0),
            ),
          ],
        ),
        iconTheme: IconThemeData(
          color: Colors.cyan,
        ),
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: Colors.cyan,
        size: 24,
      ),
      
      // Slider theme for settings
      sliderTheme: SliderThemeData(
        activeTrackColor: Colors.cyan,
        inactiveTrackColor: Colors.cyan.withOpacity(0.3),
        thumbColor: Colors.cyan,
        overlayColor: Colors.cyan.withOpacity(0.2),
        valueIndicatorColor: Colors.cyan,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.cyan;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.cyan.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.3);
        }),
      ),
      
      // Page transitions theme
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}