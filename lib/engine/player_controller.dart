import '../../core/constants/game_constants.dart';
import '../../core/math/hitbox.dart';
import '../../core/math/vector2d.dart';
import '../../domain/models/player_mode.dart';

/// Состояние и физика персонажа
class PlayerController {
  final Vector2D position = Vector2D(0.0, 0.0);
  final Vector2D velocity = Vector2D(0.0, 0.0);
  
  double rotationDegrees = 0.0;
  bool isGrounded = false;
  bool isDead = false;
  bool hasWon = false;

  PlayerMode mode = PlayerMode.cube;
  GravityDirection gravity = GravityDirection.down;
  SpeedModifier speedModifier = SpeedModifier.normal;

  bool isHoldingInput = false;
  bool justPressedInput = false;
  
  // Для анимации и следа (trail)
  final List<Vector2D> trail = [];
  static const int maxTrailLength = 12;

  PlayerController({
    double startX = 0.0,
    double startY = 0.0,
  }) {
    position.set(startX, startY);
  }

  void reset({double startX = 0.0, double startY = 0.0}) {
    position.set(startX, startY);
    velocity.set(GameConstants.baseRunSpeed * speedModifier.multiplier, 0.0);
    rotationDegrees = 0.0;
    isGrounded = false;
    isDead = false;
    hasWon = false;
    mode = PlayerMode.cube;
    gravity = GravityDirection.down;
    speedModifier = SpeedModifier.normal;
    isHoldingInput = false;
    justPressedInput = false;
    trail.clear();
  }

  AABB get hitbox {
    final padding = GameConstants.playerHitboxPadding;
    return AABB.fromDimensions(
      x: position.x + padding,
      y: position.y + padding,
      width: GameConstants.playerSize - padding * 2,
      height: GameConstants.playerSize - padding * 2,
    );
  }

  /// Обновление ввода
  void setInput({required bool isHolding, bool justPressed = false}) {
    isHoldingInput = isHolding;
    if (justPressed) {
      justPressedInput = true;
    }
  }

  /// Фиксированный шаг физики (вызывается на каждом тике детерминированного цикла)
  void updatePhysics(double dt) {
    if (isDead || hasWon) return;

    // Горизонтальная скорость постоянна согласно текущему порталу скорости
    velocity.x = GameConstants.baseRunSpeed * speedModifier.multiplier;

    switch (mode) {
      case PlayerMode.cube:
        _updateCube(dt);
        break;
      case PlayerMode.ship:
        _updateShip(dt);
        break;
      case PlayerMode.ball:
        _updateBall(dt);
        break;
    }

    // Применяем перемещение
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;

    // Обновляем след (trail) каждые несколько тиков
    trail.add(Vector2D.copy(position));
    if (trail.length > maxTrailLength) {
      trail.removeAt(0);
    }

    // Сбрасываем флаг разового нажатия
    justPressedInput = false;
  }

  void _updateCube(double dt) {
    final gSign = gravity.sign;

    // Обработка прыжка
    if (isGrounded && (justPressedInput || isHoldingInput)) {
      velocity.y = GameConstants.jumpVelocity * gSign;
      isGrounded = false;
    }

    // Применяем гравитацию
    if (!isGrounded) {
      velocity.y -= GameConstants.gravity * gSign * dt;

      // Вращение в воздухе
      final rotDir = gSign > 0 ? 1.0 : -1.0;
      rotationDegrees += GameConstants.rotationSpeed * rotDir * dt;
    } else {
      // При приземлении выравниваем куб по сетке (кратно 90 градусам)
      _snapRotationTo90();
    }
  }

  void _updateShip(double dt) {
    final gSign = gravity.sign;

    // Корабль: тяга вверх при удержании, гравитация при отпускании
    if (isHoldingInput) {
      velocity.y += GameConstants.shipThrust * gSign * dt;
    } else {
      velocity.y -= GameConstants.shipGravity * gSign * dt;
    }

    // Ограничение максимальной вертикальной скорости
    velocity.y = velocity.y.clamp(
      -GameConstants.shipMaxVerticalSpeed,
      GameConstants.shipMaxVerticalSpeed,
    );

    // Угол наклона носа корабля пропорционален вертикальной скорости
    final targetAngle = (velocity.y / GameConstants.shipMaxVerticalSpeed) *
        GameConstants.shipMaxTiltAngle;
    rotationDegrees += (targetAngle - rotationDegrees) * 10.0 * dt;
  }

  void _updateBall(double dt) {
    final gSign = gravity.sign;

    // Шар: клик на полу инвертирует гравитацию
    if (isGrounded && (justPressedInput || isHoldingInput)) {
      gravity = gravity.inverted;
      isGrounded = false;
      velocity.y = 150.0 * gravity.sign;
    } else if (!isGrounded) {
      velocity.y -= GameConstants.gravity * gSign * dt;
    }

    // Непрерывное вращение шара при движении
    rotationDegrees += 450.0 * dt;
  }

  void _snapRotationTo90() {
    final target = (rotationDegrees / 90.0).round() * 90.0;
    rotationDegrees = target % 360.0;
  }

  /// Принудительный прыжок (от прыжковой платформы / Pad)
  void applyPadJump(double padVelocity) {
    velocity.y = padVelocity * gravity.sign;
    isGrounded = false;
  }

  /// Прыжок от сферы (Orb)
  void applyOrbJump(double orbVelocity) {
    velocity.y = orbVelocity * gravity.sign;
    isGrounded = false;
  }
}
