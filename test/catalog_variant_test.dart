import 'dart:io';

import 'package:brand_icons/brand_icons.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two catalogues differ only in which marks they hold.
void main() {
  final full = BrandCatalog.parse(File('assets/brand_marks.json').readAsStringSync());
  final compact = BrandCatalog.parse(File('assets/brand_marks_compact.json').readAsStringSync());

  test('compact is the smaller subset', () {
    expect(full.marks.length, 4770);
    expect(compact.marks.length, 4473);

    final fullSlugs = full.marks.map((m) => m.slug).toSet();
    for (final mark in compact.marks) {
      expect(fullSlugs.contains(mark.slug), isTrue, reason: '${mark.slug} is not in full');
    }
  });

  test('a brand in both scores the same either way', () async {
    final a = BrandIconResolver(full, configuration: ResolverConfiguration.offline);
    final b = BrandIconResolver(compact, configuration: ResolverConfiguration.offline);
    for (final name in ['Figma', 'Spotify', 'NOTION LABS INC', 'Microsoft']) {
      final one = await a.resolve(BrandQuery(name));
      final two = await b.resolve(BrandQuery(name));
      expect(two.candidates.first.slug, one.candidates.first.slug, reason: name);
      expect(two.candidates.first.confidence, one.candidates.first.confidence, reason: name);
    }
  });

  test('what compact leaves out is illustration sized', () {
    final compactSlugs = compact.marks.map((m) => m.slug).toSet();
    final omitted = full.marks.where((m) => !compactSlugs.contains(m.slug)).toList();
    expect(omitted.length, 297);
    for (final mark in omitted) {
      final bytes = mark.path.length +
          mark.layers.fold<int>(0, (total, layer) => total + layer.path.length);
      expect(bytes, greaterThan(4096), reason: mark.slug);
    }
  });
}
