import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/config/explore_launch_config.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/presentation/providers/language_provider.dart';
import 'package:wandermood/core/utils/places_cache_utils.dart';
import 'package:wandermood/features/location/services/location_service.dart';
import 'package:wandermood/features/mood/models/activity_rating.dart';
import 'package:wandermood/features/places/services/places_service.dart';
import 'package:wandermood/features/profile/domain/providers/current_user_profile_provider.dart';
import 'package:wandermood/features/profile/presentation/utils/visit_place_photo_policy.dart';

/// Stable key for [visitRatingPhotoUrlProvider] (ActivityRating has no `==`).
class VisitRatingPhotoKey {
  const VisitRatingPhotoKey({
    required this.ratingId,
    required this.activityId,
    this.heroImageUrl,
    this.googlePlaceId,
  });

  factory VisitRatingPhotoKey.from(ActivityRating r) => VisitRatingPhotoKey(
        ratingId: r.id,
        activityId: r.activityId,
        heroImageUrl: r.heroImageUrl,
        googlePlaceId: r.googlePlaceId,
      );

  final String ratingId;
  final String activityId;
  final String? heroImageUrl;
  final String? googlePlaceId;

  @override
  bool operator ==(Object other) =>
      other is VisitRatingPhotoKey &&
      other.ratingId == ratingId &&
      other.activityId == activityId &&
      other.heroImageUrl == heroImageUrl &&
      other.googlePlaceId == googlePlaceId;

  @override
  int get hashCode => Object.hash(ratingId, activityId, heroImageUrl, googlePlaceId);
}

/// Photo URL for profile visit tiles: saved hero → `scheduled_activities` →
/// `places_cache` (several city hints) → Place Details photo (cached in service).
final visitRatingPhotoUrlProvider =
    FutureProvider.autoDispose.family<String?, VisitRatingPhotoKey>((ref, key) async {
  ref.watch(localeProvider);
  ref.watch(locationNotifierProvider);
  ref.watch(currentUserProfileProvider);

  final hero = key.heroImageUrl?.trim() ?? '';
  if (hero.isNotEmpty &&
      hero.startsWith('http') &&
      !isStockOrDecorativeImageUrl(hero)) {
    return hero;
  }

  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  String? schedulePlaceId;

  if (uid != null && key.activityId.isNotEmpty) {
    try {
      final row = await client
          .from('scheduled_activities')
          .select('image_url, place_id')
          .eq('user_id', uid)
          .eq('activity_id', key.activityId)
          .maybeSingle();
      if (row != null) {
        final iu = row['image_url'] as String?;
        if (iu != null &&
            iu.trim().isNotEmpty &&
            iu.startsWith('http') &&
            !isStockOrDecorativeImageUrl(iu)) {
          return iu.trim();
        }
        final p = row['place_id'] as String?;
        if (p != null && p.trim().isNotEmpty) schedulePlaceId = p.trim();
      }
    } catch (_) {}
  }

  final rawPid = (key.googlePlaceId != null && key.googlePlaceId!.trim().isNotEmpty)
      ? key.googlePlaceId!.trim()
      : schedulePlaceId;
  if (rawPid == null || rawPid.isEmpty) return null;

  final lang = PlacesCacheUtils.effectiveExploreLanguageTag(
    appLocale: ref.watch(localeProvider),
  );

  final cities = <String>[];
  void addCity(String? c) {
    final t = c?.trim();
    if (t == null || t.isEmpty) return;
    final lower = t.toLowerCase();
    if (lower == 'local' || lower == 'traveling' || lower == 'traveler') return;
    if (!cities.any((x) => x.toLowerCase() == lower)) cities.add(t);
  }

  addCity(ref.watch(locationNotifierProvider).asData?.value);
  ref.watch(currentUserProfileProvider).whenData((p) => addCity(p?.homeBase));

  if (cities.isEmpty && kLockExploreCityToRotterdam) {
    addCity(LocationService.defaultLocation['name'] as String?);
  }

  // Per-place rows are keyed with either local or travel aggregate; try both.
  for (final city in cities) {
    for (final localMode in <bool>[true, false]) {
      final url = await PlacesCacheUtils.tryExplorePlacePhotoUrl(
        client,
        location: city,
        placeId: rawPid,
        isLocalMode: localMode,
        languageCode: lang,
      );
      if (url != null &&
          url.trim().isNotEmpty &&
          !isStockOrDecorativeImageUrl(url)) {
        return url.trim();
      }
    }
  }

  try {
    await ref.watch(placesServiceProvider.future);
    final urls =
        await ref.read(placesServiceProvider.notifier).fetchPhotoUrlsForGooglePlace(rawPid);
    if (urls.isNotEmpty) return urls.first;
  } catch (_) {}

  return null;
});
