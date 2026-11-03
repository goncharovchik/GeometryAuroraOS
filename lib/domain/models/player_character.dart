import 'package:flutter/material.dart';

enum CharacterStyle {
  classic,
  phantom,
  vortex,
  graviton,
  magnetron,
  titan,
}

/// Модель кастомного игрового персонажа с уникальными пассивными свойствами
class PlayerCharacter {
  final String id;
  final String name;
  final String title;
  final String description;
  final int cost; // Стоимость в очках, собранных на карте
  final Color defaultColor1;
  final Color defaultColor2;
  final IconData icon;
  final CharacterStyle style;
  final String perkDescription;

  // Модификаторы физики персонажа
  final double bonusCoyoteTime;
  final double bonusThrust;
  final double bonusJumpForce;
  final double bonusMagnetRadius;
  final double hitboxScale;
  final bool hasBuiltinShield;

  const PlayerCharacter({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.cost,
    required this.defaultColor1,
    required this.defaultColor2,
    required this.icon,
    required this.style,
    required this.perkDescription,
    this.bonusCoyoteTime = 0.0,
    this.bonusThrust = 0.0,
    this.bonusJumpForce = 0.0,
    this.bonusMagnetRadius = 0.0,
    this.hitboxScale = 1.0,
    this.hasBuiltinShield = false,
  });

  static const List<PlayerCharacter> characters = [
    PlayerCharacter(
      id: 'neon_cube',
      name: 'Неон-Куб',
      title: 'Классический бегун',
      description: 'Сбалансированный и надежный куб с чистой неоновой геометрией.',
      cost: 0,
      defaultColor1: Color(0xFF00FF66),
      defaultColor2: Color(0xFFFFFF00),
      icon: Icons.crop_square_rounded,
      style: CharacterStyle.classic,
      perkDescription: 'Баланс: Стандартные параметры управления',
    ),
    PlayerCharacter(
      id: 'phantom',
      name: 'Фантом',
      title: 'Кибер-ниндзя',
      description: 'Фазовый шиноби с повышенной реакцией и узким полем столкновений.',
      cost: 100,
      defaultColor1: Color(0xFF9900FF),
      defaultColor2: Color(0xFF00FFFF),
      icon: Icons.masks_rounded,
      style: CharacterStyle.phantom,
      bonusCoyoteTime: 0.05,
      hitboxScale: 0.90, // На 10% меньший хитбокс!
      perkDescription: 'Увеличенное окно койота (+50%) и компактный хитбокс (-10%)',
    ),
    PlayerCharacter(
      id: 'turbo_vortex',
      name: 'Турбо-Вортекс',
      title: 'Аэродинамический ас',
      description: 'Реактивный спидстер с мощными импульсными стабилизаторами.',
      cost: 250,
      defaultColor1: Color(0xFFFF9900),
      defaultColor2: Color(0xFFFF0055),
      icon: Icons.rocket_launch_rounded,
      style: CharacterStyle.vortex,
      bonusThrust: 0.22,
      bonusJumpForce: 0.05,
      perkDescription: 'Турбо-тяга: +22% к скорости подъема корабля, волны и НЛО',
    ),
    PlayerCharacter(
      id: 'graviton',
      name: 'Гравитон',
      title: 'Повелитель сингулярности',
      description: 'Управляет квантовым полем тяготения с квантовым ядром в центре.',
      cost: 400,
      defaultColor1: Color(0xFF00E5FF),
      defaultColor2: Color(0xFFFFFFFF),
      icon: Icons.all_inclusive_rounded,
      style: CharacterStyle.graviton,
      bonusJumpForce: 0.10,
      perkDescription: 'Антигравитация: +10% к силе прыжка и сферам, мягкое приземление',
    ),
    PlayerCharacter(
      id: 'magnetron',
      name: 'Магнетрон',
      title: 'Техно-собиратель',
      description: 'Оснащен магнитными катушками Тесла для притяжения очков на расстоянии.',
      cost: 600,
      defaultColor1: Color(0xFFFFD700),
      defaultColor2: Color(0xFF00FFCC),
      icon: Icons.offline_bolt_rounded,
      style: CharacterStyle.magnetron,
      bonusMagnetRadius: 90.0,
      perkDescription: 'Магнитное поле: притягивает монетки и очки в радиусе +90px',
    ),
    PlayerCharacter(
      id: 'cyber_titan',
      name: 'Кибер-Титан',
      title: 'Бронированный джаггернаут',
      description: 'Сверхпрочный титановый корпус с автономным энергетическим щитом.',
      cost: 850,
      defaultColor1: Color(0xFFFF0033),
      defaultColor2: Color(0xFFFFD700),
      icon: Icons.shield_rounded,
      style: CharacterStyle.titan,
      hasBuiltinShield: true,
      perkDescription: 'Энергощит: Спасает от 1 смертельного столкновения за попытку!',
    ),
  ];

  static PlayerCharacter getById(String id) {
    return characters.firstWhere(
      (c) => c.id == id,
      orElse: () => characters.first,
    );
  }
}

