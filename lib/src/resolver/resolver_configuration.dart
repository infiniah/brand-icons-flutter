import '../core/brand_icon_source.dart';

/// How the resolver should behave.
class ResolverConfiguration {
  const ResolverConfiguration({
    this.shortCircuitConfidence = 0.95,
    this.minimumConfidence = 0.35,
    this.maximumCandidates = 5,
    this.allowsAppStore = false,
    this.allowsNetwork = true,
    this.requestsPerMinute = 15,
    this.excludesRestrictiveLicenses = false,
    this.preferredSources,
    this.preferenceThreshold = 0.8,
  });

  /// Stop as soon as a candidate reaches this confidence, without asking slower providers.
  final double shortCircuitConfidence;

  /// Candidates below this are discarded rather than returned.
  final double minimumConfidence;

  /// Most candidates to return.
  final int maximumCandidates;

  /// Whether the App Store provider may be used.
  ///
  /// Off by default, deliberately. Apple's Search API is limited to roughly twenty calls a minute
  /// per client, and its terms describe that artwork as promotional material for store content.
  final bool allowsAppStore;

  /// Whether providers that need the network may be used at all.
  final bool allowsNetwork;

  /// Requests per minute allowed per provider.
  final int requestsPerMinute;

  /// Leaves out marks whose recorded terms forbid commercial use or derivative works.
  final bool excludesRestrictiveLicenses;

  /// Sources that win over a higher scoring candidate from somewhere else.
  ///
  /// Confidence answers "is this the right brand" and says nothing about whether the artwork is
  /// any good. A monochrome catalogue mark and a real app icon can both score 1.00.
  ///
  /// Leaving this null derives it from what is enabled: every tier that returns real artwork,
  /// best first.
  final List<BrandIconSource>? preferredSources;

  /// How sure a preferred source must be before it may jump the queue.
  ///
  /// Without a bar, preference is harmful: the favicon tier answers for a domain guessed from the
  /// name, and letting that outrank a certain catalogue match trades a dull icon for a wrong one.
  final double preferenceThreshold;

  /// The ordering actually applied, after deriving it from what is enabled.
  List<BrandIconSource> get effectivePreferredSources {
    if (preferredSources != null) return preferredSources!;
    if (!allowsNetwork) return const [];
    return [
      if (allowsAppStore) BrandIconSource.appStore,
      BrandIconSource.favicon,
    ];
  }

  ResolverConfiguration copyWith({
    double? shortCircuitConfidence,
    double? minimumConfidence,
    int? maximumCandidates,
    bool? allowsAppStore,
    bool? allowsNetwork,
    int? requestsPerMinute,
    bool? excludesRestrictiveLicenses,
    List<BrandIconSource>? preferredSources,
    double? preferenceThreshold,
  }) =>
      ResolverConfiguration(
        shortCircuitConfidence: shortCircuitConfidence ?? this.shortCircuitConfidence,
        minimumConfidence: minimumConfidence ?? this.minimumConfidence,
        maximumCandidates: maximumCandidates ?? this.maximumCandidates,
        allowsAppStore: allowsAppStore ?? this.allowsAppStore,
        allowsNetwork: allowsNetwork ?? this.allowsNetwork,
        requestsPerMinute: requestsPerMinute ?? this.requestsPerMinute,
        excludesRestrictiveLicenses:
            excludesRestrictiveLicenses ?? this.excludesRestrictiveLicenses,
        preferredSources: preferredSources ?? this.preferredSources,
        preferenceThreshold: preferenceThreshold ?? this.preferenceThreshold,
      );

  /// Bundled marks only. No network, no third party, works on a plane.
  static const offline = ResolverConfiguration(allowsNetwork: false);

  /// Asks every provider and never stops early. The diagnostic path, not the resolution path.
  static const exhaustive = ResolverConfiguration(
    shortCircuitConfidence: 2,
    minimumConfidence: 0,
    maximumCandidates: 12,
  );
}
