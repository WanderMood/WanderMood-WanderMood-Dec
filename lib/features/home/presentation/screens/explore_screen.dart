import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../widgets/explore_place_quick_peek_sheet.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/providers/language_provider.dart';
import 'package:wandermood/core/utils/places_cache_utils.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/core/utils/moody_toast.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/services/connectivity_service.dart';
import 'package:wandermood/core/utils/offline_feedback.dart';
import 'package:wandermood/core/providers/explore_session_anchor_provider.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
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

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'All';
  String _searchFilter = 'All';
  bool _isSearching = false;
  String _searchQuery = '';

  // Backend search results — null means show normal explore feed
  List<Place>? _searchResults;
  Timer? _searchDebounce;

  // Scroll detection for content
  bool _isScrolling = false;
  double _lastScrollOffset = 0.0;
  bool _showScrollToTop = false;

  // View mode toggle - grid, list or map
  bool _isGridView = false;
  bool _isMapView = false;
  GoogleMapController? _mapController;

  /// Rotates named-filter fetches so "Load more" adds fresh cards without backend pagination.
  int _exploreMoreRound = 0;
  bool _isLoadingMoreExplore = false;

  /// Changes hero photo index for each place when Explore feed is refreshed.
  int _explorePlacePhotoRefreshSeed = 0;

  /// How many places to show in list/grid (capped by filtered list length).
  int _exploreVisiblePlaceCount = _kExplorePageSize;

  bool _backgroundExploreRefresh = false;

  late final List<_ExploreSectionData> _sections = [
    _ExploreSectionData(id: 'food'),
    _ExploreSectionData(id: 'trending'),
    _ExploreSectionData(id: 'solo'),
    _ExploreSectionData(id: 'different'),
  ];

  // Advanced filter settings - New Structure
  int _activeFiltersCount = 0;

  // Expandable sections state - ALL CLOSED BY DEFAULT
  bool _advancedSuggestionsExpanded = false;
  bool _dietaryExpanded = false;
  bool _accessibilityExpanded = false;
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
    'All',
    'Popular',
    'Accommodations',
    'Nature',
    'Culture',
    'Food',
    'Activities',
    'History',
  ];

  final Map<String, String> _filterIcons = {
    'All': '🌟',
    'Popular': '🔥',
    'Accommodations': '🏨',
    'Nature': '🌳',
    'Culture': '🎨',
    'Food': '🍽️',
    'Activities': '⚡',
    'History': '🏛️',
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScrollChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(locationNotifierProvider.notifier).getCurrentLocation();
      _scheduleLoadSectionsIfReady();
    });
    _explorePlacePhotoRefreshSeed = math.Random().nextInt(2000000000);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _mapController?.dispose();
    super.dispose();
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
    final city = anchor?.city ?? ref.read(locationNotifierProvider).value?.trim();
    final hasPos =
        anchor != null || ref.read(userLocationProvider).value != null;
    if (city != null && city.isNotEmpty && hasPos) {
      unawaited(_loadAllSections());
    }
  }

  Future<void> _maybeLockSessionAnchor() async {
    if (ref.read(exploreSessionAnchorProvider) != null) return;
    final city = ref.read(locationNotifierProvider).valueOrNull?.trim();
    final pos = ref.read(userLocationProvider).valueOrNull;
    if (city == null || city.isEmpty || pos == null) return;
    ref.read(exploreSessionAnchorProvider.notifier).state = ExploreSessionAnchor(
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
    ref.read(exploreSessionAnchorProvider.notifier).state = ExploreSessionAnchor(
      city: city,
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
    if (!mounted) return;
    await _loadAllSections(forceNetwork: true);
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
      if (moved >= 5000 &&
          city != null &&
          city.isNotEmpty) {
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
    await _loadAllSections(forceNetwork: true);
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

  /// Extra Explore rows via moody `namedFilters` (skips Flutter cache read).
  Future<void> _loadMoreExploreIdeas() async {
    if (_isLoadingMoreExplore || _isMapView) return;
    await _maybeLockSessionAnchor();
    final anchor = ref.read(exploreSessionAnchorProvider);
    final city = anchor?.city ?? ref.read(locationNotifierProvider).value?.trim();
    final pos =
        anchor != null ? _positionForExploreLoad() : ref.read(userLocationProvider).value;
    if (city == null || city.isEmpty || pos == null) return;
    final connected = await ref.read(connectivityServiceProvider).isConnected;
    if (!connected) {
      if (mounted) showOfflineSnackBar(context);
      return;
    }
    setState(() => _isLoadingMoreExplore = true);
    try {
      final exploreLang = PlacesCacheUtils.effectiveExploreLanguageTag(
        appLocale: ref.read(localeProvider),
      );
      const tags = [
        'cultural',
        'foodie',
        'outdoor',
        'nightlife',
        'wellness',
        'trendy',
      ];
      final tag = tags[_exploreMoreRound % tags.length];
      _exploreMoreRound++;
      final service = ref.read(moodyEdgeFunctionServiceProvider);
      final more = await service.getExplore(
        location: city,
        latitude: pos.latitude,
        longitude: pos.longitude,
        section: 'discovery',
        namedFilters: [tag],
        languageCode: exploreLang,
      );
      final notifier = ref.read(placesServiceProvider.notifier);
      for (final p in more) {
        notifier.cachePlaceObject(p);
      }
      if (!mounted) return;
      setState(() {
        if (_sections.isNotEmpty) {
          final last = _sections.last;
          last.cards = _mergePlaces(last.cards, more);
        }
      });
    } catch (e, st) {
      debugPrint('Explore load more: $e\n$st');
    } finally {
      if (mounted) setState(() => _isLoadingMoreExplore = false);
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
    await _loadMoreExploreIdeas();
    if (!mounted) return;
    setState(() {
      _exploreVisiblePlaceCount += _kExplorePageSize;
    });
  }

  Future<void> _loadAllSections({bool forceNetwork = false}) async {
    if (!mounted) return;
    await _maybeLockSessionAnchor();
    final anchor = ref.read(exploreSessionAnchorProvider);
    final cityForCache =
        anchor?.city ?? ref.read(locationNotifierProvider).valueOrNull?.trim() ?? '';

    final connected = await ref.read(connectivityServiceProvider).isConnected;
    if (!connected) {
      await _loadAllSectionsOffline();
      return;
    }

    final filters = ref.read(moodyExploreBackendFiltersProvider);
    final namedFilters = ref.read(moodyExploreBackendNamedFiltersProvider);
    final skipPlacesCacheFirstPass =
        filters.isNotEmpty || namedFilters.isNotEmpty;

    if (!forceNetwork &&
        !skipPlacesCacheFirstPass &&
        cityForCache.isNotEmpty &&
        mounted) {
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
          return;
        }
        if (needBackground) {
          unawaited(_refreshExploreStaleInBackground());
        }
        await Future.wait(
          _sections.where((s) => s.isLoading).map((s) => _loadSection(s)),
        );
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
        (s) => _loadSection(s, skipPlacesCache: forceNetwork),
      ),
    );
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
    final city = anchor?.city ??
        ref.read(locationNotifierProvider).value?.trim() ??
        '';
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
    final currentScrollOffset = _scrollController.offset;
    final scrollDelta = currentScrollOffset - _lastScrollOffset;

    final shouldShow = currentScrollOffset > 400;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }

    if (scrollDelta > 10 && !_isScrolling) {
      setState(() {
        _isScrolling = true;
      });
    } else if (scrollDelta < -5 || scrollDelta.abs() < 1) {
      setState(() {
        _isScrolling = false;
      });
    }

    _lastScrollOffset = currentScrollOffset;
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
      final response = await supabase.functions.invoke('moody', body: {
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
        final places = cards.map((c) {
          final m = c is Map<String, dynamic>
              ? c
              : Map<String, dynamic>.from(c as Map);
          return PlacesCacheUtils.placeFromMoodyExploreCard(m);
        }).toList();
        setState(() {
          _searchResults = places;
          _isSearching = false;
          _exploreVisiblePlaceCount = _kExplorePageSize;
        });
      } else {
        setState(() {
          _searchResults = [];
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
      _searchFilter = 'All'; // Reset search filter when clearing
      _searchResults = null;
      _exploreVisiblePlaceCount = _kExplorePageSize;
    });
  }

  void _updateActiveFiltersCount() {
    int count = 0;

    // Moody Suggests filters
    if (_selectedMood != null) count++;
    if (_indoorOnly) count++;
    if (_outdoorOnly) count++;
    if (_weatherSafe) count++;
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
    if (_babyFriendly) count++;
    if (_blackOwned) count++;

    // Comfort & Convenience
    // Count price range if not default (0-100)
    if (_priceRange.start != 0 || _priceRange.end != 100) count++;
    // Count distance if not default (25 km)
    if (_maxDistance != 25.0) count++;
    if (_parkingAvailable) count++;
    if (_transportIncluded) count++;
    if (_creditCards) count++;
    if (_wifiAvailable) count++;
    if (_chargingPoints) count++;

    // Photo Options
    if (_instagrammable) count++;
    if (_artisticDesign) count++;
    if (_aestheticSpaces) count++;
    if (_scenicViews) count++;
    if (_bestAtNight) count++;
    if (_bestAtSunset) count++;

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
    if (_weatherSafe) n++;
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
    if (_babyFriendly) n++;
    if (_blackOwned) n++;
    return n;
  }

  int get _comfortActiveCount {
    int n = 0;
    if (_priceRange.start != 0 || _priceRange.end != 100) n++;
    if (_maxDistance != 25.0) n++;
    if (_parkingAvailable) n++;
    if (_transportIncluded) n++;
    if (_creditCards) n++;
    if (_wifiAvailable) n++;
    if (_chargingPoints) n++;
    return n;
  }

  int get _photoActiveCount {
    int n = 0;
    if (_instagrammable) n++;
    if (_artisticDesign) n++;
    if (_aestheticSpaces) n++;
    if (_scenicViews) n++;
    if (_bestAtNight) n++;
    if (_bestAtSunset) n++;
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

    // Dietary / inclusion / photo vibes go to moody `namedFilters` (see _buildMoodyNamedFilters).
    // Remaining strings are applied server-side on cache hits as `filters.requiredKeywords`.
    final requiredKeywords = <String>[];
    if (_pescatarian) requiredKeywords.add('pescatarian');
    if (_noAlcohol) requiredKeywords.add('no alcohol');
    if (_wheelchairAccessible) requiredKeywords.add('wheelchair');
    if (_seniorFriendly) requiredKeywords.add('senior');
    if (_sensoryFriendly) requiredKeywords.add('sensory');
    if (_wifiAvailable) requiredKeywords.add('wifi');
    if (_chargingPoints) requiredKeywords.add('charging');
    if (_parkingAvailable) requiredKeywords.add('parking');
    if (_creditCards) requiredKeywords.add('card payment');
    if (_bestAtNight) requiredKeywords.add('night');
    if (_weatherSafe) requiredKeywords.add('indoor');

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
    if (_instagrammable) add('instagrammable');
    if (_romanticVibe) add('romantic');
    if (_aestheticSpaces || _artisticDesign) add('aesthetic_spaces');
    if (_scenicViews) add('scenic_views');
    if (_bestAtSunset) add('sunset');
    if (_blackOwned) add('black_owned');
    if (_lgbtqFriendly) add('lgbtq_friendly');
    if (_babyFriendly) add('kids_friendly');

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

  /// Opens place detail with light haptic — same cache + route as before.
  void _openPlaceFromExplore(Place place) {
    HapticFeedback.lightImpact();
    ref.read(placesServiceProvider.notifier).cachePlaceObject(place);
    context.push('/place/${place.id}');
  }

  Widget _buildExploreFeedLoadingSurface(AppLocalizations l10n) {
    Widget skeletonBar({
      required double height,
      required double widthFactor,
      int shimmerDelayMs = 0,
    }) {
      return Align(
        alignment: Alignment.center,
        child: FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E2D8),
              borderRadius: BorderRadius.circular(14),
            ),
          )
              .animate(
                onPlay: (c) => c.repeat(reverse: true),
              )
              .shimmer(
                delay: Duration(milliseconds: shimmerDelayMs),
                duration: const Duration(milliseconds: 1800),
                color: Colors.white.withValues(alpha: 0.55),
              ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          skeletonBar(height: 14, widthFactor: 0.42, shimmerDelayMs: 0),
          const SizedBox(height: 18),
          skeletonBar(height: 112, widthFactor: 1, shimmerDelayMs: 120),
          const SizedBox(height: 14),
          skeletonBar(height: 112, widthFactor: 1, shimmerDelayMs: 240),
          const SizedBox(height: 22),
          Text(
            l10n.exploreSearching,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8C8780),
            ),
          ).animate().fadeIn(duration: 420.ms, delay: 100.ms),
        ],
      ),
    );
  }

  String _categoryLabel(String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'All': return l10n.exploreCategoryAll;
      case 'Popular': return l10n.exploreCategoryPopular;
      case 'Accommodations': return l10n.exploreCategoryAccommodations;
      case 'Nature': return l10n.exploreCategoryNature;
      case 'Culture': return l10n.exploreCategoryCulture;
      case 'Food': return l10n.exploreCategoryFood;
      case 'Activities': return l10n.exploreCategoryActivities;
      case 'History': return l10n.exploreCategoryHistory;
      default: return key;
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _searchFilter = category; // Sync search filter with category
      _exploreVisiblePlaceCount = _kExplorePageSize;
    });
  }

  void _onSearchFilterSelected(String filter) {
    setState(() {
      _searchFilter = filter;
      _selectedCategory = filter; // Sync category with search filter
      _exploreVisiblePlaceCount = _kExplorePageSize;
    });
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

  List<Place> _filterPlaces(List<Place> places) {
    final initialCount = places.length;
    final preferencesService = ref.read(userPreferencesServiceProvider);

    var filteredPlaces = places.where((place) {
      // Filter by search query
      bool matchesSearch = _searchQuery.isEmpty ||
          place.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (place.description
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false) ||
          place.address.toLowerCase().contains(_searchQuery.toLowerCase());

      // Apply advanced filters (mood, dietary, accessibility, etc.)
      bool matchesAdvancedFilters = _checkAdvancedFilters(place);

      // Apply user preferences from onboarding (soft filter - boost matching places)
      // Only apply if no explicit filters are set (to avoid double-filtering)
      bool matchesPreferences = true;
      if (_activeFiltersCount == 0 && _searchQuery.isEmpty) {
        // Soft preference matching: prefer places that match interests/styles
        matchesPreferences = preferencesService.placeMatchesInterests(place) ||
            preferencesService.placeMatchesTravelStyles(place);
      }

      final matchesCategory = _selectedCategory == 'All' ||
          _checkCategoryMatch(place, _selectedCategory);

      return matchesSearch &&
          matchesAdvancedFilters &&
          matchesPreferences &&
          matchesCategory;
    }).toList();

    // Open first → unknown hours → closed (stable within ties: keeps Moody order).
    filteredPlaces.sort((a, b) {
      final c = _exploreOpeningDisplayPriority(a)
          .compareTo(_exploreOpeningDisplayPriority(b));
      if (c != 0) {
        return c;
      }
      return 0;
    });

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
    if (_pescatarian && !_placeSupportsVeganVegetarian(place))
      return false; // Pescatarian matches vegetarian

    // Accessibility & Inclusion - using smart metadata matching
    if (_wheelchairAccessible &&
        !_matchesFilter(place, 'wheelchair_accessible')) return false;
    if (_lgbtqFriendly &&
        (!_backendNamedFilterActive('lgbtq_friendly') &&
            !_matchesFilter(place, 'lgbtq_friendly'))) return false;
    if (_seniorFriendly && !_matchesFilter(place, 'senior_friendly'))
      return false;
    if (_babyFriendly &&
        (!_backendNamedFilterActive('kids_friendly') &&
            !_matchesFilter(place, 'baby_friendly'))) return false;
    if (_blackOwned &&
        (!_backendNamedFilterActive('black_owned') &&
            !_matchesFilter(place, 'black_owned'))) return false;

    // Comfort & Convenience - using smart metadata matching
    if (_wifiAvailable && !_matchesFilter(place, 'wifi_available'))
      return false;
    if (_chargingPoints && !_matchesFilter(place, 'charging_points'))
      return false;
    if (_parkingAvailable && !_matchesFilter(place, 'parking_available'))
      return false;
    if (_creditCards && !_matchesFilter(place, 'credit_cards')) return false;

    // Photo Options - using smart metadata matching
    if (_instagrammable &&
        (!_backendNamedFilterActive('instagrammable') &&
            !_matchesFilter(place, 'instagrammable'))) return false;
    if ((_aestheticSpaces || _artisticDesign) &&
        (!_backendNamedFilterActive('aesthetic_spaces') &&
            !_matchesFilter(place, 'aesthetic_spaces'))) return false;
    if (_scenicViews &&
        (!_backendNamedFilterActive('scenic_views') &&
            !_matchesFilter(place, 'scenic_views'))) return false;
    if (_bestAtSunset &&
        (!_backendNamedFilterActive('sunset') &&
            !_matchesFilter(place, 'best_at_sunset'))) return false;

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

  bool _checkCategoryMatch(Place place, String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return true;
      case 'popular':
        return place.rating >= 4.0 ||
            place.types.contains('tourist_attraction');
      case 'accommodations':
        return place.types.any((type) => [
              'lodging',
              'hotel',
              'apartment_rental'
            ].contains(type.toLowerCase()));
      case 'nature':
        return place.types.any((type) => [
                  'park',
                  'natural_feature',
                  'zoo',
                  'campground'
                ].contains(type.toLowerCase())) ||
            place.activities
                .any((activity) => activity.toLowerCase().contains('nature'));
      case 'culture':
        return place.types.any((type) => [
                  'museum',
                  'art_gallery',
                  'library',
                  'tourist_attraction'
                ].contains(type.toLowerCase())) ||
            place.activities.any((activity) =>
                ['culture', 'history', 'art'].contains(activity.toLowerCase()));
      case 'food':
        return place.types.any((type) => [
                  'restaurant',
                  'cafe',
                  'bakery',
                  'food',
                  'meal_takeaway'
                ].contains(type.toLowerCase())) ||
            place.activities
                .any((activity) => activity.toLowerCase().contains('dining'));
      case 'activities':
        return place.activities.isNotEmpty;
      case 'history':
        return place.types.any((type) => [
                  'museum',
                  'cemetery',
                  'church',
                  'mosque',
                  'synagogue',
                  'hindu_temple',
                  'place_of_worship'
                ].contains(type.toLowerCase())) ||
            place.activities
                .any((activity) => activity.toLowerCase().contains('history'));
      default:
        return place.types
                .any((type) => type.toLowerCase() == category.toLowerCase()) ||
            place.activities.any(
                (activity) => activity.toLowerCase() == category.toLowerCase());
    }
  }

  /// Browsing vs search vs filters — editorial line above the feed (list + map).
  /// Omits total place count so the feed feels open-ended.
  Widget _buildExploreModeContextCard() {
    final l10n = AppLocalizations.of(context)!;
    final city = ref.read(locationNotifierProvider).valueOrNull?.trim() ?? '';
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
      icon = Icons.explore_rounded;
      title = city.isNotEmpty
          ? l10n.exploreContextStripDiscovering(city)
          : l10n.exploreContextStripDiscovering(l10n.navExplore);
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
          const SizedBox(height: 6),
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
      // Title + search + chips + toggles — keep minimal dead space above the list.
      expandedHeight: 348,
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
              await _loadAllSections();
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

    final List<Place> basePlaces =
        _searchResults != null ? _searchResults! : allPlaces;
    var filteredPlaces = _filterPlaces(basePlaces);

    filteredPlaces = _applyQuickFilters(
      filteredPlaces,
      userLocation: userLocation,
      currentCity: currentCity,
    );

    if (filteredPlaces.length < 5 && allPlaces.length >= 50) {
      debugPrint(
          '⚠️ Filters reduced results to ${filteredPlaces.length} places (${allPlaces.length} unfiltered).');
    }

    final visibleCount =
        math.min(_exploreVisiblePlaceCount, filteredPlaces.length);
    final visiblePlaces = filteredPlaces.sublist(0, visibleCount);
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
                        ? _buildExploreFeedLoadingSurface(l10n)
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
                                  border:
                                      Border.all(color: const Color(0xFFE8E2D8)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.05),
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
                  AppLocalizations.of(context)!.exploreLoadMoreIdeas,
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
                  onTap: () => _openPlaceFromExplore(place),
                  onAddToMyDayTap: () => _showAddToMyDaySheet(place),
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
                final place = visiblePlaces[index];
                final ul = userLocationAsync.value;
                return PlaceCard(
                  place: place,
                  userLocation: ul,
                  cityName: currentCity,
                  photoSelectionSeed: _explorePlacePhotoRefreshSeed,
                  cardMargin: const EdgeInsets.only(top: 2, bottom: 16),
                  showAddToMyDayButton: true,
                  onAddToMyDayTap: () => _showAddToMyDaySheet(place),
                  onTap: () => _openPlaceFromExplore(place),
                ).animate().fadeIn(
                    duration: 300.ms,
                    delay: Duration(milliseconds: index * 50));
              },
              childCount: visiblePlaces.length,
            ),
          );

    return CustomScrollView(
      primary: true,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (explanationSliver != null) explanationSliver,
        SliverPadding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 16),
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
        child,
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
                child: const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(preferencesProvider);
    ref.listen<int>(exploreManualCityPickTickProvider, (prev, next) {
      if (prev != null && prev != next) {
        ref.read(exploreSessionAnchorProvider.notifier).state = null;
        unawaited(_onManualCityChangedExplore());
      }
    });

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
                  return _buildExploreFeedLoadingSurface(l10n);
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

  Widget _buildAdvancedFilterModal() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        final l10n = AppLocalizations.of(context)!;
        // Create updateFilter function that updates both states
        void updateFilter(VoidCallback updateCallback) {
          updateCallback(); // Execute the state change once
          setState(() {}); // Trigger main widget rebuild
          setModalState(() {}); // Trigger modal rebuild
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: _afWmWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _afWmParchment, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header — title row gets full width minus icon + close (avoids
                // mid-word wraps when "Clear all" sat beside long l10n titles).
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 8, 14),
                  decoration: const BoxDecoration(
                    color: _afWmWhite,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _afWmForest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.tune,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2, right: 4),
                              child: Text(
                                l10n.exploreAdvancedFiltersTitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _afWmCharcoal,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.grey),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_activeFiltersCount > 0) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 46, right: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.exploreFiltersActiveCount(
                                    _activeFiltersCount,
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: _afWmForest,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  _clearAllFilters();
                                  setModalState(() {});
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: _afWmStone,
                                  backgroundColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: const RoundedRectangleBorder(
                                    side: BorderSide.none,
                                  ),
                                ),
                                child: Text(
                                  l10n.exploreClearAll,
                                  style: GoogleFonts.poppins(
                                    color: _afWmStone,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1, color: _afWmParchment),

                // Filter Content - New Expandable Structure
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Moody hint card
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F7F4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFD0E4DA), width: 1),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _afWmForestTint,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _afWmParchment, width: 1),
                                  ),
                                  child: Center(
                                    child: MoodyCharacter(
                                      size: 30,
                                      mood: _activeFiltersCount > 0 ? 'happy' : 'default',
                                      glowOpacityScale: 0.35,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _activeFiltersCount > 0
                                            ? l10n.exploreMoodyHintFiltersActive(_activeFiltersCount)
                                            : l10n.exploreMoodyHintFiltersIntro,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: const Color(0xFF2A6049),
                                          fontWeight: FontWeight.w500,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Quick Suggestions
                        _buildExpandableSection(
                          '⚡',
                          l10n.exploreSectionQuickSuggestions,
                          _advancedSuggestionsExpanded,
                          () => updateFilter(() {
                            _advancedSuggestionsExpanded = !_advancedSuggestionsExpanded;
                          }),
                          _buildAdvancedSuggestionFilters(updateFilter),
                          activeCount: _quickSuggestionsActiveCount,
                        ),

                        // Dietary Preferences
                        _buildExpandableSection(
                          '🍽️',
                          l10n.exploreSectionDietaryPreferences,
                          _dietaryExpanded,
                          () => updateFilter(() {
                            _dietaryExpanded = !_dietaryExpanded;
                          }),
                          _buildDietaryFilters(updateFilter),
                          activeCount: _dietaryActiveCount,
                        ),

                        // Accessibility & Inclusion
                        _buildExpandableSection(
                          '♿',
                          l10n.exploreSectionAccessibilityInclusion,
                          _accessibilityExpanded,
                          () => updateFilter(() {
                            _accessibilityExpanded = !_accessibilityExpanded;
                          }),
                          _buildAccessibilityFilters(updateFilter),
                          activeCount: _accessibilityActiveCount,
                        ),

                        // Comfort & Convenience
                        _buildExpandableSection(
                          '🛋️',
                          l10n.exploreSectionComfortConvenience,
                          _logisticsExpanded,
                          () => updateFilter(() {
                            _logisticsExpanded = !_logisticsExpanded;
                          }),
                          _buildLogisticsFilters(updateFilter),
                          activeCount: _comfortActiveCount,
                        ),

                        // Photo & Aesthetic
                        _buildExpandableSection(
                          '📸',
                          l10n.exploreSectionPhotoAesthetic,
                          _photoExpanded,
                          () => updateFilter(() {
                            _photoExpanded = !_photoExpanded;
                          }),
                          _buildPhotoFilters(updateFilter),
                          activeCount: _photoActiveCount,
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),

                // Apply Button
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                  decoration: BoxDecoration(
                    color: _afWmWhite,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border(
                      top: BorderSide(color: _afWmParchment.withValues(alpha: 0.85)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            final connected = await ref
                                .read(connectivityServiceProvider)
                                .isConnected;
                            if (!context.mounted) return;
                            if (!connected) {
                              showOfflineSnackBar(context);
                              return;
                            }
                            HapticFeedback.mediumImpact();
                            Navigator.pop(context);
                            final backendFilters = _buildMoodyBackendFilters();
                            final namedFilters = _buildMoodyNamedFilters();
                            ref
                                .read(moodyExploreBackendFiltersProvider.notifier)
                                .state = backendFilters;
                            ref
                                .read(
                                    moodyExploreBackendNamedFiltersProvider
                                        .notifier,
                                )
                                .state = namedFilters;
                            ref.invalidate(moodyExploreAutoProvider);
                            unawaited(_loadAllSections());
                            // Force a rebuild to apply filters
                            setState(() {
                              _exploreVisiblePlaceCount = _kExplorePageSize;
                              // Update active filters count
                              _updateActiveFiltersCount();
                              debugPrint(
                                  '💾 Saved filters - Active count: $_activeFiltersCount');
                              debugPrint(
                                  '🔍 Filter state - Vegan: $_vegan, Vegetarian: $_vegetarian, Wheelchair: $_wheelchairAccessible');
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _afWmForest,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _activeFiltersCount > 0
                                    ? l10n.exploreSaveFiltersWithCount(_activeFiltersCount)
                                    : l10n.exploreSaveFilters,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSection(
      String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _afWmWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _afWmParchment,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _afWmForest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _afWmCharcoal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String emoji, String title) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodButtons() {
    final l10n = AppLocalizations.of(context)!;
    final moods = _exploreMoodDefinitions(l10n);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: moods
            .map((mood) => Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: _buildMoodButton(mood),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMoodButton(Map<String, dynamic> mood) {
    final isSelected = _selectedMood == mood['id'];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedMood = isSelected ? null : mood['id'] as String;
            _updateActiveFiltersCount();
          });
        },
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? mood['color'] : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? mood['color'] : Colors.grey[300]!,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: mood['color'].withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: mood['color'].withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mood['emoji'], style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                mood['label'] as String,
                style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodButtonsWithCallback(Function(VoidCallback) updateFilter) {
    final l10n = AppLocalizations.of(context)!;
    final moods = _exploreMoodDefinitions(l10n);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: moods
            .map((mood) => Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: _buildMoodButtonWithCallback(mood, updateFilter),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMoodButtonWithCallback(
      Map<String, dynamic> mood, Function(VoidCallback) updateFilter) {
    final isSelected = _selectedMood == mood['id'];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          updateFilter(() {
            _selectedMood = isSelected ? null : mood['id'] as String;
            _updateActiveFiltersCount();
          });
        },
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? mood['color'] : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? mood['color'] : Colors.grey[300]!,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: mood['color'].withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: mood['color'].withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mood['emoji'], style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                mood['label'] as String,
                style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(
      String emoji, String label, bool value, Function(bool)? onChanged) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged != null
            ? () {
                HapticFeedback.lightImpact();
                onChanged(!value);
              }
            : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: value ? const Color(0xFF2A6049) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: value ? const Color(0xFF2A6049) : Colors.grey[300]!,
              width: value ? 2 : 1,
            ),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 3,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                    color: value ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChipWithCallback(
      String emoji, String label, bool value, VoidCallback? onChanged) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: value ? const Color(0xFF2A6049) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: value ? const Color(0xFF2A6049) : Colors.grey[300]!,
              width: value ? 2 : 1,
            ),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 3,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                    color: value ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton(
      String emoji, String label, bool value, Function(bool) onChanged) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onChanged(!value);
        },
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: value ? const Color(0xFF2A6049) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: value ? const Color(0xFF2A6049) : Colors.grey[300]!,
              width: value ? 2.5 : 1.5,
            ),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 2,
                      spreadRadius: 0,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                  color: value ? Colors.white : Colors.black87,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButtonWithCallback(
      String emoji, String label, bool value, VoidCallback? onChanged) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged,
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: value ? const Color(0xFF2A6049) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: value ? const Color(0xFF2A6049) : Colors.grey[300]!,
              width: value ? 2.5 : 1.5,
            ),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 2,
                      spreadRadius: 0,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                  color: value ? Colors.white : Colors.black87,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPriceLevelText(AppLocalizations l10n, int level) {
    switch (level) {
      case 1:
        return l10n.explorePriceLevelBudget;
      case 2:
        return l10n.explorePriceLevelModerate;
      case 3:
        return l10n.explorePriceLevelExpensive;
      case 4:
        return l10n.explorePriceLevelLuxury;
      default:
        return l10n.explorePriceLevelBudget;
    }
  }

  List<Map<String, dynamic>> _exploreMoodDefinitions(AppLocalizations l10n) {
    return [
      {'id': 'adventure', 'label': l10n.exploreMoodAdventure, 'emoji': '🏔️', 'color': const Color(0xFFFFD700)},
      {'id': 'creative', 'label': l10n.exploreMoodCreative, 'emoji': '😊', 'color': const Color(0xFF87CEEB)},
      {'id': 'relaxed', 'label': l10n.exploreMoodRelaxed, 'emoji': '🍀', 'color': const Color(0xFF98FB98)},
      {'id': 'mindful', 'label': l10n.exploreMoodMindful, 'emoji': '🍀', 'color': const Color(0xFFDDA0DD)},
      {'id': 'romantic', 'label': l10n.exploreMoodRomantic, 'emoji': '❤️', 'color': const Color(0xFFFFB6C1)},
    ];
  }

  // Helper method to build expandable sections
  Widget _buildExpandableSection(
    String icon,
    String title,
    bool isExpanded,
    VoidCallback onToggle,
    Widget content, {
    int activeCount = 0,
  }) {
    final hasActive = activeCount > 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: _afWmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasActive && !isExpanded ? _afWmForest.withValues(alpha: 0.55) : _afWmParchment,
          width: hasActive && !isExpanded ? 1.25 : 0.75,
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onToggle();
              },
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(16),
                bottom: isExpanded ? Radius.zero : const Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: hasActive ? _afWmForest : _afWmCharcoal,
                        ),
                      ),
                    ),
                    // Active count badge
                    if (hasActive && !isExpanded) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _afWmForest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$activeCount',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: isExpanded ? _afWmForest : _afWmStone,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              duration: const Duration(milliseconds: 200),
              heightFactor: isExpanded ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: content,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Advanced Suggestion filters
  Widget _buildAdvancedSuggestionFilters(Function(VoidCallback) updateFilter) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFilterChip('🏠', l10n.exploreFilterIndoorOnly, _indoorOnly, (value) {
                updateFilter(() {
                  _indoorOnly = value;
                  if (value) _outdoorOnly = false;
                  _updateActiveFiltersCount();
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFilterChip('☀️', l10n.exploreFilterOutdoorOnly, _outdoorOnly, (value) {
                updateFilter(() {
                  _outdoorOnly = value;
                  if (value) _indoorOnly = false;
                  _updateActiveFiltersCount();
                });
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFilterChip('🌧️', l10n.exploreFilterWeatherSafe, _weatherSafe, (value) {
                updateFilter(() {
                  _weatherSafe = value;
                  _updateActiveFiltersCount();
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFilterChip('🌙', l10n.exploreFilterOpenNow, _openNow, (value) {
                updateFilter(() {
                  _openNow = value;
                  _updateActiveFiltersCount();
                });
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFilterChip('🤫', l10n.exploreFilterQuiet, _crowdQuiet, (value) {
                updateFilter(() {
                  _crowdQuiet = value;
                  if (value) _crowdLively = false;
                  _updateActiveFiltersCount();
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFilterChip('💃', l10n.exploreFilterLively, _crowdLively, (value) {
                updateFilter(() {
                  _crowdLively = value;
                  if (value) _crowdQuiet = false;
                  _updateActiveFiltersCount();
                });
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFilterChip('💕', l10n.exploreFilterRomanticVibe, _romanticVibe, (value) {
                updateFilter(() {
                  _romanticVibe = value;
                  _updateActiveFiltersCount();
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFilterChip('🔀', l10n.exploreFilterSurpriseMe, _surpriseMe, (value) {
                updateFilter(() {
                  _surpriseMe = value;
                  _updateActiveFiltersCount();
                });
              }),
            ),
          ],
        ),
      ],
    );
  }

  // Dietary Preferences filters
  Widget _buildDietaryFilters(Function(VoidCallback) updateFilter) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip('🌱', l10n.exploreFilterVegan, _vegan, (value) {
          updateFilter(() { _vegan = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🥬', l10n.exploreFilterVegetarian, _vegetarian, (value) {
          updateFilter(() { _vegetarian = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🥗', l10n.exploreFilterHalal, _halal, (value) {
          updateFilter(() { _halal = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🌾', l10n.exploreFilterGlutenFree, _glutenFree, (value) {
          updateFilter(() { _glutenFree = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🐟', l10n.exploreFilterPescatarian, _pescatarian, (value) {
          updateFilter(() { _pescatarian = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('❌', l10n.exploreFilterNoAlcohol, _noAlcohol, (value) {
          updateFilter(() { _noAlcohol = value; _updateActiveFiltersCount(); });
        }),
      ],
    );
  }

  // Accessibility & Inclusion filters
  Widget _buildAccessibilityFilters(Function(VoidCallback) updateFilter) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip('♿', l10n.exploreFilterWheelchairAccessible, _wheelchairAccessible, (value) {
          updateFilter(() { _wheelchairAccessible = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🏳️‍🌈', l10n.exploreFilterLgbtqFriendly, _lgbtqFriendly, (value) {
          updateFilter(() { _lgbtqFriendly = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🧓', l10n.exploreFilterSeniorFriendly, _seniorFriendly, (value) {
          updateFilter(() { _seniorFriendly = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🧑‍🍼', l10n.exploreFilterBabyFriendly, _babyFriendly, (value) {
          updateFilter(() { _babyFriendly = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('✊🏿', l10n.exploreFilterBlackOwned, _blackOwned, (value) {
          updateFilter(() { _blackOwned = value; _updateActiveFiltersCount(); });
        }),
      ],
    );
  }

  // Comfort & Convenience filters
  Widget _buildLogisticsFilters(Function(VoidCallback) updateFilter) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.exploreFilterPriceRange,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _afWmCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 100,
          divisions: 20,
          labels: RangeLabels(
            '€${_priceRange.start.round()}',
            '€${_priceRange.end.round()}',
          ),
          onChanged: (values) {
            updateFilter(() {
              _priceRange = values;
              _updateActiveFiltersCount();
            });
          },
          activeColor: _afWmForest,
          inactiveColor: _afWmForest.withOpacity(0.2),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.exploreFilterMaxDistance,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _afWmCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _maxDistance,
          min: 0,
          max: 50,
          divisions: 50,
          label: '${_maxDistance.round()} km',
          onChanged: (value) {
            updateFilter(() {
              _maxDistance = value;
              _updateActiveFiltersCount();
            });
          },
          activeColor: _afWmForest,
          inactiveColor: _afWmForest.withOpacity(0.2),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.exploreFilterAdditionalOptions,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _afWmCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip('🚗', l10n.exploreFilterParking, _parkingAvailable, (value) {
              updateFilter(() { _parkingAvailable = value; _updateActiveFiltersCount(); });
            }),
            _buildFilterChip('🚌', l10n.exploreFilterTransport, _transportIncluded, (value) {
              updateFilter(() { _transportIncluded = value; _updateActiveFiltersCount(); });
            }),
            _buildFilterChip('💳', l10n.exploreFilterCreditCards, _creditCards, (value) {
              updateFilter(() { _creditCards = value; _updateActiveFiltersCount(); });
            }),
            _buildFilterChip('📶', l10n.exploreFilterWifi, _wifiAvailable, (value) {
              updateFilter(() { _wifiAvailable = value; _updateActiveFiltersCount(); });
            }),
            _buildFilterChip('🔌', l10n.exploreFilterCharging, _chargingPoints, (value) {
              updateFilter(() { _chargingPoints = value; _updateActiveFiltersCount(); });
            }),
          ],
        ),
      ],
    );
  }

  // Photo Options filters
  Widget _buildPhotoFilters(Function(VoidCallback) updateFilter) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip('📸', l10n.exploreFilterInstagrammable, _instagrammable, (value) {
          updateFilter(() { _instagrammable = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🎨', l10n.exploreFilterArtisticDesign, _artisticDesign, (value) {
          updateFilter(() { _artisticDesign = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🧘‍♀️', l10n.exploreFilterAestheticSpaces, _aestheticSpaces, (value) {
          updateFilter(() { _aestheticSpaces = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🌆', l10n.exploreFilterScenicViews, _scenicViews, (value) {
          updateFilter(() { _scenicViews = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🌙', l10n.exploreFilterBestAtNight, _bestAtNight, (value) {
          updateFilter(() { _bestAtNight = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🌅', l10n.exploreFilterBestAtSunset, _bestAtSunset, (value) {
          updateFilter(() { _bestAtSunset = value; _updateActiveFiltersCount(); });
        }),
      ],
    );
  }

  /// v2 filter pills (SCREEN 7): unselected cream + parchment + charcoal; selected forestTint + forest + forest text.
  Widget _buildFilterChip(
      String emoji, String label, bool isSelected, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!isSelected);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _afWmForestTint : _afWmCream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _afWmForest : _afWmParchment,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? _afWmForest : _afWmCharcoal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build selectable chips (for single-select options)
  Widget _buildSelectableChip(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEBF3EE) : const Color(0xFFF5F0E8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF2A6049) : const Color(0xFFE8E2D8),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color:
                isSelected ? const Color(0xFF2A6049) : const Color(0xFF8C8780),
          ),
        ),
      ),
    );
  }

  // Build map view with markers for places
  Widget _buildMapView(List<Place> places, Position? userLocation) {
    // Safety check: if no places, show empty state
    if (places.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.exploreNoPlacesOnMap,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    // Determine initial camera position
    LatLng initialPosition;
    if (userLocation != null) {
      // Check if it's simulator coordinates
      final isSanFrancisco = (userLocation.latitude - 37.785834).abs() < 0.1 &&
          (userLocation.longitude + 122.406417).abs() < 0.1;
      if (!isSanFrancisco) {
        initialPosition = LatLng(userLocation.latitude, userLocation.longitude);
      } else {
        // Use city center as fallback
        final currentCity =
            ref.read(locationNotifierProvider).value ?? 'Rotterdam';
        final cityCoords = _getCityCoordinates(currentCity);
        initialPosition = LatLng(cityCoords['lat']!, cityCoords['lng']!);
      }
    } else {
      // Use city center
      final currentCity =
          ref.read(locationNotifierProvider).value ?? 'Rotterdam';
      final cityCoords = _getCityCoordinates(currentCity);
      initialPosition = LatLng(cityCoords['lat']!, cityCoords['lng']!);
    }

    // Create markers for all places (not filtered - show everything on map)
    final Set<Marker> markers = {};
    final currentCity = ref.read(locationNotifierProvider).value ?? 'Rotterdam';

    for (int i = 0; i < places.length; i++) {
      final place = places[i];
      final markerId = MarkerId(place.id);

      // Determine marker color based on quick filters (visual indicator only)
      BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;
      if (_quickFilterRating45 && place.rating >= 4.5) {
        markerIcon =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      } else if (_quickFilterDistance1km) {
        // Check if within 1km (for visual highlighting)
        final distance =
            _calculatePlaceDistance(place, userLocation, currentCity);
        if (distance != null && distance <= 1.0) {
          markerIcon =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        }
      }

      markers.add(
        Marker(
          markerId: markerId,
          position: LatLng(place.location.lat, place.location.lng),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.rating > 0
                ? '⭐ ${place.rating.toStringAsFixed(1)}'
                : null,
          ),
          icon: markerIcon,
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 100));
            if (!mounted) {
              return;
            }
            HapticFeedback.lightImpact();
            await showExplorePlaceQuickPeekSheet(
              context: context,
              place: place,
              photoSelectionSeed: _explorePlacePhotoRefreshSeed,
              onViewFullPlace: () => _openPlaceFromExplore(place),
              onAddToMyDay: () {
                unawaited(_showAddToMyDaySheet(place));
              },
            );
          },
        ),
      );
    }

    // Avoid ClipRRect around the PlatformView — on iOS it can leave tiles blank while
    // markers/logo still render. City / radius is unchanged; LocationDropdown still shows it.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GoogleMap(
            key: const ValueKey<String>('explore_google_map'),
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 13,
            ),
            markers: markers,
            mapType: MapType.normal,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer()),
            },
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            minMaxZoomPreference: const MinMaxZoomPreference(9, 20),
            padding: EdgeInsets.zero,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (kDebugMode) {
                debugPrint('✅ Google Map created successfully');
                debugPrint(
                    '📍 Initial position: ${initialPosition.latitude}, ${initialPosition.longitude}');
                debugPrint('📍 Markers count: ${markers.length}');
              }
            },
            onCameraMoveStarted: () {
              if (kDebugMode) {
                debugPrint('🗺️ Camera move started');
              }
            },
            onTap: (LatLng position) {
              if (kDebugMode) {
                debugPrint(
                    '🗺️ Map tapped at: ${position.latitude}, ${position.longitude}');
              }
            },
            onCameraIdle: () {
              if (kDebugMode) {
                debugPrint('🗺️ Camera idle - map should be fully loaded');
              }
            },
            myLocationEnabled: userLocation != null &&
                (userLocation.latitude - 37.785834).abs() > 0.1,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            trafficEnabled: false,
            buildingsEnabled: true,
            indoorViewEnabled: false,
          ),
          ),

          // Quick filter chips at the top
          Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.exploreQuickFilters,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const Spacer(),
                    // Distance filter (highlights places within 1km)
                    _buildQuickFilterChip(
                      '1km',
                      isActive: _quickFilterDistance1km,
                      onTap: () {
                        setState(() {
                          _quickFilterDistance1km = !_quickFilterDistance1km;
                          _exploreVisiblePlaceCount = _kExplorePageSize;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    // Rating filter (highlights places 4.5+)
                    _buildQuickFilterChip(
                      '4.5+',
                      isActive: _quickFilterRating45,
                      onTap: () {
                        setState(() {
                          _quickFilterRating45 = !_quickFilterRating45;
                          _exploreVisiblePlaceCount = _kExplorePageSize;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  /// Get city coordinates for map initialization
  Map<String, double> _getCityCoordinates(String cityName) {
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
    return cityCoords[cityName] ?? cityCoords['Rotterdam']!;
  }

  /// Calculate distance for a place (helper for map markers)
  double? _calculatePlaceDistance(
      Place place, Position? userLocation, String cityName) {
    Position? referencePoint;

    if (userLocation != null) {
      final isSanFrancisco = (userLocation.latitude - 37.785834).abs() < 0.1 &&
          (userLocation.longitude + 122.406417).abs() < 0.1;
      if (!isSanFrancisco) {
        referencePoint = userLocation;
      }
    }

    if (referencePoint == null) {
      final cityCoords = _getCityCoordinates(cityName);
      referencePoint = Position(
        latitude: cityCoords['lat']!,
        longitude: cityCoords['lng']!,
        timestamp: MoodyClock.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    return DistanceService.calculateDistance(
      referencePoint.latitude,
      referencePoint.longitude,
      place.location.lat,
      place.location.lng,
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

    final scheduledActivityService =
        ref.read(scheduledActivityServiceProvider);
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
  }

  // Build quick filter chip for map view
  Widget _buildQuickFilterChip(
    String label, {
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEAF5EE) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF2A6049) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFF2A6049) : Colors.grey[800],
          ),
        ),
      ),
    );
  }
}
