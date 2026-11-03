import 'package:flutter/material.dart';
import '../audio/audio_controller.dart';
import '../data/sample_levels.dart';
import '../domain/models/level.dart';
import 'game_screen.dart';
import 'widgets/animated_game_background.dart';
import 'widgets/difficulty_icon.dart';
import 'widgets/neon_button.dart';

class LevelSelectScreen extends StatefulWidget {
  final AudioController audioController;
  final Color playerColor1;
  final Color playerColor2;

  const LevelSelectScreen({
    super.key,
    required this.audioController,
    required this.playerColor1,
    required this.playerColor2,
  });

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  late final List<Level> _levels;
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _levels = SampleLevels.getLevels();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startLevel(Level level) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          level: level,
          audioController: widget.audioController,
          playerColor1: widget.playerColor1,
          playerColor2: widget.playerColor2,
        ),
      ),
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _levels.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLevel = _levels[_currentPage];

    return Scaffold(
      backgroundColor: const Color(0xFF07041A),
      body: AnimatedGameBackground(
        primaryGlow: currentLevel.backgroundColor.withOpacity(0.6),
        secondaryGlow: const Color(0xFF07041A),
        showGrid: true,
        child: SafeArea(
          child: Column(
            children: [
              // Верхний AppBar с заголовком и счетчиком
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Row(
                      children: [
                        const Text(
                          'ВЫБОР УРОВНЯ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            shadows: [
                              Shadow(color: Color(0xFF00E5FF), blurRadius: 14),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF140F30),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                          ),
                          child: Text(
                            '${_currentPage + 1} / ${_levels.length}',
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 48), // Балансир
                  ],
                ),
              ),

              // Карусель уровней со стрелками навигации
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: _levels.length,
                      onPageChanged: (idx) => setState(() => _currentPage = idx),
                      itemBuilder: (context, index) {
                        final level = _levels[index];
                        return _buildLevelCard(level);
                      },
                    ),

                    // Кнопка Влево
                    if (_currentPage > 0)
                      Positioned(
                        left: 8,
                        child: _buildNavArrow(
                          icon: Icons.chevron_left_rounded,
                          onTap: _previousPage,
                        ),
                      ),

                    // Кнопка Вправо
                    if (_currentPage < _levels.length - 1)
                      Positioned(
                        right: 8,
                        child: _buildNavArrow(
                          icon: Icons.chevron_right_rounded,
                          onTap: _nextPage,
                        ),
                      ),
                  ],
                ),
              ),

              // Индикатор страниц (пагинация)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, top: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_levels.length, (idx) {
                    final isActive = idx == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: isActive ? 30 : 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF00FF66) : Colors.white24,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: isActive
                            ? [
                                const BoxShadow(
                                  color: Color(0xFF00FF66),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavArrow({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF140F30).withOpacity(0.85),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.7), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.35),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildLevelCard(Level level) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: const Color(0xFF140E2E).withOpacity(0.92),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: level.difficulty.color, width: 3),
          boxShadow: [
            BoxShadow(
              color: level.difficulty.color.withOpacity(0.4),
              blurRadius: 24,
              spreadRadius: 2,
            ),
            const BoxShadow(
              color: Colors.black54,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Шапка карточки: Бейдж сложности, Звезды, Монетки
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Иконка сложности GD
                DifficultyIcon(
                  difficulty: level.difficulty,
                  size: 58.0,
                ),

                // Название сложности и звезды
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: level.difficulty.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: level.difficulty.color, width: 1.5),
                      ),
                      child: Text(
                        level.difficulty.label.toUpperCase(),
                        style: TextStyle(
                          color: level.difficulty.color,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        level.difficulty.stars > 5 ? 5 : level.difficulty.stars,
                        (_) => const Padding(
                          padding: EdgeInsets.only(right: 3.0),
                          child: Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),

                // Секретные монетки (Secret Coins)
                Row(
                  children: List.generate(3, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black38,
                        border: Border.all(color: Colors.amber.withOpacity(0.6), width: 1.5),
                      ),
                      child: const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                    );
                  }),
                ),
              ],
            ),

            // Название уровня и автор
            Column(
              children: [
                Text(
                  level.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 6, offset: Offset(2, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Автор: ${level.creator}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.music_note_rounded, color: Color(0xFF00E5FF), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${level.songTitle} • ${level.bpm.toInt()} BPM',
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Прогресс-бар рекорда уровня
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Рекорд уровня',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '0%',
                        style: TextStyle(
                          color: Color(0xFF00FF66),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    value: 0.0,
                    minHeight: 10,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF66)),
                  ),
                ),
              ],
            ),

            // Кнопки управления: ИГРАТЬ
            NeonButton(
              onTap: () => _startLevel(level),
              text: 'ИГРАТЬ',
              icon: Icons.play_arrow_rounded,
              primaryColor: const Color(0xFF00FF66),
              height: 52,
            ),
          ],
        ),
      ),
    );
  }
}
