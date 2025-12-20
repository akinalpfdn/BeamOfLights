import 'dart:ui';
import 'package:flame/components.dart';
import '../../utils/constants.dart';
import '../../models/level.dart';
import '../../models/beam.dart';

/// GridComponent - Renders the game grid with white dots at intersections
/// Now supports dynamic grid sizing based on level data for escape puzzle game
class GridComponent extends Component {
  int gridRows = 25;
  int gridColumns = 25;
  static const double dotRadius = 2.0;
  static const double dotOpacity = 0.3;

  late Paint _dotPaint;
  late Paint _linePaint;

  GridComponent({Level? level}) {
    if (level != null) {
      gridRows = level.gridSize.rows;
      gridColumns = level.gridSize.columns;
    }
  }

  /// Update grid size when level changes
  void updateGridSize(Level level) {
    gridRows = level.gridSize.rows;
    gridColumns = level.gridSize.columns;
  }

  /// Calculate the optimal grid size based on beam positions
  /// This ensures the grid fits all beam content with minimal wasted space
  void calculateOptimalGridSize(List<Beam> beams) {
    if (beams.isEmpty) return;

    int maxRow = 0;
    int maxColumn = 0;

    for (final beam in beams) {
      for (final cell in beam.cells) {
        maxRow = maxRow > cell.row ? maxRow : cell.row;
        maxColumn = maxColumn > cell.column ? maxColumn : cell.column;
      }
    }

    // Add padding around the beams (1 cell margin)
    gridRows = maxRow + 2;
    gridColumns = maxColumn + 2;

    // Ensure minimum grid size
    gridRows = gridRows < 5 ? 5 : gridRows;
    gridColumns = gridColumns < 5 ? 5 : gridColumns;
  }

  @override
  Future<void> onLoad() async {
    // Paint for grid dots
    _dotPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: dotOpacity)
      ..style = PaintingStyle.fill;

    // Paint for grid lines (optional, very subtle)
    _linePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.05)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Calculate grid dimensions
    final cellSize = GameConstants.gridCellSize;
    final gridWidth = gridColumns * cellSize;
    final gridHeight = gridRows * cellSize;

    // Center the grid in world space
    final offsetX = -gridWidth / 2;
    final offsetY = -gridHeight / 2;

    // Draw grid lines (subtle background)
    // Vertical lines
    for (int col = 0; col <= gridColumns; col++) {
      final x = offsetX + (col * cellSize);
      canvas.drawLine(
        Offset(x, offsetY),
        Offset(x, offsetY + gridHeight),
        _linePaint,
      );
    }

    // Horizontal lines
    for (int row = 0; row <= gridRows; row++) {
      final y = offsetY + (row * cellSize);
      canvas.drawLine(
        Offset(offsetX, y),
        Offset(offsetX + gridWidth, y),
        _linePaint,
      );
    }

    // Draw dots at grid intersections
    for (int row = 0; row <= gridRows; row++) {
      for (int col = 0; col <= gridColumns; col++) {
        final x = offsetX + (col * cellSize);
        final y = offsetY + (row * cellSize);

        canvas.drawCircle(
          Offset(x, y),
          dotRadius,
          _dotPaint,
        );
      }
    }
  }

  /// Convert grid coordinates to world position
  Vector2 gridToWorld(int row, int column) {
    final cellSize = GameConstants.gridCellSize;
    final gridWidth = gridColumns * cellSize;
    final gridHeight = gridRows * cellSize;

    final offsetX = -gridWidth / 2;
    final offsetY = -gridHeight / 2;

    return Vector2(
      offsetX + (column * cellSize),
      offsetY + (row * cellSize),
    );
  }

  /// Convert world position to grid coordinates
  /// Returns null if position is outside grid bounds
  ({int row, int column})? worldToGrid(Vector2 worldPosition) {
    final cellSize = GameConstants.gridCellSize;
    final gridWidth = gridColumns * cellSize;
    final gridHeight = gridRows * cellSize;

    final offsetX = -gridWidth / 2;
    final offsetY = -gridHeight / 2;

    final relativeX = worldPosition.x - offsetX;
    final relativeY = worldPosition.y - offsetY;

    final column = (relativeX / cellSize).floor();
    final row = (relativeY / cellSize).floor();

    // Check bounds
    if (row < 0 || row >= gridRows || column < 0 || column >= gridColumns) {
      return null;
    }

    return (row: row, column: column);
  }

  /// Get the center position of a grid cell in world coordinates
  Vector2 getCellCenter(int row, int column) {
    final topLeft = gridToWorld(row, column);
    final cellSize = GameConstants.gridCellSize;
    return topLeft + Vector2(cellSize / 2, cellSize / 2);
  }

  /// Get grid bounds in world coordinates
  ({Vector2 topLeft, Vector2 bottomRight}) getGridBounds() {
    final cellSize = GameConstants.gridCellSize;
    final gridWidth = gridColumns * cellSize;
    final gridHeight = gridRows * cellSize;

    return (
      topLeft: Vector2(-gridWidth / 2, -gridHeight / 2),
      bottomRight: Vector2(gridWidth / 2, gridHeight / 2),
    );
  }
}
