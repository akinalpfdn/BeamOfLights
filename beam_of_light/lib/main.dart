import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'utils/constants.dart';

void main() {
  runApp(const BeamOfLightsApp());
}

class BeamOfLightsApp extends StatelessWidget {
  const BeamOfLightsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beam of Lights',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: GameConstants.darkBackground,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final BeamOfLightsGame _game;

  @override
  void initState() {
    super.initState();
    _game = BeamOfLightsGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(game: _game),
    );
  }
}

/// Basic Flame game setup for Phase 1
/// This will be expanded in later phases
class BeamOfLightsGame extends FlameGame {
  @override
  Color backgroundColor() => GameConstants.darkBackground;

  @override
  Future<void> onLoad() async {
    // Basic setup - will be expanded in Phase 5
    // For now, just display a dark background to verify Flame is working
    debugMode = true;
  }
}
