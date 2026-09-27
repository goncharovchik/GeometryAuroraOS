import '../../domain/models/level.dart';
import '../../domain/models/player_mode.dart';
import '../../core/math/vector2d.dart';
import 'player_controller.dart';
import 'collision_detector.dart';

class Checkpoint {
  final Vector2D position;
  final Vector2D velocity;
  final double rotation;
  final PlayerMode mode;
  final GravityDirection gravity;
  final SpeedModifier speed;

  Checkpoint({
    required this.position,
    required this.velocity,
    required this.rotation,
    required this.mode,
    required this.gravity,
    required this.speed,
  });
}

/// Управление игровой сессией и прогрессом прохождения уровня
class GameSession {
  final Level level;
  final PlayerController player;
  final CollisionDetector collisionDetector;

  int attempts = 1;
  double bestPercentage = 0.0;
  bool isPracticeMode = false;
  final List<Checkpoint> checkpoints = [];

  GameSession({
    required this.level,
  })  : player = PlayerController(),
        collisionDetector = CollisionDetector() {
    restart();
  }

  double get currentPercentage {
    if (level.lengthInPixels <= 0.0) return 0.0;
    final pct = (player.position.x / level.lengthInPixels) * 100.0;
    return pct.clamp(0.0, 100.0);
  }

  void restart() {
    if (isPracticeMode && checkpoints.isNotEmpty) {
      // Откат на последний чекпоинт в режиме практики
      final cp = checkpoints.last;
      player.reset(startX: cp.position.x, startY: cp.position.y);
      player.velocity.set(cp.velocity.x, cp.velocity.y);
      player.rotationDegrees = cp.rotation;
      player.mode = cp.mode;
      player.gravity = cp.gravity;
      player.speedModifier = cp.speed;
    } else {
      // Полный рестарт с начала уровня
      player.reset(startX: 0.0, startY: 0.0);
      collisionDetector.reset();
    }
  }

  void onDeath() {
    attempts++;
    final curPct = currentPercentage;
    if (curPct > bestPercentage) {
      bestPercentage = curPct;
    }
  }

  void addCheckpoint() {
    if (!isPracticeMode || player.isDead || player.hasWon) return;
    checkpoints.add(
      Checkpoint(
        position: Vector2D.copy(player.position),
        velocity: Vector2D.copy(player.velocity),
        rotation: player.rotationDegrees,
        mode: player.mode,
        gravity: player.gravity,
        speed: player.speedModifier,
      ),
    );
  }

  void removeLastCheckpoint() {
    if (checkpoints.isNotEmpty) {
      checkpoints.removeLast();
    }
  }
}
