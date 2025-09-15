import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/managers/audio_manager.dart';
import 'asset_preloader.dart';
import 'animation_config.dart';

/// Manages the complete app startup sequence with proper timing and error handling
class StartupSequenceManager {
  static final StartupSequenceManager _instance = StartupSequenceManager._internal();
  factory StartupSequenceManager() => _instance;
  StartupSequenceManager._internal();

  bool _isInitialized = false;
  final List<StartupStep> _completedSteps = [];
  
  /// Check if startup sequence is complete
  bool get isInitialized => _isInitialized;
  
  /// Get completed steps
  List<StartupStep> get completedSteps => List.from(_completedSteps);

  /// Execute the complete startup sequence
  Future<void> executeStartupSequence({
    Function(double progress, String step, StartupStep stepType)? onProgress,
    Function(String error, StartupStep failedStep)? onError,
  }) async {
    if (_isInitialized) {
      onProgress?.call(1.0, 'Already initialized', StartupStep.complete);
      return;
    }

    final steps = [
      StartupStep.systemInit,
      StartupStep.assetPreload,
      StartupStep.audioInit,
      StartupStep.themeInit,
      StartupStep.gameInit,
      StartupStep.complete,
    ];

    try {
      for (int i = 0; i < steps.length; i++) {
        final step = steps[i];
        final progress = i / (steps.length - 1);
        
        await _executeStep(step, onProgress, progress);
        _completedSteps.add(step);
        
        // Add small delay between steps for smooth progress indication
        if (step != StartupStep.complete) {
          await Future.delayed(AnimationConfig.fast);
        }
      }
      
      _isInitialized = true;
    } catch (e) {
      final failedStep = steps[_completedSteps.length];
      onError?.call(e.toString(), failedStep);
      rethrow;
    }
  }

  /// Execute a single startup step
  Future<void> _executeStep(
    StartupStep step,
    Function(double progress, String stepName, StartupStep stepType)? onProgress,
    double progress,
  ) async {
    switch (step) {
      case StartupStep.systemInit:
        onProgress?.call(progress, 'Initializing system...', step);
        await _initializeSystem();
        break;
        
      case StartupStep.assetPreload:
        onProgress?.call(progress, 'Loading assets...', step);
        await _preloadAssets();
        break;
        
      case StartupStep.audioInit:
        onProgress?.call(progress, 'Initializing audio...', step);
        await _initializeAudio();
        break;
        
      case StartupStep.themeInit:
        onProgress?.call(progress, 'Setting up theme...', step);
        await _initializeTheme();
        break;
        
      case StartupStep.gameInit:
        onProgress?.call(progress, 'Preparing game...', step);
        await _initializeGame();
        break;
        
      case StartupStep.complete:
        onProgress?.call(1.0, 'Ready to play!', step);
        break;
    }
  }

  /// Initialize system-level configurations
  Future<void> _initializeSystem() async {
    try {
      // Set system UI overlay style
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
      
      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      // Enable edge-to-edge display
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      
      print('StartupSequenceManager: System initialization complete');
    } catch (e) {
      print('StartupSequenceManager: System initialization failed: $e');
      throw StartupException('Failed to initialize system', StartupStep.systemInit);
    }
  }

  /// Preload essential assets
  Future<void> _preloadAssets() async {
    try {
      await AssetPreloader().preloadAssets();
      print('StartupSequenceManager: Asset preloading complete');
    } catch (e) {
      print('StartupSequenceManager: Asset preloading failed: $e');
      throw StartupException('Failed to preload assets', StartupStep.assetPreload);
    }
  }

  /// Initialize audio system
  Future<void> _initializeAudio() async {
    try {
      await AudioManager().initialize();
      print('StartupSequenceManager: Audio initialization complete');
    } catch (e) {
      print('StartupSequenceManager: Audio initialization failed: $e');
      // Audio failure is not critical - continue with silent mode
      print('StartupSequenceManager: Continuing in silent mode');
    }
  }

  /// Initialize theme and visual systems
  Future<void> _initializeTheme() async {
    try {
      // Warm up shader compilation for smooth animations
      await _warmupShaders();
      
      // Initialize any theme-specific resources
      await _initializeThemeResources();
      
      print('StartupSequenceManager: Theme initialization complete');
    } catch (e) {
      print('StartupSequenceManager: Theme initialization failed: $e');
      throw StartupException('Failed to initialize theme', StartupStep.themeInit);
    }
  }

  /// Warm up shaders for smooth performance
  Future<void> _warmupShaders() async {
    // This would typically involve creating and disposing of widgets
    // that use the shaders to force compilation
    await Future.delayed(AnimationConfig.ultraFast);
  }

  /// Initialize theme-specific resources
  Future<void> _initializeThemeResources() async {
    // Initialize any theme-specific caches or resources
    await Future.delayed(AnimationConfig.ultraFast);
  }

  /// Initialize game-specific systems
  Future<void> _initializeGame() async {
    try {
      // Initialize game managers and systems
      await _initializeGameSystems();
      
      print('StartupSequenceManager: Game initialization complete');
    } catch (e) {
      print('StartupSequenceManager: Game initialization failed: $e');
      throw StartupException('Failed to initialize game', StartupStep.gameInit);
    }
  }

  /// Initialize game systems
  Future<void> _initializeGameSystems() async {
    // Initialize any game-specific managers or caches
    await Future.delayed(AnimationConfig.fast);
  }

  /// Reset the startup sequence (for testing or re-initialization)
  void reset() {
    _isInitialized = false;
    _completedSteps.clear();
  }

  /// Get startup progress as percentage
  double getProgress() {
    if (_isInitialized) return 1.0;
    return _completedSteps.length / 6.0; // 6 total steps
  }

  /// Get current startup step
  StartupStep? getCurrentStep() {
    if (_isInitialized) return StartupStep.complete;
    if (_completedSteps.isEmpty) return StartupStep.systemInit;
    
    final nextStepIndex = _completedSteps.length;
    final allSteps = [
      StartupStep.systemInit,
      StartupStep.assetPreload,
      StartupStep.audioInit,
      StartupStep.themeInit,
      StartupStep.gameInit,
      StartupStep.complete,
    ];
    
    return nextStepIndex < allSteps.length ? allSteps[nextStepIndex] : StartupStep.complete;
  }

  /// Check if a specific step is complete
  bool isStepComplete(StartupStep step) {
    return _completedSteps.contains(step);
  }

  /// Get human-readable step name
  static String getStepName(StartupStep step) {
    switch (step) {
      case StartupStep.systemInit:
        return 'System Initialization';
      case StartupStep.assetPreload:
        return 'Asset Preloading';
      case StartupStep.audioInit:
        return 'Audio Initialization';
      case StartupStep.themeInit:
        return 'Theme Setup';
      case StartupStep.gameInit:
        return 'Game Preparation';
      case StartupStep.complete:
        return 'Complete';
    }
  }

  /// Get step description
  static String getStepDescription(StartupStep step) {
    switch (step) {
      case StartupStep.systemInit:
        return 'Configuring system settings and permissions';
      case StartupStep.assetPreload:
        return 'Loading images, fonts, and other resources';
      case StartupStep.audioInit:
        return 'Setting up audio system and sound effects';
      case StartupStep.themeInit:
        return 'Preparing visual theme and animations';
      case StartupStep.gameInit:
        return 'Initializing game engine and managers';
      case StartupStep.complete:
        return 'Startup sequence complete';
    }
  }
}

/// Startup sequence steps
enum StartupStep {
  systemInit,
  assetPreload,
  audioInit,
  themeInit,
  gameInit,
  complete,
}

/// Custom exception for startup failures
class StartupException implements Exception {
  final String message;
  final StartupStep failedStep;
  
  const StartupException(this.message, this.failedStep);
  
  @override
  String toString() => 'StartupException: $message (Step: $failedStep)';
}