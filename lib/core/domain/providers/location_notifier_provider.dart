import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import '../entities/location.dart';
import '../../../features/location/services/location_service.dart';

final locationNotifierProvider = AsyncNotifierProvider<LocationNotifier, String?>(() {
  return LocationNotifier();
});

class LocationNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    // Don't fetch location immediately to avoid provider modification during build
    // Return default location, location will be fetched when explicitly requested
    return 'Rotterdam';
  }

  Future<String?> getCurrentLocation() async {
    state = const AsyncValue.loading();
    debugPrint('⚠️ LOCATION: Starting location detection process');
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied, using Rotterdam as default');
          state = AsyncValue.data(LocationService.defaultLocation['name'] as String);
          return LocationService.defaultLocation['name'] as String;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied, using Rotterdam as default');
        state = AsyncValue.data(LocationService.defaultLocation['name'] as String);
        return LocationService.defaultLocation['name'] as String;
      }

      // Get current position with higher accuracy settings
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      debugPrint('Got position: ${position.latitude}, ${position.longitude}');
      
      // For development/simulator: If the coordinates are in San Francisco (simulator default),
      // use Rotterdam instead - but be less strict about this check
      if (_isSimulatorDefaultLocation(position.latitude, position.longitude)) {
        debugPrint('Detected simulator default location, using Rotterdam instead');
        state = AsyncValue.data(LocationService.defaultLocation['name'] as String);
        return LocationService.defaultLocation['name'] as String;
      }
      
      // Get place name from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Try multiple fields to get the city name
        final cityName = place.locality ?? 
                        place.subAdministrativeArea ?? 
                        place.administrativeArea ??
                        LocationService.defaultLocation['name'] as String;
        debugPrint('Found city name: $cityName');
        state = AsyncValue.data(cityName);
        return cityName;
      } else {
        debugPrint('Could not determine location name, using Rotterdam as default');
        state = AsyncValue.data(LocationService.defaultLocation['name'] as String);
        return LocationService.defaultLocation['name'] as String;
      }
    } catch (e, stack) {
      debugPrint('Error getting location: $e, using Rotterdam as default');
      // If we're in debug mode, let's be less aggressive and try to return null first
      if (kDebugMode) {
        debugPrint('Full error details: $stack');
      }
      state = AsyncValue.data(LocationService.defaultLocation['name'] as String);
      return LocationService.defaultLocation['name'] as String;
    }
  }
  
  // Helper method to detect if we're getting the simulator's default location (San Francisco)
  bool _isSimulatorDefaultLocation(double lat, double lon) {
    // Check if coordinates are approximately in San Francisco (simulator default)
    const sfLat = 37.785834;
    const sfLon = -122.406417;
    
    // Make detection more lenient - check if within 1 degree (larger area)
    // This will ensure we catch the SF coordinates even if they're slightly different
    final bool isSF = (lat - sfLat).abs() < 1.0 && (lon - sfLon).abs() < 1.0;
    
    debugPrint('LOCATION CHECK: Current: (${lat}, ${lon}), SF default: ($sfLat, $sfLon)');
    debugPrint('LOCATION MATCH: ${isSF ? "YES - using Rotterdam instead" : "NO - using actual location"}');
    debugPrint('Rotterdam default: (${LocationService.defaultLocation['latitude']}, ${LocationService.defaultLocation['longitude']})');
    
    return isSF;
  }

  // Method to retry getting location
  Future<void> retryLocationAccess() async {
    await getCurrentLocation();
  }
} 