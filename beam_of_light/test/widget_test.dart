// Basic smoke test for Beam of Lights game
// Phase 1: Verify app initializes and Flame game loads

import 'package:flutter_test/flutter_test.dart';
import 'package:beam_of_light/main.dart';

void main() {
  testWidgets('App initializes and loads Flame game', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const BeamOfLightsApp());

    // Verify the app builds successfully
    expect(find.byType(BeamOfLightsApp), findsOneWidget);
    expect(find.byType(GameScreen), findsOneWidget);

    // Pump a few frames to allow the game to initialize
    // (don't use pumpAndSettle as Flame games continuously update)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Basic smoke test passes if no exceptions thrown
  });
}
