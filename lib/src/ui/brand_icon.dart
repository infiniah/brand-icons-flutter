import 'package:flutter/material.dart';

import '../core/brand_color.dart';
import '../core/brand_icon_candidate.dart';
import '../core/brand_icon_shape.dart';
import '../vector/path_segment.dart';
import '../vector/svg_path_parser.dart';

/// Draws a resolved candidate.
///
/// A vector is parsed and filled directly, so it stays sharp at any size. Raster artwork is
/// decoded and drawn as it arrived. A candidate with no shape falls back to a monogram rather than
/// a blank square, because an empty box in a list reads as a bug where a letter reads as
/// "not found".
///
/// A mark too close in tone to the surface behind it gets a contrasting tile, so a near black mark
/// such as GitHub's stays visible in dark mode.
class BrandIcon extends StatelessWidget {
  const BrandIcon({
    super.key,
    required this.candidate,
    this.size = 40,
    this.fallbackText,
    this.cornerRadius,
    this.surface,
  });

  final BrandIconCandidate? candidate;
  final double size;
  final String? fallbackText;
  final double? cornerRadius;
  final Color? surface;

  /// What SVG paints a path with no `fill` attribute.
  static const BrandColor unsetFill = BrandColor(0x1C, 0x1C, 0x1E);
  static const int unsetFillArgb = 0xFF1C1C1E;
  static const _contrastThreshold = 0.22;

  @override
  Widget build(BuildContext context) {
    final radius = cornerRadius ?? size * 0.28;
    final ground = surface ?? Theme.of(context).colorScheme.surface;
    final shape = candidate?.shape;

    final colors = _markColors(shape);
    // Not `Color.computeLuminance`: that gamma decodes, and the marks report the plain sRGB
    // weighting every other port uses. Mixing the two shifts the threshold by a factor of ten
    // and a mark keeps its tile on one platform and loses it on another.
    final groundLuminance = BrandColor(
      (ground.r * 255).round(),
      (ground.g * 255).round(),
      (ground.b * 255).round(),
    ).relativeLuminance;
    final needsTile = colors.isNotEmpty &&
        colors.every((color) =>
            ((color.relativeLuminance) - groundLuminance).abs() < _contrastThreshold);
    final inset = needsTile ? size * 0.18 : 0.0;

    Widget content;
    switch (shape) {
      case VectorShape():
      case LayeredVectorShape():
        content = SizedBox(
          width: size - inset * 2,
          height: size - inset * 2,
          child: CustomPaint(painter: _MarkPainter(shape!)),
        );
      case RasterShape(:final data):
        content = Image.memory(data, width: size, height: size, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _monogram(radius));
      case null:
        content = _monogram(radius);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: needsTile
            ? (colors.every((c) => c.relativeLuminance < 0.5)
                ? const Color(0xFFF2F2F0)
                : const Color(0xFF1C1C1E))
            : null,
        alignment: Alignment.center,
        child: content,
      ),
    );
  }

  Widget _monogram(double radius) {
    final label = (fallbackText ?? candidate?.title ?? '').trim();
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFE8E8ED),
      alignment: Alignment.center,
      child: Text(
        label.isEmpty ? '?' : label.characters.first.toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6C6C76),
        ),
      ),
    );
  }

  static List<BrandColor> _markColors(BrandIconShape? shape) => switch (shape) {
        VectorShape(:final tint) => tint == null ? const [] : [tint],
        // An unfilled layer is painted [unsetFill], so it counts towards the decision. Dropping
        // it leaves a mark whose layers carry no fill reporting no colours at all, and a black
        // mark then lands untiled on a black surface.
        LayeredVectorShape(:final layers) =>
          layers.map((layer) => layer.fill ?? unsetFill).toList(),
        _ => const [],
      };
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.shape);

  final BrandIconShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    switch (shape) {
      case VectorShape(:final path, :final viewBoxWidth, :final viewBoxHeight, :final tint):
        final segments = SVGPathParser.parse(path);
        if (segments == null) return;
        canvas.drawPath(
          _build(segments, viewBoxWidth, viewBoxHeight, size, false),
          Paint()..color = Color(tint?.argb ?? BrandIcon.unsetFillArgb),
        );
      case LayeredVectorShape(:final layers, :final viewBoxWidth, :final viewBoxHeight):
        for (final layer in layers) {
          final segments = SVGPathParser.parse(layer.path);
          if (segments == null) continue;
          canvas.drawPath(
            _build(segments, viewBoxWidth, viewBoxHeight, size, layer.isEvenOdd),
            Paint()..color = Color(layer.fill?.argb ?? BrandIcon.unsetFillArgb),
          );
        }
      case _:
        return;
    }
  }

  /// One factor for both axes, so a non square viewBox is letterboxed rather than stretched.
  Path _build(
    List<PathSegment> segments,
    double viewBoxWidth,
    double viewBoxHeight,
    Size size,
    bool isEvenOdd,
  ) {
    final path = Path()..fillType = isEvenOdd ? PathFillType.evenOdd : PathFillType.nonZero;
    final scale = size.shortestSide / (viewBoxWidth > viewBoxHeight ? viewBoxWidth : viewBoxHeight);
    final offsetX = (size.width - viewBoxWidth * scale) / 2;
    final offsetY = (size.height - viewBoxHeight * scale) / 2;

    double sx(double value) => value * scale + offsetX;
    double sy(double value) => value * scale + offsetY;

    for (final segment in segments) {
      if (segment is MoveToSegment) {
        path.moveTo(sx(segment.x), sy(segment.y));
      } else if (segment is LineToSegment) {
        path.lineTo(sx(segment.x), sy(segment.y));
      } else if (segment is CubicToSegment) {
        path.cubicTo(
          sx(segment.c1x), sy(segment.c1y),
          sx(segment.c2x), sy(segment.c2y),
          sx(segment.x), sy(segment.y),
        );
      } else if (segment is QuadToSegment) {
        path.quadraticBezierTo(sx(segment.cx), sy(segment.cy), sx(segment.x), sy(segment.y));
      } else if (segment is CloseSegment) {
        path.close();
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => oldDelegate.shape != shape;
}
