import '../catalog/brand_catalog.dart';
import '../catalog/bundled_mark.dart';
import '../core/brand_icon_candidate.dart';
import '../core/brand_icon_error.dart';
import '../core/brand_icon_shape.dart';
import '../core/brand_icon_source.dart';
import '../core/brand_query.dart';
import '../matching/match_scorer.dart';
import 'brand_icon_provider.dart';

/// The marks compiled into the library.
///
/// Costs no network and cannot be rate limited, so the resolver asks it first and often never asks
/// anything else. Everything clearing a low floor is returned rather than only the winner, because
/// the caller may want to show a chooser when two brands score alike.
class BundledIconProvider implements BrandIconProvider {
  BundledIconProvider(this.catalog);

  final BrandCatalog catalog;

  /// Below this a mark is noise rather than a weak answer.
  static const double floor = 0.3;

  @override
  BrandIconSource get source => BrandIconSource.bundled;

  @override
  Future<List<BrandIconCandidate>> candidates(BrandQuery query) async {
    // An exact key match cannot be beaten, so scoring the rest of the catalogue to discover that
    // is wasted work on every common name.
    final exact = catalog.index.exactMatches(query.name);
    if (exact.isNotEmpty) {
      return exact.map((mark) => _candidate(mark, 1.0)).toList();
    }

    final scored = catalog.index
        .shortlist(query.name)
        .map((mark) => _candidate(
              mark,
              MatchScorer.score(query.name, name: mark.title, slug: mark.slug),
            ))
        .where((candidate) => candidate.confidence > floor)
        .toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return scored;
  }

  @override
  Future<BrandIconShape> shape(BrandIconCandidate candidate) async {
    if (candidate.shape != null) return candidate.shape!;
    final mark = catalog.mark(candidate.slug);
    if (mark == null) throw const NotFoundError();
    return shapeFor(mark);
  }

  BrandIconCandidate _candidate(BundledMark mark, double confidence) => BrandIconCandidate(
        slug: mark.slug,
        title: mark.title,
        confidence: confidence,
        source: source,
        shape: shapeFor(mark),
      );

  /// The colour artwork when the brand has it, and the flattened mark otherwise.
  static BrandIconShape shapeFor(BundledMark mark) {
    final box = mark.colorViewBox;
    if (mark.layers.isNotEmpty && box != null) {
      return LayeredVectorShape(
        layers: mark.layers,
        viewBoxWidth: box[2],
        viewBoxHeight: box[3],
      );
    }
    return VectorShape(
      path: mark.path,
      viewBoxWidth: mark.viewBox[2],
      viewBoxHeight: mark.viewBox[3],
      tint: mark.tint,
    );
  }
}
