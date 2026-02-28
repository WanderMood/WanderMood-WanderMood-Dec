import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../profile/domain/models/visited_place.dart';

/// Provides the current user's visited places from Supabase.
/// Returns an empty list when there is no authenticated user.
final visitedPlacesProvider =
    AsyncNotifierProvider<VisitedPlacesNotifier, List<VisitedPlace>>(
  VisitedPlacesNotifier.new,
);

class VisitedPlacesNotifier extends AsyncNotifier<List<VisitedPlace>> {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<List<VisitedPlace>> build() async {
    return _fetch();
  }

  Future<List<VisitedPlace>> _fetch() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _supabase
        .from('visited_places')
        .select()
        .eq('user_id', userId)
        .order('visited_at', ascending: false);

    return (rows as List)
        .map((r) => VisitedPlace.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Add a new visited place and refresh the list.
  Future<VisitedPlace?> addPlace({
    required String placeName,
    String? city,
    String? country,
    required double lat,
    required double lng,
    String? mood,
    String? moodEmoji,
    double? energyLevel,
    String? notes,
    DateTime? visitedAt,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _supabase
        .from('visited_places')
        .insert({
          'user_id': userId,
          'place_name': placeName,
          if (city != null) 'city': city,
          if (country != null) 'country': country,
          'lat': lat,
          'lng': lng,
          if (mood != null) 'mood': mood,
          if (moodEmoji != null) 'mood_emoji': moodEmoji,
          if (energyLevel != null) 'energy_level': energyLevel,
          if (notes != null) 'notes': notes,
          if (visitedAt != null) 'visited_at': visitedAt.toIso8601String(),
        })
        .select()
        .single();

    final place = VisitedPlace.fromJson(row as Map<String, dynamic>);
    state = AsyncValue.data([place, ...state.valueOrNull ?? []]);
    return place;
  }

  /// Remove a visited place by ID.
  Future<void> removePlace(String id) async {
    await _supabase.from('visited_places').delete().eq('id', id);
    state = AsyncValue.data(
      (state.valueOrNull ?? []).where((p) => p.id != id).toList(),
    );
  }

  /// Force-refresh from Supabase.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}
