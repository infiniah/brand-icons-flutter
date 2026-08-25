import 'package:brand_icons/brand_icons.dart';
import 'package:flutter_test/flutter_test.dart';

/// The ranking rules, which answer a real complaint: a monochrome catalogue draws Figma as a
/// hollow outline, so the bundled mark scores 1.00 and looks nothing like the logo.
void main() {
  BrandIconCandidate candidate(String slug, double confidence, BrandIconSource source) =>
      BrandIconCandidate(slug: slug, title: slug, confidence: confidence, source: source);

  test('real artwork tiers are preferred, best artwork first', () {
    expect(
      const ResolverConfiguration(allowsAppStore: true).effectivePreferredSources,
      [BrandIconSource.appStore, BrandIconSource.favicon],
    );
    expect(
      const ResolverConfiguration().effectivePreferredSources,
      [BrandIconSource.favicon],
    );
  });

  test('offline prefers nothing because there is nothing to prefer', () {
    expect(ResolverConfiguration.offline.effectivePreferredSources, isEmpty);
  });

  test('a confident preferred source outranks an equally confident bundled mark', () {
    final result = BrandIconResult.ranked('Figma', [
      candidate('figma', 1.0, BrandIconSource.bundled),
      candidate('com.figma.FigmaMirror', 1.0, BrandIconSource.appStore),
    ], preferring: [BrandIconSource.appStore]);
    expect(result.candidates.first.source, BrandIconSource.appStore);
  });

  test('an unsure preferred source does not jump the queue', () {
    final result = BrandIconResult.ranked('Figma', [
      candidate('figma', 1.0, BrandIconSource.bundled),
      candidate('figma.com', 0.65, BrandIconSource.favicon),
    ], preferring: [BrandIconSource.favicon]);
    expect(result.candidates.first.source, BrandIconSource.bundled);
  });

  test('a favicon for a domain you actually supplied does jump the queue', () {
    final result = BrandIconResult.ranked('Figma', [
      candidate('figma', 1.0, BrandIconSource.bundled),
      candidate('figma.com', 0.86, BrandIconSource.favicon),
    ], preferring: [BrandIconSource.favicon]);
    expect(result.candidates.first.source, BrandIconSource.favicon);
  });

  test('within one source confidence still decides', () {
    final result = BrandIconResult.ranked('Apple', [
      candidate('appletv', 0.51, BrandIconSource.bundled),
      candidate('apple', 0.94, BrandIconSource.bundled),
    ], preferring: [BrandIconSource.appStore]);
    expect(result.candidates.map((c) => c.slug).toList(), ['apple', 'appletv']);
  });

  test('shorthand hex parses, which a two tone mark depends on', () {
    expect(BrandColor.fromHex('FFF'), BrandColor.fromHex('FFFFFF'));
    expect(BrandColor.fromHex('FFFF'), BrandColor.fromHex('FFFFFF'));
    expect(BrandColor.fromHex('nope'), isNull);
  });
}
