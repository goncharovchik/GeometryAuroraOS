import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';
import '../../domain/models/level.dart';
import '../../domain/models/level_object.dart';
import '../../domain/models/player_mode.dart';
import '../../engine/player_controller.dart';
import 'camera_controller.dart';
import 'particle_system.dart';

class GameViewportPainter extends CustomPainter {
  final Level level;
  final PlayerController player;
  final CameraController camera;
  final ParticleSystem particleSystem;
  final Color playerColor1;
  final Color playerColor2;
  final double bpmPulse; // Коэффициент пульсации музыки (0.0..1.0)

  GameViewportPainter({
    required this.level,
    required this.player,
    required this.camera,
    required this.particleSystem,
    this.playerColor1 = GameConstants.defaultPlayerColor1,
    this.playerColor2 = GameConstants.defaultPlayerColor2,
    this.bpmPulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Отрисовка градиентного фона с параллаксом
    _drawBackground(canvas, size);

    // 2. Отрисовка неонового пола
    _drawGround(canvas, size);

    // 3. Отрисовка видимых объектов уровня
    _drawLevelObjects(canvas, size);

    // 4. Отрисовка следа персонажа (Trail)
    _drawPlayerTrail(canvas, size);

    // 5. Отрисовка персонажа (Куб / Корабль / Шар)
    if (!player.isDead) {
      _drawPlayer(canvas, size);
    }

    // 6. Отрисовка системы частиц (взрыв, искры)
    _drawParticles(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    // Базовый цвет с легкой пульсацией в ритм музыки
    final pulseFactor = 0.85 + 0.15 * bpmPulse;
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(level.backgroundColor, Colors.black, 0.4)!.withOpacity(pulseFactor),
          level.backgroundColor.withOpacity(pulseFactor),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Параллакс-узоры на фоне (сетка с ромбами в стиле Geometry Dash)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04 + 0.04 * bpmPulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const bgCellSize = 96.0;
    // Параллакс смещение: фон движется медленнее камеры
    final parallaxX = (camera.position.x * 0.25) % bgCellSize;
    final parallaxY = (camera.position.y * 0.25) % bgCellSize;

    for (double x = -parallaxX; x < size.width + bgCellSize; x += bgCellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = -parallaxY; y < size.height + bgCellSize; y += bgCellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawGround(Canvas canvas, Size size) {
    final groundScreenPos = camera.worldToScreen(0, 0, size.height);
    final groundY = groundScreenPos.dy;

    if (groundY < size.height) {
      // Заливка пола
      final groundRect = Rect.fromLTWH(0, groundY, size.width, size.height - groundY);
      final groundPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            level.groundColor,
            Colors.black,
          ],
        ).createShader(groundRect);

      canvas.drawRect(groundRect, groundPaint);

      // Светящаяся неоновая линия пола
      final linePaint = Paint()
        ..color = Color.lerp(level.groundColor, Colors.white, 0.5)!
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(0, groundY), Offset(size.width, groundY), linePaint);

      // Сетка на полу
      final groundGridPaint = Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..strokeWidth = 1.0;

      const groundTileSize = GameConstants.tileSize;
      final offsetX = camera.position.x % groundTileSize;

      for (double x = -offsetX; x < size.width; x += groundTileSize) {
        canvas.drawLine(Offset(x, groundY), Offset(x, size.height), groundGridPaint);
      }
    }
  }

  void _drawLevelObjects(Canvas canvas, Size size) {
    // Отсекаем объекты вне экрана камеры (viewport culling)
    final minVisibleX = camera.position.x - GameConstants.tileSize;
    final maxVisibleX = camera.position.x + size.width + GameConstants.tileSize;

    for (final obj in level.objects) {
      if (obj.pixelX < minVisibleX || obj.pixelX > maxVisibleX) continue;

      final screenPos = camera.worldToScreen(obj.pixelX, obj.pixelY, size.height);
      final x = screenPos.dx;
      // В worldToScreen screenPos.dy это нижняя грань объекта
      final y = screenPos.dy - GameConstants.tileSize;
      final tileSize = GameConstants.tileSize;

      switch (obj.type) {
        case ObjectType.solidBlock:
          _drawBlock(canvas, x, y, tileSize);
          break;
        case ObjectType.spike:
        case ObjectType.hangingSpike:
          _drawSpike(canvas, x, y, tileSize, obj.rotationDegrees);
          break;
        case ObjectType.jumpPad:
          _drawJumpPad(canvas, x, y, tileSize, obj.padColor);
          break;
        case ObjectType.jumpOrb:
          _drawJumpOrb(canvas, x, y, tileSize, obj.orbColor);
          break;
        case ObjectType.portalMode:
        case ObjectType.portalGravity:
        case ObjectType.portalSpeed:
          _drawPortal(canvas, x, y, tileSize, obj);
          break;
        case ObjectType.finishLine:
          _drawFinishLine(canvas, x, y, size.height);
          break;
        case ObjectType.coin:
          _drawCoin(canvas, x, y, tileSize);
          break;
      }
    }
  }

  void _drawBlock(Canvas canvas, double x, double y, double size) {
    final rect = Rect.fromLTWH(x, y, size, size);

    // Внутренняя черная заливка
    canvas.drawRect(rect, Paint()..color = const Color(0xFF0F0F1A));

    // Неоновый контур
    final borderPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(rect, borderPaint);

    // Внутренний геометрический узор
    final innerRect = Rect.fromLTWH(x + 4, y + 4, size - 8, size - 8);
    canvas.drawRect(
      innerRect,
      Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _drawSpike(Canvas canvas, double x, double y, double size, double rotation) {
    canvas.save();
    // Поворот вокруг центра тайла
    final cx = x + size / 2.0;
    final cy = y + size / 2.0;
    canvas.translate(cx, cy);
    canvas.rotate(rotation * math.pi / 180.0);
    canvas.translate(-cx, -cy);

    final path = Path()
      ..moveTo(x, y + size)
      ..lineTo(x + size / 2.0, y)
      ..lineTo(x + size, y + size)
      ..close();

    // Черное тело шипа
    canvas.drawPath(path, Paint()..color = const Color(0xFF140005));

    // Неоновый контур
    final spikeBorder = Paint()
      ..color = const Color(0xFFFF0055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, spikeBorder);

    // Внутренняя светящаяся линия по центру
    canvas.drawLine(
      Offset(x + size / 2.0, y + 4),
      Offset(x + size / 2.0, y + size - 2),
      Paint()
        ..color = const Color(0xFFFF5588).withOpacity(0.6)
        ..strokeWidth = 1.5,
    );

    canvas.restore();
  }

  void _drawJumpPad(Canvas canvas, double x, double y, double size, PadColor color) {
    Color padColor;
    switch (color) {
      case PadColor.yellow:
        padColor = const Color(0xFFFFD700);
        break;
      case PadColor.pink:
        padColor = const Color(0xFFFF69B4);
        break;
      case PadColor.red:
        padColor = const Color(0xFFFF2222);
        break;
    }

    final padRect = Rect.fromLTWH(x + 4, y + size - 10, size - 8, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(padRect, const Radius.circular(5)),
      Paint()..color = padColor,
    );

    // Свечение
    canvas.drawRRect(
      RRect.fromRectAndRadius(padRect, const Radius.circular(5)),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawJumpOrb(Canvas canvas, double x, double y, double size, OrbColor color) {
    Color orbColor;
    switch (color) {
      case OrbColor.yellow:
        orbColor = const Color(0xFFFFD700);
        break;
      case OrbColor.pink:
        orbColor = const Color(0xFFFF69B4);
        break;
      case OrbColor.red:
        orbColor = const Color(0xFFFF2222);
        break;
    }

    final center = Offset(x + size / 2.0, y + size / 2.0);
    final radius = (size / 2.0) - 6.0;

    // Внешнее пульсирующее кольцо
    canvas.drawCircle(
      center,
      radius + (bpmPulse * 3.0),
      Paint()
        ..color = orbColor.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Ядро орба
    canvas.drawCircle(
      center,
      radius * 0.65,
      Paint()..color = orbColor,
    );

    // Центральный белый блик
    canvas.drawCircle(
      center,
      radius * 0.3,
      Paint()..color = Colors.white,
    );
  }

  void _drawPortal(Canvas canvas, double x, double y, double size, LevelObject obj) {
    Color portalColor = const Color(0xFF00FFCC);
    if (obj.type == ObjectType.portalGravity) {
      portalColor = const Color(0xFF9900FF);
    } else if (obj.type == ObjectType.portalMode && obj.targetMode == PlayerMode.ship) {
      portalColor = const Color(0xFFFF6600);
    }

    final center = Offset(x + size / 2.0, y + size / 2.0);

    // Портал в виде светящегося вихревого эллипса
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(0.5, 1.4);

    final portalPaint = Paint()
      ..color = portalColor.withOpacity(0.7 + 0.3 * bpmPulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawCircle(Offset.zero, size / 2.0, portalPaint);
    canvas.drawCircle(
      Offset.zero,
      (size / 2.0) * 0.6,
      Paint()..color = portalColor.withOpacity(0.3),
    );

    canvas.restore();
  }

  void _drawFinishLine(Canvas canvas, double x, double y, double screenHeight) {
    final linePaint = Paint()
      ..color = const Color(0xFF00FF66)
      ..strokeWidth = 4.0;

    canvas.drawLine(Offset(x, 0), Offset(x, screenHeight), linePaint);
  }

  void _drawCoin(Canvas canvas, double x, double y, double size) {
    final center = Offset(x + size / 2.0, y + size / 2.0);
    canvas.drawCircle(
      center,
      size * 0.35,
      Paint()..color = const Color(0xFFFFD700),
    );
    canvas.drawCircle(
      center,
      size * 0.35,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  void _drawPlayerTrail(Canvas canvas, Size size) {
    for (int i = 0; i < player.trail.length; i++) {
      final pt = player.trail[i];
      final screenPos = camera.worldToScreen(pt.x, pt.y, size.height);
      final alpha = (i / player.trail.length) * 0.35;
      final trailSize = GameConstants.playerSize * (0.6 + 0.4 * (i / player.trail.length));

      final rect = Rect.fromCenter(
        center: Offset(
          screenPos.dx + GameConstants.playerSize / 2.0,
          screenPos.dy - GameConstants.playerSize / 2.0,
        ),
        width: trailSize,
        height: trailSize,
      );

      canvas.drawRect(
        rect,
        Paint()..color = playerColor1.withOpacity(alpha),
      );
    }
  }

  void _drawPlayer(Canvas canvas, Size size) {
    final screenPos = camera.worldToScreen(player.position.x, player.position.y, size.height);
    final pSize = GameConstants.playerSize;

    canvas.save();
    // Точка вращения — центр куба
    final cx = screenPos.dx + pSize / 2.0;
    final cy = screenPos.dy - pSize / 2.0;

    canvas.translate(cx, cy);
    canvas.rotate(player.rotationDegrees * math.pi / 180.0);

    if (player.mode == PlayerMode.cube) {
      _drawPlayerCube(canvas, pSize);
    } else if (player.mode == PlayerMode.ship) {
      _drawPlayerShip(canvas, pSize);
    } else if (player.mode == PlayerMode.ball) {
      _drawPlayerBall(canvas, pSize);
    }

    canvas.restore();
  }

  void _drawPlayerCube(Canvas canvas, double size) {
    final half = size / 2.0;
    final bodyRect = Rect.fromCenter(center: Offset.zero, width: size, height: size);

    // Основной цвет тела
    canvas.drawRect(bodyRect, Paint()..color = playerColor1);

    // Черная рамка вокруг кубика
    canvas.drawRect(
      bodyRect,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Внутренний квадрат второго цвета
    final innerSize = size * 0.55;
    final innerRect = Rect.fromCenter(center: Offset.zero, width: innerSize, height: innerSize);
    canvas.drawRect(innerRect, Paint()..color = playerColor2);
    canvas.drawRect(
      innerRect,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Глаза кубика в стиле Geometry Dash
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(-half + 10, -half + 10, 7, 10), eyePaint);
    canvas.drawRect(Rect.fromLTWH(half - 17, -half + 10, 7, 10), eyePaint);
  }

  void _drawPlayerShip(Canvas canvas, double size) {
    final half = size / 2.0;

    // Корпус корабля (ракета)
    final shipPath = Path()
      ..moveTo(half, 0)
      ..lineTo(-half, -half * 0.7)
      ..lineTo(-half * 0.6, 0)
      ..lineTo(-half, half * 0.7)
      ..close();

    canvas.drawPath(shipPath, Paint()..color = playerColor1);
    canvas.drawPath(
      shipPath,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Кабина
    canvas.drawCircle(Offset(0, 0), half * 0.35, Paint()..color = playerColor2);
    canvas.drawCircle(
      Offset(0, 0),
      half * 0.35,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawPlayerBall(Canvas canvas, double size) {
    final radius = size / 2.0;

    // Шар с сегментами
    canvas.drawCircle(Offset.zero, radius, Paint()..color = playerColor1);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Внутренний вращающийся диск
    canvas.drawCircle(Offset.zero, radius * 0.5, Paint()..color = playerColor2);
    canvas.drawCircle(
      Offset.zero,
      radius * 0.5,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawParticles(Canvas canvas, Size size) {
    for (final p in particleSystem.particles) {
      final screenPos = camera.worldToScreen(p.position.x, p.position.y, size.height);
      final alpha = p.progress;

      canvas.save();
      canvas.translate(screenPos.dx, screenPos.dy);
      canvas.rotate(p.rotation);

      final pRect = Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size);
      canvas.drawRect(
        pRect,
        Paint()..color = p.color.withOpacity(alpha),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant GameViewportPainter oldDelegate) => true;
}
