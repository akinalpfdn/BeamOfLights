import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

/// LevelIndicatorWidget - Displays current level number
class LevelIndicatorWidget extends StatelessWidget {
  const LevelIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final levelNumber = gameProvider.currentLevel?.levelNumber ?? 1;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Level $levelNumber',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
