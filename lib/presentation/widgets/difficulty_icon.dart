import 'package:flutter/material.dart';
import '../../domain/models/level.dart';

/// Иконка сложности в фирменном стиле Geometry Dash
class DifficultyIcon extends StatelessWidget {
  final LevelDifficulty difficulty;
  final double size;

  const DifficultyIcon({
    super.key,
    required this.difficulty,
    this.size = 54.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF140F2E),
        border: Border.all(color: difficulty.color, width: 3),
        boxShadow: [
          BoxShadow(
            color: difficulty.color.withOpacity(0.5),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _DifficultyFacePainter(difficulty: difficulty),
      ),
    );
  }
}

class _DifficultyFacePainter extends CustomPainter {
  final LevelDifficulty difficulty;

  _DifficultyFacePainter({required this.difficulty});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2.0, size.height / 2.0);
    final r = size.width / 2.0;

    final fillPaint = Paint()..color = difficulty.color;
    final featurePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Внутренний круг с цветом сложности
    canvas.drawCircle(center, r * 0.82, fillPaint);

    switch (difficulty) {
      case LevelDifficulty.easy:
        // Улыбчивое лицо (Easy - Синий)
        canvas.drawCircle(Offset(center.dx - r * 0.32, center.dy - r * 0.15), r * 0.13, featurePaint);
        canvas.drawCircle(Offset(center.dx + r * 0.32, center.dy - r * 0.15), r * 0.13, featurePaint);
        // Улыбка
        final smilePath = Path()
          ..addArc(
            Rect.fromCenter(center: Offset(center.dx, center.dy + r * 0.15), width: r * 0.8, height: r * 0.5),
            0.1,
            2.9,
          );
        canvas.drawPath(smilePath, strokePaint);
        break;

      case LevelDifficulty.normal:
        // Нормальное лицо (Normal - Зеленый)
        canvas.drawCircle(Offset(center.dx - r * 0.3, center.dy - r * 0.15), r * 0.13, featurePaint);
        canvas.drawCircle(Offset(center.dx + r * 0.3, center.dy - r * 0.15), r * 0.13, featurePaint);
        // Прямой рот
        canvas.drawLine(
          Offset(center.dx - r * 0.35, center.dy + r * 0.28),
          Offset(center.dx + r * 0.35, center.dy + r * 0.28),
          strokePaint,
        );
        break;

      case LevelDifficulty.hard:
        // Сфокусированное лицо (Hard - Оранжевый)
        // Наклонные брови
        final browPath = Path()
          ..moveTo(center.dx - r * 0.45, center.dy - r * 0.32)
          ..lineTo(center.dx - r * 0.15, center.dy - r * 0.15)
          ..moveTo(center.dx + r * 0.45, center.dy - r * 0.32)
          ..lineTo(center.dx + r * 0.15, center.dy - r * 0.15);
        canvas.drawPath(browPath, strokePaint);
        canvas.drawCircle(Offset(center.dx - r * 0.28, center.dy - r * 0.05), r * 0.11, featurePaint);
        canvas.drawCircle(Offset(center.dx + r * 0.28, center.dy - r * 0.05), r * 0.11, featurePaint);
        // Небольшой оскал
        canvas.drawLine(
          Offset(center.dx - r * 0.28, center.dy + r * 0.3),
          Offset(center.dx + r * 0.28, center.dy + r * 0.3),
          strokePaint,
        );
        break;

      case LevelDifficulty.harder:
        // Напряженное лицо (Harder - Темно-оранжевый/красный)
        final browPath = Path()
          ..moveTo(center.dx - r * 0.5, center.dy - r * 0.35)
          ..lineTo(center.dx - r * 0.1, center.dy - r * 0.1)
          ..moveTo(center.dx + r * 0.5, center.dy - r * 0.35)
          ..lineTo(center.dx + r * 0.1, center.dy - r * 0.1);
        canvas.drawPath(browPath, strokePaint);
        canvas.drawRect(Rect.fromCenter(center: Offset(center.dx - r * 0.26, center.dy - r * 0.02), width: r * 0.22, height: r * 0.22), featurePaint);
        canvas.drawRect(Rect.fromCenter(center: Offset(center.dx + r * 0.26, center.dy - r * 0.02), width: r * 0.22, height: r * 0.22), featurePaint);
        // Злой открытый рот
        final mouthRect = Rect.fromCenter(center: Offset(center.dx, center.dy + r * 0.32), width: r * 0.6, height: r * 0.32);
        canvas.drawRRect(RRect.fromRectAndRadius(mouthRect, const Radius.circular(4)), featurePaint);
        break;

      case LevelDifficulty.insane:
        // Безумное лицо (Insane - Красный)
        final browPath = Path()
          ..moveTo(center.dx - r * 0.55, center.dy - r * 0.4)
          ..lineTo(center.dx, center.dy - r * 0.05)
          ..lineTo(center.dx + r * 0.55, center.dy - r * 0.4);
        canvas.drawPath(browPath, strokePaint..strokeWidth = 3.5);
        // Горящие злые глаза
        canvas.drawCircle(Offset(center.dx - r * 0.28, center.dy + r * 0.02), r * 0.14, featurePaint);
        canvas.drawCircle(Offset(center.dx + r * 0.28, center.dy + r * 0.02), r * 0.14, featurePaint);
        // Зигзагообразный рот
        final mouthPath = Path()
          ..moveTo(center.dx - r * 0.4, center.dy + r * 0.36)
          ..lineTo(center.dx - r * 0.2, center.dy + r * 0.44)
          ..lineTo(center.dx, center.dy + r * 0.34)
          ..lineTo(center.dx + r * 0.2, center.dy + r * 0.44)
          ..lineTo(center.dx + r * 0.4, center.dy + r * 0.36);
        canvas.drawPath(mouthPath, strokePaint);
        break;

      case LevelDifficulty.demon:
        // Демон (Demon - Фиолетовый / Рогатый)
        // Рога
        final hornPaint = Paint()..color = const Color(0xFFFF0055);
        final leftHorn = Path()
          ..moveTo(center.dx - r * 0.6, center.dy - r * 0.3)
          ..lineTo(center.dx - r * 0.9, center.dy - r * 0.8)
          ..lineTo(center.dx - r * 0.3, center.dy - r * 0.6)
          ..close();
        final rightHorn = Path()
          ..moveTo(center.dx + r * 0.6, center.dy - r * 0.3)
          ..lineTo(center.dx + r * 0.9, center.dy - r * 0.8)
          ..lineTo(center.dx + r * 0.3, center.dy - r * 0.6)
          ..close();
        canvas.drawPath(leftHorn, hornPaint);
        canvas.drawPath(rightHorn, hornPaint);
        canvas.drawPath(leftHorn, strokePaint);
        canvas.drawPath(rightHorn, strokePaint);

        // Красные демонические глаза
        final eyePaint = Paint()..color = const Color(0xFFFF0055);
        canvas.drawCircle(Offset(center.dx - r * 0.3, center.dy - r * 0.05), r * 0.14, eyePaint);
        canvas.drawCircle(Offset(center.dx + r * 0.3, center.dy - r * 0.05), r * 0.14, eyePaint);
        canvas.drawCircle(Offset(center.dx - r * 0.3, center.dy - r * 0.05), r * 0.07, featurePaint);
        canvas.drawCircle(Offset(center.dx + r * 0.3, center.dy - r * 0.05), r * 0.07, featurePaint);

        // Зубастая пасть
        final mouthRect = Rect.fromCenter(center: Offset(center.dx, center.dy + r * 0.35), width: r * 0.65, height: r * 0.35);
        canvas.drawRRect(RRect.fromRectAndRadius(mouthRect, const Radius.circular(6)), featurePaint);
        final toothPaint = Paint()..color = Colors.white;
        canvas.drawRect(Rect.fromLTWH(center.dx - r * 0.22, center.dy + r * 0.2, r * 0.12, r * 0.12), toothPaint);
        canvas.drawRect(Rect.fromLTWH(center.dx + r * 0.1, center.dy + r * 0.2, r * 0.12, r * 0.12), toothPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DifficultyFacePainter oldDelegate) =>
      oldDelegate.difficulty != difficulty;
}

