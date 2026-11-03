import '../../core/constants/game_constants.dart';
import '../../core/math/vector2d.dart';
import '../../domain/models/level_object.dart';
import '../../domain/models/player_mode.dart';
import 'player_controller.dart';

enum CollisionResult {
  none,
  death,
  win,
  padTriggered,
  orbTriggered,
  portalTriggered,
}

enum _BlockResolution {
  none,
  landed,
  death,
}

class CollisionDetector {
  final double groundY;
  final double ceilingY;

  // Чтобы орб не срабатывал дважды за одно нажатие
  final Set<String> _activatedOrbs = {};

  CollisionDetector({
    this.groundY = 0.0,
    this.ceilingY = 14.0 * GameConstants.tileSize,
  });

  void reset() {
    _activatedOrbs.clear();
  }

  /// Проверяет и разрешает коллизии игрока с окружением
  CollisionResult checkAndResolve({
    required PlayerController player,
    required List<LevelObject> objects,
  }) {
    if (player.isDead || player.hasWon) return CollisionResult.none;

    final gSign = player.gravity.sign;
    bool groundedThisFrame = false;

    // 1. Проверка коллизий с полом и потолком уровня
    final maxAllowedY = ceilingY - GameConstants.playerSize;

    if (player.gravity == GravityDirection.down) {
      if (player.position.y <= groundY) {
        player.position.y = groundY;
        if (player.velocity.y < 0.0) {
          player.velocity.y = 0.0;
        }
        groundedThisFrame = true;
      } else if (player.position.y >= maxAllowedY) {
        player.position.y = maxAllowedY;
        if (player.velocity.y > 0.0) {
          player.velocity.y = 0.0;
        }
      }
    } else {
      // При инвертированной гравитации пол сверху
      if (player.position.y >= maxAllowedY) {
        player.position.y = maxAllowedY;
        if (player.velocity.y > 0.0) {
          player.velocity.y = 0.0;
        }
        groundedThisFrame = true;
      } else if (player.position.y <= groundY) {
        player.position.y = groundY;
        if (player.velocity.y < 0.0) {
          player.velocity.y = 0.0;
        }
      }
    }

    // Для режима Корабля: пол и потолок жестко ограничивают полет
    if (player.mode == PlayerMode.ship) {
      if (player.position.y <= groundY) {
        player.position.y = groundY;
        player.velocity.y = 0.0;
      } else if (player.position.y >= maxAllowedY) {
        player.position.y = maxAllowedY;
        player.velocity.y = 0.0;
      }
    }

    // Фильтруем объекты рядом с игроком для оптимизации (broad-phase)
    final nearbyObjects = objects.where((obj) {
      final dx = (obj.pixelX - player.position.x).abs();
      return dx < GameConstants.tileSize * 3.0;
    });

    for (final obj in nearbyObjects) {
      switch (obj.type) {
        case ObjectType.solidBlock:
          final res = _resolveBlockCollision(player, obj, gSign);
          if (res == _BlockResolution.death) {
            player.isDead = true;
            return CollisionResult.death;
          } else if (res == _BlockResolution.landed) {
            groundedThisFrame = true;
          }
          break;

        case ObjectType.spike:
        case ObjectType.hangingSpike:
          if (obj.spikeHitbox.intersectsAABB(player.hitbox)) {
            player.isDead = true;
            return CollisionResult.death;
          }
          break;

        case ObjectType.jumpPad:
          if (player.hitbox.intersects(obj.padAabb)) {
            final padVel = _getPadVelocity(obj.padColor);
            player.applyPadJump(padVel);
            player.isGrounded = false;
            groundedThisFrame = false;
            return CollisionResult.padTriggered;
          }
          break;

        case ObjectType.jumpOrb:
          final orbCenter = Vector2D(
            obj.pixelX + GameConstants.tileSize / 2.0,
            obj.pixelY + GameConstants.tileSize / 2.0,
          );
          final playerCenter = Vector2D(
            player.position.x + GameConstants.playerSize / 2.0,
            player.position.y + GameConstants.playerSize / 2.0,
          );
          final distSq = (orbCenter - playerCenter).lengthSquared;

          if (distSq <= GameConstants.orbActivationRadius * GameConstants.orbActivationRadius) {
            // Орб срабатывает только при тапе
            if (player.justPressedInput && !_activatedOrbs.contains(obj.id)) {
              _activatedOrbs.add(obj.id);
              final orbVel = _getOrbVelocity(obj.orbColor);
              player.applyOrbJump(orbVel);
              player.isGrounded = false;
              groundedThisFrame = false;
              return CollisionResult.orbTriggered;
            }
          }
          break;

        case ObjectType.portalMode:
          if (player.hitbox.intersects(obj.aabb)) {
            player.mode = obj.targetMode;
            return CollisionResult.portalTriggered;
          }
          break;

        case ObjectType.portalGravity:
          if (player.hitbox.intersects(obj.aabb)) {
            player.gravity = obj.targetGravity;
            return CollisionResult.portalTriggered;
          }
          break;

        case ObjectType.portalSpeed:
          if (player.hitbox.intersects(obj.aabb)) {
            player.speedModifier = obj.targetSpeed;
            return CollisionResult.portalTriggered;
          }
          break;

        case ObjectType.finishLine:
          if (player.position.x >= obj.pixelX) {
            player.hasWon = true;
            return CollisionResult.win;
          }
          break;

        case ObjectType.coin:
          // Сбор секретной монетки
          break;
      }
    }

    // Обновляем статус заземления персонажа
    player.isGrounded = groundedThisFrame;

    return CollisionResult.none;
  }

  /// Обработка блока: приземление сверху = хорошо, удар о грань или снизу = Смерть!
  _BlockResolution _resolveBlockCollision(
    PlayerController player,
    LevelObject block,
    double gSign,
  ) {
    final blockBox = block.aabb;

    // 1. Проверяем наличие горизонтального пересечения
    final playerLeft = player.position.x + GameConstants.playerHitboxPadding;
    final playerRight = player.position.x + GameConstants.playerSize - GameConstants.playerHitboxPadding;
    final blockLeft = blockBox.minX;
    final blockRight = blockBox.maxX;

    final hasHorizontalOverlap = playerRight > blockLeft + 2.0 && playerLeft < blockRight - 2.0;
    if (!hasHorizontalOverlap) {
      return _BlockResolution.none;
    }

    const landingTolerance = 18.0;

    if (gSign > 0) {
      // Обычная гравитация (вниз)
      final feetY = player.position.y;
      final blockTop = blockBox.maxY;

      // Если ноги игрока находятся около вершины блока и игрок падает/стоит
      final isFallingOrStanding = player.velocity.y <= 50.0;
      final isNearTop = feetY >= blockTop - landingTolerance && feetY <= blockTop + 4.0;

      if (isFallingOrStanding && isNearTop) {
        player.position.y = blockTop;
        if (player.velocity.y < 0.0) {
          player.velocity.y = 0.0;
        }
        return _BlockResolution.landed;
      }

      // Если это не безопасное приземление, проверяем удар о грань или снизу
      if (player.hitbox.intersects(blockBox)) {
        return _BlockResolution.death;
      }
    } else {
      // Инвертированная гравитация (вверх)
      final headY = player.position.y + GameConstants.playerSize;
      final blockBottom = blockBox.minY;

      final isFallingOrStanding = player.velocity.y >= -50.0;
      final isNearBottom = headY <= blockBottom + landingTolerance && headY >= blockBottom - 4.0;

      if (isFallingOrStanding && isNearBottom) {
        player.position.y = blockBottom - GameConstants.playerSize;
        if (player.velocity.y > 0.0) {
          player.velocity.y = 0.0;
        }
        return _BlockResolution.landed;
      }

      if (player.hitbox.intersects(blockBox)) {
        return _BlockResolution.death;
      }
    }

    return _BlockResolution.none;
  }

  double _getPadVelocity(PadColor color) {
    switch (color) {
      case PadColor.yellow:
        return GameConstants.yellowPadVelocity;
      case PadColor.pink:
        return GameConstants.pinkPadVelocity;
      case PadColor.red:
        return GameConstants.redPadVelocity;
    }
  }

  double _getOrbVelocity(OrbColor color) {
    switch (color) {
      case OrbColor.yellow:
        return GameConstants.yellowOrbVelocity;
      case OrbColor.pink:
        return GameConstants.pinkOrbVelocity;
      case OrbColor.red:
        return GameConstants.redOrbVelocity;
    }
  }
}
