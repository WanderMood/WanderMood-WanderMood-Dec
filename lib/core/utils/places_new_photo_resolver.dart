import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:wandermood/core/constants/api_keys.dart';
import 'package:wandermood/core/utils/google_place_photo_device_url.dart';

/// True for **Places API (New)** photo media URLs, e.g.
///   https://places.googleapis.com/v1/places/{ID}/photos/{REF}/media?maxWidthPx=800&key=...
bool isPlacesApiNewPhotoUrl(String url) {
  final u = Uri.tryParse(url.trim());
  if (u == null) return false;
  return u.host == 'places.googleapis.com' && u.path.contains('/media');
}

final Map<String, String> _resolvedCache = <String, String>{};
final Map<String, Future<String>> _inFlight = <String, Future<String>>{};

/// Resolves a Places API (New) `/media` URL to the **direct image URL**
/// (`https://lh3.googleusercontent.com/...`) using `?skipHttpRedirect=true`.
///
/// Why: the `/media` endpoint normally responds with a 302 redirect to the binary
/// image host. Following that redirect chain hangs on **signed iOS release**
/// builds when using Dart's `http` / `dart:io HttpClient` (which both
/// `Image.network` and `flutter_cache_manager` rely on), so the hero image
/// stays stuck on the loading placeholder. Asking Google directly for the
/// final URL (returned as JSON's `photoUri`) sidesteps the redirect hang and
/// lets us cache the resulting image bytes through our normal disk cache.
///
/// Results are memoised in-process so repeat renders don't re-resolve.
/// Non-Places-New URLs are returned unchanged.
Future<String> resolvePlacesNewPhotoUri(String src) async {
  final trimmed = src.trim();
  if (trimmed.isEmpty || !isPlacesApiNewPhotoUrl(trimmed)) return trimmed;

  final cached = _resolvedCache[trimmed];
  if (cached != null) return cached;

  final inFlight = _inFlight[trimmed];
  if (inFlight != null) return inFlight;

  final future = _resolve(trimmed).whenComplete(() {
    _inFlight.remove(trimmed);
  });
  _inFlight[trimmed] = future;
  return future;
}

Future<String> _resolve(String src) async {
  try {
    final original = Uri.parse(src);
    final qp = Map<String, String>.from(original.queryParameters);
    qp['key'] = ApiKeys.googlePlacesKey;
    qp['skipHttpRedirect'] = 'true';
    final lookup = original.replace(queryParameters: qp);

    final res = await http
        .get(lookup, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 6));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        final photoUri = (data['photoUri'] as String?)?.trim();
        if (photoUri != null && photoUri.isNotEmpty) {
          _resolvedCache[src] = photoUri;
          return photoUri;
        }
      }
    }
  } catch (_) {
    // Fall through and return original; CachedNetworkImage will surface the failure.
  }
  return src;
}

/// Rewrites every Places API (New) `/media` entry to a direct `photoUri` (e.g. `lh3…`)
/// so [CachedNetworkImage] / disk prefetch never follows the `/media` redirect chain
/// (known to hang on signed iOS release builds).
Future<List<String>> resolvePlacesNewPhotoUrlList(List<String> urls) async {
  return Future.wait(
    urls.map((raw) async {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return trimmed;
      try {
        final accessible = deviceAccessibleGooglePlacePhotoUrl(trimmed).trim();
        if (accessible.isEmpty) return trimmed;
        if (isPlacesApiNewPhotoUrl(accessible)) {
          final resolved = (await resolvePlacesNewPhotoUri(accessible)).trim();
          return resolved.isNotEmpty ? resolved : accessible;
        }
        return accessible;
      } catch (_) {
        return trimmed;
      }
    }),
  );
}
