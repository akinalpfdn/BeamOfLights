import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// AudioService - Manages game sound effects
/// Uses simple tone generation for minimal audio
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;

  bool get soundEnabled => _soundEnabled;

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Play tap sound (brief click)
  Future<void> playTap() async {
    if (!_soundEnabled) return;

    try {
      // Use system sound or simple beep
      await _player.play(AssetSource('sounds/tap.wav'), volume: 0.3);
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }

  /// Play slide success sound
  Future<void> playSlideSuccess() async {
    if (!_soundEnabled) return;

    try {
      await _player.play(AssetSource('sounds/slide.wav'), volume: 0.4);
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }

  /// Play collision sound
  Future<void> playCollision() async {
    if (!_soundEnabled) return;

    try {
      await _player.play(AssetSource('sounds/collision.wav'), volume: 0.5);
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }

  /// Play win sound
  Future<void> playWin() async {
    if (!_soundEnabled) return;

    try {
      await _player.play(AssetSource('sounds/win.wav'), volume: 0.6);
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }

  /// Play lose sound
  Future<void> playLose() async {
    if (!_soundEnabled) return;

    try {
      await _player.play(AssetSource('sounds/lose.mp3'), volume: 0.5);
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
