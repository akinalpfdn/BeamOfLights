import 'package:uuid/uuid.dart';

/// Cell type enum - represents the type of grid cell
/// Ported from Swift: BeamOfLights/Models/Cell.swift
enum CellType {
  start,
  end,
  path,
  empty;

  /// Parse from JSON string
  static CellType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'start':
        return CellType.start;
      case 'end':
        return CellType.end;
      case 'path':
        return CellType.path;
      case 'empty':
        return CellType.empty;
      default:
        return CellType.empty;
    }
  }

  /// Convert to JSON string
  String toJson() {
    return name;
  }
}

/// Direction enum - represents the direction of a beam arrow
/// Ported from Swift: BeamOfLights/Models/Cell.swift
enum Direction {
  up,
  down,
  left,
  right,
  none;

  /// Parse from JSON string
  static Direction fromString(String value) {
    switch (value.toLowerCase()) {
      case 'up':
        return Direction.up;
      case 'down':
        return Direction.down;
      case 'left':
        return Direction.left;
      case 'right':
        return Direction.right;
      case 'none':
        return Direction.none;
      default:
        return Direction.none;
    }
  }

  /// Convert to JSON string
  String toJson() {
    return name;
  }
}

/// Cell model - represents a single grid cell in the game
/// Ported from Swift: BeamOfLights/Models/Cell.swift
class Cell {
  final String id;
  final int row;
  final int column;
  final CellType type;
  final Direction direction;
  final String color;

  Cell({
    String? id,
    required this.row,
    required this.column,
    required this.type,
    required this.direction,
    required this.color,
  }) : id = id ?? const Uuid().v4();

  /// Create Cell from JSON
  factory Cell.fromJson(Map<String, dynamic> json) {
    return Cell(
      row: json['row'] as int,
      column: json['column'] as int,
      type: CellType.fromString(json['type'] as String),
      direction: Direction.fromString(json['direction'] as String),
      color: json['color'] as String? ?? '',
    );
  }

  /// Convert Cell to JSON
  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'column': column,
      'type': type.toJson(),
      'direction': direction.toJson(),
      'color': color,
    };
  }

  /// Create a copy of Cell with optional field changes
  Cell copyWith({
    String? id,
    int? row,
    int? column,
    CellType? type,
    Direction? direction,
    String? color,
  }) {
    return Cell(
      id: id ?? this.id,
      row: row ?? this.row,
      column: column ?? this.column,
      type: type ?? this.type,
      direction: direction ?? this.direction,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cell &&
        other.row == row &&
        other.column == column &&
        other.type == type &&
        other.direction == direction &&
        other.color == color;
  }

  @override
  int get hashCode {
    return Object.hash(row, column, type, direction, color);
  }

  @override
  String toString() {
    return 'Cell(row: $row, col: $column, type: $type, dir: $direction, color: $color)';
  }
}
