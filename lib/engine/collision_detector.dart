import '../../core/constants/game_constants.dart';
import '../../core/math/hitbox.dart';
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

    final playerBox = player.hitbox;
    final gSign = player.gravity.sign;

    // 1. Проверка коллизий с полом уровня
    if (player.gravity == GravityDirection.down) {
      if (player.position.y <= groundY) {
        player.position.y = groundY;
        player.velocity.y = 0.0;
        player.isGrounded = true;
      }
    } else {
      // При инвертированной гравитации пол сверху
      if (player.position.y >= ceilingY - GameConstants.playerSize) {
        player.position.y = ceilingY - GameConstants.playerSize;
        player.velocity.y = 0.0;
        player.isGrounded = true;
      }
    }

    // Для режима Корабля: пол и потолок ограничивают полет
    if (player.mode == PlayerMode.ship) {
      if (player.position.y <= groundY) {
        player.position.y = groundY;
        player.velocity.y = 0.0;
      } else if (player.position.y >= ceilingY - GameConstants.playerSize) {
        player.position.y = ceilingY - GameConstants.playerSize;
        player.velocity.y = 0.0;
      }
    }

    // Фильтруем объекты рядом с игроком для оптимизации (broad-phase)
    final nearbyObjects = objects.where((obj) {
      final dx = (obj.pixelX - player.position.x).abs();
      return dx < GameConstants.tileSize * 3.0;
    });

    bool landedOnBlock = false;

    for (final obj in nearbyObjects) {
      switch (obj.type) {
        case ObjectType.solidBlock:
          final res = _resolveBlockCollision(player, playerBox, obj, gSign);
          if (res == CollisionResult.death) {
            player.isDead = true;
            return CollisionResult.death;
          } else if (res == CollisionResult.none) {
            landedOnBlock = true;
          }
          break;

        case ObjectType.spike:
        case ObjectType.hangingSpike:
          if (obj.spikeHitbox.intersectsAABB(playerBox)) {
            player.isDead = true;
            return CollisionResult.death;
          }
          break;

        case ObjectType.jumpPad:
          if (playerBox.intersects(obj.aabb)) {
            final padVel = _getPadVelocity(obj.padColor);
            player.applyPadJump(padVel);
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
              return CollisionResult.orbTriggered;
            }
          }
          break;

        case ObjectType.portalMode:
          if (playerBox.intersects(obj.aabb)) {
            player.mode = obj.targetMode;
            return CollisionResult.portalTriggered;
          }
          break;

        case ObjectType.portalGravity:
          if (playerBox.intersects(obj.aabb)) {
            player.gravity = obj.targetGravity;
            return CollisionResult.portalTriggered;
          }
          break;

        case ObjectType.portalSpeed:
          if (playerBox.intersects(obj.aabb)) {
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

    if (landedOnBlock) {
      player.isGrounded = true;
    }

    return CollisionResult.none;
  }

  /// Обработка блока: приземление сверху = хорошо, удар о грань или снизу = Смерть!
  CollisionResult _resolveBlockCollision(
    PlayerController player,
    AABB playerBox,
    LevelObject block,
    double gSign,
  ) {
    final blockBox = block.aabb;
    if (!playerBox.intersects(blockBox)) return CollisionResult.none;

    final intersection = playerBox.intersection(blockBox);
    if (intersection == null) return CollisionResult.none;

    // В Geometry Dash если игрок падает сверху на блок:
    // Допуск по высоте приземления (landing margin)
    const landingTolerance = 14.0;

    if (gSign > 0) {
      // Обычная гравитация (вниз)
      final feetY = player.position.y;
      final blockTop = blockBox.maxY;

      // Если ноги игрока находились около вершины блока и игрок падал/двигался вниз
      if ((feetY - blockTop).abs() <= landingTolerance && player.velocity.y <= 50.0) {
        player.position.y = blockTop;
        player.velocity.y = 0.0;
        return CollisionResult.none; // Безопасное приземление
      }
    } else {
      // Инвертированная гравитация (вверх)
      final headY = player.position.y + GameConstants.playerSize;
      final blockBottom = blockBox.minY;

      if ((headY - blockBottom).abs() <= landingTolerance && player.velocity.y >= -50.0) {
        player.position.y = blockBottom - GameConstants.playerSize;
        player.velocity.y = 0.0;
        return CollisionResult.none;
      }
    }

    // Любое столкновение сбоку или ударом снизу головой в блок — это смерть!
    return CollisionResult.death;
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
