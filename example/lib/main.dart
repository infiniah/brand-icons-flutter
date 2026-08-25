import 'package:brand_icons/brand_icons.dart';
import 'package:flutter/material.dart';

import 'facet_tabs.dart';
import 'mark_cell.dart';
import 'mark_detail_sheet.dart';
import 'mark_facet.dart';
import 'mark_search_field.dart';
import 'palette.dart';

void main() {
  const query = String.fromEnvironment('query');
  runApp(const MarksApp(initialQuery: query));
}

class MarksApp extends StatelessWidget {
  const MarksApp({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marks',
      debugShowCheckedModeBanner: false,
      theme: Palette.theme(Brightness.light),
      darkTheme: Palette.theme(Brightness.dark),
      home: MarksScreen(initialQuery: initialQuery),
    );
  }
}

class MarksScreen extends StatefulWidget {
  const MarksScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery);

  BrandCatalog? _catalog;
  CatalogVariant _variant = CatalogVariant.full;
  MarkFacet _facet = MarkFacet.all;
  List<BundledMark> _visible = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refilter);
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final catalog = await defaultCatalog(variant: _variant);
    if (!mounted) return;
    setState(() => _catalog = catalog);
    _refilter();
  }

  void _refilter() {
    final catalog = _catalog;
    if (catalog == null) return;
    setState(() => _visible = _filter(catalog.marks, _facet, _controller.text));
  }

  /// Substring first, because a browser is a filter and the answer to `spo` is every mark
  /// containing it. The scorer only runs when that finds nothing, which is the case a misspelling
  /// produces: it shares no substring and edit distance is what catches it.
  static List<BundledMark> _filter(
    List<BundledMark> marks,
    MarkFacet facet,
    String query,
  ) {
    final faceted = marks.where(facet.contains).toList();
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return faceted;

    final literal = <(BundledMark, int)>[];
    for (final mark in faceted) {
      final rank = _rank(mark, needle);
      if (rank != null) literal.add((mark, rank));
    }
    if (literal.isNotEmpty) {
      literal.sort((a, b) =>
          a.$2 == b.$2 ? a.$1.slug.compareTo(b.$1.slug) : a.$2.compareTo(b.$2));
      return literal.map((entry) => entry.$1).toList();
    }

    final scored = faceted
        .map((mark) => (mark, MatchScorer.score(needle, name: mark.title, slug: mark.slug)))
        .where((entry) => entry.$2 >= 0.35)
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((entry) => entry.$1).toList();
  }

  /// Lower sorts first. A name that starts with what was typed is what the typist meant, so `spo`
  /// puts Spotify above Diaspora rather than leaving it to the alphabet.
  static int? _rank(BundledMark mark, String needle) {
    final title = mark.title.toLowerCase();
    if (mark.slug.startsWith(needle)) return 0;
    if (title.startsWith(needle)) return 1;
    if (mark.slug.contains(needle)) return 2;
    if (title.contains(needle)) return 3;
    return null;
  }

  String get _summary {
    final catalog = _catalog;
    if (catalog == null) return 'Loading the catalogue…';
    final colour = catalog.marks.where((mark) => mark.layers.isNotEmpty).length;
    return '${_thousands(catalog.marks.length)} brands · ${_thousands(colour)} in colour';
  }

  static String _thousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marks',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _summary,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  MarkSearchField(
                    controller: _controller,
                    variant: _variant,
                    onToggleVariant: () {
                      setState(() {
                        _variant = _variant == CatalogVariant.full
                            ? CatalogVariant.compact
                            : CatalogVariant.full;
                        _catalog = null;
                      });
                      _load();
                    },
                  ),
                  const SizedBox(height: 12),
                  FacetTabs(
                    selection: _facet,
                    onSelect: (facet) {
                      setState(() => _facet = facet);
                      _refilter();
                    },
                  ),
                ],
              ),
            ),
            Container(height: 1, color: theme.colorScheme.outlineVariant),
            Expanded(
              child: _visible.isEmpty
                  ? Center(
                      child: Text(
                        _catalog == null
                            ? 'Loading the catalogue…'
                            : 'Nothing matches “${_controller.text}”',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _visible.length,
                      itemBuilder: (context, index) {
                        final mark = _visible[index];
                        return MarkCell(
                          mark: mark,
                          onTap: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: theme.scaffoldBackgroundColor,
                            builder: (_) => FractionallySizedBox(
                              heightFactor: 0.92,
                              child: MarkDetailSheet(mark: mark),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
