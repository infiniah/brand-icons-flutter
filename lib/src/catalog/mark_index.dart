import '../matching/name_normalizer.dart';
import 'bundled_mark.dart';

/// Narrows a catalogue to the handful of marks worth scoring.
///
/// Scoring every mark is fine at a few hundred and not at a few thousand: the edit distance in
/// `MatchScorer` is quadratic in the string lengths, so the cost is linear in the catalogue. Two
/// structures fix that without changing a single score: an exact map from normalised key, and an
/// inverted index from token to marks.
///
/// A query whose tokens appear nowhere falls back to the whole catalogue, because a misspelling
/// has no shared token and edit distance is exactly what should catch it.
class MarkIndex {
  MarkIndex(this._all) {
    for (final mark in _all) {
      // A set, because a mark whose title normalises to its slug would otherwise be indexed under
      // that one key twice and returned twice.
      for (final key in {NameNormalizer.key(mark.title), NameNormalizer.key(mark.slug)}) {
        if (key.isEmpty) continue;
        _byKey.putIfAbsent(key, () => []).add(mark);
      }
      for (final token in {...NameNormalizer.brandTokens(mark.title), mark.slug}) {
        if (token.isEmpty) continue;
        _byToken.putIfAbsent(token, () => []).add(mark);
      }
    }
  }

  final List<BundledMark> _all;
  final Map<String, List<BundledMark>> _byKey = {};
  final Map<String, List<BundledMark>> _byToken = {};

  /// Marks whose normalised key equals the query's exactly.
  List<BundledMark> exactMatches(String query) =>
      _byKey[NameNormalizer.key(query)] ?? const [];

  /// Every mark sharing a token, plus the whole catalogue when nothing shares one.
  List<BundledMark> shortlist(String query) {
    final queryTokens = NameNormalizer.brandTokens(query);
    if (queryTokens.isEmpty) return _all;

    final seen = <String>{};
    final shortlist = <BundledMark>[];
    for (final token in queryTokens) {
      for (final mark in _byToken[token] ?? const <BundledMark>[]) {
        if (seen.add(mark.slug)) shortlist.add(mark);
      }
    }

    // A prefix hit catches "netflixcom" against "netflix" when nothing tokenised the same.
    if (shortlist.isEmpty) {
      final key = NameNormalizer.key(query);
      for (final mark in _all) {
        if (!seen.add(mark.slug)) continue;
        final markKey = NameNormalizer.key(mark.slug);
        if (key.startsWith(markKey) || markKey.startsWith(key)) shortlist.add(mark);
      }
    }

    return shortlist.isEmpty ? _all : shortlist;
  }
}
