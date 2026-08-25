/// Resolve a messy service name to a brand icon, with a confidence score you can act on.
library brand_icons;

export 'src/catalog/brand_catalog.dart';
export 'src/catalog/bundled_mark.dart';
export 'src/core/brand_color.dart';
export 'src/core/brand_icon_candidate.dart';
export 'src/core/brand_icon_error.dart';
export 'src/core/brand_icon_result.dart';
export 'src/core/brand_icon_shape.dart';
export 'src/core/brand_icon_source.dart';
export 'src/core/brand_query.dart';
export 'src/core/vector_layer.dart';
export 'src/matching/match_scorer.dart';
export 'src/matching/name_normalizer.dart';
export 'src/providers/app_store_provider.dart';
export 'src/providers/brand_icon_provider.dart';
export 'src/providers/bundled_icon_provider.dart';
export 'src/providers/favicon_provider.dart';
export 'src/providers/icon_downloader.dart';
export 'src/resolver/brand_icon_resolver.dart';
export 'src/resolver/icon_cache.dart';
export 'src/resolver/provider_probe.dart';
export 'src/resolver/rate_limiter.dart';
export 'src/resolver/resolver_configuration.dart';
export 'src/ui/brand_icon.dart';
export 'src/vector/path_segment.dart';
export 'src/vector/svg_path_parser.dart';
