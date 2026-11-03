import 'package:flutter/material.dart';

enum UpgradeType {
  magnet,
  agility,
  thrust,
  multiplier,
  shield,
}

/// Модель ветки прокачки за очки, собранные на картах
class Upgrade {
  final UpgradeType type;
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final int maxLevel;
  final int baseCost;
  final double costGrowthFactor;

  const Upgrade({
    required this.type,
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.maxLevel = 5,
    required this.baseCost,
    this.costGrowthFactor = 1.6,
  });

  /// Стоимость прокачки на следующий уровень (0 -> 1, 1 -> 2, ...)
  int getCost(int currentLevel) {
    if (currentLevel >= maxLevel) return 0;
    return (baseCost * (1.0 + currentLevel * costGrowthFactor)).round();
  }

  /// Текстовое описание эффекта на заданном уровне
  String getLevelEffectDescription(int level) {
    switch (type) {
      case UpgradeType.magnet:
        final r = level * 25;
        return level == 0 ? 'Радиус притяжения: стандарт' : 'Радиус магнита: +$r px';
      case UpgradeType.agility:
        final ms = (level * 25);
        return level == 0 ? 'Буфер ввода: стандарт' : 'Окно буферизации: +$ms мс';
      case UpgradeType.thrust:
        final pct = (level * 6);
        return level == 0 ? 'Тяга двигателей: 100%' : 'Тяга корабля, волны и НЛО: +$pct%';
      case UpgradeType.multiplier:
        final mult = 1.0 + level * 0.25;
        return 'Множитель очков: ${mult.toStringAsFixed(2)}x';
      case UpgradeType.shield:
        if (level == 0) return 'Энергощит не активен';
        if (level == 1) return '1 спасение от крушения за уровень';
        if (level == 2) return '1 спасение + импульсный отскок';
        return '2 спасения от крушения за уровень!';
    }
  }

  static const List<Upgrade> allUpgrades = [
    Upgrade(
      type: UpgradeType.magnet,
      id: 'magnet',
      name: 'Магнит очков',
      description: 'Автоматически притягивает парящие монетки и очки с карты.',
      icon: Icons.track_changes_rounded,
      baseCost: 40,
      maxLevel: 5,
    ),
    Upgrade(
      type: UpgradeType.agility,
      id: 'agility',
      name: 'Буфер прыжка',
      description: 'Расширяет окно предварительного нажатия и время койота на краях.',
      icon: Icons.touch_app_rounded,
      baseCost: 35,
      maxLevel: 5,
    ),
    Upgrade(
      type: UpgradeType.thrust,
      id: 'thrust',
      name: 'Турбо-Маневренность',
      description: 'Увеличивает тягу и скорость отклика в режимах Корабля, Волны и НЛО.',
      icon: Icons.speed_rounded,
      baseCost: 50,
      maxLevel: 5,
    ),
    Upgrade(
      type: UpgradeType.multiplier,
      id: 'multiplier',
      name: 'Множитель очков',
      description: 'Увеличивает количество очков, получаемых за каждую собранную монетку.',
      icon: Icons.auto_awesome_rounded,
      baseCost: 60,
      maxLevel: 5,
    ),
    Upgrade(
      type: UpgradeType.shield,
      id: 'shield',
      name: 'Энергетический Щит',
      description: 'Поглощает смертельное столкновение и позволяет продолжить забег.',
      icon: Icons.shield_outlined,
      baseCost: 120,
      maxLevel: 3,
      costGrowthFactor: 2.2,
    ),
  ];

  static Upgrade getById(String id) {
    return allUpgrades.firstWhere(
      (u) => u.id == id,
      orElse: () => allUpgrades.first,
    );
  }
}

