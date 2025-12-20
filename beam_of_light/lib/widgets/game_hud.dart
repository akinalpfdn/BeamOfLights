import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'hearts_widget.dart';
import 'level_indicator_widget.dart';
import 'win_screen.dart';
import 'lose_screen.dart';
import 'tutorial_overlay.dart';

/// GameHUD - UI overlay layer on top of Flame game
/// Displays hearts, level indicator, and win/lose screens
class GameHUD extends StatefulWidget {
  const GameHUD({super.key});

  @override
  State<GameHUD> createState() => _GameHUDState();
}

class _GameHUDState extends State<GameHUD> {
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    final shouldShow = await TutorialOverlay.shouldShow();
    if (shouldShow && mounted) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        return Stack(
          children: [
            // Top bar with level indicator and hearts
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      RepaintBoundary(child: LevelIndicatorWidget()),
                      RepaintBoundary(child: HeartsWidget()),
                    ],
                  ),
                ),
              ),
            ),

            // Win screen overlay
            if (gameProvider.gameState == GameState.won)
              const RepaintBoundary(child: WinScreen()),

            // Lose screen overlay
            if (gameProvider.gameState == GameState.lost)
              const RepaintBoundary(child: LoseScreen()),

            // Tutorial overlay (first launch)
            if (_showTutorial)
              TutorialOverlay(
                onDismiss: () {
                  setState(() {
                    _showTutorial = false;
                  });
                },
              ),
          ],
        );
      },
    );
  }
}
