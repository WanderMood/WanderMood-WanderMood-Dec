import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/utils/places_cache_utils.dart';

/// First photo URL from `places_cache` per-place explore row (no Google Details).
final placePhotoUrlProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, placeId) async {
  if (placeId.isEmpty) return null;
  try {
    final city = ref.watch(locationNotifierProvider).asData?.value?.trim();
    if (city == null || city.isEmpty) return null;
    return PlacesCacheUtils.tryExplorePlacePhotoUrl(
      Supabase.instance.client,
      location: city,
      placeId: placeId,
    );
  } catch (_) {
    return null;
  }
});
