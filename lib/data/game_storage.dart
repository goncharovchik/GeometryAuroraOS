import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/game_constants.dart';
import '../domain/models/player_character.dart';
import '../domain/models/upgrade.dart';

/// Сервис сохранения прогресса игрока: очки, разблокированные персонажи и прокачки
class GameStorage extends ChangeNotifier {
  static final GameStorage _instance = GameStorage._internal();
  static GameStorage get instance => _instance;

  int _totalPoints = 0;
  String _selectedCharacterId = 'neon_cube';
  final Set<String> _unlockedCharacters = {'neon_cube'};
  final Map<String, int> _upgradeLevels = {};
  bool _flipLandscape = false;
  
  Color _playerColor1 = GameConstants.defaultPlayerColor1;
  Color _playerColor2 = GameConstants.defaultPlayerColor2;

  final Map<String, double> _levelBestPercent = {};
  final Map<String, int> _levelCoinsCollected = {};

  bool _isLoaded = false;

  GameStorage._internal();

  int get totalPoints => _totalPoints;
  String get selectedCharacterId => _selectedCharacterId;
  PlayerCharacter get selectedCharacter => PlayerCharacter.getById(_selectedCharacterId);
  Set<String> get unlockedCharacters => Set.unmodifiable(_unlockedCharacters);
  Map<String, int> get upgradeLevels => Map.unmodifiable(_upgradeLevels);

  bool get flipLandscape => _flipLandscape;
  void toggleFlipLandscape() {
    _flipLandscape = !_flipLandscape;
    notifyListeners();
    save();
  }

  Color get playerColor1 => _playerColor1;
  Color get playerColor2 => _playerColor2;

  void setColors(Color c1, Color c2) {
    _playerColor1 = c1;
    _playerColor2 = c2;
    notifyListeners();
    save();
  }

  void setColor1(Color c) {
    _playerColor1 = c;
    notifyListeners();
    save();
  }

  void setColor2(Color c) {
    _playerColor2 = c;
    notifyListeners();
    save();
  }

  bool isCharacterUnlocked(String id) => _unlockedCharacters.contains(id);

  int getUpgradeLevel(String upgradeId) => _upgradeLevels[upgradeId] ?? 0;

  double getBestPercent(String levelId) => _levelBestPercent[levelId] ?? 0.0;
  void recordBestPercent(String levelId, double percent) {
    final current = getBestPercent(levelId);
    if (percent > current) {
      _levelBestPercent[levelId] = percent;
      save();
      notifyListeners();
    }
  }

  int getCoinsCollected(String levelId) => _levelCoinsCollected[levelId] ?? 0;
  void recordCoinsCollected(String levelId, int count) {
    final current = getCoinsCollected(levelId);
    if (count > current) {
      _levelCoinsCollected[levelId] = count;
      save();
      notifyListeners();
    }
  }

  /// Добавление очков (монет), собранных на карте
  void addPoints(int amount) {
    if (amount <= 0) return;
    _totalPoints += amount;
    notifyListeners();
    save();
  }

  /// Покупка персонажа за очки
  bool unlockCharacter(String id) {
    if (isCharacterUnlocked(id)) return true;
    final char = PlayerCharacter.getById(id);
    if (_totalPoints >= char.cost) {
      _totalPoints -= char.cost;
      _unlockedCharacters.add(id);
      _selectedCharacterId = id;
      _playerColor1 = char.defaultColor1;
      _playerColor2 = char.defaultColor2;
      notifyListeners();
      save();
      return true;
    }
    return false;
  }

  /// Выбор активного персонажа
  void selectCharacter(String id) {
    if (isCharacterUnlocked(id)) {
      _selectedCharacterId = id;
      final char = PlayerCharacter.getById(id);
      _playerColor1 = char.defaultColor1;
      _playerColor2 = char.defaultColor2;
      notifyListeners();
      save();
    }
  }

  /// Прокачка способности за очки
  bool upgradeSkill(String upgradeId) {
    final upgrade = Upgrade.getById(upgradeId);
    final currentLevel = getUpgradeLevel(upgradeId);
    if (currentLevel >= upgrade.maxLevel) return false;

    final cost = upgrade.getCost(currentLevel);
    if (_totalPoints >= cost) {
      _totalPoints -= cost;
      _upgradeLevels[upgradeId] = currentLevel + 1;
      notifyListeners();
      save();
      return true;
    }
    return false;
  }

  // --- Вычисление итоговых физических бонусов для игрока ---

  double get effectiveMagnetRadius {
    final charBonus = selectedCharacter.bonusMagnetRadius;
    final upgradeBonus = getUpgradeLevel('magnet') * 25.0;
    return GameConstants.baseMagnetRadius + charBonus + upgradeBonus;
  }

  double get effectiveCoyoteDuration {
    final charBonus = selectedCharacter.bonusCoyoteTime;
    final upgradeBonus = getUpgradeLevel('agility') * 0.025;
    return GameConstants.coyoteDuration + charBonus + upgradeBonus;
  }

  double get effectiveJumpBufferDuration {
    final upgradeBonus = getUpgradeLevel('agility') * 0.025;
    return GameConstants.jumpBufferDuration + upgradeBonus;
  }

  double get effectiveThrustMultiplier {
    final charBonus = selectedCharacter.bonusThrust;
    final upgradeBonus = getUpgradeLevel('thrust') * 0.06;
    return 1.0 + charBonus + upgradeBonus;
  }

  double get effectiveJumpForceMultiplier {
    final charBonus = selectedCharacter.bonusJumpForce;
    return 1.0 + charBonus;
  }

  double get effectiveScoreMultiplier {
    final upgradeBonus = getUpgradeLevel('multiplier') * 0.25;
    return 1.0 + upgradeBonus;
  }

  int get maxShieldCharges {
    int charges = selectedCharacter.hasBuiltinShield ? 1 : 0;
    final shieldLvl = getUpgradeLevel('shield');
    if (shieldLvl >= 3) {
      charges += 2;
    } else if (shieldLvl >= 1) {
      charges += 1;
    }
    return charges;
  }

  double get effectiveHitboxScale => selectedCharacter.hitboxScale;

  // --- Файловое хранилище (JSON) ---

  File _getSaveFile() {
    String basePath = '.';
    try {
      if (Platform.isWindows) {
        basePath = Platform.environment['LOCALAPPDATA'] ??
            Platform.environment['APPDATA'] ??
            '.';
      } else if (Platform.isLinux || Platform.operatingSystem.contains('aurora')) {
        basePath = Platform.environment['XDG_DATA_HOME'] ??
            (Platform.environment['HOME'] != null
                ? '${Platform.environment['HOME']}/.local/share'
                : '.');
      }
    } catch (_) {
      basePath = '.';
    }

    final dir = Directory('$basePath/ru.aurora.geometry_dash_aurora');
    if (!dir.existsSync()) {
      try {
        dir.createSync(recursive: true);
      } catch (_) {}
    }
    return File('${dir.path}/game_save.json');
  }

  Future<void> save() async {
    try {
      final file = _getSaveFile();
      final data = {
        'totalPoints': _totalPoints,
        'selectedCharacterId': _selectedCharacterId,
        'unlockedCharacters': _unlockedCharacters.toList(),
        'upgradeLevels': _upgradeLevels,
        'playerColor1': _playerColor1.value,
        'playerColor2': _playerColor2.value,
        'levelBestPercent': _levelBestPercent,
        'levelCoinsCollected': _levelCoinsCollected,
        'flipLandscape': _flipLandscape,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      // Игнорируем ошибки записи в изолированных средах
    }
  }

  void load() {
    if (_isLoaded) return;
    _isLoaded = true;
    try {
      final file = _getSaveFile();
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final Map<String, dynamic> data = jsonDecode(content);

        _totalPoints = data['totalPoints'] as int? ?? 0;
        _flipLandscape = data['flipLandscape'] as bool? ?? false;
        _selectedCharacterId = data['selectedCharacterId'] as String? ?? 'neon_cube';

        if (data['unlockedCharacters'] is List) {
          _unlockedCharacters.clear();
          _unlockedCharacters.addAll(
            (data['unlockedCharacters'] as List).map((e) => e.toString()),
          );
          _unlockedCharacters.add('neon_cube');
        }

        if (data['upgradeLevels'] is Map) {
          _upgradeLevels.clear();
          (data['upgradeLevels'] as Map).forEach((k, v) {
            _upgradeLevels[k.toString()] = (v as num).toInt();
          });
        }

        if (data['playerColor1'] is int) {
          _playerColor1 = Color(data['playerColor1'] as int);
        }
        if (data['playerColor2'] is int) {
          _playerColor2 = Color(data['playerColor2'] as int);
        }

        if (data['levelBestPercent'] is Map) {
          (data['levelBestPercent'] as Map).forEach((k, v) {
            _levelBestPercent[k.toString()] = (v as num).toDouble();
          });
        }
        if (data['levelCoinsCollected'] is Map) {
          (data['levelCoinsCollected'] as Map).forEach((k, v) {
            _levelCoinsCollected[k.toString()] = (v as num).toInt();
          });
        }
      }
    } catch (_) {
      // Fallback к начальным значениям
    }
  }
}

