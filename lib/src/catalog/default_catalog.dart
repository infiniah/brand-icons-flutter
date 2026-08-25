import 'package:flutter/services.dart';

import 'brand_catalog.dart';

/// The catalogue that ships with this package.
///
/// The asset path is this package's business, not the caller's, so it is not something to look up
/// and pass in. Building the indexes walks every mark twice, so the result is memoised: await it
/// as often as you like and it is parsed once.
Future<BrandCatalog> defaultCatalog({AssetBundle? bundle}) {
  return _cached ??= _load(bundle ?? rootBundle);
}

Future<BrandCatalog>? _cached;

Future<BrandCatalog> _load(AssetBundle bundle) async {
  final text = await bundle.loadString('packages/brand_icons/assets/brand_marks.json');
  return BrandCatalog.parse(text);
}

/// Drops the memoised catalogue. Only useful in tests.
void resetDefaultCatalog() {
  _cached = null;
}
