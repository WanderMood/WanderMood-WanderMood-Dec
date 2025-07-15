import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/places/domain/models/place.dart';
import '../../../features/places/application/places_service.dart';
import '../../../features/location/providers/location_provider.dart';

/// Provider for nearby places
final nearbyPlacesProvider = FutureProvider.autoDispose<List<Place>>((ref) async {
  final location = await ref.watch(currentLocationProvider.future);
  if (location == null) return [];
  
  final placesService = ref.watch(placesServiceProvider);
  return await placesService.getNearbyPlaces(
    latitude: location.latitude,
    longitude: location.longitude,
    radius: 5000, // 5km radius
  );
}); 