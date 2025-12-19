import 'package:uuid/uuid.dart';
import 'cell.dart';

/// Beam model - represents a sliding beam in the game
/// Ported from Swift: BeamOfLights/ViewModels/GameViewModel.swift (lines 28-61)
class Beam {
  final String id;
  final List<Cell> cells; // All cells that make up this beam (ordered from start to end)
  final String color;
  bool isSliding;

  Beam({
    String? id,
    required this.cells,
    required this.color,
    this.isSliding = false,
  }) : id = id ?? const Uuid().v4();

  /// Get the direction of the beam (from the last non-end cell)
  /// This is a computed property that matches the Swift implementation
  Direction get direction {
    // If no cells, return none
    if (cells.isEmpty) return Direction.none;

    final lastCell = cells.last;

    // If the last cell has a direction (not an end cell), use it
    if (lastCell.direction != Direction.none) {
      return lastCell.direction;
    }

    // If last cell is an end cell (direction: none),
    // find the previous cell's direction
    if (cells.length >= 2) {
      final secondToLastCell = cells[cells.length - 2];
      return secondToLastCell.direction;
    }

    return Direction.none;
  }

  /// Get the start cell of the beam
  Cell? get startCell {
    if (cells.isEmpty) return null;
    return cells.first;
  }

  /// Get the end cell of the beam
  Cell? get endCell {
    if (cells.isEmpty) return null;
    return cells.last;
  }

  /// Get the tip cell (last cell) for rendering
  Cell? get tipCell {
    if (cells.isEmpty) return null;
    return cells.last;
  }

  /// Check if a cell is part of this beam
  bool containsCell(int row, int column) {
    return cells.any((cell) => cell.row == row && cell.column == column);
  }

  /// Create a copy of Beam with optional field changes
  Beam copyWith({
    String? id,
    List<Cell>? cells,
    String? color,
    bool? isSliding,
  }) {
    return Beam(
      id: id ?? this.id,
      cells: cells ?? this.cells,
      color: color ?? this.color,
      isSliding: isSliding ?? this.isSliding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Beam && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Beam(id: ${id.substring(0, 8)}..., color: $color, cells: ${cells.length}, direction: $direction, isSliding: $isSliding)';
  }
}
