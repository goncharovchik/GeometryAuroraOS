import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'presentation/main_menu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
      title: 'Geometry Dash Aurora',
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
      home: const MainMenuScreen(),
    );
  }
}
