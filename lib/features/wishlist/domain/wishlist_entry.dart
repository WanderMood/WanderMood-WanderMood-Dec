import 'package:wandermood/features/places/models/place.dart';

class WishlistEntry {
  const WishlistEntry({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.place,
    required this.savedAt,
    this.source,
    this.sourceUrl,
    this.sourceThumbnailUrl,
  });

  final String id;
  final String placeId;
  final String placeName;
  final Place place;
  final DateTime savedAt;
  final String? source;
  final String? sourceUrl;
  final String? sourceThumbnailUrl;

  bool get isSocialSource {
    final s = source?.toLowerCase() ?? '';
    return s == 'tiktok' || s == 'instagram';
  }

  factory WishlistEntry.fromJson(Map<String, dynamic> json) {
    final placeData = json['place_data'];
    Place place;
    if (placeData is Map<String, dynamic>) {
      try {
        place = Place.fromJson(placeData);
      } catch (_) {
        place = Place(
          id: json['place_id'] as String,
          name: json['place_name'] as String? ?? 'Place',
          address: '',
          location: const PlaceLocation(lat: 0, lng: 0),
        );
      }
    } else {
      place = Place(
        id: json['place_id'] as String,
        name: json['place_name'] as String? ?? 'Place',
        address: '',
        location: const PlaceLocation(lat: 0, lng: 0),
      );
    }

    return WishlistEntry(
      id: json['id'] as String,
      placeId: json['place_id'] as String,
      placeName: json['place_name'] as String? ?? place.name,
      place: place,
      savedAt: DateTime.tryParse(json['saved_at'] as String? ?? '') ??
          DateTime.now(),
      source: json['source'] as String?,
      sourceUrl: json['source_url'] as String?,
      sourceThumbnailUrl: json['source_thumbnail_url'] as String?,
    );
  }
}
