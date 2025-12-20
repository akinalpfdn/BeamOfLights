import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'hearts_widget.dart';
import 'level_indicator_widget.dart';
import 'win_screen.dart';
import 'lose_screen.dart';

/// GameHUD - UI overlay layer on top of Flame game
/// Displays hearts, level indicator, and win/lose screens
class GameHUD extends StatelessWidget {
  const GameHUD({super.key});

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
          ],
        );
      },
    );
  }
}
