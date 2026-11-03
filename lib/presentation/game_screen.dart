import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../audio/audio_controller.dart';
import '../core/constants/game_constants.dart';
import '../core/math/vector2d.dart';
import '../data/game_storage.dart';
import '../domain/models/level.dart';
import '../engine/collision_detector.dart';
import '../engine/game_session.dart';
import '../engine/game_ticker.dart';
import '../render/camera_controller.dart';
import '../render/game_viewport_painter.dart';
import '../render/particle_system.dart';
import 'widgets/neon_button.dart';

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

  int _sessionCoinsCollected = 0;
  int _sessionPointsEarned = 0;
  String? _floatingPointsText;
  double _floatingPointsTimer = 0.0;

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

    if (_floatingPointsTimer > 0.0) {
      _floatingPointsTimer -= dt;
      if (_floatingPointsTimer <= 0.0) {
        _floatingPointsText = null;
      }
    }

    if (_session.player.isDead) {
      _deathCooldownTimer -= dt;
      if (_deathCooldownTimer <= 0.0) {
        // Мгновенный респаун
        _session.restart();
        _particleSystem.clear();
        _sessionCoinsCollected = 0;
        _sessionPointsEarned = 0;
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

        if (collision == CollisionResult.coinCollected) {
          widget.audioController.playCoinSfx();
          final earned = (GameConstants.coinBasePoints * _session.player.scoreMultiplier).round();
          _sessionCoinsCollected++;
          _sessionPointsEarned += earned;
          GameStorage.instance.addPoints(earned);

          final center = Vector2D(
            _session.player.position.x + GameConstants.playerSize / 2.0,
            _session.player.position.y + GameConstants.playerSize / 2.0,
          );
          _particleSystem.spawnCoinCollect(center);
          _floatingPointsText = '+$earned 🪙';
          _floatingPointsTimer = 0.85;
        } else if (collision == CollisionResult.shieldAbsorbed) {
          widget.audioController.playShieldSfx();
          final center = Vector2D(
            _session.player.position.x + GameConstants.playerSize / 2.0,
            _session.player.position.y + GameConstants.playerSize / 2.0,
          );
          _particleSystem.spawnShieldAbsorb(center);
        } else if (collision == CollisionResult.death) {
          widget.audioController.playDeathSfx();
          _session.onDeath();
          GameStorage.instance.recordBestPercent(widget.level.id, _session.currentPercentage);
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
          GameStorage.instance.recordBestPercent(widget.level.id, 100.0);
          GameStorage.instance.recordCoinsCollected(widget.level.id, _sessionCoinsCollected);
          final winBonus = widget.level.difficulty.stars * 25;
          GameStorage.instance.addPoints(winBonus);
        }

        if (_session.player.position.x >= widget.level.lengthInPixels && !_session.player.hasWon) {
          _session.player.hasWon = true;
          widget.audioController.playWinSfx();
          GameStorage.instance.recordBestPercent(widget.level.id, 100.0);
          GameStorage.instance.recordCoinsCollected(widget.level.id, _sessionCoinsCollected);
          final winBonus = widget.level.difficulty.stars * 25;
          GameStorage.instance.addPoints(winBonus);
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

    final character = GameStorage.instance.selectedCharacter;

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
                  characterStyle: character.style,
                  collectedCoinIds: _session.collisionDetector.collectedCoins,
                ),
              ),

              // Всплывающий индикатор собранных очков
              if (_floatingPointsText != null)
                Positioned(
                  top: 75,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: (_floatingPointsTimer / 0.85).clamp(0.0, 1.0),
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF140F30).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFD700), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.4),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Text(
                          _floatingPointsText!,
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Верхний футуристичный HUD уровня
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Номер попытки
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF140F30).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white24, width: 1.5),
                          ),
                          child: Text(
                            'Попытка ${_session.attempts}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Счетчик собранных очков / монет
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF140F30).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.25),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '+$_sessionPointsEarned',
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Индикатор энергощита
                        if (_session.player.shieldCharges > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_rounded, color: Color(0xFF00E5FF), size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  '${_session.player.shieldCharges}',
                                  style: const TextStyle(
                                    color: Color(0xFF00E5FF),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Центральный прогресс-бар с бегущим значком куба
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final barWidth = constraints.maxWidth;
                                final progressRatio = (_session.currentPercentage / 100.0).clamp(0.0, 1.0);
                                final maxCubeX = math.max(0.0, barWidth - 20);
                                final cubeX = (maxCubeX * progressRatio).clamp(0.0, maxCubeX);

                                return Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Container(
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF100B24).withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.6), width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF00E5FF).withOpacity(0.2),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            width: barWidth * progressRatio,
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xFF00E5FF),
                                                  Color(0xFF00FF66),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Бегущий мини-куб на прогресс-баре
                                    Positioned(
                                      left: cubeX,
                                      top: -3,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: widget.playerColor1,
                                          border: Border.all(color: Colors.black, width: 1.5),
                                          borderRadius: BorderRadius.circular(2),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.black54, blurRadius: 4),
                                          ],
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            color: widget.playerColor2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),

                        // Процент прохождения
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF140F30).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00FF66), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00FF66).withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            '${_session.currentPercentage.toInt()}%',
                            style: const TextStyle(
                              color: Color(0xFF00FF66),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Кнопка паузы
                        GestureDetector(
                          onTap: _togglePause,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF140F30).withOpacity(0.85),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white70, width: 1.5),
                            ),
                            child: const Icon(Icons.pause_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Бейдж режима практики
              if (_session.isPracticeMode)
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.diamond_outlined, color: Color(0xFF00E5FF), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'РЕЖИМ ПРАКТИКИ',
                            style: TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Кнопки режима практики
              if (_session.isPracticeMode)
                Positioned(
                  bottom: 24,
                  left: 24,
                  child: Row(
                    children: [
                      _buildPracticeDiamondButton(
                        icon: Icons.add,
                        label: 'Чекпоинт',
                        color: const Color(0xFF00E5FF),
                        onTap: () => _session.addCheckpoint(),
                      ),
                      const SizedBox(width: 14),
                      _buildPracticeDiamondButton(
                        icon: Icons.close,
                        label: 'Удалить',
                        color: const Color(0xFFFF0055),
                        onTap: () => _session.removeLastCheckpoint(),
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

  Widget _buildPracticeDiamondButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF140F30).withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinOverlay(BuildContext context) {
    final winBonus = widget.level.difficulty.stars * 25;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFF15102A).withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF00FF66), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF66).withOpacity(0.5),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
                const BoxShadow(
                  color: Colors.black87,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 64),
                const SizedBox(height: 8),
                const Text(
                  'LEVEL COMPLETE!',
                  style: TextStyle(
                    color: Color(0xFF00FF66),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                    shadows: [
                      Shadow(color: Color(0xFF00FF66), blurRadius: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.level.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Всего попыток: ${_session.attempts}',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15),
                ),
                const SizedBox(height: 10),
                // Награды за прохождение
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B143A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 22),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Собрано: +$_sessionPointsEarned очков | Бонус: +$winBonus',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: NeonButton(
                        onTap: () => Navigator.of(context).pop(),
                        text: 'МЕНЮ',
                        icon: Icons.home_rounded,
                        primaryColor: const Color(0xFF555577),
                        textColor: Colors.white,
                        height: 48,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: NeonButton(
                        onTap: () {
                          _session.restart();
                          _sessionCoinsCollected = 0;
                          _sessionPointsEarned = 0;
                          setState(() {});
                        },
                        text: 'ЗАНОВО',
                        icon: Icons.replay_rounded,
                        primaryColor: const Color(0xFF00FF66),
                        height: 48,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: const Color(0xFF140E2E).withOpacity(0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF00E5FF), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.4),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ПАУЗА',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(color: Color(0xFF00E5FF), blurRadius: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.level.title,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  'Очки за попытку: +$_sessionPointsEarned 🪙',
                  style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),

                // Кнопка Продолжить
                NeonButton(
                  onTap: _togglePause,
                  text: 'ПРОДОЛЖИТЬ',
                  icon: Icons.play_arrow_rounded,
                  primaryColor: const Color(0xFF00FF66),
                  height: 48,
                ),
                const SizedBox(height: 10),

                // Кнопка Рестарт
                NeonButton(
                  onTap: () {
                    _togglePause();
                    _session.restart();
                    _sessionCoinsCollected = 0;
                    _sessionPointsEarned = 0;
                  },
                  text: 'РЕСТАРТ',
                  icon: Icons.replay_rounded,
                  primaryColor: const Color(0xFFFF9900),
                  height: 48,
                ),
                const SizedBox(height: 10),

                // Режим практики
                NeonButton(
                  onTap: () {
                    setState(() {
                      _session.isPracticeMode = !_session.isPracticeMode;
                    });
                  },
                  text: _session.isPracticeMode ? 'ПРАКТИКА: ВКЛ' : 'ПРАКТИКА: ВЫКЛ',
                  icon: Icons.diamond_rounded,
                  primaryColor: const Color(0xFF00E5FF),
                  height: 48,
                ),
                const SizedBox(height: 12),

                // Выход в меню
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 20),
                  label: const Text(
                    'Выйти в главное меню',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
