import 'dart:math' as math;

import 'elliptical_arc.dart';
import 'path_segment.dart';
import 'svg_path_command.dart';
import 'svg_path_scanner.dart';

/// Turns SVG path data into drawable segments.
///
/// The whole command set is supported: absolute and relative forms, commands whose letter is given
/// once and whose operands repeat, elliptical arcs, and the smooth curve forms `S` and `T`.
///
/// The result is in the source coordinate space, where y grows downwards, which is what a canvas
/// expects, so no flip is applied.
abstract final class SVGPathParser {
  /// The segments drawn by [pathData], or null when it is empty, malformed, or draws nothing.
  ///
  /// Parsing is strict: unreadable data returns null rather than a partial shape, because half an
  /// icon is worse than none. Malformed input never throws.
  static List<PathSegment>? parse(String pathData) {
    final scanner = SVGPathScanner(pathData);
    final segments = <PathSegment>[];

    var currentX = 0.0;
    var currentY = 0.0;
    var subpathStartX = 0.0;
    var subpathStartY = 0.0;
    double? cubicControlX;
    double? cubicControlY;
    double? quadraticControlX;
    double? quadraticControlY;
    SVGPathCommand? lastCommand;
    var isSubpathOpen = false;

    while (true) {
      final unit = scanner.nextCommandUnit();
      SVGPathCommand command;
      if (unit != null) {
        command = SVGPathCommand.from(unit)!;
      } else if (scanner.isAtEnd) {
        break;
      } else if (lastCommand?.repeated != null && scanner.hasNumber) {
        command = lastCommand!.repeated!;
      } else {
        return null;
      }

      if (lastCommand == null && command.kind != SVGCommandKind.move) return null;

      double absoluteX(double x) => command.isRelative ? currentX + x : x;
      double absoluteY(double y) => command.isRelative ? currentY + y : y;

      void openSubpath() {
        if (isSubpathOpen) return;
        segments.add(MoveToSegment(currentX, currentY));
        isSubpathOpen = true;
      }

      switch (command.kind) {
        case SVGCommandKind.move:
          final x = scanner.nextNumber();
          final y = scanner.nextNumber();
          if (x == null || y == null) return null;
          currentX = absoluteX(x);
          currentY = absoluteY(y);
          subpathStartX = currentX;
          subpathStartY = currentY;
          segments.add(MoveToSegment(currentX, currentY));
          isSubpathOpen = true;
          cubicControlX = cubicControlY = null;
          quadraticControlX = quadraticControlY = null;

        case SVGCommandKind.close:
          if (isSubpathOpen) {
            segments.add(const CloseSegment());
            isSubpathOpen = false;
          }
          currentX = subpathStartX;
          currentY = subpathStartY;
          cubicControlX = cubicControlY = null;
          quadraticControlX = quadraticControlY = null;

        case SVGCommandKind.line:
          final x = scanner.nextNumber();
          final y = scanner.nextNumber();
          if (x == null || y == null) return null;
          openSubpath();
          currentX = absoluteX(x);
          currentY = absoluteY(y);
          segments.add(LineToSegment(currentX, currentY));
          cubicControlX = cubicControlY = null;
          quadraticControlX = quadraticControlY = null;

        case SVGCommandKind.horizontalLine:
          final x = scanner.nextNumber();
          if (x == null) return null;
          openSubpath();
          currentX = command.isRelative ? currentX + x : x;
          segments.add(LineToSegment(currentX, currentY));
          cubicControlX = cubicControlY = null;
          quadraticControlX = quadraticControlY = null;

        case SVGCommandKind.verticalLine:
          final y = scanner.nextNumber();
          if (y == null) return null;
          openSubpath();
          currentY = command.isRelative ? currentY + y : y;
          segments.add(LineToSegment(currentX, currentY));
          cubicControlX = cubicControlY = null;
          quadraticControlX = quadraticControlY = null;

        case SVGCommandKind.cubic:
          final x1 = scanner.nextNumber();
          final y1 = scanner.nextNumber();
          final x2 = scanner.nextNumber();
          final y2 = scanner.nextNumber();
          final x = scanner.nextNumber();
          final y = scanner.nextNumber();
          if (x1 == null || y1 == null || x2 == null || y2 == null || x == null || y == null) {
            return null;
          }
          openSubpath();
          final c1x = absoluteX(x1);
          final c1y = absoluteY(y1);
          final c2x = absoluteX(x2);
          final c2y = absoluteY(y2);
          currentX = absoluteX(x);
          currentY = absoluteY(y);
          segments.add(CubicToSegment(c1x, c1y, c2x, c2y, currentX, currentY));
          cubicControlX = c2x;
          cubicControlY = c2y;
          quadraticControlX = quadraticControlY = null;

        case SVGCommandKind.smoothCubic:
          final x2 = scanner.nextNumber();
          final y2 = scanner.nextNumber();
          final x = scanner.nextNumber();
          final y = scanner.nextNumber();
          if (x2 == null || y2 == null || x == null || y == null) return null;
          openSubpath();
          final c1x = _reflect(cubicControlX, currentX);
          final c1y = _reflect(cubicControlY, currentY);
          final c2x = absoluteX(x2);
          final c2y = absoluteY(y2);
          currentX = absoluteX(x);
          currentY = absoluteY(y);
          segments.add(CubicToSegment(c1x, c1y, c2x, c2y, currentX, currentY));
          cubicControlX = c2x;
          cubicControlY = c2y;
          quadraticControlX = quadraticControlY = null;

        case SVGCommandKind.quadratic:
          final x1 = scanner.nextNumber();
          final y1 = scanner.nextNumber();
          final x = scanner.nextNumber();
          final y = scanner.nextNumber();
          if (x1 == null || y1 == null || x == null || y == null) return null;
          openSubpath();
          final cx = absoluteX(x1);
          final cy = absoluteY(y1);
          currentX = absoluteX(x);
          currentY = absoluteY(y);
          segments.add(QuadToSegment(cx, cy, currentX, currentY));
          quadraticControlX = cx;
          quadraticControlY = cy;
          cubicControlX = cubicControlY = null;

        case SVGCommandKind.smoothQuadratic:
          final x = scanner.nextNumber();
          final y = scanner.nextNumber();
          if (x == null || y == null) return null;
          openSubpath();
          final cx = _reflect(quadraticControlX, currentX);
          final cy = _reflect(quadraticControlY, currentY);
          currentX = absoluteX(x);
          currentY = absoluteY(y);
          segments.add(QuadToSegment(cx, cy, currentX, currentY));
          quadraticControlX = cx;
          quadraticControlY = cy;
          cubicControlX = cubicControlY = null;

        case SVGCommandKind.arc:
          final rx = scanner.nextNumber();
          final ry = scanner.nextNumber();
          final degrees = scanner.nextNumber();
          final largeArc = scanner.nextFlag();
          final sweep = scanner.nextFlag();
          final x = scanner.nextNumber();
          final y = scanner.nextNumber();
          if (rx == null || ry == null || degrees == null || largeArc == null ||
              sweep == null || x == null || y == null) {
            return null;
          }
          openSubpath();
          final endX = absoluteX(x);
          final endY = absoluteY(y);
          final arc = EllipticalArc(
            startX: currentX,
            startY: currentY,
            endX: endX,
            endY: endY,
            radiusX: rx,
            radiusY: ry,
            rotation: degrees * math.pi / 180,
            isLargeArc: largeArc,
            isSweep: sweep,
          ).segments();

          if (arc.isEmpty) {
            if (currentX != endX || currentY != endY) {
              segments.add(LineToSegment(endX, endY));
            }
          } else {
            for (final piece in arc) {
              segments.add(
                CubicToSegment(piece.c1x, piece.c1y, piece.c2x, piece.c2y, piece.endX, piece.endY),
              );
            }
          }
          currentX = endX;
          currentY = endY;
          cubicControlX = cubicControlY = null;
          quadraticControlX = quadraticControlY = null;
      }

      lastCommand = command;
    }

    // A lone move draws nothing, so a path that is only moves is as empty as no path at all.
    final drawsSomething = segments.any((segment) => segment is! MoveToSegment);
    return drawsSomething ? segments : null;
  }

  /// The previous control point mirrored through the current point.
  ///
  /// With no previous curve the specification says the control point coincides with the current
  /// point, which makes a lone `S` behave like a plain cubic.
  static double _reflect(double? control, double point) =>
      control == null ? point : 2 * point - control;
}
