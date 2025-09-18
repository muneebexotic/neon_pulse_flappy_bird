import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

/// Secure storage utility for handling sensitive authentication data
class SecureStorage {
  static const String _keyPrefix = 'secure_';
  static const String _saltKey = 'storage_salt';
  static SharedPreferences? _prefs;
  static String? _salt;
  
  /// Initialize secure storage
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _salt = await _getOrCreateSalt();
  }
  
  /// Store a secure value
  static Future<bool> store(String key, String value) async {
    try {
      if (_prefs == null) await initialize();
      
      final encryptedValue = _encrypt(value);
      return await _prefs!.setString('$_keyPrefix$key', encryptedValue);
    } catch (e) {
      debugPrint('Failed to store secure value: $e');
      return false;
    }
  }
  
  /// Retrieve a secure value
  static Future<String?> retrieve(String key) async {
    try {
      if (_prefs == null) await initialize();
      
      final encryptedValue = _prefs!.getString('$_keyPrefix$key');
      if (encryptedValue == null) return null;
      
      return _decrypt(encryptedValue);
    } catch (e) {
      debugPrint('Failed to retrieve secure value: $e');
      return null;
    }
  }
  
  /// Remove a secure value
  static Future<bool> remove(String key) async {
    try {
      if (_prefs == null) await initialize();
      
      return await _prefs!.remove('$_keyPrefix$key');
    } catch (e) {
      debugPrint('Failed to remove secure value: $e');
      return false;
    }
  }
  
  /// Clear all secure values
  static Future<bool> clearAll() async {
    try {
      if (_prefs == null) await initialize();
      
      final keys = _prefs!.getKeys().where((key) => key.startsWith(_keyPrefix));
      for (final key in keys) {
        await _prefs!.remove(key);
      }
      
      // Also remove the salt to ensure complete cleanup
      await _prefs!.remove(_saltKey);
      _salt = null;
      
      return true;
    } catch (e) {
      debugPrint('Failed to clear secure storage: $e');
      return false;
    }
  }
  
  /// Check if a key exists
  static Future<bool> containsKey(String key) async {
    try {
      if (_prefs == null) await initialize();
      
      return _prefs!.containsKey('$_keyPrefix$key');
    } catch (e) {
      debugPrint('Failed to check key existence: $e');
      return false;
    }
  }
  
  /// Store JSON data securely
  static Future<bool> storeJson(String key, Map<String, dynamic> data) async {
    try {
      final jsonString = json.encode(data);
      return await store(key, jsonString);
    } catch (e) {
      debugPrint('Failed to store JSON data: $e');
      return false;
    }
  }
  
  /// Retrieve JSON data securely
  static Future<Map<String, dynamic>?> retrieveJson(String key) async {
    try {
      final jsonString = await retrieve(key);
      if (jsonString == null) return null;
      
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to retrieve JSON data: $e');
      return null;
    }
  }
  
  /// Private methods for encryption/decryption
  /// Note: This is a simple obfuscation method, not cryptographically secure
  /// For production apps, consider using flutter_secure_storage or similar
  
  static String _encrypt(String value) {
    if (_salt == null) return value;
    
    final bytes = utf8.encode(value);
    final saltBytes = utf8.encode(_salt!);
    final encrypted = <int>[];
    
    for (int i = 0; i < bytes.length; i++) {
      final saltIndex = i % saltBytes.length;
      encrypted.add(bytes[i] ^ saltBytes[saltIndex]);
    }
    
    return base64.encode(encrypted);
  }
  
  static String _decrypt(String encryptedValue) {
    if (_salt == null) return encryptedValue;
    
    try {
      final encrypted = base64.decode(encryptedValue);
      final saltBytes = utf8.encode(_salt!);
      final decrypted = <int>[];
      
      for (int i = 0; i < encrypted.length; i++) {
        final saltIndex = i % saltBytes.length;
        decrypted.add(encrypted[i] ^ saltBytes[saltIndex]);
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      debugPrint('Failed to decrypt value: $e');
      return encryptedValue;
    }
  }
  
  static Future<String> _getOrCreateSalt() async {
    String? salt = _prefs?.getString(_saltKey);
    
    if (salt == null) {
      // Generate a new salt
      final random = Random.secure();
      final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
      salt = base64.encode(saltBytes);
      
      await _prefs?.setString(_saltKey, salt);
    }
    
    return salt;
  }
  
  /// Store authentication token
  static Future<bool> storeAuthToken(String token) async {
    return await SecureStorage.store('auth_token', token);
  }
  
  /// Retrieve authentication token
  static Future<String?> getAuthToken() async {
    return await SecureStorage.retrieve('auth_token');
  }
  
  /// Remove authentication token
  static Future<bool> removeAuthToken() async {
    return await SecureStorage.remove('auth_token');
  }
  
  /// Store refresh token
  static Future<bool> storeRefreshToken(String token) async {
    return await SecureStorage.store('refresh_token', token);
  }
  
  /// Retrieve refresh token
  static Future<String?> getRefreshToken() async {
    return await SecureStorage.retrieve('refresh_token');
  }
  
  /// Remove refresh token
  static Future<bool> removeRefreshToken() async {
    return await SecureStorage.remove('refresh_token');
  }
  
  /// Store user credentials
  static Future<bool> storeUserCredentials(Map<String, dynamic> credentials) async {
    return await SecureStorage.storeJson('user_credentials', credentials);
  }
  
  /// Retrieve user credentials
  static Future<Map<String, dynamic>?> getUserCredentials() async {
    return await SecureStorage.retrieveJson('user_credentials');
  }
  
  /// Remove user credentials
  static Future<bool> removeUserCredentials() async {
    return await SecureStorage.remove('user_credentials');
  }
}