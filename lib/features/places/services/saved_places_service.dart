import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/place.dart';

final savedPlacesServiceProvider = Provider<SavedPlacesService>((ref) {
  return SavedPlacesService(Supabase.instance.client);
});

final savedPlacesProvider = StreamProvider<List<SavedPlace>>((ref) {
  final service = ref.watch(savedPlacesServiceProvider);
  return service.getSavedPlacesStream();
});

class SavedPlace {
  final String id;
  final String userId;
  final String placeId;
  final String placeName;
  final Place place;
  final DateTime savedAt;

  SavedPlace({
    required this.id,
    required this.userId,
    required this.placeId,
    required this.placeName,
    required this.place,
    required this.savedAt,
  });

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      placeId: json['place_id'] as String,
      placeName: json['place_name'] as String,
      place: Place.fromJson(json['place_data'] as Map<String, dynamic>),
      savedAt: DateTime.parse(json['saved_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'place_id': placeId,
      'place_name': placeName,
      'place_data': place.toJson(),
      'saved_at': savedAt.toIso8601String(),
    };
  }
}

class SavedPlacesService {
  final SupabaseClient _client;

  SavedPlacesService(this._client);

  /// Save a place for later
  Future<void> savePlace(Place place) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client.from('user_saved_places').upsert({
        'user_id': userId,
        'place_id': place.id,
        'place_name': place.name,
        'place_data': place.toJson(),
        'saved_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) debugPrint('✅ Place saved: ${place.name}');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to save place: $e');
      rethrow;
    }
  }

  /// Remove a saved place
  Future<void> unsavePlace(String placeId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client
          .from('user_saved_places')
          .delete()
          .eq('user_id', userId)
          .eq('place_id', placeId);

      if (kDebugMode) debugPrint('✅ Place unsaved: $placeId');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to unsave place: $e');
      rethrow;
    }
  }

  /// Check if a place is saved
  Future<bool> isPlaceSaved(String placeId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _client
          .from('user_saved_places')
          .select('id')
          .eq('user_id', userId)
          .eq('place_id', placeId)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to check if place is saved: $e');
      return false;
    }
  }

  /// Get all saved places
  Future<List<SavedPlace>> getSavedPlaces() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('user_saved_places')
          .select()
          .eq('user_id', userId)
          .order('saved_at', ascending: false);

      return (response as List)
          .map((json) => SavedPlace.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to get saved places: $e');
      return [];
    }
  }

  /// Get saved places as a stream (for real-time updates)
  Stream<List<SavedPlace>> getSavedPlacesStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value([]);
    }

    return _client
        .from('user_saved_places')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('saved_at', ascending: false)
        .map((data) => data.map((json) => SavedPlace.fromJson(json)).toList());
  }

  /// Get count of saved places
  Future<int> getSavedPlacesCount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _client
          .from('user_saved_places')
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to get saved places count: $e');
      return 0;
    }
  }
}

