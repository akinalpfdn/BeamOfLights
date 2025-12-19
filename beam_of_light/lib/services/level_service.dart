import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/level.dart';

/// LevelService - handles loading and managing game levels
/// Ported from Swift: BeamOfLights/ViewModels/GameViewModel.swift (loadLevels method)
class LevelService {
  static List<Level>? _cachedLevels;

  /// Load all levels from the levels.json asset file
  /// Returns a list of Level objects parsed from JSON
  /// Caches the result for subsequent calls
  static Future<List<Level>> loadAllLevels() async {
    // Return cached levels if already loaded
    if (_cachedLevels != null) {
      return _cachedLevels!;
    }

    try {
      // Load JSON string from assets
      final jsonString = await rootBundle.loadString('assets/levels.json');

      // Parse JSON
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // Deserialize to LevelsData
      final levelsData = LevelsData.fromJson(jsonData);

      // Cache the levels
      _cachedLevels = levelsData.levels;

      return levelsData.levels;
    } catch (e) {
      throw Exception('Failed to load levels: $e');
    }
  }

  /// Get a specific level by index
  /// Returns null if index is out of bounds
  static Future<Level?> getLevel(int index) async {
    final levels = await loadAllLevels();

    if (index < 0 || index >= levels.length) {
      return null;
    }

    return levels[index];
  }

  /// Get the total number of levels
  static Future<int> getLevelCount() async {
    final levels = await loadAllLevels();
    return levels.length;
  }

  /// Clear the cached levels (useful for testing or reloading)
  static void clearCache() {
    _cachedLevels = null;
  }

  /// Validate that a level has required data
  /// Returns true if the level is valid for gameplay
  static bool validateLevel(Level level) {
    // Must have cells
    if (level.cells.isEmpty) return false;

    // Grid size must be positive
    if (level.gridSize.rows <= 0 || level.gridSize.columns <= 0) {
      return false;
    }

    // Difficulty must be 3-5 hearts
    if (level.difficulty < 3 || level.difficulty > 5) {
      return false;
    }

    // Must have at least one colored cell
    final coloredCells = level.cells.where((cell) => cell.color.isNotEmpty);
    if (coloredCells.isEmpty) return false;

    return true;
  }
}
