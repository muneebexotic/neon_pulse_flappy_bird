import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/services/authentication_service.dart';

void main() {
  group('AuthenticationService', () {
    test('should handle guest sign-in when Firebase is not configured', () async {
      // This test verifies that guest mode works offline
      final user = await AuthenticationService.signInAsGuest();
      
      expect(user, isNotNull);
      expect(user!.isGuest, true);
      expect(user.displayName, 'Guest Player');
      expect(user.uid.startsWith('guest_'), true);
    });

    test('should handle sign out gracefully', () async {
      // This should not throw even when Firebase is not configured
      expect(() => AuthenticationService.signOut(), returnsNormally);
    });

    test('should return correct authentication state', () {
      expect(AuthenticationService.currentUser, null);
      expect(AuthenticationService.isSignedIn, false);
      expect(AuthenticationService.isGuest, true);
    });
  });
}