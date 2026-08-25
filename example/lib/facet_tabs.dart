import 'package:flutter/material.dart';

import 'mark_facet.dart';

class FacetTabs extends StatelessWidget {
  const FacetTabs({super.key, required this.selection, required this.onSelect});

  final MarkFacet selection;
  final ValueChanged<MarkFacet> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final facet in MarkFacet.values)
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => onSelect(facet),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    facet.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          facet == selection ? FontWeight.w600 : FontWeight.w400,
                      color: facet == selection
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 2,
                    width: facet == selection ? 22 : 0,
                    color: scheme.onSurface,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
