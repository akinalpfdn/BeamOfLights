import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

/// HeartWidget - Displays remaining hearts (lives)
/// Ported from Swift: HeartView.swift
class HeartsWidget extends StatelessWidget {
  const HeartsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final heartsRemaining = gameProvider.heartsRemaining;
        final maxHearts = gameProvider.currentLevel?.difficulty ?? 3;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(maxHearts, (index) {
              final isFilled = index < heartsRemaining;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isFilled ? 1.0 : 0.3,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: isFilled ? 1.0 : 0.8,
                    child: Icon(
                      isFilled ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red.shade400,
                      size: 32,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
