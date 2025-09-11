# Neon Pulse Flappy Bird

A cyberpunk-themed Flappy Bird game with neon effects and pulse mechanics built with Flutter and Flame.

## Features

- Cyberpunk aesthetic with neon visual effects
- Energy pulse mechanic to disable obstacles
- Beat-synchronized gameplay
- Progressive difficulty system
- Power-up system
- Bird customization and progression
- Particle effects and dynamic backgrounds

## Project Structure

```
lib/
├── game/           # Game engine components (Flame)
├── models/         # Data models and game state
├── ui/             # Flutter UI components
│   └── screens/    # App screens
└── main.dart       # App entry point

assets/
├── images/         # Game sprites and images
├── audio/          # Music and sound effects
└── fonts/          # Custom fonts
```

## Dependencies

- **flame**: Game engine for Flutter
- **audioplayers**: Audio playback and beat detection
- **shared_preferences**: Local storage for scores and settings
- **flutter_animate**: Advanced animations
- **vector_math**: Mathematical operations for game physics

## Getting Started

1. Ensure Flutter is installed and configured
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

## Development

This project follows a spec-driven development approach. See `.kiro/specs/neon-pulse-flappy-bird/` for detailed requirements, design, and implementation tasks.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
