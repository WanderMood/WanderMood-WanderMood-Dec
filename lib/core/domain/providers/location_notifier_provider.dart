import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import '../../../features/location/services/location_service.dart';
import 'package:wandermood/core/utils/reverse_geocode_settlement.dart';

final locationNotifierProvider = AsyncNotifierProvider<LocationNotifier, String?>(() {
  return LocationNotifier();
});

class LocationNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    // No default city: UI should resolve GPS (see appInitializerProvider) or show
    // "locating…". Hard-coding Rotterdam made every user appear in Rotterdam until
    // reverse-geocode finished (or if init was skipped).
    return null;
  }

  Future<void> _restoreDeviceGeocoderLocale() async {
    try {
      final loc = ui.PlatformDispatcher.instance.locale;
      final cc = loc.countryCode;
      if (cc != null && cc.isNotEmpty) {
        await setLocaleIdentifier('${loc.languageCode}_$cc');
      } else {
        await setLocaleIdentifier(loc.languageCode);
      }
    } catch (_) {}
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

      // Low accuracy + modest time limit: 5s was too tight on cold GPS / iOS.
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 12),
      );
      debugPrint('Got position: ${position.latitude}, ${position.longitude}');
      
      // For development/simulator: If the coordinates are in San Francisco (simulator default),
      // use Rotterdam instead - but be less strict about this check
      if (_isSimulatorDefaultLocation(position.latitude, position.longitude)) {
        debugPrint('Detected simulator default location, using Rotterdam instead');
        state = AsyncValue.data(LocationService.defaultLocation['name'] as String);
        return LocationService.defaultLocation['name'] as String;
      }
      
      // Prefer Dutch locale for reverse-geocode (better locality for NL, e.g. Spijkenisse).
      List<Placemark> placemarks;
      try {
        await setLocaleIdentifier('nl_NL');
        placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
      } finally {
        await _restoreDeviceGeocoderLocale();
      }

      if (placemarks.isNotEmpty) {
        final cityName = settlementNameFromPlacemarks(placemarks) ??
            LocationService.defaultLocation['name'] as String;
        debugPrint(
          'Found settlement: $cityName (from ${placemarks.length} placemark(s))',
        );
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

  // Method to manually set a location
  void setLocation(String locationName) {
    state = AsyncValue.data(locationName);
  }

  // Method to retry getting location
  Future<void> retryLocationAccess() async {
    await getCurrentLocation();
  }
} 