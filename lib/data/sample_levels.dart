import 'package:flutter/material.dart';
import '../domain/models/level.dart';
import '../domain/models/level_object.dart';
import '../domain/models/player_mode.dart';

class SampleLevels {
  static List<Level> getLevels() {
    return [
      _buildStereoAurora(),
      _buildOrbitFlight(),
      _buildGravityStorm(),
      _buildAuroraFusion(),
      _buildQuantumChaos(),
    ];
  }

  /// Уровень 1: Stereo Aurora (Базовый режим куба, шипы, платформы, пады)
  static Level _buildStereoAurora() {
    final objects = <LevelObject>[];

    void addSpike(int gx, int gy, {double rot = 0.0}) {
      objects.add(LevelObject(
        id: 'spike_${gx}_$gy',
        type: ObjectType.spike,
        gridX: gx,
        gridY: gy,
        rotationDegrees: rot,
      ));
    }

    void addBlock(int gx, int gy) {
      objects.add(LevelObject(
        id: 'block_${gx}_$gy',
        type: ObjectType.solidBlock,
        gridX: gx,
        gridY: gy,
      ));
    }

    void addPad(int gx, int gy, {PadColor color = PadColor.yellow}) {
      objects.add(LevelObject(
        id: 'pad_${gx}_$gy',
        type: ObjectType.jumpPad,
        gridX: gx,
        gridY: gy,
        padColor: color,
      ));
    }

    void addOrb(int gx, int gy, {OrbColor color = OrbColor.yellow}) {
      objects.add(LevelObject(
        id: 'orb_${gx}_$gy',
        type: ObjectType.jumpOrb,
        gridX: gx,
        gridY: gy,
        orbColor: color,
      ));
    }

    // Вводная часть
    addSpike(12, 0);
    addSpike(18, 0);
    addSpike(19, 0);

    // Первые ступени из блоков
    addBlock(24, 0);
    addBlock(25, 0);
    addBlock(25, 1);
    addSpike(26, 0);
    addSpike(27, 0);
    addBlock(28, 0);
    addBlock(28, 1);
    addBlock(29, 0);

    // Прыжковый пад на высокий утес
    addPad(34, 0, color: PadColor.yellow);
    addBlock(38, 2);
    addBlock(39, 2);
    addBlock(40, 2);
    addSpike(41, 0);
    addSpike(42, 0);

    // Орб в воздухе над шипами
    addSpike(47, 0);
    addSpike(48, 0);
    addOrb(47, 2, color: OrbColor.yellow);
    addBlock(50, 0);
    addBlock(51, 0);

    // Тройной шип
    addSpike(58, 0);
    addSpike(59, 0);
    addSpike(60, 0);
    addPad(56, 0, color: PadColor.red); // Красный супер-пад перебрасывает тройной шип!

    addBlock(64, 0);
    addBlock(65, 0);
    addBlock(65, 1);
    addBlock(66, 1);
    addBlock(67, 1);
    addBlock(67, 2);
    addBlock(68, 2);

    // Череда орбов
    addSpike(74, 0);
    addOrb(74, 2, color: OrbColor.pink);
    addSpike(77, 0);
    addOrb(77, 2, color: OrbColor.yellow);

    addBlock(82, 0);
    addBlock(83, 0);

    // Финиш
    objects.add(LevelObject(
      id: 'finish',
      type: ObjectType.finishLine,
      gridX: 90,
      gridY: 0,
    ));

    return Level(
      id: 'level_1',
      title: 'Stereo Aurora',
      creator: 'Open Mobile Platform',
      difficulty: LevelDifficulty.easy,
      songTitle: 'Stereo Madness (Remix)',
      bpm: 130.0,
      totalTilesLength: 95,
      backgroundColor: const Color(0xFF0F0C29),
      groundColor: const Color(0xFF1B1464),
      objects: objects,
    );
  }

  /// Уровень 2: Orbit Flight (Полет на Корабле)
  static Level _buildOrbitFlight() {
    final objects = <LevelObject>[];

    // Разгон на кубе
    objects.add(LevelObject(
      id: 'spike_10',
      type: ObjectType.spike,
      gridX: 10,
      gridY: 0,
    ));

    // Портал входа в режим Корабля на 16 тайле
    objects.add(LevelObject(
      id: 'portal_ship_1',
      type: ObjectType.portalMode,
      gridX: 16,
      gridY: 2,
      targetMode: PlayerMode.ship,
    ));

    // Коридор для полета корабля (шипы на полу и потолке)
    for (int gx = 20; gx <= 60; gx += 4) {
      // Шипы на полу
      objects.add(LevelObject(
        id: 'ship_floor_$gx',
        type: ObjectType.spike,
        gridX: gx,
        gridY: 0,
      ));
      // Нависающие шипы на потолке
      objects.add(LevelObject(
        id: 'ship_ceil_$gx',
        type: ObjectType.hangingSpike,
        gridX: gx + 2,
        gridY: 8,
        rotationDegrees: 180.0,
      ));
    }

    // Блоки-препятствия посреди тоннеля
    for (int gy = 3; gy <= 6; gy++) {
      objects.add(LevelObject(
        id: 'wall_1_$gy',
        type: ObjectType.solidBlock,
        gridX: 36,
        gridY: gy,
      ));
    }
    for (int gy = 1; gy <= 4; gy++) {
      objects.add(LevelObject(
        id: 'wall_2_$gy',
        type: ObjectType.solidBlock,
        gridX: 48,
        gridY: gy,
      ));
    }

    // Обратный портал в режим Куба
    objects.add(LevelObject(
      id: 'portal_cube_1',
      type: ObjectType.portalMode,
      gridX: 65,
      gridY: 1,
      targetMode: PlayerMode.cube,
    ));

    // Финишные шипы
    objects.add(LevelObject(
      id: 'spike_72',
      type: ObjectType.spike,
      gridX: 72,
      gridY: 0,
    ));

    // Финиш
    objects.add(LevelObject(
      id: 'finish_2',
      type: ObjectType.finishLine,
      gridX: 85,
      gridY: 0,
    ));

    return Level(
      id: 'level_2',
      title: 'Orbit Flight',
      creator: 'Aurora Games',
      difficulty: LevelDifficulty.normal,
      songTitle: 'Back On Track',
      bpm: 140.0,
      totalTilesLength: 90,
      backgroundColor: const Color(0xFF16002B),
      groundColor: const Color(0xFF38006B),
      objects: objects,
    );
  }

  /// Уровень 3: Gravity Storm (Инверсия гравитации и сферы)
  static Level _buildGravityStorm() {
    final objects = <LevelObject>[];

    // Разбег
    objects.add(LevelObject(
      id: 'spike_10',
      type: ObjectType.spike,
      gridX: 10,
      gridY: 0,
    ));

    // Портал инверсии гравитации (полет к потолку)
    objects.add(LevelObject(
      id: 'portal_grav_up',
      type: ObjectType.portalGravity,
      gridX: 18,
      gridY: 1,
      targetGravity: GravityDirection.up,
    ));

    // Блоки на потолке, по которым бежит перевернутый куб
    for (int gx = 22; gx <= 45; gx++) {
      objects.add(LevelObject(
        id: 'ceiling_block_$gx',
        type: ObjectType.solidBlock,
        gridX: gx,
        gridY: 10,
      ));
    }

    // Шипы на потолке
    objects.add(LevelObject(
      id: 'spike_ceil_28',
      type: ObjectType.spike,
      gridX: 28,
      gridY: 9,
      rotationDegrees: 180.0,
    ));
    objects.add(LevelObject(
      id: 'spike_ceil_36',
      type: ObjectType.spike,
      gridX: 36,
      gridY: 9,
      rotationDegrees: 180.0,
    ));

    // Портал возврата гравитации на пол
    objects.add(LevelObject(
      id: 'portal_grav_down',
      type: ObjectType.portalGravity,
      gridX: 46,
      gridY: 7,
      targetGravity: GravityDirection.down,
    ));

    // Скоростной портал 2x
    objects.add(LevelObject(
      id: 'portal_speed_2x',
      type: ObjectType.portalSpeed,
      gridX: 52,
      gridY: 1,
      targetSpeed: SpeedModifier.fast2x,
    ));

    // Быстрые шипы
    objects.add(LevelObject(
      id: 'fast_spike_60',
      type: ObjectType.spike,
      gridX: 60,
      gridY: 0,
    ));
    objects.add(LevelObject(
      id: 'fast_spike_66',
      type: ObjectType.spike,
      gridX: 66,
      gridY: 0,
    ));
    objects.add(LevelObject(
      id: 'fast_orb_66',
      type: ObjectType.jumpOrb,
      gridX: 66,
      gridY: 2,
      orbColor: OrbColor.yellow,
    ));

    // Финиш
    objects.add(LevelObject(
      id: 'finish_3',
      type: ObjectType.finishLine,
      gridX: 80,
      gridY: 0,
    ));

    return Level(
      id: 'level_3',
      title: 'Gravity Storm',
      creator: 'Aurora Games',
      difficulty: LevelDifficulty.hard,
      songTitle: 'Polargeist',
      bpm: 150.0,
      totalTilesLength: 85,
      backgroundColor: const Color(0xFF001A26),
      groundColor: const Color(0xFF004D40),
      objects: objects,
    );
  }

  /// Уровень 4: Aurora Fusion (Комбинированный: Куб -> Корабль -> Шар -> Финал)
  static Level _buildAuroraFusion() {
    final objects = <LevelObject>[];

    // Фаза 1: Куб (0..20)
    objects.add(LevelObject(id: 'sp_1', type: ObjectType.spike, gridX: 8, gridY: 0));
    objects.add(LevelObject(id: 'bl_1', type: ObjectType.solidBlock, gridX: 12, gridY: 0));
    objects.add(LevelObject(id: 'bl_2', type: ObjectType.solidBlock, gridX: 13, gridY: 0));
    objects.add(LevelObject(id: 'bl_3', type: ObjectType.solidBlock, gridX: 13, gridY: 1));
    objects.add(LevelObject(id: 'sp_2', type: ObjectType.spike, gridX: 14, gridY: 0));

    // Портал Корабля на gx=18
    objects.add(LevelObject(
      id: 'p_ship_1',
      type: ObjectType.portalMode,
      gridX: 18,
      gridY: 2,
      targetMode: PlayerMode.ship,
    ));

    // Фаза 2: Корабль в туннеле (20..42)
    for (int gx = 22; gx <= 40; gx += 4) {
      objects.add(LevelObject(id: 'sp_ship_f_$gx', type: ObjectType.spike, gridX: gx, gridY: 0));
      objects.add(LevelObject(id: 'sp_ship_c_$gx', type: ObjectType.spike, gridX: gx + 2, gridY: 8, rotationDegrees: 180.0));
    }
    objects.add(LevelObject(id: 'mid_bl_1', type: ObjectType.solidBlock, gridX: 30, gridY: 4));

    // Портал Шара на gx=44
    objects.add(LevelObject(
      id: 'p_ball_1',
      type: ObjectType.portalMode,
      gridX: 44,
      gridY: 2,
      targetMode: PlayerMode.ball,
    ));

    // Фаза 3: Шар (45..68) - переключение гравитации
    for (int gx = 45; gx <= 68; gx++) {
      objects.add(LevelObject(id: 'ceil_bl_$gx', type: ObjectType.solidBlock, gridX: gx, gridY: 8));
    }
    objects.add(LevelObject(id: 'b_sp_1', type: ObjectType.spike, gridX: 50, gridY: 0));
    objects.add(LevelObject(id: 'b_sp_2', type: ObjectType.spike, gridX: 56, gridY: 7, rotationDegrees: 180.0));
    objects.add(LevelObject(id: 'b_sp_3', type: ObjectType.spike, gridX: 62, gridY: 0));

    // Фаза 4: Портал Куба + Скорость 2x (gx=70)
    objects.add(LevelObject(
      id: 'p_cube_2',
      type: ObjectType.portalMode,
      gridX: 70,
      gridY: 2,
      targetMode: PlayerMode.cube,
    ));
    objects.add(LevelObject(
      id: 'p_spd_2',
      type: ObjectType.portalSpeed,
      gridX: 72,
      gridY: 2,
      targetSpeed: SpeedModifier.fast2x,
    ));

    // Финальный спринт
    objects.add(LevelObject(id: 'f_pad_1', type: ObjectType.jumpPad, gridX: 76, gridY: 0, padColor: PadColor.red));
    objects.add(LevelObject(id: 'f_sp_1', type: ObjectType.spike, gridX: 80, gridY: 0));
    objects.add(LevelObject(id: 'f_sp_2', type: ObjectType.spike, gridX: 81, gridY: 0));
    objects.add(LevelObject(id: 'f_orb_1', type: ObjectType.jumpOrb, gridX: 84, gridY: 2, orbColor: OrbColor.yellow));
    objects.add(LevelObject(id: 'f_sp_3', type: ObjectType.spike, gridX: 84, gridY: 0));

    // Финишная черта
    objects.add(LevelObject(
      id: 'finish_fusion',
      type: ObjectType.finishLine,
      gridX: 92,
      gridY: 0,
    ));

    return Level(
      id: 'level_4',
      title: 'Aurora Fusion',
      creator: 'Aurora Games',
      difficulty: LevelDifficulty.insane,
      songTitle: 'Electroman Adventures',
      bpm: 152.0,
      totalTilesLength: 96,
      backgroundColor: const Color(0xFF1A0500),
      groundColor: const Color(0xFFB71C1C),
      objects: objects,
    );
  }

  /// Уровень 5: Quantum Chaos (Демон - Ультра-комбинированный: Скорость 2x, Инверсия, Все режимы)
  static Level _buildQuantumChaos() {
    final objects = <LevelObject>[];

    // Старт на скорости 2x!
    objects.add(LevelObject(
      id: 'qc_spd_1',
      type: ObjectType.portalSpeed,
      gridX: 6,
      gridY: 1,
      targetSpeed: SpeedModifier.fast2x,
    ));

    objects.add(LevelObject(id: 'qc_sp_1', type: ObjectType.spike, gridX: 12, gridY: 0));
    objects.add(LevelObject(id: 'qc_pad_1', type: ObjectType.jumpPad, gridX: 16, gridY: 0, padColor: PadColor.yellow));
    objects.add(LevelObject(id: 'qc_bl_1', type: ObjectType.solidBlock, gridX: 19, gridY: 2));
    objects.add(LevelObject(id: 'qc_sp_2', type: ObjectType.spike, gridX: 23, gridY: 0));

    // Инвертированный Корабль! (портал корабля + портал гравитации вверх)
    objects.add(LevelObject(
      id: 'qc_ship_p',
      type: ObjectType.portalMode,
      gridX: 28,
      gridY: 2,
      targetMode: PlayerMode.ship,
    ));
    objects.add(LevelObject(
      id: 'qc_grav_up',
      type: ObjectType.portalGravity,
      gridX: 30,
      gridY: 2,
      targetGravity: GravityDirection.up,
    ));

    // Препятствия для инвертированного корабля
    for (int gx = 34; gx <= 54; gx += 4) {
      objects.add(LevelObject(id: 'qc_sp_inv_f_$gx', type: ObjectType.spike, gridX: gx, gridY: 0));
      objects.add(LevelObject(id: 'qc_sp_inv_c_$gx', type: ObjectType.spike, gridX: gx + 2, gridY: 8, rotationDegrees: 180.0));
    }

    // Инвертированный Шар
    objects.add(LevelObject(
      id: 'qc_ball_p',
      type: ObjectType.portalMode,
      gridX: 58,
      gridY: 6,
      targetMode: PlayerMode.ball,
    ));

    for (int gx = 58; gx <= 78; gx++) {
      objects.add(LevelObject(id: 'qc_ceil_$gx', type: ObjectType.solidBlock, gridX: gx, gridY: 8));
    }
    objects.add(LevelObject(id: 'qc_bsp_1', type: ObjectType.spike, gridX: 64, gridY: 7, rotationDegrees: 180.0));
    objects.add(LevelObject(id: 'qc_bsp_2', type: ObjectType.spike, gridX: 70, gridY: 0));

    // Финальный безумный Куб с нормальной гравитацией
    objects.add(LevelObject(
      id: 'qc_cube_final',
      type: ObjectType.portalMode,
      gridX: 80,
      gridY: 2,
      targetMode: PlayerMode.cube,
    ));
    objects.add(LevelObject(
      id: 'qc_grav_normal',
      type: ObjectType.portalGravity,
      gridX: 81,
      gridY: 2,
      targetGravity: GravityDirection.down,
    ));

    // Каскад орбов и супер-падов к финишу
    objects.add(LevelObject(id: 'qc_sp_f1', type: ObjectType.spike, gridX: 86, gridY: 0));
    objects.add(LevelObject(id: 'qc_orb_f1', type: ObjectType.jumpOrb, gridX: 86, gridY: 2, orbColor: OrbColor.red));
    objects.add(LevelObject(id: 'qc_sp_f2', type: ObjectType.spike, gridX: 91, gridY: 0));
    objects.add(LevelObject(id: 'qc_sp_f3', type: ObjectType.spike, gridX: 92, gridY: 0));
    objects.add(LevelObject(id: 'qc_pad_f1', type: ObjectType.jumpPad, gridX: 96, gridY: 0, padColor: PadColor.red));
    objects.add(LevelObject(id: 'qc_sp_f4', type: ObjectType.spike, gridX: 100, gridY: 0));
    objects.add(LevelObject(id: 'qc_sp_f5', type: ObjectType.spike, gridX: 101, gridY: 0));
    objects.add(LevelObject(id: 'qc_sp_f6', type: ObjectType.spike, gridX: 102, gridY: 0));

    // Финишные врата Демона!
    objects.add(LevelObject(
      id: 'finish_demon',
      type: ObjectType.finishLine,
      gridX: 108,
      gridY: 0,
    ));

    return Level(
      id: 'level_5',
      title: 'Quantum Chaos',
      creator: 'Aurora Games',
      difficulty: LevelDifficulty.demon,
      songTitle: 'Clubstep',
      bpm: 160.0,
      totalTilesLength: 112,
      backgroundColor: const Color(0xFF0D001A),
      groundColor: const Color(0xFF4A148C),
      objects: objects,
    );
  }
}

