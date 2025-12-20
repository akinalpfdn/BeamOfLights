import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../../models/beam.dart';
import '../../utils/constants.dart';
import 'grid_component.dart';

/// BeamComponent - Renders a single beam as a colored path
/// Phase 6: Simple colored lines (neon effects in Phase 8)
/// Ported from Swift: GameScene.swift beam rendering
class BeamComponent extends PositionComponent with TapCallbacks, HasPaint {
  final Beam beam;
  final GridComponent gridComponent;
  final VoidCallback? onTap;

  // Visual properties (simple rendering for Phase 6)
  static const double beamWidth = 8.0;
  late Paint _beamPaint;
  late Color _beamColor;

  // Path for rendering
  late Path _beamPath;

  BeamComponent({
    required this.beam,
    required this.gridComponent,
    this.onTap,
  }) : super(priority: 10); // Higher priority than grid

  @override
  Future<void> onLoad() async {
    // Parse beam color
    _beamColor = GameConstants.parseHexColor(beam.color);

    // Create paint for beam
    _beamPaint = Paint()
      ..color = _beamColor
      ..strokeWidth = beamWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Build the beam path
    _buildBeamPath();

    // Set component size to encompass the beam
    _updateComponentBounds();
  }

  /// Build the visual path for the beam
  void _buildBeamPath() {
    _beamPath = Path();

    if (beam.cells.isEmpty) return;

    // Start at the center of the first cell
    final startCell = beam.cells.first;
    final startPos = gridComponent.getCellCenter(startCell.row, startCell.column);

    _beamPath.moveTo(startPos.x, startPos.y);

    // Draw lines to each subsequent cell center
    for (int i = 1; i < beam.cells.length; i++) {
      final cell = beam.cells[i];
      final cellPos = gridComponent.getCellCenter(cell.row, cell.column);
      _beamPath.lineTo(cellPos.x, cellPos.y);
    }
  }

  /// Update component bounds to encompass the beam
  void _updateComponentBounds() {
    if (beam.cells.isEmpty) return;

    // Calculate bounding box
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final cell in beam.cells) {
      final cellPos = gridComponent.getCellCenter(cell.row, cell.column);
      minX = minX < cellPos.x ? minX : cellPos.x;
      minY = minY < cellPos.y ? minY : cellPos.y;
      maxX = maxX > cellPos.x ? maxX : cellPos.x;
      maxY = maxY > cellPos.y ? maxY : cellPos.y;
    }

    // Add padding for beam width
    const padding = beamWidth * 2;
    position = Vector2(minX - padding, minY - padding);
    size = Vector2(
      (maxX - minX) + (padding * 2),
      (maxY - minY) + (padding * 2),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Translate canvas to account for component position
    canvas.save();
    canvas.translate(-position.x, -position.y);

    // Update beam paint opacity from HasPaint mixin (for fade effects)
    _beamPaint.color = _beamColor.withValues(alpha: paint.color.a);

    // Draw the beam path
    canvas.drawPath(_beamPath, _beamPaint);

    canvas.restore();
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Notify parent that this beam was tapped
    onTap?.call();
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // Convert point to world coordinates
    final worldPoint = point + position;

    // Check if point is near any cell in the beam
    for (final cell in beam.cells) {
      final cellCenter = gridComponent.getCellCenter(cell.row, cell.column);
      final distance = (worldPoint - cellCenter).length;

      // Allow tap within cell radius
      if (distance < GameConstants.gridCellSize / 2) {
        return true;
      }
    }

    return false;
  }

  /// Update the beam's path dynamically (for snake slide animation)
  /// Ported from Swift: GameScene.swift updateBeamPath (lines 305-326)
  void updatePath(List<Vector2> newPoints) {
    if (newPoints.length < 2) {
      // Hide beam if path is too short
      opacity = 0;
      return;
    }

    // Rebuild the path with new points
    _beamPath = Path();
    _beamPath.moveTo(newPoints.first.x, newPoints.first.y);
    for (int i = 1; i < newPoints.length; i++) {
      _beamPath.lineTo(newPoints[i].x, newPoints[i].y);
    }

    // Update component bounds to match new path
    _updateComponentBoundsFromPoints(newPoints);
  }

  /// Update component bounds from a list of points
  void _updateComponentBoundsFromPoints(List<Vector2> points) {
    if (points.isEmpty) return;

    // Calculate bounding box
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final point in points) {
      minX = minX < point.x ? minX : point.x;
      minY = minY < point.y ? minY : point.y;
      maxX = maxX > point.x ? maxX : point.x;
      maxY = maxY > point.y ? maxY : point.y;
    }

    // Add padding for beam width
    const padding = beamWidth * 2;
    position = Vector2(minX - padding, minY - padding);
    size = Vector2(
      (maxX - minX) + (padding * 2),
      (maxY - minY) + (padding * 2),
    );
  }
}
