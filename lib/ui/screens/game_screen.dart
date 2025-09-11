import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../../game/neon_pulse_game.dart';

/// Game screen that displays the actual game
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late NeonPulseGame game;

  @override
  void initState() {
    super.initState();
    game = NeonPulseGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game widget with tap handling
          GestureDetector(
            onTap: () {
              // Handle tap input for the game
              game.handleTap();
            },
            child: GameWidget<NeonPulseGame>.controlled(
              gameFactory: () => game,
            ),
          ),
          
          // Debug info overlay (can be removed later)
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tap to Jump',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Double-tap for Pulse',
                    style: TextStyle(
                      color: Colors.cyan.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Back button
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close,
                color: Colors.cyan,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}