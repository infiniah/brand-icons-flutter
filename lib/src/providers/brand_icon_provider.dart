import '../core/brand_icon_candidate.dart';
import '../core/brand_icon_shape.dart';
import '../core/brand_icon_source.dart';
import '../core/brand_query.dart';

/// A place icons can come from.
///
/// Providers return *candidates*, not a single answer, and never throw for "no match": an empty
/// list is a normal result. They throw only when something went wrong that the caller might act
/// on, such as being rate limited.
abstract class BrandIconProvider {
  BrandIconSource get source;

  /// Candidates for a free text service name. May be empty.
  Future<List<BrandIconCandidate>> candidates(BrandQuery query);

  /// Fetches the drawable payload for a candidate this provider produced.
  Future<BrandIconShape> shape(BrandIconCandidate candidate);
}
