# Neon Pulse Flappy Bird

A cyberpunk-themed Flappy Bird game with stunning neon effects, energy pulse mechanics, and beat-synchronized gameplay built with Flutter and Flame.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-blue.svg)
![Flame](https://img.shields.io/badge/Flame-1.32.0-orange.svg)
![License](https://img.shields.io/badge/license-Private-red.svg)

## 🎮 Game Overview

Neon Pulse reimagines the classic Flappy Bird mechanics within a vibrant cyberpunk universe. Navigate through digital barriers and laser grids while using energy pulses to temporarily disable obstacles. The game features dynamic difficulty scaling, power-ups, customizable bird skins, and beat-synchronized gameplay that responds to the background music.

### 🌟 Key Features

- **Cyberpunk Aesthetic**: Dark backgrounds with vibrant neon colors (electric blue, hot pink, neon green)
- **Energy Pulse Mechanic**: Double-tap to emit energy pulses that disable obstacles for 2 seconds
- **Beat Synchronization**: Obstacles spawn in sync with background music beats
- **Progressive Difficulty**: Game speed and complexity increase with score
- **Power-up System**: Shield, Score Multiplier, and Slow Motion power-ups
- **Bird Customization**: Unlockable skins with unique particle trail effects
- **Dynamic Backgrounds**: Animated cyberpunk cityscape with parallax scrolling
- **Accessibility Features**: Haptic feedback, high contrast mode, color-blind support
- **Performance Optimization**: Adaptive quality based on device capabilities

## 🏗️ Project Structure

```
neon_pulse_flappy_bird/
├── lib/                              # Main source code
│   ├── game/                         # Game engine components (Flame)
│   │   ├── components/               # Game objects and entities
│   │   │   ├── bird.dart            # Player-controlled bird with physics
│   │   │   ├── obstacle.dart        # Base obstacle class
│   │   │   ├── digital_barrier.dart # Basic vertical obstacles
│   │   │   ├── laser_grid.dart      # Horizontal laser obstacles
│   │   │   ├── floating_platform.dart # Moving platform obstacles
│   │   │   ├── power_up.dart        # Collectible power-ups
│   │   │   ├── pulse_effect.dart    # Energy pulse visualization
│   │   │   ├── cyberpunk_background.dart # Animated background system
│   │   │   ├── beat_visualizer.dart # Beat sync visual indicators
│   │   │   └── rhythm_feedback.dart # Beat accuracy feedback
│   │   ├── effects/                  # Visual effects and rendering
│   │   │   ├── particle_system.dart # Particle effects engine
│   │   │   ├── neon_painter.dart    # Custom neon glow effects
│   │   │   ├── neon_colors.dart     # Color palette definitions
│   │   │   ├── skin_trail_effects.dart # Bird skin trail effects
│   │   │   └── effects.dart         # Effect utilities
│   │   ├── managers/                 # Game system managers
│   │   │   ├── audio_manager.dart   # Music and sound effects
│   │   │   ├── obstacle_manager.dart # Obstacle spawning and management
│   │   │   ├── power_up_manager.dart # Power-up system
│   │   │   ├── pulse_manager.dart   # Energy pulse mechanics
│   │   │   ├── difficulty_manager.dart # Progressive difficulty
│   │   │   ├── customization_manager.dart # Bird skins and unlocks
│   │   │   ├── achievement_manager.dart # Achievement system
│   │   │   ├── settings_manager.dart # Game settings persistence
│   │   │   ├── accessibility_manager.dart # Accessibility features
│   │   │   ├── haptic_manager.dart  # Haptic feedback and vibration
│   │   │   └── adaptive_quality_manager.dart # Performance optimization
│   │   ├── utils/                    # Utility classes
│   │   │   ├── object_pool.dart     # Object pooling for performance
│   │   │   ├── performance_monitor.dart # FPS and memory monitoring
│   │   │   └── performance_test_suite.dart # Performance testing
│   │   ├── input_handler.dart       # Input processing (tap, double-tap)
│   │   └── neon_pulse_game.dart     # Main game class
│   ├── models/                       # Data models and state
│   │   ├── game_state.dart          # Game state management
│   │   ├── bird_skin.dart           # Bird customization data
│   │   └── achievement.dart         # Achievement definitions
│   ├── ui/                           # Flutter UI components
│   │   ├── screens/                  # Application screens
│   │   │   ├── splash_screen.dart   # App startup screen
│   │   │   ├── main_menu_screen.dart # Main menu with neon styling
│   │   │   ├── game_screen.dart     # Gameplay screen
│   │   │   ├── game_over_screen.dart # Game over and restart
│   │   │   ├── settings_screen.dart # Settings and preferences
│   │   │   ├── customization_screen.dart # Bird skin selection
│   │   │   ├── achievements_screen.dart # Achievement display
│   │   │   └── performance_screen.dart # Performance monitoring
│   │   ├── components/               # Reusable UI components
│   │   │   ├── neon_button.dart     # Cyberpunk-styled buttons
│   │   │   ├── game_hud.dart        # In-game UI overlay
│   │   │   ├── pause_overlay.dart   # Pause menu
│   │   │   ├── achievement_notification.dart # Achievement popups
│   │   │   ├── visual_metronome.dart # Beat visualization
│   │   │   ├── beat_prediction_display.dart # Beat timing display
│   │   │   ├── beat_sync_bonus.dart # Beat sync score bonus
│   │   │   ├── audio_settings.dart  # Audio controls
│   │   │   ├── graphics_settings.dart # Graphics quality settings
│   │   │   ├── accessibility_settings.dart # Accessibility options
│   │   │   ├── control_settings.dart # Input customization
│   │   │   ├── difficulty_settings.dart # Difficulty selection
│   │   │   └── performance_settings.dart # Performance options
│   │   ├── theme/                    # App theming
│   │   │   ├── neon_theme.dart      # Main cyberpunk theme
│   │   │   └── accessibility_theme.dart # Accessibility theme variants
│   │   ├── utils/                    # UI utilities
│   │   │   ├── animation_config.dart # Animation configurations
│   │   │   ├── asset_preloader.dart # Asset loading management
│   │   │   ├── startup_sequence_manager.dart # App startup flow
│   │   │   └── transition_manager.dart # Screen transitions
│   │   └── app.dart                  # Main app widget
│   └── main.dart                     # Application entry point
├── assets/                           # Game assets
│   ├── audio/                        # Audio files
│   │   ├── music/                    # Background music tracks
│   │   └── sfx/                      # Sound effects
│   ├── images/                       # Sprites and textures
│   ├── icons/                        # App icons and UI icons
│   └── fonts/                        # Custom fonts (Orbitron, etc.)
├── test/                             # Unit and integration tests
│   ├── bird_test.dart               # Bird physics tests
│   ├── obstacle_test.dart           # Collision detection tests
│   ├── pulse_mechanic_test.dart     # Pulse mechanic tests
│   ├── power_up_test.dart           # Power-up system tests
│   ├── audio_manager_test.dart      # Audio system tests
│   ├── difficulty_manager_test.dart # Difficulty scaling tests
│   ├── game_state_test.dart         # Game state management tests
│   ├── settings_test.dart           # Settings persistence tests
│   ├── customization_test.dart      # Customization system tests
│   ├── accessibility_test.dart      # Accessibility feature tests
│   ├── performance_test.dart        # Performance optimization tests
│   └── integration_test.dart        # Full game integration tests
├── android/                          # Android platform files
├── ios/                              # iOS platform files
├── web/                              # Web platform files
├── windows/                          # Windows platform files
├── linux/                            # Linux platform files
├── macos/                            # macOS platform files
├── build_scripts/                    # Build automation scripts
│   ├── build_release.dart          # Release build script
│   └── optimize_assets.dart        # Asset optimization
├── deployment/                       # Deployment documentation
├── legal/                            # Legal documents
│   ├── privacy_policy.md           # Privacy policy
│   └── terms_of_service.md         # Terms of service
├── store_assets/                     # App store materials
│   ├── google_play_description.md  # Google Play description
│   └── app_store_description.md    # App Store description
├── scripts/                          # Utility scripts
│   ├── generate_icons.py           # Icon generation script
│   ├── generate_icons.sh           # Unix icon script
│   └── generate_icons.bat          # Windows icon script
├── .github/workflows/                # CI/CD workflows
│   ├── ci.yml                      # Continuous integration
│   └── release.yml                 # Release automation
├── pubspec.yaml                      # Flutter dependencies
├── analysis_options.yaml            # Dart analysis configuration
└── README.md                         # This file
```

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: Version 3.8.1 or higher
- **Dart SDK**: Version 3.0.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** for version control

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd neon_pulse_flappy_bird
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android
- Minimum SDK: API 21 (Android 5.0)
- Target SDK: API 34 (Android 14)
- Requires permissions: VIBRATE, INTERNET (for sharing)

#### iOS
- Minimum iOS version: 12.0
- Requires Xcode 14.0 or later
- Haptic feedback requires iOS device (not simulator)

#### Web
- Supports modern browsers with WebGL
- Audio may have limitations on some browsers
- Haptic feedback not available

## 🎯 Core Gameplay Mechanics

### Basic Controls
- **Tap**: Make the bird jump upward
- **Double-tap**: Activate energy pulse (when charged)
- **Pause**: Tap pause button in top-right corner

### Energy Pulse System
- **Cooldown**: 5 seconds between pulses
- **Effect**: Disables obstacles for 2 seconds
- **Visual Indicator**: Bird glows when pulse is ready
- **Strategy**: Save pulses for difficult obstacle patterns

### Obstacle Types
1. **Digital Barriers**: Basic vertical obstacles with neon glow
2. **Laser Grids**: Horizontal laser beams (introduced at score 20+)
3. **Floating Platforms**: Moving vertical obstacles (introduced at score 40+)

### Power-ups
1. **Shield** (Blue): 3-second invulnerability
2. **Score Multiplier** (Gold): 2x points for 10 seconds
3. **Slow Motion** (Purple): 50% game speed for 5 seconds

### Difficulty Progression
- **Speed Increase**: +5% every 10 points
- **New Obstacles**: Introduced at score milestones
- **Spawn Rate**: Increases with difficulty level
- **Plateau**: Difficulty caps at score 100 to maintain playability

## 🎨 Customization System

### Bird Skins
Unlock new bird appearances by reaching score milestones:
- **Default Neon**: Starting skin with blue trail
- **Plasma Wing**: Score 25+ (pink/purple trail)
- **Cyber Phoenix**: Score 50+ (multi-color trail)
- **Quantum Ghost**: Score 75+ (shifting color trail)
- **Digital Dragon**: Score 100+ (rainbow trail)

### Trail Effects
Each skin has unique particle trail effects:
- Different colors and patterns
- Varying particle density
- Unique glow effects
- Performance-adaptive quality

## 🔧 Technical Implementation

### Dependencies

```yaml
dependencies:
  flutter: sdk
  flame: ^1.32.0              # Game engine
  audioplayers: ^5.0.0        # Audio playback
  shared_preferences: ^2.0.0   # Local storage
  flutter_animate: ^4.0.0     # Advanced animations
  vector_math: ^2.1.0         # Mathematical operations
  share_plus: ^7.2.2          # Social sharing
  screenshot: ^2.1.0          # Screenshot capture
  path_provider: ^2.1.1       # File operations
  vibration: ^3.1.3           # Haptic feedback
```

### Performance Optimizations

#### Object Pooling
- Particles reused from memory pools
- Obstacles recycled when off-screen
- Reduced garbage collection overhead

#### Adaptive Quality
- Automatic quality adjustment based on FPS
- Particle count scaling
- Animation complexity reduction
- Device-specific performance profiles

#### Memory Management
- Efficient texture loading
- Audio file caching
- Background layer optimization
- Automatic cleanup of unused resources

### Audio System

#### Beat Detection
- Real-time audio analysis for BPM detection
- Fallback to 128 BPM when detection fails
- Obstacle spawning synchronized to beats
- Visual beat indicators for player guidance

#### Sound Effects
- **Jump**: Bird wing flap sound
- **Collision**: Impact sound with haptic feedback
- **Pulse**: Energy discharge sound
- **Power-up**: Collection chime
- **Score**: Point increment sound

## ♿ Accessibility Features

### Visual Accessibility
- **High Contrast Mode**: Enhanced visibility
- **Reduced Motion**: Minimized animations
- **Large Text**: 20% larger text size
- **Color Blind Support**: Alternative color palettes for protanopia, deuteranopia, and tritanopia

### Motor Accessibility
- **Haptic Feedback**: Vibration patterns for game events
- **UI Scaling**: 80% to 150% interface scaling
- **Touch Target Size**: Minimum 44dp touch targets
- **Customizable Controls**: Adjustable tap sensitivity

### Audio Accessibility
- **Sound-Based Feedback**: Audio cues for visual elements
- **Volume Controls**: Separate music and SFX volume
- **Subtitle Support**: Visual indicators for audio cues

## 🧪 Testing

### Test Coverage
- **Unit Tests**: Core game logic and physics
- **Integration Tests**: System interactions
- **Performance Tests**: FPS and memory usage
- **Accessibility Tests**: Feature validation

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/bird_test.dart

# Run with coverage
flutter test --coverage
```

### Performance Testing
```bash
# Run performance test suite
flutter test test/performance_test.dart

# Monitor performance in debug mode
flutter run --profile
```

## 📱 Building and Deployment

### Debug Build
```bash
flutter run --debug
```

### Release Build
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Automated Builds
The project includes GitHub Actions workflows for:
- **Continuous Integration**: Automated testing on pull requests
- **Release Builds**: Automated building and deployment
- **Asset Optimization**: Automatic asset compression

## 🎵 Audio Setup

### Current Status
- ✅ Sound effects implemented and working
- ✅ Background music implemented and working
- ✅ Audio system with volume controls
- ✅ Beat detection with fallback
- ✅ Settings synchronization and proper lifecycle management

### Audio Features
- Full background music with fade-in/fade-out effects
- Complete sound effect library (jump, collision, pulse, power-up, score)
- Audio settings respect user preferences across all game states
- Proper audio lifecycle management (pause, resume, app background)
- Synchronized settings between AudioManager and SettingsManager

See [AUDIO_SETUP.md](AUDIO_SETUP.md) for detailed audio configuration.

## 🏆 Achievements System

### Achievement Categories
1. **Score Milestones**: Reach specific scores
2. **Survival Challenges**: Survive for certain durations
3. **Skill Challenges**: Use pulse mechanic effectively
4. **Collection Goals**: Collect power-ups
5. **Customization Unlocks**: Unlock all skins

### Achievement Rewards
- Unlock new bird skins
- Special particle effects
- Bonus starting power-ups
- Exclusive color schemes

## ⚙️ Settings and Configuration

### Graphics Settings
- **Quality Presets**: Low, Medium, High, Ultra
- **Particle Density**: Adjustable particle count
- **Background Complexity**: Layered background detail
- **Frame Rate Target**: 30fps or 60fps options

### Audio Settings
- **Music Volume**: 0-100% with mute option
- **Sound Effects Volume**: 0-100% with mute option
- **Beat Sync**: Enable/disable rhythm gameplay
- **Haptic Feedback**: Vibration intensity control

### Gameplay Settings
- **Difficulty**: Easy, Normal, Hard presets
- **Control Sensitivity**: Tap response timing
- **Double-tap Timing**: Pulse activation window
- **Auto-pause**: Pause when app loses focus

## 🐛 Troubleshooting

### Common Issues

#### Audio Not Playing
1. Check device volume settings
2. Verify audio settings in game menu
3. Ensure audio files are not corrupted
4. Check console for AudioManager error messages

#### Performance Issues
1. Lower graphics quality in settings
2. Reduce particle density
3. Enable performance monitoring
4. Close other apps to free memory

#### Haptic Feedback Not Working
1. Check device vibration settings
2. Ensure haptic feedback is enabled in game
3. Test on physical device (not simulator)
4. Verify device supports vibration

### Debug Information
Enable performance monitoring in settings to view:
- Current FPS
- Memory usage
- Particle count
- Audio system status

## 🤝 Contributing

### Development Workflow
1. Follow the spec-driven development approach
2. Check `.kiro/specs/neon-pulse-flappy-bird/` for requirements
3. Write tests for new features
4. Ensure accessibility compliance
5. Test on multiple devices and platforms

### Code Style
- Follow Dart/Flutter style guidelines
- Use meaningful variable and function names
- Add documentation for public APIs
- Maintain consistent formatting with `dart format`

### Pull Request Process
1. Create feature branch from main
2. Implement changes with tests
3. Update documentation if needed
4. Ensure all tests pass
5. Submit pull request with detailed description

## 📄 License

This project is private and not licensed for public use. All rights reserved.

## 📞 Support

For technical support or questions:
1. Check existing documentation files
2. Review troubleshooting section
3. Check GitHub issues for known problems
4. Contact development team for assistance

## 🔮 Future Enhancements

### Planned Features
- **Multiplayer Mode**: Real-time competitive gameplay
- **Level Editor**: Custom obstacle patterns
- **Seasonal Events**: Limited-time challenges
- **Cloud Saves**: Cross-device progress sync
- **Leaderboards**: Global score competition
- **VR Support**: Virtual reality gameplay mode

### Technical Improvements
- **Advanced AI**: Adaptive difficulty based on player skill
- **Procedural Generation**: Dynamic obstacle patterns
- **Real-time Multiplayer**: WebSocket-based networking
- **Machine Learning**: Personalized gameplay optimization
- **Advanced Physics**: More realistic bird movement
- **Shader Effects**: Custom GPU-accelerated visuals

---

**Neon Pulse Flappy Bird** - Where cyberpunk meets classic gameplay in a stunning neon-lit adventure!
