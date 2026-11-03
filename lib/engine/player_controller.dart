import '../../core/constants/game_constants.dart';
import '../../core/math/hitbox.dart';
import '../../core/math/vector2d.dart';
import '../../domain/models/player_mode.dart';
import '../../data/game_storage.dart';

/// Состояние и улучшенная физика персонажа
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

  // Буферизация прыжков и таймер койота (улучшение отзывчивости физики)
  double jumpBufferTimer = 0.0;
  double coyoteTimer = 0.0;
  double ballFlipCooldown = 0.0;

  // Энергощит и защита от крушения
  int shieldCharges = 0;
  double shieldInvulnerabilityTimer = 0.0;

  // Перки персонажа и прокачки
  double jumpForceMultiplier = 1.0;
  double thrustMultiplier = 1.0;
  double effectiveCoyoteDuration = GameConstants.coyoteDuration;
  double effectiveJumpBufferDuration = GameConstants.jumpBufferDuration;
  double magnetRadius = GameConstants.baseMagnetRadius;
  double scoreMultiplier = 1.0;
  double hitboxScale = 1.0;
  
  // Для анимации и следа (trail)
  final List<Vector2D> trail = [];
  static const int maxTrailLength = 14;

  PlayerController({
    double startX = 0.0,
    double startY = 0.0,
  }) {
    position.set(startX, startY);
    applyUpgrades();
  }

  /// Применяет прокачки и характеристики выбранного персонажа из хранилища
  void applyUpgrades() {
    final storage = GameStorage.instance;
    effectiveCoyoteDuration = storage.effectiveCoyoteDuration;
    effectiveJumpBufferDuration = storage.effectiveJumpBufferDuration;
    thrustMultiplier = storage.effectiveThrustMultiplier;
    jumpForceMultiplier = storage.effectiveJumpForceMultiplier;
    magnetRadius = storage.effectiveMagnetRadius;
    scoreMultiplier = storage.effectiveScoreMultiplier;
    hitboxScale = storage.effectiveHitboxScale;
    shieldCharges = storage.maxShieldCharges;
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
    jumpBufferTimer = 0.0;
    coyoteTimer = 0.0;
    ballFlipCooldown = 0.0;
    shieldInvulnerabilityTimer = 0.0;
    trail.clear();
    applyUpgrades();
  }

  AABB get hitbox {
    final padding = GameConstants.playerHitboxPadding + ((1.0 - hitboxScale) * 12.0);
    return AABB.fromDimensions(
      x: position.x + padding,
      y: position.y + padding,
      width: GameConstants.playerSize - padding * 2,
      height: GameConstants.playerSize - padding * 2,
    );
  }

  /// Обновление ввода с буферизацией
  void setInput({required bool isHolding, bool justPressed = false}) {
    isHoldingInput = isHolding;
    if (justPressed) {
      justPressedInput = true;
      jumpBufferTimer = effectiveJumpBufferDuration;
    }
  }

  /// Фиксированный шаг физики (вызывается на каждом тике 60 Гц)
  void updatePhysics(double dt) {
    if (isDead || hasWon) return;

    // Таймеры буфера ввода и неуязвимости
    if (jumpBufferTimer > 0.0) jumpBufferTimer -= dt;
    if (coyoteTimer > 0.0) coyoteTimer -= dt;
    if (ballFlipCooldown > 0.0) ballFlipCooldown -= dt;
    if (shieldInvulnerabilityTimer > 0.0) shieldInvulnerabilityTimer -= dt;

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
      case PlayerMode.wave:
        _updateWave(dt);
        break;
      case PlayerMode.ufo:
        _updateUfo(dt);
        break;
    }

    // Применяем перемещение
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;

    // Обновляем след (trail)
    trail.add(Vector2D.copy(position));
    if (trail.length > maxTrailLength) {
      trail.removeAt(0);
    }

    // Сбрасываем флаг разового нажатия
    justPressedInput = false;
  }

  void _updateCube(double dt) {
    final gSign = gravity.sign;
    final canJump = isGrounded || coyoteTimer > 0.0;
    final wantsJump = justPressedInput || jumpBufferTimer > 0.0 || isHoldingInput;

    // Прыжок с поддержкой буферизации ввода и времени койота
    if (canJump && wantsJump) {
      velocity.y = GameConstants.jumpVelocity * jumpForceMultiplier * gSign;
      isGrounded = false;
      coyoteTimer = 0.0;
      jumpBufferTimer = 0.0;
    }

    // Применяем гравитацию
    if (!isGrounded) {
      velocity.y -= GameConstants.gravity * gSign * dt;

      // Ограничение терминальной скорости падения
      if (gSign > 0) {
        if (velocity.y < -GameConstants.maxFallSpeed) {
          velocity.y = -GameConstants.maxFallSpeed;
        }
      } else {
        if (velocity.y > GameConstants.maxFallSpeed) {
          velocity.y = GameConstants.maxFallSpeed;
        }
      }

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
    final thrust = GameConstants.shipThrust * thrustMultiplier;

    // Корабль: тяга вверх при удержании, гравитация при отпускании
    if (isHoldingInput) {
      velocity.y += thrust * gSign * dt;
    } else {
      velocity.y -= GameConstants.shipGravity * gSign * dt;
    }

    // Ограничение максимальной вертикальной скорости
    final maxV = GameConstants.shipMaxVerticalSpeed * thrustMultiplier;
    velocity.y = velocity.y.clamp(-maxV, maxV);

    // Угол наклона носа корабля пропорционален вертикальной скорости
    final targetAngle = (velocity.y / maxV) * GameConstants.shipMaxTiltAngle;
    rotationDegrees += (targetAngle - rotationDegrees) * 12.0 * dt;
  }

  void _updateBall(double dt) {
    final wantsFlip = justPressedInput || (isHoldingInput && ballFlipCooldown <= 0.0) || jumpBufferTimer > 0.0;

    // Шар: клик на поверхности инвертирует гравитацию и придает импульс в НОВОМ направлении
    if (isGrounded && wantsFlip) {
      gravity = gravity.inverted;
      isGrounded = false;
      coyoteTimer = 0.0;
      jumpBufferTimer = 0.0;
      ballFlipCooldown = 0.18; // Защита от бесконечного дрожания при зажатии

      // Импульс строго в сторону новой гравитации (-gravity.sign)
      velocity.y = -gravity.sign * 190.0 * jumpForceMultiplier;
    } else if (!isGrounded) {
      final gSign = gravity.sign;
      velocity.y -= GameConstants.gravity * gSign * dt;
      if (gSign > 0) {
        if (velocity.y < -GameConstants.maxFallSpeed) {
          velocity.y = -GameConstants.maxFallSpeed;
        }
      } else {
        if (velocity.y > GameConstants.maxFallSpeed) {
          velocity.y = GameConstants.maxFallSpeed;
        }
      }
    }

    // Непрерывное вращение шара при движении
    rotationDegrees += 480.0 * dt;
  }

  void _updateWave(double dt) {
    // Волна: мгновенное диагональное движение под 45 градусов
    final gSign = gravity.sign;
    final waveV = velocity.x * thrustMultiplier;

    if (isHoldingInput) {
      velocity.y = waveV * gSign;
      rotationDegrees = gSign > 0 ? -GameConstants.waveTiltAngle : GameConstants.waveTiltAngle;
    } else {
      velocity.y = -waveV * gSign;
      rotationDegrees = gSign > 0 ? GameConstants.waveTiltAngle : -GameConstants.waveTiltAngle;
    }
  }

  void _updateUfo(double dt) {
    final gSign = gravity.sign;
    final wantsFlap = justPressedInput || jumpBufferTimer > 0.0;

    // НЛО: прыжок в любой точке воздуха на каждый тап (Flappy Bird)
    if (wantsFlap) {
      velocity.y = GameConstants.ufoJumpVelocity * jumpForceMultiplier * gSign;
      jumpBufferTimer = 0.0;
      isGrounded = false;
    } else {
      velocity.y -= GameConstants.gravity * 0.95 * gSign * dt;
      if (gSign > 0) {
        if (velocity.y < -GameConstants.maxFallSpeed) {
          velocity.y = -GameConstants.maxFallSpeed;
        }
      } else {
        if (velocity.y > GameConstants.maxFallSpeed) {
          velocity.y = GameConstants.maxFallSpeed;
        }
      }
    }

    // Плавный наклон тарелки
    final targetTilt = (velocity.y / GameConstants.ufoJumpVelocity).clamp(-1.0, 1.0) * 22.0;
    rotationDegrees += (targetTilt - rotationDegrees) * 10.0 * dt;
  }

  void _snapRotationTo90() {
    final target = (rotationDegrees / 90.0).round() * 90.0;
    rotationDegrees = target % 360.0;
  }

  /// Принудительный прыжок (от прыжковой платформы / Pad)
  void applyPadJump(double padVelocity) {
    velocity.y = padVelocity * jumpForceMultiplier * gravity.sign;
    isGrounded = false;
    coyoteTimer = 0.0;
  }

  /// Прыжок от сферы (Orb)
  void applyOrbJump(double orbVelocity) {
    velocity.y = orbVelocity * jumpForceMultiplier * gravity.sign;
    isGrounded = false;
    coyoteTimer = 0.0;
  }
}
