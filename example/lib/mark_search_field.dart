import 'package:brand_icons/brand_icons.dart';
import 'package:flutter/material.dart';

class MarkSearchField extends StatelessWidget {
  const MarkSearchField({
    super.key,
    required this.controller,
    required this.variant,
    required this.onToggleVariant,
  });

  final TextEditingController controller;
  final CatalogVariant variant;
  final VoidCallback onToggleVariant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.only(left: 12, right: 6, top: 2, bottom: 2),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(fontSize: 16, color: scheme.onSurface),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search marks',
                hintStyle:
                    TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () => controller.clear(),
              child: Icon(Icons.cancel,
                  size: 18, color: scheme.onSurfaceVariant),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onToggleVariant,
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                variant == CatalogVariant.full ? 'Full' : 'Compact',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
