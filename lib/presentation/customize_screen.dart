import 'package:flutter/material.dart';

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

class _CustomizeScreenState extends State<CustomizeScreen> {
  late Color _color1;
  late Color _color2;

  final List<Color> _palette = const [
    Color(0xFF00FF66), // Зеленый
    Color(0xFFFFFF00), // Желтый
    Color(0xFF00E5FF), // Голубой
    Color(0xFFFF0055), // Розовый
    Color(0xFFFF9900), // Оранжевый
    Color(0xFF9900FF), // Фиолетовый
    Color(0xFFFFFFFF), // Белый
    Color(0xFFFF3333), // Красный
    Color(0xFF0066FF), // Синий
    Color(0xFFCCFF00), // Лаймовый
  ];

  @override
  void initState() {
    super.initState();
    _color1 = widget.initialColor1;
    _color2 = widget.initialColor2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0820),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'КАСТОМИЗАЦИЯ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Превью персонажа
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161036),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _color1.withOpacity(0.4),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: _color1,
                        border: Border.all(color: Colors.black, width: 4),
                      ),
                      child: Center(
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _color2,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(width: 6, height: 10, color: Colors.black),
                              Container(width: 6, height: 10, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Выбор основного цвета (Primary)
              _buildColorSelector(
                title: 'ОСНОВНОЙ ЦВЕТ (ЦВЕТ 1)',
                selectedColor: _color1,
                onSelect: (c) {
                  setState(() => _color1 = c);
                  widget.onColor1Changed(c);
                },
              ),

              const SizedBox(height: 24),

              // Выбор вторичного цвета (Secondary)
              _buildColorSelector(
                title: 'ВТОРИЧНЫЙ ЦВЕТ (ЦВЕТ 2)',
                selectedColor: _color2,
                onSelect: (c) {
                  setState(() => _color2 = c);
                  widget.onColor2Changed(c);
                },
              ),
            ],
          ),
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
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: const Color(0xFF140F30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _palette.map((color) {
              final isSelected = color.value == selectedColor.value;
              return GestureDetector(
                onTap: () => onSelect(color),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.black,
                      width: isSelected ? 3.5 : 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.black, size: 24)
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
