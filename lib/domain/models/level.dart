import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';
import 'level_object.dart';

enum LevelDifficulty {
  easy('Easy', Colors.blue, 1),
  normal('Normal', Colors.green, 2),
  hard('Hard', Colors.orange, 3),
  harder('Harder', Colors.deepOrange, 4),
  insane('Insane', Colors.red, 5),
  demon('Demon', Colors.purple, 10);

  final String label;
  final Color color;
  final int stars;
  const LevelDifficulty(this.label, this.color, this.stars);
}

/// Модель уровня Geometry Dash
class Level {
  final String id;
  final String title;
  final String creator;
  final LevelDifficulty difficulty;
  final String songTitle;
  final double bpm;
  final int totalTilesLength;
  final Color backgroundColor;
  final Color groundColor;
  final List<LevelObject> objects;

  Level({
    required this.id,
    required this.title,
    required this.creator,
    required this.difficulty,
    required this.songTitle,
    required this.bpm,
    required this.totalTilesLength,
    this.backgroundColor = GameConstants.defaultBgColor,
    this.groundColor = GameConstants.defaultGroundColor,
    required this.objects,
  });

  double get lengthInPixels => totalTilesLength * GameConstants.tileSize;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'creator': creator,
        'difficulty': difficulty.name,
        'songTitle': songTitle,
        'bpm': bpm,
        'totalTilesLength': totalTilesLength,
        'backgroundColor': backgroundColor.value,
        'groundColor': groundColor.value,
        'objects': objects.map((o) => o.toJson()).toList(),
      };

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'] as String,
      title: json['title'] as String,
      creator: json['creator'] as String,
      difficulty: LevelDifficulty.values.byName(json['difficulty'] as String),
      songTitle: json['songTitle'] as String,
      bpm: (json['bpm'] as num).toDouble(),
      totalTilesLength: json['totalTilesLength'] as int,
      backgroundColor: Color(json['backgroundColor'] as int? ?? GameConstants.defaultBgColor.value),
      groundColor: Color(json['groundColor'] as int? ?? GameConstants.defaultGroundColor.value),
      objects: (json['objects'] as List<dynamic>)
          .map((o) => LevelObject.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}
