import 'package:flame/effects.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/cell.dart';
import '../../models/level.dart';
import '../components/beam_component.dart';

/// SlideAnimation - Animates beam sliding off the grid with snake movement
/// Ported from Swift: GameScene.swift lines 193-238
class SlideAnimation {
  static const double duration = 0.6; // 600ms as specified

  /// Create snake-slide effect for a beam
  /// The beam slides along its path like a snake until it exits the grid
  /// Direction: the beam's sliding direction
  /// Level: needed to calculate exit point
  static ComponentEffect createSlideEffect({
    required BeamComponent beamComponent,
    required Direction direction,
    required Level level,
    VoidCallback? onComplete,
  }) {
    debugPrint('🐍 Creating snake slide animation for beam in direction: $direction');

    // This will be a custom effect that updates the beam's path each frame
    // matching the Swift implementation's customAction approach
    return _SnakeSlideEffect(
      beamComponent: beamComponent,
      direction: direction,
      level: level,
      onComplete: onComplete,
    );
  }

  /// Create fade-out effect to accompany slide
  static OpacityEffect createFadeEffect({VoidCallback? onComplete}) {
    return OpacityEffect.fadeOut(
      EffectController(
        duration: duration,
        curve: Curves.easeIn,
      ),
      onComplete: onComplete,
    );
  }
}

/// Custom effect that implements the snake slide animation
/// Ported from Swift: GameScene.swift customAction (lines 216-231)
class _SnakeSlideEffect extends ComponentEffect {
  final BeamComponent beamComponent;
  final Direction direction;
  final Level level;

  late List<Vector2> _originalPoints;
  late List<Vector2> _trajectory;
  late double _beamLength;
  late double _totalTrajectoryLength;

  _SnakeSlideEffect({
    required this.beamComponent,
    required this.direction,
    required this.level,
    VoidCallback? onComplete,
  }) : super(
          EffectController(
            duration: SlideAnimation.duration,
            onMax: onComplete,
          ),
        );

  @override
  void onMount() {
    super.onMount();

    // Build the trajectory path (original path + exit point)
    _buildTrajectory();

    debugPrint('🐍 Snake slide mounted: ${_originalPoints.length} points, trajectory length: $_totalTrajectoryLength');
  }

  void _buildTrajectory() {
    // Get original beam path points
    _originalPoints = beamComponent.beam.cells
        .map((cell) => beamComponent.gridComponent.getCellCenter(cell.row, cell.column))
        .toList();

    if (_originalPoints.isEmpty) {
      _trajectory = [];
      _beamLength = 0;
      _totalTrajectoryLength = 0;
      return;
    }

    // Calculate beam length
    _beamLength = _calculatePathLength(_originalPoints);

    // Build trajectory: original path + exit point
    _trajectory = List.from(_originalPoints);

    // Add exit point (2000 units away in the sliding direction)
    final tipPoint = _originalPoints.last;
    const exitDistance = 2000.0;
    Vector2 exitPoint;

    switch (direction) {
      case Direction.right:
        exitPoint = Vector2(tipPoint.x + exitDistance, tipPoint.y);
        break;
      case Direction.left:
        exitPoint = Vector2(tipPoint.x - exitDistance, tipPoint.y);
        break;
      case Direction.up:
        exitPoint = Vector2(tipPoint.x, tipPoint.y - exitDistance);
        break;
      case Direction.down:
        exitPoint = Vector2(tipPoint.x, tipPoint.y + exitDistance);
        break;
      case Direction.none:
        exitPoint = tipPoint;
        break;
    }

    _trajectory.add(exitPoint);
    _totalTrajectoryLength = _calculatePathLength(_trajectory);
  }

  @override
  void apply(double progress) {
    // Quadratic easing (t * t) to match Swift
    final easedT = progress * progress;

    // Calculate how far along the trajectory the beam has moved
    final moveDistance = _totalTrajectoryLength * easedT;

    // The beam's visible portion: from moveDistance to moveDistance + beamLength
    final startDist = moveDistance;
    final endDist = startDist + _beamLength;

    // Extract the visible portion of the trajectory
    final newPoints = _extractSubPath(
      points: _trajectory,
      startDistance: startDist,
      endDistance: endDist,
    );

    if (newPoints.isEmpty) {
      // Beam has completely exited - hide it
      beamComponent.opacity = 0;
      debugPrint('🐍 Beam fully exited at progress: $progress');
    } else {
      // Update the beam's path to show the snake movement
      beamComponent.updatePath(newPoints);
    }
  }


  /// Calculate total length of a path
  /// Ported from Swift: GameScene.swift calculatePathLength (lines 481-485)
  double _calculatePathLength(List<Vector2> points) {
    double dist = 0;
    for (int i = 0; i < points.length - 1; i++) {
      dist += (points[i + 1] - points[i]).length;
    }
    return dist;
  }

  /// Extract a sub-path between two distances along the path
  /// Ported from Swift: GameScene.swift extractSubPath (lines 460-479)
  List<Vector2> _extractSubPath({
    required List<Vector2> points,
    required double startDistance,
    required double endDistance,
  }) {
    List<Vector2> result = [];
    double currentDist = 0;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final segmentDist = (p2 - p1).length;
      final nextDist = currentDist + segmentDist;

      if (nextDist > startDistance && currentDist < endDistance) {
        // Calculate entry point into this segment
        final entryRatio = (startDistance - currentDist).clamp(0, segmentDist) / segmentDist;
        final pEntry = Vector2(
          p1.x + (p2.x - p1.x) * entryRatio,
          p1.y + (p2.y - p1.y) * entryRatio,
        );

        // Calculate exit point from this segment
        final exitRatio = ((endDistance - currentDist) / segmentDist).clamp(0, 1);
        final pExit = Vector2(
          p1.x + (p2.x - p1.x) * exitRatio,
          p1.y + (p2.y - p1.y) * exitRatio,
        );

        if (result.isEmpty) {
          result.add(pEntry);
        }

        if (exitRatio >= 1.0) {
          result.add(p2);
        } else {
          result.add(pExit);
        }
      }

      currentDist = nextDist;
      if (currentDist >= endDistance) break;
    }

    return result;
  }
}
