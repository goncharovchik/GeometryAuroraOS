import 'dart:ui';

/// Основные константы игры Geometry Dash
class GameConstants {
  // Фиксированный шаг физики (60 Гц)
  static const double fixedDeltaTime = 1.0 / 60.0;
  static const int fixedDeltaMs = 16;

  // Размеры сетки
  static const double tileSize = 48.0;
  static const double playerSize = 44.0;
  
  // Хитбокс кубика и шипов (с уменьшением для честной игры)
  static const double playerHitboxPadding = 4.0;
  static const double spikeHitboxInset = 8.0;

  // Физика Куба
  static const double baseRunSpeed = 380.0; // Пикселей в секунду для 1x скорости
  static const double gravity = 2200.0;
  static const double jumpVelocity = 760.0;
  static const double maxFallSpeed = 960.0; // Максимальная скорость падения (терминальная скорость)
  static const double rotationSpeed = 360.0; // Градусов в секунду во время прыжка

  // Буферизация прыжка и время койота (улучшение отзывчивости физики)
  static const double jumpBufferDuration = 0.14; // Буфер нажатия прыжка до приземления (~8.4 тика)
  static const double coyoteDuration = 0.09; // Время койота после схода с платформы (~5.4 тика)

  // Физика Корабля (Ship)
  static const double shipGravity = 1100.0;
  static const double shipThrust = 1600.0;
  static const double shipMaxVerticalSpeed = 500.0;
  static const double shipMaxTiltAngle = 35.0; // Градусов

  // Физика Волны (Wave) — резкий диагональный полет под 45 градусов
  static const double waveTiltAngle = 45.0;

  // Физика НЛО (UFO) — прыжки в воздухе как в Flappy Bird
  static const double ufoJumpVelocity = 640.0;

  // Прыжковые платформы (Jump Pads)
  static const double yellowPadVelocity = 920.0;
  static const double pinkPadVelocity = 620.0;
  static const double redPadVelocity = 1150.0;

  // Интерактивные сферы (Jump Orbs)
  static const double yellowOrbVelocity = 780.0;
  static const double pinkOrbVelocity = 580.0;
  static const double redOrbVelocity = 1000.0;
  static const double orbActivationRadius = 40.0;

  // Монетки и очки на карте
  static const int coinBasePoints = 10;
  static const double baseMagnetRadius = 32.0;
  static const double coinCollisionRadius = 24.0;

  // Оформление по умолчанию
  static const Color defaultBgColor = Color(0xFF0D0826);
  static const Color defaultGroundColor = Color(0xFF001A33);
  static const Color defaultAccentColor = Color(0xFF00E5FF);
  static const Color defaultPlayerColor1 = Color(0xFF00FF66);
  static const Color defaultPlayerColor2 = Color(0xFFFFFF00);

  // Множители скорости (Speed Portals)
  static const double speedHalf = 0.8;
  static const double speed1x = 1.0;
  static const double speed2x = 1.25;
  static const double speed3x = 1.55;
  static const double speed4x = 1.95;
}
