import '../models/beam.dart';
import '../models/level.dart';

/// BeamBuilder - compatibility layer for legacy code
/// DEPRECATED: Levels now contain beams directly in the new structure
/// This is kept for backward compatibility during transition
@Deprecated('Use level.beams directly instead of this builder')
class BeamBuilder {
  /// Build all beams for a given level
  /// DEPRECATED: Use level.beams directly instead
  @Deprecated('Use level.beams directly instead of this builder')
  static List<Beam> buildBeams(Level level) {
    return level.beams;
  }
}