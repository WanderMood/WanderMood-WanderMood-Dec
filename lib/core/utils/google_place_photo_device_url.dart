import 'package:wandermood/core/constants/api_keys.dart';

/// Rewrites Google Place Photo URLs so the **device** can load them (see below).
///
/// **Not a “Places API call” in the search/details sense** — the app only performs an
/// HTTP GET to `…/place/photo?…` when an image is actually shown. Those responses are
/// **disk-cached** app-wide via [WmNetworkImage] / [WmPlacePhotoNetworkImage] and
/// [WanderMoodImageCacheManager] (same URL ⇒ no re-download until cache expiry).
///
/// **Shared JSON across users** (Explore cards, moods, prefs) still comes from
/// Supabase `places_cache` / Moody — that is unchanged. Image bytes are cached **per
/// device** after the first successful load; different users do not share one phone’s
/// disk cache, but they all receive the same `photo_url` strings from the server.
///
/// Backend URLs often embed a **server-only** API key; mobile gets 403 / grey placeholder.
/// This helper swaps `key=` for the app’s [ApiKeys.googlePlacesKey] while keeping the same
/// `photoreference`, so the cached file key stays stable for a given reference + maxwidth.
String deviceAccessibleGooglePlacePhotoUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.startsWith('assets/')) return trimmed;

  Uri uri;
  try {
    uri = Uri.parse(trimmed);
  } catch (_) {
    return trimmed;
  }

  if (uri.host != 'maps.googleapis.com') return trimmed;
  if (!uri.path.contains('place/photo')) return trimmed;

  try {
    final clientKey = ApiKeys.googlePlacesKey;
    final qp = Map<String, String>.from(uri.queryParameters);
    if (qp['photoreference'] == null || qp['photoreference']!.isEmpty) {
      return trimmed;
    }
    qp['key'] = clientKey;
    return uri.replace(queryParameters: qp).toString();
  } catch (_) {
    return trimmed;
  }
}
