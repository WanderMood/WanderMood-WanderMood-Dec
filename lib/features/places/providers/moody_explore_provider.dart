import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/core/presentation/providers/language_provider.dart';
import 'package:wandermood/core/services/moody_edge_function_service.dart';
import 'package:wandermood/core/utils/places_cache_utils.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/services/places_service.dart';
import 'package:wandermood/core/errors/explore_location_exception.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Parameters for the moody explore provider
class ExploreParams {
  final String location;
  final double latitude;
  final double longitude;
  final Map<String, dynamic>? filters;
  final String? section;
  final String languageCode;

  ExploreParams({
    required this.location,
    required this.latitude,
    required this.longitude,
    this.filters,
    this.section,
    required this.languageCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExploreParams &&
          runtimeType == other.runtimeType &&
          location == other.location &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          section == other.section &&
          languageCode == other.languageCode &&
          _mapsEqual(filters, other.filters);

  @override
  int get hashCode =>
      location.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      (section?.hashCode ?? 0) ^
      languageCode.hashCode ^
      (filters?.toString().hashCode ?? 0);

  bool _mapsEqual(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Provider for Moody Edge Function service
final moodyEdgeFunctionServiceProvider = Provider<MoodyEdgeFunctionService>((ref) {
  return MoodyEdgeFunctionService(Supabase.instance.client);
});

/// Backend-ready Explore filters selected from the Explore Advanced Filters modal.
final moodyExploreBackendFiltersProvider =
    StateProvider<Map<String, dynamic>>((ref) => <String, dynamic>{});

/// Provider that gets explore places from Moody Edge Function
final moodyExploreProvider = FutureProvider.family<List<Place>, ExploreParams>((ref, params) async {
  final service = ref.watch(moodyEdgeFunctionServiceProvider);
  
  try {
    final places = await service.getExplore(
      location: params.location,
      latitude: params.latitude,
      longitude: params.longitude,
      section: params.section,
      filters: params.filters,
      languageCode: params.languageCode,
    );
    final notifier = ref.read(placesServiceProvider.notifier);
    for (final p in places) {
      notifier.cachePlaceObject(p);
    }
    return places;
  } catch (e) {
    // Log error - this will be handled by UI to show error state
    debugPrint('❌ Error in moodyExploreProvider: $e');
    rethrow; // Re-throw so UI can show proper error state
  }
});

/// Broad discovery feed (no `section`) + current location.
///
/// Explore screen section rows load via [MoodyEdgeFunctionService.getExplore] directly.
/// 
/// CRITICAL: Location and coordinates are REQUIRED - no defaults
/// If location is missing, this will throw an error that UI should handle
/// 
/// CRITICAL: NOT autoDispose to prevent disposal on hot reload
final moodyExploreAutoProvider = FutureProvider<List<Place>>((ref) async {
  // CRITICAL: Get location name (city)
  final locationAsync = ref.watch(locationNotifierProvider);
  final location = locationAsync.value;
  
  // CRITICAL: Validate location exists - no defaults allowed
  if (location == null || location.isEmpty || location.trim().isEmpty) {
    throw const ExploreLocationException(ExploreLocationReason.missingCity);
  }

  // CRITICAL: Get GPS coordinates - use .future to get the Future directly
  final position = await ref.read(userLocationProvider.future);

  // CRITICAL: Validate coordinates exist - no defaults allowed
  if (position == null) {
    throw const ExploreLocationException(
        ExploreLocationReason.missingCoordinates);
  }
  
  // CRITICAL: Don't use fallback/mock positions
  if (position.isMocked == true) {
    debugPrint('⚠️ Location is mocked/fallback - this should not be used in production');
    // Still allow it for now, but log a warning
  }
  
  // Advanced filters from Explore UI (kept in provider state).
  final filters = ref.watch(moodyExploreBackendFiltersProvider);
  
  // Create params with validated location and coordinates
  final params = ExploreParams(
    location: location.trim(),
    latitude: position.latitude,
    longitude: position.longitude,
    filters: filters,
    section: null,
    languageCode: PlacesCacheUtils.effectiveExploreLanguageTag(
      appLocale: ref.watch(localeProvider),
    ),
  );
  
  return ref.watch(moodyExploreProvider(params).future);
});

/// Moody Hub only: reads the Explore aggregate row in `places_cache`.
/// Does not call the Edge Function or Google — empty until the user has opened Explore (or another path filled cache).
final moodyHubExploreCacheOnlyProvider =
    FutureProvider.autoDispose<List<Place>>((ref) async {
  final locationAsync = ref.watch(locationNotifierProvider);
  final city = locationAsync.value?.trim();
  if (city == null || city.isEmpty) return [];

  final places = await PlacesCacheUtils.tryLoadExplorePlaces(
    Supabase.instance.client,
    'discovery',
    city,
    languageCode: PlacesCacheUtils.effectiveExploreLanguageTag(
      appLocale: ref.watch(localeProvider),
    ),
  );
  return places ?? [];
});

