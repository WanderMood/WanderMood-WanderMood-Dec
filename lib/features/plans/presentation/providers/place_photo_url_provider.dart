import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/places/services/places_service.dart';

/// Fetches the first place photo URL from Google Places API (same API key as Explore).
/// Use this when activity.imageUrl is empty but activity.placeId is set.
final placePhotoUrlProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, placeId) async {
  if (placeId.isEmpty) return null;
  try {
    await ref.watch(placesServiceProvider.future);
    final service = ref.read(placesServiceProvider.notifier);
    final details = await service.getPlaceDetails(placeId);
    final photos = details['photos'] as List<dynamic>?;
    if (photos == null || photos.isEmpty) return null;
    final firstRef = photos.first?.toString();
    if (firstRef == null || firstRef.isEmpty) return null;
    return service.getPhotoUrl(firstRef);
  } catch (_) {
    return null;
  }
});
