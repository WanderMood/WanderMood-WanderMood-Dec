import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/places/services/places_service.dart';

/// Fetches open_now from Google Place Details (uses device local time, e.g. NL).
/// Returns null when placeId is null/empty or when API doesn't return opening_hours.
final placeOpenNowProvider =
    FutureProvider.autoDispose.family<bool?, String>((ref, placeId) async {
  if (placeId.isEmpty) return null;
  try {
    await ref.watch(placesServiceProvider.future);
    final service = ref.read(placesServiceProvider.notifier);
    final details = await service.getPlaceDetails(placeId);
    return details['open_now'] as bool?;
  } catch (_) {
    return null;
  }
});
