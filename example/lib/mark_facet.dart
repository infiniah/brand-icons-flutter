import 'package:brand_icons/brand_icons.dart';

enum MarkFacet {
  all('All'),
  colour('Colour'),
  monochrome('One tint'),
  restricted('Restricted');

  const MarkFacet(this.label);

  final String label;

  bool contains(BundledMark mark) => switch (this) {
        MarkFacet.all => true,
        MarkFacet.colour => mark.layers.isNotEmpty,
        MarkFacet.monochrome => mark.layers.isEmpty,
        MarkFacet.restricted => mark.license?.isRestrictive ?? false,
      };
}
