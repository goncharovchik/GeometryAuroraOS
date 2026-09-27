import 'dart:math' as math;
import 'vector2d.dart';

/// Прямоугольник ограничения (Axis-Aligned Bounding Box)
class AABB {
  double minX;
  double minY;
  double maxX;
  double maxY;

  AABB({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  AABB.fromDimensions({
    required double x,
    required double y,
    required double width,
    required double height,
  })  : minX = x,
        minY = y,
        maxX = x + width,
        maxY = y + height;

  double get width => maxX - minX;
  double get height => maxY - minY;

  bool intersects(AABB other) {
    return minX < other.maxX &&
        maxX > other.minX &&
        minY < other.maxY &&
        maxY > other.minY;
  }

  /// Проверка точки внутри прямоугольника
  bool containsPoint(Vector2D point) {
    return point.x >= minX &&
        point.x <= maxX &&
        point.y >= minY &&
        point.y <= maxY;
  }

  /// Возвращает пересекающийся прямоугольник
  AABB? intersection(AABB other) {
    if (!intersects(other)) return null;
    return AABB(
      minX: math.max(minX, other.minX),
      minY: math.max(minY, other.minY),
      maxX: math.min(maxX, other.maxX),
      maxY: math.min(maxY, other.maxY),
    );
  }

  @override
  String toString() => 'AABB($minX, $minY -> $maxX, $maxY)';
}

/// Хитбокс треугольного шипа для честной детекции смерти
class TriangleHitbox {
  final Vector2D p1;
  final Vector2D p2;
  final Vector2D p3;

  TriangleHitbox(this.p1, this.p2, this.p3);

  /// Создает уменьшенный треугольник шипа по координатам плитки и углу поворота
  factory TriangleHitbox.spike({
    required double tileX,
    required double tileY,
    required double size,
    required double inset,
    double rotationDegrees = 0.0,
  }) {
    // Базовый шип, смотрящий вверх
    // Вершина по центру сверху, основание внизу
    Vector2D top = Vector2D(tileX + size / 2.0, tileY + size - inset);
    Vector2D bLeft = Vector2D(tileX + inset, tileY + inset);
    Vector2D bRight = Vector2D(tileX + size - inset, tileY + inset);

    if (rotationDegrees == 180.0) {
      // Шип на потолке, смотрит вниз
      top = Vector2D(tileX + size / 2.0, tileY + inset);
      bLeft = Vector2D(tileX + inset, tileY + size - inset);
      bRight = Vector2D(tileX + size - inset, tileY + size - inset);
    } else if (rotationDegrees == 90.0) {
      // Смотрит вправо
      top = Vector2D(tileX + size - inset, tileY + size / 2.0);
      bLeft = Vector2D(tileX + inset, tileY + size - inset);
      bRight = Vector2D(tileX + inset, tileY + inset);
    } else if (rotationDegrees == 270.0) {
      // Смотрит влево
      top = Vector2D(tileX + inset, tileY + size / 2.0);
      bLeft = Vector2D(tileX + size - inset, tileY + inset);
      bRight = Vector2D(tileX + size - inset, tileY + size - inset);
    }

    return TriangleHitbox(top, bLeft, bRight);
  }

  /// Проверяет пересечение AABB прямоугольника игрока с треугольником
  bool intersectsAABB(AABB box) {
    // Быстрый отсев по AABB треугольника
    final triMinX = math.min(p1.x, math.min(p2.x, p3.x));
    final triMaxX = math.max(p1.x, math.max(p2.x, p3.x));
    final triMinY = math.min(p1.y, math.min(p2.y, p3.y));
    final triMaxY = math.max(p1.y, math.max(p2.y, p3.y));

    if (box.maxX < triMinX || box.minX > triMaxX || box.maxY < triMinY || box.minY > triMaxY) {
      return false;
    }

    // Проверяем, находится ли какая-либо вершина треугольника внутри коробки
    if (box.containsPoint(p1) || box.containsPoint(p2) || box.containsPoint(p3)) {
      return true;
    }

    // Проверяем 4 угла коробки внутри треугольника
    final c1 = Vector2D(box.minX, box.minY);
    final c2 = Vector2D(box.maxX, box.minY);
    final c3 = Vector2D(box.maxX, box.maxY);
    final c4 = Vector2D(box.minX, box.maxY);

    if (containsPoint(c1) || containsPoint(c2) || containsPoint(c3) || containsPoint(c4)) {
      return true;
    }

    // Проверка пересечения ребер (отрезков)
    final edgesBox = [
      (c1, c2),
      (c2, c3),
      (c3, c4),
      (c4, c1),
    ];
    final edgesTri = [
      (p1, p2),
      (p2, p3),
      (p3, p1),
    ];

    for (final e1 in edgesBox) {
      for (final e2 in edgesTri) {
        if (_linesIntersect(e1.$1, e1.$2, e2.$1, e2.$2)) {
          return true;
        }
      }
    }

    return false;
  }

  bool containsPoint(Vector2D p) {
    double sign(Vector2D p1, Vector2D p2, Vector2D p3) {
      return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
    }

    final d1 = sign(p, p1, p2);
    final d2 = sign(p, p2, p3);
    final d3 = sign(p, p3, p1);

    final hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0);
    final hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0);

    return !(hasNeg && hasPos);
  }

  static bool _linesIntersect(Vector2D a1, Vector2D a2, Vector2D b1, Vector2D b2) {
    double ccw(Vector2D A, Vector2D B, Vector2D C) {
      return (C.y - A.y) * (B.x - A.x) - (B.y - A.y) * (C.x - A.x);
    }

    return (ccw(a1, b1, b2) * ccw(a2, b1, b2) < 0) &&
        (ccw(a1, a2, b1) * ccw(a1, a2, b2) < 0);
  }
}
