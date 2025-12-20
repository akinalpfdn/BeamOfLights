import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'components/game_world.dart';
import 'components/grid_component.dart';

/// BeamOfLightsGame - Main Flame game instance
/// Ported from Swift: GameScene.swift
class BeamOfLightsGame extends FlameGame<GameWorld>
    with PanDetector, ScaleDetector {
  // Camera zoom constraints
  static const double minZoom = 1.0; // Fit entire grid
  static const double maxZoom = 3.0; // Maximum zoom level
  static const double gridPadding = 100.0; // Padding around grid

  // Camera state
  double _currentZoom = 1.0;
  Vector2? _lastPanPosition;
  Vector2 _cameraPosition = Vector2.zero();

  BeamOfLightsGame() : super(world: GameWorld());

  @override
  Color backgroundColor() => GameConstants.darkBackground;

  @override
  Future<void> onLoad() async {
    // Calculate initial camera viewport size
    // Grid is 25x25 cells at 50pt each = 1250x1250
    const gridSize = 25 * GameConstants.gridCellSize;
    final viewportSize = gridSize + (gridPadding * 2);

    // Create camera with fixed resolution centered on grid
    camera = CameraComponent.withFixedResolution(
      world: world,
      width: viewportSize,
      height: viewportSize,
    );

    // Position camera at world origin (grid center)
    camera.viewfinder.position = Vector2.zero();
    camera.viewfinder.zoom = _currentZoom;

    await add(camera);
  }

  /// Handle pan/drag gestures for camera movement
  /// Ported from Swift: GameScene.swift camera pan logic
  @override
  void onPanStart(DragStartInfo info) {
    _lastPanPosition = info.eventPosition.global;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_lastPanPosition == null) return;

    final currentPosition = info.eventPosition.global;
    final delta = currentPosition - _lastPanPosition!;

    // Move camera in opposite direction of drag (for natural feel)
    // Scale movement by zoom level (less movement when zoomed in)
    _cameraPosition -= delta / _currentZoom;

    // Apply camera bounds to keep grid visible
    _applyCameraBounds();

    camera.viewfinder.position = _cameraPosition;
    _lastPanPosition = currentPosition;
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _lastPanPosition = null;
  }

  /// Handle pinch-to-zoom gestures
  /// Ported from Swift: GameScene.swift zoom logic (lines 74-94)
  @override
  void onScaleStart(ScaleStartInfo info) {
    // Store initial zoom level
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    // Update zoom level based on scale
    // info.scale.global is a Vector2, we need to get its x component for the scale value
    final scaleValue = info.scale.global.x;
    final newZoom = (_currentZoom * scaleValue).clamp(minZoom, maxZoom);

    // Apply zoom
    _currentZoom = newZoom;
    camera.viewfinder.zoom = _currentZoom;

    // Recalculate bounds after zoom change
    _applyCameraBounds();
    camera.viewfinder.position = _cameraPosition;
  }

  @override
  void onScaleEnd(ScaleEndInfo info) {
    // Zoom gesture ended
  }

  /// Apply camera bounds to keep grid visible with padding
  /// Ported from Swift: GameScene.swift camera bounds logic
  void _applyCameraBounds() {
    const gridSize = 25 * GameConstants.gridCellSize;

    // Calculate maximum camera offset based on zoom level
    // When zoomed out (zoom = 1.0), camera should stay near center
    // When zoomed in (zoom > 1.0), allow more movement
    final maxOffset = (gridSize / 2) * (_currentZoom - 1.0);

    // Clamp camera position to keep grid visible
    _cameraPosition.x = _cameraPosition.x.clamp(-maxOffset, maxOffset);
    _cameraPosition.y = _cameraPosition.y.clamp(-maxOffset, maxOffset);
  }

  /// Reset camera to default position and zoom
  void resetCamera() {
    _currentZoom = 1.0;
    _cameraPosition = Vector2.zero();
    camera.viewfinder.position = _cameraPosition;
    camera.viewfinder.zoom = _currentZoom;
  }

  /// Convert screen position to world position
  Vector2 screenToWorld(Vector2 screenPosition) {
    return camera.viewfinder.globalToLocal(screenPosition);
  }

  /// Get current grid component
  GridComponent? getGridComponent() {
    return world.gridComponent;
  }

  /// Trigger red screen flash on collision
  /// Ported from Swift: GameScene.swift triggerRedScreenFlash (lines 278-302)
  void triggerRedScreenFlash() {
    // Create full-screen overlay using PositionComponent for absolute positioning
    final overlay = _RedFlashOverlay();

    // Add directly to game (not viewport or world) for full screen coverage
    add(overlay);
  }
}

/// Full-screen red flash overlay component
class _RedFlashOverlay extends PositionComponent with HasPaint {
  _RedFlashOverlay() : super(priority: 1000); // Very high priority to render on top

  late Paint _flashPaint;

  @override
  Future<void> onLoad() async {
    _flashPaint = Paint()..color = Colors.red.withValues(alpha: 0);

    // Animate: fade in → hold → fade out → remove
    final fadeIn = OpacityEffect.to(
      0.15,
      EffectController(duration: 0.1),
    );

    final hold = OpacityEffect.to(
      0.15,
      EffectController(duration: 0.1),
    );

    final fadeOut = OpacityEffect.fadeOut(
      EffectController(duration: 0.3),
    );

    final remove = RemoveEffect();

    final sequence = SequenceEffect([fadeIn, hold, fadeOut, remove]);
    add(sequence);
  }

  @override
  void render(Canvas canvas) {
    // Get the actual screen size from the game
    final game = findGame();
    if (game == null) return;

    final screenSize = game.canvasSize;

    // Update paint opacity from HasPaint mixin
    _flashPaint.color = Colors.red.withValues(alpha: paint.color.a);

    // Draw full-screen rectangle
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenSize.x, screenSize.y),
      _flashPaint,
    );
  }
}
