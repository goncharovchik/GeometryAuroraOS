import 'package:flutter/material.dart';
import '../audio/audio_controller.dart';
import '../core/constants/game_constants.dart';
import '../data/sample_levels.dart';
import 'customize_screen.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with SingleTickerProviderStateMixin {
  late final AudioController _audioController;
  late final AnimationController _animController;

  Color _playerColor1 = GameConstants.defaultPlayerColor1;
  Color _playerColor2 = GameConstants.defaultPlayerColor2;

  @override
  void initState() {
    super.initState();
    _audioController = AudioController()..setBpm(128.0);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
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
      body: Stack(
        children: [
          // Неоновый фон с мягким свечением
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Color(0xFF1B0B3B),
                    Color(0xFF070417),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Логотип Geometry Dash Aurora с пульсацией
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      final scale = 1.0 + (_animController.value * 0.04);
                      return Transform.scale(
                        scale: scale,
                        child: Column(
                          children: [
                            Text(
                              'GEOMETRY DASH',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4.0,
                                color: const Color(0xFFFFD700),
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFFFF8800).withOpacity(0.8),
                                    blurRadius: 18,
                                    offset: const Offset(0, 4),
                                  ),
                                  const Shadow(
                                    color: Colors.black,
                                    blurRadius: 8,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                              ),
                              child: const Text(
                                'AURORA OS EDITION',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3.0,
                                  color: Color(0xFF00E5FF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Большая круглая кнопка PLAY по центру
                  GestureDetector(
                    onTap: _quickPlay,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF00FF66),
                            Color(0xFF00CC44),
                          ],
                        ),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00FF66).withOpacity(0.5),
                            blurRadius: 32,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 90,
                        ),
                      ),
                    ),
                  ),

                  // Кнопки навигации: Levels, Customize, Settings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Кнопка Выбор уровней
                      _buildMenuButton(
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
                      const SizedBox(width: 24),
                      // Кнопка Кастомизация скина
                      _buildMenuButton(
                        icon: Icons.palette_rounded,
                        label: 'СКИН',
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
                      const SizedBox(width: 24),
                      // Кнопка Настройки
                      _buildMenuButton(
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFF140F30),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
