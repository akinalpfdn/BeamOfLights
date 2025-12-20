import 'package:flame/effects.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/beam.dart';
import '../components/beam_component.dart';

/// BounceAnimation - Animates beam bouncing back on collision
/// Ported from Swift: GameScene.swift lines 242-275
class BounceAnimation {
  static const double duration = 0.3; // 300ms
  static const double bounceDistance = 20.0; // 20pt movement in direction (matching Swift)

  /// Create bounce effect for a beam that collided
  /// Direction: the beam's attempted movement direction
  static ComponentEffect createBounceEffect({
    required BeamComponent beamComponent,
    required BeamDirection direction,
    VoidCallback? onComplete,
  }) {
    // Calculate bounce movement vector (small distance)
    final Vector2 bounceVector;
    switch (direction) {
      case BeamDirection.up:
        bounceVector = Vector2(0, -bounceDistance);
        break;
      case BeamDirection.down:
        bounceVector = Vector2(0, bounceDistance);
        break;
      case BeamDirection.left:
        bounceVector = Vector2(-bounceDistance, 0);
        break;
      case BeamDirection.right:
        bounceVector = Vector2(bounceDistance, 0);
        break;
      case BeamDirection.none:
        bounceVector = Vector2.zero();
        break;
    }

    return _BounceOffsetEffect(
      beamComponent: beamComponent,
      bounceVector: bounceVector,
      onComplete: onComplete,
    );
  }

  /// Create flash effect (white overlay) for collision
  static ColorEffect createFlashEffect({VoidCallback? onComplete}) {
    return ColorEffect(
      Colors.white,
      EffectController(
        duration: duration,
        reverseDuration: duration / 2,
        curve: Curves.easeInOut,
      ),
      opacityFrom: 0.0,
      opacityTo: 0.6,
      onComplete: onComplete,
    );
  }

  /// Create combined bounce + flash effect
  static ComponentEffect createFullBounceEffect({
    required BeamComponent beamComponent,
    required BeamDirection direction,
    VoidCallback? onComplete,
  }) {
    // Apply both bounce movement and flash simultaneously
    // Since we can't truly run in parallel with SequenceEffect,
    // we'll add the flash as a separate effect
    Future.delayed(Duration.zero, () {
      beamComponent.add(createFlashEffect());
    });

    return createBounceEffect(
      beamComponent: beamComponent,
      direction: direction,
      onComplete: onComplete,
    );
  }
}

/// Custom effect that animates the bounceOffset property
class _BounceOffsetEffect extends ComponentEffect {
  final BeamComponent beamComponent;
  final Vector2 bounceVector;

  _BounceOffsetEffect({
    required this.beamComponent,
    required this.bounceVector,
    VoidCallback? onComplete,
  }) : super(
          EffectController(
            duration: BounceAnimation.duration,
            onMax: onComplete,
          ),
        );

  @override
  void apply(double progress) {
    if (progress < 0.5) {
      // First half: move forward (easeOut)
      final t = progress * 2; // 0 to 1
      final eased = Curves.easeOut.transform(t);
      beamComponent.bounceOffset = bounceVector * eased;
    } else {
      // Second half: spring back (elasticOut)
      final t = (progress - 0.5) * 2; // 0 to 1
      final eased = Curves.elasticOut.transform(t);
      beamComponent.bounceOffset = bounceVector * (1 - eased);
    }
  }

  @override
  void onMount() {
    super.onMount();
    beamComponent.bounceOffset = Vector2.zero();
  }

  @override
  void onRemove() {
    beamComponent.bounceOffset = Vector2.zero();
    super.onRemove();
  }
}
