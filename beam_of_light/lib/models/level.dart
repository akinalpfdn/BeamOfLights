import 'package:uuid/uuid.dart';
import 'grid_size.dart';
import 'beam.dart';

/// Level model - represents a complete escape puzzle game level
class Level {
  final String id;
  final int levelNumber;
  final String? name;
  final String? description;
  final GridSize gridSize;
  final int difficulty; // Number of hearts (3-5)
  final List<Beam> beams;
  final List<String>? solution;
  final List<String>? hints;

  Level({
    String? id,
    required this.levelNumber,
    this.name,
    this.description,
    required this.gridSize,
    required this.difficulty,
    required this.beams,
    this.solution,
    this.hints,
  }) : id = id ?? const Uuid().v4();

  /// Create Level from JSON
  factory Level.fromJson(Map<String, dynamic> json) {
    final List<Beam> beams = (json['beams'] as List<dynamic>)
        .map((beamJson) => Beam.fromJson(beamJson as Map<String, dynamic>))
        .toList();

    return Level(
      levelNumber: json['levelNumber'] as int,
      name: json['name'] as String?,
      description: json['description'] as String?,
      gridSize: GridSize.fromJson(json['gridSize'] as Map<String, dynamic>),
      difficulty: json['difficulty'] as int,
      beams: beams,
      solution: (json['solution'] as List<dynamic>?)?.cast<String>(),
      hints: (json['hints'] as List<dynamic>?)?.cast<String>(),
    );
  }

  /// Convert Level to JSON
  Map<String, dynamic> toJson() {
    return {
      'levelNumber': levelNumber,
      'name': name,
      'description': description,
      'gridSize': gridSize.toJson(),
      'difficulty': difficulty,
      'beams': beams.map((beam) => beam.toJson()).toList(),
      'solution': solution,
      'hints': hints,
    };
  }

  /// Get beam by color or id
  Beam? getBeamByIdentifier(String identifier) {
    try {
      return beams.firstWhere((beam) => beam.id == identifier || beam.color == identifier);
    } catch (e) {
      return null;
    }
  }

  /// Get all active beams (not removed)
  List<Beam> get activeBeams => beams.where((beam) => !beam.isRemoved).toList();

  /// Get all collision points in the level
  List<CollisionPoint> getAllCollisions() {
    final collisions = <CollisionPoint>[];
    final activeBeams = this.activeBeams;

    for (int i = 0; i < activeBeams.length; i++) {
      for (int j = i + 1; j < activeBeams.length; j++) {
        collisions.addAll(activeBeams[i].getCollisionsWith([activeBeams[j]]));
      }
    }

    return collisions;
  }

  /// Check if level is completed (no collisions)
  bool get isCompleted => getAllCollisions().isEmpty;

  @override
  String toString() {
    return 'Level(#$levelNumber, ${gridSize.rows}x${gridSize.columns}, difficulty: $difficulty, beams: ${beams.length})';
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
