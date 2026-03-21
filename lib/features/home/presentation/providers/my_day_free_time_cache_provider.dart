import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/core/utils/places_cache_utils.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';

/// My Day "Free time" carousel: read-only from Supabase `places_cache` aggregate row.
/// No Edge/Google calls from this provider — empty list if cache miss.
final myDayFreeTimeActivitiesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final city = ref.watch(locationNotifierProvider).value?.trim();
  if (city == null || city.isEmpty) return [];

  final moodState = ref.watch(dailyMoodStateNotifierProvider);
  final mood = (moodState.currentMood ?? 'adventurous').toLowerCase().trim();

  final places = await PlacesCacheUtils.tryLoadExplorePlaces(
    Supabase.instance.client,
    mood,
    city,
  );
  if (places == null || places.isEmpty) return [];

  final pos = await ref.watch(userLocationProvider.future);
  final lat = pos?.latitude;
  final lng = pos?.longitude;

  return PlacesCacheUtils.toMyDayFreeTimeCarouselMaps(
    places,
    userLat: lat,
    userLng: lng,
    maxItems: 5,
  );
});
