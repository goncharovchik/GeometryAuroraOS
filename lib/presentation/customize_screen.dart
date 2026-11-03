import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/game_storage.dart';
import '../domain/models/player_character.dart';
import '../domain/models/player_mode.dart';
import '../domain/models/upgrade.dart';
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
  int _activeTabIndex = 0; // 0: Персонажи, 1: Прокачка, 2: Цвета

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
    GameStorage.instance.setColors(c1, c2);
    widget.onColor1Changed(c1);
    widget.onColor2Changed(c2);
  }

  @override
  Widget build(BuildContext context) {
    final storage = GameStorage.instance;
    final selectedChar = storage.selectedCharacter;

    return Scaffold(
      backgroundColor: const Color(0xFF08051E),
      body: AnimatedGameBackground(
        primaryGlow: _color1.withOpacity(0.35),
        secondaryGlow: const Color(0xFF08051E),
        showGrid: true,
        child: SafeArea(
          child: Column(
            children: [
              // Верхний AppBar с балансом очков
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'МАСТЕРСКАЯ',
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
                      ),
                    ),
                    // Баланс очков/монет
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF140F30),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${storage.totalPoints}',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Вкладки: Персонажи / Прокачка / Цвета
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Row(
                  children: [
                    _buildNavTab(0, 'ПЕРСОНАЖИ', Icons.person_rounded),
                    const SizedBox(width: 8),
                    _buildNavTab(1, 'ПРОКАЧКА', Icons.bolt_rounded),
                    const SizedBox(width: 8),
                    _buildNavTab(2, 'ЦВЕТА', Icons.palette_rounded),
                  ],
                ),
              ),

              // Основное интерактивное окно
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    children: [
                      // Интерактивная сцена предпросмотра персонажа
                      AnimatedBuilder(
                        animation: _hoverAnimController,
                        builder: (context, _) {
                          final hoverOffset = math.sin(_hoverAnimController.value * math.pi) * 8.0;
                          return Container(
                            width: 250,
                            height: 155,
                            decoration: BoxDecoration(
                              color: const Color(0xFF140E2E).withOpacity(0.92),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: _color1.withOpacity(0.85), width: 2.5),
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
                                // Пьедестал
                                Positioned(
                                  bottom: 16,
                                  child: Container(
                                    width: 140,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: RadialGradient(
                                        colors: [
                                          _color1.withOpacity(0.85),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Парящий персонаж
                                Transform.translate(
                                  offset: Offset(0, -hoverOffset),
                                  child: _buildCharacterPreview(68.0, selectedChar.style),
                                ),

                                // Название активного персонажа внизу сцены
                                Positioned(
                                  bottom: 6,
                                  child: Text(
                                    selectedChar.name.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 14),

                      // Переключатель режима для предпросмотра
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildModeTab('КУБ', PlayerMode.cube, Icons.crop_square_rounded),
                            const SizedBox(width: 8),
                            _buildModeTab('КОРАБЛЬ', PlayerMode.ship, Icons.navigation_rounded),
                            const SizedBox(width: 8),
                            _buildModeTab('ШАР', PlayerMode.ball, Icons.circle_outlined),
                            const SizedBox(width: 8),
                            _buildModeTab('ВОЛНА', PlayerMode.wave, Icons.change_history_rounded),
                            const SizedBox(width: 8),
                            _buildModeTab('НЛО', PlayerMode.ufo, Icons.flight_rounded),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Содержимое выбранной вкладки
                      if (_activeTabIndex == 0)
                        _buildCharactersTab(storage)
                      else if (_activeTabIndex == 1)
                        _buildUpgradesTab(storage)
                      else
                        _buildColorsTab(),

                      const SizedBox(height: 24),

                      // Кнопка сохранения
                      NeonButton(
                        onTap: () => Navigator.of(context).pop(),
                        text: 'СОХРАНИТЬ И ВЫЙТИ',
                        icon: Icons.check_circle_outline_rounded,
                        primaryColor: const Color(0xFF00FF66),
                        height: 48,
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

  Widget _buildNavTab(int index, String label, IconData icon) {
    final isSelected = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00E5FF).withOpacity(0.25) : const Color(0xFF140F30),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white24,
              width: 1.8,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withOpacity(0.35),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? const Color(0xFF00E5FF) : Colors.white60,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
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

  Widget _buildCharactersTab(GameStorage storage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ДОСТУПНЫЕ ПЕРСОНАЖИ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...PlayerCharacter.characters.map((char) {
          final isUnlocked = storage.isCharacterUnlocked(char.id);
          final isSelected = storage.selectedCharacterId == char.id;
          final canAfford = storage.totalPoints >= char.cost;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1A1238)
                  : const Color(0xFF120C28).withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00FF66)
                    : isUnlocked
                        ? Colors.white24
                        : Colors.white12,
                width: isSelected ? 2.0 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00FF66).withOpacity(0.25),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Иконка персонажа
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: char.defaultColor1.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: char.defaultColor1, width: 2),
                  ),
                  child: Icon(char.icon, color: char.defaultColor1, size: 28),
                ),
                const SizedBox(width: 14),

                // Описание и перк
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              char.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              char.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        char.perkDescription,
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Кнопка выбора / покупки
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF66).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00FF66), width: 1.5),
                    ),
                    child: const Text(
                      'ВЫБРАН',
                      style: TextStyle(
                        color: Color(0xFF00FF66),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  )
                else if (isUnlocked)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        storage.selectCharacter(char.id);
                        _color1 = char.defaultColor1;
                        _color2 = char.defaultColor2;
                      });
                      widget.onColor1Changed(char.defaultColor1);
                      widget.onColor2Changed(char.defaultColor2);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                      ),
                      child: const Text(
                        'ВЫБРАТЬ',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: canAfford
                        ? () {
                            if (storage.unlockCharacter(char.id)) {
                              setState(() {
                                _color1 = char.defaultColor1;
                                _color2 = char.defaultColor2;
                              });
                              widget.onColor1Changed(char.defaultColor1);
                              widget.onColor2Changed(char.defaultColor2);
                            }
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: canAfford
                            ? const Color(0xFFFFD700).withOpacity(0.2)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: canAfford ? const Color(0xFFFFD700) : Colors.white24,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: canAfford ? const Color(0xFFFFD700) : Colors.white38,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${char.cost}',
                            style: TextStyle(
                              color: canAfford ? const Color(0xFFFFD700) : Colors.white38,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUpgradesTab(GameStorage storage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ВЕТКА ПРОКАЧКИ ЗА ОЧКИ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...Upgrade.allUpgrades.map((upgrade) {
          final level = storage.getUpgradeLevel(upgrade.id);
          final isMax = level >= upgrade.maxLevel;
          final cost = upgrade.getCost(level);
          final canAfford = storage.totalPoints >= cost;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF120C28).withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isMax ? const Color(0xFFFFD700).withOpacity(0.7) : Colors.white12,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Иконка улучшения
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF00E5FF), width: 1.8),
                  ),
                  child: Icon(upgrade.icon, color: const Color(0xFF00E5FF), size: 26),
                ),
                const SizedBox(width: 14),

                // Описание и текущий эффект
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              upgrade.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Звездочки уровня
                          Row(
                            children: List.generate(upgrade.maxLevel, (i) {
                              return Icon(
                                i < level ? Icons.star_rounded : Icons.star_border_rounded,
                                color: i < level ? const Color(0xFFFFD700) : Colors.white24,
                                size: 16,
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        upgrade.getLevelEffectDescription(level),
                        style: const TextStyle(
                          color: Color(0xFF00FF66),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        upgrade.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Кнопка прокачки
                if (isMax)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                    ),
                    child: const Text(
                      'МАКС',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: canAfford
                        ? () {
                            setState(() {
                              storage.upgradeSkill(upgrade.id);
                            });
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: canAfford
                            ? const Color(0xFF00FF66).withOpacity(0.2)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: canAfford ? const Color(0xFF00FF66) : Colors.white24,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: canAfford ? const Color(0xFFFFD700) : Colors.white38,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$cost',
                            style: TextStyle(
                              color: canAfford ? Colors.white : Colors.white38,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildColorsTab() {
    return Column(
      children: [
        // Пресеты
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

        const SizedBox(height: 20),

        // Палитра 1
        _buildColorSelector(
          title: 'ОСНОВНОЙ ЦВЕТ (ТЕЛО)',
          selectedColor: _color1,
          onSelect: (c) {
            setState(() => _color1 = c);
            GameStorage.instance.setColor1(c);
            widget.onColor1Changed(c);
          },
        ),

        const SizedBox(height: 18),

        // Палитра 2
        _buildColorSelector(
          title: 'ВТОРИЧНЫЙ ЦВЕТ (ДЕТАЛИ / АКЦЕНТЫ)',
          selectedColor: _color2,
          onSelect: (c) {
            setState(() => _color2 = c);
            GameStorage.instance.setColor2(c);
            widget.onColor2Changed(c);
          },
        ),
      ],
    );
  }

  Widget _buildModeTab(String label, PlayerMode mode, IconData icon) {
    final isSelected = _previewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _previewMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E5FF).withOpacity(0.2) : const Color(0xFF140E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E5FF) : Colors.white24,
            width: 1.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF00E5FF) : Colors.white60, size: 16),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterPreview(double size, CharacterStyle style) {
    switch (_previewMode) {
      case PlayerMode.cube:
        return CustomPaint(
          size: Size(size, size),
          painter: _CubePreviewPainter(color1: _color1, color2: _color2, style: style),
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
      case PlayerMode.wave:
        return CustomPaint(
          size: Size(size, size * 0.75),
          painter: _WavePreviewPainter(color1: _color1, color2: _color2),
        );
      case PlayerMode.ufo:
        return CustomPaint(
          size: Size(size, size * 0.75),
          painter: _UfoPreviewPainter(color1: _color1, color2: _color2),
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
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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

class _CubePreviewPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final CharacterStyle style;

  _CubePreviewPainter({required this.color1, required this.color2, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final half = size.width / 2.0;
    final bodyRect = Rect.fromCenter(center: Offset(half, half), width: size.width, height: size.height);

    canvas.drawRect(bodyRect, Paint()..color = color1);
    canvas.drawRect(
      bodyRect,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // Отрисовка деталей в зависимости от стиля
    switch (style) {
      case CharacterStyle.classic:
        final innerSize = size.width * 0.52;
        final innerRect = Rect.fromCenter(center: Offset(half, half), width: innerSize, height: innerSize);
        canvas.drawRect(innerRect, Paint()..color = color2);
        canvas.drawRect(innerRect, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2);
        final eyePaint = Paint()..color = Colors.black;
        canvas.drawRect(Rect.fromLTWH(half - 14, half - 10, 6, 9), eyePaint);
        canvas.drawRect(Rect.fromLTWH(half + 8, half - 10, 6, 9), eyePaint);
        break;

      case CharacterStyle.phantom:
        final maskRect = Rect.fromCenter(center: Offset(half, half), width: size.width * 0.65, height: size.height * 0.48);
        canvas.drawRRect(RRect.fromRectAndRadius(maskRect, const Radius.circular(4)), Paint()..color = const Color(0xFF100826));
        final eyePaint = Paint()..color = color2;
        final p1 = Path()..moveTo(half - 14, half - 3)..lineTo(half - 4, half - 7)..lineTo(half - 5, half + 2)..close();
        final p2 = Path()..moveTo(half + 14, half - 3)..lineTo(half + 4, half - 7)..lineTo(half + 5, half + 2)..close();
        canvas.drawPath(p1, eyePaint);
        canvas.drawPath(p2, eyePaint);
        break;

      case CharacterStyle.vortex:
        final p = Paint()..color = color2;
        canvas.drawRect(Rect.fromLTWH(8, 6, size.width - 16, 5), p);
        canvas.drawCircle(Offset(half - 8, half + 4), 6, p);
        canvas.drawCircle(Offset(half + 8, half + 4), 6, p);
        canvas.drawCircle(Offset(half - 8, half + 4), 3, Paint()..color = Colors.black);
        canvas.drawCircle(Offset(half + 8, half + 4), 3, Paint()..color = Colors.black);
        break;

      case CharacterStyle.graviton:
        final ringRadius = size.width * 0.3;
        canvas.drawCircle(Offset(half, half), ringRadius, Paint()..color = color2..style = PaintingStyle.stroke..strokeWidth = 3);
        canvas.drawCircle(Offset(half, half), ringRadius * 0.45, Paint()..color = color2);
        canvas.drawCircle(Offset(half, half), ringRadius * 0.2, Paint()..color = Colors.black);
        break;

      case CharacterStyle.magnetron:
        final visor = Rect.fromCenter(center: Offset(half, half - 4), width: size.width * 0.7, height: 7);
        canvas.drawRRect(RRect.fromRectAndRadius(visor, const Radius.circular(3)), Paint()..color = Colors.black);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(half, half - 4), width: size.width * 0.6, height: 4), const Radius.circular(2)), Paint()..color = color2);
        break;

      case CharacterStyle.titan:
        final inner = Rect.fromCenter(center: Offset(half, half), width: size.width * 0.6, height: size.height * 0.6);
        canvas.drawRect(inner, Paint()..color = color2);
        canvas.drawRect(inner, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2);
        final bp = Paint()..color = Colors.black;
        canvas.drawCircle(const Offset(7, 7), 2.5, bp);
        canvas.drawCircle(Offset(size.width - 7, 7), 2.5, bp);
        canvas.drawCircle(Offset(7, size.height - 7), 2.5, bp);
        canvas.drawCircle(Offset(size.width - 7, size.height - 7), 2.5, bp);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _CubePreviewPainter oldDelegate) => true;
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
  bool shouldRepaint(covariant _ShipPreviewPainter oldDelegate) => true;
}

class _WavePreviewPainter extends CustomPainter {
  final Color color1;
  final Color color2;

  _WavePreviewPainter({required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final halfW = size.width / 2.0;
    final halfH = size.height / 2.0;
    final center = Offset(halfW, halfH);

    final p = Path()
      ..moveTo(center.dx + halfW * 0.9, center.dy)
      ..lineTo(center.dx - halfW * 0.85, center.dy - halfH * 0.75)
      ..lineTo(center.dx - halfW * 0.4, center.dy)
      ..lineTo(center.dx - halfW * 0.85, center.dy + halfH * 0.75)
      ..close();

    canvas.drawPath(p, Paint()..color = color1);
    canvas.drawPath(p, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 3);

    final core = Path()
      ..moveTo(center.dx + halfW * 0.3, center.dy)
      ..lineTo(center.dx - halfW * 0.3, center.dy - halfH * 0.35)
      ..lineTo(center.dx - halfW * 0.1, center.dy)
      ..lineTo(center.dx - halfW * 0.3, center.dy + halfH * 0.35)
      ..close();

    canvas.drawPath(core, Paint()..color = color2);
  }

  @override
  bool shouldRepaint(covariant _WavePreviewPainter oldDelegate) => true;
}

class _UfoPreviewPainter extends CustomPainter {
  final Color color1;
  final Color color2;

  _UfoPreviewPainter({required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final halfW = size.width / 2.0;
    final halfH = size.height / 2.0;
    final center = Offset(halfW, halfH);

    final saucer = Path()
      ..moveTo(center.dx + halfW * 0.95, center.dy)
      ..quadraticBezierTo(center.dx, center.dy + halfH * 0.7, center.dx - halfW * 0.95, center.dy)
      ..quadraticBezierTo(center.dx, center.dy - halfH * 0.3, center.dx + halfW * 0.95, center.dy)
      ..close();

    canvas.drawPath(saucer, Paint()..color = color1);
    canvas.drawPath(saucer, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 3);

    // Купол
    final dome = Rect.fromLTWH(center.dx - halfW * 0.5, center.dy - halfH * 0.85, halfW, halfH * 0.7);
    canvas.drawArc(dome, math.pi, math.pi, true, Paint()..color = color2);
    canvas.drawArc(dome, math.pi, math.pi, false, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _UfoPreviewPainter oldDelegate) => true;
}
