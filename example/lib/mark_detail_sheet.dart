import 'package:brand_icons/brand_icons.dart';
import 'package:flutter/material.dart';

class MarkDetailSheet extends StatelessWidget {
  const MarkDetailSheet({super.key, required this.mark});

  final BundledMark mark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final candidate = BrandIconCandidate(
      slug: mark.slug,
      title: mark.title,
      confidence: 1,
      source: BrandIconSource.bundled,
      shape: BundledIconProvider.shapeFor(mark),
    );
    final box = mark.colorViewBox ?? mark.viewBox;
    final bytes = mark.layers.isEmpty
        ? mark.path.length
        : mark.layers.fold<int>(0, (sum, layer) => sum + layer.path.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mark.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          Text(
            mark.slug,
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: BrandIcon(
              candidate: candidate,
              size: 120,
              surface: scheme.surface,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _facts(mark),
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          _Panel(
            label: 'Every size from one path',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final size in const [20.0, 28.0, 40.0, 56.0])
                  Padding(
                    padding: const EdgeInsets.only(right: 22),
                    child: Column(
                      children: [
                        BrandIcon(
                          candidate: candidate,
                          size: size,
                          surface: scheme.surface,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${size.toInt()}',
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // A mark that reads on one ground can vanish on the other, so the widget puts a
          // contrasting tile behind one that would. Both grounds are shown because only one of
          // them is the reader's.
          _Panel(
            label: 'On either ground',
            child: Row(
              children: [
                for (final ground in const [Color(0xFFF4F4F2), Color(0xFF141414)])
                  Expanded(
                    child: Container(
                      height: 72,
                      margin: EdgeInsets.only(
                        right: ground == const Color(0xFFF4F4F2) ? 12 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: ground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: BrandIcon(
                        candidate: candidate,
                        size: 44,
                        surface: ground,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Panel(
            label: 'Geometry',
            badge: mark.layers.isEmpty ? 'VECTOR' : 'LAYERED',
            child: Column(
              children: [
                _row(context, 'View box',
                    '${box[2].toInt()} × ${box[3].toInt()}'),
                const SizedBox(height: 8),
                _row(context, 'Path data', '$bytes bytes'),
                const SizedBox(height: 8),
                _row(context, 'Layers',
                    mark.layers.isEmpty ? 'none' : '${mark.layers.length}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _facts(BundledMark mark) {
    final parts = <String>[
      mark.layers.isEmpty
          ? 'Monochrome'
          : '${mark.layers.length} colour layers',
      if (mark.tint != null)
        '#${mark.tint!.red.toRadixString(16).padLeft(2, '0')}'
                '${mark.tint!.green.toRadixString(16).padLeft(2, '0')}'
                '${mark.tint!.blue.toRadixString(16).padLeft(2, '0')}'
            .toUpperCase(),
      mark.license?.type ?? 'no licence on file',
      if (mark.license?.isRestrictive ?? false) 'restrictive',
    ];
    return parts.join(' · ');
  }

  static Widget _row(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.label, required this.child, this.badge});

  final String label;
  final Widget child;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
