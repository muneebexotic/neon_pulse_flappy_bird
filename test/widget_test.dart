// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:neon_pulse_flappy_bird/ui/app.dart';

void main() {
  testWidgets('App loads main menu', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NeonPulseFlappyBirdApp());

    // Verify that the main menu loads with the game title.
    expect(find.text('NEON PULSE'), findsOneWidget);
    expect(find.text('FLAPPY BIRD'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
  });
}
