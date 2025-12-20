import 'dart:ui';
import 'package:flame/components.dart';
import '../../utils/constants.dart';

/// MarkerType - Type of marker to render
enum MarkerType {
  start, // Green circle for beam start
  end, // Red circle for beam end
}

/// MarkerComponent - Renders start/end markers for beams
/// Simple circles for Phase 6 (will be enhanced in later phases)
class MarkerComponent extends PositionComponent {
  final MarkerType color;
  final String beamColor;

  static const double markerRadius = 12.0;
  late Paint _markerPaint;
  late Paint _borderPaint;

  MarkerComponent({
    required Vector2 position,
    required this.color,
    required this.beamColor,
  }) : super(
          position: position,
          size: Vector2.all(markerRadius * 2),
          anchor: Anchor.center,
          priority: 15, // Render on top of beams
        );

  @override
  Future<void> onLoad() async {
    // Determine marker color
    final Color fillColor;
    if (color == MarkerType.start) {
      fillColor = const Color(0xFF00FF00); // Green for start
    } else {
      fillColor = const Color(0xFFFF0000); // Red for end
    }

    // Create paints
    _markerPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    // Parse beam color for border
    final beamColorParsed = GameConstants.parseHexColor(beamColor);
    _borderPaint = Paint()
      ..color = beamColorParsed
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw filled circle
    canvas.drawCircle(
      Offset(markerRadius, markerRadius),
      markerRadius,
      _markerPaint,
    );

    // Draw border
    canvas.drawCircle(
      Offset(markerRadius, markerRadius),
      markerRadius,
      _borderPaint,
    );
  }
}
