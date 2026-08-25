import 'brand_icon_shape.dart';
import 'brand_icon_source.dart';

/// One possible answer, with how sure the library is about it.
///
/// Deliberately cheap: resolving a name gives titles, slugs and confidences without downloading
/// anything. [shape] is filled in only once you ask for it.
class BrandIconCandidate {
  const BrandIconCandidate({
    required this.slug,
    required this.title,
    required this.confidence,
    required this.source,
    this.shape,
  });

  final String slug;
  final String title;
  final double confidence;
  final BrandIconSource source;
  final BrandIconShape? shape;

  String get id => '${source.id}:$slug';

  BrandIconCandidate withShape(BrandIconShape shape) => BrandIconCandidate(
        slug: slug,
        title: title,
        confidence: confidence,
        source: source,
        shape: shape,
      );

  @override
  bool operator ==(Object other) =>
      other is BrandIconCandidate &&
      other.id == id &&
      other.confidence == confidence;

  @override
  int get hashCode => Object.hash(id, confidence);
}
