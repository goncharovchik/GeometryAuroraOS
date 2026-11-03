import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/models/player_mode.dart';
import 'widgets/animated_game_background.dart';
import 'widgets/neon_button.dart';

class CustomizeScreen extends StatefulWidget {
  final Color initialColor1;
  final Color initialColor2;
  final ValueChanged<Color> onColor1Changed;
  final ValueChanged<Color> onColor2Changed;

  const CustomizeScreen({
    super.key,
    required this.initialColor1,
    required this.initialColor2,
    required this.onColor1Changed,
    required this.onColor2Changed,
  });

  @override
  State<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends State<CustomizeScreen> with SingleTickerProviderStateMixin {
  late Color _color1;
  late Color _color2;
  PlayerMode _previewMode = PlayerMode.cube;
  late final AnimationController _hoverAnimController;

  final List<Color> _palette = const [
    Color(0xFF00FF66), // Яркий зеленый
    Color(0xFFFFFF00), // Неоновый желтый
    Color(0xFF00E5FF), // Электрик голубой
    Color(0xFFFF0055), // Фуксия / Розовый
    Color(0xFFFF9900), // Оранжевый
    Color(0xFF9900FF), // Неоновый фиолетовый
    Color(0xFFFFFFFF), // Чистый белый
    Color(0xFFFF3333), // Алый красный
    Color(0xFF0066FF), // Ультрамарин синий
    Color(0xFFCCFF00), // Лаймовый
    Color(0xFF00FFAA), // Мятный
    Color(0xFFFF66B2), // Пастельно-розовый
    Color(0xFFFFCC00), // Золотистый
    Color(0xFF7000FF), // Индиго
    Color(0xFF00FFFF), // Циан
    Color(0xFF888888), // Стальной серый
  ];

  @override
  void initState() {
    super.initState();
    _color1 = widget.initialColor1;
    _color2 = widget.initialColor2;
    _hoverAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _hoverAnimController.dispose();
    super.dispose();
  }

  void _applyPreset(Color c1, Color c2) {
    setState(() {
      _color1 = c1;
      _color2 = c2;
    });
    widget.onColor1Changed(c1);
    widget.onColor2Changed(c2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08051E),
      body: AnimatedGameBackground(
        primaryGlow: _color1.withOpacity(0.35),
        secondaryGlow: const Color(0xFF08051E),
        showGrid: true,
        child: SafeArea(
          child: Column(
            children: [
              // Верхний AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'КАСТОМИЗАЦИЯ',
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
                    const SizedBox(width: 48), // Балансир
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    children: [
                      // Переключатель режима предпросмотра: Куб, Корабль, Шар
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildModeTab('КУБ', PlayerMode.cube, Icons.crop_square_rounded),
                          const SizedBox(width: 12),
                          _buildModeTab('КОРАБЛЬ', PlayerMode.ship, Icons.navigation_rounded),
                          const SizedBox(width: 12),
                          _buildModeTab('ШАР', PlayerMode.ball, Icons.circle_outlined),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Сцена с персонажем и пьедесталом
                      AnimatedBuilder(
                        animation: _hoverAnimController,
                        builder: (context, _) {
                          final hoverOffset = math.sin(_hoverAnimController.value * math.pi) * 8.0;
                          return Container(
                            width: 220,
                            height: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFF140E2E).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: _color1.withOpacity(0.8), width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: _color1.withOpacity(0.35),
                                  blurRadius: 28,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Светящийся пьедестал внизу
                                Positioned(
                                  bottom: 18,
                                  child: Container(
                                    width: 120,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: RadialGradient(
                                        colors: [
                                          _color1.withOpacity(0.8),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Парящий персонаж
                                Transform.translate(
                                  offset: Offset(0, -hoverOffset),
                                  child: _buildCharacterPreview(70.0),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      // Быстрые пресеты стилей
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPresetChip('Классика', const Color(0xFF00FF66), const Color(0xFFFFFF00)),
                            const SizedBox(width: 8),
                            _buildPresetChip('Кибер Неон', const Color(0xFF00E5FF), const Color(0xFFFF0055)),
                            const SizedBox(width: 8),
                            _buildPresetChip('Инферно', const Color(0xFFFF9900), const Color(0xFFFF3333)),
                            const SizedBox(width: 8),
                            _buildPresetChip('Сияние', const Color(0xFFCCFF00), const Color(0xFF9900FF)),
                            const SizedBox(width: 8),
                            _buildPresetChip('Золото', const Color(0xFFFFCC00), const Color(0xFFFFFFFF)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Палитра 1 (Основной цвет)
                      _buildColorSelector(
                        title: 'ОСНОВНОЙ ЦВЕТ (ТЕЛО)',
                        selectedColor: _color1,
                        onSelect: (c) {
                          setState(() => _color1 = c);
                          widget.onColor1Changed(c);
                        },
                      ),

                      const SizedBox(height: 20),

                      // Палитра 2 (Вторичный цвет)
                      _buildColorSelector(
                        title: 'ВТОРИЧНЫЙ ЦВЕТ (ДЕТАЛИ / ГЛАЗА)',
                        selectedColor: _color2,
                        onSelect: (c) {
                          setState(() => _color2 = c);
                          widget.onColor2Changed(c);
                        },
                      ),

                      const SizedBox(height: 24),

                      // Кнопка Готово
                      NeonButton(
                        onTap: () => Navigator.of(context).pop(),
                        text: 'СОХРАНИТЬ И ВЫЙТИ',
                        icon: Icons.check_circle_outline_rounded,
                        primaryColor: const Color(0xFF00FF66),
                        height: 50,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab(String label, PlayerMode mode, IconData icon) {
    final isSelected = _previewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _previewMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E5FF).withOpacity(0.2) : const Color(0xFF140E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E5FF) : Colors.white24,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.4),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white60,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterPreview(double size) {
    switch (_previewMode) {
      case PlayerMode.cube:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _color1,
            border: Border.all(color: Colors.black, width: 4),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Container(
              width: size * 0.52,
              height: size * 0.52,
              decoration: BoxDecoration(
                color: _color2,
                border: Border.all(color: Colors.black, width: 2),
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

      case PlayerMode.ship:
        return CustomPaint(
          size: Size(size, size * 0.8),
          painter: _ShipPreviewPainter(color1: _color1, color2: _color2),
        );

      case PlayerMode.ball:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color1,
            border: Border.all(color: Colors.black, width: 4),
          ),
          child: Center(
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _color2,
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          ),
        );
    }
  }

  Widget _buildPresetChip(String name, Color c1, Color c2) {
    return GestureDetector(
      onTap: () => _applyPreset(c1, c2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF140F30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 14, height: 14, decoration: BoxDecoration(color: c1, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Container(width: 14, height: 14, decoration: BoxDecoration(color: c2, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelector({
    required String title,
    required Color selectedColor,
    required ValueChanged<Color> onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF120C28).withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selectedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: selectedColor.withOpacity(0.5), blurRadius: 8),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _palette.map((color) {
              final isSelected = color.value == selectedColor.value;
              return GestureDetector(
                onTap: () => onSelect(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.black45,
                      width: isSelected ? 3.5 : 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.8),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(Icons.check, color: Colors.black, size: 22),
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ShipPreviewPainter extends CustomPainter {
  final Color color1;
  final Color color2;

  _ShipPreviewPainter({required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final halfW = size.width / 2.0;
    final halfH = size.height / 2.0;
    final center = Offset(halfW, halfH);

    final shipPath = Path()
      ..moveTo(center.dx + halfW * 0.9, center.dy)
      ..lineTo(center.dx - halfW * 0.8, center.dy - halfH * 0.7)
      ..lineTo(center.dx - halfW * 0.4, center.dy)
      ..lineTo(center.dx - halfW * 0.8, center.dy + halfH * 0.7)
      ..close();

    canvas.drawPath(shipPath, Paint()..color = color1);
    canvas.drawPath(
      shipPath,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Кабина
    canvas.drawCircle(Offset(center.dx, center.dy), halfW * 0.3, Paint()..color = color2);
    canvas.drawCircle(
      Offset(center.dx, center.dy),
      halfW * 0.3,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ShipPreviewPainter oldDelegate) =>
      oldDelegate.color1 != color1 || oldDelegate.color2 != color2;
}
