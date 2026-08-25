import 'brand_color.dart';

/// One filled path of a multi colour mark.
///
/// A monochrome mark is one path and one tint. A brand whose identity is colour is not: Figma is
/// five shapes in five colours. Those marks arrive as an ordered list of these, painted back to
/// front.
class VectorLayer {
  const VectorLayer({required this.path, this.fill, this.isEvenOdd = false});

  /// SVG path data, in the coordinate space of the shape's viewBox.
  final String path;

  /// The layer's own fill. Null means the artwork left it unset, which SVG paints black.
  final BrandColor? fill;

  /// Whether the layer fills by the even odd rule rather than the non zero winding default.
  ///
  /// A mark that punches holes with `fill-rule="evenodd"` fills them in if drawn by winding.
  final bool isEvenOdd;
}
