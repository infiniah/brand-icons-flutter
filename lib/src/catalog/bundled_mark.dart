import '../core/brand_color.dart';
import '../core/vector_layer.dart';

/// One mark as it appears in the compiled catalogue.
class BundledMark {
  const BundledMark({
    required this.slug,
    required this.title,
    required this.path,
    required this.viewBox,
    required this.tint,
    this.layers = const [],
    this.colorViewBox,
    this.license,
  });

  /// Stable identifier, lowercase.
  final String slug;

  /// Display name as the brand writes it.
  final String title;

  /// SVG path data, the `d` attribute, in the coordinate space of [viewBox].
  final String path;

  /// `[minX, minY, width, height]`.
  final List<double> viewBox;

  /// The brand's own colour.
  final BrandColor? tint;

  /// The brand's real artwork, when a multi colour rendition exists for it.
  ///
  /// Empty for most marks. When present it is what should be drawn, because [path] is the
  /// flattened silhouette of the same brand.
  final List<VectorLayer> layers;

  /// The coordinate space [layers] are drawn in, which is not [viewBox].
  final List<double>? colorViewBox;

  /// Present only for marks whose terms are not the set default.
  final BundledMarkLicense? license;
}

/// The terms a mark is offered under, when they are not the catalogue default.
class BundledMarkLicense {
  const BundledMarkLicense(this.type, [this.url]);

  final String type;
  final String? url;

  /// True when the terms forbid commercial use or derivative works.
  bool get isRestrictive =>
      type.toUpperCase().contains('NC') ||
      type.toUpperCase().contains('ND') ||
      type.toUpperCase().contains('AGPL');
}
