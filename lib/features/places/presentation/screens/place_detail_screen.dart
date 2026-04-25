import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:wandermood/core/presentation/widgets/moody_avatar_compact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/places/services/sharing_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:wandermood/core/theme/app_theme.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/providers/moody_explore_provider.dart';
import 'package:wandermood/features/places/services/saved_places_service.dart';
import 'package:wandermood/features/places/presentation/widgets/booking_bottom_sheet.dart';
import 'package:wandermood/core/services/moody_ai_service.dart';
import 'package:wandermood/features/places/services/places_service.dart';
import 'package:wandermood/features/places/services/reviews_cache_service.dart';
import 'package:wandermood/core/widgets/data_source_badge.dart';
import 'package:wandermood/core/presentation/providers/language_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/core/services/distance_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/features/places/presentation/widgets/place_detail_about_block.dart';
import 'package:wandermood/core/utils/places_cache_utils.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/core/services/taste_profile_service.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/utils/google_place_photo_device_url.dart';
import 'package:wandermood/core/utils/place_gallery_merge.dart';
import 'package:wandermood/core/utils/places_new_photo_resolver.dart';
import 'package:wandermood/core/utils/place_type_formatter.dart';

/// Set `--dart-define=WM_PLACE_DETAIL_HERO_DEBUG=true` on IPA/TestFlight builds to
/// overlay the first hero URL + resolver flags (remove when finished debugging).
const bool kWmPlaceDetailHeroPhotoDebug = bool.fromEnvironment(
  'WM_PLACE_DETAIL_HERO_DEBUG',
  defaultValue: false,
);

void _agentLogPlaceDetail(
  String hypothesisId,
  String message, {
  Map<String, dynamic>? data,
  String runId = 'run1',
  String location = 'place_detail_screen.dart',
}) {
  try {
    final entry = {
      'sessionId': '9a3a3b',
      'runId': runId,
      'hypothesisId': hypothesisId,
      'location': location,
      'message': message,
      'data': data ?? <String, dynamic>{},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    File('/Users/edviennemerencia/WanderMood-WanderMood-Dec/.cursor/debug-9a3a3b.log')
        .writeAsStringSync('${jsonEncode(entry)}\n', mode: FileMode.append, flush: true);
  } catch (_) {}
}

String _wmHeroDebugClipUrl(String u) {
  final t = u.trim();
  if (t.length <= 200) return t;
  return '${t.substring(0, 200)}…';
}

/// WanderMood v2 — Place detail (SCREEN 8)
const Color _pdWmWhite = Color(0xFFFFFFFF);
const Color _pdWmCream = Color(0xFFF5F0E8);
const Color _pdWmParchment = Color(0xFFE8E2D8);
const Color _pdWmForest = Color(0xFF2A6049);
const Color _pdWmForestTint = Color(0xFFEBF3EE);
const Color _pdWmCharcoal = Color(0xFF1E1C18);
const Color _pdWmCard = Color(0xFFFFFFFF);
const Color _pdWmCardBorder = Color(0xFFD9D0C3);

class PlaceDetailScreen extends ConsumerStatefulWidget {
  final String placeId;

  const PlaceDetailScreen({
    required this.placeId,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _photoController = PageController();
  int _currentPhotoIndex = 0;
  Place? _currentPlace; // Track current place for booking button
  List<Map<String, dynamic>> _realReviews = []; // Real reviews from Google API
  bool _loadingReviews = false;
  bool _hasAttemptedReviewFetch = false;
  
  // Request deduplication: Track in-flight API requests
  final Set<String> _inFlightRequests = {};
  Place? _cachedPlace; // Cache the found place to avoid repeated lookups
  Future<List<String>>? _cachedMoodyTipsFuture; // Cache AI tips Future
  String? _cachedPlaceIdForTips; // Track which place the tips are for
  bool _isInitialized = false; // Track if widget has been initialized to prevent rebuild loops
  /// Single resolved gallery for hero, Foto's tab, gallery strip, fullscreen (deduped, max 10).
  List<String> _unifiedDetailPhotos = [];
  bool _unifiedDetailPhotosLoading = false;
  bool _unifiedDetailPhotosResolutionComplete = false;
  String? _unifiedPhotosResolvedPlaceId;
  String? _unifiedDetailPhotosInflightForPlaceId;
  final Set<String> _descriptionEnrichAttempted = {};
  String? _enrichedWebsite;
  String? _enrichedPhone;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _isInitialized = true;
  }

  @override
  void dispose() {
    _isInitialized = false; // Mark as disposed to prevent rebuilds
    _inFlightRequests.clear(); // Clear any pending requests
    _tabController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('🔥 PLACE DETAIL SCREEN - BUILDING WITH PLACE ID: ${widget.placeId}');
    final l10n = AppLocalizations.of(context)!;

    // Instant open when the user tapped a card we already have in memory (Explore / My Day).
    final memoryPlace =
        ref.read(placesServiceProvider.notifier).getCachedPlace(widget.placeId);
    if (memoryPlace != null &&
        memoryPlace.name.isNotEmpty &&
        memoryPlace.name != l10n.placeDetailUnavailableName) {
      if (_cachedPlace?.id != memoryPlace.id) {
        _cachedPlace = memoryPlace;
        _syncResolvedPlace(memoryPlace);
      }
      return Scaffold(
        backgroundColor: const Color(0xFFF5F0E8),
        body: _buildPlaceDetail(_placeForDetailBody(memoryPlace)),
        bottomNavigationBar: _buildBottomActionBar(_placeForDetailBody(memoryPlace)),
      );
    }

    // Prevent rebuild loops: If we have a cached place and it matches, use it immediately
    // Don't use broken fallback places — let the fetch retry succeed.
    // Don't do any provider reads/watches that could trigger rebuilds
    if (_cachedPlace != null && _cachedPlace!.id == widget.placeId && _isInitialized &&
        _cachedPlace!.name != l10n.placeDetailUnavailableName) {
      _syncResolvedPlace(_cachedPlace!);
      return Scaffold(
        backgroundColor: const Color(0xFFF5F0E8),
        body: _buildPlaceDetail(_cachedPlace!),
        bottomNavigationBar: _buildBottomActionBar(_cachedPlace!),
      );
    }
    
    // Resolve from Supabase places_cache aggregate only (same as Moody Hub / My Day free time).
    if (kDebugMode) debugPrint('🔍 Looking for place in places_cache aggregate...');
    final edgePlacesAsync = ref.watch(moodyHubExploreCacheOnlyProvider);
    
    return Scaffold(
        backgroundColor: const Color(0xFFF5F0E8),
        body: edgePlacesAsync.when(
          data: (places) {
            try {
              final place = places.firstWhere(
                (p) => p.id == widget.placeId,
              );
              _cachedPlace = place;
              _syncResolvedPlace(place);
              if (kDebugMode) debugPrint('✅ Place found in Edge Function cache');
              return _buildPlaceDetail(_placeForDetailBody(place));
            } catch (e) {
              // Place not found in Edge Function cache - always attempt direct fetch fallback.
              if (kDebugMode) {
                debugPrint(
                  '🔄 Place not in Edge Function cache, trying direct fallback for: ${widget.placeId}',
                );
              }
              return FutureBuilder<Place>(
                future: _fetchPlaceDirectly(widget.placeId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A6049)),
                      ),
                    );
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    final place = snapshot.data!;
                    _cachedPlace = place;
                    _syncResolvedPlace(place);
                    return _buildPlaceDetail(_placeForDetailBody(place));
                  }
                  return _buildErrorState(Exception(l10n.placeDetailNotFound));
                },
              );
            }
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A6049)),
            ),
          ),
          error: (error, stack) => _buildErrorState(error),
        ),
        bottomNavigationBar: _cachedPlace != null
            ? _buildBottomActionBar(_cachedPlace!)
            : const SizedBox.shrink(),
      );
  }
  
  /// Side effects when the resolved [Place] is known (reviews, booking state).
  void _syncResolvedPlace(Place place) {
    if (_currentPlace?.id != place.id) {
      _currentPlace = place;
      _cachedPlace = place;
      _hasAttemptedReviewFetch = false;
      _realReviews = [];
      _unifiedDetailPhotos = [];
      _unifiedDetailPhotosLoading = false;
      _unifiedDetailPhotosResolutionComplete = false;
      _unifiedPhotosResolvedPlaceId = null;
      _unifiedDetailPhotosInflightForPlaceId = null;
      _descriptionEnrichAttempted.clear();
      _enrichedWebsite = null;
      _enrichedPhone = null;
      TasteProfileService.recordFromPlace(
        place,
        interactionType: 'tapped',
        moodContext: ref.read(dailyMoodStateNotifierProvider).currentMood,
        timeSlot:
            TasteProfileService.inferTimeSlotFromHour(MoodyClock.now().hour),
      );
      // Only schedule photo/description loading when the place actually changes —
      // not on every rebuild — to prevent addPostFrameCallback accumulation.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _cachedPlace == null) return;
        _ensureUnifiedDetailPhotos(_cachedPlace!);
        _maybeEnrichDescription(_cachedPlace!);
      });
    }
  }

  /// Prefer [_cachedPlace] when it matches the same id so photo merges / unified
  /// resolution are visible (memory path used to pass a stale [memoryPlace]).
  Place _placeForDetailBody(Place candidate) {
    final c = _cachedPlace;
    if (c != null && c.id == candidate.id) return c;
    return candidate;
  }

  /// Sliver [FlexibleSpaceBar] already shows the first image; the Foto’s tab lists
  /// the remaining gallery only (up to 9) so the hero is not repeated in the grid.
  List<String> _fotosTabPhotoUrlsExcludingHero(List<String> unified) {
    if (unified.isEmpty) return const <String>[];
    if (unified.length == 1) {
      // Single image: nothing to add beyond the hero; avoid an empty tab.
      return List<String>.from(unified);
    }
    return unified.skip(1).take(9).toList();
  }

  /// Interim: [place.photos] until unified resolution completes; then the same
  /// merged list for hero, Foto's tab, strip, and fullscreen.
  List<String> _displayPhotosForDetail(Place place) {
    if (_unifiedDetailPhotosResolutionComplete &&
        _unifiedPhotosResolvedPlaceId == place.id) {
      return _unifiedDetailPhotos;
    }
    return place.photos;
  }

  Future<List<String>> _resolveUnifiedDetailPhotos(Place place) async {
    try {
      // 1. Card / cache order first (legacy /place/photo URLs that already work).
      var photos = place.photos.take(10).toList();
      // #region agent log
      _agentLogPlaceDetail(
        'H1',
        'resolve unified start',
        location: 'place_detail_screen.dart:_resolveUnifiedDetailPhotos:start',
        data: {
          'placeId': place.id,
          'initialCount': photos.length,
          'firstPhoto': photos.isNotEmpty ? _wmHeroDebugClipUrl(photos.first) : '',
          'hasV1Media': photos.any(isPlacesApiNewPhotoMediaUrl),
          'isGoogleBacked': _isGoogleBackedPlace(place.id),
        },
      );
      // #endregion

      // 2. Append legacy Details photo URLs only when the card did not already ship
      // a multi-image Places v1 gallery. Merging v1 + legacy repeats the same frames
      // (different URL strings for the same bitmap) and fills Foto's with duplicates.
      final hasMultiV1Gallery =
          photos.length >= 2 && photos.any(isPlacesApiNewPhotoMediaUrl);
      if (place.id.isNotEmpty && _isGoogleBackedPlace(place.id) && !hasMultiV1Gallery) {
        try {
          final urls = await ref
              .read(placesServiceProvider.notifier)
              .fetchPhotoUrlsForGooglePlace(place.id);
          // #region agent log
          _agentLogPlaceDetail(
            'H2',
            'fetched google place photo urls',
            location: 'place_detail_screen.dart:_resolveUnifiedDetailPhotos:fetchPhotoUrls',
            data: {
              'placeId': place.id,
              'fetchedCount': urls.length,
              'firstFetched': urls.isNotEmpty ? _wmHeroDebugClipUrl(urls.first) : '',
            },
          );
          // #endregion
          if (urls.isNotEmpty) {
            photos = PlacesService.mergeUniquePhotoUrls(
              photos,
              urls,
              maxPhotos: 10,
            );
          }
        } catch (e) {
          debugPrint(
            '📷 place_detail: fetchPhotoUrlsForGooglePlace failed for '
            '${place.id}: $e',
          );
        }
      }

      // 3. Last-resort rescue: still empty (e.g. deep-link / saved-place id
      // that doesn't match the google heuristic but DOES resolve via the
      // existing direct-fetch path). Reuse [_fetchPlaceDirectly] so the hero
      // does not stay grey just because the Place arrived without photos.
      if (photos.isEmpty) {
        try {
          final fetched = await _fetchPlaceDirectly(place.id);
          if (fetched.photos.isNotEmpty) {
            photos = fetched.photos.take(10).toList();
            if (kDebugMode) {
              debugPrint(
                '📷 place_detail: rescued ${photos.length} photo(s) via '
                '_fetchPlaceDirectly for non-Google id ${place.id}',
              );
            }
          }
        } catch (e) {
          debugPrint(
            '📷 place_detail: rescue _fetchPlaceDirectly failed for '
            '${place.id}: $e',
          );
        }
      }

      // Collapse exact + semantic dupes; strip repeats of the hero frame (v1 vs legacy).
      var merged = PlacesService.mergeUniquePhotoUrls(photos, [], maxPhotos: 10);
      merged = dedupeRepeatedHeroIdentity(merged);
      // Resolve Places API (New) `/media` → direct `photoUri` once so hero / Foto's /
      // CachedNetworkImage never follow redirects (iOS release hang on `/media`).
      merged = await resolvePlacesNewPhotoUrlList(merged);
      merged = dedupeRepeatedHeroIdentity(merged);
      // #region agent log
      _agentLogPlaceDetail(
        'H3',
        'resolved unified done',
        location: 'place_detail_screen.dart:_resolveUnifiedDetailPhotos:done',
        data: {
          'placeId': place.id,
          'finalCount': merged.length,
          'finalFirst': merged.isNotEmpty ? _wmHeroDebugClipUrl(merged.first) : '',
        },
      );
      // #endregion
      return PlacesService.mergeUniquePhotoUrls(merged, [], maxPhotos: 10);
    } catch (e) {
      debugPrint('📷 place_detail: error resolving unified detail photos: $e');
      final fb = PlacesService.mergeUniquePhotoUrls(place.photos, [], maxPhotos: 10);
      final deduped = dedupeRepeatedHeroIdentity(fb);
      final direct = await resolvePlacesNewPhotoUrlList(deduped);
      return dedupeRepeatedHeroIdentity(direct);
    }
  }

  /// One async pass: merges [place.photos] + Places API gallery, updates state
  /// and [_cachedPlace].photos so every surface reads the same list.
  Future<void> _ensureUnifiedDetailPhotos(Place place) async {
    if (!mounted) return;
    if (_unifiedPhotosResolvedPlaceId == place.id &&
        _unifiedDetailPhotosResolutionComplete) {
      return;
    }
    if (_unifiedDetailPhotosInflightForPlaceId == place.id) {
      return;
    }
    _unifiedDetailPhotosInflightForPlaceId = place.id;

    if (kDebugMode) {
      debugPrint(
        '📷 place_detail[${place.id}]: unified photos START '
        'initialPlacePhotos.len=${place.photos.length}',
      );
    }

    setState(() {
      _unifiedDetailPhotosLoading = true;
      if (_unifiedPhotosResolvedPlaceId != place.id) {
        _unifiedDetailPhotosResolutionComplete = false;
        _unifiedDetailPhotos = [];
      }
    });

    try {
      final merged = await _resolveUnifiedDetailPhotos(place);
      if (!mounted || _cachedPlace?.id != place.id) return;
      setState(() {
        _unifiedDetailPhotos = merged;
        _unifiedDetailPhotosResolutionComplete = true;
        _unifiedDetailPhotosLoading = false;
        _unifiedPhotosResolvedPlaceId = place.id;
        _cachedPlace = _cachedPlace!.copyWith(photos: merged);
        _currentPlace = _cachedPlace;
        if (merged.isEmpty) {
          _currentPhotoIndex = 0;
        } else if (_currentPhotoIndex >= merged.length) {
          _currentPhotoIndex = 0;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_photoController.hasClients) return;
        final n = merged.length;
        if (n == 0) return;
        final target = _currentPhotoIndex.clamp(0, n - 1);
        _photoController.jumpToPage(target);
      });
      // Warm the disk cache for the whole resolved gallery so swiping the hero
      // carousel (and opening Foto's / fullscreen) is instant. Fire-and-forget,
      // deduped, no UI side effects — the rendering path is unchanged.
      prefetchPlacePhotos(merged);
      if (kWmPlaceDetailHeroPhotoDebug && merged.isNotEmpty) {
        // ignore: avoid_print
        print(
          'WM_PLACE_DETAIL_HERO_DEBUG firstUrl=${merged.first} len=${merged.length} '
          'placeId=${place.id}',
        );
      }
      if (kDebugMode) {
        debugPrint(
          '📷 place_detail[${place.id}]: unified photos DONE '
          'resolvedLen=${merged.length} heroAndFotosUseSameList=true '
          'prefetchScheduled=${merged.length}',
        );
      }
    } catch (e) {
      if (!mounted || _cachedPlace?.id != place.id) return;
      final fallback = place.photos.take(10).toList();
      List<String> resolvedFb = fallback;
      try {
        resolvedFb = await resolvePlacesNewPhotoUrlList(fallback);
      } catch (_) {}
      setState(() {
        _unifiedDetailPhotos = resolvedFb;
        _unifiedDetailPhotosResolutionComplete = true;
        _unifiedDetailPhotosLoading = false;
        _unifiedPhotosResolvedPlaceId = place.id;
        _cachedPlace = _cachedPlace!.copyWith(photos: resolvedFb);
        _currentPlace = _cachedPlace;
        if (resolvedFb.isEmpty) {
          _currentPhotoIndex = 0;
        } else if (_currentPhotoIndex >= resolvedFb.length) {
          _currentPhotoIndex = 0;
        }
      });
      prefetchPlacePhotos(resolvedFb);
      if (kDebugMode) {
        debugPrint(
          '📷 place_detail[${place.id}]: unified photos ERROR -> fallback '
          'len=${resolvedFb.length} $e',
        );
      }
    } finally {
      if (_unifiedDetailPhotosInflightForPlaceId == place.id) {
        _unifiedDetailPhotosInflightForPlaceId = null;
      }
    }
  }

  bool _isGoogleBackedPlace(String id) {
    final t = id.trim();
    if (t.isEmpty) return false;
    if (t.startsWith('google_')) return true;
    return t.startsWith('ChIJ') || t.startsWith('EhIJ');
  }

  /// Fetches editorial description from Places API if the Place came from hub cache
  /// without one.
  Future<void> _maybeEnrichDescription(Place place) async {
    if (!_isGoogleBackedPlace(place.id)) return;
    if (_descriptionEnrichAttempted.contains(place.id)) return;
    // Always fetch once: Explore/cache may be English or wrong locale after mode switch.
    _descriptionEnrichAttempted.add(place.id);
    try {
      final raw = place.id.startsWith('google_')
          ? place.id.substring('google_'.length)
          : place.id;
      final details = await ref.read(placesServiceProvider.notifier).getPlaceDetails(raw);
      if (!mounted || _cachedPlace?.id != place.id) return;
      final desc = details['description'] as String?;
      final website = details['website'] as String?;
      final phone = details['phone_number'] as String?;
      setState(() {
        if (desc != null && desc.trim().isNotEmpty && !RegExp(r'^\d').hasMatch(desc.trim())) {
          _cachedPlace = _cachedPlace!.copyWith(description: desc);
          _currentPlace = _cachedPlace;
        }
        if (website != null && website.trim().isNotEmpty) _enrichedWebsite = website;
        if (phone != null && phone.trim().isNotEmpty) _enrichedPhone = phone;
      });
    } catch (_) {
      // keep existing description
    }
  }

  /// Primary directions CTA (v2 SCREEN 8). Booking removed — no booking system.
  Widget _buildBottomActionBar(Place place) {
    return _buildDirectionsBar(place);
  }

  Widget _buildPlaceDetail(Place place) {
    if (kDebugMode) debugPrint('🏗️ BUILDING PLACE DETAIL for: ${place.name}');
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        _buildSliverAppBar(place, innerBoxIsScrolled),
      ],
      body: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F0E8),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildTabBar(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildTabContent(place),
            ),
              ],
            ),
          ),
    );
  }

  Widget _buildSliverAppBar(Place place, bool innerBoxIsScrolled) {
    final l10n = AppLocalizations.of(context)!;
    // Use solid background when scrolled to prevent content bleed-through
    final backgroundColor = innerBoxIsScrolled
        ? const Color(0xFFF5F0E8)
        : Colors.transparent;
    
    final iconColor = innerBoxIsScrolled ? Colors.black : Colors.white;
    final buttonBackground = innerBoxIsScrolled
        ? Colors.white.withOpacity(0.9)
        : Colors.black.withOpacity(0.3);
    
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: backgroundColor,
      elevation: innerBoxIsScrolled ? 2 : 0,
      systemOverlayStyle: innerBoxIsScrolled
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: buttonBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            // Deep link / no stack: default to Explore.
            context.goNamed('main', extra: {'tab': 1});
          },
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: buttonBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.share, color: iconColor),
            onPressed: () => _sharePlace(place),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: buttonBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Consumer(
            builder: (context, ref, child) {
              final savedPlacesAsync = ref.watch(savedPlacesProvider);
              
              return savedPlacesAsync.when(
                data: (savedPlaces) {
                  final isSaved = savedPlaces.any((sp) => sp.placeId == place.id);
                  
                  return IconButton(
                    icon: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved ? Colors.red : iconColor,
                    ),
                    onPressed: () async {
                      final savedPlacesService = ref.read(savedPlacesServiceProvider);
                      try {
                        if (isSaved) {
                          await savedPlacesService.unsavePlace(place.id);
                          showWanderMoodToast(
                            context,
                            message: l10n.dayPlanCardRemovedFromSaved(place.name),
                          );
                        } else {
                          await savedPlacesService.savePlace(place);
                          showWanderMoodToast(
                            context,
                            message: l10n.placeDetailSavedToFavorites(place.name),
                          );
                        }
                        ref.invalidate(savedPlacesProvider);
                        HapticFeedback.lightImpact();
                      } catch (e) {
                        showWanderMoodToast(
                          context,
                          message: l10n.placeDetailSaveToggleFailed,
                          isError: true,
                        );
                      }
                    },
                  );
                },
                loading: () => IconButton(
                  icon: Icon(Icons.favorite_border, color: iconColor),
                  onPressed: () {},
                ),
                error: (_, __) => IconButton(
                  icon: Icon(Icons.favorite_border, color: iconColor),
                  onPressed: () {},
                ),
              );
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        // Default stretch/zoom competes with horizontal PageView drags on the hero.
        stretchModes: const [],
        background: ClipRect(
          child: _buildPhotoCarousel(place, l10n),
        ),
      ),
    );
  }

  Widget _placeDetailHeroLoadingScaffold(AppLocalizations l10n) {
    return Container(
      color: const Color(0xFFE0E4E8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A6049)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.placeDetailLoadingPhotos,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF8C8780),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCarousel(Place place, AppLocalizations l10n) {
    // Interim [place.photos] for Google often carries Places New `/media` strings.
    // [WmPlacePhotoNetworkImage] must resolve those; painting before
    // [_resolveUnifiedDetailPhotos] finishes can leave the IPA hero stuck on grey
    // (LoadingBuilder / redirect hang). Wait for the merged, resolved list.
    final bool googleHeroUntilUnified = _isGoogleBackedPlace(place.id) &&
        !(_unifiedDetailPhotosResolutionComplete &&
            _unifiedPhotosResolvedPlaceId == place.id);
    if (googleHeroUntilUnified) {
      return _placeDetailHeroLoadingScaffold(l10n);
    }

    final photos = _displayPhotosForDetail(place);
    if (kDebugMode) {
      debugPrint(
        '📷 place_detail HERO placeId=${place.id} displayPhotos.len=${photos.length} '
        'unifiedComplete=$_unifiedDetailPhotosResolutionComplete '
        'unifiedLen=${_unifiedDetailPhotos.length}',
      );
    }

    if (photos.isEmpty) {
      if (_unifiedDetailPhotosLoading) {
        // Same loading path as Foto's tab while the unified list is resolving.
        return _placeDetailHeroLoadingScaffold(l10n);
      }
      return Container(
        color: const Color(0xFFE0E4E8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              l10n.placeDetailNoPhotos,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: photos.length < 2
          ? null
          : (details) {
              final v = details.primaryVelocity ?? 0;
              if (v < -280 && _currentPhotoIndex < photos.length - 1) {
                _photoController.nextPage(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                );
              } else if (v > 280 && _currentPhotoIndex > 0) {
                _photoController.previousPage(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                );
              }
            },
      child: Stack(
      key: ValueKey<int>(photos.length),
      children: [
        PageView.builder(
          controller: _photoController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _currentPhotoIndex = index),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photoUrl = photos[index].trim();
            if (!place.isAsset && photoUrl.isEmpty) {
              return _buildImageFallback();
            }
            return place.isAsset
                ? Image.asset(
                    photos[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImageFallback(),
                  )
                : WmPlacePhotoNetworkImage(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImageFallback(),
                  );
          },
        ),
        // Pass touches through to PageView (these layers sit above it in the Stack).
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          left: 24,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Activity tags
              if (place.activities.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: place.activities.take(2).map((activity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _pdWmForestTint,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _pdWmParchment, width: 0.5),
                      ),
                      child: Text(
                        _localizedPlaceActivityLabel(context, activity),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                          color: _pdWmForest,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              // Place name (activity name only, no location)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getCleanActivityName(place.name),
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Rating badge
                  if (place.rating > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A6049),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            place.rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              // Removed address from image overlay as requested
              ],
            ),
          ),
        ),
        if (photos.length > 1) ...[
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(photos.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPhotoIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
        if (kWmPlaceDetailHeroPhotoDebug && photos.isNotEmpty)
          Positioned(
            left: 8,
            right: 8,
            top: 52,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    'hero[${_currentPhotoIndex.clamp(0, photos.length - 1)}/${photos.length}]\n'
                    'unified=$_unifiedDetailPhotosResolutionComplete '
                    'load=$_unifiedDetailPhotosLoading\n'
                    '${_wmHeroDebugClipUrl(photos[_currentPhotoIndex.clamp(0, photos.length - 1)])}',
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image, size: 64, color: Colors.grey),
      ),
    );
  }



  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: _pdWmCard,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _pdWmCardBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: _pdWmCharcoal.withValues(alpha: 0.78),
        indicator: BoxDecoration(
          color: _pdWmForest,
          borderRadius: BorderRadius.circular(28),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(text: '✨ ${l10n.placeDetailTabDetails}'),
          Tab(text: '📸 ${l10n.placeDetailTabPhotos}'),
          Tab(text: '⭐ ${l10n.placeDetailTabReviews}'),
        ],
      ),
      ),
    );
  }

  Widget _buildTabContent(Place place) {
    if (kDebugMode) debugPrint('📋 BUILDING TAB CONTENT for: ${place.name}');
    return Padding(
        padding: const EdgeInsets.all(24),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDetailsTab(place),
            _buildPhotosTab(place),
          _buildReviewsTab(place),
          ],
      ),
    );
  }

  Widget _buildDetailsTab(Place place) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // v2: Duration / Price / Distance — uniform tiles (SCREEN 8)
          _buildQuickStatsRow(place),
          const SizedBox(height: 24),
          // About section - title only
          Row(
            children: [
              const Text(
                '🏛️✨',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.placeDetailAboutThisPlace,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _pdWmCharcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Rich place info card
          _buildPlaceInfoCard(place),
          const SizedBox(height: 24),
          if (place.openingHours != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _pdWmCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _pdWmCardBorder,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _pdWmForestTint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _pdWmParchment,
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          Icons.schedule,
                          size: 20,
                          color: _pdWmForest,
                        ),
                      ),
                      const SizedBox(width: 12),
            Text(
                        l10n.placeDetailOpeningHours,
              style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _pdWmCharcoal,
              ),
                      ),
                    ],
            ),
                  const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                      color: _pdWmCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: place.openingHours!.isOpen
                            ? _pdWmForest.withOpacity(0.25)
                            : Colors.red.withOpacity(0.35),
                        width: 1.5,
                      ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                              width: 12,
                              height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: place.openingHours!.isOpen
                              ? _pdWmForest
                              : Colors.red,
                                boxShadow: [
                                  BoxShadow(
                                    color: place.openingHours!.isOpen
                                        ? _pdWmForest.withOpacity(0.3)
                                        : Colors.red.withOpacity(0.3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                        ),
                      ),
                            const SizedBox(width: 12),
                      Text(
                              place.openingHours!.isOpen
                                  ? l10n.placeDetailHeroOpenNowLine
                                  : l10n.placeDetailHeroClosedLine,
                        style: GoogleFonts.poppins(
                                fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: place.openingHours!.isOpen
                              ? _pdWmForest
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (place.openingHours!.currentStatus != null) ...[
                          const SizedBox(height: 8),
                    Text(
                      _localizedOpeningSecondary(
                            l10n,
                            place.openingHours!.currentStatus,
                          ) ??
                          place.openingHours!.currentStatus!,
                      style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: _pdWmCharcoal.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Features section - colorful pills without card container
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  children: [
                    const Text(
                      '✨',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
          Text(
                      l10n.placeDetailAmazingFeatures,
            style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _pdWmCharcoal,
                      ),
                    ),
                  ],
            ),
          ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36, // Fixed height for carousel
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: (place.types.isNotEmpty ? 3 : 2),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildColorfulFeatureChip(
                          place.isIndoor ? '🏠' : '☀️',
                          place.isIndoor
                              ? l10n.placeDetailIndoorVibes
                              : l10n.placeDetailOutdoorFun,
                        ),
                      );
                    } else if (index == 1) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildColorfulFeatureChip(
                          _getEnergyEmoji(place.energyLevel),
                          _energyChipLabel(l10n, place.energyLevel),
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildColorfulFeatureChip(
                          _getCategoryEmoji(place.types.first),
                          _localizedGooglePlaceType(l10n, place.types.first),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildGoodToKnow(place),
          const SizedBox(height: 24),
          _buildImageCarousel(place),
        ],
      ),
    );
  }

  /// Localize common English activity chips on the hero (Explore cache often ships English labels).
  String _localizedPlaceActivityLabel(BuildContext context, String activity) {
    final l10n = AppLocalizations.of(context)!;
    final t = activity.toLowerCase();
    if (t.contains('food tour') || t.contains('tasting')) return l10n.placeCategoryFood;
    if (t.contains('shopping')) return l10n.placeCategoryShopping;
    if (t.contains('museum') || t.contains('gallery')) return l10n.placeCategoryMuseum;
    if (t.contains('park') || t.contains('walk') || t.contains('nature')) return l10n.placeCategoryNature;
    if (t.contains('night') || t.contains('bar ') || t.contains('club')) return l10n.placeCategoryNightlife;
    if (t.contains('coffee') || t.contains('café') || t.contains('cafe')) return l10n.placeCategoryCafe;
    if (t.contains('restaurant') || t.contains('dining')) return l10n.placeCategoryRestaurant;
    if (t.contains('adventure') || t.contains('hiking')) return l10n.placeCategoryAdventure;
    if (t.contains('culture') || t.contains('historic')) return l10n.placeCategoryCulture;
    return activity;
  }

  String _energyChipLabel(AppLocalizations l10n, String energyLevel) {
    final e = energyLevel.toLowerCase().trim();
    if (e.contains('low')) return l10n.placeDetailEnergyChipLow;
    if (e.contains('high')) return l10n.placeDetailEnergyChipHigh;
    return l10n.placeDetailEnergyChipMedium;
  }

  String _localizedGooglePlaceType(AppLocalizations l10n, String rawType) {
    final t = rawType.toLowerCase().replaceAll('_', ' ').trim();
    switch (t) {
      case 'restaurant':
      case 'meal takeaway':
      case 'meal delivery':
      case 'food':
        return l10n.placeCategoryRestaurant;
      case 'cafe':
      case 'coffee shop':
      case 'bakery':
        return l10n.placeCategoryCafe;
      case 'bar':
      case 'night club':
        return l10n.placeCategoryBar;
      case 'museum':
      case 'art gallery':
        return l10n.placeCategoryMuseum;
      case 'park':
      case 'natural feature':
        return l10n.placeCategoryPark;
      case 'shopping mall':
      case 'store':
        return l10n.placeCategoryShopping;
      case 'tourist attraction':
      case 'point of interest':
        return l10n.placeCategorySpot;
      case 'spa':
      case 'beauty salon':
        return l10n.placeCategoryCulture;
      default:
        return formatPlaceType(rawType, languageCode: l10n.localeName);
    }
  }

  String? _localizedOpeningSecondary(AppLocalizations l10n, String? status) {
    if (status == null || status.isEmpty) return null;
    final s = status.trim().toLowerCase();
    if (s == 'open' || s == 'opened' || s == 'geopend') {
      return l10n.placeDetailHeroOpenNow;
    }
    if (s == 'closed' || s == 'gesloten') {
      return l10n.placeDetailHeroClosed;
    }
    return null;
  }

  // Helper method to clean activity name by removing location info
  String _getCleanActivityName(String name) {
    // Remove common location patterns like "Rotterdam, The Netherlands", "Rotterdam", etc.
    final patterns = [
      ', Rotterdam, The Netherlands',
      ', Rotterdam',
      ', The Netherlands',
      ' Rotterdam',
      ' The Netherlands',
    ];
    
    String cleanName = name;
    for (final pattern in patterns) {
      cleanName = cleanName.replaceAll(pattern, '');
    }
    
    return cleanName.trim();
  }

  /// Duration / Price / Distance — three matching tiles: wmCream + wmParchment + wmForest icons (SCREEN 8).
  Widget _buildQuickStatsRow(Place place) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildStandaloneInfoTile(
            icon: Icons.schedule,
            label: l10n.placeDetailDurationLabel,
            value: _getDurationText(place, l10n),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStandaloneInfoTile(
            icon: Icons.euro,
            label: l10n.placeDetailPriceLabel,
            value: _getCostText(place, l10n),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStandaloneInfoTile(
            icon: Icons.directions_walk,
            label: l10n.placeDetailDistanceLabel,
            value: _distanceLineForPlace(place, l10n),
          ),
        ),
      ],
    );
  }

  Widget _buildStandaloneInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _pdWmCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _pdWmCardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _pdWmForest),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: _pdWmCharcoal.withValues(alpha: 0.55),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: _pdWmCharcoal,
            ),
          ),
        ],
      ),
    );
  }

  String _distanceLineForPlace(Place place, AppLocalizations l10n) {
    final lat = place.location.lat;
    final lng = place.location.lng;
    final placeHasCoords =
        lat.abs() > 1e-6 || lng.abs() > 1e-6;
    if (!placeHasCoords) {
      return '—';
    }
    return ref.watch(userLocationProvider).when(
      data: (pos) {
        if (pos == null) {
          return l10n.placeDetailOpenMaps;
        }
        final km = DistanceService.calculateDistance(
          pos.latitude,
          pos.longitude,
          lat,
          lng,
        );
        if (km > 2500) {
          return '—';
        }
        return DistanceService.formatDistance(km);
      },
      loading: () => '…',
      error: (_, __) => l10n.placeDetailOpenMaps,
    );
  }

  /// New "Good to know" section - lighter and more decision-focused
  Widget _buildGoodToKnow(Place place) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    final bestTime = _getBestTimeForPlace(place, hour, l10n);
    final goodWith = _getGoodWithContext(place, l10n);
    final energyLevel = place.energyLevel;
    final timeNeeded = _getTimeNeeded(place, l10n);
    final moodAwareLabel = _getMoodAwareLabel(place, hour, l10n);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _pdWmCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _pdWmCardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '💡',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.placeDetailGoodToKnow,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _pdWmCharcoal,
                ),
              ),
            ],
          ),
          // Mood-aware label (if applicable)
          if (moodAwareLabel != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _pdWmForestTint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _pdWmParchment, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '✨',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    moodAwareLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _pdWmForest,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Quick info grid
          Row(
            children: [
              Expanded(
                child: _buildCompactInfoCard(
                  '🕐',
                  l10n.placeDetailBestTimeLabel,
                  bestTime,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactInfoCard(
                  '👥',
                  l10n.placeDetailGoodWithLabel,
                  goodWith,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCompactInfoCard(
                  '⚡',
                  l10n.placeDetailEnergyLabel,
                  energyLevel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactInfoCard(
                  '⏱️',
                  l10n.placeDetailTimeNeededLabel,
                  timeNeeded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Helper to build compact info cards for Good to know section
  Widget _buildCompactInfoCard(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _pdWmWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _pdWmCardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                  color: _pdWmCharcoal.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _pdWmCharcoal,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get best time for place based on current hour and place properties
  String _getBestTimeForPlace(Place place, int hour, AppLocalizations l10n) {
    // Check place type for time hints
    final types = place.types.map((t) => t.toLowerCase()).toList();
    
    if (types.any((t) => t.contains('bar') || t.contains('night_club') || t.contains('nightclub'))) {
      return l10n.placeDetailEvening;
    } else if (types.any((t) => t.contains('cafe') || t.contains('breakfast'))) {
      return l10n.placeDetailMorning;
    } else if (types.any((t) => t.contains('restaurant'))) {
      return l10n.placeDetailBestTimeLunchDinner;
    }
    
    // Fallback to energy level
    if (place.energyLevel.toLowerCase() == 'high') {
      return l10n.placeDetailAfternoon;
    } else if (place.energyLevel.toLowerCase() == 'low') {
      return l10n.placeDetailAnytime;
    } else {
      return l10n.placeDetailMorning;
    }
  }
  
  /// Helper to check if place is good for groups based on type
  bool _isGoodForGroups(Place place) {
    final types = place.types.map((t) => t.toLowerCase()).toList();
    return types.any((t) => 
      t.contains('restaurant') || 
      t.contains('bar') || 
      t.contains('park') || 
      t.contains('stadium') ||
      t.contains('bowling') ||
      t.contains('amusement') ||
      t.contains('tourist_attraction')
    );
  }
  
  /// Get social context for place
  String _getGoodWithContext(Place place, AppLocalizations l10n) {
    if (_isGoodForGroups(place)) {
      return l10n.placeDetailFriendsGroups;
    } else if (place.types.any((t) => 
      t.contains('restaurant') || t.contains('cafe') || t.contains('bar'))) {
      return l10n.placeDetailSoloDate;
    } else {
      return l10n.placeDetailSoloFriends;
    }
  }
  
  /// Get estimated time needed
  String _getTimeNeeded(Place place, AppLocalizations l10n) {
    if (place.types.any((t) =>
        t.contains('museum') || t.contains('art_gallery') || t.contains('zoo'))) {
      return l10n.placeDetailDurationTwoToThree;
    } else if (place.types.any((t) =>
        t.contains('cafe') || t.contains('bar') || t.contains('restaurant'))) {
      return l10n.placeDetailDurationOneToTwo;
    } else if (place.energyLevel.toLowerCase() == 'high') {
      return l10n.placeDetailDurationTwoToFour;
    } else {
      return l10n.placeDetailDurationAboutOneHour;
    }
  }
  
  /// Get mood-aware label based on current time and place properties
  String? _getMoodAwareLabel(Place place, int hour, AppLocalizations l10n) {
    final isEvening = hour >= 17;
    final isWeekend = DateTime.now().weekday >= 6;
    final isLateNight = hour >= 21 || hour < 6;
    
    // Evening fit
    if (isEvening && place.energyLevel.toLowerCase() != 'low' && 
        place.types.any((t) => 
          t.contains('bar') || t.contains('restaurant') || t.contains('night_club'))) {
      return l10n.placeDetailGoodFitForTonight;
    }
    
    // Weekend fit
    if (isWeekend && _isGoodForGroups(place)) {
      return l10n.placeDetailBestOnWeekends;
    }
    
    // Chill warning
    if (place.energyLevel.toLowerCase() == 'high' && hour < 12) {
      return l10n.placeDetailSkipIfChill;
    }
    
    // Late night warning
    if (isLateNight && place.openingHours != null && !place.openingHours!.isOpen) {
      return l10n.placeDetailClosedCheckHours;
    }
    
    return null; // No special label
  }

  Widget _buildInfoItem(String emoji, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFullWidthInfoItem(String emoji, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.amber[800],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[900],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCostText(Place place, AppLocalizations l10n) {
    if (place.isFree) return l10n.placeDetailFreeToVisit;
    if (place.priceRange != null) return place.priceRange!;
    if (place.priceLevel != null) {
      switch (place.priceLevel!) {
        case 0: return l10n.placeDetailFreeToVisit;
        case 1: return l10n.placeDetailPrice5to15;
        case 2: return l10n.placeDetailPrice15to35;
        case 3: return l10n.placeDetailPrice30to50;
        case 4: return l10n.placeDetailPrice50Plus;
        default: return l10n.placeDetailVaries;
      }
    }
    return _inferCostFromPlace(place, l10n);
  }

  String _inferCostFromPlace(Place place, AppLocalizations l10n) {
    final placeName = place.name.toLowerCase();
    final description = place.description?.toLowerCase() ?? '';
    
    // Check specific place names/types
    if (placeName.contains('park') || placeName.contains('garden') || 
        placeName.contains('beach') || placeName.contains('square') ||
        placeName.contains('harbor') || placeName.contains('haven')) {
      return l10n.placeDetailFreeToVisit;
    }
    
    if (placeName.contains('museum') || placeName.contains('gallery')) {
      return l10n.placeDetailPrice8to25;
    }
    
    if (placeName.contains('market') || placeName.contains('markt')) {
      return l10n.placeDetailFreeEntryPayItems;
    }
    
    if (placeName.contains('restaurant') || placeName.contains('cafe')) {
      if (description.contains('fine dining') || description.contains('upscale')) {
        return l10n.placeDetailPrice40to80;
      }
      return l10n.placeDetailPrice15to35;
    }
    
    if (placeName.contains('mall') || placeName.contains('shopping')) {
      return l10n.placeDetailFreeEntryPayItems;
    }
    
    if (placeName.contains('church') || placeName.contains('cathedral')) {
      return l10n.placeDetailFreeDonationsWelcome;
    }
    
    if (placeName.contains('tower') || placeName.contains('observation')) {
      return l10n.placeDetailPrice10to20;
    }
    
    // Fallback to place types
    for (final type in place.types) {
      switch (type.toLowerCase()) {
        case 'park':
        case 'tourist_attraction':
          return l10n.placeDetailFreeToVisit;
        case 'museum':
          return l10n.placeDetailPrice10to25;
        case 'restaurant':
          return l10n.placeDetailPrice15to40;
        case 'shopping_mall':
          return l10n.placeDetailFreeEntry;
        default:
          continue;
      }
    }
    return l10n.placeDetailCheckLocally;
  }

  String _getDurationText(Place place, AppLocalizations l10n) {
    final placeName = place.name.toLowerCase();
    final activities = place.activities.join(' ').toLowerCase();

    if (placeName.contains('museum') || placeName.contains('gallery')) {
      return l10n.placeDetailDurationOneHalfToThree;
    }

    if (placeName.contains('market') || placeName.contains('markt')) {
      return l10n.placeDetailDurationFortyFiveToNinety;
    }

    if (placeName.contains('restaurant') || placeName.contains('cafe')) {
      if (placeName.contains('quick') || placeName.contains('fast')) {
        return l10n.placeDetailDurationThirtyToFortyFive;
      }
      return l10n.placeDetailDurationOneToTwo;
    }

    if (placeName.contains('park') || placeName.contains('garden')) {
      if (activities.contains('walk') || activities.contains('stroll')) {
        return l10n.placeDetailDurationOneToThree;
      }
      return l10n.placeDetailDurationTwoToFour;
    }

    if (placeName.contains('mall') || placeName.contains('shopping')) {
      return l10n.placeDetailDurationOneToThree;
    }

    if (placeName.contains('church') || placeName.contains('cathedral')) {
      return l10n.placeDetailDurationThirtyToSixty;
    }

    if (placeName.contains('tower') ||
        placeName.contains('observation') ||
        placeName.contains('viewpoint')) {
      return l10n.placeDetailDurationFortyFiveToNinety;
    }

    if (placeName.contains('harbor') ||
        placeName.contains('haven') ||
        placeName.contains('waterfront')) {
      return l10n.placeDetailDurationOneToTwo;
    }

    if (activities.contains('quick tour') || activities.contains('short visit')) {
      return l10n.placeDetailDurationThirtyToSixty;
    }

    if (activities.contains('dining') || activities.contains('meal')) {
      return l10n.placeDetailDurationOneToTwo;
    }

    if (activities.contains('shopping')) {
      return l10n.placeDetailDurationOneToThree;
    }

    for (final type in place.types) {
      switch (type.toLowerCase()) {
        case 'restaurant':
        case 'cafe':
          return l10n.placeDetailDurationOneToTwo;
        case 'museum':
        case 'tourist_attraction':
          return l10n.placeDetailDurationOneToTwoPointFive;
        case 'park':
          return l10n.placeDetailDurationOneToFour;
        case 'shopping_mall':
          return l10n.placeDetailDurationOneToThree;
        default:
          continue;
      }
    }

    return l10n.placeDetailDurationAllowOneToTwo;
  }

  String _getAccessibilityText(Place place) {
    // Check description or activities for accessibility mentions
    final description = place.description?.toLowerCase() ?? '';
    final activities = place.activities.join(' ').toLowerCase();
    
    if (description.contains('accessible') || 
        description.contains('wheelchair') ||
        activities.contains('accessible') ||
        activities.contains('easy walking')) {
      return 'Easy walking (accessible)';
    }
    
    // Check place types for accessibility assumptions
    for (final type in place.types) {
      switch (type.toLowerCase()) {
        case 'museum':
        case 'restaurant':
        case 'shopping_mall':
          return 'Easy walking (accessible)';
        case 'park':
          return 'Moderate walking';
        case 'tourist_attraction':
          return 'Check locally';
        default:
          continue;
      }
    }
    
    return 'Easy walking';
  }

  String _getBestTimeText(Place place) {
    final placeName = place.name.toLowerCase();
    final description = place.description?.toLowerCase() ?? '';
    final activities = place.activities.join(' ').toLowerCase();
    
    // First check for specific place characteristics
    if (placeName.contains('market') || placeName.contains('markt')) {
      return 'Morning hours (fresh produce)';
    }
    
    if (placeName.contains('museum') || placeName.contains('gallery')) {
      return 'Weekday mornings (less crowded)';
    }
    
    if (placeName.contains('restaurant') || placeName.contains('cafe') || placeName.contains('bar')) {
      if (placeName.contains('breakfast') || description.contains('breakfast')) {
        return 'Early morning (8-11 AM)';
      }
      if (placeName.contains('lunch') || description.contains('lunch')) {
        return 'Lunch hours (12-3 PM)';
      }
      return 'Evening for dinner (6-9 PM)';
    }
    
    if (placeName.contains('park') || placeName.contains('garden')) {
      if (activities.contains('photo') || description.contains('scenic')) {
        return 'Golden hour (6-8 PM) for photos';
      }
      return 'Sunny weather, any time of day';
    }
    
    if (placeName.contains('beach') || placeName.contains('waterfront') || placeName.contains('harbor') || placeName.contains('haven')) {
      return 'Golden hour (sunset) for photos';
    }
    
    if (placeName.contains('mall') || placeName.contains('shopping') || placeName.contains('store')) {
      return 'Weekday afternoons (less busy)';
    }
    
    if (placeName.contains('church') || placeName.contains('cathedral') || placeName.contains('temple')) {
      return 'Quiet morning hours';
    }
    
    if (placeName.contains('tower') || placeName.contains('viewpoint') || placeName.contains('observation')) {
      return 'Clear weather, sunset for views';
    }
    
    // Check activities for specific recommendations
    if (activities.contains('food') || activities.contains('dining')) {
      return 'Meal times (lunch or dinner)';
    }
    
    if (activities.contains('shopping')) {
      return 'Weekday afternoons (less crowded)';
    }
    
    if (activities.contains('photo') || activities.contains('sightseeing')) {
      // Only recommend sunset if it's actually outdoor/scenic
      if (place.isIndoor || placeName.contains('hall') || placeName.contains('mall')) {
        return 'Good lighting hours (10 AM - 4 PM)';
      }
      return 'Golden hour (6-8 PM) for photos';
    }
    
    // Final fallback based on place type with better logic
    for (final type in place.types) {
      switch (type.toLowerCase()) {
        case 'restaurant':
        case 'food':
          return 'Meal times (check opening hours)';
        case 'museum':
          return 'Weekday mornings (less crowded)';
        case 'shopping_mall':
        case 'store':
          return 'Weekday afternoons';
        case 'park':
          return 'Sunny weather preferred';
        default:
          continue;
      }
    }
    
    return 'Check opening hours for best times';
  }

  /// Category / feature pills — v2 forest system (SCREEN 8).
  Widget _buildColorfulFeatureChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _pdWmForestTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pdWmParchment, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: _pdWmForest,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  String _getEnergyEmoji(String energyLevel) {
    switch (energyLevel.toLowerCase()) {
      case 'low':
        return '😌';
      case 'medium':
        return '⚡';
      case 'high':
        return '🔥';
      default:
        return '⚡';
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'tourist_attraction':
        return '🏛️';
      case 'museum':
        return '🏛️';
      case 'park':
        return '🌳';
      case 'restaurant':
        return '🍽️';
      case 'shopping':
        return '🛍️';
      case 'entertainment':
        return '🎭';
      case 'nature':
        return '🌿';
      case 'culture':
        return '🎨';
      default:
        return '📍';
    }
  }

  Widget _buildImageCarousel(Place place) {
    final l10n = AppLocalizations.of(context)!;
    final raw = _displayPhotosForDetail(place);
    if (kDebugMode) {
      debugPrint(
        '📷 place_detail STRIP placeId=${place.id} displayPhotos.len=${raw.length} '
        'sameUnifiedListAsHero=true',
      );
    }
    var allImages = List<String>.from(raw);
    if (allImages.isEmpty) {
      allImages = [
        'assets/images/fallbacks/default.jpg',
        'assets/images/fallbacks/default_place.jpg',
      ];
    }
    final showStripSpinner =
        _unifiedDetailPhotosLoading && raw.isEmpty && !place.isAsset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
      children: [
        Text(
          '📸 ${l10n.placeDetailGalleryTitle}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
                ),
                if (showStripSpinner) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF2A6049),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  l10n.placeDetailPhotoCount(allImages.length),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
                itemCount: allImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.only(
                      right: index == allImages.length - 1 ? 0 : 12,
                ),
                child: GestureDetector(
                      onTap: () => _showFullScreenPhoto(allImages, index, place.isAsset),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                      ),
                          child: Stack(
                            children: [
                              place.isAsset
                          ? Image.asset(
                                      allImages[index],
                              fit: BoxFit.cover,
                                      width: 150,
                                      height: 120,
                              errorBuilder: (_, __, ___) => _buildImageFallback(),
                            )
                          : WmPlacePhotoNetworkImage(
                                      allImages[index],
                              fit: BoxFit.cover,
                                      width: 150,
                                      height: 120,
                              errorBuilder: (_, __, ___) => _buildImageFallback(),
                                    ),
                              // Add a subtle gradient overlay for better visual appeal
                              Container(
                                width: 150,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.1),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Rich info card shown between Moody tips and Opening Hours.
  /// Shows: category chips, editorial description, and address.
  Widget _buildPlaceInfoCard(Place place) {
    final l10n = AppLocalizations.of(context)!;

    // Derive human-readable category labels from place.types
    final categoryChips = <String>[];
    for (final t in place.types.take(6)) {
      final label = _typeToCategoryLabel(t, l10n);
      if (label != null && !categoryChips.contains(label)) {
        categoryChips.add(label);
        if (categoryChips.length >= 3) break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _pdWmCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pdWmCardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category chips
          if (categoryChips.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: categoryChips.map((chip) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _pdWmForestTint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _pdWmParchment, width: 0.5),
                  ),
                  child: Text(
                    chip,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _pdWmForest,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          // Description — sectioned rich copy or long blurb (no misleading loading text)
          PlaceDetailAboutBlock(place: place),
          // Address
          if (place.address.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on_outlined, place.address),
          ],
          // Phone
          if (_enrichedPhone != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('tel:${_enrichedPhone!}')),
              child: _buildInfoRow(Icons.phone_outlined, _enrichedPhone!,
                  tappable: true),
            ),
          ],
          // Website
          if (_enrichedWebsite != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse(_enrichedWebsite!),
                  mode: LaunchMode.externalApplication),
              child: _buildInfoRow(Icons.language_outlined,
                  _enrichedWebsite!.replaceFirst(RegExp(r'^https?://'), ''),
                  tappable: true),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool tappable = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: tappable ? _pdWmForest : _pdWmForest.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: tappable
                  ? _pdWmForest
                  : _pdWmCharcoal.withValues(alpha: 0.65),
              height: 1.4,
              decoration: tappable ? TextDecoration.underline : null,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  /// Map a Google place type string to a localised label. Returns null for generic/useless types.
  String? _typeToCategoryLabel(String type, AppLocalizations l10n) {
    switch (type.toLowerCase()) {
      case 'restaurant': return l10n.placeTypeRestaurant;
      case 'cafe': case 'coffee_shop': return l10n.placeTypeCafe;
      case 'bar': return l10n.placeTypeBar;
      case 'night_club': return l10n.placeTypeNightclub;
      case 'museum': return l10n.placeTypeMuseum;
      case 'art_gallery': return l10n.placeTypeArtGallery;
      case 'park': case 'national_park': return l10n.placeTypePark;
      case 'tourist_attraction': return l10n.placeTypeTouristAttraction;
      case 'bakery': return l10n.placeTypeBakery;
      case 'shopping_mall': return l10n.placeTypeShoppingMall;
      case 'spa': return l10n.placeTypeSpa;
      case 'gym': case 'health': return l10n.placeTypeGym;
      case 'movie_theater': return l10n.placeTypeMovieTheater;
      case 'library': return l10n.placeTypeLibrary;
      case 'church': case 'place_of_worship': return l10n.placeTypeChurch;
      case 'amusement_park': return l10n.placeTypeAmusementPark;
      case 'zoo': return l10n.placeTypeZoo;
      case 'aquarium': return l10n.placeTypeAquarium;
      case 'bowling_alley': return l10n.placeTypeBowling;
      case 'stadium': return l10n.placeTypeStadium;
      default: return null;
    }
  }

  Widget _buildMoodyTips(Place place) {
    final l10n = AppLocalizations.of(context)!;
    // Cache the Future to avoid creating new ones on every rebuild
    if (_cachedMoodyTipsFuture == null || _cachedPlaceIdForTips != place.id) {
      _cachedMoodyTipsFuture = _generateAIMoodyTips(place);
      _cachedPlaceIdForTips = place.id;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _pdWmCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pdWmCardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const MoodyAvatarCompact(size: 30, glowOpacityScale: 0.18),
              const SizedBox(width: 8),
            Text(
                l10n.placeDetailMoodyName,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                fontWeight: FontWeight.w600,
                  color: const Color(0xFF2A6049),
              ),
            ),
          ],
        ),
          const SizedBox(height: 8),
          FutureBuilder<List<String>>(
            future: _cachedMoodyTipsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                      children: [
                        SizedBox(
                        width: 12,
                        height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF2A6049),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.placeDetailMoodyLoadingTips,
                            style: GoogleFonts.poppins(
                          fontSize: 13,
                              fontStyle: FontStyle.italic,
                          color: const Color(0xFF2A6049),
                          ),
                        ),
                      ),
                      ],
                    ),
                );
              }
              
              final moodyTips = snapshot.data ?? [
                l10n.placeDetailMoodyFallbackTipA,
                l10n.placeDetailMoodyFallbackTipB,
                l10n.placeDetailMoodyFallbackTipC,
              ];
              
              // Combine all tips into one conversational message
              final conversationalTip = _formatTipsAsConversation(moodyTips, place);
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _pdWmForestTint.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _pdWmParchment.withValues(alpha: 0.9),
                    width: 1,
                  ),
                ),
                          child: Text(
                  conversationalTip,
                            style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.4,
                    color: const Color(0xFF2E2E2E),
                    fontWeight: FontWeight.w400,
                            ),
                          ),
              );
            },
                        ),
                      ],
                    ),
                  );
  }

  String _formatTipsAsConversation(List<String> tips, Place place) {
    if (tips.isEmpty) {
      // Fallback decision-focused message based on place properties
      return _getDecisionFocusedMessage(place);
    }
    
    // Take first tip only and make it decision-focused (1-2 sentences max)
    String tip = tips.first;
    
    // Clean up the tip (remove ** formatting)
    tip = tip.replaceAll('**', '').replaceAll('*', '').trim();
    
    // Keep it short and decision-oriented (max 2 sentences)
    if (tip.length > 120) {
      // Find the first sentence or cut at 120 chars
      final firstSentence = tip.split(RegExp(r'[.!?]')).first;
      tip = firstSentence.length <= 120 ? firstSentence + '.' : tip.substring(0, 117) + '...';
    }
    
    return tip;
  }
  
  /// Generate a decision-focused message based on place properties
  String _getDecisionFocusedMessage(Place place) {
    final hour = DateTime.now().hour;
    final isEvening = hour >= 17;
    final isMorning = hour < 12;
    
    // Build decision-focused message based on place characteristics
    String fitContext = '';
    String energyNote = '';
    
    // Determine fit based on time and energy level
    if (place.energyLevel.toLowerCase() == 'high') {
      fitContext = isEvening ? 'evening' : 'daytime';
      energyNote = 'engaging but high-energy';
    } else if (place.energyLevel.toLowerCase() == 'low' || place.energyLevel.toLowerCase() == 'relaxed') {
      fitContext = 'any time';
      energyNote = 'relaxed and easy-going';
    } else {
      fitContext = isEvening ? 'evening' : 'afternoon';
      energyNote = 'moderately active';
    }
    
    // Determine social context
    final isGroupPlace = _isGoodForGroups(place);
    String socialContext = isGroupPlace ? 'friends or groups' : 'solo or intimate outings';
    
    return 'Perfect for ${isGroupPlace ? 'a ' : ''}$fitContext with $socialContext — $energyNote, not too intense.';
  }

  /// Generate AI-powered Moody Tips for the place with request deduplication
  Future<List<String>> _generateAIMoodyTips(Place place) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    // Request deduplication: Check if request is already in flight
    final requestKey = 'moody_tips_${place.id}';
    if (_inFlightRequests.contains(requestKey)) {
      if (kDebugMode) debugPrint('⏸️ Moody Tips request already in flight for: ${place.id}');
      return MoodyAIService.emergencyTips(languageCode);
    }
    
    // Mark request as in-flight
    _inFlightRequests.add(requestKey);
    
    try {
      final moodyService = ref.read(moodyAIServiceProvider);
      
      // Get current time context
      final hour = DateTime.now().hour;
      final timeOfDay = hour < 12 ? 'morning' : hour < 17 ? 'afternoon' : 'evening';
      
      // You could also get user's current mood from preferences/state if available
      String? userMood;
      // Example: userMood = ref.read(currentMoodProvider);
      
      final tips = await moodyService.generateMoodyTips(
        place: place,
        userMood: userMood,
        timeOfDay: timeOfDay,
        languageCode: languageCode,
        // You could add weather context here if available
        // weather: ref.read(weatherProvider).value?.description,
      );
      
      if (kDebugMode) debugPrint('✅ Generated ${tips.length} AI-powered Moody Tips');
      return tips;
    } catch (e) {
      debugPrint('❌ Error generating AI Moody Tips: $e');
      return MoodyAIService.emergencyTips(languageCode);
    } finally {
      // Always remove from in-flight requests
      _inFlightRequests.remove(requestKey);
    }
  }

  Widget _buildReviews(Place place) {
    if (!_loadingReviews && _realReviews.isEmpty && !_hasAttemptedReviewFetch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_loadingReviews && _realReviews.isEmpty && !_hasAttemptedReviewFetch) {
          _fetchRealReviews(place);
        }
      });
    }
    final reviews = _realReviews;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '⭐ Reviews',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.amber,
                ),
                const SizedBox(width: 4),
                Text(
                  '${place.rating.toStringAsFixed(1)} (${reviews.length} reviews)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: reviews.map((review) => _buildReviewCard(review)).toList(),
        ),
        // View all reviews feature - coming soon (hidden for now)
        // const SizedBox(height: 12),
        // Center(
        //   child: TextButton(
        //     onPressed: () {
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         SnackBar(
        //           content: Text(
        //             'View all reviews feature coming soon!',
        //             style: GoogleFonts.poppins(),
        //           ),
        //           backgroundColor: const Color(0xFF2A6049),
        //           behavior: SnackBarBehavior.floating,
        //         ),
        //       );
        //     },
        //     child: Text(
        //       'View all reviews',
        //       style: GoogleFonts.poppins(
        //         fontSize: 14,
        //         fontWeight: FontWeight.w500,
        //         color: const Color(0xFF2A6049),
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEAF5EE),
                child: Text(
                  (review['author_name'] as String? ?? 'A')[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A6049),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['author_name'] ?? l10n.placeDetailAnonymous,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review['rating'] ? Icons.star : Icons.star_border,
                              size: 14,
                              color: Colors.amber,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          review['relative_time_description'] ?? l10n.placeDetailRecently,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review['text'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Smart review fetching: Check cache first, then API with request deduplication
  Future<void> _fetchRealReviews(Place place) async {
    // Extract Google Place ID from place.id (format: "google_ChIJ...")
    String googlePlaceId = place.id;
    if (googlePlaceId.startsWith('google_')) {
      googlePlaceId = googlePlaceId.substring('google_'.length);
    }
    
    // Request deduplication: Check if request is already in flight
    final requestKey = 'reviews_$googlePlaceId';
    if (_inFlightRequests.contains(requestKey)) {
      if (kDebugMode) debugPrint('⏸️ Reviews request already in flight for: $googlePlaceId');
      return; // Request already in progress, don't start another one
    }
    
    if (_loadingReviews) return;
    
    // If we already have reviews, don't fetch again
    if (_realReviews.isNotEmpty) {
      if (kDebugMode) debugPrint('✅ Already have reviews cached in memory for: $googlePlaceId');
      return;
    }
    
    setState(() {
      _loadingReviews = true;
    });
    
    // Mark request as in-flight
    _inFlightRequests.add(requestKey);

    try {
      _hasAttemptedReviewFetch = true;
      final reviewsCache = ref.read(reviewsCacheServiceProvider);
      
      // Step 1: Check cache first
      final cachedReviews = await reviewsCache.getCachedReviews(googlePlaceId);
      if (cachedReviews != null && cachedReviews.isNotEmpty) {
        if (mounted) {
          setState(() {
            _realReviews = cachedReviews;
            _loadingReviews = false;
          });
          if (kDebugMode) {
            debugPrint('✅ Using cached reviews for place: $googlePlaceId (${cachedReviews.length} reviews)');
          }
        }
        _inFlightRequests.remove(requestKey);
        return; // Use cached reviews, no API call needed
      }
      
      // Step 2: Cache miss - fetch from API
      if (kDebugMode) {
        debugPrint('🔄 Cache miss - fetching reviews from API for: $googlePlaceId');
      }
      
      // Check if widget is still mounted before making API call
      if (!mounted) {
        _inFlightRequests.remove(requestKey);
        return;
      }
      
      final placesService = ref.read(placesServiceProvider.notifier);
      final details = await placesService.getPlaceDetails(googlePlaceId);
      
      // Check again after async operation
      if (!mounted) {
        _inFlightRequests.remove(requestKey);
        return;
      }
      
      // Step 3: Safely extract reviews with null safety
      List<Map<String, dynamic>> reviews = [];
      if (details.containsKey('reviews') && details['reviews'] != null) {
        final reviewsData = details['reviews'];
        if (reviewsData is List) {
          reviews = reviewsData
              .where((r) => r is Map<String, dynamic>)
              .cast<Map<String, dynamic>>()
              .toList();
        }
      }
      
      // Step 4: Cache the fetched reviews
      if (reviews.isNotEmpty) {
        await reviewsCache.cacheReviews(googlePlaceId, reviews);
      }
      
      if (mounted) {
        setState(() {
          _realReviews = reviews;
          _loadingReviews = false;
        });
        if (kDebugMode) {
          debugPrint('✅ Loaded ${reviews.length} real reviews from Google Places API and cached them');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching reviews: $e');
      }
      if (mounted) {
        setState(() {
          _realReviews = [];
          _loadingReviews = false;
        });
      }
    } finally {
      // Always remove from in-flight requests
      _inFlightRequests.remove(requestKey);
    }
  }

  Widget _buildPhotosTab(Place place) {
    final l10n = AppLocalizations.of(context)!;
    final allUrls = _displayPhotosForDetail(place);
    final urls = _fotosTabPhotoUrlsExcludingHero(allUrls);
    if (kDebugMode) {
      debugPrint(
        '📷 place_detail FOTOS_TAB placeId=${place.id} all.len=${allUrls.length} '
        'gridExHero.len=${urls.length} ',
      );
    }
    if (allUrls.isEmpty) {
      if (_unifiedDetailPhotosLoading) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A6049)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.placeDetailLoadingPhotos,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.placeDetailNoPhotos,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: urls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showFullScreenPhoto(urls, index, place.isAsset),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: place.isAsset
                ? Image.asset(
                    urls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImageFallback(),
                  )
                : WmPlacePhotoNetworkImage(
                    urls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImageFallback(),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab(Place place) {
    final l10n = AppLocalizations.of(context)!;
    if (!_loadingReviews && _realReviews.isEmpty && !_hasAttemptedReviewFetch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_loadingReviews && _realReviews.isEmpty && !_hasAttemptedReviewFetch) {
          _fetchRealReviews(place);
        }
      });
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviews header with rating summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '⭐ ${l10n.placeDetailReviewsSectionTitle}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (_realReviews.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    const DataSourceBadge(
                      source: DataSource.real,
                      tooltip: 'Real reviews from Google Places API',
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5EE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2A6049).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${place.rating.toStringAsFixed(1)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2A6049),
                      ),
                    ),
                    if (place.reviewCount > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${place.reviewCount} reviews)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const DataSourceBadge(
                        source: DataSource.real,
                        tooltip: 'Rating and review count from Google Places API',
                        size: 10,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Reviews list - show loading or real reviews
          if (_loadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_realReviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.reviews_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      l10n.placeDetailNoReviews,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.placeDetailReviewsWhenAvailable,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _realReviews.map((review) => _buildDetailedReviewCard(review)).toList(),
            ),
          
          const SizedBox(height: 16),
          
          // Add review button - coming soon (hidden for now)
          // SizedBox(
          //   width: double.infinity,
          //   child: OutlinedButton.icon(
          //     onPressed: () {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         SnackBar(
          //           content: Text(
          //             'Add review feature coming soon!',
          //             style: GoogleFonts.poppins(),
          //           ),
          //           backgroundColor: const Color(0xFF2A6049),
          //           behavior: SnackBarBehavior.floating,
          //         ),
          //       );
          //     },
          //     icon: const Icon(Icons.add_comment),
          //     label: Text(
          //       'Add Your Review',
          //       style: GoogleFonts.poppins(
          //         fontSize: 14,
          //         fontWeight: FontWeight.w600,
          //       ),
          //     ),
          //     style: OutlinedButton.styleFrom(
          //       foregroundColor: const Color(0xFF2A6049),
          //       side: const BorderSide(color: Color(0xFF2A6049)),
          //       padding: const EdgeInsets.symmetric(vertical: 16),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(25),
          //       ),
          //     ),
          //   ),
          // ),
                ],
              ),
    );
  }

  Widget _buildDetailedReviewCard(Map<String, dynamic> review) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
        color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEAF5EE),
                child: Text(
                  (review['author_name'] as String? ?? 'A')[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                      color: const Color(0xFF2A6049),
                  ),
                ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['author_name'] ?? l10n.placeDetailAnonymous,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review['rating'] ? Icons.star : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                Text(
                          review['relative_time_description'] ?? l10n.placeDetailRecently,
                  style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                  ),
                ),
              ],
            ),
                  ],
                ),
              ),
            ],
                ),
          const SizedBox(height: 12),
          Text(
            review['text'] ?? '',
              style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton(Place place) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: _pdWmCream,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _showBookingSheet(place),
            style: ElevatedButton.styleFrom(
              backgroundColor: _pdWmForest,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '✨ Book Your Adventure!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Primary maps CTA when booking is not shown (SCREEN 8 — Directions / Route).
  Widget _buildDirectionsBar(Place place) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: _pdWmCream,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _openInMaps(place),
            style: ElevatedButton.styleFrom(
              backgroundColor: _pdWmForest,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions, size: 22, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context)!.activityDetailDirections,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
            alignment: Alignment.centerLeft,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.placeDetailNotFound,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.agendaPleaseTryAgainLater,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: Text(AppLocalizations.of(context)!.back),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePlace(Place place) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await SharingService.sharePlace(place, context: context);
    } catch (e) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: l10n.placeCardFailedToShare('$e'),
          isError: true,
        );
      }
    }
  }

  void _showFullScreenPhoto(List<String> photos, int initialIndex, bool isAsset) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenPhotoView(
          photos: photos,
          initialIndex: initialIndex,
          isAsset: isAsset,
        ),
      ),
    );
  }

  void _openInMaps(Place place) async {
    try {
      final availableMaps = await MapLauncher.installedMaps;
      if (availableMaps.isNotEmpty) {
        await availableMaps.first.showMarker(
          coords: Coords(place.location.lat, place.location.lng),
          title: place.name,
          description: place.address,
        );
      } else {
        final url = 'https://www.google.com/maps/search/?api=1&query='
            '${place.location.lat},${place.location.lng}';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        }
      }
    } catch (e) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.placeDetailCouldNotOpenMaps('$e'),
          isError: true,
        );
      }
    }
  }

  // Determine if a place should show booking options
  bool _isPlaceBookable(Place place) {
    debugPrint('🔍 Checking if place is bookable: ${place.name}');
    debugPrint('   - Types: ${place.types}');
    debugPrint('   - priceLevel: ${place.priceLevel}');
    debugPrint('   - isFree: ${place.isFree}');
    
    // First, exclude all free or walk-in attractions
    if (_isFreeWalkInPlace(place)) {
      debugPrint('   ❌ Place is free/walk-in, no booking needed');
      return false;
    }
    
    // Show booking for places that typically need reservations/tickets
    final bookableTypes = [
      // Food & Drink
      'restaurant',
      'cafe',
      'bar',
      // Wellness & Services
      'spa',
      'beauty_salon',
      'hair_care',
      'gym',
      // Accommodation
      'lodging',
      'hotel',
      // Entertainment
      'movie_theater',
      'night_club',
      'bowling_alley',
      // Attractions that require tickets/reservations
      'museum',
      'tourist_attraction',
      'amusement_park',
      'zoo',
      'aquarium',
      'art_gallery',
      'stadium',
      'theater',
      'opera_house',
      'concert_hall',
      // Tours & Activities
      'tour_operator',
      'travel_agency',
    ];
    
    // Check if place type matches bookable types
    final hasBookableType = place.types.any((type) => 
      bookableTypes.any((bookable) => 
        type.toLowerCase().contains(bookable.toLowerCase())
      )
    );
    
    // Also check activities for paid tour/ticket hints
    final hasBookableActivity = place.activities.any((activity) {
      final lowerActivity = activity.toLowerCase();
      return lowerActivity.contains('guided tour') ||
             lowerActivity.contains('reservation') ||
             lowerActivity.contains('booking required') ||
             lowerActivity.contains('ticket required');
    });
    
    // Show booking if:
    // 1. Has bookable type (restaurant, spa, hotel, museum, tourist_attraction, etc.)
    // 2. OR has paid/ticketed activities
    // 3. AND is not explicitly free (price level 0 or flagged as free)
    final isKnownFree = place.isFree;
    final hasCost = !isKnownFree && (place.priceLevel == null || place.priceLevel! > 0);
    
    final shouldShow = (hasBookableType || hasBookableActivity) && hasCost;
    
    debugPrint('   - hasBookableType: $hasBookableType');
    debugPrint('   - hasBookableActivity: $hasBookableActivity');
    debugPrint('   - hasCost: $hasCost');
    debugPrint('   ${shouldShow ? "✅" : "❌"} Should show booking: $shouldShow');
    
    return shouldShow;
  }
  
  // Helper to determine if a place is free/walk-in (no booking needed)
  bool _isFreeWalkInPlace(Place place) {
    // Explicitly free based on flag or price level
    if (place.isFree || place.priceLevel == 0) {
      return true;
    }
    
    // First, check if place has bookable types - if so, it's NOT free/walk-in
    final bookableTypes = [
      'restaurant', 'cafe', 'bar', 'spa', 'beauty_salon', 'hair_care',
      'lodging', 'hotel', 'gym', 'movie_theater', 'night_club', 'bowling_alley',
      'museum', 'tourist_attraction', 'amusement_park', 'zoo', 'aquarium',
      'art_gallery', 'stadium', 'theater', 'opera_house', 'concert_hall',
      'tour_operator', 'travel_agency', 'meal_takeaway', 'food',
    ];
    
    final hasBookableType = place.types.any((type) => 
      bookableTypes.any((bookable) => 
        type.toLowerCase().contains(bookable.toLowerCase())
      )
    );
    
    // If it has bookable types, it's NOT free/walk-in
    if (hasBookableType) {
      debugPrint('   ⚠️ Has bookable types (${place.types.where((t) => bookableTypes.any((bt) => t.toLowerCase().contains(bt.toLowerCase()))).toList()}), NOT free/walk-in');
      return false;
    }
    
    // Free types - public spaces, monuments, parks (ONLY if no bookable types)
    final freeWalkInTypes = [
      'park',
      'arboretum',        // Botanical gardens/arboretums
      'garden',           // Public gardens
      'botanical_garden', // Botanical gardens
      'natural_feature',
      'cemetery',
      'church',
      'mosque',
      'synagogue',
      'hindu_temple',
      'library',
      'public_square',
      'plaza',
      'beach',
      'hiking_area',
      'walking_street',
      'street',
      'route',
      'neighborhood',
      'locality',
      'viewpoint',        // Scenic viewpoints
      'monument',         // Public monuments
      // Removed 'point_of_interest' - too generic, many paid places have this
    ];
    
    // Check if place is a free type (and has no bookable types)
    final isFreeType = place.types.any((type) => 
      freeWalkInTypes.any((freeType) => 
        type.toLowerCase().contains(freeType.toLowerCase())
      )
    );
    
    return isFreeType;
  }

  /// Per-place `places_cache` row (if moody wrote one), then Google Places API.
  Future<Place> _fetchPlaceDirectly(String placeId) async {
    try {
      final location = ref.read(locationNotifierProvider).valueOrNull;
      if (location != null && location.trim().isNotEmpty) {
        final raw = await PlacesCacheUtils.tryLoadExplorePlaceData(
          Supabase.instance.client,
          location,
          placeId,
          languageCode: PlacesCacheUtils.effectiveExploreLanguageTag(
            appLocale: ref.watch(localeProvider),
          ),
        );
        if (raw != null) {
          var fromCache = PlacesCacheUtils.placeFromMoodyExploreCard(raw);
          if (fromCache.id.isEmpty) {
            fromCache = fromCache.copyWith(id: placeId);
          }
          final hasName = fromCache.name.trim().isNotEmpty &&
              fromCache.name.trim().toLowerCase() != 'unknown place';
          final hasCoords = fromCache.location.lat.abs() > 1e-6 ||
              fromCache.location.lng.abs() > 1e-6;
          if (hasName && hasCoords) {
            if (kDebugMode) {
              debugPrint(
                '✅ Place detail from per-place places_cache: ${fromCache.name}',
              );
            }
            return fromCache;
          }
        }
      }

      final placesService = ref.read(placesServiceProvider.notifier);
      final place = await placesService.getPlaceById(placeId);
      if (kDebugMode) {
        debugPrint('✅ Successfully fetched place directly: ${place.name}');
      }
      if (place.name.trim().isNotEmpty &&
          place.name.trim().toLowerCase() != 'place details unavailable') {
        return place;
      }

      // Fallback to user_saved_places payload when external details are unavailable.
      final savedPlaces = await ref.read(savedPlacesServiceProvider).getSavedPlaces();
      for (final saved in savedPlaces) {
        if (saved.placeId == placeId || saved.place.id == placeId) {
          if (kDebugMode) {
            debugPrint('✅ Using fallback place data from saved places: ${saved.place.name}');
          }
          return saved.place;
        }
      }

      return place;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error fetching place directly: $e');
      final savedPlaces = await ref.read(savedPlacesServiceProvider).getSavedPlaces();
      for (final saved in savedPlaces) {
        if (saved.placeId == placeId || saved.place.id == placeId) {
          if (kDebugMode) {
            debugPrint('✅ Recovered place from saved places after fetch failure: ${saved.place.name}');
          }
          return saved.place;
        }
      }
      rethrow;
    }
  }

  void _showBookingSheet(Place place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingBottomSheet(place: place),
    );
  }
}

// Full screen photo view widget
class FullScreenPhotoView extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  final bool isAsset;

  const FullScreenPhotoView({
    Key? key,
    required this.photos,
    required this.initialIndex,
    required this.isAsset,
  }) : super(key: key);

  @override
  State<FullScreenPhotoView> createState() => _FullScreenPhotoViewState();
}

class _FullScreenPhotoViewState extends State<FullScreenPhotoView> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} of ${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: widget.isAsset
                  ? Image.asset(
                      widget.photos[index],
                      fit: BoxFit.contain,
                    )
                  : WmPlacePhotoNetworkImage(
                      widget.photos[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.error,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
} 