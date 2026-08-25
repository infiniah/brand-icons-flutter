import '../core/brand_icon_candidate.dart';
import '../core/brand_icon_error.dart';
import '../core/brand_icon_source.dart';

/// What one provider returned for a query, and how long it took.
///
/// Use it to decide which tiers are worth enabling for your data: a provider that answers in two
/// milliseconds from a bundled catalogue and one that answers in eight hundred over the network
/// are not interchangeable.
class ProviderProbe {
  const ProviderProbe({
    required this.source,
    required this.milliseconds,
    required this.candidates,
    this.failure,
  });

  final BrandIconSource source;

  /// Wall clock time from asking to answering, including the network.
  final int milliseconds;

  /// What it found, best first. Empty is a normal answer.
  final List<BrandIconCandidate> candidates;

  /// Why it returned nothing, when it failed rather than simply not matching.
  final BrandIconError? failure;

  String get id => source.id;

  /// The best confidence this provider offered, or zero.
  double get topConfidence => candidates.isEmpty ? 0 : candidates.first.confidence;

  ProviderProbe withCandidates(List<BrandIconCandidate> replacement) => ProviderProbe(
        source: source,
        milliseconds: milliseconds,
        candidates: replacement,
        failure: failure,
      );
}
