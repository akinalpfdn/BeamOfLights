import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import '../../models/beam.dart';
import '../../models/cell.dart';
import '../../providers/game_provider.dart';
import '../beam_of_lights_game.dart';
import 'grid_component.dart';
import 'beam_component.dart';
import 'marker_component.dart';
import '../animations/slide_animation.dart';
import '../animations/bounce_animation.dart';
import '../effects/collision_particles.dart';

/// BeamRenderer - Manages all beam components and markers
/// Synchronizes with GameProvider state
class BeamRenderer extends Component {
  final GameProvider gameProvider;
  final GridComponent gridComponent;

  final Map<String, BeamComponent> _beamComponents = {};
  final Map<String, MarkerComponent> _startMarkers = {};
  final Map<String, MarkerComponent> _endMarkers = {};

  StreamSubscription<GameActionEvent>? _gameActionsSubscription;
  bool _isAnimating = false; // Block input during animations

  BeamRenderer({
    required this.gameProvider,
    required this.gridComponent,
  }) : super(priority: 5); // Render after grid, before UI

  @override
  Future<void> onLoad() async {
    debugPrint('🎨 BeamRenderer onLoad: initializing with ${gameProvider.activeBeams.length} beams');

    // Initial render of beams
    await _updateBeams();

    // Listen to game provider changes
    gameProvider.addListener(_onGameStateChanged);

    // Listen to game action events for animations
    _gameActionsSubscription =
        gameProvider.gameActions.listen(_handleGameAction);

    debugPrint('🎨 BeamRenderer onLoad: complete, rendered ${_beamComponents.length} beams');
  }

  @override
  void onRemove() {
    gameProvider.removeListener(_onGameStateChanged);
    _gameActionsSubscription?.cancel();
    super.onRemove();
  }

  /// Handle game state changes
  void _onGameStateChanged() {
    _updateBeams();
  }

  /// Update beams to match GameProvider state
  Future<void> _updateBeams() async {
    final activeBeams = gameProvider.activeBeams;
    debugPrint('🔄 BeamRenderer._updateBeams: ${activeBeams.length} active beams in GameProvider');

    // Track which beams are still active
    final activeBeamIds = activeBeams.map((b) => b.id).toSet();

    // Remove beams that no longer exist
    final beamsToRemove = _beamComponents.keys
        .where((id) => !activeBeamIds.contains(id))
        .toList();

    if (beamsToRemove.isNotEmpty) {
      debugPrint('🗑️ Removing ${beamsToRemove.length} beams');
    }

    for (final beamId in beamsToRemove) {
      final beamComponent = _beamComponents.remove(beamId);
      final startMarker = _startMarkers.remove(beamId);
      final endMarker = _endMarkers.remove(beamId);

      beamComponent?.removeFromParent();
      startMarker?.removeFromParent();
      endMarker?.removeFromParent();
    }

    // Add new beams
    int addedCount = 0;
    for (final beam in activeBeams) {
      if (!_beamComponents.containsKey(beam.id)) {
        await _addBeam(beam);
        addedCount++;
      }
    }

    if (addedCount > 0) {
      debugPrint('✅ Added $addedCount new beams, total rendered: ${_beamComponents.length}');
    }
  }

  /// Add a new beam with markers
  Future<void> _addBeam(Beam beam) async {
    // Create beam component
    final beamComponent = BeamComponent(
      beam: beam,
      gridComponent: gridComponent,
      onTap: () => _handleBeamTap(beam),
    );

    // Create start marker
    final startCell = beam.cells.first;
    final startMarker = MarkerComponent(
      position: gridComponent.getCellCenter(startCell.row, startCell.column),
      color: MarkerType.start,
      beamColor: beam.color,
    );

    // Create end marker
    final endCell = beam.cells.last;
    final endMarker = MarkerComponent(
      position: gridComponent.getCellCenter(endCell.row, endCell.column),
      color: MarkerType.end,
      beamColor: beam.color,
    );

    // Add to parent and tracking
    await addAll([beamComponent, startMarker, endMarker]);

    _beamComponents[beam.id] = beamComponent;
    _startMarkers[beam.id] = startMarker;
    _endMarkers[beam.id] = endMarker;
  }

  /// Handle beam tap
  void _handleBeamTap(Beam beam) {
    // Block taps during animations
    if (_isAnimating) return;

    // Find the cell that was tapped (use first cell for now)
    if (beam.cells.isNotEmpty) {
      final cell = beam.cells.first;
      gameProvider.tapBeam(row: cell.row, column: cell.column);
    }
  }

  /// Handle game action events (animations)
  void _handleGameAction(GameActionEvent event) {
    switch (event.action) {
      case GameAction.slideOut:
        if (event.beamId != null && event.direction != null) {
          _animateSlideOut(event.beamId!, event.direction!);
        }
        break;
      case GameAction.bounce:
        if (event.beamId != null && event.direction != null) {
          _animateBounce(event.beamId!, event.direction!);
        }
        break;
      case GameAction.reset:
        // Clear animations on reset
        _isAnimating = false;
        break;
    }
  }

  /// Animate beam sliding out
  void _animateSlideOut(String beamId, Direction direction) {
    final beamComponent = _beamComponents[beamId];
    if (beamComponent == null || gameProvider.currentLevel == null) return;

    debugPrint('🎬 Starting slide animation for beam $beamId in direction $direction');

    // Block input during animation
    _isAnimating = true;

    // Create snake slide animation
    final slideEffect = SlideAnimation.createSlideEffect(
      beamComponent: beamComponent,
      direction: direction,
      level: gameProvider.currentLevel!,
      onComplete: () {
        debugPrint('✅ Slide animation complete for beam $beamId');
        _isAnimating = false;
        // Remove markers associated with this beam
        _startMarkers[beamId]?.removeFromParent();
        _endMarkers[beamId]?.removeFromParent();
        _startMarkers.remove(beamId);
        _endMarkers.remove(beamId);
        _beamComponents.remove(beamId);

        // Notify GameProvider to remove beam from logical model
        gameProvider.removeBeamAfterAnimation(beamId);
      },
    );

    // Apply snake slide effect to beam
    beamComponent.add(slideEffect);
  }

  /// Animate beam bouncing back
  void _animateBounce(String beamId, Direction direction) {
    final beamComponent = _beamComponents[beamId];
    if (beamComponent == null) return;

    debugPrint('💥 Starting bounce animation for beam $beamId in direction $direction');

    // Block input during animation
    _isAnimating = true;

    // Trigger red screen flash (collision alert)
    _triggerRedScreenFlash();

    // Spawn collision particles at beam tip
    _spawnCollisionParticles(beamComponent);

    // Create bounce animation
    final bounceEffect = BounceAnimation.createFullBounceEffect(
      beamComponent: beamComponent,
      direction: direction,
      onComplete: () {
        debugPrint('✅ Bounce animation complete for beam $beamId');
        _isAnimating = false;
      },
    );

    // Apply effect to beam
    beamComponent.add(bounceEffect);
  }

  /// Spawn collision particles at beam tip
  void _spawnCollisionParticles(BeamComponent beamComponent) {
    // Get the beam tip position (end of beam)
    final tipPosition = beamComponent.position + beamComponent.size / 2;

    // Create particles with beam color
    final particles = CollisionParticles(
      spawnPosition: tipPosition,
      color: beamComponent.beamColor,
    );

    // Add to parent world
    parent?.add(particles);
  }

  /// Trigger red screen flash effect via game instance
  void _triggerRedScreenFlash() {
    // Access the game instance through the component tree
    final game = findGame();
    if (game != null && game is BeamOfLightsGame) {
      (game as BeamOfLightsGame).triggerRedScreenFlash();
    }
  }

  /// Remove all beams (for reset)
  void clearAllBeams() {
    for (final component in _beamComponents.values) {
      component.removeFromParent();
    }
    for (final marker in _startMarkers.values) {
      marker.removeFromParent();
    }
    for (final marker in _endMarkers.values) {
      marker.removeFromParent();
    }

    _beamComponents.clear();
    _startMarkers.clear();
    _endMarkers.clear();
    _isAnimating = false;
  }
}
