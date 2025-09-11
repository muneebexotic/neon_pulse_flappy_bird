import 'package:flutter/material.dart';
import 'screens/main_menu_screen.dart';

class NeonPulseFlappyBirdApp extends StatelessWidget {
  const NeonPulseFlappyBirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Pulse Flappy Bird',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Cyberpunk color scheme
        primarySwatch: Colors.cyan,
        scaffoldBackgroundColor: const Color(0xFF0B0B1F),
        fontFamily: 'monospace', // Will be replaced with Orbitron later
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
            ],
          ),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.cyan,
            side: const BorderSide(color: Colors.cyan, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}