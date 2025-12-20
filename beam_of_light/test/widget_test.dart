// Basic smoke test for Beam of Lights game
// Phase 5: Verify app initializes with Flame game and GameProvider

import 'package:flutter_test/flutter_test.dart';
import 'package:beam_of_light/main.dart';
import 'package:beam_of_light/game/beam_of_lights_game.dart';
import 'package:flame/game.dart';

void main() {
  testWidgets('App initializes and loads Flame game with Provider',
      (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const BeamOfLightsApp());

    // Verify the app builds successfully
    expect(find.byType(BeamOfLightsApp), findsOneWidget);
    expect(find.byType(GameScreen), findsOneWidget);

    // Pump a few frames to allow the game and provider to initialize
    // (don't use pumpAndSettle as Flame games continuously update)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify GameWidget is present (Flame game rendering)
    expect(find.byType(GameWidget<BeamOfLightsGame>), findsOneWidget);

    // Basic smoke test passes if no exceptions thrown
  });
}
