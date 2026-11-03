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

  /// Уровень 1: Stereo Aurora (Базовый режим куба, шипы, платформы, пады и монетки)
  static Level _buildStereoAurora() {
    final objects = <LevelObject>[];

    void addSpike(int gx, int gy, {double rot = 0.0}) {
      objects.add(LevelObject(
        id: 'l1_spike_${gx}_$gy',
        type: ObjectType.spike,
        gridX: gx,
        gridY: gy,
        rotationDegrees: rot,
      ));
    }

    void addBlock(int gx, int gy) {
      objects.add(LevelObject(
        id: 'l1_block_${gx}_$gy',
        type: ObjectType.solidBlock,
        gridX: gx,
        gridY: gy,
      ));
    }

    void addPad(int gx, int gy, {PadColor color = PadColor.yellow}) {
      objects.add(LevelObject(
        id: 'l1_pad_${gx}_$gy',
        type: ObjectType.jumpPad,
        gridX: gx,
        gridY: gy,
        padColor: color,
      ));
    }

    void addOrb(int gx, int gy, {OrbColor color = OrbColor.yellow}) {
      objects.add(LevelObject(
        id: 'l1_orb_${gx}_$gy',
        type: ObjectType.jumpOrb,
        gridX: gx,
        gridY: gy,
        orbColor: color,
      ));
    }

    void addCoin(int gx, int gy) {
      objects.add(LevelObject(
        id: 'l1_coin_${gx}_$gy',
        type: ObjectType.coin,
        gridX: gx,
        gridY: gy,
      ));
    }

    // Вводная часть с первой монеткой за прыжком
    addSpike(12, 0);
    addCoin(12, 3);
    addSpike(18, 0);
    addSpike(19, 0);
    addCoin(19, 3);

    // Первые ступени из блоков
    addBlock(24, 0);
    addBlock(25, 0);
    addBlock(25, 1);
    addSpike(26, 0);
    addSpike(27, 0);
    addBlock(28, 0);
    addBlock(28, 1);
    addCoin(28, 3); // Монетка на вершине блоков
    addBlock(29, 0);

    // Прыжковый пад на высокий утес
    addPad(34, 0, color: PadColor.yellow);
    addBlock(38, 2);
    addBlock(39, 2);
    addBlock(40, 2);
    addCoin(39, 4); // Секретная монетка в воздухе
    addSpike(41, 0);
    addSpike(42, 0);

    // Орб в воздухе над шипами
    addSpike(47, 0);
    addSpike(48, 0);
    addOrb(47, 2, color: OrbColor.yellow);
    addCoin(48, 3);
    addBlock(50, 0);
    addBlock(51, 0);

    // Тройной шип и супер-пад
    addSpike(58, 0);
    addSpike(59, 0);
    addSpike(60, 0);
    addPad(56, 0, color: PadColor.red);
    addCoin(59, 3); // Монетка прямо над тройным шипом

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
    addCoin(74, 4);
    addSpike(77, 0);
    addOrb(77, 2, color: OrbColor.yellow);
    addCoin(77, 4);

    addBlock(82, 0);
    addBlock(83, 0);
    addCoin(85, 2);

    // Финиш
    objects.add(LevelObject(
      id: 'l1_finish',
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

  /// Уровень 2: Orbit Flight (Полет на Корабле с монетами)
  static Level _buildOrbitFlight() {
    final objects = <LevelObject>[];

    void addCoin(int gx, int gy) {
      objects.add(LevelObject(
        id: 'l2_coin_${gx}_$gy',
        type: ObjectType.coin,
        gridX: gx,
        gridY: gy,
      ));
    }

    // Разгон на кубе
    objects.add(LevelObject(
      id: 'l2_spike_10',
      type: ObjectType.spike,
      gridX: 10,
      gridY: 0,
    ));
    addCoin(10, 2);

    // Портал входа в режим Корабля на 16 тайле
    objects.add(LevelObject(
      id: 'l2_portal_ship_1',
      type: ObjectType.portalMode,
      gridX: 16,
      gridY: 2,
      targetMode: PlayerMode.ship,
    ));

    // Коридор для полета корабля (шипы на полу и потолке)
    for (int gx = 20; gx <= 60; gx += 4) {
      objects.add(LevelObject(
        id: 'l2_ship_floor_$gx',
        type: ObjectType.spike,
        gridX: gx,
        gridY: 0,
      ));
      objects.add(LevelObject(
        id: 'l2_ship_ceil_$gx',
        type: ObjectType.hangingSpike,
        gridX: gx + 2,
        gridY: 8,
        rotationDegrees: 180.0,
      ));
    }

    // Монетки по изогнутой траектории корабля
    addCoin(24, 4);
    addCoin(30, 6);
    addCoin(36, 2);
    addCoin(44, 5);
    addCoin(52, 3);
    addCoin(58, 6);

    // Блоки-препятствия посреди тоннеля
    for (int gy = 3; gy <= 6; gy++) {
      objects.add(LevelObject(
        id: 'l2_wall_1_$gy',
        type: ObjectType.solidBlock,
        gridX: 36,
        gridY: gy,
      ));
    }
    for (int gy = 1; gy <= 4; gy++) {
      objects.add(LevelObject(
        id: 'l2_wall_2_$gy',
        type: ObjectType.solidBlock,
        gridX: 48,
        gridY: gy,
      ));
    }

    // Обратный портал в режим Куба
    objects.add(LevelObject(
      id: 'l2_portal_cube_1',
      type: ObjectType.portalMode,
      gridX: 65,
      gridY: 1,
      targetMode: PlayerMode.cube,
    ));

    // Финишные препятствия
    objects.add(LevelObject(
      id: 'l2_spike_72',
      type: ObjectType.spike,
      gridX: 72,
      gridY: 0,
    ));
    addCoin(72, 3);

    // Финиш
    objects.add(LevelObject(
      id: 'l2_finish_2',
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

  /// Уровень 3: Gravity Storm (Инверсия гравитации + Режим НЛО)
  static Level _buildGravityStorm() {
    final objects = <LevelObject>[];

    void addCoin(int gx, int gy) {
      objects.add(LevelObject(
        id: 'l3_coin_${gx}_$gy',
        type: ObjectType.coin,
        gridX: gx,
        gridY: gy,
      ));
    }

    // Разбег
    objects.add(LevelObject(id: 'l3_spike_10', type: ObjectType.spike, gridX: 10, gridY: 0));
    addCoin(10, 2);

    // Портал инверсии гравитации (полет к потолку)
    objects.add(LevelObject(
      id: 'l3_portal_grav_up',
      type: ObjectType.portalGravity,
      gridX: 18,
      gridY: 1,
      targetGravity: GravityDirection.up,
    ));

    // Блоки на потолке, по которым бежит перевернутый куб
    for (int gx = 22; gx <= 45; gx++) {
      objects.add(LevelObject(
        id: 'l3_ceiling_block_$gx',
        type: ObjectType.solidBlock,
        gridX: gx,
        gridY: 10,
      ));
    }

    addCoin(25, 8);
    // Шипы на потолке
    objects.add(LevelObject(
      id: 'l3_spike_ceil_28',
      type: ObjectType.spike,
      gridX: 28,
      gridY: 9,
      rotationDegrees: 180.0,
    ));
    addCoin(32, 8);
    objects.add(LevelObject(
      id: 'l3_spike_ceil_36',
      type: ObjectType.spike,
      gridX: 36,
      gridY: 9,
      rotationDegrees: 180.0,
    ));
    addCoin(40, 8);

    // Портал возврата гравитации на пол
    objects.add(LevelObject(
      id: 'l3_portal_grav_down',
      type: ObjectType.portalGravity,
      gridX: 46,
      gridY: 7,
      targetGravity: GravityDirection.down,
    ));

    // Портал нового режима: НЛО (UFO) на 50 тайле!
    objects.add(LevelObject(
      id: 'l3_portal_ufo',
      type: ObjectType.portalMode,
      gridX: 50,
      gridY: 2,
      targetMode: PlayerMode.ufo,
    ));

    // Препятствия и парящие монеты для НЛО
    for (int gx = 54; gx <= 70; gx += 4) {
      objects.add(LevelObject(
        id: 'l3_ufo_sp_$gx',
        type: ObjectType.spike,
        gridX: gx,
        gridY: 0,
      ));
      addCoin(gx + 1, 3);
    }

    // Возврат в режим куба
    objects.add(LevelObject(
      id: 'l3_portal_cube_end',
      type: ObjectType.portalMode,
      gridX: 74,
      gridY: 2,
      targetMode: PlayerMode.cube,
    ));

    addCoin(77, 2);

    // Финиш
    objects.add(LevelObject(
      id: 'l3_finish_3',
      type: ObjectType.finishLine,
      gridX: 84,
      gridY: 0,
    ));

    return Level(
      id: 'level_3',
      title: 'Gravity Storm',
      creator: 'Aurora Games',
      difficulty: LevelDifficulty.hard,
      songTitle: 'Polargeist',
      bpm: 150.0,
      totalTilesLength: 88,
      backgroundColor: const Color(0xFF001A26),
      groundColor: const Color(0xFF004D40),
      objects: objects,
    );
  }

  /// Уровень 4: Aurora Fusion (Куб -> Корабль -> Шар -> ВОЛНА!)
  static Level _buildAuroraFusion() {
    final objects = <LevelObject>[];

    void addCoin(int gx, int gy) {
      objects.add(LevelObject(
        id: 'l4_coin_${gx}_$gy',
        type: ObjectType.coin,
        gridX: gx,
        gridY: gy,
      ));
    }

    // Фаза 1: Куб
    objects.add(LevelObject(id: 'l4_sp_1', type: ObjectType.spike, gridX: 8, gridY: 0));
    addCoin(8, 2);
    objects.add(LevelObject(id: 'l4_bl_1', type: ObjectType.solidBlock, gridX: 12, gridY: 0));
    objects.add(LevelObject(id: 'l4_bl_2', type: ObjectType.solidBlock, gridX: 13, gridY: 0));
    objects.add(LevelObject(id: 'l4_bl_3', type: ObjectType.solidBlock, gridX: 13, gridY: 1));
    objects.add(LevelObject(id: 'l4_sp_2', type: ObjectType.spike, gridX: 14, gridY: 0));
    addCoin(13, 3);

    // Портал Корабля на gx=18
    objects.add(LevelObject(
      id: 'l4_p_ship_1',
      type: ObjectType.portalMode,
      gridX: 18,
      gridY: 2,
      targetMode: PlayerMode.ship,
    ));

    // Фаза 2: Корабль
    for (int gx = 22; gx <= 38; gx += 4) {
      objects.add(LevelObject(id: 'l4_sp_ship_f_$gx', type: ObjectType.spike, gridX: gx, gridY: 0));
      objects.add(LevelObject(id: 'l4_sp_ship_c_$gx', type: ObjectType.spike, gridX: gx + 2, gridY: 8, rotationDegrees: 180.0));
      addCoin(gx + 1, 4);
    }
    objects.add(LevelObject(id: 'l4_mid_bl_1', type: ObjectType.solidBlock, gridX: 30, gridY: 4));

    // Портал Шара на gx=42
    objects.add(LevelObject(
      id: 'l4_p_ball_1',
      type: ObjectType.portalMode,
      gridX: 42,
      gridY: 2,
      targetMode: PlayerMode.ball,
    ));

    // Фаза 3: Шар
    for (int gx = 43; gx <= 64; gx++) {
      objects.add(LevelObject(id: 'l4_ceil_bl_$gx', type: ObjectType.solidBlock, gridX: gx, gridY: 8));
    }
    objects.add(LevelObject(id: 'l4_b_sp_1', type: ObjectType.spike, gridX: 48, gridY: 0));
    addCoin(48, 4);
    objects.add(LevelObject(id: 'l4_b_sp_2', type: ObjectType.spike, gridX: 54, gridY: 7, rotationDegrees: 180.0));
    addCoin(54, 3);
    objects.add(LevelObject(id: 'l4_b_sp_3', type: ObjectType.spike, gridX: 60, gridY: 0));
    addCoin(60, 4);

    // Фаза 4: Портал ВОЛНЫ (Wave) на gx=66!
    objects.add(LevelObject(
      id: 'l4_p_wave_1',
      type: ObjectType.portalMode,
      gridX: 66,
      gridY: 3,
      targetMode: PlayerMode.wave,
    ));

    // Зигзаг-коридор для Волны с монетами
    addCoin(70, 5);
    addCoin(74, 2);
    addCoin(78, 6);
    addCoin(82, 3);

    // Обратный портал в Куб для финального спринта
    objects.add(LevelObject(
      id: 'l4_p_cube_final',
      type: ObjectType.portalMode,
      gridX: 84,
      gridY: 2,
      targetMode: PlayerMode.cube,
    ));

    objects.add(LevelObject(id: 'l4_f_pad_1', type: ObjectType.jumpPad, gridX: 86, gridY: 0, padColor: PadColor.red));
    objects.add(LevelObject(id: 'l4_f_sp_1', type: ObjectType.spike, gridX: 90, gridY: 0));
    addCoin(90, 4);

    // Финишная черта
    objects.add(LevelObject(
      id: 'l4_finish_fusion',
      type: ObjectType.finishLine,
      gridX: 96,
      gridY: 0,
    ));

    return Level(
      id: 'level_4',
      title: 'Aurora Fusion',
      creator: 'Aurora Games',
      difficulty: LevelDifficulty.insane,
      songTitle: 'Electroman Adventures',
      bpm: 152.0,
      totalTilesLength: 100,
      backgroundColor: const Color(0xFF1A0500),
      groundColor: const Color(0xFFB71C1C),
      objects: objects,
    );
  }

  /// Уровень 5: Quantum Chaos (Демон - Куб, Скорость 2x, Корабль, Шар, НЛО, Волна!)
  static Level _buildQuantumChaos() {
    final objects = <LevelObject>[];

    void addCoin(int gx, int gy) {
      objects.add(LevelObject(
        id: 'l5_coin_${gx}_$gy',
        type: ObjectType.coin,
        gridX: gx,
        gridY: gy,
      ));
    }

    // Старт на скорости 2x!
    objects.add(LevelObject(
      id: 'qc_spd_1',
      type: ObjectType.portalSpeed,
      gridX: 6,
      gridY: 1,
      targetSpeed: SpeedModifier.fast2x,
    ));

    objects.add(LevelObject(id: 'qc_sp_1', type: ObjectType.spike, gridX: 12, gridY: 0));
    addCoin(12, 3);
    objects.add(LevelObject(id: 'qc_pad_1', type: ObjectType.jumpPad, gridX: 16, gridY: 0, padColor: PadColor.yellow));
    objects.add(LevelObject(id: 'qc_bl_1', type: ObjectType.solidBlock, gridX: 19, gridY: 2));
    addCoin(19, 4);
    objects.add(LevelObject(id: 'qc_sp_2', type: ObjectType.spike, gridX: 23, gridY: 0));

    // Инвертированный Корабль!
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

    for (int gx = 34; gx <= 50; gx += 4) {
      objects.add(LevelObject(id: 'qc_sp_inv_f_$gx', type: ObjectType.spike, gridX: gx, gridY: 0));
      objects.add(LevelObject(id: 'qc_sp_inv_c_$gx', type: ObjectType.spike, gridX: gx + 2, gridY: 8, rotationDegrees: 180.0));
      addCoin(gx + 1, 4);
    }

    // НЛО на скорости 2x!
    objects.add(LevelObject(
      id: 'qc_ufo_p',
      type: ObjectType.portalMode,
      gridX: 54,
      gridY: 4,
      targetMode: PlayerMode.ufo,
    ));

    addCoin(58, 5);
    addCoin(62, 3);
    addCoin(66, 6);

    // Волна сквозь квантовые ворота!
    objects.add(LevelObject(
      id: 'qc_wave_p',
      type: ObjectType.portalMode,
      gridX: 70,
      gridY: 4,
      targetMode: PlayerMode.wave,
    ));

    addCoin(74, 4);
    addCoin(78, 6);
    addCoin(82, 2);

    // Финальный безумный Куб с нормальной гравитацией
    objects.add(LevelObject(
      id: 'qc_cube_final',
      type: ObjectType.portalMode,
      gridX: 86,
      gridY: 2,
      targetMode: PlayerMode.cube,
    ));
    objects.add(LevelObject(
      id: 'qc_grav_normal',
      type: ObjectType.portalGravity,
      gridX: 87,
      gridY: 2,
      targetGravity: GravityDirection.down,
    ));

    // Каскад орбов и супер-падов к финишу
    objects.add(LevelObject(id: 'qc_sp_f1', type: ObjectType.spike, gridX: 92, gridY: 0));
    objects.add(LevelObject(id: 'qc_orb_f1', type: ObjectType.jumpOrb, gridX: 92, gridY: 2, orbColor: OrbColor.red));
    addCoin(92, 4);
    objects.add(LevelObject(id: 'qc_sp_f2', type: ObjectType.spike, gridX: 97, gridY: 0));
    objects.add(LevelObject(id: 'qc_sp_f3', type: ObjectType.spike, gridX: 98, gridY: 0));
    objects.add(LevelObject(id: 'qc_pad_f1', type: ObjectType.jumpPad, gridX: 102, gridY: 0, padColor: PadColor.red));
    addCoin(102, 5);
    objects.add(LevelObject(id: 'qc_sp_f4', type: ObjectType.spike, gridX: 106, gridY: 0));
    objects.add(LevelObject(id: 'qc_sp_f5', type: ObjectType.spike, gridX: 107, gridY: 0));

    // Финишные врата Демона!
    objects.add(LevelObject(
      id: 'finish_demon',
      type: ObjectType.finishLine,
      gridX: 114,
      gridY: 0,
    ));

    return Level(
      id: 'level_5',
      title: 'Quantum Chaos',
      creator: 'Aurora Games',
      difficulty: LevelDifficulty.demon,
      songTitle: 'Clubstep',
      bpm: 160.0,
      totalTilesLength: 118,
      backgroundColor: const Color(0xFF0D001A),
      groundColor: const Color(0xFF4A148C),
      objects: objects,
    );
  }
}
