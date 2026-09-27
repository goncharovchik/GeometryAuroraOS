import 'package:flutter_test/flutter_test.dart';
import 'package:geometry_dash_aurora/core/constants/game_constants.dart';
import 'package:geometry_dash_aurora/domain/models/level.dart';
import 'package:geometry_dash_aurora/domain/models/level_object.dart';
import 'package:geometry_dash_aurora/domain/models/player_mode.dart';
import 'package:geometry_dash_aurora/engine/collision_detector.dart';
import 'package:geometry_dash_aurora/engine/game_session.dart';
import 'package:geometry_dash_aurora/engine/game_ticker.dart';
import 'package:geometry_dash_aurora/engine/player_controller.dart';

void main() {
  group('Физический движок и игровой цикл', () {
    test('FixedTimestepGameTicker делит кадр на фиксированные шаги', () {
      final ticker = FixedTimestepGameTicker();
      int stepCount = 0;
      double lastAlpha = 0.0;

      // 0.033 секунды (примерно 2 шага по 1/60 с = 0.01666 с)
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

  group('Система коллизий', () {
    late CollisionDetector detector;
    late PlayerController player;

    setUp(() {
      detector = CollisionDetector();
      player = PlayerController(startX: 0.0, startY: 0.0);
    });

    test('Столкновение с шипом приводит к смерти', () {
      final spike = LevelObject(
        id: 'spike_1',
        type: ObjectType.spike,
        gridX: 0,
        gridY: 0,
      );

      player.position.set(spike.pixelX, spike.pixelY);
      final result = detector.checkAndResolve(player: player, objects: [spike]);

      expect(result, equals(CollisionResult.death));
      expect(player.isDead, isTrue);
    });

    test('Безопасное приземление сверху на твердый блок', () {
      final block = LevelObject(
        id: 'block_1',
        type: ObjectType.solidBlock,
        gridX: 0,
        gridY: 0,
      );

      // Игрок падает сверху, пересекая верхнюю грань блока с учетом padding хитбокса
      player.position.set(block.pixelX, block.aabb.maxY - 8.0);
      player.velocity.y = -10.0; // Падает вниз

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

      // Игрок бежит справа в боковую грань блока
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

    test('Сфера (Jump Orb) срабатывает только при тапе', () {
      final orb = LevelObject(
        id: 'orb_1',
        type: ObjectType.jumpOrb,
        gridX: 0,
        gridY: 1,
        orbColor: OrbColor.yellow,
      );

      player.position.set(orb.pixelX, orb.pixelY);

      // 1. Без нажатия сфера НЕ срабатывает
      player.justPressedInput = false;
      var result = detector.checkAndResolve(player: player, objects: [orb]);
      expect(result, equals(CollisionResult.none));

      // 2. С тапом сфера активируется
      player.justPressedInput = true;
      result = detector.checkAndResolve(player: player, objects: [orb]);
      expect(result, equals(CollisionResult.orbTriggered));
      expect(player.velocity.y, equals(GameConstants.yellowOrbVelocity));
    });
  });

  group('Сериализация уровней и GameSession', () {
    test('Уровень корректно преобразуется в JSON и восстанавливается', () {
      final level = Level(
        id: 'test_level',
        title: 'Тестовый уровень',
        creator: 'Тестировщик',
        difficulty: LevelDifficulty.hard,
        songTitle: 'Test Song',
        bpm: 135.0,
        totalTilesLength: 100,
        objects: [
          LevelObject(
            id: 'obj_1',
            type: ObjectType.solidBlock,
            gridX: 5,
            gridY: 1,
          ),
          LevelObject(
            id: 'obj_2',
            type: ObjectType.spike,
            gridX: 6,
            gridY: 0,
            rotationDegrees: 180.0,
          ),
        ],
      );

      final json = level.toJson();
      final restored = Level.fromJson(json);

      expect(restored.id, equals(level.id));
      expect(restored.title, equals(level.title));
      expect(restored.difficulty, equals(LevelDifficulty.hard));
      expect(restored.bpm, equals(135.0));
      expect(restored.objects.length, equals(2));
      expect(restored.objects[1].rotationDegrees, equals(180.0));
    });

    test('GameSession корректно отслеживает прогресс и попытки', () {
      final level = Level(
        id: 'test',
        title: 'Test',
        creator: 'OMP',
        difficulty: LevelDifficulty.normal,
        songTitle: 'Test',
        bpm: 120.0,
        totalTilesLength: 50,
        objects: [],
      );

      final session = GameSession(level: level);
      expect(session.attempts, equals(1));
      expect(session.currentPercentage, equals(0.0));

      // Сдвигаем игрока на половину длины уровня
      session.player.position.x = level.lengthInPixels / 2.0;
      expect(session.currentPercentage, closeTo(50.0, 0.1));

      // Смерть игрока
      session.onDeath();
      expect(session.attempts, equals(2));
      expect(session.bestPercentage, closeTo(50.0, 0.1));
    });
  });
}
