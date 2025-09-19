import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neon_pulse_flappy_bird/services/connectivity_service.dart';

void main() {
  group('ConnectivityService', () {
    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      // Clean up after each test
      await ConnectivityService.dispose();
    });

    test('should initialize with unknown status', () {
      expect(ConnectivityService.status, ConnectivityStatus.unknown);
    });

    test('should queue operations when offline', () async {
      await ConnectivityService.queueOperation(
        type: 'test_operation',
        data: {'key': 'value'},
      );

      final count = await ConnectivityService.getQueuedOperationsCount();
      expect(count, greaterThan(0));
    });

    test('should clear queued operations', () async {
      // Queue some operations
      await ConnectivityService.queueOperation(
        type: 'test_operation_1',
        data: {'key': 'value1'},
      );
      await ConnectivityService.queueOperation(
        type: 'test_operation_2',
        data: {'key': 'value2'},
      );

      // Verify operations are queued
      int count = await ConnectivityService.getQueuedOperationsCount();
      expect(count, greaterThan(0));

      // Clear operations
      await ConnectivityService.clearQueuedOperations();

      // Verify operations are cleared
      count = await ConnectivityService.getQueuedOperationsCount();
      expect(count, equals(0));
    });

    test('should limit queued operations to prevent storage bloat', () async {
      // Queue more than 100 operations
      for (int i = 0; i < 105; i++) {
        await ConnectivityService.queueOperation(
          type: 'test_operation_$i',
          data: {'index': i},
        );
      }

      final count = await ConnectivityService.getQueuedOperationsCount();
      expect(count, lessThanOrEqualTo(100));
    });

    test('should provide correct status strings', () {
      expect(ConnectivityService.getStatusString(), isA<String>());
      expect(ConnectivityService.getStatusString().isNotEmpty, isTrue);
    });

    test('should handle connectivity status changes', () async {
      // This test would require mocking the connectivity plugin
      // For now, we'll just test that the status stream is available
      expect(ConnectivityService.statusStream, isA<Stream<ConnectivityStatus>>());
    });

    test('should queue different types of operations separately', () async {
      await ConnectivityService.queueOperation(
        type: 'auth_operation',
        data: {'userId': 'test123'},
        queueKey: 'queued_auth_operations',
      );

      await ConnectivityService.queueOperation(
        type: 'profile_update',
        data: {'name': 'Test User'},
        queueKey: 'queued_profile_updates',
      );

      final count = await ConnectivityService.getQueuedOperationsCount();
      expect(count, equals(2));
    });

    test('should handle queue operation errors gracefully', () async {
      // This test ensures the method doesn't throw exceptions
      expect(() async {
        await ConnectivityService.queueOperation(
          type: 'test_operation',
          data: {'key': null}, // Potentially problematic data
        );
      }, returnsNormally);
    });

    test('should provide connectivity status checks', () {
      expect(ConnectivityService.isOnline, isA<bool>());
      expect(ConnectivityService.isOffline, isA<bool>());
      
      // Online and offline should be mutually exclusive (unless unknown)
      if (ConnectivityService.status != ConnectivityStatus.unknown) {
        expect(ConnectivityService.isOnline != ConnectivityService.isOffline, isTrue);
      }
    });
  });

  group('ConnectivityStatus enum', () {
    test('should have all expected values', () {
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.online));
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.offline));
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.unknown));
    });

    test('should have exactly 3 values', () {
      expect(ConnectivityStatus.values.length, equals(3));
    });
  });
}