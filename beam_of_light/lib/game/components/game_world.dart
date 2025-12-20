import 'package:flame/components.dart';
import '../../providers/game_provider.dart';
import 'grid_component.dart';
import 'beam_renderer.dart';

/// GameWorld - Main game world container
/// Holds all game components (grid, beams, etc.)
/// Ported from Swift: GameScene.swift world setup
class GameWorld extends World {
  late GridComponent gridComponent;
  BeamRenderer? beamRenderer;

  @override
  Future<void> onLoad() async {
    // Create and add grid component
    gridComponent = GridComponent();
    await add(gridComponent);
  }

  /// Initialize beam renderer with game provider
  /// Called after GameProvider is available
  Future<void> initializeBeamRenderer(GameProvider gameProvider) async {
    if (beamRenderer != null) {
      beamRenderer!.removeFromParent();
    }

    beamRenderer = BeamRenderer(
      gameProvider: gameProvider,
      gridComponent: gridComponent,
    );

    await add(beamRenderer!);
  }
}
