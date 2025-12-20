import 'package:flame/components.dart';
import '../../models/beam.dart';
import '../../providers/game_provider.dart';
import 'grid_component.dart';
import 'beam_component.dart';
import 'marker_component.dart';

/// BeamRenderer - Manages all beam components and markers
/// Synchronizes with GameProvider state
class BeamRenderer extends Component {
  final GameProvider gameProvider;
  final GridComponent gridComponent;

  final Map<String, BeamComponent> _beamComponents = {};
  final Map<String, MarkerComponent> _startMarkers = {};
  final Map<String, MarkerComponent> _endMarkers = {};

  BeamRenderer({
    required this.gameProvider,
    required this.gridComponent,
  }) : super(priority: 5); // Render after grid, before UI

  @override
  Future<void> onLoad() async {
    // Initial render of beams
    await _updateBeams();

    // Listen to game provider changes
    gameProvider.addListener(_onGameStateChanged);
  }

  @override
  void onRemove() {
    gameProvider.removeListener(_onGameStateChanged);
    super.onRemove();
  }

  /// Handle game state changes
  void _onGameStateChanged() {
    _updateBeams();
  }

  /// Update beams to match GameProvider state
  Future<void> _updateBeams() async {
    final activeBeams = gameProvider.activeBeams;

    // Track which beams are still active
    final activeBeamIds = activeBeams.map((b) => b.id).toSet();

    // Remove beams that no longer exist
    final beamsToRemove = _beamComponents.keys
        .where((id) => !activeBeamIds.contains(id))
        .toList();

    for (final beamId in beamsToRemove) {
      final beamComponent = _beamComponents.remove(beamId);
      final startMarker = _startMarkers.remove(beamId);
      final endMarker = _endMarkers.remove(beamId);

      beamComponent?.removeFromParent();
      startMarker?.removeFromParent();
      endMarker?.removeFromParent();
    }

    // Add new beams
    for (final beam in activeBeams) {
      if (!_beamComponents.containsKey(beam.id)) {
        await _addBeam(beam);
      }
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
    // Find the cell that was tapped (use first cell for now)
    if (beam.cells.isNotEmpty) {
      final cell = beam.cells.first;
      gameProvider.tapBeam(row: cell.row, column: cell.column);
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
  }
}
