import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../audio/audio_controller.dart';
import '../core/constants/game_constants.dart';
import '../core/math/vector2d.dart';
import '../domain/models/level.dart';
import '../engine/collision_detector.dart';
import '../engine/game_session.dart';
import '../engine/game_ticker.dart';
import '../render/camera_controller.dart';
import '../render/game_viewport_painter.dart';
import '../render/particle_system.dart';

class GameScreen extends StatefulWidget {
  final Level level;
  final AudioController audioController;
  final Color playerColor1;
  final Color playerColor2;

  const GameScreen({
    super.key,
    required this.level,
    required this.audioController,
    this.playerColor1 = GameConstants.defaultPlayerColor1,
    this.playerColor2 = GameConstants.defaultPlayerColor2,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late final GameSession _session;
  late final FixedTimestepGameTicker _ticker;
  late final CameraController _camera;
  late final ParticleSystem _particleSystem;

  late final Ticker _flutterTicker;
  Duration _lastElapsed = Duration.zero;

  bool _isPaused = false;
  double _deathCooldownTimer = 0.0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _session = GameSession(level: widget.level);
    _ticker = FixedTimestepGameTicker();
    _camera = CameraController();
    _particleSystem = ParticleSystem();

    widget.audioController.setBpm(widget.level.bpm);
    widget.audioController.startPlayback();

    _flutterTicker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _flutterTicker.dispose();
    _focusNode.dispose();
    widget.audioController.stopPlayback();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_isPaused) {
      _lastElapsed = elapsed;
      return;
    }

    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    widget.audioController.update(dt);
    _particleSystem.update(dt);

    if (_session.player.isDead) {
      _deathCooldownTimer -= dt;
      if (_deathCooldownTimer <= 0.0) {
        // Мгновенный респаун
        _session.restart();
        _particleSystem.clear();
      }
      setState(() {});
      return;
    }

    if (_session.player.hasWon) {
      setState(() {});
      return;
    }

    _ticker.update(
      dt,
      onPhysicsStep: (physicsDt) {
        _session.player.updatePhysics(physicsDt);

        final collision = _session.collisionDetector.checkAndResolve(
          player: _session.player,
          objects: widget.level.objects,
        );

        if (collision == CollisionResult.death) {
          widget.audioController.playDeathSfx();
          _session.onDeath();
          _deathCooldownTimer = 0.65; // Небольшая пауза для эффекта взрыва

          final center = Vector2D(
            _session.player.position.x + GameConstants.playerSize / 2.0,
            _session.player.position.y + GameConstants.playerSize / 2.0,
          );
          _particleSystem.spawnDeathExplosion(
            center,
            widget.playerColor1,
            widget.playerColor2,
          );
        } else if (collision == CollisionResult.win) {
          widget.audioController.playWinSfx();
        }

        if (_session.player.position.x >= widget.level.lengthInPixels && !_session.player.hasWon) {
          _session.player.hasWon = true;
          widget.audioController.playWinSfx();
          final center = Vector2D(
            _session.player.position.x + GameConstants.playerSize / 2.0,
            _session.player.position.y + GameConstants.playerSize / 2.0,
          );
          _particleSystem.spawnJumpSparks(center, const Color(0xFF00FF66));
        } else if (collision == CollisionResult.padTriggered) {
          widget.audioController.playJumpSfx();
          final center = Vector2D(
            _session.player.position.x + GameConstants.playerSize / 2.0,
            _session.player.position.y,
          );
          _particleSystem.spawnJumpSparks(center, const Color(0xFFFFD700));
        } else if (collision == CollisionResult.orbTriggered) {
          widget.audioController.playOrbSfx();
          final center = Vector2D(
            _session.player.position.x + GameConstants.playerSize / 2.0,
            _session.player.position.y + GameConstants.playerSize / 2.0,
          );
          _particleSystem.spawnJumpSparks(center, const Color(0xFF00FFFF));
        }
      },
      onRenderStep: (alpha) {
        // Запрос перерисовки
        setState(() {});
      },
    );
  }

  void _handleInputDown() {
    if (_isPaused || _session.player.isDead || _session.player.hasWon) return;
    _session.player.setInput(isHolding: true, justPressed: true);
    widget.audioController.playJumpSfx();
  }

  void _handleInputUp() {
    _session.player.setInput(isHolding: false, justPressed: false);
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        widget.audioController.pausePlayback();
      } else {
        widget.audioController.startPlayback();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    _camera.update(
      player: _session.player,
      screenSize: screenSize,
      particleSystem: _particleSystem,
      dt: GameConstants.fixedDeltaTime,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _handleInputDown();
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              _togglePause();
            }
          } else if (event is KeyUpEvent) {
            if (event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _handleInputUp();
            }
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _handleInputDown(),
          onTapUp: (_) => _handleInputUp(),
          onTapCancel: () => _handleInputUp(),
          child: Stack(
            children: [
              // Основной Canvas рендерер
              CustomPaint(
                size: screenSize,
                painter: GameViewportPainter(
                  level: widget.level,
                  player: _session.player,
                  camera: _camera,
                  particleSystem: _particleSystem,
                  playerColor1: widget.playerColor1,
                  playerColor2: widget.playerColor2,
                  bpmPulse: widget.audioController.bpmPulse,
                ),
              ),

              // Верхний прогресс-бар уровня
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _session.currentPercentage / 100.0,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FF66)),
                        minHeight: 6,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Процент прохождения
                            Text(
                              '${_session.currentPercentage.toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                                ],
                              ),
                            ),
                            // Номер попытки
                            Text(
                              'Attempt ${_session.attempts}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(color: Colors.black, blurRadius: 4),
                                ],
                              ),
                            ),
                            // Кнопка паузы
                            IconButton(
                              icon: const Icon(Icons.pause, color: Colors.white, size: 28),
                              onPressed: _togglePause,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Кнопки режима практики (если включен)
              if (_session.isPracticeMode)
                Positioned(
                  bottom: 24,
                  left: 24,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => _session.addCheckpoint(),
                        icon: const Icon(Icons.diamond),
                        label: const Text('Чекпоинт'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _session.removeLastCheckpoint(),
                        icon: const Icon(Icons.delete),
                        label: const Text('Удалить'),
                      ),
                    ],
                  ),
                ),

              // Экран победы (Level Complete)
              if (_session.player.hasWon)
                _buildWinOverlay(context),

              // Экран паузы
              if (_isPaused)
                _buildPauseOverlay(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWinOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: const Color(0xFF15102A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00FF66), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FF66).withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'LEVEL COMPLETE!',
                style: TextStyle(
                  color: Color(0xFF00FF66),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.level.title,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Попыток: ${_session.attempts}',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.home),
                    label: const Text('Меню'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF66),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onPressed: () {
                      _session.restart();
                      setState(() {});
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('Заново'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF00E5FF), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ПАУЗА',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF66),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _togglePause,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Продолжить', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    _togglePause();
                    _session.restart();
                  },
                  icon: const Icon(Icons.replay),
                  label: const Text('Рестарт'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: _session.isPracticeMode ? const Color(0xFF00E5FF) : Colors.white24,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      _session.isPracticeMode = !_session.isPracticeMode;
                    });
                  },
                  icon: Icon(
                    Icons.diamond,
                    color: _session.isPracticeMode ? const Color(0xFF00E5FF) : Colors.white54,
                  ),
                  label: Text(_session.isPracticeMode ? 'Практика: ВКЛ' : 'Практика: ВЫКЛ'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Выйти в главное меню'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
