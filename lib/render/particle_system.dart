import 'dart:math' as math;
import 'dart:ui';
import '../../core/math/vector2d.dart';

class Particle {
  final Vector2D position;
  final Vector2D velocity;
  final double size;
  final Color color;
  final double maxLife;
  double life;
  double rotation;
  double rotationSpeed;

  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    required this.maxLife,
    this.rotation = 0.0,
    this.rotationSpeed = 0.0,
  }) : life = maxLife;

  bool get isDead => life <= 0.0;
  double get progress => (life / maxLife).clamp(0.0, 1.0);

  void update(double dt) {
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;
    velocity.y -= 800.0 * dt; // Легкая гравитация для осколков
    rotation += rotationSpeed * dt;
    life -= dt;
  }
}

class ParticleSystem {
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();

  double screenShakeIntensity = 0.0;
  double screenShakeDuration = 0.0;

  List<Particle> get particles => _particles;

  void triggerScreenShake(double intensity, double duration) {
    screenShakeIntensity = intensity;
    screenShakeDuration = duration;
  }

  /// Эффект взрыва кубика на мелкие осколки при смерти
  void spawnDeathExplosion(Vector2D center, Color primaryColor, Color secondaryColor) {
    triggerScreenShake(14.0, 0.45);

    // Спавним 36 квадратных осколков
    for (int i = 0; i < 36; i++) {
      final angle = _random.nextDouble() * math.pi * 2.0;
      final speed = 150.0 + _random.nextDouble() * 550.0;
      final size = 6.0 + _random.nextDouble() * 10.0;
      final isPrimary = _random.nextBool();

      _particles.add(
        Particle(
          position: Vector2D(center.x + (size / 2.0), center.y + (size / 2.0)),
          velocity: Vector2D(math.cos(angle) * speed, math.sin(angle) * speed),
          size: size,
          color: isPrimary ? primaryColor : secondaryColor,
          maxLife: 0.6 + _random.nextDouble() * 0.5,
          rotation: _random.nextDouble() * math.pi * 2.0,
          rotationSpeed: (_random.nextDouble() - 0.5) * 12.0,
        ),
      );
    }
  }

  /// Искры при прыжке от орба или пада
  void spawnJumpSparks(Vector2D center, Color color) {
    for (int i = 0; i < 14; i++) {
      final angle = _random.nextDouble() * math.pi * 2.0;
      final speed = 80.0 + _random.nextDouble() * 220.0;

      _particles.add(
        Particle(
          position: Vector2D.copy(center),
          velocity: Vector2D(math.cos(angle) * speed, math.sin(angle) * speed),
          size: 4.0 + _random.nextDouble() * 4.0,
          color: color,
          maxLife: 0.35,
        ),
      );
    }
  }

  /// След огня корабля
  void spawnShipExhaust(Vector2D rearPos) {
    _particles.add(
      Particle(
        position: Vector2D(rearPos.x - 4.0, rearPos.y + (_random.nextDouble() - 0.5) * 10.0),
        velocity: Vector2D(-180.0 - _random.nextDouble() * 80.0, (_random.nextDouble() - 0.5) * 40.0),
        size: 5.0 + _random.nextDouble() * 5.0,
        color: _random.nextBool() ? const Color(0xFFFF9900) : const Color(0xFFFF3300),
        maxLife: 0.25,
      ),
    );
  }

  void update(double dt) {
    // Обновление тряски экрана
    if (screenShakeDuration > 0.0) {
      screenShakeDuration -= dt;
      if (screenShakeDuration <= 0.0) {
        screenShakeIntensity = 0.0;
      }
    }

    // Обновление частиц
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.update(dt);
      if (p.isDead) {
        _particles.removeAt(i);
      }
    }
  }

  void clear() {
    _particles.clear();
    screenShakeIntensity = 0.0;
    screenShakeDuration = 0.0;
  }
}
