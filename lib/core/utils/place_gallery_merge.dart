import 'dart:async';

import 'package:wandermood/core/cache/wandermood_image_cache_manager.dart';
import 'package:wandermood/core/utils/google_place_photo_device_url.dart';
import 'package:wandermood/core/utils/places_new_photo_resolver.dart';

/// True for Places API (New) `/…/photos/…/media` URLs (place detail hero merge).
bool isPlacesApiNewPhotoMediaUrl(String url) => isPlacesApiNewPhotoUrl(url);

String? _photoGalleryDedupeKey(String raw) {
  final u = Uri.tryParse(raw.trim());
  if (u == null) return null;
  if (u.host == 'places.googleapis.com') {
    final m = RegExp(r'/places/([^/]+)/photos/([^/]+)').firstMatch(u.path);
    if (m != null) return 'pnew:${m[1]}:${m[2]}';
  }
  final pr = u.queryParameters['photoreference']?.trim();
  if (pr != null && pr.isNotEmpty) return 'pref:$pr';
  return raw.trim();
}

/// Collapses v1 New vs legacy URLs that resolve to the same hero frame.
List<String> dedupeRepeatedHeroIdentity(List<String> urls) {
  final seen = <String>{};
  final out = <String>[];
  for (final u in urls) {
    if (u.isEmpty) continue;
    final k = _photoGalleryDedupeKey(u) ?? u;
    if (seen.contains(k)) continue;
    seen.add(k);
    out.add(u);
  }
  return out;
}

/// Warm disk cache for a resolved gallery (fire-and-forget).
void prefetchPlacePhotos(Iterable<String> urls) {
  for (final raw in urls) {
    final url = deviceAccessibleGooglePlacePhotoUrl(raw).trim();
    if (url.isEmpty) continue;
    unawaited(WanderMoodImageCacheManager.instance.downloadFile(url));
  }
}
