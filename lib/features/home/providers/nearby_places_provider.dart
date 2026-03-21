import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/core/services/distance_service.dart';
import 'package:wandermood/core/utils/places_cache_utils.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/features/places/domain/models/place.dart' as domain;
import 'package:wandermood/features/places/models/place.dart' as explore;

/// Nearby places from cached explore list + user GPS (no Places API nearby search).
final nearbyPlacesProvider =
    FutureProvider.autoDispose<List<domain.Place>>((ref) async {
  final position = await ref.watch(userLocationProvider.future);
  if (position == null) return [];

  final city =
      ref.watch(locationNotifierProvider).asData?.value?.trim() ?? 'Rotterdam';
  final mood =
      ref.watch(dailyMoodStateNotifierProvider).currentMood ?? 'adventurous';

  final cached = await PlacesCacheUtils.tryLoadExplorePlaces(
    Supabase.instance.client,
    mood.toLowerCase().trim(),
    city,
  );
  if (cached == null || cached.isEmpty) return [];

  const radiusKm = 5.0;
  final withDistance = <({domain.Place place, double km})>[];
  for (final p in cached) {
    if (p.location.lat == 0 && p.location.lng == 0) continue;
    final km = DistanceService.calculateDistance(
      position.latitude,
      position.longitude,
      p.location.lat,
      p.location.lng,
    );
    if (km > radiusKm) continue;
    withDistance.add((place: _cachedToDomain(p), km: km));
  }
  withDistance.sort((a, b) => a.km.compareTo(b.km));
  return withDistance.map((e) => e.place).take(20).toList();
});

domain.Place _cachedToDomain(explore.Place p) {
  final rawId = p.id.startsWith('google_') ? p.id.substring(7) : p.id;
  return domain.Place(
    placeId: rawId,
    name: p.name,
    formattedAddress: p.address,
    geometry: domain.PlaceGeometry(
      location:
          domain.PlaceLocation(lat: p.location.lat, lng: p.location.lng),
    ),
    types: p.types,
    rating: p.rating,
    photoUrls: p.photos,
    vicinity: p.address,
  );
}
