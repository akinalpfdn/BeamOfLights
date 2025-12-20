import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/level.dart';

/// LevelService - handles loading and managing escape puzzle game levels
/// Updated to load individual level files (lvl1.json, lvl2.json, etc.)
class LevelService {
  static final Map<int, Level> _cachedLevels = {};

  /// Load a specific level by number (lvl1.json, lvl2.json, etc.)
  static Future<Level?> loadLevel(int levelNumber) async {
    print('🔍 Loading level $levelNumber...');

    // Return cached level if already loaded
    if (_cachedLevels.containsKey(levelNumber)) {
      print('✅ Level $levelNumber found in cache');
      return _cachedLevels[levelNumber];
    }

    try {
      final assetPath = 'assets/levels/lvl$levelNumber.json';
      print('📂 Attempting to load: $assetPath');

      // Load JSON string from assets
      final jsonString = await rootBundle.loadString(assetPath);
      print('📄 Successfully loaded JSON string: ${jsonString.length} characters');

      // Parse JSON
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // Deserialize to Level
      final level = Level.fromJson(jsonData);
      print('✅ Successfully parsed level ${level.levelNumber} with ${level.beams.length} beams');

      // Cache the level
      _cachedLevels[levelNumber] = level;

      return level;
    } catch (e) {
      print('❌ Failed to load level $levelNumber: $e');
      throw Exception('Failed to load level $levelNumber: $e');
    }
  }

  /// Load all available levels by scanning for lvl*.json files
  /// Returns a list of Level objects ordered by level number
  static Future<List<Level>> loadAllLevels() async {
    final levels = <Level>[];
    int levelNumber = 1;

    // Keep loading levels until one fails to load
    while (true) {
      try {
        final level = await loadLevel(levelNumber);
        if (level != null) {
          levels.add(level);
          levelNumber++;
        } else {
          break;
        }
      } catch (e) {
        // If we can't load a level, assume we've reached the end
        break;
      }
    }

    return levels;
  }

  /// Get a specific level by number
  static Future<Level?> getLevel(int levelNumber) async {
    return await loadLevel(levelNumber);
  }

  /// Get the total number of available levels
  static Future<int> getLevelCount() async {
    final levels = await loadAllLevels();
    return levels.length;
  }

  /// Clear cached levels (useful for testing or reloading)
  static void clearCache() {
    _cachedLevels.clear();
  }

  /// Clear specific level from cache
  static void clearLevelCache(int levelNumber) {
    _cachedLevels.remove(levelNumber);
  }

  /// Validate that a level has required data for escape puzzle game
  /// Returns true if the level is valid for gameplay
  static bool validateLevel(Level level) {
    // Must have beams
    if (level.beams.isEmpty) return false;

    // Grid size must be positive
    if (level.gridSize.rows <= 0 || level.gridSize.columns <= 0) {
      return false;
    }

    // Difficulty must be 3-5 hearts
    if (level.difficulty < 3 || level.difficulty > 5) {
      return false;
    }

    // Each beam must have at least 2 cells
    for (final beam in level.beams) {
      if (beam.cells.length < 2) return false;
    }

    return true;
  }

  /// Check if a level number exists
  static Future<bool> levelExists(int levelNumber) async {
    try {
      final level = await loadLevel(levelNumber);
      return level != null;
    } catch (e) {
      return false;
    }
  }
}
