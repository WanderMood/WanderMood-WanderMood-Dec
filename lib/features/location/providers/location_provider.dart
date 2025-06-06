import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/location/services/location_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

part 'location_provider.g.dart';

@riverpod
class LocationNotifier extends AutoDisposeAsyncNotifier<String?> {
  @override
  FutureOr<String?> build() async {
    // Always get current location on initialization
    return getCurrentLocation();
  }

  Future<String?> getCurrentLocation() async {
    state = const AsyncValue.loading();
    try {
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          state = const AsyncValue.data(null);
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        state = const AsyncValue.data(null);
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition();
      debugPrint('Got position: ${position.latitude}, ${position.longitude}');

      // Get place name from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final cityName = place.locality ?? 
                        place.subAdministrativeArea ?? 
                        place.administrativeArea;
        if (cityName != null) {
          debugPrint('Found city name: $cityName');
          state = AsyncValue.data(cityName);
          return cityName;
        }
      }

      debugPrint('Could not determine city name');
      state = const AsyncValue.data(null);
      return null;
    } catch (e) {
      debugPrint('Error getting location: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }

  // Method to manually set a city
  Future<void> setCity(String cityName) async {
    state = const AsyncValue.loading();
    debugPrint('Manually setting city to: $cityName');
    
    try {
      // Get coordinates for the city
      final position = await LocationService.getCoordinatesForCity(cityName);
      debugPrint('Found coordinates for $cityName: ${position.latitude}, ${position.longitude}');
      state = AsyncValue.data(cityName);
    } catch (e) {
      debugPrint('Error getting coordinates for $cityName: $e');
      state = AsyncValue.data(cityName); // Still set the city even if coordinates lookup fails
    }
  }

  // Method to retry getting location
  Future<void> retryLocationAccess() async {
    await getCurrentLocation();
  }
} 