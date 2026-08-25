import 'package:brand_icons/brand_icons.dart';
import 'package:flutter/material.dart';

import 'application.dart';
import 'palette.dart';

void main() => runApp(const AppliedApp());

class AppliedApp extends StatelessWidget {
  const AppliedApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Applied',
        debugShowCheckedModeBanner: false,
        theme: Palette.theme(Brightness.light),
        darkTheme: Palette.theme(Brightness.dark),
        home: const ApplicationsScreen(),
      );
}

/// A job application tracker that resolves an icon for every company.
///
/// The point of the screen is the leading mark on each row: none of these names were typed as a
/// slug, and one of them is a brand the monochrome catalogue does not carry at all.
class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final _applications = Application.sample;
  BrandCatalog? _catalog;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // The package finds and parses its own catalogue, and holds it for the process.
    final catalog = await defaultCatalog();
    final resolver = await BrandIconResolver.bundled(
      configuration: ResolverConfiguration.offline,
    );

    for (final application in _applications) {
      final result = await resolver.resolve(BrandQuery(application.company));
      application.icon = result.best(minimum: 0.5);
    }
    if (mounted) setState(() => _catalog = catalog);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: _catalog == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                    child: Text(
                      'Applied',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                    child: Text(
                      '${_applications.length} applications',
                      style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        for (var index = 0; index < _applications.length; index++) ...[
                          _Row(application: _applications[index]),
                          if (index < _applications.length - 1)
                            Divider(height: 1, indent: 68, color: scheme.outlineVariant),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.application});

  final Application application;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          BrandIcon(
            candidate: application.icon,
            size: 40,
            fallbackText: application.company,
            surface: scheme.surface,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  application.company,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  application.role,
                  style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: application.status.tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  application.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: application.status.tint,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                application.postedAgo,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
