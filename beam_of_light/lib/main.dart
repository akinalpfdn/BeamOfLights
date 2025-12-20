import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:provider/provider.dart';
import 'utils/constants.dart';
import 'game/beam_of_lights_game.dart';
import 'providers/game_provider.dart';

void main() {
  runApp(const BeamOfLightsApp());
}

class BeamOfLightsApp extends StatelessWidget {
  const BeamOfLightsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: MaterialApp(
        title: 'Beam of Lights',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: GameConstants.darkBackground,
        ),
        home: const GameScreen(),
      ),
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
      body: Stack(
        children: [
          // Flame game rendering layer
          GameWidget(game: _game),

          // UI overlay layer (will be expanded in Phase 9)
          Positioned(
            top: 50,
            left: 20,
            child: Consumer<GameProvider>(
              builder: (context, gameProvider, child) {
                return Text(
                  'Level ${gameProvider.currentLevel?.levelNumber ?? "?"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),

          // Hearts display (basic version for now)
          Positioned(
            top: 50,
            right: 20,
            child: Consumer<GameProvider>(
              builder: (context, gameProvider, child) {
                return Row(
                  children: List.generate(
                    gameProvider.heartsRemaining,
                    (index) => const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
