import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/services/saved_places_service.dart';
import 'package:wandermood/features/wishlist/data/extract_place_from_url_service.dart';
import 'package:wandermood/features/wishlist/domain/wishlist_entry.dart';

final wishlistServiceProvider = Provider<WishlistService>((ref) {
  return WishlistService(
    Supabase.instance.client,
    ref.watch(savedPlacesServiceProvider),
  );
});

final wishlistEntriesProvider = StreamProvider<List<WishlistEntry>>((ref) {
  return ref.watch(wishlistServiceProvider).watchEntries();
});

class WishlistService {
  WishlistService(this._client, this._savedPlaces);

  final SupabaseClient _client;
  final SavedPlacesService _savedPlaces;

  Stream<List<WishlistEntry>> watchEntries() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _client
        .from('user_saved_places')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('saved_at', ascending: false)
        .map(
          (rows) => rows
              .map((json) => WishlistEntry.fromJson(json))
              .where((e) => e.placeId.isNotEmpty)
              .toList(),
        );
  }

  Future<List<WishlistEntry>> fetchEntries() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('user_saved_places')
        .select()
        .eq('user_id', userId)
        .order('saved_at', ascending: false);

    return (response as List)
        .map((json) => WishlistEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveFromShare({
    required ExtractedPlacePayload payload,
    required String sourceUrl,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final place = _placeFromPayload(payload);
    final row = <String, dynamic>{
      'user_id': userId,
      'place_id': payload.placeId,
      'place_name': payload.placeName,
      'saved_at': DateTime.now().toIso8601String(),
      'place_data': SavedPlacesService.encodePlaceDataRow(place),
      'source': payload.source,
      'source_url': sourceUrl,
      if (payload.sourceThumbnailUrl != null)
        'source_thumbnail_url': payload.sourceThumbnailUrl,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    try {
      await _client.from('user_saved_places').upsert(
            row,
            onConflict: 'user_id,place_id',
          );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Wishlist full upsert failed, retrying minimal: $e');
      }
      await _savedPlaces.savePlace(place);
    }
  }

  Future<void> savePlace({
    required Place place,
    String source = 'manual',
    String? sourceUrl,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final row = <String, dynamic>{
      'user_id': userId,
      'place_id': place.id,
      'place_name': place.name,
      'saved_at': DateTime.now().toIso8601String(),
      'place_data': SavedPlacesService.encodePlaceDataRow(place),
      'source': source,
      if (sourceUrl != null) 'source_url': sourceUrl,
    };

    try {
      await _client.from('user_saved_places').upsert(
            row,
            onConflict: 'user_id,place_id',
          );
    } catch (e) {
      await _savedPlaces.savePlace(place);
    }
  }

  Future<void> deleteEntry(String placeId) async {
    await _savedPlaces.unsavePlace(placeId);
  }

  Place _placeFromPayload(ExtractedPlacePayload payload) {
    final data = payload.placeData;
    final loc = data['location'];
    double lat = 0;
    double lng = 0;
    if (loc is Map) {
      lat = (loc['lat'] as num?)?.toDouble() ?? 0;
      lng = (loc['lng'] as num?)?.toDouble() ?? 0;
    }
    final photos = <String>[];
    final photoUrl = payload.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) photos.add(photoUrl);
    final rawPhotos = data['photos'];
    if (rawPhotos is List) {
      for (final p in rawPhotos) {
        final s = p?.toString();
        if (s != null && s.isNotEmpty && !photos.contains(s)) photos.add(s);
      }
    }

    return Place(
      id: payload.placeId,
      name: payload.placeName,
      address: (data['address'] as String?) ?? '',
      rating: payload.rating ?? 0,
      photos: photos,
      types: (data['types'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      location: PlaceLocation(lat: lat, lng: lng),
      reviewCount: (data['review_count'] as num?)?.toInt() ?? 0,
      primaryType: payload.primaryType,
    );
  }
}
