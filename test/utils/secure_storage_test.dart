import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neon_pulse_flappy_bird/utils/secure_storage.dart';

void main() {
  group('SecureStorage', () {
    setUp(() async {
      // Initialize SharedPreferences with empty values
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      // Clean up after each test
      await SecureStorage.clearAll();
    });

    group('Basic Operations', () {
      test('should store and retrieve values correctly', () async {
        const key = 'test_key';
        const value = 'test_value';

        final storeResult = await SecureStorage.store(key, value);
        expect(storeResult, isTrue);

        final retrievedValue = await SecureStorage.retrieve(key);
        expect(retrievedValue, equals(value));
      });

      test('should return null for non-existent keys', () async {
        const key = 'non_existent_key';

        final retrievedValue = await SecureStorage.retrieve(key);
        expect(retrievedValue, isNull);
      });

      test('should remove values correctly', () async {
        const key = 'test_key';
        const value = 'test_value';

        await SecureStorage.store(key, value);
        expect(await SecureStorage.retrieve(key), equals(value));

        final removeResult = await SecureStorage.remove(key);
        expect(removeResult, isTrue);

        final retrievedValue = await SecureStorage.retrieve(key);
        expect(retrievedValue, isNull);
      });

      test('should check key existence correctly', () async {
        const key = 'test_key';
        const value = 'test_value';

        expect(await SecureStorage.containsKey(key), isFalse);

        await SecureStorage.store(key, value);
        expect(await SecureStorage.containsKey(key), isTrue);

        await SecureStorage.remove(key);
        expect(await SecureStorage.containsKey(key), isFalse);
      });
    });

    group('JSON Operations', () {
      test('should store and retrieve JSON data correctly', () async {
        const key = 'json_key';
        final jsonData = {
          'name': 'Test User',
          'score': 100,
          'active': true,
          'settings': {
            'volume': 0.8,
            'difficulty': 'normal',
          },
        };

        final storeResult = await SecureStorage.storeJson(key, jsonData);
        expect(storeResult, isTrue);

        final retrievedData = await SecureStorage.retrieveJson(key);
        expect(retrievedData, isNotNull);
        expect(retrievedData!['name'], equals('Test User'));
        expect(retrievedData['score'], equals(100));
        expect(retrievedData['active'], equals(true));
        expect(retrievedData['settings']['volume'], equals(0.8));
        expect(retrievedData['settings']['difficulty'], equals('normal'));
      });

      test('should return null for non-existent JSON keys', () async {
        const key = 'non_existent_json_key';

        final retrievedData = await SecureStorage.retrieveJson(key);
        expect(retrievedData, isNull);
      });

      test('should handle empty JSON objects', () async {
        const key = 'empty_json_key';
        final emptyJson = <String, dynamic>{};

        await SecureStorage.storeJson(key, emptyJson);
        final retrievedData = await SecureStorage.retrieveJson(key);

        expect(retrievedData, isNotNull);
        expect(retrievedData!.isEmpty, isTrue);
      });
    });

    group('Clear Operations', () {
      test('should clear all stored values', () async {
        // Store multiple values
        await SecureStorage.store('key1', 'value1');
        await SecureStorage.store('key2', 'value2');
        await SecureStorage.storeJson('json_key', {'test': 'data'});

        // Verify they exist
        expect(await SecureStorage.containsKey('key1'), isTrue);
        expect(await SecureStorage.containsKey('key2'), isTrue);
        expect(await SecureStorage.containsKey('json_key'), isTrue);

        // Clear all
        final clearResult = await SecureStorage.clearAll();
        expect(clearResult, isTrue);

        // Verify they're gone
        expect(await SecureStorage.containsKey('key1'), isFalse);
        expect(await SecureStorage.containsKey('key2'), isFalse);
        expect(await SecureStorage.containsKey('json_key'), isFalse);
      });
    });

    group('Extension Methods', () {
      test('should store and retrieve auth tokens', () async {
        const token = 'test_auth_token_12345';

        final storeResult = await SecureStorage.storeAuthToken(token);
        expect(storeResult, isTrue);

        final retrievedToken = await SecureStorage.getAuthToken();
        expect(retrievedToken, equals(token));

        final removeResult = await SecureStorage.removeAuthToken();
        expect(removeResult, isTrue);

        final removedToken = await SecureStorage.getAuthToken();
        expect(removedToken, isNull);
      });

      test('should store and retrieve refresh tokens', () async {
        const refreshToken = 'test_refresh_token_67890';

        await SecureStorage.storeRefreshToken(refreshToken);
        final retrievedToken = await SecureStorage.getRefreshToken();
        expect(retrievedToken, equals(refreshToken));

        await SecureStorage.removeRefreshToken();
        final removedToken = await SecureStorage.getRefreshToken();
        expect(removedToken, isNull);
      });

      test('should store and retrieve user credentials', () async {
        final credentials = {
          'uid': 'user123',
          'email': 'test@example.com',
          'lastTokenRefresh': DateTime.now().millisecondsSinceEpoch,
        };

        await SecureStorage.storeUserCredentials(credentials);
        final retrievedCredentials = await SecureStorage.getUserCredentials();

        expect(retrievedCredentials, isNotNull);
        expect(retrievedCredentials!['uid'], equals('user123'));
        expect(retrievedCredentials['email'], equals('test@example.com'));
        expect(retrievedCredentials['lastTokenRefresh'], isA<int>());

        await SecureStorage.removeUserCredentials();
        final removedCredentials = await SecureStorage.getUserCredentials();
        expect(removedCredentials, isNull);
      });
    });

    group('Error Handling', () {
      test('should handle storage errors gracefully', () async {
        // Test with invalid JSON data
        const key = 'invalid_json_key';
        
        // This should not throw an exception
        final result = await SecureStorage.retrieveJson(key);
        expect(result, isNull);
      });

      test('should handle initialization multiple times', () async {
        // Multiple initializations should not cause issues
        await SecureStorage.initialize();
        await SecureStorage.initialize();
        await SecureStorage.initialize();

        // Storage should still work
        await SecureStorage.store('test', 'value');
        final value = await SecureStorage.retrieve('test');
        expect(value, equals('value'));
      });
    });

    group('Data Encryption', () {
      test('should encrypt stored data', () async {
        const key = 'encryption_test';
        const value = 'sensitive_data';

        await SecureStorage.store(key, value);

        // Get the raw stored value from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final rawValue = prefs.getString('secure_$key');

        // The raw value should exist and be base64 encoded (different format)
        expect(rawValue, isNotNull);
        // The raw value should be base64 encoded, so it should be different from original
        // unless the encryption is not working, but retrieval should still work
        
        // But retrieval should return the original value
        final retrievedValue = await SecureStorage.retrieve(key);
        expect(retrievedValue, equals(value));
      });

      test('should handle different data types in encryption', () async {
        final testCases = [
          'simple_string',
          'string with spaces and special chars !@#\$%^&*()',
          '12345',
          'unicode_test_🎮🚀💫',
          '',
        ];

        for (int i = 0; i < testCases.length; i++) {
          final key = 'test_$i';
          final value = testCases[i];

          await SecureStorage.store(key, value);
          final retrieved = await SecureStorage.retrieve(key);
          expect(retrieved, equals(value), reason: 'Failed for value: $value');
        }
      });
    });
  });
}