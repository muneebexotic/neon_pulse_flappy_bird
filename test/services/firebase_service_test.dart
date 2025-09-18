import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/services/firebase_service.dart';

void main() {
  group('FirebaseService', () {
    test('should handle initialization gracefully when Firebase is not configured', () async {
      // This test verifies that the app doesn't crash when Firebase is not configured
      final result = await FirebaseService.initialize();
      
      // Should return false when Firebase is not configured
      expect(result, false);
      expect(FirebaseService.isInitialized, false);
      expect(FirebaseService.firestore, null);
      expect(FirebaseService.isOnline, false);
    });

    test('should provide correct offline status', () {
      expect(FirebaseService.isOnline, false);
    });
  });
}