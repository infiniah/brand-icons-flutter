import '../core/brand_query.dart';

/// The word a person would call a brand, taken from its domain.
///
/// `netflix.com` and `bbc.co.uk` both reduce to the brand rather than to a suffix, which is what
/// makes a domain scoreable against a free text name at all.
abstract final class DomainLabel {
  static const _secondLevelSuffixes = {'co', 'com', 'net', 'org', 'ac', 'gov', 'edu'};

  static String secondLevel(String domain) {
    final parts = BrandQuery.normalizeDomain(domain).split('.').where((p) => p.isNotEmpty).toList();
    if (parts.length < 2) return parts.isEmpty ? '' : parts.first;

    // `bbc.co.uk` puts the brand three labels from the end, not two.
    if (parts.length >= 3 &&
        parts[parts.length - 1].length == 2 &&
        _secondLevelSuffixes.contains(parts[parts.length - 2])) {
      return parts[parts.length - 3];
    }
    return parts[parts.length - 2];
  }
}
