import 'dart:convert';
import 'dart:io';

import 'package:brand_icons/src/catalog/brand_catalog.dart';
import 'package:brand_icons/src/vector/path_segment.dart';
import 'package:brand_icons/src/vector/svg_path_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Proves this port's path parser draws the same shape as the Swift reference.
///
/// The corpus proves the ports agree about *which* brand a name means. It says nothing about
/// whether they draw the same thing, and a parser that mishandles an arc produces a mangled icon
/// at a perfect confidence score.
void main() {
  final reference =
      jsonDecode(File('test/fixtures/golden-geometry.json').readAsStringSync()) as List<dynamic>;
  final catalog = BrandCatalog.parse(File('assets/brand_marks.json').readAsStringSync());

  test('every reference mark parses to the same elements', () {
    for (final row in reference.cast<Map<String, dynamic>>()) {
      final slug = row['slug'] as String;
      final mark = catalog.mark(slug);
      expect(mark, isNotNull, reason: 'catalogue is missing $slug');

      final segments = SVGPathParser.parse(mark!.path);
      expect(segments, isNotNull, reason: '$slug did not parse');

      final kinds = segments!.map((segment) => switch (segment) {
            MoveToSegment() => 'M',
            LineToSegment() => 'L',
            QuadToSegment() => 'Q',
            CubicToSegment() => 'C',
            CloseSegment() => 'Z',
          }).join();
      expect(kinds, row['kinds'], reason: 'element kinds for $slug');

      final points = <double>[];
      for (final segment in segments) {
        switch (segment) {
          case MoveToSegment(:final x, :final y):
          case LineToSegment(:final x, :final y):
            points.addAll([x, y]);
          case QuadToSegment(:final cx, :final cy, :final x, :final y):
            points.addAll([cx, cy, x, y]);
          case CubicToSegment(:final c1x, :final c1y, :final c2x, :final c2y, :final x, :final y):
            points.addAll([c1x, c1y, c2x, c2y, x, y]);
          case CloseSegment():
            break;
        }
      }

      final expected = (row['points'] as List<dynamic>).cast<num>();
      expect(points.length, expected.length, reason: 'point count for $slug');
      for (var index = 0; index < points.length; index++) {
        expect(
          points[index],
          closeTo(expected[index], 0.01),
          reason: '$slug point $index',
        );
      }
    }
  });

  test('every mark and every layer in the catalogue parses', () {
    final failed = <String>[];
    var paths = 0;
    for (final mark in catalog.marks) {
      // A mark with colour layers carries no flattened path, so there is nothing to parse.
      if (mark.path.isNotEmpty) {
        paths++;
        if (SVGPathParser.parse(mark.path) == null) failed.add('${mark.slug}: mono');
      }
      for (var index = 0; index < mark.layers.length; index++) {
        paths++;
        if (SVGPathParser.parse(mark.layers[index].path) == null) {
          failed.add('${mark.slug}: layer $index');
        }
      }
    }
    expect(failed, isEmpty, reason: 'paths that did not parse');
    expect(paths, greaterThan(4000));
  });
}
