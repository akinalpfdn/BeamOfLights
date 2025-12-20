import 'package:flame/components.dart';
import 'grid_component.dart';

/// GameWorld - Main game world container
/// Holds all game components (grid, beams, etc.)
/// Ported from Swift: GameScene.swift world setup
class GameWorld extends World {
  late GridComponent gridComponent;

  @override
  Future<void> onLoad() async {
    // Create and add grid component
    gridComponent = GridComponent();
    await add(gridComponent);
  }
}
