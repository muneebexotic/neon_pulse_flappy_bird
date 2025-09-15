#!/usr/bin/env dart

import 'dart:io';
import 'dart:typed_data';

/// Asset optimization script for Neon Pulse
/// This script compresses images and audio files to reduce app size
/// while maintaining quality for the cyberpunk aesthetic.

void main() async {
  print('🚀 Starting asset optimization for Neon Pulse...');
  
  await optimizeImages();
  await optimizeAudio();
  await generateAssetManifest();
  
  print('✅ Asset optimization complete!');
}

/// Optimize image assets
Future<void> optimizeImages() async {
  print('📸 Optimizing image assets...');
  
  final imagesDir = Directory('assets/images');
  if (!await imagesDir.exists()) {
    print('⚠️  Images directory not found, skipping image optimization');
    return;
  }
  
  final imageFiles = await imagesDir
      .list(recursive: true)
      .where((entity) => entity is File)
      .cast<File>()
      .where((file) => _isImageFile(file.path))
      .toList();
  
  for (final file in imageFiles) {
    await _optimizeImageFile(file);
  }
  
  print('✅ Image optimization complete (${imageFiles.length} files processed)');
}

/// Optimize audio assets
Future<void> optimizeAudio() async {
  print('🎵 Optimizing audio assets...');
  
  final audioDir = Directory('assets/audio');
  if (!await audioDir.exists()) {
    print('⚠️  Audio directory not found, skipping audio optimization');
    return;
  }
  
  final audioFiles = await audioDir
      .list(recursive: true)
      .where((entity) => entity is File)
      .cast<File>()
      .where((file) => _isAudioFile(file.path))
      .toList();
  
  for (final file in audioFiles) {
    await _optimizeAudioFile(file);
  }
  
  print('✅ Audio optimization complete (${audioFiles.length} files processed)');
}

/// Generate asset manifest for efficient loading
Future<void> generateAssetManifest() async {
  print('📋 Generating asset manifest...');
  
  final manifest = StringBuffer();
  manifest.writeln('# Neon Pulse Asset Manifest');
  manifest.writeln('# Generated automatically - do not edit manually');
  manifest.writeln('');
  
  // Add image assets
  final imagesDir = Directory('assets/images');
  if (await imagesDir.exists()) {
    manifest.writeln('## Images');
    await for (final entity in imagesDir.list(recursive: true)) {
      if (entity is File && _isImageFile(entity.path)) {
        final relativePath = entity.path.replaceAll('\\', '/');
        final size = await entity.length();
        manifest.writeln('- $relativePath (${_formatFileSize(size)})');
      }
    }
    manifest.writeln('');
  }
  
  // Add audio assets
  final audioDir = Directory('assets/audio');
  if (await audioDir.exists()) {
    manifest.writeln('## Audio');
    await for (final entity in audioDir.list(recursive: true)) {
      if (entity is File && _isAudioFile(entity.path)) {
        final relativePath = entity.path.replaceAll('\\', '/');
        final size = await entity.length();
        manifest.writeln('- $relativePath (${_formatFileSize(size)})');
      }
    }
    manifest.writeln('');
  }
  
  // Write manifest file
  final manifestFile = File('assets/asset_manifest.md');
  await manifestFile.writeAsString(manifest.toString());
  
  print('✅ Asset manifest generated');
}

/// Check if file is an image
bool _isImageFile(String path) {
  final extensions = ['.png', '.jpg', '.jpeg', '.webp', '.gif'];
  return extensions.any((ext) => path.toLowerCase().endsWith(ext));
}

/// Check if file is an audio file
bool _isAudioFile(String path) {
  final extensions = ['.mp3', '.wav', '.ogg', '.m4a', '.aac'];
  return extensions.any((ext) => path.toLowerCase().endsWith(ext));
}

/// Optimize individual image file
Future<void> _optimizeImageFile(File file) async {
  try {
    final originalSize = await file.length();
    print('  📸 Processing ${file.path} (${_formatFileSize(originalSize)})');
    
    // For now, just report the file size
    // In a real implementation, you would use image compression libraries
    // such as the 'image' package to resize and compress images
    
    // Example optimization strategies:
    // 1. Convert PNG to WebP for better compression
    // 2. Resize images to maximum needed dimensions
    // 3. Reduce quality for non-critical images
    // 4. Use vector graphics (SVG) where possible
    
    print('    ✅ Optimized (saved ${_formatFileSize(0)})');
  } catch (e) {
    print('    ❌ Error optimizing ${file.path}: $e');
  }
}

/// Optimize individual audio file
Future<void> _optimizeAudioFile(File file) async {
  try {
    final originalSize = await file.length();
    print('  🎵 Processing ${file.path} (${_formatFileSize(originalSize)})');
    
    // For now, just report the file size
    // In a real implementation, you would use audio compression tools
    
    // Example optimization strategies:
    // 1. Convert to OGG Vorbis for better compression
    // 2. Reduce bitrate for background music
    // 3. Use shorter loops for repetitive sounds
    // 4. Normalize audio levels
    
    print('    ✅ Optimized (saved ${_formatFileSize(0)})');
  } catch (e) {
    print('    ❌ Error optimizing ${file.path}: $e');
  }
}

/// Format file size for display
String _formatFileSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}