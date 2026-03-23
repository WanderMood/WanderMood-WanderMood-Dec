import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/place.dart';

// ─── Providers ──────────────────────────────────────────────────────────────

final tripCollectionsServiceProvider = Provider<TripCollectionsService>((ref) {
  return TripCollectionsService(Supabase.instance.client);
});

/// All collections for the current user.
final tripCollectionsProvider = FutureProvider<List<TripCollection>>((ref) {
  final service = ref.watch(tripCollectionsServiceProvider);
  return service.getCollections();
});

/// Places inside a specific collection.
final collectionPlacesProvider =
    FutureProvider.family<List<CollectionPlace>, String>((ref, collectionId) {
  final service = ref.watch(tripCollectionsServiceProvider);
  return service.getCollectionPlaces(collectionId);
});

// ─── Models ─────────────────────────────────────────────────────────────────

class TripCollection {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  final DateTime createdAt;
  final int placeCount;
  /// First photo URL from the newest place in this collection (for cover).
  final String? coverPhotoUrl;

  TripCollection({
    required this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    required this.createdAt,
    required this.placeCount,
    this.coverPhotoUrl,
  });

  factory TripCollection.fromJson(Map<String, dynamic> json) {
    return TripCollection(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      emoji: (json['emoji'] as String?) ?? '📍',
      createdAt: DateTime.parse(json['created_at'] as String),
      placeCount: (json['place_count'] as int?) ?? 0,
      coverPhotoUrl: json['cover_photo_url'] as String?,
    );
  }

  TripCollection copyWith({String? name, String? emoji}) {
    return TripCollection(
      id: id,
      userId: userId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt,
      placeCount: placeCount,
      coverPhotoUrl: coverPhotoUrl,
    );
  }
}

class CollectionPlace {
  final String id;
  final String collectionId;
  final String userId;
  final String placeId;
  final String placeName;
  final Place place;
  final DateTime addedAt;

  CollectionPlace({
    required this.id,
    required this.collectionId,
    required this.userId,
    required this.placeId,
    required this.placeName,
    required this.place,
    required this.addedAt,
  });

  factory CollectionPlace.fromJson(Map<String, dynamic> json) {
    return CollectionPlace(
      id: json['id'] as String,
      collectionId: json['collection_id'] as String,
      userId: json['user_id'] as String,
      placeId: json['place_id'] as String,
      placeName: json['place_name'] as String,
      place: Place.fromJson(json['place_data'] as Map<String, dynamic>),
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }
}

// ─── Service ─────────────────────────────────────────────────────────────────

class TripCollectionsService {
  final SupabaseClient _client;

  TripCollectionsService(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  // ── Schema bootstrap ──────────────────────────────────────────────────────

  Future<void> ensureTablesExist() async {
    try {
      await _client.from('trip_collections').select('id').limit(1);
    } catch (_) {
      // Table doesn't exist yet — try to create via RPC.
      const sql = '''
        CREATE TABLE IF NOT EXISTS public.trip_collections (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL,
          name TEXT NOT NULL,
          emoji TEXT DEFAULT \'📍\',
          created_at TIMESTAMPTZ DEFAULT NOW()
        );
        CREATE TABLE IF NOT EXISTS public.collection_places (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          collection_id UUID NOT NULL REFERENCES public.trip_collections(id) ON DELETE CASCADE,
          user_id UUID NOT NULL,
          place_id TEXT NOT NULL,
          place_name TEXT NOT NULL,
          place_data JSONB NOT NULL,
          added_at TIMESTAMPTZ DEFAULT NOW(),
          UNIQUE(collection_id, place_id)
        );
      ''';
      try {
        await _client.rpc('execute_sql', params: {'query': sql});
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ TripCollections: could not auto-create tables: $e');
      }
    }
  }

  // ── Collections CRUD ─────────────────────────────────────────────────────

  Future<List<TripCollection>> getCollections() async {
    final uid = _userId;
    if (uid == null) return [];
    final rows = await _client
        .from('trip_collections')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    final result = <TripCollection>[];
    for (final row in (rows as List)) {
      int count = 0;
      String? cover;
      try {
        final countRes = await _client
            .from('collection_places')
            .select('id')
            .eq('collection_id', row['id'] as String)
            .eq('user_id', uid);
        count = (countRes as List).length;
        if (count > 0) {
          final topPlace = await _client
              .from('collection_places')
              .select('place_data')
              .eq('collection_id', row['id'] as String)
              .eq('user_id', uid)
              .order('added_at', ascending: false)
              .limit(1);
          final placeData =
              (topPlace as List).isNotEmpty
                  ? topPlace.first['place_data'] as Map<String, dynamic>?
                  : null;
          final photos = placeData?['photos'] as List?;
          if (photos != null && photos.isNotEmpty) {
            cover = photos.first as String?;
          }
        }
      } catch (_) {}
      result.add(TripCollection.fromJson({
        ...row,
        'place_count': count,
        'cover_photo_url': cover,
      }));
    }
    return result;
  }

  Future<TripCollection> createCollection({
    required String name,
    required String emoji,
  }) async {
    final uid = _userId;
    if (uid == null) throw Exception('Not authenticated');
    final response = await _client
        .from('trip_collections')
        .insert({'user_id': uid, 'name': name, 'emoji': emoji})
        .select()
        .single();
    return TripCollection.fromJson({...response, 'place_count': 0});
  }

  Future<void> updateCollection(
    String collectionId, {
    required String name,
    required String emoji,
  }) async {
    await _client
        .from('trip_collections')
        .update({'name': name, 'emoji': emoji})
        .eq('id', collectionId);
  }

  Future<void> deleteCollection(String collectionId) async {
    await _client
        .from('trip_collections')
        .delete()
        .eq('id', collectionId);
  }

  // ── Places within a collection ───────────────────────────────────────────

  Future<List<CollectionPlace>> getCollectionPlaces(String collectionId) async {
    final uid = _userId;
    if (uid == null) return [];
    final rows = await _client
        .from('collection_places')
        .select()
        .eq('collection_id', collectionId)
        .eq('user_id', uid)
        .order('added_at', ascending: false);
    return (rows as List).map((r) => CollectionPlace.fromJson(r)).toList();
  }

  Future<void> addPlaceToCollection({
    required String collectionId,
    required Place place,
  }) async {
    final uid = _userId;
    if (uid == null) throw Exception('Not authenticated');
    await _client.from('collection_places').upsert({
      'collection_id': collectionId,
      'user_id': uid,
      'place_id': place.id,
      'place_name': place.name,
      'place_data': place.toJson(),
      'added_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removePlaceFromCollection({
    required String collectionId,
    required String placeId,
  }) async {
    await _client
        .from('collection_places')
        .delete()
        .eq('collection_id', collectionId)
        .eq('place_id', placeId);
  }

  /// Returns a set of collection IDs that contain the given placeId.
  Future<Set<String>> collectionsContainingPlace(String placeId) async {
    final uid = _userId;
    if (uid == null) return {};
    try {
      final rows = await _client
          .from('collection_places')
          .select('collection_id')
          .eq('user_id', uid)
          .eq('place_id', placeId);
      return {for (final r in (rows as List)) r['collection_id'] as String};
    } catch (_) {
      return {};
    }
  }
}
