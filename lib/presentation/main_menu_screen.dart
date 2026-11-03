import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../audio/audio_controller.dart';
import '../core/constants/game_constants.dart';
import '../data/sample_levels.dart';
import 'customize_screen.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'widgets/animated_game_background.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with TickerProviderStateMixin {
  late final AudioController _audioController;
  late final AnimationController _pulseController;
  late final AnimationController _cubeSpinController;

  Color _playerColor1 = GameConstants.defaultPlayerColor1;
  Color _playerColor2 = GameConstants.defaultPlayerColor2;

  @override
  void initState() {
    super.initState();
    _audioController = AudioController()..setBpm(128.0);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _cubeSpinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cubeSpinController.dispose();
    _audioController.dispose();
    super.dispose();
  }

  void _quickPlay() {
    final firstLevel = SampleLevels.getLevels().first;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          level: firstLevel,
          audioController: _audioController,
          playerColor1: _playerColor1,
          playerColor2: _playerColor2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070417),
      body: AnimatedGameBackground(
        primaryGlow: const Color(0xFF220946),
        secondaryGlow: const Color(0xFF070417),
        showGrid: true,
        child: SafeArea(
          child: Stack(
            children: [
              // Верхняя панель: звук и команда
              Positioned(
                top: 14,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Чип команды "FAQ"
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF140F30).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.terminal, color: Color(0xFF00E5FF), size: 16),
                          SizedBox(width: 8),
                          Text(
                            'FAQ • ФИТ-262',
                            style: TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Быстрый переключатель звука
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _audioController.isMuted = !_audioController.isMuted;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF140F30).withOpacity(0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _audioController.isMuted ? Colors.white30 : const Color(0xFF00FF66),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_audioController.isMuted ? Colors.transparent : const Color(0xFF00FF66)).withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          _audioController.isMuted ? Icons.volume_off : Icons.volume_up,
                          color: _audioController.isMuted ? Colors.white54 : const Color(0xFF00FF66),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Центр: Логотип, Play и кнопки меню
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(height: 10),

                    // Логотип Geometry Dash
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 1.0 + (_pulseController.value * 0.035);
                        return Transform.scale(
                          scale: scale,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'GEOMETRY DASH',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 5.0,
                                  color: const Color(0xFFFFD700),
                                  shadows: [
                                    Shadow(
                                      color: const Color(0xFFFF8800).withOpacity(0.9),
                                      blurRadius: 24,
                                      offset: const Offset(0, 4),
                                    ),
                                    const Shadow(
                                      color: Colors.black,
                                      blurRadius: 10,
                                      offset: Offset(3, 3),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E5FF).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF00E5FF), width: 1.8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withOpacity(0.35),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'AURORA OS EDITION',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3.5,
                                    color: Color(0xFF00E5FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Большая кнопка PLAY с пульсирующими кольцами
                    _buildPlayButton(),

                    // Навигационные кнопки: Уровни, Скины, Настройки
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTactileMenuButton(
                          icon: Icons.view_list_rounded,
                          label: 'УРОВНИ',
                          color: const Color(0xFF00E5FF),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LevelSelectScreen(
                                  audioController: _audioController,
                                  playerColor1: _playerColor1,
                                  playerColor2: _playerColor2,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 28),
                        _buildTactileMenuButton(
                          icon: Icons.palette_rounded,
                          label: 'СКИНЫ',
                          color: const Color(0xFFFF0055),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CustomizeScreen(
                                  initialColor1: _playerColor1,
                                  initialColor2: _playerColor2,
                                  onColor1Changed: (c) => setState(() => _playerColor1 = c),
                                  onColor2Changed: (c) => setState(() => _playerColor2 = c),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 28),
                        _buildTactileMenuButton(
                          icon: Icons.settings_rounded,
                          label: 'НАСТРОЙКИ',
                          color: const Color(0xFFFFD700),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SettingsScreen(
                                  audioController: _audioController,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    // Подвал с инфо о платформе
                    Text(
                      'v1.0.0 • 60 FPS • Aurora OS Native Engine',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Правый нижний угол: плавающий интерактивный мини-кубик игрока
              Positioned(
                bottom: 16,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomizeScreen(
                          initialColor1: _playerColor1,
                          initialColor2: _playerColor2,
                          onColor1Changed: (c) => setState(() => _playerColor1 = c),
                          onColor2Changed: (c) => setState(() => _playerColor2 = c),
                        ),
                      ),
                    );
                  },
                  child: AnimatedBuilder(
                    animation: _cubeSpinController,
                    builder: (context, _) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF140F30).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24, width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.rotate(
                              angle: math.sin(_cubeSpinController.value * math.pi * 2) * 0.2,
                              child: _buildMiniPlayerPreview(32.0),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Скин',
                              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final ringExpand = _pulseController.value * 12.0;
        final ringOpacity = (1.0 - _pulseController.value * 0.6).clamp(0.0, 1.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Внешнее пульсирующее кольцо
            Container(
              width: 150 + ringExpand * 2,
              height: 150 + ringExpand * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00FF66).withOpacity(0.3 * ringOpacity),
                  width: 3,
                ),
              ),
            ),

            // Сама кнопка PLAY
            GestureDetector(
              onTap: _quickPlay,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.2, -0.3),
                    radius: 0.9,
                    colors: [
                      Color(0xFF55FF88),
                      Color(0xFF00CC44),
                      Color(0xFF00882B),
                    ],
                  ),
                  border: Border.all(color: Colors.white, width: 4.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF66).withOpacity(0.65),
                      blurRadius: 36,
                      spreadRadius: 6,
                    ),
                    const BoxShadow(
                      color: Colors.black54,
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 92,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTactileMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF140F30),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.8),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.45),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
                const BoxShadow(
                  color: Colors.black45,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 34),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniPlayerPreview(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _playerColor1,
        border: Border.all(color: Colors.black, width: 2.5),
      ),
      child: Center(
        child: Container(
          width: size * 0.52,
          height: size * 0.52,
          decoration: BoxDecoration(
            color: _playerColor2,
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(width: size * 0.1, height: size * 0.18, color: Colors.black),
              Container(width: size * 0.1, height: size * 0.18, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}
