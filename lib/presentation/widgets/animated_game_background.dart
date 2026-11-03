import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Элемент фоновой геометрии (ромбы, квадраты, треугольники)
class _BgParticle {
  double x;
  double y;
  double size;
  double speed;
  double rotation;
  double rotSpeed;
  double opacity;
  int shapeType; // 0: square, 1: diamond, 2: triangle

  _BgParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.rotation,
    required this.rotSpeed,
    required this.opacity,
    required this.shapeType,
  });
}

/// Анимированный неоновый фон в стиле Geometry Dash:
/// плавающие светящиеся геометрические фигуры, градиентное свечение и сетка
class AnimatedGameBackground extends StatefulWidget {
  final Widget? child;
  final Color primaryGlow;
  final Color secondaryGlow;
  final bool showGrid;

  const AnimatedGameBackground({
    super.key,
    this.child,
    this.primaryGlow = const Color(0xFF1B0B3B),
    this.secondaryGlow = const Color(0xFF070417),
    this.showGrid = true,
  });

  @override
  State<AnimatedGameBackground> createState() => _AnimatedGameBackgroundState();
}

class _AnimatedGameBackgroundState extends State<AnimatedGameBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_BgParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    // Генерируем набор парящих неоновых фигур
    for (int i = 0; i < 28; i++) {
      _particles.add(_BgParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 14.0 + _random.nextDouble() * 28.0,
        speed: 0.03 + _random.nextDouble() * 0.06,
        rotation: _random.nextDouble() * math.pi * 2,
        rotSpeed: (_random.nextDouble() - 0.5) * 1.5,
        opacity: 0.08 + _random.nextDouble() * 0.22,
        shapeType: _random.nextInt(3),
      ));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Радиальный градиент
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.15,
                colors: [
                  widget.primaryGlow,
                  widget.secondaryGlow,
                ],
              ),
            ),
          ),
        ),

        // Анимированный Canvas с фигурами и сеткой
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _BgPainter(
                  particles: _particles,
                  time: _controller.value,
                  showGrid: widget.showGrid,
                ),
              );
            },
          ),
        ),

        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _BgPainter extends CustomPainter {
  final List<_BgParticle> particles;
  final double time;
  final bool showGrid;

  _BgPainter({
    required this.particles,
    required this.time,
    required this.showGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Отрисовка тонкой неоновой сетки с перспективой/акцентом
    if (showGrid) {
      final gridPaint = Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      const gridSize = 48.0;
      for (double x = 0; x < size.width; x += gridSize) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += gridSize) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    // 2. Отрисовка плавающих геометрических фигур
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5;

    for (final p in particles) {
      // Движение вверх с плавным переносом
      final currentY = (p.y - (time * p.speed * 10.0)) % 1.0;
      final px = p.x * size.width;
      final py = (currentY < 0 ? currentY + 1.0 : currentY) * size.height;
      final currentRot = p.rotation + (time * p.rotSpeed * math.pi * 2);

      paint.color = const Color(0xFF00E5FF).withOpacity(p.opacity);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(currentRot);

      final half = p.size / 2.0;

      switch (p.shapeType) {
        case 0:
          // Квадрат
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size), paint);
          break;
        case 1:
          // Ромб (Diamond)
          final path = Path()
            ..moveTo(0, -half * 1.2)
            ..lineTo(half * 0.9, 0)
            ..lineTo(0, half * 1.2)
            ..lineTo(-half * 0.9, 0)
            ..close();
          canvas.drawPath(path, paint);
          break;
        case 2:
          // Треугольник (Spike-like)
          final path = Path()
            ..moveTo(0, -half)
            ..lineTo(half, half)
            ..lineTo(-half, half)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BgPainter oldDelegate) => true;
}

