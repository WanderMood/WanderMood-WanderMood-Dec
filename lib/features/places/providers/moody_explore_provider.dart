import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/core/services/moody_edge_function_service.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

/// Parameters for the moody explore provider
class ExploreParams {
  final String mood;
  final String location;
  final double latitude;
  final double longitude;
  final Map<String, dynamic>? filters;

  ExploreParams({
    required this.mood,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.filters,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExploreParams &&
          runtimeType == other.runtimeType &&
          mood == other.mood &&
          location == other.location &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          _mapsEqual(filters, other.filters);

  @override
  int get hashCode => mood.hashCode ^ location.hashCode ^ latitude.hashCode ^ longitude.hashCode ^ (filters?.toString().hashCode ?? 0);

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
      latitude: params.latitude,
      longitude: params.longitude,
      filters: params.filters,
    );
    
    return places;
  } catch (e) {
    // Log error - this will be handled by UI to show error state
    debugPrint('❌ Error in moodyExploreProvider: $e');
    rethrow; // Re-throw so UI can show proper error state
  }
});

/// Convenience provider that automatically gets mood and location
/// 
/// This is the main provider to use in the Explore screen
/// 
/// CRITICAL: Location and coordinates are REQUIRED - no defaults
/// If location is missing, this will throw an error that UI should handle
final moodyExploreAutoProvider = FutureProvider<List<Place>>((ref) async {
  // Get current mood from daily mood state
  final dailyMoodState = ref.watch(dailyMoodStateNotifierProvider);
  final currentMood = dailyMoodState.currentMood ?? 'adventurous'; // Default to adventurous
  
  // CRITICAL: Get location name (city)
  final locationAsync = ref.watch(locationNotifierProvider);
  final location = locationAsync.value;
  
  // CRITICAL: Validate location exists - no defaults allowed
  if (location == null || location.isEmpty || location.trim().isEmpty) {
    throw Exception('Location is required. Please enable location services or set your location in settings.');
  }
  
  // CRITICAL: Get GPS coordinates - use .future to get the Future directly
  final position = await ref.read(userLocationProvider.future);
  
  // CRITICAL: Validate coordinates exist - no defaults allowed
  if (position == null) {
    throw Exception('GPS coordinates are required. Please enable location services.');
  }
  
  // CRITICAL: Don't use fallback/mock positions
  if (position.isMocked == true) {
    debugPrint('⚠️ Location is mocked/fallback - this should not be used in production');
    // Still allow it for now, but log a warning
  }
  
  // Build filters (can be extended later)
  final filters = <String, dynamic>{};
  
  // Create params with validated location and coordinates
  final params = ExploreParams(
    mood: currentMood,
    location: location.trim(),
    latitude: position.latitude,
    longitude: position.longitude,
    filters: filters,
  );
  
  return ref.watch(moodyExploreProvider(params).future);
});

