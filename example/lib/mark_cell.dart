import 'package:brand_icons/brand_icons.dart';
import 'package:flutter/material.dart';

class MarkCell extends StatelessWidget {
  const MarkCell({super.key, required this.mark, required this.onTap});

  final BundledMark mark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandIcon(
            candidate: BrandIconCandidate(
              slug: mark.slug,
              title: mark.title,
              confidence: 1,
              source: BrandIconSource.bundled,
              shape: BundledIconProvider.shapeFor(mark),
            ),
            size: 46,
            fallbackText: mark.title,
            surface: theme.scaffoldBackgroundColor,
          ),
          const SizedBox(height: 6),
          Text(
            mark.slug,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
