import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/managers/audio_manager.dart';

/// Handles preloading of assets for smooth app startup
class AssetPreloader {
  static final AssetPreloader _instance = AssetPreloader._internal();
  factory AssetPreloader() => _instance;
  AssetPreloader._internal();

  bool _isInitialized = false;
  final List<String> _preloadedAssets = [];
  final Map<String, ImageProvider> _imageCache = {};

  /// Check if assets are already preloaded
  bool get isInitialized => _isInitialized;

  /// Preload all essential assets
  Future<void> preloadAssets() async {
    if (_isInitialized) return;

    try {
      // Preload images
      await _preloadImages();
      
      // Preload fonts
      await _preloadFonts();
      
      // Initialize audio system
      await _initializeAudio();
      
      // Preload shaders (if any)
      await _preloadShaders();
      
      _isInitialized = true;
      print('AssetPreloader: All assets preloaded successfully');
    } catch (e) {
      print('AssetPreloader: Error during asset preloading: $e');
      // Continue anyway - the app should still work
      _isInitialized = true;
    }
  }

  /// Preload essential images
  Future<void> _preloadImages() async {
    final imagesToPreload = [
      // Add your image assets here
      // 'images/bird_default.png',
      // 'images/bird_neon.png',
      // 'images/background_city.png',
    ];

    for (final imagePath in imagesToPreload) {
      try {
        final imageProvider = AssetImage(imagePath);
        _imageCache[imagePath] = imageProvider;
        
        // Force the image to load
        final imageStream = imageProvider.resolve(ImageConfiguration.empty);
        final completer = Completer<void>();
        
        imageStream.addListener(
          ImageStreamListener((info, synchronousCall) {
            if (!completer.isCompleted) {
              completer.complete();
            }
          }),
        );
        
        await completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('AssetPreloader: Timeout loading image: $imagePath');
          },
        );
        
        _preloadedAssets.add(imagePath);
        print('AssetPreloader: Preloaded image: $imagePath');
      } catch (e) {
        print('AssetPreloader: Failed to preload image $imagePath: $e');
      }
    }
  }

  /// Preload custom fonts
  Future<void> _preloadFonts() async {
    final fontsToPreload = [
      // Add your font assets here when available
      // 'fonts/Orbitron-Regular.ttf',
      // 'fonts/Orbitron-Bold.ttf',
    ];

    for (final fontPath in fontsToPreload) {
      try {
        await rootBundle.load(fontPath);
        _preloadedAssets.add(fontPath);
        print('AssetPreloader: Preloaded font: $fontPath');
      } catch (e) {
        print('AssetPreloader: Failed to preload font $fontPath: $e');
      }
    }
  }

  /// Initialize audio system
  Future<void> _initializeAudio() async {
    try {
      await AudioManager().initialize();
      print('AssetPreloader: Audio system initialized');
    } catch (e) {
      print('AssetPreloader: Failed to initialize audio: $e');
    }
  }

  /// Preload shaders (for advanced visual effects)
  Future<void> _preloadShaders() async {
    // Placeholder for shader preloading
    // In a real implementation, you might preload custom shaders here
    print('AssetPreloader: Shader preloading completed (placeholder)');
  }

  /// Get a preloaded image
  ImageProvider? getPreloadedImage(String path) {
    return _imageCache[path];
  }

  /// Check if a specific asset is preloaded
  bool isAssetPreloaded(String path) {
    return _preloadedAssets.contains(path);
  }

  /// Get preloading progress (0.0 to 1.0)
  double getPreloadingProgress() {
    if (_isInitialized) return 1.0;
    
    // This is a simplified progress calculation
    // In a real implementation, you'd track actual loading progress
    return 0.0;
  }

  /// Preload assets with progress callback
  Future<void> preloadAssetsWithProgress(
    Function(double progress, String currentAsset)? onProgress,
  ) async {
    if (_isInitialized) {
      onProgress?.call(1.0, 'Already loaded');
      return;
    }

    final totalSteps = 4; // Images, fonts, audio, shaders
    var currentStep = 0;

    // Preload images
    onProgress?.call(currentStep / totalSteps, 'Loading images...');
    await _preloadImages();
    currentStep++;

    // Preload fonts
    onProgress?.call(currentStep / totalSteps, 'Loading fonts...');
    await _preloadFonts();
    currentStep++;

    // Initialize audio
    onProgress?.call(currentStep / totalSteps, 'Initializing audio...');
    await _initializeAudio();
    currentStep++;

    // Preload shaders
    onProgress?.call(currentStep / totalSteps, 'Loading shaders...');
    await _preloadShaders();
    currentStep++;

    onProgress?.call(1.0, 'Ready to play!');
    _isInitialized = true;
  }

  /// Clear cached assets (for memory management)
  void clearCache() {
    _imageCache.clear();
    _preloadedAssets.clear();
    _isInitialized = false;
    print('AssetPreloader: Cache cleared');
  }

  /// Get memory usage information
  Map<String, dynamic> getMemoryInfo() {
    return {
      'preloaded_assets_count': _preloadedAssets.length,
      'cached_images_count': _imageCache.length,
      'is_initialized': _isInitialized,
      'preloaded_assets': List.from(_preloadedAssets),
    };
  }
}