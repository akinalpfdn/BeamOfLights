import '../models/beam.dart';
import '../models/cell.dart';
import '../models/level.dart';

/// BeamBuilder - constructs Beam objects from Level cell data
/// Ported from Swift: BeamOfLights/ViewModels/GameViewModel.swift
/// (buildBeams, buildConnectedPath, findNextCell methods)
class BeamBuilder {
  /// Build all beams for a given level by grouping cells by color
  /// and following their directional connections
  /// Returns a list of Beam objects ready for gameplay
  static List<Beam> buildBeams(Level level) {
    // Group cells by color
    final Map<String, List<Cell>> cellsByColor = {};

    for (final cell in level.cells) {
      if (cell.color.isNotEmpty) {
        cellsByColor.putIfAbsent(cell.color, () => []).add(cell);
      }
    }

    // Build beam objects by following connected paths for each color
    final List<Beam> beams = [];

    for (final entry in cellsByColor.entries) {
      final color = entry.key;
      final cells = entry.value;

      // Build the connected path for this color
      final orderedCells = _buildConnectedPath(cells);

      if (orderedCells != null && orderedCells.isNotEmpty) {
        beams.add(Beam(cells: orderedCells, color: color));
      }
    }

    return beams;
  }

  /// Build a connected path by following cell directions
  /// Starts from the 'start' cell and follows directions until 'end' cell
  /// Returns null if no valid path can be constructed
  /// Ported from Swift: GameViewModel.swift lines 170-189
  static List<Cell>? _buildConnectedPath(List<Cell> cells) {
    // Find the start cell (or just use first cell if no start exists)
    final startCell = cells.firstWhere(
      (cell) => cell.type == CellType.start,
      orElse: () => cells.first,
    );

    final List<Cell> orderedCells = [startCell];
    final Set<String> visited = {'${startCell.row},${startCell.column}'};

    Cell current = startCell;
    int iterations = 0;
    final int maxIterations = cells.length * 2; // Prevent infinite loops

    // Keep following directions until we reach an end cell or can't continue
    while (current.type != CellType.end && iterations < maxIterations) {
      final nextCell = _findNextCell(current, cells, visited);

      if (nextCell == null) break;

      orderedCells.add(nextCell);
      visited.add('${nextCell.row},${nextCell.column}');
      current = nextCell;
      iterations++;
    }

    return orderedCells;
  }

  /// Find the next cell in a path by following the current cell's direction
  /// Returns null if no valid next cell exists
  /// Ported from Swift: GameViewModel.swift lines 191-207
  static Cell? _findNextCell(
    Cell currentCell,
    List<Cell> availableCells,
    Set<String> visited,
  ) {
    // Calculate next position based on direction
    int nextRow = currentCell.row;
    int nextColumn = currentCell.column;

    switch (currentCell.direction) {
      case Direction.up:
        nextRow -= 1;
        break;
      case Direction.down:
        nextRow += 1;
        break;
      case Direction.left:
        nextColumn -= 1;
        break;
      case Direction.right:
        nextColumn += 1;
        break;
      case Direction.none:
        return null; // End cells have no direction
    }

    // Check if we've already visited this cell (prevent loops)
    final key = '$nextRow,$nextColumn';
    if (visited.contains(key)) {
      return null;
    }

    // Find the cell at the next position
    try {
      return availableCells.firstWhere(
        (cell) => cell.row == nextRow && cell.column == nextColumn,
      );
    } catch (e) {
      return null; // No cell found at this position
    }
  }

  /// Validate that a beam path is complete and valid
  /// A valid beam should start with a 'start' cell and end with an 'end' cell
  static bool validateBeamPath(Beam beam) {
    if (beam.cells.isEmpty) return false;

    // First cell should be start (or at least have a direction)
    final firstCell = beam.cells.first;
    if (firstCell.type != CellType.start && firstCell.direction == Direction.none) {
      return false;
    }

    // Last cell should be end
    final lastCell = beam.cells.last;
    if (lastCell.type != CellType.end) {
      return false;
    }

    // All cells should have the same color
    final color = beam.color;
    for (final cell in beam.cells) {
      if (cell.color != color) {
        return false;
      }
    }

    return true;
  }

  /// Debug helper: Print beam path information
  static String debugBeamPath(Beam beam) {
    final buffer = StringBuffer();
    buffer.writeln('Beam: ${beam.color} (${beam.cells.length} cells)');

    for (var i = 0; i < beam.cells.length; i++) {
      final cell = beam.cells[i];
      final arrow = _directionArrow(cell.direction);
      buffer.writeln(
          '  [$i] (${cell.row},${cell.column}) ${cell.type.name} $arrow');
    }

    buffer.writeln('  Direction: ${beam.direction.name}');

    return buffer.toString();
  }

  /// Helper: Convert direction to arrow symbol for debugging
  static String _directionArrow(Direction direction) {
    switch (direction) {
      case Direction.up:
        return '↑';
      case Direction.down:
        return '↓';
      case Direction.left:
        return '←';
      case Direction.right:
        return '→';
      case Direction.none:
        return '•';
    }
  }
}
