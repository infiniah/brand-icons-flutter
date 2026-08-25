import 'package:brand_icons/brand_icons.dart';

import 'palette.dart';

/// One row in the tracker: a company, the role, and where the application got to.
class Application {
  Application({
    required this.company,
    required this.role,
    required this.postedAgo,
    required this.status,
    this.icon,
  });

  final String company;
  final String role;
  final String postedAgo;
  final ApplicationStatus status;
  BrandIconCandidate? icon;

  /// Seed rows, chosen to make the library's limits visible rather than to flatter it.
  ///
  /// Microsoft is here because Simple Icons removed it on trademark request, so only the colour
  /// sets carry it. Figma and Duolingo are here because their monochrome marks are a hollow
  /// outline and a flat silhouette of logos that are really full colour.
  static List<Application> get sample => [
        Application(
          company: 'Figma',
          role: 'Senior Product Engineer',
          postedAgo: '2d ago',
          status: ApplicationStatus.interview,
        ),
        Application(
          company: 'Duolingo',
          role: 'Android Engineer, Learning',
          postedAgo: '5d ago',
          status: ApplicationStatus.applied,
        ),
        Application(
          company: 'Spotify',
          role: 'Engineering Manager, Playback',
          postedAgo: '1w ago',
          status: ApplicationStatus.offer,
        ),
        Application(
          company: 'Microsoft',
          role: 'Principal SWE, Developer Division',
          postedAgo: '1w ago',
          status: ApplicationStatus.applied,
        ),
        Application(
          company: 'Notion',
          role: 'Product Engineer, Databases',
          postedAgo: '2w ago',
          status: ApplicationStatus.rejected,
        ),
        Application(
          company: 'GitHub',
          role: 'Staff Engineer, Actions',
          postedAgo: '3w ago',
          status: ApplicationStatus.interview,
        ),
      ];
}
