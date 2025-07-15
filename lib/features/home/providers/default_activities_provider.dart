import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/places/domain/models/place.dart';
import '../../../features/places/application/places_service.dart';
import '../../../features/location/providers/location_provider.dart';

/// Provider for default activities based on time of day
final defaultActivitiesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final location = await ref.watch(currentLocationProvider.future);
  if (location == null) return [];
  
  final placesService = ref.watch(placesServiceProvider);
  final hour = DateTime.now().hour;
  
  // Get nearby places based on time of day
  final List<String> placeTypes = [];
  if (hour >= 6 && hour < 12) {
    placeTypes.addAll(['cafe', 'park', 'gym']); // Morning activities
  } else if (hour >= 12 && hour < 17) {
    placeTypes.addAll(['restaurant', 'museum', 'shopping_mall']); // Afternoon activities
  } else {
    placeTypes.addAll(['restaurant', 'bar', 'movie_theater']); // Evening activities
  }
  
  final places = await placesService.getNearbyPlacesByTypes(
    latitude: location.latitude,
    longitude: location.longitude,
    radius: 2000, // 2km radius
    types: placeTypes,
  );
  
  // Convert places to activity format
  return places.map((place) {
    String category;
    int duration;
    String mood;
    
    // Determine category and duration based on place type
    if (place.types.contains('restaurant') || place.types.contains('cafe')) {
      category = 'food';
      duration = 90;
      mood = 'relaxed';
    } else if (place.types.contains('park') || place.types.contains('gym')) {
      category = 'exercise';
      duration = 60;
      mood = 'energetic';
    } else if (place.types.contains('museum')) {
      category = 'culture';
      duration = 120;
      mood = 'curious';
    } else if (place.types.contains('bar') || place.types.contains('movie_theater')) {
      category = 'entertainment';
      duration = 180;
      mood = 'social';
    } else {
      category = 'general';
      duration = 60;
      mood = 'relaxed';
    }
    
    return {
      'id': place.id,
      'title': place.name,
      'description': place.description ?? 'Explore this amazing place',
      'category': category,
      'timeOfDay': hour < 12 ? 'morning' : (hour < 17 ? 'afternoon' : 'evening'),
      'duration': duration,
      'mood': mood,
      'imageUrl': place.photos.isNotEmpty ? place.photos.first : 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&q=80',
      'isRecommended': true,
      'location': place.location,
    };
  }).toList();
}); 