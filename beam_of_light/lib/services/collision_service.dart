import '../models/beam.dart';
import '../models/cell.dart';
import '../models/level.dart';

/// GridPosition - helper class for representing a grid coordinate
class GridPosition {
  final int row;
  final int column;

  const GridPosition(this.row, this.column);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GridPosition &&
        other.row == row &&
        other.column == column;
  }

  @override
  int get hashCode => Object.hash(row, column);

  @override
  String toString() => '($row,$column)';
}

/// CollisionService - handles collision detection and beam sliding path calculations
/// Ported from Swift: BeamOfLights/ViewModels/GameViewModel.swift
/// (willCollideWithOtherBeam, getBeamSlidingPath methods)
class CollisionService {
  /// Check if a beam will collide with any other beam when sliding
  /// Returns true if the beam's sliding path intersects with any existing beam cells
  /// Ported from Swift: GameViewModel.swift lines 266-279
  static bool willCollideWithOtherBeam(
    Beam movingBeam,
    List<Beam> allBeams,
    Level level,
  ) {
    final slidingPath = getBeamSlidingPath(movingBeam, level);

    if (slidingPath == null) return false;

    // Check collision with ALL beams (including the moving beam itself)
    // This is important because a beam can collide with itself in some configurations
    for (final otherBeam in allBeams) {
      for (final otherCell in otherBeam.cells) {
        // If the sliding path intersects with any existing cell, it's a collision
        for (final pathPosition in slidingPath) {
          if (pathPosition.row == otherCell.row &&
              pathPosition.column == otherCell.column) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Get the path that a beam will slide through when activated
  /// Calculates all grid positions the beam will traverse from its current tip
  /// to the edge of the grid in its direction
  /// Returns null if the beam has no direction
  /// Ported from Swift: GameViewModel.swift lines 282-311
  static List<GridPosition>? getBeamSlidingPath(Beam beam, Level level) {
    final direction = beam.direction;

    if (direction == Direction.none) return null;

    final tipCell = beam.tipCell;
    if (tipCell == null) return null;

    final List<GridPosition> path = [];

    int currentRow = tipCell.row;
    int currentColumn = tipCell.column;

    int steps = 0;
    final maxSteps = level.gridSize.rows + level.gridSize.columns + 1;

    // Keep moving in the direction until we hit the edge of the grid
    while (steps < maxSteps) {
      // Move one step in the beam's direction
      switch (direction) {
        case Direction.up:
          currentRow -= 1;
          break;
        case Direction.down:
          currentRow += 1;
          break;
        case Direction.left:
          currentColumn -= 1;
          break;
        case Direction.right:
          currentColumn += 1;
          break;
        case Direction.none:
          return path; // Should not happen, but handle it
      }

      // If out of bounds, we're done
      if (currentRow < 0 ||
          currentRow >= level.gridSize.rows ||
          currentColumn < 0 ||
          currentColumn >= level.gridSize.columns) {
        break;
      }

      // Add this position to the path
      path.add(GridPosition(currentRow, currentColumn));
      steps++;
    }

    return path;
  }

  /// Check if a specific grid position collides with any beam
  /// Used for more granular collision checking
  static bool positionCollidesWithBeam(
    int row,
    int column,
    Beam beam,
  ) {
    for (final cell in beam.cells) {
      if (cell.row == row && cell.column == column) {
        return true;
      }
    }
    return false;
  }

  /// Get all beams that would collide with a moving beam
  /// Returns a list of beams that intersect with the sliding path
  static List<Beam> getCollidingBeams(
    Beam movingBeam,
    List<Beam> allBeams,
    Level level,
  ) {
    final slidingPath = getBeamSlidingPath(movingBeam, level);

    if (slidingPath == null) return [];

    final List<Beam> collidingBeams = [];

    for (final otherBeam in allBeams) {
      for (final otherCell in otherBeam.cells) {
        for (final pathPosition in slidingPath) {
          if (pathPosition.row == otherCell.row &&
              pathPosition.column == otherCell.column) {
            if (!collidingBeams.contains(otherBeam)) {
              collidingBeams.add(otherBeam);
            }
            break;
          }
        }
      }
    }

    return collidingBeams;
  }

  /// Debug helper: Print collision path information
  static String debugCollisionPath(Beam beam, Level level) {
    final path = getBeamSlidingPath(beam, level);

    if (path == null) {
      return 'Beam ${beam.color}: No sliding path (direction: none)';
    }

    final buffer = StringBuffer();
    buffer.writeln(
        'Beam ${beam.color} sliding path (${path.length} positions):');
    buffer.writeln('  From: (${beam.tipCell?.row},${beam.tipCell?.column})');
    buffer.writeln('  Direction: ${beam.direction.name}');

    if (path.length <= 10) {
      buffer.write('  Path: ');
      buffer.writeln(path.map((p) => p.toString()).join(' → '));
    } else {
      buffer.writeln('  First 5: ${path.take(5).map((p) => p.toString()).join(' → ')}');
      buffer.writeln('  Last 5: ${path.skip(path.length - 5).map((p) => p.toString()).join(' → ')}');
    }

    return buffer.toString();
  }
}
