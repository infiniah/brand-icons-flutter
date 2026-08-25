import 'dart:math' as math;

import 'name_normalizer.dart';

/// Scores how well a query names a brand, 0 to 1.
///
/// The number is meant to be *acted on*, so it is built from signals that can be explained rather
/// than a single fuzzy distance. In descending order of trust:
///
/// 1. the normalised keys are identical
/// 2. every brand token of one appears in the other
/// 3. tokens overlap partially
/// 4. the strings are merely close in edit distance
///
/// A tier word present on one side only applies a penalty, because `Apple Music` and `Apple TV`
/// must not collapse into `Apple`.
abstract final class MatchScorer {
  /// Score [query] against a brand's canonical [name], optionally also its [slug].
  static double score(String query, {required String name, String? slug}) {
    final queryKey = NameNormalizer.key(query);
    if (queryKey.isEmpty) return 0;

    var best = 0.0;
    for (final target in [name, if (slug != null) slug]) {
      best = math.max(best, _rawScore(queryKey, query, target));
    }
    return best.clamp(0.0, 1.0);
  }

  static double _rawScore(String queryKey, String query, String target) {
    final targetKey = NameNormalizer.key(target);
    if (targetKey.isEmpty) return 0;

    if (queryKey == targetKey) return 1.0 - _qualifierPenalty(query, target);

    final queryTokens = NameNormalizer.brandTokens(query).toSet();
    final targetTokens = NameNormalizer.brandTokens(target).toSet();

    var structural = 0.0;
    if (queryTokens.isNotEmpty && targetTokens.isNotEmpty) {
      final ratio = math.min(queryTokens.length, targetTokens.length) /
          math.max(queryTokens.length, targetTokens.length);

      if (targetTokens.every(queryTokens.contains)) {
        // The query carries extra words the brand does not, which is what a statement descriptor
        // looks like: "SPOTIFY USA" is Spotify with a region bolted on.
        structural = 0.72 + 0.18 * ratio;
      } else if (queryTokens.every(targetTokens.contains)) {
        // The brand carries extra words the query does not, so the brand is the more specific
        // thing. `Apple` is not `Apple TV`. Every sibling scores alike here, which is deliberate.
        structural = 0.42 + 0.18 * ratio;
      } else {
        final shared = queryTokens.intersection(targetTokens).length;
        if (shared > 0) {
          final union = queryTokens.union(targetTokens).length;
          structural = 0.38 + 0.3 * (shared / union);
        }
      }
    }

    // Substring containment on the joined key catches "netflixcom" against "netflix". The floor
    // and the ratio gate keep a brand named "E" from matching inside "sqbluebottle".
    if (structural == 0) {
      final shorter = math.min(queryKey.length, targetKey.length);
      final ratio = shorter / math.max(queryKey.length, targetKey.length);
      if (shorter >= 3 &&
          ratio >= 0.5 &&
          (queryKey.contains(targetKey) || targetKey.contains(queryKey))) {
        structural = 0.28 + 0.24 * ratio;
      }
    }

    final similarity = 1 - normalizedEditDistance(queryKey, targetKey);
    // Edit distance alone is a weak signal, so it can never carry a match on its own.
    final fuzzy = similarity >= 0.82 ? similarity * 0.6 : 0.0;

    return math.max(structural, fuzzy) - _qualifierPenalty(query, target);
  }

  /// Penalises a tier word present on one side only.
  static double _qualifierPenalty(String query, String target) {
    final queryQualifiers = NameNormalizer.qualifiers(query).toSet();
    final targetQualifiers = NameNormalizer.qualifiers(target).toSet();
    if (queryQualifiers.length == targetQualifiers.length &&
        queryQualifiers.containsAll(targetQualifiers)) {
      return 0;
    }
    final difference = queryQualifiers.difference(targetQualifiers).length +
        targetQualifiers.difference(queryQualifiers).length;
    return math.min(0.12, 0.06 * difference);
  }

  /// Levenshtein distance divided by the longer length, so 0 is identical and 1 is unrelated.
  static double normalizedEditDistance(String lhs, String rhs) {
    if (lhs == rhs) return 0;
    if (lhs.isEmpty || rhs.isEmpty) return 1;

    final a = lhs.codeUnits;
    final b = rhs.codeUnits;
    var previous = List<int>.generate(b.length + 1, (index) => index);
    var current = List<int>.filled(b.length + 1, 0);

    for (var i = 1; i <= a.length; i++) {
      current[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        current[j] = math.min(
          math.min(previous[j] + 1, current[j - 1] + 1),
          previous[j - 1] + cost,
        );
      }
      final swap = previous;
      previous = current;
      current = swap;
    }
    return previous[b.length] / math.max(a.length, b.length);
  }
}
