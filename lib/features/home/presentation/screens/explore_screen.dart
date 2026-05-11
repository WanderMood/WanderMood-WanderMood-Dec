import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' show ProviderSubscription;
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wandermood/features/location/presentation/widgets/location_dropdown.dart';
import 'package:wandermood/features/places/models/place.dart';
// OLD - Replaced by moody_explore_provider. Keep for 24-48h rollback safety.
import 'package:wandermood/features/places/providers/moody_explore_provider.dart';
import 'package:wandermood/features/places/presentation/widgets/place_card.dart';
import 'package:wandermood/features/places/presentation/widgets/place_grid_card.dart';
import 'package:wandermood/features/places/presentation/widgets/add_place_to_my_day_sheet.dart';
import 'package:wandermood/features/places/presentation/utils/save_explore_place_to_my_day.dart';
import 'package:wandermood/features/places/services/places_service.dart';
import 'package:wandermood/core/errors/explore_location_exception.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wandermood/core/utils/moody_clock.dart';

import 'package:geolocator/geolocator.dart';
import 'package:wandermood/core/services/distance_service.dart';
import 'package:wandermood/core/services/user_preferences_service.dart';

import '../widgets/conversational_explore_header.dart';
import '../widgets/explore_feed_loading_surface.dart';
import '../widgets/explore_place_quick_peek_sheet.dart';
import 'package:wandermood/features/home/presentation/widgets/planner_activity_detail_sheet.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/providers/language_provider.dart';
import 'package:wandermood/core/utils/places_cache_utils.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/core/utils/moody_toast.dart';
import 'package:wandermood/core/config/supabase_config.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/services/connectivity_service.dart';
import 'package:wandermood/core/utils/offline_feedback.dart';
import 'package:wandermood/core/providers/explore_session_anchor_provider.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/core/config/explore_launch_config.dart';
import 'package:wandermood/features/location/services/location_service.dart';
import 'package:wandermood/features/home/presentation/providers/explore_intent_provider.dart';
import 'package:wandermood/features/places/providers/moody_place_card_blurb_provider.dart';
import 'package:wandermood/core/services/business_listing_tracker.dart';
import 'package:wandermood/core/services/partner_listing_service.dart';
import 'package:wandermood/features/home/presentation/widgets/partner_stories_row.dart';
import 'package:wandermood/features/home/presentation/widgets/partner_carousel.dart';

part 'explore_screen_data.dart';
part 'explore_screen_map_view.part.dart';
part 'explore_screen_af_layout.part.dart';
part 'explore_screen_af_mood_pills.part.dart';
part 'explore_screen_af_suggestion_outline.part.dart';
part 'explore_screen_af_quick_suggestions.part.dart';
part 'explore_screen_af_dietary_accessibility.part.dart';
part 'explore_screen_af_logistics_photo_chips.part.dart';
part 'explore_screen_af_shell_chrome.part.dart';
part 'explore_screen_af_shell.part.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ProviderSubscription<int>? _manualCityPickSubscription;
  ProviderSubscription<String?>? _externalSearchIntentSubscription;
  String _selectedCategory = 'all';
  String _searchFilter = 'all';
  bool _isSearching = false;
  String _searchQuery = '';

  // Backend search results — null means show normal explore feed
  List<Place>? _searchResults;
  List<String> _relatedSearchOptions = const [];
  Timer? _searchDebounce;

  // Scroll detection for content
  bool _isScrolling = false;
  double _lastScrollOffset = 0.0;
  bool _showScrollToTop = false;

  // View mode toggle - grid, list or map
  bool _isGridView = false;
  bool _isMapView = false;
  GoogleMapController? _mapController;

  bool _isLoadingMoreExplore = false;

  /// Changes hero photo index for each place when Explore feed is refreshed.
  int _explorePlacePhotoRefreshSeed = 0;

  /// How many places to show in list/grid (capped by filtered list length).
  int _exploreVisiblePlaceCount = _kExplorePageSize;

  bool _backgroundExploreRefresh = false;
  final Queue<Place> _exploreRichPrewarmQueue = Queue<Place>();
  final Set<String> _exploreRichPrewarmQueuedIds = <String>{};
  bool _exploreRichPrewarmRunning = false;

  bool _exploreBulkSeedInFlight = false;
  String? _exploreBulkSeedGateCity;
  bool _exploreBulkSeedRanForGateCity = false;

  /// Dedupes partner listing view RPCs for the same visible Explore slice.
  String? _partnerListingViewsTrackedSig;

  /// Dedupes partner listing fetches so we don't call setState in build()
  /// for the same city+filters slice.
  String? _partnerFetchSig;
  List<PartnerListing> _partnerMoodMatches = const [];
  List<PartnerListing> _partnerTrending = const [];
  bool _partnerLoading = false;

  /// Incremented on pull-to-refresh so the feed re-shuffles within open/closed tiers
  /// (opening-only sort alone kept the same place on top every time).
  ///
  /// Shuffle uses this as a **seed** on every [_filterPlaces] call (deterministic per
  /// generation). Do not "consume" shuffle only once per refresh: [build] calls
  /// [_filterPlaces] more than once (e.g. activitiesCount then list body); the first
  /// call used to steal the shuffle and the visible list stayed sorted-only.
  int _explorePullRefreshGeneration = 0;

  late final List<_ExploreSectionData> _sections = [
    _ExploreSectionData(id: 'food'),
    _ExploreSectionData(id: 'trending'),
    _ExploreSectionData(id: 'solo'),
    _ExploreSectionData(id: 'different'),
  ];

  // Advanced filter settings - New Structure
  int _activeFiltersCount = 0;

  // Expandable sections — open by default so every filter chip is visible.
  bool _advancedSuggestionsExpanded = false;
  bool _dietaryExpanded = true;
  bool _accessibilityExpanded = true;
  bool _logisticsExpanded = false;
  bool _photoExpanded = false;

  // Moody Suggests filters
  String? _selectedMood; // Keep for backward compatibility
  bool _indoorOnly = false;
  bool _outdoorOnly = false;
  bool _weatherSafe = false;
  bool _openNow = false;
  bool _crowdQuiet = false;
  bool _crowdLively = false;
  bool _romanticVibe = false;
  bool _surpriseMe = false;

  // Dietary Preferences
  bool _vegan = false;
  bool _vegetarian = false;
  bool _halal = false;
  bool _glutenFree = false;
  bool _pescatarian = false;
  bool _noAlcohol = false;

  // Accessibility & Inclusion
  bool _wheelchairAccessible = false;
  bool _lgbtqFriendly = false;
  bool _sensoryFriendly = false;
  bool _seniorFriendly = false;
  bool _familyFriendly = false;
  bool _babyFriendly = false;
  bool _blackOwned = false;

  // Quick filter state (used primarily in map view, but applied globally)
  bool _quickFilterDistance1km = false;
  bool _quickFilterRating45 = false;

  // Comfort & Convenience
  // Price Range - Multi-select
  // Price Range slider (€0 to €100)
  RangeValues _priceRange = const RangeValues(0, 100);

  // Distance slider (0 to 50 km)
  double _maxDistance = 25.0;

  bool _parkingAvailable = false;
  bool _transportIncluded = false;
  bool _creditCards = false;
  bool _wifiAvailable = false;
  bool _chargingPoints = false;

  // Photo Options
  bool _instagrammable = false;
  bool _artisticDesign = false;
  bool _aestheticSpaces = false;
  bool _scenicViews = false;
  bool _bestAtNight = false;
  bool _bestAtSunset = false;

  final List<String> _categories = [
    'all',
    'popular',
    'walking_tours',
    'museums',
    'boat_tours',
    'landmarks',
    'events',
  ];

  final Map<String, String> _filterIcons = {
    'all': '🌟',
    'popular': '🔥',
    'walking_tours': '🚶',
    'museums': '🏛️',
    'boat_tours': '⛵',
    'landmarks': '📍',
    'events': '🎉',
  };

  @override
  void initState() {
    super.initState();
    if (_selectedCategory == 'Accommodations') {
      _selectedCategory = 'all';
      _searchFilter = 'all';
    }
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScrollChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!kLockExploreCityToRotterdam) {
        ref.read(locationNotifierProvider.notifier).getCurrentLocation();
      }
      _scheduleLoadSectionsIfReady();
    });
    _explorePlacePhotoRefreshSeed = math.Random().nextInt(2000000000);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _manualCityPickSubscription ??=
        ref.listenManual<int>(exploreManualCityPickTickProvider, (prev, next) {
      if (prev != null && prev != next) {
        ref.read(exploreSessionAnchorProvider.notifier).state = null;
        unawaited(_onManualCityChangedExplore());
      }
    });
    _externalSearchIntentSubscription ??=
        ref.listenManual<String?>(exploreSearchIntentProvider, (prev, next) {
      final q = next?.trim();
      if (q == null || q.isEmpty) return;
      _applyExternalSearchIntent(q);
      ref.read(exploreSearchIntentProvider.notifier).state = null;
    });
  }

  @override
  void dispose() {
    _manualCityPickSubscription?.close();
    _externalSearchIntentSubscription?.close();
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _mapController?.dispose();
    _exploreRichPrewarmQueue.clear();
    _exploreRichPrewarmQueuedIds.clear();
    super.dispose();
  }

  void _enqueueVisibleRichPrewarm(List<Place> visiblePlaces) {
    for (final place in visiblePlaces) {
      final id = place.id.trim();
      if (id.isEmpty) continue;
      if (_exploreRichPrewarmQueuedIds.add(id)) {
        _exploreRichPrewarmQueue.add(place);
      }
    }
    if (_exploreRichPrewarmRunning) return;
    _exploreRichPrewarmRunning = true;
    unawaited(_runExploreRichPrewarmQueue());
  }

  /// Partner analytics: first visible cards only, once per distinct slice.
  void _trackPartnerListingViewsForVisibleSlice(List<Place> visiblePlaces) {
    final sample = visiblePlaces.take(6).toList();
    if (sample.isEmpty) return;
    final sig =
        '${_searchResults != null ? 'q' : 'e'}|$_explorePullRefreshGeneration|${sample.map((p) => p.id).join('|')}';
    if (_partnerListingViewsTrackedSig == sig) return;
    _partnerListingViewsTrackedSig = sig;
    for (final card in sample) {
      final id = card.id.trim();
      if (id.isEmpty) continue;
      unawaited(BusinessListingTracker.trackView(id));
    }
  }

  List<String> _activeMoodFiltersForPartners() {
    final out = <String>[];
    if (_selectedMood != null && _selectedMood!.trim().isNotEmpty) {
      out.add(_selectedMood!.trim().toLowerCase());
    }
    return out;
  }

  String _normalizePartnerPlaceId(String raw) {
    final t = raw.trim();
    if (t.startsWith('google_')) return t.substring('google_'.length);
    return t;
  }

  /// UI test fallback: when partner listings are empty, still render the partner
  /// row/carousel using normal Explore places (so we can verify layout/insertion).
  List<PartnerListing> _mockPartnerListingsForUi({
    required List<Place> places,
    required String city,
    required int limit,
  }) {
    final src = places.take(limit).toList();
    return src
        .map((p) => PartnerListing(
              id: 'ui_test_${p.id}',
              businessName: p.name,
              placeId: p.id,
              city: city,
              targetMoods: const [],
              activeOffer: null,
              customDescription: null,
              isFeaturedThisWeek: false,
              showNewBadge: false,
              hasActiveOffer: false,
              totalViews: 0,
              totalTaps: 0,
              totalCheckins: 0,
            ))
        .toList();
  }

  Future<void> _refreshPartnerDataForCity(String city) async {
    if (_partnerLoading) return;
    _partnerLoading = true;
    final moods = _activeMoodFiltersForPartners();
    try {
      final results = await Future.wait([
        PartnerListingService.getMatchingMoods(city, moods),
        PartnerListingService.getTrending(city),
      ]);
      if (!mounted) return;
      setState(() {
        _partnerMoodMatches = results[0] as List<PartnerListing>;
        _partnerTrending = results[1] as List<PartnerListing>;
      });
    } catch (_) {
      // Optional data layer; ignore failures.
    } finally {
      _partnerLoading = false;
    }
  }

  Future<void> _runExploreRichPrewarmQueue() async {
    try {
      while (mounted && _exploreRichPrewarmQueue.isNotEmpty) {
        final batch = <Place>[];
        while (batch.length < _kExplorePrewarmBatchSize &&
            _exploreRichPrewarmQueue.isNotEmpty) {
          batch.add(_exploreRichPrewarmQueue.removeFirst());
        }
        await Future.wait(
          batch.map((p) async {
            try {
              await ref.read(moodyPlaceCardUiDescriptionProvider(p).future);
            } catch (_) {
              // Keep Explore responsive: copy prewarm failures should never block UI.
            }
          }),
        );
      }
    } finally {
      _exploreRichPrewarmRunning = false;
      if (mounted && _exploreRichPrewarmQueue.isNotEmpty) {
        _exploreRichPrewarmRunning = true;
        unawaited(_runExploreRichPrewarmQueue());
      }
    }
  }

  void _applyExternalSearchIntent(String query) {
    _searchDebounce?.cancel();
    _searchController.text = query;
    _searchController.selection = TextSelection.collapsed(offset: query.length);
    setState(() {
      _searchQuery = query;
      _isSearching = true;
      _searchResults = null;
      _exploreVisiblePlaceCount = _kExplorePageSize;
    });
    _performBackendSearch(query);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _isSearching = _searchQuery.isNotEmpty;
    });
  }

  Future<void> _invalidateExploreIfOnline() async {
    final connected = await ref.read(connectivityServiceProvider).isConnected;
    if (!mounted) return;
    if (!connected) {
      showOfflineSnackBar(context);
      return;
    }
    if (mounted) {
      setState(() => _explorePlacePhotoRefreshSeed++);
    }
    ref.invalidate(moodyExploreAutoProvider);
    await _onUserPulledToRefresh();
  }

  void _scheduleLoadSectionsIfReady() {
    if (!mounted) return;
    unawaited(_maybeLockSessionAnchor());
    final anchor = ref.read(exploreSessionAnchorProvider);
    final city =
        anchor?.city ?? ref.read(locationNotifierProvider).value?.trim();
    final hasPos =
        anchor != null || ref.read(userLocationProvider).value != null;
    if (city != null && city.isNotEmpty && hasPos) {
      unawaited(_loadAllSections());
    }
  }

  Future<void> _maybeLockSessionAnchor() async {
    if (kLockExploreCityToRotterdam) {
      final name = LocationService.defaultLocation['name'] as String;
      final lat = LocationService.defaultLocation['latitude'] as double;
      final lng = LocationService.defaultLocation['longitude'] as double;
      final cur = ref.read(exploreSessionAnchorProvider);
      if (cur == null ||
          cur.city.trim().toLowerCase() != name.toLowerCase() ||
          (cur.latitude - lat).abs() > 0.08 ||
          (cur.longitude - lng).abs() > 0.08) {
        ref.read(exploreSessionAnchorProvider.notifier).state =
            ExploreSessionAnchor(city: name, latitude: lat, longitude: lng);
      }
      return;
    }
    if (ref.read(exploreSessionAnchorProvider) != null) return;
    final city = ref.read(locationNotifierProvider).valueOrNull?.trim();
    final pos = ref.read(userLocationProvider).valueOrNull;
    if (city == null || city.isEmpty || pos == null) return;
    ref.read(exploreSessionAnchorProvider.notifier).state =
        ExploreSessionAnchor(
      city: city,
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
  }

  Position _positionForExploreLoad() {
    final anchor = ref.read(exploreSessionAnchorProvider);
    if (anchor != null) {
      return Position(
        latitude: anchor.latitude,
        longitude: anchor.longitude,
        timestamp: MoodyClock.now(),
        accuracy: 500,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
        isMocked: false,
      );
    }
    final pos = ref.read(userLocationProvider).value!;
    return pos;
  }

  Future<void> _onManualCityChangedExplore() async {
    await ref.read(userLocationProvider.notifier).refreshLocation();
    await ref.read(locationNotifierProvider.future);
    final city = ref.read(locationNotifierProvider).valueOrNull?.trim();
    final pos = ref.read(userLocationProvider).valueOrNull;
    if (city == null || city.isEmpty || pos == null) return;
    ref.read(exploreSessionAnchorProvider.notifier).state =
        ExploreSessionAnchor(
      city: city,
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
    if (!mounted) return;
    await _loadAllSections(resetBulkSeed: true);
  }

  Future<void> _onUserPulledToRefresh() async {
    await ref.read(userLocationProvider.notifier).refreshLocation();
    await ref.read(locationNotifierProvider.future);
    final pos = ref.read(userLocationProvider).valueOrNull;
    final anchor = ref.read(exploreSessionAnchorProvider);
    final city = ref.read(locationNotifierProvider).valueOrNull?.trim();
    if (pos != null && anchor != null) {
      final moved = Geolocator.distanceBetween(
        anchor.latitude,
        anchor.longitude,
        pos.latitude,
        pos.longitude,
      );
      if (moved >= 5000 && city != null && city.isNotEmpty) {
        ref.read(exploreSessionAnchorProvider.notifier).state =
            ExploreSessionAnchor(
          city: city,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      }
    } else if (pos != null && city != null && city.isNotEmpty) {
      ref.read(exploreSessionAnchorProvider.notifier).state =
          ExploreSessionAnchor(
        city: city,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    }
    ref.invalidate(moodyExploreAutoProvider);
    _explorePullRefreshGeneration++;
    await _loadAllSections(resetBulkSeed: true);
    if (!mounted) return;
    _rotateExploreCachedPresentation();
    unawaited(_refreshExploreStaleInBackground());
  }

  /// Pull-to-refresh: after cache-first reload, vary section order + photo seed;
  /// list order also updates via [_explorePullRefreshGeneration] in [_filterPlaces].
  void _rotateExploreCachedPresentation() {
    if (!mounted) return;
    final rng = math.Random();
    setState(() {
      _explorePlacePhotoRefreshSeed++;
      for (final s in _sections) {
        if (s.cards.length <= 1) continue;
        final copy = List<Place>.from(s.cards)..shuffle(rng);
        s.cards = copy;
      }
    });
  }

  List<Place> _mergePlaces(List<Place> existing, List<Place> incoming) {
    final seen = <String>{};
    final out = <Place>[];
    for (final p in [...existing, ...incoming]) {
      if (p.id.isEmpty) continue;
      if (seen.add(p.id)) out.add(p);
    }
    return out;
  }

  /// After the four section rows load, optionally call moody [getExplore] a few
  /// more times (discovery + rotating named filters) until the merged unique
  /// pool reaches [_kExploreSeedTargetMin] or [maxExtraCalls] is hit. Writes
  /// go through the same moody → `places_cache` path as normal Explore.
  ///
  /// Runs at most once per [ExploreSessionAnchor] city per state lifetime so
  /// tab revisits do not spam the edge function.
  Future<void> _maybeBulkSeedExplorePool() async {
    if (!mounted || _exploreBulkSeedInFlight) return;
    if (_searchResults != null) return;

    final mapFilters = ref.read(moodyExploreBackendFiltersProvider);
    final namedScaffold = ref.read(moodyExploreBackendNamedFiltersProvider);
    if (mapFilters.isNotEmpty || namedScaffold.isNotEmpty) return;

    if (_allCards.length >= _kExploreSeedTargetMin) return;

    await _maybeLockSessionAnchor();
    final anchor = ref.read(exploreSessionAnchorProvider);
    final city =
        (anchor?.city ?? ref.read(locationNotifierProvider).value)?.trim() ??
            '';
    if (city.isEmpty) return;

    if (_exploreBulkSeedGateCity != city) {
      _exploreBulkSeedGateCity = city;
      _exploreBulkSeedRanForGateCity = false;
    }
    if (_exploreBulkSeedRanForGateCity) return;

    final pos = anchor != null
        ? _positionForExploreLoad()
        : ref.read(userLocationProvider).value;
    if (pos == null) return;

    final online = await ref.read(connectivityServiceProvider).isConnected;
    if (!online || !mounted) return;

    _exploreBulkSeedInFlight = true;
    try {
      final service = ref.read(moodyEdgeFunctionServiceProvider);
      final notifier = ref.read(placesServiceProvider.notifier);
      final lang = PlacesCacheUtils.effectiveExploreLanguageTag(
        appLocale: ref.read(localeProvider),
      );

      const tags = <String>[
        'cultural',
        'foodie',
        'outdoor',
        'nightlife',
        'wellness',
        'trendy',
        'solo',
        'family',
        'romantic',
        'budget',
      ];

      var round = 0;
      while (mounted &&
          _allCards.length < _kExploreSeedTargetMin &&
          round < _kExploreBulkSeedMaxExtraCalls) {
        round++;
        List<Place> more;
        if (round == 1) {
          more = await service.getExplore(
            location: city,
            latitude: pos.latitude,
            longitude: pos.longitude,
            section: 'discovery',
            languageCode: lang,
          );
        } else {
          final tag = tags[(round - 2) % tags.length];
          more = await service.getExplore(
            location: city,
            latitude: pos.latitude,
            longitude: pos.longitude,
            section: 'discovery',
            namedFilters: <String>[tag],
            languageCode: lang,
          );
        }
        if (!mounted) return;
        if (more.isEmpty) continue;

        for (final p in more) {
          notifier.cachePlaceObject(p);
        }
        setState(() {
          final last = _sections.last;
          last.cards = _mergePlaces(last.cards, more);
          last.isLoading = false;
          last.hasError = false;
        });
      }
    } catch (e, st) {
      debugPrint('Explore bulk seed: $e\n$st');
    } finally {
      _exploreBulkSeedRanForGateCity = true;
      _exploreBulkSeedInFlight = false;
    }
  }

  /// Reveal next page of already-loaded places, or fetch more (main feed only).
  Future<void> _onExploreLoadMoreTap(int filteredTotal) async {
    if (_isLoadingMoreExplore || _isMapView) return;
    HapticFeedback.selectionClick();
    final visible = math.min(_exploreVisiblePlaceCount, filteredTotal);
    if (visible < filteredTotal) {
      setState(() {
        _exploreVisiblePlaceCount = math.min(
          _exploreVisiblePlaceCount + _kExplorePageSize,
          filteredTotal,
        );
      });
      return;
    }
    if (_searchResults != null) return;
    if (filteredTotal < _kExplorePageSize) return;
    // Strict cache-first behavior: when currently loaded cards are exhausted,
    // stop instead of triggering extra fetches from scroll/load-more.
    // This keeps Explore pagination local to the seeded/cached pool.
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exploreEndOfCachedPool)),
      );
    }
  }

  Future<void> _loadAllSections({bool resetBulkSeed = false}) async {
    if (!mounted) return;
    if (resetBulkSeed) {
      _exploreBulkSeedRanForGateCity = false;
      _exploreBulkSeedGateCity = null;
    }
    await _maybeLockSessionAnchor();
    final anchor = ref.read(exploreSessionAnchorProvider);
    final cityForCache = anchor?.city ??
        ref.read(locationNotifierProvider).valueOrNull?.trim() ??
        '';

    final connected = await ref.read(connectivityServiceProvider).isConnected;
    if (!connected) {
      await _loadAllSectionsOffline();
      return;
    }

    final filters = ref.read(moodyExploreBackendFiltersProvider);
    final namedFilters = ref.read(moodyExploreBackendNamedFiltersProvider);
    final skipPlacesCacheFirstPass =
        filters.isNotEmpty || namedFilters.isNotEmpty;

    // Always try Supabase `places_cache` first when no advanced filters —
    // never skip this path for "refresh" (pull-to-refresh uses cache + rotate;
    // moody Edge runs only inside getExplore / deferred stale refresh).
    if (!skipPlacesCacheFirstPass && cityForCache.isNotEmpty && mounted) {
      final client = Supabase.instance.client;
      final exploreLang = PlacesCacheUtils.effectiveExploreLanguageTag(
        appLocale: ref.read(localeProvider),
      );
      final isLocal = await PlacesCacheUtils.readExploreIsLocalMode(client);

      final hits = await Future.wait(
        _sections.map(
          (s) => PlacesCacheUtils.tryLoadExplorePlacesHit(
            client,
            s.id,
            cityForCache,
            isLocalMode: isLocal,
            languageCode: exploreLang,
          ),
        ),
      );

      if (!mounted) return;

      final anyHit = hits.any((h) => h != null && h.places.isNotEmpty);
      if (anyHit) {
        final needBackground =
            hits.any((h) => h?.shouldRefreshInBackground == true);
        setState(() {
          _exploreVisiblePlaceCount = _kExplorePageSize;
          for (var i = 0; i < _sections.length; i++) {
            final hit = hits[i];
            final list = hit?.places ?? const <Place>[];
            _sections[i].cards = List<Place>.from(list);
            _sections[i].hasError = false;
            _sections[i].isLoading = list.isEmpty;
            for (final p in list) {
              ref.read(placesServiceProvider.notifier).cachePlaceObject(p);
            }
          }
        });
        final allFilled = _sections.every((s) => !s.isLoading);
        if (allFilled) {
          if (needBackground) {
            unawaited(_refreshExploreStaleInBackground());
          }
          unawaited(_maybeBulkSeedExplorePool());
          return;
        }
        if (needBackground) {
          unawaited(_refreshExploreStaleInBackground());
        }
        await Future.wait(
          _sections.where((s) => s.isLoading).map((s) => _loadSection(s)),
        );
        if (mounted) {
          unawaited(_maybeBulkSeedExplorePool());
        }
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _exploreVisiblePlaceCount = _kExplorePageSize;
      for (final s in _sections) {
        final keepCards = s.cards.isNotEmpty;
        s.isLoading = !keepCards;
        s.hasError = false;
      }
    });
    await Future.wait(
      _sections.map(
        (s) => _loadSection(s),
      ),
    );
    if (mounted) {
      unawaited(_maybeBulkSeedExplorePool());
    }
  }

  Future<void> _refreshExploreStaleInBackground() async {
    if (_backgroundExploreRefresh || !mounted) return;
    _backgroundExploreRefresh = true;
    try {
      await Future.wait(
        _sections.map(
          (s) => _loadSection(s, silent: true, skipPlacesCache: true),
        ),
      );
    } finally {
      _backgroundExploreRefresh = false;
    }
  }

  Future<void> _loadAllSectionsOffline() async {
    final city = ref.read(locationNotifierProvider).value?.trim() ?? '';
    if (city.isEmpty || !mounted) return;
    final exploreLang = PlacesCacheUtils.effectiveExploreLanguageTag(
      appLocale: ref.watch(localeProvider),
    );
    final client = Supabase.instance.client;
    setState(() {
      _exploreVisiblePlaceCount = _kExplorePageSize;
      for (final s in _sections) {
        s.isLoading = true;
        s.hasError = false;
      }
    });
    for (final s in _sections) {
      final cached = await PlacesCacheUtils.tryLoadExplorePlaces(
        client,
        s.id,
        city,
        languageCode: exploreLang,
      );
      if (!mounted) return;
      setState(() {
        s.cards = cached ?? [];
        s.isLoading = false;
        s.hasError = cached == null || cached.isEmpty;
      });
    }
  }

  Future<void> _loadSection(
    _ExploreSectionData section, {
    bool append = false,
    bool silent = false,
    bool skipPlacesCache = false,
  }) async {
    if (!mounted) return;
    await _maybeLockSessionAnchor();
    final anchor = ref.read(exploreSessionAnchorProvider);
    final city =
        anchor?.city ?? ref.read(locationNotifierProvider).value?.trim() ?? '';
    final position = anchor != null
        ? _positionForExploreLoad()
        : ref.read(userLocationProvider).value;
    if (city.isEmpty || position == null) {
      setState(() {
        section.isLoading = false;
        section.hasError = true;
      });
      return;
    }

    final exploreLang = PlacesCacheUtils.effectiveExploreLanguageTag(
      appLocale: ref.watch(localeProvider),
    );
    final connected = await ref.read(connectivityServiceProvider).isConnected;
    if (!connected) {
      final cached = await PlacesCacheUtils.tryLoadExplorePlaces(
        Supabase.instance.client,
        section.id,
        city,
        languageCode: exploreLang,
      );
      if (!mounted) return;
      final list = cached ?? [];
      final notifier = ref.read(placesServiceProvider.notifier);
      for (final p in list) {
        notifier.cachePlaceObject(p);
      }
      setState(() {
        section.cards =
            append ? _mergePlaces(section.cards, list) : List<Place>.from(list);
        section.isLoading = false;
        section.hasError = list.isEmpty;
      });
      return;
    }

    if (!silent) {
      setState(() {
        section.isLoading = true;
        section.hasError = false;
        if (!append) section.cards = [];
      });
    }

    final filters = ref.read(moodyExploreBackendFiltersProvider);
    final namedFilters = ref.read(moodyExploreBackendNamedFiltersProvider);
    final service = ref.read(moodyEdgeFunctionServiceProvider);
    try {
      final places = await service.getExplore(
        location: city,
        latitude: position.latitude,
        longitude: position.longitude,
        section: section.id,
        filters: filters.isEmpty ? null : filters,
        namedFilters: namedFilters.isEmpty ? null : namedFilters,
        languageCode: exploreLang,
        bypassPlacesCache: skipPlacesCache,
      );
      if (!mounted) return;
      final notifier = ref.read(placesServiceProvider.notifier);
      for (final p in places) {
        notifier.cachePlaceObject(p);
      }
      setState(() {
        section.cards = append
            ? _mergePlaces(section.cards, places)
            : List<Place>.from(places);
        section.isLoading = false;
      });
    } catch (e, st) {
      debugPrint('Explore section ${section.id} error: $e\n$st');
      final cached = await PlacesCacheUtils.tryLoadExplorePlaces(
        Supabase.instance.client,
        section.id,
        city,
        languageCode: exploreLang,
      );
      if (!mounted) return;
      final list = cached ?? [];
      final notifier = ref.read(placesServiceProvider.notifier);
      for (final p in list) {
        notifier.cachePlaceObject(p);
      }
      setState(() {
        section.cards =
            append ? _mergePlaces(section.cards, list) : List<Place>.from(list);
        section.isLoading = false;
        section.hasError = list.isEmpty;
      });
    }
  }

  List<Place> get _allCards {
    final seen = <String>{};
    final all = <Place>[];
    for (final section in _sections) {
      for (final card in section.cards) {
        if (card.id.isEmpty) continue;
        if (seen.add(card.id)) all.add(card);
      }
    }
    return all;
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    final currentScrollOffset = _scrollController.offset;
    final scrollDelta = currentScrollOffset - _lastScrollOffset;
    _lastScrollOffset = currentScrollOffset;

    final shouldShow = currentScrollOffset > 400;
    var newShowScrollToTop = _showScrollToTop;
    var newIsScrolling = _isScrolling;

    if (shouldShow != _showScrollToTop) {
      newShowScrollToTop = shouldShow;
    }

    if (scrollDelta > 10 && !_isScrolling) {
      newIsScrolling = true;
    } else if (scrollDelta < -5 || scrollDelta.abs() < 1) {
      // Only clear when we're actually in a "scrolling" state. The old branch
      // called setState on almost every notification with delta near zero even
      // when already false — that spammed rebuilds during NestedScrollView /
      // pointer handling and contributed to semantics cascades.
      if (_isScrolling) {
        newIsScrolling = false;
      }
    }

    if (newShowScrollToTop != _showScrollToTop ||
        newIsScrolling != _isScrolling) {
      setState(() {
        _showScrollToTop = newShowScrollToTop;
        _isScrolling = newIsScrolling;
      });
    }
  }

  void _onConversationalSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });

    _searchDebounce?.cancel();

    if (query.trim().length < 3) {
      // Clear search — restore normal explore feed
      if (mounted) {
        setState(() {
          _searchResults = null;
          _exploreVisiblePlaceCount = _kExplorePageSize;
        });
      }
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 600), () {
      _performBackendSearch(query.trim());
    });
  }

  Future<void> _performBackendSearch(String query) async {
    final locationAsync = ref.read(locationNotifierProvider);
    final city = locationAsync.value ?? '';
    if (city.isEmpty) return;

    final positionAsync = ref.read(userLocationProvider);
    final position = positionAsync.value;
    if (position == null) return;

    final connected = await ref.read(connectivityServiceProvider).isConnected;
    if (!connected) {
      if (mounted) showOfflineSnackBar(context);
      return;
    }

    final supabase = Supabase.instance.client;

    if (!mounted) return;
    setState(() => _isSearching = true);

    try {
      final response =
          await supabase.functions.invoke(SupabaseConfig.moodyFunction, body: {
        'action': 'search',
        'query': query,
        'location': city,
        'coordinates': {
          'lat': position.latitude,
          'lng': position.longitude,
        },
      });

      if (!mounted) return;

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final cards = (data['cards'] as List<dynamic>?) ?? [];
        final related = (data['related_searches'] as List<dynamic>?)
                ?.whereType<String>()
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList() ??
            const <String>[];
        final places = cards.map((c) {
          final m = c is Map<String, dynamic>
              ? c
              : Map<String, dynamic>.from(c as Map);
          return PlacesCacheUtils.placeFromMoodyExploreCard(m);
        }).toList();
        setState(() {
          _searchResults = places;
          _relatedSearchOptions = related;
          _isSearching = false;
          _exploreVisiblePlaceCount = _kExplorePageSize;
        });
      } else {
        setState(() {
          _searchResults = [];
          _relatedSearchOptions = const [];
          _isSearching = false;
          _exploreVisiblePlaceCount = _kExplorePageSize;
        });
      }
    } catch (e) {
      debugPrint('🔍 Search error: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
      _searchFilter = 'all';
      _searchResults = null;
      _relatedSearchOptions = const [];
      _exploreVisiblePlaceCount = _kExplorePageSize;
    });
  }

  void _applyRelatedSearchOption(String option) {
    _searchDebounce?.cancel();
    _searchController.text = option;
    _searchController.selection =
        TextSelection.collapsed(offset: option.length);
    setState(() {
      _searchQuery = option;
      _isSearching = true;
      _searchResults = null;
      _exploreVisiblePlaceCount = _kExplorePageSize;
    });
    _performBackendSearch(option);
  }

  void _updateActiveFiltersCount() {
    int count = 0;

    // Moody Suggests filters
    if (_selectedMood != null) count++;
    if (_indoorOnly) count++;
    if (_outdoorOnly) count++;
    if (_openNow) count++;
    if (_crowdQuiet) count++;
    if (_crowdLively) count++;
    if (_romanticVibe) count++;
    if (_surpriseMe) count++;

    // Dietary Preferences
    if (_vegan) count++;
    if (_vegetarian) count++;
    if (_halal) count++;
    if (_glutenFree) count++;
    if (_pescatarian) count++;
    if (_noAlcohol) count++;

    // Accessibility & Inclusion
    if (_wheelchairAccessible) count++;
    if (_lgbtqFriendly) count++;
    if (_sensoryFriendly) count++;
    if (_seniorFriendly) count++;
    if (_familyFriendly) count++;
    if (_babyFriendly) count++;
    if (_blackOwned) count++;

    // Comfort & Convenience
    // Count price range if not default (0-100)
    if (_priceRange.start != 0 || _priceRange.end != 100) count++;
    // Count distance if not default (25 km)
    if (_maxDistance != 25.0) count++;
    if (_parkingAvailable) count++;
    if (_wifiAvailable) count++;

    // Photo Options
    if (_instagrammable) count++;
    if (_artisticDesign) count++;
    if (_aestheticSpaces) count++;
    if (_scenicViews) count++;

    setState(() {
      _activeFiltersCount = count;
    });
  }

  // Per-section active filter counts — used for badge indicators.
  int get _quickSuggestionsActiveCount {
    int n = 0;
    if (_selectedMood != null) n++;
    if (_indoorOnly) n++;
    if (_outdoorOnly) n++;
    if (_openNow) n++;
    if (_crowdQuiet) n++;
    if (_crowdLively) n++;
    if (_romanticVibe) n++;
    if (_surpriseMe) n++;
    return n;
  }

  int get _dietaryActiveCount {
    int n = 0;
    if (_vegan) n++;
    if (_vegetarian) n++;
    if (_halal) n++;
    if (_glutenFree) n++;
    if (_pescatarian) n++;
    if (_noAlcohol) n++;
    return n;
  }

  int get _accessibilityActiveCount {
    int n = 0;
    if (_wheelchairAccessible) n++;
    if (_lgbtqFriendly) n++;
    if (_sensoryFriendly) n++;
    if (_seniorFriendly) n++;
    if (_familyFriendly) n++;
    if (_babyFriendly) n++;
    if (_blackOwned) n++;
    return n;
  }

  int get _comfortActiveCount {
    int n = 0;
    if (_priceRange.start != 0 || _priceRange.end != 100) n++;
    if (_maxDistance != 25.0) n++;
    if (_parkingAvailable) n++;
    if (_wifiAvailable) n++;
    return n;
  }

  int get _photoActiveCount {
    int n = 0;
    if (_instagrammable) n++;
    if (_artisticDesign) n++;
    if (_aestheticSpaces) n++;
    if (_scenicViews) n++;
    return n;
  }

  void _clearAllFilters() {
    setState(() {
      // Moody Suggests filters
      _selectedMood = null;
      _indoorOnly = false;
      _outdoorOnly = false;
      _weatherSafe = false;
      _openNow = false;
      _crowdQuiet = false;
      _crowdLively = false;
      _romanticVibe = false;
      _surpriseMe = false;

      // Dietary Preferences
      _vegan = false;
      _vegetarian = false;
      _halal = false;
      _glutenFree = false;
      _pescatarian = false;
      _noAlcohol = false;

      // Accessibility & Inclusion
      _wheelchairAccessible = false;
      _lgbtqFriendly = false;
      _sensoryFriendly = false;
      _seniorFriendly = false;
      _familyFriendly = false;
      _babyFriendly = false;
      _blackOwned = false;

      // Comfort & Convenience
      _priceRange = const RangeValues(0, 100);
      _maxDistance = 25.0;
      _parkingAvailable = false;
      _transportIncluded = false;
      _creditCards = false;
      _wifiAvailable = false;
      _chargingPoints = false;

      // Photo Options
      _instagrammable = false;
      _artisticDesign = false;
      _aestheticSpaces = false;
      _scenicViews = false;
      _bestAtNight = false;
      _bestAtSunset = false;

      _activeFiltersCount = 0;
      _exploreVisiblePlaceCount = _kExplorePageSize;
    });
    ref.read(moodyExploreBackendFiltersProvider.notifier).state =
        <String, dynamic>{};
    ref.read(moodyExploreBackendNamedFiltersProvider.notifier).state = [];
    unawaited(_invalidateExploreIfOnline());
  }

  Map<String, dynamic> _buildMoodyBackendFilters() {
    final filters = <String, dynamic>{};

    if (_quickFilterRating45) {
      filters['rating'] = 4.5;
    }
    if (_openNow) {
      filters['openNow'] = true;
    }
    if (_maxDistance != 25.0) {
      filters['radius'] = (_maxDistance * 1000).clamp(1000, 50000).round();
    }
    if (_priceRange.end < 100) {
      final end = _priceRange.end;
      final maxPriceLevel = end <= 15
          ? 1
          : end <= 30
              ? 2
              : end <= 50
                  ? 3
                  : 4;
      filters['priceLevel'] = maxPriceLevel;
    }

    final includeTypes = <String>[];
    final excludeTypes = <String>[];

    if (_outdoorOnly) {
      includeTypes.addAll(['park', 'tourist_attraction', 'natural_feature']);
    }
    if (_indoorOnly) {
      excludeTypes.addAll(['park', 'campground', 'zoo']);
    }
    if ((_selectedMood ?? '').toLowerCase() == 'relaxed') {
      excludeTypes.addAll(['gym', 'fitness_center']);
    }
    if (includeTypes.isNotEmpty) {
      filters['types'] = includeTypes;
    }
    if (excludeTypes.isNotEmpty) {
      filters['excludeTypes'] = excludeTypes;
    }

    // Dietary / inclusion / logistics / vibe slugs go to moody `namedFilters`
    // (see _buildMoodyNamedFilters).
    final requiredKeywords = <String>[];
    if (requiredKeywords.isNotEmpty) {
      filters['requiredKeywords'] = requiredKeywords;
    }

    return filters;
  }

  /// Slugs aligned with moody `getFilterSearchQueries` / `filterByNamedFilter`.
  List<String> _buildMoodyNamedFilters() {
    final out = <String>[];
    void add(String s) {
      if (!out.contains(s)) out.add(s);
    }

    if (_vegan) add('vegan');
    if (_vegetarian) add('vegetarian');
    if (_halal) add('halal');
    if (_glutenFree) add('gluten_free');
    if (_pescatarian) add('pescatarian');
    if (_instagrammable) add('instagrammable');
    if (_romanticVibe) add('romantic');
    if (_aestheticSpaces) add('aesthetic_spaces');
    if (_artisticDesign) add('artistic_design');
    if (_scenicViews) add('scenic_views');
    if (_blackOwned) add('black_owned');
    if (_lgbtqFriendly) add('lgbtq_friendly');
    if (_familyFriendly) add('family_friendly');
    if (_babyFriendly) add('kids_friendly');
    if (_wheelchairAccessible) add('wheelchair_accessible');
    if (_sensoryFriendly) add('sensory_friendly');
    if (_seniorFriendly) add('senior_friendly');
    if (_wifiAvailable) add('wifi');
    if (_parkingAvailable) add('parking');
    if (_crowdQuiet) add('quiet');
    if (_crowdLively) add('lively');
    if (_surpriseMe) add('surprise_me');
    if (_noAlcohol) add('no_alcohol');

    return out;
  }

  void _showAdvancedFilters() {
    HapticFeedback.lightImpact();
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _buildAdvancedFilterModal();
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Opens place quick sheet (same body as full detail) + CTAs; full route on demand.
  void _openPlaceFromExplore(Place place) {
    String normalizedId(String raw) {
      final t = raw.trim();
      if (t.startsWith('google_')) return t;
      if (t.startsWith('ChIJ') || t.startsWith('EhIJ')) return 'google_$t';
      return t;
    }

    final targetId = normalizedId(place.id);
    HapticFeedback.lightImpact();
    unawaited(_trackExploreTasteInteraction(place, 'tapped'));
    final seeded = targetId != place.id ? place.copyWith(id: targetId) : place;
    ref.read(placesServiceProvider.notifier).cachePlaceObject(seeded);

    final l10n = AppLocalizations.of(context)!;
    unawaited(
      showPlaceQuickDetailSheet(
        context,
        place: seeded,
        footerBuilder: (pop) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        pop();
                        unawaited(_openDirectionsForPlace(seeded));
                      },
                      icon: const Icon(Icons.directions),
                      label: Text(l10n.activityDetailDirections),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A6049),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        pop();
                        _showAddToMyDaySheet(seeded);
                      },
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(l10n.placeQuickSheetAddToMyDayCta),
                      style: placeQuickSheetSecondaryFilledButtonStyle(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  pop();
                  if (!mounted) return;
                  context.push('/place/$targetId');
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                label: Text(l10n.myDayOpenFullPlaceDetails),
                style: placeQuickSheetOutlinedButtonStyle(),
              ),
            ],
          );
        },
      ),
    );
  }

  Uri _exploreGoogleWebDirectionsUri(double? lat, double? lng, String title) {
    if (lat != null && lng != null && (lat.abs() > 1e-5 || lng.abs() > 1e-5)) {
      return Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
    }
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(title)}',
    );
  }

  Uri _exploreGoogleAppDirectionsUri(double? lat, double? lng, String title) {
    if (lat != null && lng != null && (lat.abs() > 1e-5 || lng.abs() > 1e-5)) {
      return Uri.parse(
        'comgooglemaps://?daddr=$lat,$lng&directionsmode=driving',
      );
    }
    return Uri.parse('comgooglemaps://?q=${Uri.encodeComponent(title)}');
  }

  Uri _exploreAppleMapsUri(double? lat, double? lng, String title) {
    if (lat != null && lng != null && (lat.abs() > 1e-5 || lng.abs() > 1e-5)) {
      return Uri.parse('maps://?q=${Uri.encodeComponent(title)}&ll=$lat,$lng');
    }
    return Uri.parse('maps://?q=${Uri.encodeComponent(title)}');
  }

  Future<void> _openDirectionsForPlace(Place place) async {
    final l10n = AppLocalizations.of(context)!;
    final lat = place.location.lat;
    final lng = place.location.lng;
    final title = place.name;

    try {
      final appleUri = _exploreAppleMapsUri(lat, lng, title);
      final googleAppUri = _exploreGoogleAppDirectionsUri(lat, lng, title);
      final googleWebUri = _exploreGoogleWebDirectionsUri(lat, lng, title);

      final canOpenApple = await canLaunchUrl(appleUri);
      final canOpenGoogleApp = await canLaunchUrl(googleAppUri);

      if (!mounted) return;

      final options = <({String label, Uri uri})>[
        (
          label: l10n.myDayOpenGoogleMaps,
          uri: canOpenGoogleApp ? googleAppUri : googleWebUri,
        ),
        if (canOpenApple)
          (
            label: l10n.myDayOpenAppleMaps,
            uri: appleUri,
          ),
      ];

      if (options.length == 1) {
        await launchUrl(
          options.first.uri,
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E2D8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.myDayDirectionsNavigateTitle,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1C18),
                ),
              ),
              const SizedBox(height: 8),
              ...options.map(
                (opt) => ListTile(
                  leading:
                      const Icon(Icons.map_outlined, color: Color(0xFF2A6049)),
                  title: Text(
                    opt.label,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E1C18),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await launchUrl(opt.uri,
                        mode: LaunchMode.externalApplication);
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showMoodyToast(context, l10n.placeDetailOpenMaps);
    }
  }

  Future<void> _trackExploreTasteInteraction(
    Place place,
    String interactionType,
  ) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final now = MoodyClock.now();
    final hour = now.hour;
    final timeSlot = hour < 12
        ? 'morning'
        : hour < 17
            ? 'afternoon'
            : 'evening';
    final allTypes = <String>{
      ...place.types,
      if ((place.primaryType ?? '').trim().isNotEmpty)
        place.primaryType!.trim(),
    }.toList();

    try {
      await Supabase.instance.client.rpc(
        'update_taste_profile',
        params: {
          'p_user_id': user.id,
          'p_place_id': place.id,
          'p_place_name': place.name,
          'p_place_types': allTypes,
          'p_price_level': place.priceLevel,
          'p_interaction_type': interactionType,
          'p_mood_context': _selectedMood,
          'p_time_slot': timeSlot,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ track interaction failed ($interactionType): $e');
      }
    }
  }

  String _categoryLabel(String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'all':
        return l10n.exploreCategoryAll;
      case 'popular':
        return l10n.exploreCategoryPopular;
      case 'walking_tours':
        return l10n.exploreCategoryActivities;
      case 'museums':
        return l10n.exploreCategoryCulture;
      case 'boat_tours':
        return l10n.gygCategoryBoatTours.replaceAll('⛵ ', '');
      case 'landmarks':
        return l10n.profileModeTravelFeature1;
      case 'events':
        return l10n.exploreCategoryChipNightlife;
      default:
        return key;
    }
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    final named = _effectiveNamedFiltersForCategory(category);
    ref.read(moodyExploreBackendNamedFiltersProvider.notifier).state = named;
    setState(() {
      _selectedCategory = category;
      _searchFilter = category;
      _exploreVisiblePlaceCount = _kExplorePageSize;
    });
    if (kDebugMode) {
      debugPrint(
        '🧭 Explore category="$category" mergedNamedFilters=${named.join(",")}',
      );
    }
    unawaited(_loadAllSections(resetBulkSeed: true));
  }

  void _onSearchFilterSelected(String filter) {
    setState(() {
      _searchFilter = filter;
      _selectedCategory = filter;
      _exploreVisiblePlaceCount = _kExplorePageSize;
    });
    final named = _effectiveNamedFiltersForCategory(filter);
    ref.read(moodyExploreBackendNamedFiltersProvider.notifier).state = named;
    if (kDebugMode) {
      debugPrint(
        '🧭 Explore search-filter="$filter" mergedNamedFilters=${named.join(",")}',
      );
    }
    unawaited(_loadAllSections(resetBulkSeed: true));
  }

  List<String> _namedFiltersForCategory(String category) {
    switch (category) {
      case 'walking_tours':
        return const ['walking_tours'];
      case 'museums':
        return const ['museums_exhibitions'];
      case 'boat_tours':
        return const ['boat_tours'];
      case 'landmarks':
        return const ['landmarks_viewpoints'];
      case 'events':
        return const ['events_night_out'];
      default:
        return const <String>[];
    }
  }

  /// Keep category intent + active advanced-filter slugs together.
  /// This avoids chip taps accidentally dropping dietary/accessibility filters.
  List<String> _effectiveNamedFiltersForCategory(String category) {
    final out = <String>[];
    void addAllUnique(List<String> values) {
      for (final v in values) {
        if (!out.contains(v)) out.add(v);
      }
    }

    addAllUnique(_namedFiltersForCategory(category));
    addAllUnique(_buildMoodyNamedFilters());
    return out;
  }

  void _showSearchFilterMenu() {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 200, // Position from right
        120, // Top position
        20, // Right margin
        0, // Bottom
      ),
      items: _categories.map((category) {
        return PopupMenuItem<String>(
          value: category,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _filterIcons[category] ?? '📍',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                _categoryLabel(category),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: category == _searchFilter
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: category == _searchFilter
                      ? const Color(0xFF2A6049)
                      : Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ).then((selectedFilter) {
      if (selectedFilter != null) {
        _onSearchFilterSelected(selectedFilter);
      }
    });
  }

  /// 0 = open now, 1 = no hours data, 2 = closed — for Explore list/grid/map ordering.
  int _exploreOpeningDisplayPriority(Place p) {
    final oh = p.openingHours;
    if (oh == null) {
      return 1;
    }
    return oh.isOpen ? 0 : 2;
  }

  /// Shuffle within opening-hours tiers, then rotate the "open now" tier by
  /// [generation] so pull-to-refresh reliably changes the first card when
  /// several places share the same hours tier.
  void _tieredShuffleExploreByOpening(
    List<Place> list,
    int salt,
    int generation,
  ) {
    if (list.length <= 1) return;
    final rng = math.Random(salt);
    final byTier = <int, List<Place>>{};
    for (final p in list) {
      final t = _exploreOpeningDisplayPriority(p);
      byTier.putIfAbsent(t, () => []).add(p);
    }
    for (final t in [0, 1, 2]) {
      final bucket = byTier[t];
      if (bucket == null || bucket.length <= 1) continue;
      bucket.shuffle(rng);
      if (t == 0 && bucket.length > 1) {
        final rot = generation % bucket.length;
        if (rot > 0) {
          final head = bucket.sublist(0, rot);
          final tail = bucket.sublist(rot);
          bucket
            ..clear()
            ..addAll(tail)
            ..addAll(head);
        }
      }
    }
    list..clear();
    for (final t in [0, 1, 2]) {
      final bucket = byTier[t];
      if (bucket == null) continue;
      list.addAll(bucket);
    }
  }

  /// Substring match across fields we keep on [Place] (not menus/reviews — those are not stored here).
  static bool _placeTextContainsQuery(Place place, String queryLower) {
    if (queryLower.isEmpty) return true;
    bool hay(String? s) => s != null && s.toLowerCase().contains(queryLower);
    if (hay(place.name)) return true;
    if (hay(place.description)) return true;
    if (hay(place.address)) return true;
    if (hay(place.editorialSummary)) return true;
    if (hay(place.primaryType)) return true;
    if (hay(place.socialSignal)) return true;
    if (hay(place.bestTime)) return true;
    if (hay(place.tag)) return true;
    for (final t in place.types) {
      if (t.toLowerCase().contains(queryLower)) return true;
    }
    for (final a in place.activities) {
      if (a.toLowerCase().contains(queryLower)) return true;
    }
    return false;
  }

  List<Place> _filterPlaces(
    List<Place> places, {
    bool ignoreCategory = false,
  }) {
    final initialCount = places.length;
    final preferencesService = ref.read(userPreferencesServiceProvider);

    final hour = DateTime.now().hour;
    final queryLower = _searchQuery.toLowerCase().trim();
    final trustBackendSearch = _searchResults != null && queryLower.isNotEmpty;

    var filteredPlaces = places.where((place) {
      // Always strip utility / errand places (supermarkets, pharmacies, gas stations, etc.)
      if (_isUtilityPlace(place)) return false;

      // Time-of-day soft filter when no explicit search/filter is active.
      // Only exclude breakfast-only places in the afternoon/evening and
      // late-night-only places in the morning — keeps the feed contextually relevant.
      if (_searchQuery.isEmpty && _activeFiltersCount == 0) {
        if (!_placeMatchesTimeOfDay(place, hour)) return false;
      }

      // Filter by search query: Moody `search` already used Google text search — do not
      // re-filter to name/description/address only (drops relevant hits).
      final bool matchesSearch = queryLower.isEmpty ||
          trustBackendSearch ||
          _placeTextContainsQuery(place, queryLower);

      // Apply advanced filters (mood, dietary, accessibility, etc.)
      bool matchesAdvancedFilters = _checkAdvancedFilters(place);

      final matchesCategory = ignoreCategory ||
          _selectedCategory == 'all' ||
          _checkCategoryMatch(place, _selectedCategory);

      return matchesSearch && matchesAdvancedFilters && matchesCategory;
    }).toList();

    // Open first → unknown hours → closed. When no heavy filters/search, boost
    // onboarding matches **via sort only** — do not hide other places (hiding made
    // "Nu open" + prefs often collapse to a single card that never shuffles away).
    if (_activeFiltersCount == 0 && _searchQuery.isEmpty) {
      filteredPlaces.sort((a, b) {
        final oh = _exploreOpeningDisplayPriority(a)
            .compareTo(_exploreOpeningDisplayPriority(b));
        if (oh != 0) return oh;
        final ap = preferencesService.placeMatchesInterests(a) ||
                preferencesService.placeMatchesTravelStyles(a)
            ? 0
            : 1;
        final bp = preferencesService.placeMatchesInterests(b) ||
                preferencesService.placeMatchesTravelStyles(b)
            ? 0
            : 1;
        return ap.compareTo(bp);
      });
    } else {
      filteredPlaces.sort((a, b) {
        final c = _exploreOpeningDisplayPriority(a)
            .compareTo(_exploreOpeningDisplayPriority(b));
        if (c != 0) return c;
        return 0;
      });
    }

    if (filteredPlaces.length > 1) {
      _tieredShuffleExploreByOpening(
        filteredPlaces,
        _explorePullRefreshGeneration * 524287,
        _explorePullRefreshGeneration,
      );
    } else if (kDebugMode) {
      debugPrint(
        '⚠️ Explore: only ${filteredPlaces.length} card(s) after filters '
        '(pull gen $_explorePullRefreshGeneration)',
      );
    }

    // Debug logging
    if (_activeFiltersCount > 0 || _searchQuery.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
            '🔍 Filtering: ${initialCount} → ${filteredPlaces.length} places');
        debugPrint('   Active filters: $_activeFiltersCount');
        debugPrint('   Search query: "$_searchQuery"');
      }
    }

    return filteredPlaces;
  }

  /// Apply quick filters (distance, rating) on top of existing filters
  List<Place> _applyQuickFilters(
    List<Place> places, {
    required Position? userLocation,
    required String currentCity,
  }) {
    var result = List<Place>.from(places);

    // Rating quick filter: 4.5+
    if (_quickFilterRating45) {
      result = result.where((place) => place.rating >= 4.5).toList();
    }

    // Distance quick filter: within 1km
    if (_quickFilterDistance1km) {
      // If we don't have user location, fall back to city center coordinates
      double originLat;
      double originLng;

      if (userLocation != null) {
        originLat = userLocation.latitude;
        originLng = userLocation.longitude;
      } else {
        // Simple fallback using same coordinates map as explore_places_provider
        final cityCoords = {
          'Rotterdam': {'lat': 51.9244, 'lng': 4.4777},
          'Amsterdam': {'lat': 52.3676, 'lng': 4.9041},
          'The Hague': {'lat': 52.0705, 'lng': 4.3007},
          'Utrecht': {'lat': 52.0907, 'lng': 5.1214},
          'Eindhoven': {'lat': 51.4416, 'lng': 5.4697},
          'Groningen': {'lat': 53.2194, 'lng': 6.5665},
          'Delft': {'lat': 52.0067, 'lng': 4.3556},
          'Beneden-Leeuwen': {'lat': 51.8892, 'lng': 5.5142},
        };
        final fallback = cityCoords[currentCity] ?? cityCoords['Rotterdam']!;
        originLat = fallback['lat']!;
        originLng = fallback['lng']!;
      }

      result = result.where((place) {
        final distanceKm = DistanceService.calculateDistance(
          originLat,
          originLng,
          place.location.lat,
          place.location.lng,
        );
        return distanceKm <= 1.0;
      }).toList();
    }

    return result;
  }

  bool _backendNamedFilterActive(String slug) {
    return ref.read(moodyExploreBackendNamedFiltersProvider).contains(slug);
  }

  /// When Explore did not use `namedFilters`, keep "no alcohol" from obvious bar-only venues.
  bool _passesNoAlcoholLocalHeuristic(Place place) {
    final types = place.types.map((e) => e.toLowerCase()).join(' ');
    final n =
        '${place.name} ${place.description ?? ''} ${place.editorialSummary ?? ''}'
            .toLowerCase();
    if ((types.contains('bar') || types.contains('night_club')) &&
        !n.contains('mocktail') &&
        !n.contains('non-alcoholic') &&
        !n.contains('non alcoholic') &&
        !n.contains('0%') &&
        !n.contains('soft drink')) {
      return false;
    }
    return true;
  }

  static const _kUtilityTypes = {
    'supermarket',
    'grocery_or_supermarket',
    'convenience_store',
    'gas_station',
    'pharmacy',
    'drugstore',
    'hardware_store',
    'car_repair',
    'car_wash',
    'car_dealer',
    'storage',
    'laundry',
    'moving_company',
    'locksmith',
    'insurance_agency',
    'bank',
    'atm',
    'post_office',
    'government_office',
  };

  static const _kUtilityNamePatterns = [
    'jumbo',
    'albert heijn',
    'lidl',
    'aldi',
    'plus supermarkt',
    'dirk van den broek',
    'dekamarkt',
    'spar supermarkt',
  ];

  bool _isUtilityPlace(Place place) {
    final types = place.types.map((t) => t.toLowerCase()).toSet();
    if (types.intersection(_kUtilityTypes).isNotEmpty) return true;
    final nameLower = place.name.toLowerCase();
    return _kUtilityNamePatterns.any((p) => nameLower.contains(p));
  }

  /// Returns false only for places that are clearly **wrong** for the current hour.
  /// We err on the side of showing rather than hiding — only obvious mismatches get filtered.
  bool _placeMatchesTimeOfDay(Place place, int hour) {
    final types = place.types.map((t) => t.toLowerCase()).toSet();
    final nameLower =
        '${place.name} ${place.description ?? ''} ${place.editorialSummary ?? ''}'
            .toLowerCase();

    // Breakfast/brunch places (strongly breakfast-cued): hide after 14:00
    final isBreakfastOnly = (types.contains('bakery') ||
            types.contains('breakfast_restaurant')) &&
        RegExp(r'\b(ontbijt|breakfast only|brunch only)\b').hasMatch(nameLower);
    if (isBreakfastOnly && hour >= 14) return false;

    // Night-club / late-night bars: hide before 17:00 on weekdays
    final isNightOnly = types.contains('night_club') ||
        RegExp(r'\b(nightclub|night club|late night)\b').hasMatch(nameLower);
    final weekday = DateTime.now().weekday; // 1=Mon … 7=Sun
    final isWeekend = weekday >= 5;
    if (isNightOnly && hour < 17 && !isWeekend) return false;

    return true;
  }

  bool _passesSurpriseLocalTypes(Place place) {
    const ok = <String>{
      'restaurant',
      'cafe',
      'bar',
      'museum',
      'art_gallery',
      'park',
      'tourist_attraction',
      'food_court',
      'bakery',
      'coffee_shop',
    };
    return place.types.map((e) => e.toLowerCase()).any(ok.contains);
  }

  bool _checkAdvancedFilters(Place place) {
    // Mood filter
    if (_selectedMood != null && !_placeMatchesMood(place, _selectedMood!))
      return false;

    // Indoor/Outdoor filters
    if (_indoorOnly && !_placeIsIndoor(place)) return false;
    if (_outdoorOnly && _placeIsIndoor(place)) return false;

    // Weather safe filter
    if (_weatherSafe && !_placeIsWeatherSafe(place)) return false;

    // Availability filter
    if (_openNow && !_placeIsCurrentlyOpen(place)) return false;

    // Dietary — when moody fetched with matching [namedFilters], trust that path.
    if (_vegan &&
        !_backendNamedFilterActive('vegan') &&
        !_matchesFilter(place, 'vegan')) return false;
    if (_vegetarian &&
        !_backendNamedFilterActive('vegetarian') &&
        !_matchesFilter(place, 'vegetarian')) return false;
    if (_halal &&
        !_backendNamedFilterActive('halal') &&
        !_matchesFilter(place, 'halal')) return false;
    if (_glutenFree &&
        !_backendNamedFilterActive('gluten_free') &&
        !_matchesFilter(place, 'gluten_free')) return false;
    if (_pescatarian &&
        !_backendNamedFilterActive('pescatarian') &&
        !_placeSupportsVeganVegetarian(place)) {
      final blob = '${place.name} ${place.description ?? ''}'.toLowerCase();
      if (!RegExp(r'pescatar|seafood|fish|sushi|ceviche|poke|oyster')
          .hasMatch(blob)) {
        return false;
      }
    }

    if (_romanticVibe &&
        !_backendNamedFilterActive('romantic') &&
        !_matchesFilter(place, 'romantic')) return false;

    // Accessibility & Inclusion
    if (_wheelchairAccessible &&
        !_backendNamedFilterActive('wheelchair_accessible') &&
        !_backendNamedFilterActive('wheelchair') &&
        !_matchesFilter(place, 'wheelchair_accessible')) return false;
    if (_lgbtqFriendly &&
        (!_backendNamedFilterActive('lgbtq_friendly') &&
            !_matchesFilter(place, 'lgbtq_friendly'))) return false;
    if (_sensoryFriendly &&
        !_backendNamedFilterActive('sensory_friendly') &&
        !_backendNamedFilterActive('sensory') &&
        !_matchesFilter(place, 'sensory_friendly')) return false;
    if (_seniorFriendly &&
        !_backendNamedFilterActive('senior_friendly') &&
        !_backendNamedFilterActive('senior') &&
        !_matchesFilter(place, 'senior_friendly')) return false;
    if (_familyFriendly &&
        !_backendNamedFilterActive('family_friendly') &&
        !_backendNamedFilterActive('kids_friendly')) {
      final familyBlob =
          '${place.name} ${place.description ?? ''} ${place.editorialSummary ?? ''}'
              .toLowerCase();
      if (!RegExp(
        r'family|kids|children|playground|stroller|child[- ]?friendly',
      ).hasMatch(familyBlob)) {
        return false;
      }
    }
    if (_babyFriendly &&
        (!_backendNamedFilterActive('kids_friendly') &&
            !_matchesFilter(place, 'baby_friendly'))) return false;
    if (_blackOwned &&
        (!_backendNamedFilterActive('black_owned') &&
            !_matchesFilter(place, 'black_owned'))) return false;

    // Comfort & Convenience
    if (_wifiAvailable &&
        !_backendNamedFilterActive('wifi') &&
        !_matchesFilter(place, 'wifi_available')) return false;
    if (_chargingPoints &&
        !_backendNamedFilterActive('charging') &&
        !_matchesFilter(place, 'charging_points')) return false;
    if (_parkingAvailable &&
        !_backendNamedFilterActive('parking') &&
        !_matchesFilter(place, 'parking_available')) return false;
    if (_creditCards &&
        !_backendNamedFilterActive('credit_cards') &&
        !_matchesFilter(place, 'credit_cards')) return false;

    if (_crowdQuiet &&
        !_backendNamedFilterActive('quiet') &&
        !_matchesFilter(place, 'quiet')) return false;
    if (_crowdLively &&
        !_backendNamedFilterActive('lively') &&
        !_matchesFilter(place, 'lively')) return false;
    if (_surpriseMe &&
        !_backendNamedFilterActive('surprise_me') &&
        !_backendNamedFilterActive('surprise') &&
        !_passesSurpriseLocalTypes(place)) return false;
    if (_transportIncluded &&
        !_backendNamedFilterActive('transit') &&
        !_backendNamedFilterActive('transport') &&
        !_matchesFilter(place, 'transit')) return false;
    if (_noAlcohol &&
        !_backendNamedFilterActive('no_alcohol') &&
        !_passesNoAlcoholLocalHeuristic(place)) return false;

    // Photo / vibe
    if (_instagrammable &&
        (!_backendNamedFilterActive('instagrammable') &&
            !_matchesFilter(place, 'instagrammable'))) return false;
    if (_aestheticSpaces &&
        (!_backendNamedFilterActive('aesthetic_spaces') &&
            !_matchesFilter(place, 'aesthetic_spaces'))) return false;
    if (_artisticDesign &&
        (!_backendNamedFilterActive('artistic_design') &&
            !_matchesFilter(place, 'artistic_design'))) return false;
    if (_scenicViews &&
        (!_backendNamedFilterActive('scenic_views') &&
            !_matchesFilter(place, 'scenic_views'))) return false;
    if (_bestAtSunset &&
        (!_backendNamedFilterActive('sunset') &&
            !_matchesFilter(place, 'best_at_sunset'))) return false;
    if (_bestAtNight &&
        !_backendNamedFilterActive('best_at_night') &&
        !_matchesFilter(place, 'best_at_night')) return false;

    return true;
  }

  // Smart metadata matching method - improved with fallback logic
  bool _matchesFilter(Place place, String filterKey) {
    // NEW: Edge Function handles mood-based filtering
    // Local filters use keyword matching (no need for metadata from old provider)
    // Create search text for keyword matching
    final searchText =
        '${place.name.toLowerCase()} ${place.description?.toLowerCase() ?? ''} ${place.address.toLowerCase()}';

    // Use keyword-based matching (Edge Function already filtered by mood)
    return _matchesFilterByKeywords(place, filterKey, searchText);
  }

  // Fallback keyword matching when metadata is not available
  bool _matchesFilterByKeywords(
      Place place, String filterKey, String searchText) {
    final keywordMap = {
      'vegan': ['vegan', 'plant-based', 'plant based', 'vegetarian'],
      'vegetarian': ['vegetarian', 'veggie', 'meat-free', 'meat free'],
      'halal': [
        'halal',
        'muslim',
        'islamic',
        'turkish',
        'kebab',
        'kabab',
        'döner',
        'doner',
        'shawarma',
        'middle eastern',
        'persian',
        'arab',
        'moroccan',
        'lebanese',
        'pakistani',
      ],
      'gluten_free': ['gluten-free', 'gluten free', 'celiac', 'gf'],
      'wheelchair_accessible': [
        'accessible',
        'wheelchair',
        'ramp',
        'elevator',
        'disabled'
      ],
      'lgbtq_friendly': ['lgbtq', 'lgbt', 'gay', 'pride', 'inclusive'],
      'senior_friendly': ['senior', 'elderly', 'accessible', 'easy access'],
      'sensory_friendly': [
        'sensory',
        'autism',
        'neurodiverse',
        'low stimulation',
        'quiet room',
        'calm',
        'soft lighting',
      ],
      'baby_friendly': [
        'baby',
        'child',
        'family',
        'kids',
        'stroller',
        'changing'
      ],
      'black_owned': ['black owned', 'black-owned', 'african'],
      'wifi_available': ['wifi', 'wi-fi', 'wireless', 'internet', 'free wifi'],
      'charging_points': ['charging', 'power outlet', 'usb', 'electric'],
      'parking_available': ['parking', 'car park', 'garage'],
      'credit_cards': ['card', 'credit', 'debit', 'payment', 'cashless'],
      'instagrammable': [
        'instagram',
        'photo',
        'picturesque',
        'scenic',
        'beautiful'
      ],
      'aesthetic_spaces': [
        'aesthetic',
        'design',
        'decor',
        'interior',
        'stylish'
      ],
      'scenic_views': ['view', 'scenic', 'panoramic', 'vista', 'overlook'],
      'best_at_sunset': ['sunset', 'evening', 'golden hour', 'dusk'],
      'best_at_night': [
        'late night',
        'open late',
        'midnight',
        'night',
        'evening',
        'rooftop',
        'cocktail',
        'bar',
        'nightlife',
      ],
      'romantic': [
        'romantic',
        'candle',
        'wine',
        'sunset',
        'waterfront',
        'date',
        'intimate',
        'valentine',
      ],
      'artistic_design': [
        'design',
        'architecture',
        'gallery',
        'concept',
        'artistic',
        'minimal',
        'brutalist',
      ],
      'quiet': [
        'quiet',
        'peaceful',
        'calm',
        'cozy',
        'reading',
        'library',
        'intimate',
        'low noise',
      ],
      'lively': [
        'lively',
        'buzzing',
        'busy',
        'crowd',
        'live music',
        'dj ',
        'party',
        'vibrant',
        'food hall',
      ],
      'transit': [
        'station',
        'metro',
        'tram',
        'train',
        'bus',
        'transit',
        'centraal',
      ],
    };

    final keywords = keywordMap[filterKey] ?? [];
    if (keywords.isEmpty)
      return true; // If no keywords defined, don't filter out

    // Check if any keyword matches
    return keywords
        .any((keyword) => searchText.contains(keyword.toLowerCase()));
  }

  // Helper method for mood matching
  bool _placeMatchesMood(Place place, String mood) {
    switch (mood.toLowerCase()) {
      case 'adventure':
        return place.types.contains('park') ||
            place.types.contains('tourist_attraction') ||
            place.activities.any(
                (activity) => activity.toLowerCase().contains('adventure'));
      case 'creative':
        return place.types.contains('art_gallery') ||
            place.types.contains('museum') ||
            place.activities.any((activity) => ['art', 'creative', 'workshop']
                .contains(activity.toLowerCase()));
      case 'relaxed':
        return place.types.contains('spa') ||
            place.types.contains('cafe') ||
            place.types.contains('park') ||
            place.activities.any((activity) => [
                  'relaxation',
                  'wellness',
                  'meditation'
                ].contains(activity.toLowerCase()));
      case 'mindful':
        return place.types.contains('place_of_worship') ||
            place.types.contains('park') ||
            place.activities.any((activity) => [
                  'meditation',
                  'spiritual',
                  'mindfulness'
                ].contains(activity.toLowerCase()));
      case 'romantic':
        return place.types.contains('restaurant') && place.rating > 4.0 ||
            place.activities.any((activity) => ['romantic', 'date', 'intimate']
                .contains(activity.toLowerCase()));
      default:
        return true;
    }
  }

  // Helper method for indoor places
  bool _placeIsIndoor(Place place) {
    return !place.types.contains('park') &&
        !place.types.contains('zoo') &&
        !place.types.contains('campground') &&
        !place.types.contains('amusement_park');
  }

  // Helper method for weather safe places
  bool _placeIsWeatherSafe(Place place) {
    // Weather safe places are typically indoor or have good weather protection
    return _placeIsIndoor(place) ||
        place.types.contains('shopping_mall') ||
        place.types.contains('subway_station') ||
        place.types.contains('train_station') ||
        place.types.contains('airport') ||
        place.types.contains('hospital') ||
        place.types.contains('university') ||
        place.types.contains('school');
  }

  // Helper method to check if place is currently open
  // Uses real opening hours data when available, otherwise estimates based on type
  bool _placeIsCurrentlyOpen(Place place) {
    // Use real opening hours if available
    final oh = place.openingHours;
    if (oh != null) {
      return oh.isOpen;
    }

    // Fallback: estimate based on place type and current time
    // This is a reasonable fallback when real data isn't available
    final hour = MoodyClock.now().hour;
    if (place.types.contains('museum')) return hour >= 9 && hour <= 17;
    if (place.types.contains('restaurant')) return hour >= 11 && hour <= 22;
    if (place.types.contains('bar'))
      return hour >= 17 || hour <= 2; // Bars open late
    if (place.types.contains('park')) return hour >= 6 && hour <= 22;
    return hour >= 8 && hour <= 20; // Default business hours
  }

  // Helper methods for filter logic (in a real app, this data would come from your database)
  bool _placeSupportsHalal(Place place) =>
      place.types.contains('restaurant') &&
          place.name.toLowerCase().contains('halal') ||
      place.description?.toLowerCase().contains('halal') == true;

  bool _placeSupportsVeganVegetarian(Place place) =>
      place.types.contains('restaurant') &&
      (place.name.toLowerCase().contains('vegan') ||
          place.name.toLowerCase().contains('vegetarian') ||
          place.description?.toLowerCase().contains('vegan') == true ||
          place.description?.toLowerCase().contains('vegetarian') == true);

  bool _placeSupportsGlutenFree(Place place) =>
      place.types.contains('restaurant') &&
      (place.name.toLowerCase().contains('gluten') ||
          place.description?.toLowerCase().contains('gluten') == true);

  // Helper methods for accessibility and inclusivity
  // These use rating as a proxy when real data isn't available
  // In production, this data should come from place details API or user reviews
  bool _placeIsAccessible(Place place) {
    // Check description for accessibility keywords
    final desc = place.description?.toLowerCase() ?? '';
    if (desc.contains('accessible') ||
        desc.contains('wheelchair') ||
        desc.contains('ramp')) {
      return true;
    }
    // Fallback: higher-rated places are more likely to be accessible
    return place.rating > 4.0;
  }

  bool _placeIsLGBTQFriendly(Place place) {
    // Check description for inclusivity keywords
    final desc = place.description?.toLowerCase() ?? '';
    if (desc.contains('lgbtq') ||
        desc.contains('inclusive') ||
        desc.contains('diverse') ||
        desc.contains('pride')) {
      return true;
    }
    // Fallback: higher-rated places are more likely to be inclusive
    return place.rating > 4.2;
  }

  /// "Popular" on the chip row = high confidence picks (aligned with Moody
  /// `social_signal` + rating/review bar), not "anything tourist_attraction".
  bool _placeMatchesPopularCategory(Place place) {
    final rating = place.rating;
    final reviews = place.reviewCount;
    final sig = (place.socialSignal ?? '').toLowerCase().trim();
    final moodyBoost =
        sig == 'trending' || sig == 'popular' || sig == 'loved_by_locals';
    if (moodyBoost && rating >= 4.0 && reviews >= 25) return true;
    if (rating >= 4.35 && reviews >= 50) return true;
    if (rating >= 4.2 && reviews >= 180) return true;
    final types = place.types.map((e) => e.toLowerCase()).toSet();
    if (types.contains('tourist_attraction') &&
        rating >= 4.25 &&
        reviews >= 120) {
      return true;
    }
    return false;
  }

  bool _checkCategoryMatch(Place place, String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return true;
      case 'popular':
        return _placeMatchesPopularCategory(place);
      case 'walking_tours':
        final blob =
            '${place.name} ${place.description ?? ''} ${place.editorialSummary ?? ''}'
                .toLowerCase();
        return RegExp(
              r'walking tour|city tour|guided tour|free tour|architecture tour|self[- ]guided',
            ).hasMatch(blob) ||
            place.types.any((t) => {
                  'tourist_attraction',
                  'point_of_interest',
                }.contains(t.toLowerCase()));
      case 'museums':
      case 'culture':
        const cultureCore = <String>{
          'museum',
          'art_gallery',
          'library',
          'cultural_center',
          'performing_arts_theater',
          'art_studio',
        };
        final typesLo = place.types.map((e) => e.toLowerCase()).toSet();
        if (typesLo.any(cultureCore.contains)) {
          return true;
        }
        if (typesLo.contains('tourist_attraction')) {
          final blob =
              '${place.name} ${place.description ?? ''} ${place.editorialSummary ?? ''}'
                  .toLowerCase();
          return RegExp(
            r'art|gallery|museum|culture|exhibit|theatre|theater|concert|performance|sculpture|opera',
          ).hasMatch(blob);
        }
        return false;
      case 'boat_tours':
        final boatBlob =
            '${place.name} ${place.description ?? ''} ${place.editorialSummary ?? ''}'
                .toLowerCase();
        return RegExp(
              r'boat|harbor cruise|canal cruise|splash|water taxi|rib',
            ).hasMatch(boatBlob) ||
            place.types.any((t) => {
                  'marina',
                  'tourist_attraction',
                }.contains(t.toLowerCase()));
      case 'landmarks':
        final landmarkBlob =
            '${place.name} ${place.description ?? ''} ${place.editorialSummary ?? ''}'
                .toLowerCase();
        return RegExp(
              r'landmark|viewpoint|observation|tower|iconic|panoramic|euromast',
            ).hasMatch(landmarkBlob) ||
            place.types.any((t) => {
                  'historical_landmark',
                  'tourist_attraction',
                  'point_of_interest',
                }.contains(t.toLowerCase()));
      case 'events':
        final eventsBlob =
            '${place.name} ${place.description ?? ''} ${place.editorialSummary ?? ''}'
                .toLowerCase();
        return RegExp(
              r'event|concert|show|theater|theatre|comedy|live music|festival|night',
            ).hasMatch(eventsBlob) ||
            place.types.any((t) => {
                  'night_club',
                  'bar',
                  'performing_arts_theater',
                }.contains(t.toLowerCase()));
      case 'nature':
        const natureTypes = <String>{
          'park',
          'natural_feature',
          'zoo',
          'campground',
          'national_park',
          'aquarium',
          'botanical_garden',
          'beach',
          'marina',
          'hiking_area',
        };
        return place.types
            .any((type) => natureTypes.contains(type.toLowerCase()));
      case 'food':
        const foodTypes = <String>{
          'restaurant',
          'cafe',
          'bakery',
          'coffee_shop',
          'bar',
          'meal_takeaway',
          'meal_delivery',
          'food_court',
          'ice_cream_shop',
          'dessert_shop',
        };
        return place.types
            .any((type) => foodTypes.contains(type.toLowerCase()));
      case 'activities':
        const activityTypes = <String>{
          'amusement_park',
          'aquarium',
          'bowling_alley',
          'casino',
          'movie_theater',
          'night_club',
          'spa',
          'stadium',
          'zoo',
          'tourist_attraction',
          'park',
          'gym',
          'fitness_center',
          'sports_complex',
          'marina',
          'campground',
          'hiking_area',
          'golf_course',
          'ski_resort',
        };
        if (place.types
            .any((type) => activityTypes.contains(type.toLowerCase()))) {
          if (place.types.any((type) => {
                    'restaurant',
                    'cafe',
                    'bakery',
                    'meal_takeaway',
                  }.contains(type.toLowerCase())) &&
              !place.types.any((type) => {
                    'amusement_park',
                    'aquarium',
                    'bowling_alley',
                    'casino',
                    'movie_theater',
                    'night_club',
                    'stadium',
                    'zoo',
                    'gym',
                    'fitness_center',
                    'sports_complex',
                    'golf_course',
                    'ski_resort',
                  }.contains(type.toLowerCase()))) {
            return false;
          }
          return true;
        }
        return false;
      case 'history':
        const historyTypes = <String>{
          'museum',
          'cemetery',
          'church',
          'mosque',
          'synagogue',
          'hindu_temple',
          'place_of_worship',
          'historical_landmark',
        };
        final typesLo = place.types.map((e) => e.toLowerCase()).toSet();
        if (typesLo.any(historyTypes.contains)) {
          return true;
        }
        if (typesLo.contains('tourist_attraction')) {
          final blob =
              '${place.name} ${place.description ?? ''} ${place.editorialSummary ?? ''}'
                  .toLowerCase();
          return RegExp(
            r'histor|heritage|monument|memorial|castle|fort|ancient|world war|wwii|ww2|ruins|archaeolog',
          ).hasMatch(blob);
        }
        return place.activities.any(
          (activity) => activity.toLowerCase().contains('history'),
        );
      default:
        return place.types
                .any((type) => type.toLowerCase() == category.toLowerCase()) ||
            place.activities.any(
                (activity) => activity.toLowerCase() == category.toLowerCase());
    }
  }

  /// Browsing vs search vs filters — editorial line above the feed (list + map).
  /// Omits total place count so the feed feels open-ended.
  /// Default “Discovering {city}” strip is hidden — users already know they are on Explore.
  Widget _buildExploreModeContextCard() {
    final l10n = AppLocalizations.of(context)!;
    final IconData icon;
    final String title;
    if (_searchQuery.trim().isNotEmpty && _searchResults == null) {
      icon = Icons.hourglass_top_rounded;
      title = l10n.exploreSearching;
    } else if (_searchResults != null && _searchQuery.trim().isNotEmpty) {
      icon = Icons.search_rounded;
      title = l10n.exploreContextStripSearch(_searchQuery.trim());
    } else if (_activeFiltersCount > 0) {
      icon = Icons.tune_rounded;
      title = l10n.exploreContextStripFiltered(_activeFiltersCount);
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E2D8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF2A6049), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4A4640),
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreInlineFilterActions() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Material(
            color: const Color(0xFFEBF3EE),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                _showAdvancedFilters();
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune, size: 16, color: Color(0xFF2A6049)),
                    const SizedBox(width: 6),
                    Text(
                      l10n.exploreFiltersActiveCount(_activeFiltersCount),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2A6049),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _clearAllFilters();
            },
            child: Text(
              l10n.exploreClearAll,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8C8780),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreHeaderColumn(
    int activitiesCount, {
    bool showOfflineCachedHint = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Match [DynamicMyDayScreen] title row: horizontal 24, top 16, wmTitle scale.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      l10n.navExplore,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: Colors.grey[900],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const LocationDropdown(),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ConversationalExploreHeader(
              onSearchChanged: _onConversationalSearchChanged,
              onFilterTap: _showAdvancedFilters,
              activeFiltersCount: _activeFiltersCount,
              isGridView: _isGridView,
              isMapView: _isMapView,
              onViewToggle: (isGrid, isMap) {
                setState(() {
                  _isGridView = isGrid;
                  _isMapView = isMap;
                });
              },
              categoryKeys: _categories,
              selectedCategory: _selectedCategory,
              categoryLabel: _categoryLabel,
              categoryEmoji: (k) => _filterIcons[k] ?? '📍',
              onCategorySelected: _onCategorySelected,
            ),
            _buildExploreModeContextCard(),
            if (_activeFiltersCount > 0) _buildExploreInlineFilterActions(),
            if (showOfflineCachedHint)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF3EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD0E4DA)),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 18,
                          color: _afWmForest.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.exploreOfflineShowingCached,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF2A6049),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 280.ms, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreOfflineEmptyBody() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8E2D8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: Color(0xFF8C8780),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              l10n.exploreOfflineEmptyBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A4640),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 320.ms, curve: Curves.easeOut);
  }

  Widget _buildExploreSliverAppBar(
    int activitiesCount, {
    bool showOfflineCachedHint = false,
  }) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: false,
      // Tight fit: extra [expandedHeight] becomes empty parchment between the
      // header (incl. list/grid/map toggles) and the first body sliver (e.g. Trending).
      // Keep in sync with [_buildExploreHeaderColumn] + [ConversationalExploreHeader] height.
      expandedHeight: _activeFiltersCount > 0 ? 246 : 210,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: null,
      title: null,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _buildExploreHeaderColumn(
          activitiesCount,
          showOfflineCachedHint: showOfflineCachedHint,
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox.shrink(),
      ),
    );
  }

  Widget _buildExploreErrorBody(Object error, StackTrace? stack) {
    final l10n = AppLocalizations.of(context)!;
    final errorMessage = error.toString();
    final isLocationError = error is ExploreLocationException ||
        errorMessage.contains('Location is required') ||
        errorMessage.contains('GPS coordinates') ||
        errorMessage.contains('Coordinates are required') ||
        errorMessage.contains('valid city name') ||
        errorMessage.contains('location services') ||
        errorMessage.contains('Locatie') ||
        errorMessage.contains('Standort') ||
        errorMessage.contains('Localisation');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLocationError ? Icons.location_off : Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            isLocationError
                ? l10n.exploreErrorLocationRequiredTitle
                : l10n.exploreErrorLoadingPlacesTitle,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              isLocationError ? l10n.exploreErrorLocationBody : errorMessage,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final connected =
                  await ref.read(connectivityServiceProvider).isConnected;
              if (!mounted) return;
              if (!connected) {
                showOfflineSnackBar(context);
                return;
              }
              if (mounted) {
                setState(() => _explorePlacePhotoRefreshSeed++);
              }
              ref.invalidate(moodyExploreAutoProvider);
              _explorePullRefreshGeneration++;
              await _loadAllSections(resetBulkSeed: true);
              if (!mounted) return;
              _rotateExploreCachedPresentation();
              unawaited(_refreshExploreStaleInBackground());
              if (isLocationError) {
                ref
                    .read(locationNotifierProvider.notifier)
                    .retryLocationAccess();
                ref.read(userLocationProvider.notifier).refreshLocation();
              }
            },
            child: Text(
              isLocationError
                  ? l10n.exploreErrorEnableLocation
                  : l10n.planLoadingTryAgain,
            ),
          ),
        ],
      ),
    );
  }

  /// Map mode avoids [NestedScrollView] so pinch/pan gestures are not stolen by the header scroll coordinator.
  Widget _buildExploreMapModeBody(
    List<Place> allPlaces,
    int activitiesCount, {
    bool showOfflineCachedHint = false,
  }) {
    final userLocationAsync = ref.read(userLocationProvider);
    final userLocation = userLocationAsync.value;

    final List<Place> basePlaces =
        _searchResults != null ? _searchResults! : allPlaces;
    final filteredPlaces = _filterPlaces(basePlaces);

    final placesForMap = filteredPlaces;
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom +
        _kExploreFloatingNavClearance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildExploreHeaderColumn(
          activitiesCount,
          showOfflineCachedHint: showOfflineCachedHint,
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPad),
            child: _buildMapView(placesForMap, userLocation),
          ),
        ),
      ],
    );
  }

  Widget _buildExploreListGridBody(List<Place> allPlaces) {
    final locationAsync = ref.watch(locationNotifierProvider);
    final userLocationAsync = ref.read(userLocationProvider);
    final currentCity = locationAsync.value ?? 'Rotterdam';
    final userLocation = userLocationAsync.value;
    final sig = '$currentCity|${_activeMoodFiltersForPartners().join(',')}';
    if (_partnerFetchSig != sig) {
      _partnerFetchSig = sig;
      unawaited(_refreshPartnerDataForCity(currentCity));
    }

    final List<Place> basePlaces =
        _searchResults != null ? _searchResults! : allPlaces;
    var filteredPlaces = _filterPlaces(basePlaces);
    var categoryFallbackApplied = false;

    if (filteredPlaces.isEmpty &&
        _selectedCategory != 'all' &&
        _searchQuery.trim().isEmpty) {
      final relaxed = _filterPlaces(basePlaces, ignoreCategory: true);
      final relaxedQuick = _applyQuickFilters(
        relaxed,
        userLocation: userLocation,
        currentCity: currentCity,
      );
      if (relaxedQuick.isNotEmpty) {
        filteredPlaces = relaxedQuick;
        categoryFallbackApplied = true;
        if (kDebugMode) {
          debugPrint(
            '🛟 Explore fallback activated for category="$_selectedCategory": restored ${filteredPlaces.length} places.',
          );
        }
      }
    }

    filteredPlaces = _applyQuickFilters(
      filteredPlaces,
      userLocation: userLocation,
      currentCity: currentCity,
    );

    final activeMoodFilters = _activeMoodFiltersForPartners();
    if (activeMoodFilters.isNotEmpty && _partnerMoodMatches.isNotEmpty) {
      final partnerIds = _partnerMoodMatches
          .map((p) => p.placeId)
          .whereType<String>()
          .map(_normalizePartnerPlaceId)
          .toSet();
      final partners = <Place>[];
      final others = <Place>[];
      for (final p in filteredPlaces) {
        final id = _normalizePartnerPlaceId(p.id);
        if (partnerIds.contains(id)) {
          partners.add(p);
        } else {
          others.add(p);
        }
      }
      filteredPlaces = [...partners, ...others];
    }

    if (filteredPlaces.length < 5 && allPlaces.length >= 50) {
      debugPrint(
          '⚠️ Filters reduced results to ${filteredPlaces.length} places (${allPlaces.length} unfiltered).');
    }

    final visibleCount =
        math.min(_exploreVisiblePlaceCount, filteredPlaces.length);
    final visiblePlaces = filteredPlaces.sublist(0, visibleCount);
    final partnerIds = _partnerMoodMatches
        .map((p) => p.placeId)
        .whereType<String>()
        .map(_normalizePartnerPlaceId)
        .toSet();
    final partnerUiTestMode =
        kDebugMode && _partnerTrending.isEmpty && _partnerMoodMatches.isEmpty;

    var carouselPlaces = filteredPlaces
        .where((p) => partnerIds.contains(_normalizePartnerPlaceId(p.id)))
        .take(10)
        .toList();
    if (partnerUiTestMode) {
      carouselPlaces = filteredPlaces.take(10).toList();
    }
    final storiesPartnersForUi = partnerUiTestMode
        ? _mockPartnerListingsForUi(
            places: filteredPlaces,
            city: currentCity,
            limit: 6,
          )
        : _partnerTrending;
    _enqueueVisibleRichPrewarm(visiblePlaces);
    _trackPartnerListingViewsForVisibleSlice(visiblePlaces);
    final hasMoreLocally = visibleCount < filteredPlaces.length;
    final canFetchMoreExplore = _searchResults == null &&
        filteredPlaces.length >= _kExplorePageSize &&
        !hasMoreLocally;
    final showExploreLoadMore =
        filteredPlaces.isNotEmpty && (hasMoreLocally || canFetchMoreExplore);

    if (filteredPlaces.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      // While search is in-flight or sections are refetching (cards cleared), show
      // loading — not "no results" (filter apply clears section.cards until Moody returns).
      final sectionsReloadingEmpty =
          _sections.any((s) => s.isLoading && s.cards.isEmpty);
      final showLoadingEmpty = sectionsReloadingEmpty ||
          _isSearching ||
          (_searchQuery.trim().length >= 1 && _searchResults == null);
      return CustomScrollView(
        primary: true,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: showLoadingEmpty
                        ? ExploreFeedLoadingSurface(l10n: l10n)
                            .animate()
                            .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFE8E2D8)),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.search_off_rounded,
                                  size: 36,
                                  color: Color(0xFFB0BAC0),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                l10n.exploreNoPlacesFound,
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4A4640),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  l10n.exploreNoPlacesFoundHint,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF8C8780),
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              if (_searchQuery.trim().isNotEmpty &&
                                  _relatedSearchOptions.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _relatedSearchOptions
                                        .take(4)
                                        .map(
                                          (option) => InkWell(
                                            onTap: () =>
                                                _applyRelatedSearchOption(
                                                    option),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEAF5EE),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: const Color(0xFF2A6049)
                                                      .withValues(alpha: 0.28),
                                                ),
                                              ),
                                              child: Text(
                                                option,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      const Color(0xFF2A6049),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ],
                            ],
                          ).animate().fadeIn(
                              duration: 320.ms,
                              curve: Curves.easeOutCubic,
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final l10n = AppLocalizations.of(context)!;

    final exploreFooterSliver = SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
        child: OutlinedButton(
          onPressed: _isLoadingMoreExplore
              ? null
              : () => _onExploreLoadMoreTap(filteredPlaces.length),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2A6049),
            side: const BorderSide(color: Color(0xFF2A6049), width: 1.5),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isLoadingMoreExplore
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2A6049),
                  ),
                )
              : Text(
                  l10n.exploreLoadMoreIdeas,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
    const explanationSliver = null;

    final placesSliver = _isGridView
        ? SliverGrid(
            key: const ValueKey<String>('explore_sliver_grid'),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              // Wider vs height = shorter cards; tuned with [PlaceGridCard] padding + photo height.
              childAspectRatio: 0.70,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final place = visiblePlaces[index];
                final ul = userLocationAsync.value;
                return PlaceGridCard(
                  place: place,
                  userLocation: ul,
                  cityName: currentCity,
                  photoSelectionSeed: _explorePlacePhotoRefreshSeed,
                  allowVisibilityEnrichment: true,
                  onTap: () => _openPlaceFromExplore(place),
                  onAddToMyDayTap: () => _showAddToMyDaySheet(place),
                  onSavedTap: () => unawaited(
                    _trackExploreTasteInteraction(place, 'saved'),
                  ),
                ).animate().fadeIn(
                    duration: 300.ms,
                    delay: Duration(milliseconds: index * 30));
              },
              childCount: visiblePlaces.length,
            ),
          )
        : SliverList(
            key: const ValueKey<String>('explore_sliver_list'),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final ul = userLocationAsync.value;
                final showCarousel = carouselPlaces.length >= 2;
                final injectAt = math.min(4, visiblePlaces.length);
                if (showCarousel && index == injectAt) {
                  return PartnerCarousel(
                    label: l10n.explorePartnerRecommendedForYou,
                    places: carouselPlaces,
                    userLocation: ul,
                    cityName: currentCity,
                    photoSelectionSeed: _explorePlacePhotoRefreshSeed,
                    onOpenPlace: _openPlaceFromExplore,
                    onAddToMyDay: _showAddToMyDaySheet,
                  ).animate().fadeIn(
                        duration: 300.ms,
                        delay: Duration(milliseconds: index * 50),
                      );
                }
                final placeIndex =
                    (showCarousel && index > injectAt) ? index - 1 : index;
                final place = visiblePlaces[placeIndex];
                return PlaceCard(
                  place: place,
                  userLocation: ul,
                  cityName: currentCity,
                  photoSelectionSeed: _explorePlacePhotoRefreshSeed,
                  allowVisibilityEnrichment: true,
                  cardMargin: const EdgeInsets.only(top: 2, bottom: 16),
                  showAddToMyDayButton: true,
                  onAddToMyDayTap: () => _showAddToMyDaySheet(place),
                  onTap: () => _openPlaceFromExplore(place),
                  onSavedTap: () => unawaited(
                    _trackExploreTasteInteraction(place, 'saved'),
                  ),
                ).animate().fadeIn(
                    duration: 300.ms,
                    delay: Duration(milliseconds: index * 50));
              },
              childCount:
                  visiblePlaces.length + (carouselPlaces.length >= 2 ? 1 : 0),
            ),
          );

    return CustomScrollView(
      primary: true,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (categoryFallbackApplied)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E2D8)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded,
                        size: 16, color: Color(0xFF2A6049)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.exploreNoPlacesFoundHint,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4A4640),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (explanationSliver != null) explanationSliver,
        if (storiesPartnersForUi.length >= 3)
          SliverToBoxAdapter(
            child: PartnerStoriesRow(
              partners: storiesPartnersForUi,
              headline: l10n.explorePartnerTrendingHeadline,
              onTapPartnerPlace: _openPlaceFromExplore,
            ),
          ),
        SliverPadding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 16),
          sliver: placesSliver,
        ),
        if (showExploreLoadMore) exploreFooterSliver,
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _wrapExploreStack(Widget child) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Non-positioned Stack children get loose constraints; NestedScrollView
        // needs bounded max height or layout can fail (infinite size / sliver errors).
        Positioned.fill(child: child),
        if (_showScrollToTop && !_isMapView)
          Positioned(
            bottom: 24,
            right: 16,
            child: AnimatedOpacity(
              opacity: _showScrollToTop ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: FloatingActionButton.small(
                heroTag: 'explore_scroll_top',
                backgroundColor: const Color(0xFF2A6049),
                onPressed: () => _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                ),
                child: const Icon(Icons.arrow_upward,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.watch(preferencesProvider);

    final city = ref.watch(locationNotifierProvider).value?.trim();
    final online = ref.watch(isConnectedProvider).valueOrNull ?? true;
    final userLocAsync = ref.watch(userLocationProvider);
    final combined = _allCards;
    final sectionsStillLoading =
        _sections.any((s) => s.isLoading && s.cards.isEmpty);

    if (city == null || city.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F0E8),
        body: _wrapExploreStack(
          NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildExploreSliverAppBar(0),
            ],
            body: _buildExploreErrorBody(
              const ExploreLocationException(ExploreLocationReason.missingCity),
              null,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: userLocAsync.when(
        loading: () {
          final hasCached = _sections.any((s) => s.cards.isNotEmpty);
          if (hasCached) {
            return _wrapExploreStack(
              NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  _buildExploreSliverAppBar(0),
                ],
                body: RefreshIndicator(
                  onRefresh: _onUserPulledToRefresh,
                  child: _buildExploreListGridBody(_allCards),
                ),
              ),
            );
          }
          return _wrapExploreStack(
            NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildExploreSliverAppBar(0),
              ],
              body: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return ExploreFeedLoadingSurface(l10n: l10n);
                },
              ),
            ),
          );
        },
        error: (e, st) => _wrapExploreStack(
          NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildExploreSliverAppBar(0),
            ],
            body: _buildExploreErrorBody(e, st),
          ),
        ),
        data: (pos) {
          if (pos == null) {
            return _wrapExploreStack(
              NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  _buildExploreSliverAppBar(0),
                ],
                body: _buildExploreErrorBody(
                  const ExploreLocationException(
                      ExploreLocationReason.missingCoordinates),
                  null,
                ),
              ),
            );
          }

          if (!online && combined.isEmpty && !sectionsStillLoading) {
            return _wrapExploreStack(
              NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  _buildExploreSliverAppBar(0),
                ],
                body: _buildExploreOfflineEmptyBody(),
              ),
            );
          }

          final offlineCached = !online && combined.isNotEmpty;
          final activitiesCount = _searchResults != null
              ? _searchResults!.length
              : _filterPlaces(combined).length;

          if (_isMapView) {
            return _buildExploreMapModeBody(
              _allCards,
              activitiesCount,
              showOfflineCachedHint: offlineCached,
            );
          }

          final inner = RefreshIndicator(
            onRefresh: _onUserPulledToRefresh,
            child: _buildExploreListGridBody(_allCards),
          );

          return _wrapExploreStack(
            NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildExploreSliverAppBar(
                  activitiesCount,
                  showOfflineCachedHint: offlineCached,
                ),
              ],
              body: inner,
            ),
          );
        },
      ),
    );
  }

  // --- Add to My Day ---

  Future<void> _showAddToMyDaySheet(Place place) async {
    final l10n = AppLocalizations.of(context)!;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        showMoodyToast(context, l10n.myDayAddSignInRequired);
      }
      return;
    }

    final selectedDate = ref.read(selectedMyDayDateProvider);
    final planningDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final scheduledActivityService = ref.read(scheduledActivityServiceProvider);
    final occupied =
        await scheduledActivityService.getOccupiedTimeSlotKeysForPlaceOnDate(
      placeId: place.id,
      date: planningDate,
    );

    if (!mounted) return;
    if (occupied.length >= 3) {
      showMoodyToast(context, l10n.exploreAlreadyInDayPlan);
      return;
    }

    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddPlaceToMyDaySheet(
        place: place,
        planningDate: planningDate,
        onTimeSelected: (DateTime startTime) =>
            _addActivityToMyDay(place, startTime),
      ),
    );
  }

  Future<void> _addActivityToMyDay(Place place, DateTime startTime) async {
    await saveExplorePlaceToMyDay(
      context: context,
      ref: ref,
      place: place,
      startTime: startTime,
      photoSelectionSeed: _explorePlacePhotoRefreshSeed,
    );
    unawaited(_trackExploreTasteInteraction(place, 'added_to_day'));
  }
}
