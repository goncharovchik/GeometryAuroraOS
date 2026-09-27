import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Контроллер аудио и ритмической синхронизации
class AudioController extends ChangeNotifier {
  double _bpm = 128.0;
  double _playbackTimeSeconds = 0.0;
  bool _isPlaying = false;
  double latencyOffsetMs = 0.0;

  bool isMuted = false;
  double musicVolume = 1.0;
  double sfxVolume = 1.0;

  double get bpm => _bpm;
  double get playbackTimeSeconds => _playbackTimeSeconds;
  bool get isPlaying => _isPlaying;

  void setBpm(double bpm) {
    _bpm = bpm;
    notifyListeners();
  }

  void startPlayback() {
    _playbackTimeSeconds = 0.0;
    _isPlaying = true;
    notifyListeners();
  }

  void pausePlayback() {
    _isPlaying = false;
    notifyListeners();
  }

  void stopPlayback() {
    _isPlaying = false;
    _playbackTimeSeconds = 0.0;
    notifyListeners();
  }

  void update(double dt) {
    if (_isPlaying) {
      _playbackTimeSeconds += dt;
    }
  }

  /// Возвращает коэффициент пульсации от 0.0 до 1.0 на основе BPM и текущего времени
  double get bpmPulse {
    if (!_isPlaying) return 0.0;
    final beatDuration = 60.0 / _bpm;
    final adjustedTime = math.max(0.0, _playbackTimeSeconds - (latencyOffsetMs / 1000.0));
    final currentBeatProgress = (adjustedTime % beatDuration) / beatDuration;

    // Экспоненциальный спад от 1.0 до 0.0 на каждый удар
    return math.exp(-currentBeatProgress * 4.5);
  }

  // Звуковые эффекты
  void playJumpSfx() {
    if (isMuted) return;
    // SFX триггер (в нативной сборке под Аврору вызывает audioplayers_aurora)
  }

  void playDeathSfx() {
    if (isMuted) return;
    // SFX взрыва кубика
  }

  void playOrbSfx() {
    if (isMuted) return;
    // SFX сферы
  }

  void playWinSfx() {
    if (isMuted) return;
    // SFX победы
  }
}
