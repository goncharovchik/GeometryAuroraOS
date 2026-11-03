import 'package:flutter_test/flutter_test.dart';
import 'package:geometry_dash_aurora/core/constants/game_constants.dart';
import 'package:geometry_dash_aurora/data/game_storage.dart';
import 'package:geometry_dash_aurora/domain/models/level_object.dart';
import 'package:geometry_dash_aurora/domain/models/player_character.dart';
import 'package:geometry_dash_aurora/domain/models/player_mode.dart';
import 'package:geometry_dash_aurora/domain/models/upgrade.dart';
import 'package:geometry_dash_aurora/engine/collision_detector.dart';
import 'package:geometry_dash_aurora/engine/game_ticker.dart';
import 'package:geometry_dash_aurora/engine/player_controller.dart';

void main() {
  group('Физический движок и игровой цикл', () {
    test('FixedTimestepGameTicker делит кадр на фиксированные шаги', () {
      final ticker = FixedTimestepGameTicker();
      int stepCount = 0;
      double lastAlpha = 0.0;

      // 0.034 секунды (примерно 2 шага по 1/60 с = 0.01666 с)
      ticker.update(
        0.034,
        onPhysicsStep: (dt) {
          stepCount++;
          expect(dt, closeTo(GameConstants.fixedDeltaTime, 0.0001));
        },
        onRenderStep: (alpha) {
          lastAlpha = alpha;
        },
      );

      expect(stepCount, equals(2));
      expect(lastAlpha, greaterThanOrEqualTo(0.0));
      expect(lastAlpha, lessThanOrEqualTo(1.0));
    });

    test('Куб прыгает и падает под действием гравитации', () {
      final player = PlayerController(startX: 0.0, startY: 0.0);
      player.isGrounded = true;

      // Нажимаем прыжок
      player.setInput(isHolding: true, justPressed: true);
      player.updatePhysics(GameConstants.fixedDeltaTime);

      expect(player.velocity.y, closeTo(GameConstants.jumpVelocity - GameConstants.gravity * GameConstants.fixedDeltaTime, 5.0));
      expect(player.position.y, greaterThan(0.0));
      expect(player.isGrounded, isFalse);
    });

    test('Корабль (Ship Mode) плавно набирает высоту при зажатии', () {
      final player = PlayerController(startX: 0.0, startY: 100.0);
      player.mode = PlayerMode.ship;

      player.setInput(isHolding: true);
      player.updatePhysics(GameConstants.fixedDeltaTime);

      expect(player.velocity.y, greaterThan(0.0));
      expect(player.rotationDegrees, greaterThan(0.0)); // Нос наклоняется вверх
    });
  });

  group('Улучшенная физика: буферизация ввода, время койота и фикс шара', () {
    test('Буферизация прыжка: тап в воздухе перед приземлением вызывает прыжок в момент касания', () {
      final player = PlayerController(startX: 0.0, startY: 10.0);
      player.isGrounded = false;

      // Игрок тапает прыжок за 0.05 с до земли
      player.setInput(isHolding: false, justPressed: true);
      expect(player.jumpBufferTimer, greaterThan(0.0));

      // Приземление
      player.isGrounded = true;
      player.updatePhysics(GameConstants.fixedDeltaTime);

      // Прыжок должен сработать благодаря буферу!
      expect(player.velocity.y, greaterThan(500.0));
      expect(player.jumpBufferTimer, equals(0.0));
    });

    test('Время койота: сход с платформы позволяет прыгнуть еще несколько кадров', () {
      final player = PlayerController(startX: 0.0, startY: 48.0);
      player.coyoteTimer = 0.08; // Игрок только что сошел с края
      player.isGrounded = false;

      // Нажимаем прыжок в воздухе в пределах окна койота
      player.setInput(isHolding: false, justPressed: true);
      player.updatePhysics(GameConstants.fixedDeltaTime);

      // Прыжок успешен, несмотря на то что isGrounded был false!
      expect(player.velocity.y, greaterThan(500.0));
      expect(player.coyoteTimer, equals(0.0));
    });

    test('Фикс физики Шара: переключение гравитации придает импульс в сторону новой гравитации', () {
      final player = PlayerController(startX: 0.0, startY: 0.0);
      player.mode = PlayerMode.ball;
      player.gravity = GravityDirection.down;
      player.isGrounded = true;

      // Тап на полу инвертирует гравитацию на UP
      player.setInput(isHolding: false, justPressed: true);
      player.updatePhysics(GameConstants.fixedDeltaTime);

      expect(player.gravity, equals(GravityDirection.up));
      // Скорость должна быть положительной (вверх к потолку)
      expect(player.velocity.y, greaterThan(100.0));
    });
  });

  group('Новые режимы для разнообразия: Волна (Wave) и НЛО (UFO)', () {
    test('Волна мгновенно движется под углом 45 градусов вверх при зажатии и вниз при отпускании', () {
      final player = PlayerController(startX: 0.0, startY: 100.0);
      player.mode = PlayerMode.wave;

      // Зажатие — полет вверх под 45 градусов
      player.setInput(isHolding: true);
      player.updatePhysics(GameConstants.fixedDeltaTime);
      expect(player.velocity.y, equals(player.velocity.x));
      expect(player.rotationDegrees, equals(-45.0));

      // Отпускание — полет вниз под 45 градусов
      player.setInput(isHolding: false);
      player.updatePhysics(GameConstants.fixedDeltaTime);
      expect(player.velocity.y, equals(-player.velocity.x));
      expect(player.rotationDegrees, equals(45.0));
    });

    test('НЛО (UFO) прыгает в любой точке воздуха при тапе', () {
      final player = PlayerController(startX: 0.0, startY: 200.0);
      player.mode = PlayerMode.ufo;
      player.isGrounded = false;

      player.setInput(isHolding: false, justPressed: true);
      player.updatePhysics(GameConstants.fixedDeltaTime);

      expect(player.velocity.y, closeTo(GameConstants.ufoJumpVelocity, 20.0));
    });
  });

  group('Система коллизий, монеток и защиты щитом', () {
    late CollisionDetector detector;
    late PlayerController player;

    setUp(() {
      detector = CollisionDetector();
      player = PlayerController(startX: 0.0, startY: 0.0);
    });

    test('Столкновение с шипом приводит к смерти без щита', () {
      final spike = LevelObject(
        id: 'spike_1',
        type: ObjectType.spike,
        gridX: 0,
        gridY: 0,
      );

      player.shieldCharges = 0;
      player.position.set(spike.pixelX, spike.pixelY);
      final result = detector.checkAndResolve(player: player, objects: [spike]);

      expect(result, equals(CollisionResult.death));
      expect(player.isDead, isTrue);
    });

    test('Энергетический щит спасает от гибели и активирует неуязвимость', () {
      final spike = LevelObject(
        id: 'spike_shield_test',
        type: ObjectType.spike,
        gridX: 0,
        gridY: 0,
      );

      player.shieldCharges = 1;
      player.position.set(spike.pixelX, spike.pixelY);
      final result = detector.checkAndResolve(player: player, objects: [spike]);

      expect(result, equals(CollisionResult.shieldAbsorbed));
      expect(player.isDead, isFalse);
      expect(player.shieldCharges, equals(0));
      expect(player.shieldInvulnerabilityTimer, greaterThan(0.0));
    });

    test('Сбор монетки на карте и притяжение магнитом', () {
      final coin = LevelObject(
        id: 'test_coin',
        type: ObjectType.coin,
        gridX: 1,
        gridY: 0,
      );

      // Игрок находится в зоне действия магнита
      player.magnetRadius = 60.0;
      player.position.set(coin.pixelX - 30.0, coin.pixelY);

      final result = detector.checkAndResolve(player: player, objects: [coin]);
      expect(result, equals(CollisionResult.coinCollected));
      expect(detector.collectedCoins.contains('test_coin'), isTrue);
    });

    test('Безопасное приземление сверху на твердый блок', () {
      final block = LevelObject(
        id: 'block_1',
        type: ObjectType.solidBlock,
        gridX: 0,
        gridY: 0,
      );

      player.position.set(block.pixelX, block.aabb.maxY - 8.0);
      player.velocity.y = -10.0;

      final result = detector.checkAndResolve(player: player, objects: [block]);

      expect(result, equals(CollisionResult.none));
      expect(player.isDead, isFalse);
      expect(player.isGrounded, isTrue);
      expect(player.position.y, equals(block.aabb.maxY));
    });

    test('Удар сбоку в блок приводит к смерти', () {
      final block = LevelObject(
        id: 'block_1',
        type: ObjectType.solidBlock,
        gridX: 1,
        gridY: 0,
      );

      player.shieldCharges = 0;
      player.position.set(block.pixelX - 10.0, 0.0);

      final result = detector.checkAndResolve(player: player, objects: [block]);

      expect(result, equals(CollisionResult.death));
      expect(player.isDead, isTrue);
    });

    test('Прыжковый пад автоматически подбрасывает игрока', () {
      final pad = LevelObject(
        id: 'pad_1',
        type: ObjectType.jumpPad,
        gridX: 0,
        gridY: 0,
        padColor: PadColor.yellow,
      );

      player.position.set(pad.pixelX, 0.0);
      final result = detector.checkAndResolve(player: player, objects: [pad]);

      expect(result, equals(CollisionResult.padTriggered));
      expect(player.velocity.y, equals(GameConstants.yellowPadVelocity));
      expect(player.isGrounded, isFalse);
    });
  });

  group('Кастомные персонажи и прокачки за очки', () {
    test('Каталог содержит 6 кастомных персонажей с уникальными стилями и перками', () {
      expect(PlayerCharacter.characters.length, equals(6));

      final phantom = PlayerCharacter.getById('phantom');
      expect(phantom.style, equals(CharacterStyle.phantom));
      expect(phantom.hitboxScale, lessThan(1.0)); // Компактный хитбокс
      expect(phantom.bonusCoyoteTime, greaterThan(0.0));

      final titan = PlayerCharacter.getById('cyber_titan');
      expect(titan.hasBuiltinShield, isTrue);

      final magnetron = PlayerCharacter.getById('magnetron');
      expect(magnetron.bonusMagnetRadius, greaterThan(50.0));
    });

    test('Ветка прокачки рассчитывает стоимость и эффекты', () {
      final magnet = Upgrade.getById('magnet');
      expect(magnet.maxLevel, equals(5));
      expect(magnet.getCost(0), equals(magnet.baseCost));
      expect(magnet.getCost(1), greaterThan(magnet.getCost(0)));

      final desc = magnet.getLevelEffectDescription(2);
      expect(desc, contains('+50 px'));
    });

    test('GameStorage начисляет очки и разблокирует улучшения', () {
      final storage = GameStorage.instance;
      final initialPoints = storage.totalPoints;

      storage.addPoints(500);
      expect(storage.totalPoints, equals(initialPoints + 500));

      // Прокачиваем магнит
      final canUpgrade = storage.upgradeSkill('magnet');
      expect(canUpgrade, isTrue);
      expect(storage.getUpgradeLevel('magnet'), greaterThan(0));
    });
  });
}
