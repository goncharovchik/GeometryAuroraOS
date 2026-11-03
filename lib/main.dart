import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/game_storage.dart';
import 'presentation/main_menu_screen.dart';
import 'presentation/widgets/landscape_enforcer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Загружаем сохраненный прогресс, очки и персонажей
  GameStorage.instance.load();

  // Фиксация ландшафтной ориентации экрана (стандарт для Geometry Dash)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Скрытие системных панелей для полноэкранного погружения
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const GeometryDashApp());
}

class GeometryDashApp extends StatelessWidget {
  const GeometryDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Абстракции',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF66),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF140F30),
        ),
      ),
      builder: (context, child) {
        return LandscapeEnforcer(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const MainMenuScreen(),
    );
  }
}
