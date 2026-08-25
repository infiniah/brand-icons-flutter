import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../core/brand_icon_candidate.dart';
import '../core/brand_icon_error.dart';
import '../core/brand_icon_shape.dart';
import '../core/brand_icon_source.dart';
import '../core/brand_query.dart';
import '../matching/match_scorer.dart';
import 'brand_icon_provider.dart';
import 'domain_label.dart';
import 'icon_downloader.dart';
import 'image_pixel_size.dart';

/// The service's own site, via the icons it declares.
///
/// No third party sits between the user and the brand, which is the point: an icon service would
/// work just as well and would also learn every domain your users look up.
///
/// Two things are uncertain here and both belong in the number. Whether this is the right brand at
/// all: a site answering on a guessed host is often not the company the user meant, which caps the
/// tier at [ceiling]. And whether the icon is usable: a 16 pixel `.ico` drawn at 44 points is four
/// pixels per point of blur, so the measured resolution scales within the range the match sets.
class FaviconProvider implements BrandIconProvider {
  FaviconProvider({IconDownloader? downloader})
      : _downloader = downloader ?? HttpIconDownloader();

  final IconDownloader _downloader;

  static const manifestPaths = ['/site.webmanifest', '/manifest.json'];
  static const fallbackPaths = [
    '/apple-touch-icon.png',
    '/apple-touch-icon-precomposed.png',
    '/favicon.ico',
  ];
  static const double floor = 0.35;
  static const double ceiling = 0.65;

  @override
  BrandIconSource get source => BrandIconSource.favicon;

  @override
  Future<List<BrandIconCandidate>> candidates(BrandQuery query) async {
    final domain = query.domain ?? query.inferredDomain;
    final icon = await _bestIcon(domain);
    if (icon == null) return const [];

    final label = DomainLabel.secondLevel(domain);
    return [
      BrandIconCandidate(
        slug: domain,
        title: label.isEmpty ? domain : '${label[0].toUpperCase()}${label.substring(1)}',
        confidence: confidence(
          MatchScorer.score(query.name, name: label, slug: label),
          icon.pixelSize,
        ),
        source: source,
        shape: RasterShape(icon.data),
      ),
    ];
  }

  @override
  Future<BrandIconShape> shape(BrandIconCandidate candidate) async {
    if (candidate.shape != null) return candidate.shape!;
    final icon = await _bestIcon(candidate.slug);
    if (icon == null) throw const NotFoundError();
    return RasterShape(icon.data);
  }

  Future<_FetchedIcon?> _bestIcon(String domain) async {
    final host = BrandQuery.normalizeDomain(domain);
    if (host.isEmpty) return null;

    for (final path in manifestPaths) {
      final data = await _downloader.bytes('https://$host$path');
      if (data == null) continue;
      final icon = await _download(_manifestIcons(data, 'https://$host$path'));
      if (icon != null) return icon;
    }

    final markup = await _downloader.headMarkup('https://$host/');
    if (markup != null) {
      final declared = _declaredIcons(markup, 'https://$host/');
      final icon = await _download(declared);
      if (icon != null) return icon;
    }

    return _download(
      fallbackPaths.map((path) => _Declared('https://$host$path', null, 0)).toList(),
      ranked: false,
    );
  }

  Future<_FetchedIcon?> _download(List<_Declared> icons, {bool ranked = true}) async {
    final ordered = [...icons];
    if (ranked) ordered.sort((a, b) => b.rank.compareTo(a.rank));
    for (final icon in ordered) {
      final data = await _downloader.bytes(icon.url, accept: 'image/*');
      if (data == null) continue;
      return _FetchedIcon(data, ImagePixelSize.shortestSide(data) ?? icon.declaredSize);
    }
    return null;
  }

  static final _sizePair = RegExp(r'(\d+)\s*[xX]\s*(\d+)');
  static final _linkTag = RegExp(r'<link\b[^>]*>', caseSensitive: false);
  static final _attribute =
      RegExp(r'''([a-zA-Z-]+)\s*=\s*("([^"]*)"|'([^']*)'|([^\s">]+))''');

  List<_Declared> _declaredIcons(String markup, String documentUrl) {
    final icons = <_Declared>[];
    for (final tag in _linkTag.allMatches(markup)) {
      final attributes = <String, String>{};
      for (final match in _attribute.allMatches(tag.group(0)!)) {
        final value = [match.group(3), match.group(4), match.group(5)]
            .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => '')!;
        attributes[match.group(1)!.toLowerCase()] = value;
      }

      final rel = attributes['rel']?.toLowerCase();
      final href = attributes['href']?.trim();
      if (rel == null || href == null || href.isEmpty) continue;
      final resolved = _resolve(href, documentUrl);
      if (resolved == null) continue;

      final sizes = attributes['sizes'];
      final declared = sizes == null
          ? null
          : _sizePair
              .allMatches(sizes)
              .map((m) => math.min(int.parse(m.group(1)!), int.parse(m.group(2)!)))
              .fold<int?>(null, (best, value) => best == null || value > best ? value : best);

      final assumed = rel.contains('apple-touch-icon')
          ? 180
          : rel.split(' ').contains('icon') || rel.contains('shortcut icon')
              ? 32
              : null;
      if (assumed == null) continue;

      icons.add(_Declared(resolved, declared, assumed));
    }
    return icons;
  }

  List<_Declared> _manifestIcons(Uint8List data, String manifestUrl) {
    try {
      final root = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      final icons = root['icons'];
      if (icons is! List) return const [];
      final declared = <_Declared>[];
      for (final raw in icons.cast<Map<String, dynamic>>()) {
        final src = raw['src'] as String?;
        if (src == null || src.isEmpty) continue;
        final url = _resolve(src, manifestUrl);
        if (url == null) continue;
        final sizes = raw['sizes'] as String?;
        final size = sizes == null
            ? null
            : _sizePair
                .allMatches(sizes)
                .map((m) => math.min(int.parse(m.group(1)!), int.parse(m.group(2)!)))
                .fold<int?>(null, (best, value) => best == null || value > best ? value : best);
        // A manifest icon with no declared size is still likelier to be large than a favicon.
        declared.add(_Declared(url, size, 128));
      }
      return declared;
    } catch (_) {
      return const [];
    }
  }

  static String? _resolve(String href, String against) {
    try {
      final resolved = Uri.parse(against).resolve(href).toString();
      return resolved.startsWith('http') ? resolved : null;
    } catch (_) {
      return null;
    }
  }

  /// Match strength sets the range, measured resolution scales within it.
  static double confidence(double match, int? pixelSize) =>
      floor + (ceiling - floor) * match * (0.4 + 0.6 * resolutionScore(pixelSize));

  /// 0 at 16 pixels, 1 at 512, log scaled between.
  ///
  /// Linear would spend most of its range on sizes nobody ships. On this curve 128 pixels lands at
  /// 0.6 rather than at 0.22.
  static double resolutionScore(int? pixelSize) {
    if (pixelSize == null || pixelSize <= 0) return 0;
    final position = (math.log(pixelSize) / math.ln2 - 4) / 5;
    return position.clamp(0.0, 1.0);
  }
}

class _Declared {
  const _Declared(this.url, this.declaredSize, this.assumedSize);
  final String url;
  final int? declaredSize;
  final int assumedSize;
  int get rank => declaredSize ?? assumedSize;
}

class _FetchedIcon {
  const _FetchedIcon(this.data, this.pixelSize);
  final Uint8List data;
  final int? pixelSize;
}
