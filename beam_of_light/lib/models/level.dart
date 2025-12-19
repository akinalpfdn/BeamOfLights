import 'package:uuid/uuid.dart';
import 'cell.dart';
import 'grid_size.dart';

/// Level model - represents a complete game level
/// Ported from Swift: BeamOfLights/Models/Level.swift
class Level {
  final String id;
  final int levelNumber;
  final GridSize gridSize;
  final int difficulty; // Number of hearts (3-5)
  final List<Cell> cells;

  Level({
    String? id,
    required this.levelNumber,
    required this.gridSize,
    required this.difficulty,
    required this.cells,
  }) : id = id ?? const Uuid().v4();

  /// Create Level from JSON
  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      levelNumber: json['levelNumber'] as int,
      gridSize: GridSize.fromJson(json['gridSize'] as Map<String, dynamic>),
      difficulty: json['difficulty'] as int,
      cells: (json['cells'] as List<dynamic>)
          .map((cellJson) => Cell.fromJson(cellJson as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert Level to JSON
  Map<String, dynamic> toJson() {
    return {
      'levelNumber': levelNumber,
      'gridSize': gridSize.toJson(),
      'difficulty': difficulty,
      'cells': cells.map((cell) => cell.toJson()).toList(),
    };
  }

  /// Get cell at specific position
  /// Returns null if no cell exists at that position
  Cell? cellAt(int row, int column) {
    try {
      return cells.firstWhere(
        (cell) => cell.row == row && cell.column == column,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get the start cell (where a beam begins)
  Cell? get startCell {
    try {
      return cells.firstWhere((cell) => cell.type == CellType.start);
    } catch (e) {
      return null;
    }
  }

  /// Get the end cell (where a beam terminates)
  Cell? get endCell {
    try {
      return cells.firstWhere((cell) => cell.type == CellType.end);
    } catch (e) {
      return null;
    }
  }

  /// Get all cells of a specific color
  List<Cell> cellsWithColor(String color) {
    return cells.where((cell) => cell.color == color).toList();
  }

  @override
  String toString() {
    return 'Level(#$levelNumber, ${gridSize.rows}x${gridSize.columns}, difficulty: $difficulty, cells: ${cells.length})';
  }
}

/// LevelsData - container for all levels loaded from JSON
/// Ported from Swift: BeamOfLights/Models/Level.swift
class LevelsData {
  final List<Level> levels;

  const LevelsData({required this.levels});

  /// Create LevelsData from JSON
  factory LevelsData.fromJson(Map<String, dynamic> json) {
    return LevelsData(
      levels: (json['levels'] as List<dynamic>)
          .map((levelJson) => Level.fromJson(levelJson as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert LevelsData to JSON
  Map<String, dynamic> toJson() {
    return {
      'levels': levels.map((level) => level.toJson()).toList(),
    };
  }

  @override
  String toString() => 'LevelsData(${levels.length} levels)';
}
