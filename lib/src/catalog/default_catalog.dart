import 'package:flutter/services.dart';

import 'brand_catalog.dart';

/// Which set of marks to load.
///
/// The two differ only in which marks they contain. Scoring, ranking and the whole API are the
/// same either way, so a query that resolves in one resolves the same in the other unless the
/// brand it names is one of the marks [CatalogVariant.compact] leaves out.
enum CatalogVariant {
  /// Every mark, 4,770 of them.
  full('packages/brand_icons/assets/brand_marks.json'),

  /// 4,473 marks, leaving out those whose path data runs past 4 KB.
  ///
  /// Those are illustrations rather than icons, indistinct at the size an icon is drawn, and they
  /// account for most of the difference in size.
  compact('packages/brand_icons/assets/brand_marks_compact.json');

  const CatalogVariant(this.asset);

  final String asset;
}

/// The catalogue that ships with this package.
///
/// The asset path is this package's business, not the caller's. Building the indexes walks every
/// mark twice, so the result is memoised per variant: await it as often as you like.
Future<BrandCatalog> defaultCatalog({
  CatalogVariant variant = CatalogVariant.full,
  AssetBundle? bundle,
}) {
  return _cached[variant] ??= _load(variant, bundle ?? rootBundle);
}

final Map<CatalogVariant, Future<BrandCatalog>> _cached = {};

Future<BrandCatalog> _load(CatalogVariant variant, AssetBundle bundle) async {
  return BrandCatalog.parse(await bundle.loadString(variant.asset));
}

/// Drops the memoised catalogues. Only useful in tests.
void resetDefaultCatalog() => _cached.clear();
