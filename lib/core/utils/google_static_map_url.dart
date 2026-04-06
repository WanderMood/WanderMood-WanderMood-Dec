import 'package:wandermood/core/constants/api_keys.dart';

/// Returns a Google Static Maps image URL for a small preview, or null if no key.
String? googleStaticMapPreviewUrl(
  double lat,
  double lng, {
  int widthPx = 640,
  int heightPx = 320,
  int zoom = 15,
}) {
  final String key;
  try {
    key = ApiKeys.googleMapsKey;
  } catch (_) {
    return null;
  }
  if (key.isEmpty) return null;

  final latS = lat.toStringAsFixed(6);
  final lngS = lng.toStringAsFixed(6);
  final uri = Uri.https('maps.googleapis.com', '/maps/api/staticmap', {
    'center': '$latS,$lngS',
    'zoom': '$zoom',
    'size': '${widthPx}x$heightPx',
    'scale': '2',
    'maptype': 'roadmap',
    'markers': 'color:0x2A6049|$latS,$lngS',
    'key': key,
  });
  return uri.toString();
}
