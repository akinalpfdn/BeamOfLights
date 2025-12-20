import 'package:uuid/uuid.dart';

/// BeamCell represents a cell in a beam with position and type
class BeamCell {
  final int row;
  final int column;
  final String type; // "↑", "↓", "←", "→", "●"

  BeamCell({
    required this.row,
    required this.column,
    required this.type,
  });

  /// Create BeamCell from JSON array [row, column, type]
  factory BeamCell.fromJson(List<dynamic> json) {
    return BeamCell(
      row: json[0] as int,
      column: json[1] as int,
      type: json[2] as String,
    );
  }

  /// Check if this is the end cell
  bool get isEnd => type == '●';

  /// Check if this is a path cell with direction
  bool get isPath => !isEnd;

  @override
  String toString() => 'BeamCell($row,$column,$type)';
}

/// Direction enum for beam movement
enum BeamDirection {
  up,
  down,
  left,
  right,
  none;

  String get name {
    switch (this) {
      case BeamDirection.up:
        return 'up';
      case BeamDirection.down:
        return 'down';
      case BeamDirection.left:
        return 'left';
      case BeamDirection.right:
        return 'right';
      case BeamDirection.none:
        return 'none';
    }
  }
}

/// Beam model - represents a beam in the escape puzzle game
class Beam {
  final String id;
  final List<BeamCell> cells;
  final String color;
  bool isRemoved; // For escape puzzle game mechanics
  bool isSliding; // For animation compatibility

  Beam({
    String? id,
    required this.cells,
    required this.color,
    this.isRemoved = false,
    this.isSliding = false,
  }) : id = id ?? const Uuid().v4();

  /// Create Beam from JSON structure
  factory Beam.fromJson(Map<String, dynamic> json) {
    final List<BeamCell> cells = (json['cells'] as List<dynamic>)
        .map((cellData) => BeamCell.fromJson(cellData as List<dynamic>))
        .toList();

    return Beam(
      id: json['id'] as String? ?? json['color'] as String,
      cells: cells,
      color: json['color'] as String,
    );
  }

  /// Get the start cell of the beam (first cell)
  BeamCell get startCell => cells.first;

  /// Get the end cell of the beam (last cell)
  BeamCell get endCell => cells.last;

  /// Get the tip cell (last cell) for rendering compatibility
  BeamCell get tipCell => endCell;

  /// Get the direction of the beam based on the last non-end cell
  BeamDirection get direction {
    if (cells.isEmpty) return BeamDirection.none;

    // Find the last non-end cell to get direction
    for (int i = cells.length - 1; i >= 0; i--) {
      final cell = cells[i];
      if (cell.type != '●') {
        switch (cell.type) {
          case '↑':
            return BeamDirection.up;
          case '↓':
            return BeamDirection.down;
          case '←':
            return BeamDirection.left;
          case '→':
            return BeamDirection.right;
          default:
            return BeamDirection.none;
        }
      }
    }

    return BeamDirection.none;
  }

  /// Check if a position is part of this beam
  bool containsPosition(int row, int column) {
    return cells.any((cell) => cell.row == row && cell.column == column);
  }

  /// Check if this beam collides with another beam at any position
  bool collidesWith(Beam other) {
    if (isRemoved || other.isRemoved) return false;

    for (final thisCell in cells) {
      if (other.containsPosition(thisCell.row, thisCell.column)) {
        return true;
      }
    }
    return false;
  }

  /// Get all collision points with other beams
  List<CollisionPoint> getCollisionsWith(List<Beam> otherBeams) {
    final collisions = <CollisionPoint>[];

    for (final otherBeam in otherBeams) {
      if (otherBeam.id == id || otherBeam.isRemoved) continue;

      for (final thisCell in cells) {
        for (final otherCell in otherBeam.cells) {
          if (thisCell.row == otherCell.row && thisCell.column == otherCell.column) {
            collisions.add(CollisionPoint(
              row: thisCell.row,
              column: thisCell.column,
              beam1: this,
              beam2: otherBeam,
            ));
          }
        }
      }
    }

    return collisions;
  }

  /// Mark beam as removed
  void remove() {
    // This will be handled by the game state manager
    // The actual modification will create a new Beam instance
  }

  /// Create a copy of Beam with optional field changes
  Beam copyWith({
    String? id,
    List<BeamCell>? cells,
    String? color,
    bool? isRemoved,
    bool? isSliding,
  }) {
    return Beam(
      id: id ?? this.id,
      cells: cells ?? this.cells,
      color: color ?? this.color,
      isRemoved: isRemoved ?? this.isRemoved,
      isSliding: isSliding ?? this.isSliding,
    );
  }

  /// Convert Beam to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'color': color,
      'cells': cells.map((cell) => [cell.row, cell.column, cell.type]).toList(),
    };
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
    return 'Beam(id: $id, color: $color, cells: ${cells.length}, removed: $isRemoved)';
  }
}

/// Represents a collision point between two beams
class CollisionPoint {
  final int row;
  final int column;
  final Beam beam1;
  final Beam beam2;

  CollisionPoint({
    required this.row,
    required this.column,
    required this.beam1,
    required this.beam2,
  });

  @override
  String toString() => 'CollisionPoint($row,$column, ${beam1.id}↔${beam2.id})';
}
