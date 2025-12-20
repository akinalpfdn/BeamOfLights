import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:provider/provider.dart';
import 'utils/constants.dart';
import 'game/beam_of_lights_game.dart';
import 'providers/game_provider.dart';
import 'widgets/game_hud.dart';

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
  bool _beamRendererInitialized = false;

  @override
  void initState() {
    super.initState();
    _game = BeamOfLightsGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize beam renderer once GameProvider is available
    if (!_beamRendererInitialized) {
      _beamRendererInitialized = true; // Prevent multiple calls
      final gameProvider = context.read<GameProvider>();

      // Schedule initialization after the widget tree is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Wait a bit for the game to fully load
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _game.world.initializeBeamRenderer(gameProvider);
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Flame game rendering layer
          GameWidget(game: _game),

          // UI overlay layer with HUD
          const GameHUD(),
        ],
      ),
    );
  }
}
