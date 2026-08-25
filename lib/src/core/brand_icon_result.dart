import 'brand_icon_candidate.dart';
import 'brand_icon_source.dart';

/// Everything the resolver found for one query, best first.
class BrandIconResult {
  BrandIconResult._(this.query, this.candidates);

  final String query;

  /// Candidates ranked by preferred source, then descending confidence. May be empty.
  final List<BrandIconCandidate> candidates;

  /// Ranks [candidates] and wraps them.
  ///
  /// Sources in [preferring] come first in the order given, but only once they reach
  /// [preferenceThreshold]. A preferred source that is unsure about the brand sorts on its score
  /// like anything else, so a favicon scraped off a guessed domain cannot displace a certain
  /// catalogue match.
  factory BrandIconResult.ranked(
    String query,
    List<BrandIconCandidate> candidates, {
    List<BrandIconSource> preferring = const [],
    double preferenceThreshold = 0.8,
  }) {
    int rank(BrandIconCandidate candidate) {
      if (candidate.confidence < preferenceThreshold) return preferring.length;
      final index = preferring.indexOf(candidate.source);
      return index >= 0 ? index : preferring.length;
    }

    final sorted = [...candidates]..sort((a, b) {
        final left = rank(a);
        final right = rank(b);
        if (left != right) return left.compareTo(right);
        return b.confidence.compareTo(a.confidence);
      });
    return BrandIconResult._(query, sorted);
  }

  factory BrandIconResult.empty(String query) => BrandIconResult._(query, const []);

  /// The single best candidate, if one clears [minimum].
  ///
  /// Pick a threshold from what a wrong answer costs. A dashboard that can show a letter tile is
  /// happy at 0.5. A flow that writes the choice to a database should ask below roughly 0.8.
  BrandIconCandidate? best({double minimum = 0.5}) {
    if (candidates.isEmpty) return null;
    final first = candidates.first;
    return first.confidence >= minimum ? first : null;
  }

  /// True when the top two are close enough that picking silently is a guess.
  bool isAmbiguous({double margin = 0.15}) {
    if (candidates.length < 2) return false;
    return candidates[0].confidence - candidates[1].confidence < margin;
  }
}
