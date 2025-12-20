import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
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

  // Visual properties (neon rendering for Phase 8)
  static const double beamWidth = 8.0;
  late Color _beamColor;

  // Path for rendering
  late Path _beamPath;

  // Neon effect paints (4 layers)
  late Paint _outerHazePaint;
  late Paint _innerGlowPaint;
  late Paint _corePaint;
  late Paint _tipDotPaint;
  late Paint _tipAuraPaint;

  // Bounce offset for collision animation
  Vector2 bounceOffset = Vector2.zero();

  BeamComponent({
    required this.beam,
    required this.gridComponent,
    this.onTap,
  }) : super(priority: 10); // Higher priority than grid

  @override
  Future<void> onLoad() async {
    // Parse beam color
    _beamColor = GameConstants.parseHexColor(beam.color);

    // Create neon effect paints (4 layers matching Swift implementation)
    // Layer 1: Outer Haze - large, faint glow
    _outerHazePaint = Paint()
      ..color = _beamColor.withValues(alpha: 0.15)
      ..strokeWidth = GameConstants.gridCellSize * 0.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    // Layer 2: Inner Glow - medium, bright glow
    _innerGlowPaint = Paint()
      ..color = _beamColor.withValues(alpha: 0.6)
      ..strokeWidth = GameConstants.gridCellSize * 0.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    // Layer 3: Core - thin, bright white line
    _corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = GameConstants.gridCellSize * 0.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Layer 4: Tip Dot - bright white center
    _tipDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    // Tip Aura - colored glow around tip
    _tipAuraPaint = Paint()
      ..color = _beamColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

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

    // Translate canvas to account for component position and bounce offset
    canvas.save();
    canvas.translate(-position.x + bounceOffset.x, -position.y + bounceOffset.y);

    // Get opacity multiplier from HasPaint mixin (for fade effects)
    final opacityMultiplier = paint.color.a;

    // Draw neon effect in 4 layers (back to front)
    // Layer 1: Outer Haze (largest, faintest)
    _outerHazePaint.color = _beamColor.withValues(alpha: 0.15 * opacityMultiplier);
    canvas.drawPath(_beamPath, _outerHazePaint);

    // Layer 2: Inner Glow (medium, brighter)
    _innerGlowPaint.color = _beamColor.withValues(alpha: 0.6 * opacityMultiplier);
    canvas.drawPath(_beamPath, _innerGlowPaint);

    // Layer 3: Core (thin, bright white)
    _corePaint.color = Colors.white.withValues(alpha: 0.9 * opacityMultiplier);
    canvas.drawPath(_beamPath, _corePaint);

    // Layer 4: Tip effects (if beam has cells)
    if (beam.cells.isNotEmpty) {
      final lastCell = beam.cells.last;
      final tipPos = gridComponent.getCellCenter(lastCell.row, lastCell.column);

      // Tip Aura (colored glow)
      _tipAuraPaint.color = _beamColor.withValues(alpha: 0.4 * opacityMultiplier);
      canvas.drawCircle(
        Offset(tipPos.x, tipPos.y),
        GameConstants.gridCellSize * 0.15,
        _tipAuraPaint,
      );

      // Tip Dot (bright white center)
      _tipDotPaint.color = Colors.white.withValues(alpha: opacityMultiplier);
      canvas.drawCircle(
        Offset(tipPos.x, tipPos.y),
        GameConstants.gridCellSize * 0.1,
        _tipDotPaint,
      );
    }

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
