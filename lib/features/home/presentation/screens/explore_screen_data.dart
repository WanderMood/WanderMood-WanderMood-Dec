part of 'explore_screen.dart';

class _ExploreSectionData {
  _ExploreSectionData({required this.id, List<Place>? cards})
      : cards = cards ?? [];

  final String id;
  List<Place> cards;
  bool isLoading = false;
  bool hasError = false;
}

/// WanderMood v2 — Advanced Filters modal (SCREEN 7)
const Color _afWmWhite = Color(0xFFFFFFFF);
const Color _afWmCream = Color(0xFFF5F0E8);
const Color _afWmParchment = Color(0xFFE8E2D8);
const Color _afWmForest = Color(0xFF2A6049);
const Color _afWmForestTint = Color(0xFFEBF3EE);
const Color _afWmCharcoal = Color(0xFF1E1C18);
const Color _afWmStone = Color(0xFF8C8780);

/// Clears MainScreen floating pill nav + typical home indicator ([MainScreen] `extendBody`).
const double _kExploreFloatingNavClearance = 88;

/// Explore list/grid: initial batch and each "Load more" step (local reveal or after fetch).
const int _kExplorePageSize = 18;
const int _kExploreSeedTargetMin = 180;
const int _kExplorePrewarmBatchSize = 4;
/// Extra [getExplore] discovery / named-filter rounds to grow the merged pool
/// toward [_kExploreSeedTargetMin] on first load (writes through moody → DB).
/// Kept at 4 to cap the first-user-per-city Google API spend.
const int _kExploreBulkSeedMaxExtraCalls = 4;
