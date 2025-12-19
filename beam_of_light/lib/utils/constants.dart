import 'dart:ui';

/// Game constants ported from Swift BeamOfLights game
class GameConstants {
  // Grid Configuration
  static const double gridCellSize = 50.0; // Fixed cell size for sharp neon rendering

  // Animation Durations
  static const double slideAnimationDuration = 0.6; // Slide-out animation (seconds)
  static const double bounceAnimationDuration = 0.3; // Bounce animation (seconds)
  static const double bounceDistance = 20.0; // Bounce movement distance
  static const double tipPulseAnimationDuration = 1.5; // Tip pulse loop (seconds)

  // Z-Positions (rendering layers)
  static const double zPosGrid = 0;
  static const double zPosBeamGlow = 10;
  static const double zPosBeamCore = 11;
  static const double zPosBeamTip = 12;

  // Neon Effect Parameters (4-layer glow)
  static const double outerHazeWidth = 0.4; // Multiplier of gridCellSize
  static const double outerHazeOpacity = 0.15;
  static const double innerGlowWidth = 0.2; // Multiplier of gridCellSize
  static const double innerGlowOpacity = 0.6;
  static const double coreWidth = 0.05; // Multiplier of gridCellSize
  static const double tipRadius = 0.1; // Multiplier of gridCellSize
  static const double tipAuraRadius = 0.15; // Multiplier of gridCellSize
  static const double tipAuraOpacity = 0.4;

  // Camera Configuration
  static const double minZoom = 1.0; // Show full grid
  static const double maxZoom = 3.0; // Close-up zoom
  static const double cameraPadding = 100.0; // Padding around grid

  // Performance Targets
  static const int targetFps = 60;
  static const int maxMemoryMb = 150;

  // Game Timing
  static const double levelCompleteDelay = 1.5; // Auto-advance delay (seconds)
  static const double collisionFlashDuration = 0.1;
  static const double collisionFlashOpacity = 0.3;

  // Color Mappings (from Swift UIColor mappings)
  static const Map<String, Color> beamColors = {
    'blue': Color(0xFF00CED1), // Cyan
    'pink': Color(0xFFFF69B4), // Hot Pink
    'purple': Color(0xFF9370DB), // Medium Purple
    'green': Color(0xFF00FF00), // Green
    'orange': Color(0xFFFFA500), // Orange
    'red': Color(0xFFFF0000), // Red
    'yellow': Color(0xFFFFFF00), // Yellow
  };

  // Grid Display
  static const double gridDotRadius = 2.0;
  static const double gridDotOpacity = 0.15;
  static const Color gridDotColor = Color(0xFFFFFFFF); // White

  // Background Colors
  static const Color darkBackground = Color(0xFF292A3A); // #292A3A from Swift

  // Helper Methods

  /// Parse hex color string (e.g., "#FFD5C8") to Color
  static Color parseHexColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Get beam color from color string (named color or hex)
  static Color getBeamColor(String colorString) {
    // Try named colors first
    final namedColor = beamColors[colorString.toLowerCase()];
    if (namedColor != null) return namedColor;

    // Try parsing as hex color
    if (colorString.startsWith('#')) {
      return parseHexColor(colorString);
    }

    // Default to white if unknown
    return const Color(0xFFFFFFFF);
  }
}
