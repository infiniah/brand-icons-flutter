import '../catalog/brand_catalog.dart';
import '../catalog/default_catalog.dart';
import '../core/brand_icon_candidate.dart';
import '../core/brand_icon_error.dart';
import '../core/brand_icon_result.dart';
import '../core/brand_icon_shape.dart';
import '../core/brand_query.dart';
import '../matching/name_normalizer.dart';
import '../providers/app_store_provider.dart';
import '../providers/brand_icon_provider.dart';
import '../providers/bundled_icon_provider.dart';
import '../providers/favicon_provider.dart';
import 'provider_probe.dart';
import 'resolver_configuration.dart';

/// Resolves a service name to ranked brand icon candidates.
///
/// ```dart
/// final resolver = BrandIconResolver(catalog);
/// final result = await resolver.resolve(BrandQuery('NETFLIX.COM'));
/// final icon = result.best(minimum: 0.8);
/// ```
///
/// Providers are consulted cheapest first and the resolver stops early once a candidate is good
/// enough, so the common case never touches the network.
class BrandIconResolver {
  /// Wraps a catalogue you already have.
  ///
  /// Prefer [BrandIconResolver.bundled] unless you are shipping your own marks.
  BrandIconResolver(
    BrandCatalog catalog, {
    this.configuration = const ResolverConfiguration(),
    List<BrandIconProvider>? providers,
  }) : providers = providers ??
            [
              BundledIconProvider(
                configuration.excludesRestrictiveLicenses
                    ? catalog.withoutRestrictiveLicenses()
                    : catalog,
              ),
              if (configuration.allowsNetwork) FaviconProvider(),
              if (configuration.allowsNetwork && configuration.allowsAppStore)
                AppStoreProvider(isEnabled: true),
            ];

  /// A resolver over the catalogue bundled with this package.
  ///
  /// ```dart
  /// final resolver = await BrandIconResolver.bundled();
  /// ```
  static Future<BrandIconResolver> bundled({
    ResolverConfiguration configuration = const ResolverConfiguration(),
    CatalogVariant variant = CatalogVariant.full,
    List<BrandIconProvider>? providers,
  }) async =>
      BrandIconResolver(
        await defaultCatalog(variant: variant),
        configuration: configuration,
        providers: providers,
      );

  final ResolverConfiguration configuration;
  final List<BrandIconProvider> providers;
  final Map<String, BrandIconResult> _cache = {};

  /// Ranked candidates for a query that may also carry a domain or a known slug.
  Future<BrandIconResult> resolve(BrandQuery query) async {
    final key = _cacheKey(query);
    final cached = _cache[key];
    if (cached != null) return cached;

    final collected = <BrandIconCandidate>[];
    for (final provider in providers) {
      if (collected.isNotEmpty &&
          collected.first.confidence >= configuration.shortCircuitConfidence) {
        break;
      }
      try {
        collected.addAll(await provider.candidates(query));
      } catch (_) {
        continue;
      }
      collected.sort((a, b) => b.confidence.compareTo(a.confidence));
    }

    final result = BrandIconResult.ranked(
      query.name,
      _deduplicated(collected)
          .where((candidate) => candidate.confidence >= configuration.minimumConfidence)
          .take(configuration.maximumCandidates)
          .toList(),
      preferring: configuration.effectivePreferredSources,
      preferenceThreshold: configuration.preferenceThreshold,
    );
    _cache[key] = result;
    return result;
  }

  /// Fetches the drawable payload for a candidate, if it does not already carry one.
  Future<BrandIconShape> shape(BrandIconCandidate candidate) async {
    if (candidate.shape != null) return candidate.shape!;
    for (final provider in providers) {
      if (provider.source == candidate.source) return provider.shape(candidate);
    }
    throw ProviderDisabledError(candidate.source);
  }

  /// Asks every provider in parallel and reports what each returned, with timings.
  ///
  /// The diagnostic path, not the resolution path. It ignores the short circuit so a name the
  /// catalogue already knows still reaches the network providers, which is the only way to
  /// compare them.
  Future<List<ProviderProbe>> probe(BrandQuery query) async {
    final probes = await Future.wait(providers.map((provider) async {
      final started = DateTime.now();
      var found = <BrandIconCandidate>[];
      BrandIconError? failure;
      try {
        found = await provider.candidates(query);
      } on BrandIconError catch (error) {
        failure = error;
      } catch (error) {
        failure = TransportError('$error');
      }
      found.sort((a, b) => b.confidence.compareTo(a.confidence));
      return ProviderProbe(
        source: provider.source,
        milliseconds: DateTime.now().difference(started).inMilliseconds,
        candidates: found,
        failure: failure,
      );
    }));

    probes.sort((a, b) {
      if (a.topConfidence != b.topConfidence) {
        return b.topConfidence.compareTo(a.topConfidence);
      }
      return a.milliseconds.compareTo(b.milliseconds);
    });
    return probes;
  }

  void removeCachedResults() => _cache.clear();

  /// Keeps the highest scoring candidate per brand, so the same company arriving from two
  /// providers is offered once rather than twice.
  List<BrandIconCandidate> _deduplicated(List<BrandIconCandidate> candidates) {
    final seen = <String>{};
    return candidates
        .where((candidate) => seen.add(NameNormalizer.key(candidate.slug)))
        .toList();
  }

  String _cacheKey(BrandQuery query) =>
      [NameNormalizer.key(query.name), query.domain ?? '', query.slug ?? ''].join('|');
}
