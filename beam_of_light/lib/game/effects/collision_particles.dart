import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// CollisionParticles - Simple particle effect for beam collisions
class CollisionParticles extends PositionComponent {
  final Color color;
  final Vector2 spawnPosition;

  static const int particleCount = 8;
  static const double particleSpeed = 150.0;
  static const double particleLifetime = 0.4;

  final List<_Particle> _particles = [];
  double _elapsed = 0.0;

  CollisionParticles({
    required this.color,
    required this.spawnPosition,
  }) : super(priority: 100); // Render on top

  @override
  Future<void> onLoad() async {
    position = spawnPosition;

    // Create particles in all directions
    final random = Random();
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * pi;
      final velocity = Vector2(
        cos(angle) * particleSpeed,
        sin(angle) * particleSpeed,
      );

      _particles.add(_Particle(
        position: Vector2.zero(),
        velocity: velocity,
        size: 3.0 + random.nextDouble() * 2.0,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _elapsed += dt;

    if (_elapsed >= particleLifetime) {
      removeFromParent();
      return;
    }

    // Update particles
    for (final particle in _particles) {
      particle.position += particle.velocity * dt;
      particle.velocity *= 0.95; // Friction
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = _elapsed / particleLifetime;
    final opacity = 1.0 - progress;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    for (final particle in _particles) {
      canvas.drawCircle(
        Offset(particle.position.x, particle.position.y),
        particle.size * (1.0 - progress * 0.5),
        paint,
      );
    }
  }
}

class _Particle {
  Vector2 position;
  Vector2 velocity;
  double size;

  _Particle({
    required this.position,
    required this.velocity,
    required this.size,
  });
}
