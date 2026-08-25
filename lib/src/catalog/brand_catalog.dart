import 'dart:convert';

import '../core/brand_color.dart';
import '../core/vector_layer.dart';
import 'bundled_mark.dart';
import 'mark_index.dart';

/// The marks compiled into the library, plus the indexes that make them fast to search.
///
/// Build one with [parse] and keep it. Construction walks every mark twice to build the indexes,
/// which costs real milliseconds at four thousand marks and is wasted if done per lookup.
class BrandCatalog {
  BrandCatalog._(this.marks, this.sourceVersion)
      : _bySlug = {for (final mark in marks) mark.slug: mark},
        index = MarkIndex(marks);

  /// Every mark, in catalogue order.
  final List<BundledMark> marks;

  /// The Simple Icons release the catalogue was generated from.
  final String sourceVersion;

  final Map<String, BundledMark> _bySlug;
  final MarkIndex index;

  BundledMark? mark(String slug) => _bySlug[slug];

  /// Marks whose recorded terms forbid commercial use or derivative works. See NOTICE.
  List<BundledMark> get restrictivelyLicensed =>
      marks.where((mark) => mark.license?.isRestrictive ?? false).toList();

  /// Everything except [restrictivelyLicensed].
  BrandCatalog withoutRestrictiveLicenses() => BrandCatalog._(
        marks.where((mark) => !(mark.license?.isRestrictive ?? false)).toList(),
        sourceVersion,
      );

  static BrandCatalog get empty => BrandCatalog._(const [], '');

  /// Parses the generated catalogue.
  static BrandCatalog parse(String text) {
    final payload = jsonDecode(text) as Map<String, dynamic>;
    final entries = (payload['marks'] as List<dynamic>? ?? const []);
    final marks = <BundledMark>[];

    for (final entry in entries.cast<Map<String, dynamic>>()) {
      final slug = entry['slug'] as String?;
      final title = entry['title'] as String?;
      final path = entry['path'] as String?;
      if (slug == null || title == null || path == null) continue;

      final viewBox = _numbers(entry['viewBox']) ?? const [0.0, 0.0, 24.0, 24.0];
      final colorViewBox = _numbers(entry['colorViewBox']);
      final layers = <VectorLayer>[];
      for (final raw in (entry['layers'] as List<dynamic>? ?? const [])) {
        final layer = raw as Map<String, dynamic>;
        final layerPath = layer['path'] as String?;
        if (layerPath == null || layerPath.isEmpty) continue;
        layers.add(
          VectorLayer(
            path: layerPath,
            fill: layer['fill'] == null ? null : BrandColor.fromHex(layer['fill'] as String),
            isEvenOdd: layer['evenOdd'] == true,
          ),
        );
      }

      // Colour artwork is only usable with the canvas it was drawn on, so a mark with one and not
      // the other falls back to the monochrome path.
      final usableColor = layers.isNotEmpty && colorViewBox != null;

      final licenseRaw = entry['license'] as Map<String, dynamic>?;
      marks.add(
        BundledMark(
          slug: slug,
          title: title,
          path: path,
          viewBox: viewBox,
          tint: BrandColor.fromHex(entry['tint'] as String? ?? ''),
          layers: usableColor ? layers : const [],
          colorViewBox: usableColor ? colorViewBox : null,
          license: licenseRaw == null
              ? null
              : BundledMarkLicense(
                  licenseRaw['type'] as String? ?? '',
                  licenseRaw['url'] as String?,
                ),
        ),
      );
    }

    return BrandCatalog._(marks, payload['sourceVersion'] as String? ?? '');
  }

  static List<double>? _numbers(Object? raw) {
    if (raw is! List) return null;
    if (raw.length != 4) return null;
    final values = raw.map((value) => (value as num).toDouble()).toList();
    if (values[2] <= 0 || values[3] <= 0) return null;
    return values;
  }
}
