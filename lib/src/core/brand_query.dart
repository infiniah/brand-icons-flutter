import '../matching/name_normalizer.dart';

/// What you know about the thing you want an icon for.
///
/// Only [name] is required. Supplying [domain] markedly improves both accuracy and speed, because
/// domain lookups are exact where name lookups are fuzzy.
class BrandQuery {
  BrandQuery(this.name, {String? domain, this.slug})
      : domain = domain == null ? null : normalizeDomain(domain);

  final String name;
  final String? domain;
  final String? slug;

  String get key => NameNormalizer.key(name);

  /// A domain guessed from the name, used when the caller did not supply one.
  ///
  /// Deliberately naive. Providers that use it should treat a miss as ordinary.
  String get inferredDomain => domain ?? '${NameNormalizer.key(name)}.com';

  static String normalizeDomain(String raw) {
    var value = raw.toLowerCase();
    for (final prefix in ['https://', 'http://', 'www.']) {
      if (value.startsWith(prefix)) value = value.substring(prefix.length);
    }
    final slash = value.indexOf('/');
    if (slash >= 0) value = value.substring(0, slash);
    return value;
  }
}
