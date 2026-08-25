import 'dart:typed_data';

import 'brand_color.dart';
import 'vector_layer.dart';

/// Resolved artwork, as either a vector to draw or bytes to decode.
sealed class BrandIconShape {
  const BrandIconShape();

  bool get isVector => this is VectorShape || this is LayeredVectorShape;
}

/// A single filled path in its own coordinate space.
class VectorShape extends BrandIconShape {
  const VectorShape({
    required this.path,
    required this.viewBoxWidth,
    required this.viewBoxHeight,
    this.tint,
  });

  final String path;
  final double viewBoxWidth;
  final double viewBoxHeight;
  final BrandColor? tint;
}

/// Several filled paths in one coordinate space, painted in order.
class LayeredVectorShape extends BrandIconShape {
  const LayeredVectorShape({
    required this.layers,
    required this.viewBoxWidth,
    required this.viewBoxHeight,
  });

  final List<VectorLayer> layers;
  final double viewBoxWidth;
  final double viewBoxHeight;

  /// True when the mark carries the brand's real colours rather than one flat tint.
  bool get isMultiColor =>
      layers.map((layer) => layer.fill?.argb).whereType<int>().toSet().length > 1;
}

/// Encoded image bytes, PNG or JPEG, as served.
class RasterShape extends BrandIconShape {
  const RasterShape(this.data);

  final Uint8List data;
}
