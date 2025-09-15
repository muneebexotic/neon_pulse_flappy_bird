#!/usr/bin/env dart

import 'dart:io';

/// Release build script for Neon Pulse
/// Automates the process of building optimized release versions
/// for both Android and iOS platforms.

void main(List<String> args) async {
  print('🚀 Neon Pulse Release Build Script');
  print('==================================');
  
  final platform = args.isNotEmpty ? args[0].toLowerCase() : 'all';
  
  try {
    // Pre-build optimizations
    await runPreBuildOptimizations();
    
    // Build for specified platform(s)
    switch (platform) {
      case 'android':
        await buildAndroid();
        break;
      case 'ios':
        await buildIOS();
        break;
      case 'all':
      default:
        await buildAndroid();
        await buildIOS();
        break;
    }
    
    // Post-build analysis
    await runPostBuildAnalysis();
    
    print('✅ Release build complete!');
  } catch (e) {
    print('❌ Build failed: $e');
    exit(1);
  }
}

/// Run pre-build optimizations
Future<void> runPreBuildOptimizations() async {
  print('\n📋 Running pre-build optimizations...');
  
  // Clean previous builds
  print('  🧹 Cleaning previous builds...');
  await _runCommand('flutter', ['clean']);
  
  // Get dependencies
  print('  📦 Getting dependencies...');
  await _runCommand('flutter', ['pub', 'get']);
  
  // Optimize assets
  print('  🎨 Optimizing assets...');
  await _runCommand('dart', ['build_scripts/optimize_assets.dart']);
  
  // Run code generation if needed
  print('  🔧 Running code generation...');
  await _runCommand('flutter', ['packages', 'pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs']);
  
  print('✅ Pre-build optimizations complete');
}

/// Build Android release
Future<void> buildAndroid() async {
  print('\n🤖 Building Android release...');
  
  // Build APK
  print('  📱 Building APK...');
  await _runCommand('flutter', [
    'build',
    'apk',
    '--release',
    '--shrink',
    '--obfuscate',
    '--split-debug-info=build/app/outputs/symbols',
  ]);
  
  // Build App Bundle
  print('  📦 Building App Bundle...');
  await _runCommand('flutter', [
    'build',
    'appbundle',
    '--release',
    '--shrink',
    '--obfuscate',
    '--split-debug-info=build/app/outputs/symbols',
  ]);
  
  print('✅ Android build complete');
  print('  📱 APK: build/app/outputs/flutter-apk/app-release.apk');
  print('  📦 AAB: build/app/outputs/bundle/release/app-release.aab');
}

/// Build iOS release
Future<void> buildIOS() async {
  print('\n🍎 Building iOS release...');
  
  if (!Platform.isMacOS) {
    print('⚠️  iOS builds require macOS, skipping...');
    return;
  }
  
  // Build iOS
  print('  📱 Building iOS archive...');
  await _runCommand('flutter', [
    'build',
    'ios',
    '--release',
    '--obfuscate',
    '--split-debug-info=build/ios/symbols',
  ]);
  
  // Create IPA (requires Xcode)
  print('  📦 Creating IPA archive...');
  await _runCommand('xcodebuild', [
    '-workspace',
    'ios/Runner.xcworkspace',
    '-scheme',
    'Runner',
    '-configuration',
    'Release',
    '-archivePath',
    'build/ios/Runner.xcarchive',
    'archive',
  ]);
  
  await _runCommand('xcodebuild', [
    '-exportArchive',
    '-archivePath',
    'build/ios/Runner.xcarchive',
    '-exportPath',
    'build/ios/ipa',
    '-exportOptionsPlist',
    'ios/ExportOptions.plist',
  ]);
  
  print('✅ iOS build complete');
  print('  📱 Archive: build/ios/Runner.xcarchive');
  print('  📦 IPA: build/ios/ipa/Neon Pulse.ipa');
}

/// Run post-build analysis
Future<void> runPostBuildAnalysis() async {
  print('\n📊 Running post-build analysis...');
  
  // Analyze APK size (Android)
  final apkFile = File('build/app/outputs/flutter-apk/app-release.apk');
  if (await apkFile.exists()) {
    final apkSize = await apkFile.length();
    print('  📱 APK size: ${_formatFileSize(apkSize)}');
    
    if (apkSize > 50 * 1024 * 1024) { // 50MB
      print('  ⚠️  APK size is large, consider further optimization');
    }
  }
  
  // Analyze AAB size (Android)
  final aabFile = File('build/app/outputs/bundle/release/app-release.aab');
  if (await aabFile.exists()) {
    final aabSize = await aabFile.length();
    print('  📦 AAB size: ${_formatFileSize(aabSize)}');
  }
  
  // Check for debug symbols
  final symbolsDir = Directory('build/app/outputs/symbols');
  if (await symbolsDir.exists()) {
    print('  🔍 Debug symbols generated for crash reporting');
  }
  
  print('✅ Post-build analysis complete');
}

/// Run a command and handle errors
Future<void> _runCommand(String command, List<String> args) async {
  final process = await Process.start(command, args);
  
  // Stream output
  process.stdout.listen((data) {
    stdout.add(data);
  });
  
  process.stderr.listen((data) {
    stderr.add(data);
  });
  
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw Exception('Command failed: $command ${args.join(' ')} (exit code: $exitCode)');
  }
}

/// Format file size for display
String _formatFileSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}