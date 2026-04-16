import 'package:wandermood/features/places/models/place.dart';

/// Builds a [Place] for [PlaceCard] from a group plan recommendation map.
Place placeFromGroupPlanRecommendation(
  Map<String, dynamic> data, {
  required String sessionId,
  required int index,
}) {
  final name = (data['name'] as String?)?.trim().isNotEmpty == true
      ? data['name'] as String
      : 'Place';
  final type = (data['type'] as String?)?.trim().toLowerCase() ?? 'place';
  final imageUrl = (data['imageUrl'] as String?)?.trim() ?? '';
  final desc = (data['description'] as String?)?.trim() ?? '';
  final rating = (data['rating'] as num?)?.toDouble() ?? 4.2;

  final rawId = data['id'] ?? data['placeId'] ?? data['place_id'];
  final id = rawId != null && rawId.toString().trim().isNotEmpty
      ? rawId.toString()
      : 'groupplan_${sessionId}_$index';

  double lat = 0;
  double lng = 0;
  final loc = data['location'];
  if (loc is Map) {
    final m = Map<String, dynamic>.from(loc);
    lat = (m['latitude'] as num?)?.toDouble() ??
        (m['lat'] as num?)?.toDouble() ??
        0;
    lng = (m['longitude'] as num?)?.toDouble() ??
        (m['lng'] as num?)?.toDouble() ??
        0;
  }

  final social = (data['socialSignal'] as String?)?.trim();

  return Place(
    id: id,
    name: name,
    address: desc.isNotEmpty ? desc : name,
    rating: rating,
    photos: imageUrl.isNotEmpty ? [imageUrl] : const [],
    types: type.isNotEmpty ? [type] : const ['establishment'],
    location: PlaceLocation(lat: lat, lng: lng),
    description: desc.isNotEmpty ? desc : null,
    editorialSummary:
        (data['editorialSummary'] as String?)?.trim().isNotEmpty == true
            ? data['editorialSummary'] as String
            : (data['editorial_summary'] as String?)?.trim(),
    primaryType: type,
    socialSignal: social,
  );
}
