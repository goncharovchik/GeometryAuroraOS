import 'package:flutter/material.dart';
import '../audio/audio_controller.dart';
import '../data/sample_levels.dart';
import '../domain/models/level.dart';
import 'game_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A071E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ВЫБОР УРОВНЯ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _levels.length,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemBuilder: (context, index) {
                final level = _levels[index];
                return _buildLevelCard(level);
              },
            ),
          ),
          // Индикатор страниц
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_levels.length, (idx) {
                final isActive = idx == _currentPage;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF00FF66) : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(Level level) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: level.backgroundColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: level.difficulty.color, width: 3),
          boxShadow: [
            BoxShadow(
              color: level.difficulty.color.withOpacity(0.35),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Заголовок и сложность
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: level.difficulty.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: level.difficulty.color),
                      ),
                      child: Text(
                        level.difficulty.label.toUpperCase(),
                        style: TextStyle(
                          color: level.difficulty.color,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: List.generate(
                        level.difficulty.stars > 5 ? 5 : level.difficulty.stars,
                        (_) => const Icon(Icons.star, color: Colors.amber, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  level.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Автор: ${level.creator}',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Трек: ${level.songTitle} (${level.bpm.toInt()} BPM)',
                  style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13),
                ),
              ],
            ),

            // Иконка уровня / Превью
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: level.groundColor,
                border: Border.all(color: Colors.white30, width: 2),
              ),
              child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
            ),

            // Кнопка Старт
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF66),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                ),
                onPressed: () => _startLevel(level),
                child: const Text(
                  'ИГРАТЬ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
