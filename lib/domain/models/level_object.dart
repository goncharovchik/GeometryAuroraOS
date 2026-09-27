import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';
import '../../core/math/hitbox.dart';
import 'player_mode.dart';

enum ObjectType {
  solidBlock,
  spike,
  hangingSpike,
  jumpPad,
  jumpOrb,
  portalMode,
  portalGravity,
  portalSpeed,
  coin,
  finishLine,
}

enum PadColor {
  yellow,
  pink,
  red,
}

enum OrbColor {
  yellow,
  pink,
  red,
}

/// Базовый объект на сетке уровня
class LevelObject {
  final String id;
  final ObjectType type;
  final int gridX;
  final int gridY;
  final double rotationDegrees;
  
  // Дополнительные параметры в зависимости от типа
  final PadColor padColor;
  final OrbColor orbColor;
  final PlayerMode targetMode;
  final GravityDirection targetGravity;
  final SpeedModifier targetSpeed;
  final Color? customColor;

  LevelObject({
    required this.id,
    required this.type,
    required this.gridX,
    required this.gridY,
    this.rotationDegrees = 0.0,
    this.padColor = PadColor.yellow,
    this.orbColor = OrbColor.yellow,
    this.targetMode = PlayerMode.cube,
    this.targetGravity = GravityDirection.down,
    this.targetSpeed = SpeedModifier.normal,
    this.customColor,
  });

  double get pixelX => gridX * GameConstants.tileSize;
  double get pixelY => gridY * GameConstants.tileSize;
  double get width => GameConstants.tileSize;
  double get height => GameConstants.tileSize;

  AABB get aabb => AABB.fromDimensions(
        x: pixelX,
        y: pixelY,
        width: width,
        height: height,
      );

  TriangleHitbox get spikeHitbox => TriangleHitbox.spike(
        tileX: pixelX,
        tileY: pixelY,
        size: GameConstants.tileSize,
        inset: GameConstants.spikeHitboxInset,
        rotationDegrees: rotationDegrees,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'gridX': gridX,
        'gridY': gridY,
        'rotation': rotationDegrees,
        'padColor': padColor.name,
        'orbColor': orbColor.name,
        'targetMode': targetMode.name,
        'targetGravity': targetGravity.name,
        'targetSpeed': targetSpeed.name,
      };

  factory LevelObject.fromJson(Map<String, dynamic> json) {
    return LevelObject(
      id: json['id'] as String,
      type: ObjectType.values.byName(json['type'] as String),
      gridX: json['gridX'] as int,
      gridY: json['gridY'] as int,
      rotationDegrees: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      padColor: PadColor.values.byName(json['padColor'] as String? ?? 'yellow'),
      orbColor: OrbColor.values.byName(json['orbColor'] as String? ?? 'yellow'),
      targetMode: PlayerMode.values.byName(json['targetMode'] as String? ?? 'cube'),
      targetGravity: GravityDirection.values.byName(json['targetGravity'] as String? ?? 'down'),
      targetSpeed: SpeedModifier.values.byName(json['targetSpeed'] as String? ?? 'normal'),
    );
  }
}
