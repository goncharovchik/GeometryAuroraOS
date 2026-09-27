import 'dart:math' as math;
import 'dart:ui';
import '../../core/math/vector2d.dart';
import '../../engine/player_controller.dart';
import 'particle_system.dart';

class CameraController {
  final Vector2D position = Vector2D(0.0, 0.0);
  final math.Random _random = math.Random();

  // Доля экрана слева, где находится игрок (примерно 28%)
  static const double playerScreenRatioX = 0.28;

  void update({
    required PlayerController player,
    required Size screenSize,
    required ParticleSystem particleSystem,
    required double dt,
  }) {
    // Горизонтальная позиция: игрок на фиксированном отступе
    final targetX = player.position.x - (screenSize.width * playerScreenRatioX);
    position.x = targetX;

    // Вертикальная позиция: плавная подтяжка к высоте игрока
    final targetY = player.position.y - (screenSize.height * 0.35);
    // Не опускаем камеру ниже уровня пола
    final clampedTargetY = math.max(0.0, targetY);

    position.y += (clampedTargetY - position.y) * 8.0 * dt;

    // Применяем тряску экрана
    if (particleSystem.screenShakeIntensity > 0.0) {
      final intensity = particleSystem.screenShakeIntensity;
      final offsetX = (_random.nextDouble() - 0.5) * 2.0 * intensity;
      final offsetY = (_random.nextDouble() - 0.5) * 2.0 * intensity;
      position.x += offsetX;
      position.y += offsetY;
    }
  }

  /// Переводит мировые координаты в экранные
  Offset worldToScreen(double worldX, double worldY, double screenHeight) {
    // В мире игры Y=0 это пол, ось Y направлена вверх
    // На экране Canvas Y=0 вверху, ось Y направлена вниз
    final screenX = worldX - position.x;
    final screenY = screenHeight - (worldY - position.y);
    return Offset(screenX, screenY);
  }
}
