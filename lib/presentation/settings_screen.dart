import 'package:flutter/material.dart';
import '../audio/audio_controller.dart';
import '../data/game_storage.dart';
import 'widgets/animated_game_background.dart';

class SettingsScreen extends StatefulWidget {
  final AudioController audioController;

  const SettingsScreen({
    super.key,
    required this.audioController,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _latencyOffset;

  @override
  void initState() {
    super.initState();
    _latencyOffset = widget.audioController.latencyOffsetMs;
  }

  void _testLatencyBeep() {
    widget.audioController.playJumpSfx();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07041A),
      body: AnimatedGameBackground(
        primaryGlow: const Color(0xFF1B0B3B),
        secondaryGlow: const Color(0xFF07041A),
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
                      'НАСТРОЙКИ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        shadows: [
                          Shadow(color: Color(0xFFFFD700), blurRadius: 14),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  children: [
                    // Раздел Ориентации экрана
                    _buildCard(
                      title: 'ЭКРАН И ОРИЕНТАЦИЯ',
                      icon: Icons.screen_rotation_rounded,
                      accentColor: const Color(0xFF00E5FF),
                      children: [
                        AnimatedBuilder(
                          animation: GameStorage.instance,
                          builder: (context, _) {
                            return SwitchListTile(
                              title: const Text(
                                'Поворот экрана на 180°',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                GameStorage.instance.flipLandscape
                                    ? 'Режим: Landscape Right (поворот вправо)'
                                    : 'Режим: Landscape Left (поворот влево, стандарт)',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              value: GameStorage.instance.flipLandscape,
                              activeColor: const Color(0xFF00E5FF),
                              secondary: const Icon(Icons.sync_alt_rounded, color: Color(0xFF00E5FF)),
                              onChanged: (val) {
                                GameStorage.instance.toggleFlipLandscape();
                              },
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Раздел Аудио и калибровки
                    _buildCard(
                      title: 'АУДИО И СИНХРОНИЗАЦИЯ',
                      icon: Icons.music_note_rounded,
                      accentColor: const Color(0xFF00FF66),
                      children: [
                        SwitchListTile(
                          title: const Text('Звуковые эффекты и музыка', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          value: !widget.audioController.isMuted,
                          activeColor: const Color(0xFF00FF66),
                          onChanged: (val) {
                            setState(() {
                              widget.audioController.isMuted = !val;
                            });
                          },
                        ),
                        const Divider(color: Colors.white12),
                        ListTile(
                          title: const Text('Калибровка задержки (Audio Latency)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${_latencyOffset.toInt()} мс (компенсация задержки Bluetooth/динамиков)',
                            style: const TextStyle(color: Color(0xFF00E5FF)),
                          ),
                          trailing: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2),
                              foregroundColor: const Color(0xFF00E5FF),
                              side: const BorderSide(color: Color(0xFF00E5FF)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _testLatencyBeep,
                            icon: const Icon(Icons.volume_up, size: 18),
                            label: const Text('Тест звука'),
                          ),
                        ),
                        Slider(
                          value: _latencyOffset,
                          min: -150.0,
                          max: 150.0,
                          divisions: 30,
                          activeColor: const Color(0xFF00E5FF),
                          inactiveColor: Colors.white12,
                          onChanged: (val) {
                            setState(() {
                              _latencyOffset = val;
                              widget.audioController.latencyOffsetMs = val;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Раздел Команды и разработчиков
                    _buildCard(
                      title: 'КОМАНДА И О ПРОЕКТЕ',
                      icon: Icons.groups_rounded,
                      accentColor: const Color(0xFFFF0055),
                      children: [
                        const ListTile(
                          leading: Icon(Icons.videogame_asset_rounded, color: Color(0xFFFF0055)),
                          title: Text('Название игры', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          subtitle: Text('«Абстракции» (Geometry Dash Aurora)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        const ListTile(
                          leading: Icon(Icons.terminal_rounded, color: Color(0xFF00E5FF)),
                          title: Text('Команда разработчиков', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          subtitle: Text('Команда «FAQ» • Группа ФИТ-262', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        const Divider(color: Colors.white12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            'Состав команды:',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        _buildMemberRow('Гончаров Алексей Юрьевич', 'Тимлид • Архитектура и движок'),
                        _buildMemberRow('Зубаненко Татьяна Вячеславовна', 'Геймдизайн • Левел-дизайн и арт'),
                        _buildMemberRow('Тихомирова Анна Павловна', 'Разработка • Физика и коллизии'),
                        const SizedBox(height: 8),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Раздел ОС Аврора
                    _buildCard(
                      title: 'ОС АВРОРА И ПРОИЗВОДИТЕЛЬНОСТЬ',
                      icon: Icons.speed_rounded,
                      accentColor: const Color(0xFFFFD700),
                      children: const [
                        ListTile(
                          title: Text('Целевая платформа', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('ОС Аврора 5.x / 4.x (Flutter Engine, ОМП)', style: TextStyle(color: Colors.white70)),
                          trailing: Icon(Icons.phone_android, color: Color(0xFFFFD700)),
                        ),
                        ListTile(
                          title: Text('Физический тик (Tickrate)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('Детерминированный цикл 60 Гц (16.6 мс на шаг)', style: TextStyle(color: Colors.white70)),
                          trailing: Icon(Icons.check_circle_outline, color: Color(0xFF00FF66)),
                        ),
                        ListTile(
                          title: Text('Пакет дистрибутива', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('RPM Package (armv7hl / aarch64 / x86_64)', style: TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberRow(String name, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF00E5FF), size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '$name\n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  TextSpan(text: role, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF140E2E).withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withOpacity(0.5), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.2),
            blurRadius: 18,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
