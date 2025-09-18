import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:neon_pulse_flappy_bird/ui/screens/leaderboard_screen.dart';
import 'package:neon_pulse_flappy_bird/providers/authentication_provider.dart';

void main() {
  group('LeaderboardScreen Tests', () {
    testWidgets('should display leaderboard header', (WidgetTester tester) async {
      // Create a mock authentication provider
      final authProvider = AuthenticationProvider();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthenticationProvider>.value(
            value: authProvider,
            child: const LeaderboardScreen(),
          ),
        ),
      );

      // Verify the header is displayed
      expect(find.text('GLOBAL LEADERBOARD'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('should display loading state initially', (WidgetTester tester) async {
      final authProvider = AuthenticationProvider();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthenticationProvider>.value(
            value: authProvider,
            child: const LeaderboardScreen(),
          ),
        ),
      );

      // Verify loading state is displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading leaderboard...'), findsOneWidget);
    });

    testWidgets('should have refresh functionality', (WidgetTester tester) async {
      final authProvider = AuthenticationProvider();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthenticationProvider>.value(
            value: authProvider,
            child: const LeaderboardScreen(),
          ),
        ),
      );

      // Verify RefreshIndicator is present
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('should navigate back when back button is pressed', (WidgetTester tester) async {
      final authProvider = AuthenticationProvider();
      bool navigatedBack = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider<AuthenticationProvider>.value(
                        value: authProvider,
                        child: const LeaderboardScreen(),
                      ),
                    ),
                  ).then((_) => navigatedBack = true);
                },
                child: const Text('Go to Leaderboard'),
              ),
            ),
          ),
        ),
      );

      // Navigate to leaderboard
      await tester.tap(find.text('Go to Leaderboard'));
      await tester.pumpAndSettle();

      // Verify we're on the leaderboard screen
      expect(find.text('GLOBAL LEADERBOARD'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify we navigated back
      expect(find.text('Go to Leaderboard'), findsOneWidget);
    });
  });
}