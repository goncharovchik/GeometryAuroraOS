import 'dart:math' as math;

/// Легковесный 2D вектор для детерминированных вычислений физики
class Vector2D {
  double x;
  double y;

  Vector2D(this.x, this.y);

  Vector2D.zero() : x = 0.0, y = 0.0;

  Vector2D.copy(Vector2D other) : x = other.x, y = other.y;

  Vector2D operator +(Vector2D other) => Vector2D(x + other.x, y + other.y);

  Vector2D operator -(Vector2D other) => Vector2D(x - other.x, y - other.y);

  Vector2D operator *(double scalar) => Vector2D(x * scalar, y * scalar);

  Vector2D operator /(double scalar) => Vector2D(x / scalar, y / scalar);

  void set(double newX, double newY) {
    x = newX;
    y = newY;
  }

  void add(Vector2D other) {
    x += other.x;
    y += other.y;
  }

  void addScaled(Vector2D other, double scale) {
    x += other.x * scale;
    y += other.y * scale;
  }

  double get lengthSquared => x * x + y * y;

  double get length => math.sqrt(lengthSquared);

  Vector2D normalized() {
    final len = length;
    if (len == 0.0) return Vector2D.zero();
    return Vector2D(x / len, y / len);
  }

  @override
  String toString() => 'Vector2D(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';
}
