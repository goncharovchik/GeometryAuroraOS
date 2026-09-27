/// Режим движения персонажа в Geometry Dash
enum PlayerMode {
  cube,
  ship,
  ball,
}

/// Направление силы гравитации
enum GravityDirection {
  down,
  up,
}

extension GravityDirectionExtension on GravityDirection {
  double get sign => this == GravityDirection.down ? 1.0 : -1.0;
  GravityDirection get inverted => this == GravityDirection.down ? GravityDirection.up : GravityDirection.down;
}

/// Множитель скорости бега
enum SpeedModifier {
  half(0.8),
  normal(1.0),
  fast2x(1.25),
  faster3x(1.55),
  fastest4x(1.95);

  final double multiplier;
  const SpeedModifier(this.multiplier);
}
