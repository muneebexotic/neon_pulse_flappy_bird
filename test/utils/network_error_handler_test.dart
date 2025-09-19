import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/utils/network_error_handler.dart';

void main() {
  group('NetworkErrorHandler', () {
    test('should identify network errors correctly', () {
      // Network-related errors
      expect(NetworkErrorHandler.isNetworkError('Network error occurred'), isTrue);
      expect(NetworkErrorHandler.isNetworkError('Connection timeout'), isTrue);
      expect(NetworkErrorHandler.isNetworkError('Host unreachable'), isTrue);
      expect(NetworkErrorHandler.isNetworkError('Socket exception'), isTrue);
      expect(NetworkErrorHandler.isNetworkError('CONNECTION_ERROR'), isTrue);

      // Non-network errors
      expect(NetworkErrorHandler.isNetworkError('Invalid data format'), isFalse);
      expect(NetworkErrorHandler.isNetworkError('Permission denied'), isFalse);
      expect(NetworkErrorHandler.isNetworkError('File not found'), isFalse);
      expect(NetworkErrorHandler.isNetworkError('Authentication failed'), isFalse);
    });

    test('should provide appropriate error messages for different error types', () {
      // Network errors
      String message = NetworkErrorHandler.getErrorMessage('Network connection failed');
      expect(message, contains('offline'));

      // Permission errors
      message = NetworkErrorHandler.getErrorMessage('Permission denied to access resource');
      expect(message, contains('permission'));

      // Quota errors
      message = NetworkErrorHandler.getErrorMessage('Quota exceeded for this service');
      expect(message, contains('quota'));

      // Authentication errors
      message = NetworkErrorHandler.getErrorMessage('Authentication token expired');
      expect(message, contains('Authentication'));

      // Generic errors
      message = NetworkErrorHandler.getErrorMessage('Unknown error occurred');
      expect(message, contains('unexpected error'));
    });

    test('should handle null and empty error messages', () {
      expect(() => NetworkErrorHandler.getErrorMessage(null), returnsNormally);
      expect(() => NetworkErrorHandler.getErrorMessage(''), returnsNormally);
      expect(() => NetworkErrorHandler.isNetworkError(null), returnsNormally);
      expect(() => NetworkErrorHandler.isNetworkError(''), returnsNormally);
    });

    test('should handle different error object types', () {
      // String errors
      expect(NetworkErrorHandler.isNetworkError('network error'), isTrue);
      
      // Exception objects
      final networkException = Exception('Connection timeout');
      expect(NetworkErrorHandler.isNetworkError(networkException), isTrue);
      
      // Other object types
      final customError = {'type': 'network', 'message': 'connection failed'};
      expect(() => NetworkErrorHandler.isNetworkError(customError), returnsNormally);
    });

    test('should provide consistent error messages', () {
      final message1 = NetworkErrorHandler.getErrorMessage('network error');
      final message2 = NetworkErrorHandler.getErrorMessage('connection failed');
      
      // Both network errors should get similar messages
      expect(message1, equals(message2));
    });

    test('should handle case-insensitive error detection', () {
      expect(NetworkErrorHandler.isNetworkError('NETWORK ERROR'), isTrue);
      expect(NetworkErrorHandler.isNetworkError('Connection Failed'), isTrue);
      expect(NetworkErrorHandler.isNetworkError('TIMEOUT OCCURRED'), isTrue);
      expect(NetworkErrorHandler.isNetworkError('socket exception'), isTrue);
    });

    test('should detect various network error patterns', () {
      final networkErrors = [
        'network error',
        'connection failed',
        'timeout occurred',
        'host unreachable',
        'socket exception',
        'no internet connection',
        'connection refused',
        'network is unreachable',
        'connection timed out',
        'failed to connect',
      ];

      for (final error in networkErrors) {
        expect(NetworkErrorHandler.isNetworkError(error), isTrue, 
               reason: 'Should detect "$error" as a network error');
      }
    });

    test('should not detect non-network errors as network errors', () {
      final nonNetworkErrors = [
        'invalid json format',
        'file not found',
        'access denied',
        'invalid credentials',
        'data parsing error',
        'null pointer exception',
        'index out of bounds',
        'illegal argument',
      ];

      for (final error in nonNetworkErrors) {
        expect(NetworkErrorHandler.isNetworkError(error), isFalse,
               reason: 'Should not detect "$error" as a network error');
      }
    });

    test('should provide specific messages for known error types', () {
      final permissionMessage = NetworkErrorHandler.getErrorMessage('permission denied');
      expect(permissionMessage, contains('permission'));
      expect(permissionMessage, contains('check'));

      final quotaMessage = NetworkErrorHandler.getErrorMessage('quota exceeded');
      expect(quotaMessage, contains('quota'));
      expect(quotaMessage, contains('try again later'));

      final authMessage = NetworkErrorHandler.getErrorMessage('auth failed');
      expect(authMessage, contains('Authentication'));
      expect(authMessage, contains('sign in'));
    });
  });
}