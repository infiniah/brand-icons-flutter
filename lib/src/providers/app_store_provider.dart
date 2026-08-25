import '../core/brand_icon_candidate.dart';
import '../core/brand_icon_error.dart';
import '../core/brand_icon_shape.dart';
import '../core/brand_icon_source.dart';
import '../core/brand_query.dart';
import '../matching/match_scorer.dart';
import 'brand_icon_provider.dart';
import 'icon_downloader.dart';

/// App Store artwork, via Apple's iTunes Search API.
///
/// Off unless you turn it on, because two facts about this source belong to the adopter. Apple
/// limits the Search API to roughly twenty requests a minute per client and answers `429` beyond
/// that. Apple's terms describe App Store artwork as promotional material for store content, to be
/// displayed near a store badge. Labelling a row of your own interface is a different use.
///
/// What it is unambiguously good at is the case a monochrome catalogue cannot serve: a brand whose
/// identity is colour, and a brand removed from an icon set for trademark reasons.
class AppStoreProvider implements BrandIconProvider {
  AppStoreProvider({
    this.isEnabled = false,
    this.country = 'US',
    int limit = 3,
    IconDownloader? downloader,
  })  : limit = limit < 1 ? 1 : limit,
        _downloader = downloader ?? HttpIconDownloader();

  /// Must be set explicitly. The default leaves the provider inert.
  final bool isEnabled;
  final String country;
  final int limit;
  final IconDownloader _downloader;
  final Map<String, String> _artwork = {};

  @override
  BrandIconSource get source => BrandIconSource.appStore;

  @override
  Future<List<BrandIconCandidate>> candidates(BrandQuery query) async {
    if (!isEnabled) return const [];
    final term = query.name.trim();
    if (term.isEmpty) return const [];

    final url = Uri.https('itunes.apple.com', '/search', {
      'term': term,
      'entity': 'software',
      'limit': '$limit',
      'country': country,
    }).toString();

    final payload = await _downloader.json(url);
    if (payload == null) return const [];
    final results = payload['results'];
    if (results is! List) throw const UnreadableResponseError();

    final candidates = <BrandIconCandidate>[];
    for (final raw in results.cast<Map<String, dynamic>>()) {
      final bundleId = raw['bundleId'] as String?;
      final trackName = raw['trackName'] as String?;
      final artwork = raw['artworkUrl512'] as String?;
      if (bundleId == null || trackName == null || artwork == null) continue;

      _artwork[bundleId] = artwork;
      candidates.add(
        BrandIconCandidate(
          slug: bundleId,
          title: trackName,
          confidence: MatchScorer.score(query.name, name: trackName),
          source: source,
        ),
      );
    }
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    return candidates;
  }

  @override
  Future<BrandIconShape> shape(BrandIconCandidate candidate) async {
    if (!isEnabled) throw ProviderDisabledError(source);
    if (candidate.shape != null) return candidate.shape!;

    var artwork = _artwork[candidate.slug];
    if (artwork == null) {
      final url = Uri.https('itunes.apple.com', '/lookup', {
        'bundleId': candidate.slug,
        'country': country,
      }).toString();
      final payload = await _downloader.json(url);
      final results = payload?['results'];
      if (results is List && results.isNotEmpty) {
        artwork = (results.first as Map<String, dynamic>)['artworkUrl512'] as String?;
        if (artwork != null) _artwork[candidate.slug] = artwork;
      }
    }
    if (artwork == null) throw const NotFoundError();

    final data = await _downloader.bytes(artwork);
    if (data == null) throw const NotFoundError();
    return RasterShape(data);
  }
}
