import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/core/services/moody_edge_function_service.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Parameters for the moody explore provider
class ExploreParams {
  final String mood;
  final String location;
  final Map<String, dynamic>? filters;

  ExploreParams({
    required this.mood,
    required this.location,
    this.filters,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExploreParams &&
          runtimeType == other.runtimeType &&
          mood == other.mood &&
          location == other.location &&
          _mapsEqual(filters, other.filters);

  @override
  int get hashCode => mood.hashCode ^ location.hashCode ^ (filters?.toString().hashCode ?? 0);

  bool _mapsEqual(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Provider for Moody Edge Function service
final moodyEdgeFunctionServiceProvider = Provider<MoodyEdgeFunctionService>((ref) {
  return MoodyEdgeFunctionService(Supabase.instance.client);
});

/// Provider that gets explore places from Moody Edge Function
/// 
/// Automatically uses current mood from dailyMoodState and current location
final moodyExploreProvider = FutureProvider.family<List<Place>, ExploreParams>((ref, params) async {
  final service = ref.watch(moodyEdgeFunctionServiceProvider);
  
  try {
    final places = await service.getExplore(
      mood: params.mood,
      location: params.location,
      filters: params.filters,
    );
    
    return places;
  } catch (e) {
    // Log error but don't crash - return empty list
    debugPrint('❌ Error in moodyExploreProvider: $e');
    return [];
  }
});

/// Convenience provider that automatically gets mood and location
/// 
/// This is the main provider to use in the Explore screen
final moodyExploreAutoProvider = FutureProvider<List<Place>>((ref) async {
  // Get current mood from daily mood state
  final dailyMoodState = ref.watch(dailyMoodStateNotifierProvider);
  final currentMood = dailyMoodState.currentMood ?? 'adventurous'; // Default to adventurous
  
  // Get current location
  final locationAsync = ref.watch(locationNotifierProvider);
  final location = locationAsync.value ?? 'Rotterdam'; // Default to Rotterdam
  
  // Build filters (can be extended later)
  final filters = <String, dynamic>{};
  
  // Create params and call the family provider
  final params = ExploreParams(
    mood: currentMood,
    location: location,
    filters: filters,
  );
  
  return ref.watch(moodyExploreProvider(params).future);
});

