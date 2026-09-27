import 'package:flutter/material.dart';
import '../audio/audio_controller.dart';

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
          'НАСТРОЙКИ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Раздел Аудио
          _buildCard(
            title: 'АУДИО И СИНХРОНИЗАЦИЯ',
            icon: Icons.music_note,
            children: [
              SwitchListTile(
                title: const Text('Звуковые эффекты и музыка', style: TextStyle(color: Colors.white)),
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
                title: const Text('Калибровка задержки (Audio Latency)', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  '${_latencyOffset.toInt()} мс (компенсация задержки гарнитуры)',
                  style: const TextStyle(color: Color(0xFF00E5FF)),
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

          const SizedBox(height: 20),

          // Раздел ОС Аврора
          _buildCard(
            title: 'ОС АВРОРА И ПРОИЗВОДИТЕЛЬНОСТЬ',
            icon: Icons.phone_android,
            children: const [
              ListTile(
                title: Text('Целевая платформа', style: TextStyle(color: Colors.white)),
                subtitle: Text('ОС Аврора 5.x / 4.x (Flutter Engine)', style: TextStyle(color: Colors.white70)),
              ),
              ListTile(
                title: Text('Частота кадров (FPS)', style: TextStyle(color: Colors.white)),
                subtitle: Text('60 FPS (Fixed Timestep 16.6 ms)', style: TextStyle(color: Colors.white70)),
                trailing: Icon(Icons.speed, color: Color(0xFF00FF66)),
              ),
              ListTile(
                title: Text('Сборка пакета', style: TextStyle(color: Colors.white)),
                subtitle: Text('RPM Package (armv7hl / aarch64 / x86_64)', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF140F30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF00E5FF), size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
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
