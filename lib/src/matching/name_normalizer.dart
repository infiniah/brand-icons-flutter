/// Turns the many ways a service gets written into something comparable.
///
/// Real inputs are messy: a bank statement says `NETFLIX.COM`, an Apple receipt says
/// `Apple Music (Family)`, a person types `netflix`. All three should reach the same brand.
///
/// Every rule here is mirrored byte for byte in the Swift, Kotlin and TypeScript ports and pinned
/// by `golden-corpus.json`. Change one and you have to change all four.
abstract final class NameNormalizer {
  /// Words that describe a *tier* rather than a *brand*.
  ///
  /// These are stripped for matching but kept in [qualifiers], because they are exactly what
  /// separates two real brands: `Apple Music` and `Apple TV` share a root and are not the same
  /// product.
  static const tierWords = <String>{
    'plus', 'premium', 'pro', 'family', 'individual', 'student', 'duo', 'basic',
    'standard', 'unlimited', 'annual', 'monthly', 'yearly', 'subscription', 'plan',
    'membership', 'trial', 'tier', 'account',
  };

  /// Noise a payment processor bolts onto a descriptor, safe to drop anywhere it appears.
  static const processorNoise = <String>{
    'com', 'www', 'inc', 'ltd', 'llc', 'co', 'corp', 'gmbh', 'bv', 'sa', 'ag',
    'payment', 'payments', 'recurring', 'autopay', 'bill', 'billing', 'purchase',
  };

  /// Processors that are also real brands.
  ///
  /// `APPLE.COM/BILL SPOTIFY` is Spotify, so the leading `apple` is noise. `Apple TV` is Apple, so
  /// the same token is the brand. Position alone does not separate them, since both lead. What
  /// separates them is what follows: a descriptor puts processor noise after the prefix, and a
  /// brand name does not.
  static const processorPrefixes = <String>{
    'apple', 'google', 'paypal', 'stripe', 'sq', 'sumup', 'chk', 'pos',
  };

  /// Lowercased, diacritic free, punctuation collapsed to single spaces.
  static String normalize(String raw) {
    final folded = _stripDiacritics(raw.toLowerCase());
    final buffer = StringBuffer();
    for (final rune in folded.runes) {
      buffer.writeCharCode(_isAlphanumeric(rune) ? rune : 0x20);
    }
    return buffer
        .toString()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .join(' ');
  }

  /// Word tokens, with processor noise removed.
  ///
  /// `APPLE.COM/BILL SPOTIFY` becomes `['spotify']`, which is the only useful token in it.
  static List<String> tokens(String raw, {bool keepingProcessorNoise = false}) {
    final words = normalize(raw).split(' ').where((word) => word.isNotEmpty).toList();
    if (keepingProcessorNoise) return words;

    var kept = words;
    if (words.isNotEmpty &&
        processorPrefixes.contains(words.first) &&
        words.length > 1 &&
        processorNoise.contains(words[1])) {
      kept = words.sublist(1);
    }

    final meaningful = kept.where((word) => !processorNoise.contains(word)).toList();
    // Falling back to the kept words matters for a descriptor that is *only* noise, such as a bare
    // "APPLE.COM", where "apple" really is the brand.
    return meaningful.isEmpty ? kept : meaningful;
  }

  /// Brand tokens only, with tier words removed.
  static List<String> brandTokens(String raw) {
    final all = tokens(raw);
    final stripped = all.where((word) => !tierWords.contains(word)).toList();
    return stripped.isEmpty ? all : stripped;
  }

  /// The tier words present, in order. `Kalend Plus` reports `['plus']`.
  static List<String> qualifiers(String raw) => tokens(raw, keepingProcessorNoise: true)
      .where(tierWords.contains)
      .toList();

  /// The comparable key: brand tokens, joined, no spaces.
  static String key(String raw) => brandTokens(raw).join();

  static bool _isAlphanumeric(int rune) =>
      (rune >= 0x30 && rune <= 0x39) ||
      (rune >= 0x41 && rune <= 0x5A) ||
      (rune >= 0x61 && rune <= 0x7A) ||
      (rune > 0x7F && _isLetterBeyondAscii(rune));

  /// Dart has no Unicode category table in core, and the catalogue is Latin, so the only non ASCII
  /// letters that reach here are ones `_stripDiacritics` did not know. Treating them as letters
  /// keeps a name like `Ünknown` from collapsing to nothing.
  static bool _isLetterBeyondAscii(int rune) =>
      !_combiningMarks.contains(rune) && !_punctuationBeyondAscii.contains(rune);

  static const _punctuationBeyondAscii = <int>{
    0x00A0, 0x00A9, 0x00AE, 0x00B7, 0x2013, 0x2014, 0x2018, 0x2019, 0x201C, 0x201D,
    0x2022, 0x2026, 0x2122, 0x00D7, 0x00F7,
  };

  static const _combiningMarks = <int>{};

  /// NFD would need `package:characters` plus a table; the catalogue and real statement text only
  /// ever carry Latin-1 accents, so those are mapped directly and anything else is left alone.
  static String _stripDiacritics(String value) {
    const from = 'àáâãäåāăąçćĉċčďđèéêëēĕėęěĝğġģĥħìíîïĩīĭįıĵķĺļľŀłñńņňòóôõöøōŏőŕŗřśŝşšţťŧùúûüũūŭůűųŵýÿŷźżžæœß';
    const to = 'aaaaaaaaacccccddeeeeeeeeegggghhiiiiiiiiijklllllnnnnooooooooorrrsssstttuuuuuuuuuuwyyyzzzaoos';
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final index = from.runes.toList().indexOf(rune);
      buffer.writeCharCode(index >= 0 ? to.runes.elementAt(index) : rune);
    }
    return buffer.toString();
  }
}
