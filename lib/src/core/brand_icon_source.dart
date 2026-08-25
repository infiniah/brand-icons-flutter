/// Where a candidate came from.
enum BrandIconSource {
  /// The catalogue compiled into the library. No network, microseconds.
  bundled('bundled', 'Bundled'),

  /// Apple's iTunes Search API. Real app artwork, in colour, rate limited.
  ///
  /// Named for Apple on every platform: Google publishes no equivalent public search API, so
  /// "App Store" beside a Play Store button would read like a mistake.
  appStore('appStore', 'Apple App Store'),

  /// The site's own declared icon, from its HTML or web manifest.
  favicon('favicon', 'Site icon');

  const BrandIconSource(this.id, this.label);

  /// The stable API identifier.
  final String id;

  /// What to call this tier in front of a person.
  final String label;

  static BrandIconSource? fromId(String id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }
}
