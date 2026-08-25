import 'dart:math' as math;

/// One SVG elliptical arc, converted to the cubic Béziers a path can draw.
///
/// The endpoint parameters an `A` command carries are turned into a centre, a start angle and a
/// sweep, following the SVG 1.1 implementation notes (section F.6). Out of range radii are
/// corrected the way the specification requires rather than rejected.
class EllipticalArc {
  const EllipticalArc({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.radiusX,
    required this.radiusY,
    required this.rotation,
    required this.isLargeArc,
    required this.isSweep,
  });

  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double radiusX;
  final double radiusY;
  final double rotation;
  final bool isLargeArc;
  final bool isSweep;

  /// The arc as cubic segments.
  ///
  /// Empty when the arc degenerates: identical endpoints draw nothing, and a zero radius is a
  /// straight line, which the caller draws instead.
  List<ArcSegment> segments() {
    var rx = radiusX.abs();
    var ry = radiusY.abs();
    if (rx <= 0 || ry <= 0) return const [];
    if (startX == endX && startY == endY) return const [];

    final cosPhi = math.cos(rotation);
    final sinPhi = math.sin(rotation);

    final dx = (startX - endX) / 2;
    final dy = (startY - endY) / 2;
    final x1 = cosPhi * dx + sinPhi * dy;
    final y1 = -sinPhi * dx + cosPhi * dy;

    final lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry);
    if (lambda > 1) {
      final correction = math.sqrt(lambda);
      rx *= correction;
      ry *= correction;
    }

    final denominator = rx * rx * y1 * y1 + ry * ry * x1 * x1;
    if (denominator <= 0) return const [];
    final numerator = math.max(0.0, rx * rx * ry * ry - denominator);
    final coefficient =
        (isLargeArc == isSweep ? -1.0 : 1.0) * math.sqrt(numerator / denominator);

    final cx1 = coefficient * rx * y1 / ry;
    final cy1 = -coefficient * ry * x1 / rx;
    final centerX = cosPhi * cx1 - sinPhi * cy1 + (startX + endX) / 2;
    final centerY = sinPhi * cx1 + cosPhi * cy1 + (startY + endY) / 2;

    final unitStartX = (x1 - cx1) / rx;
    final unitStartY = (y1 - cy1) / ry;
    final unitEndX = (-x1 - cx1) / rx;
    final unitEndY = (-y1 - cy1) / ry;

    final startAngle = _angle(1, 0, unitStartX, unitStartY);
    var sweep = _angle(unitStartX, unitStartY, unitEndX, unitEndY);
    if (!isSweep && sweep > 0) {
      sweep -= 2 * math.pi;
    } else if (isSweep && sweep < 0) {
      sweep += 2 * math.pi;
    }

    // The epsilon decides the split by the geometry rather than by the rounding: a 90 degree arc
    // divides to 1.0000000000000002 as often as to 0.999999999999999.
    final count = math.max(1, (sweep.abs() / (math.pi / 2) - 1e-9).ceil());
    final step = sweep / count;
    final controlScale = 4.0 / 3.0 * math.tan(step / 4);

    double placedX(double x, double y) => cosPhi * (x * rx) - sinPhi * (y * ry) + centerX;
    double placedY(double x, double y) => sinPhi * (x * rx) + cosPhi * (y * ry) + centerY;

    return List.generate(count, (index) {
      final from = startAngle + index * step;
      final to = from + step;
      final unitFromX = math.cos(from);
      final unitFromY = math.sin(from);
      final unitToX = math.cos(to);
      final unitToY = math.sin(to);

      final c1x = unitFromX - controlScale * math.sin(from);
      final c1y = unitFromY + controlScale * math.cos(from);
      final c2x = unitToX + controlScale * math.sin(to);
      final c2y = unitToY - controlScale * math.cos(to);

      return ArcSegment(
        placedX(c1x, c1y),
        placedY(c1x, c1y),
        placedX(c2x, c2y),
        placedY(c2x, c2y),
        index == count - 1 ? endX : placedX(unitToX, unitToY),
        index == count - 1 ? endY : placedY(unitToX, unitToY),
      );
    });
  }

  static double _angle(double ax, double ay, double bx, double by) {
    final dot = ax * bx + ay * by;
    final magnitude = math.sqrt((ax * ax + ay * ay) * (bx * bx + by * by));
    if (magnitude <= 0) return 0;
    final sign = (ax * by - ay * bx) < 0 ? -1.0 : 1.0;
    return sign * math.acos((dot / magnitude).clamp(-1.0, 1.0));
  }
}

class ArcSegment {
  const ArcSegment(this.c1x, this.c1y, this.c2x, this.c2y, this.endX, this.endY);
  final double c1x;
  final double c1y;
  final double c2x;
  final double c2y;
  final double endX;
  final double endY;
}
