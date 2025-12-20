import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import '../models/level.dart';
import '../models/beam.dart';
import '../services/level_service.dart';
import '../services/collision_service.dart';
import '../services/audio_service.dart';

/// GameState enum - represents the current state of the game
/// Ported from Swift: GameViewModel.swift lines 13-17
enum GameState {
  playing,
  won,
  lost,
}

/// GameAction enum - events sent to the rendering layer for animations
/// Ported from Swift: GameViewModel.swift lines 20-24
enum GameAction {
  slideOut,
  bounce,
  reset,
}

/// GameProvider - Main game state management using Provider pattern
/// Replaces Swift's GameViewModel (MVVM → Provider pattern)
/// Ported from Swift: BeamOfLights/ViewModels/GameViewModel.swift lines 64-330
class GameProvider extends ChangeNotifier {
  // MARK: - State Properties

  Level? _currentLevel;
  GameState _gameState = GameState.playing;
  int _heartsRemaining = 3;
  List<Beam> _activeBeams = [];
  List<Level> _allLevels = [];
  int _currentLevelIndex = 0;

  // Event stream for animations (using StreamController instead of PassthroughSubject)
  final StreamController<GameActionEvent> _gameActionsController =
      StreamController<GameActionEvent>.broadcast();

  bool _showLevelCompleteAnimation = false;
  bool _isProcessingWin = false;

  // MARK: - Getters

  Level? get currentLevel => _currentLevel;
  GameState get gameState => _gameState;
  int get heartsRemaining => _heartsRemaining;
  List<Beam> get activeBeams => List.unmodifiable(_activeBeams);
  List<Level> get allLevels => List.unmodifiable(_allLevels);
  int get currentLevelIndex => _currentLevelIndex;
  Stream<GameActionEvent> get gameActions => _gameActionsController.stream;
  bool get showLevelCompleteAnimation => _showLevelCompleteAnimation;

  // MARK: - Initialization

  GameProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadLevels();
    if (_allLevels.isNotEmpty) {
      await loadLevel(0);
    }
  }

  // MARK: - Level Loading

  /// Load all levels from JSON file
  /// Ported from Swift: GameViewModel.swift lines 94-109
  Future<void> loadLevels() async {
    try {
      _allLevels = await LevelService.loadAllLevels();
      debugPrint('✅ Loaded ${_allLevels.length} levels');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading levels: $e');
    }
  }

  /// Load specific level by index
  /// Ported from Swift: GameViewModel.swift lines 112-124
  Future<void> loadLevel(int index) async {
    if (index < 0 || index >= _allLevels.length) {
      debugPrint('❌ Invalid level index: $index');
      return;
    }

    _currentLevelIndex = index;
    _currentLevel = _allLevels[index];
    resetLevel();
    _buildBeams();
    _sendGameAction(GameActionEvent(GameAction.reset, null, null));

    debugPrint(
        '✅ Loaded level ${_currentLevel?.levelNumber} with ${_activeBeams.length} beams');
    notifyListeners();
  }

  /// Move to next level
  /// Ported from Swift: GameViewModel.swift lines 127-135
  Future<void> nextLevel() async {
    _isProcessingWin = false;
    _gameState = GameState.playing;
    final nextIndex = _currentLevelIndex + 1;

    if (nextIndex < _allLevels.length) {
      await loadLevel(nextIndex);
    } else {
      debugPrint('🎉 All levels completed!');
    }
  }

  /// Reset current level
  /// Ported from Swift: GameViewModel.swift lines 138-144
  void resetLevel() {
    _gameState = GameState.playing;
    _isProcessingWin = false;
    _showLevelCompleteAnimation = false;
    _activeBeams = [];
    _heartsRemaining = _currentLevel?.difficulty ?? 3;
    notifyListeners();
  }

  // MARK: - Beam Building

  /// Build all beams from level cells by grouping cells with same color
  /// Ported from Swift: GameViewModel.swift lines 149-167
  void _buildBeams() {
    if (_currentLevel == null) return;

    _activeBeams = _currentLevel!.beams;
  }

  // MARK: - Game Logic

  /// Handle beam tap - check logic and trigger action
  /// Ported from Swift: GameViewModel.swift lines 212-230
  void tapBeam({required int row, required int column}) {
    if (_gameState != GameState.playing) return;

    // Find which beam was tapped
    final beamIndex = _activeBeams.indexWhere((beam) {
      return beam.cells.any((cell) => cell.row == row && cell.column == column);
    });

    if (beamIndex == -1) return;

    final beam = _activeBeams[beamIndex];

    // Prevent tapping a beam that's already sliding
    if (beam.isSliding) {
      debugPrint('⚠️ Beam already sliding, ignoring tap');
      return;
    }

    // Play tap sound and haptic
    debugPrint('🔊 TAP - Playing sound and haptic');
    AudioService().playTap();
    Vibration.vibrate(duration: 10); // Light tap vibration

    // Check collision logic
    if (_willCollideWithOtherBeam(beam)) {
      // Collision → Bounce
      _handleCollision(beam);
    } else {
      // Clear path → Slide out
      _handleSuccess(beam, beamIndex);
    }
  }

  /// Handle collision (lose a heart, trigger bounce animation)
  /// Ported from Swift: GameViewModel.swift lines 232-244
  void _handleCollision(Beam beam) {
    // Lose a heart
    _heartsRemaining -= 1;

    debugPrint('💥 COLLISION - Playing sound and haptic');

    // Play collision sound
    AudioService().playCollision();

    // Haptic feedback (error) - heavy vibration
    Vibration.vibrate(duration: 100, amplitude: 255);

    // Trigger bounce animation
    _sendGameAction(GameActionEvent(GameAction.bounce, beam.id, beam.direction));

    if (_heartsRemaining <= 0) {
      _gameState = GameState.lost;
      AudioService().playLose();
    }

    notifyListeners();
  }

  /// Handle successful slide (remove beam, check win condition)
  /// Ported from Swift: GameViewModel.swift lines 246-263
  void _handleSuccess(Beam beam, int index) {
    // Mark beam as sliding to prevent re-tapping
    _activeBeams[index] = beam.copyWith(isSliding: true);

    debugPrint('✅ SLIDE - Playing sound');

    // Small delay before slide sound to avoid cutting off tap sound
    Future.delayed(const Duration(milliseconds: 50), () {
      AudioService().playSlideSuccess();
    });

    // Trigger slide animation
    _sendGameAction(
        GameActionEvent(GameAction.slideOut, beam.id, beam.direction));

    // Note: We don't remove the beam yet - let animation complete first
    // The BeamRenderer will call removeBeamAfterAnimation() in onComplete callback

    notifyListeners();
  }

  /// Remove beam after animation completes (called by BeamRenderer)
  void removeBeamAfterAnimation(String beamId) {
    _activeBeams.removeWhere((b) => b.id == beamId);

    if (_activeBeams.isEmpty) {
      _handleWin();
    }

    notifyListeners();
  }

  /// Check if beam will collide with another beam OR itself when sliding
  /// Ported from Swift: GameViewModel.swift lines 266-279
  bool _willCollideWithOtherBeam(Beam beam) {
    if (_currentLevel == null) return false;

    return CollisionService.willCollideWithOtherBeam(
      beam,
      _activeBeams,
      _currentLevel!,
    );
  }

  /// Handle win condition (level complete)
  /// Ported from Swift: GameViewModel.swift lines 318-329
  void _handleWin() {
    if (_isProcessingWin || _gameState != GameState.playing) return;

    _isProcessingWin = true;
    _gameState = GameState.won;
    _showLevelCompleteAnimation = true;

    // Play win sound
    AudioService().playWin();

    // Haptic feedback (success) - celebratory double vibration
    Vibration.vibrate(duration: 100, amplitude: 255);
    Future.delayed(const Duration(milliseconds: 150), () {
      Vibration.vibrate(duration: 100, amplitude: 255);
    });

    notifyListeners();
  }

  /// Send game action event to animation layer
  void _sendGameAction(GameActionEvent event) {
    _gameActionsController.add(event);
  }

  // MARK: - Cleanup

  @override
  void dispose() {
    _gameActionsController.close();
    super.dispose();
  }
}

/// GameActionEvent - wrapper for game actions with associated data
class GameActionEvent {
  final GameAction action;
  final String? beamId;
  final BeamDirection? direction;

  GameActionEvent(this.action, this.beamId, this.direction);

  @override
  String toString() =>
      'GameActionEvent(action: $action, beamId: ${beamId?.substring(0, 8)}..., direction: $direction)';
}
