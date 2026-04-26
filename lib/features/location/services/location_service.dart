import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math' as math;

enum LocationError {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown
}

class LocationResult {
  final Position? position;
  final LocationError? error;

  LocationResult({this.position, this.error});
}

class LocationService {
  static const Map<String, dynamic> defaultLocation = {
    'latitude': 51.9225,  // Rotterdam coordinates
    'longitude': 4.4792,
    'name': 'Rotterdam'
  };

  // Cache for location to prevent redundant GPS calls
  static Position? _lastKnownLocation;
  static DateTime? _lastLocationTime;
  static const Duration _locationCacheValidDuration = Duration(minutes: 2); // Reduced from 30s to 2min

  static Future<Position> getCurrentLocation() async {
    // Check if we have recent cached location
    if (_lastKnownLocation != null && _lastLocationTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastLocationTime!);
      if (timeSinceLastFetch < _locationCacheValidDuration) {
        // Check if the cached location changed significantly
        final hasLocationChanged = _hasLocationChanged(
          _lastKnownLocation!.latitude, _lastKnownLocation!.longitude,
          _lastKnownLocation!.latitude, _lastKnownLocation!.longitude,
          threshold: 0.001, // ~100 meters
        );

        if (!hasLocationChanged) {
          print('📍 Using cached location (${timeSinceLastFetch.inSeconds}s old)');
          return _lastKnownLocation!;
        }
      }
    }

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      final fallbackPosition = _createFallbackPosition();
      _cacheLocation(fallbackPosition);
      return fallbackPosition;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        final fallbackPosition = _createFallbackPosition();
        _cacheLocation(fallbackPosition);
        return fallbackPosition;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      final fallbackPosition = _createFallbackPosition();
      _cacheLocation(fallbackPosition);
      return fallbackPosition;
    }

    try {
      print('🌍 Fetching fresh GPS location...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Changed from medium to low for faster response  
        timeLimit: const Duration(seconds: 5), // Reduced from no timeout to 5s
      );
      _cacheLocation(position);
      print('✅ GPS location updated: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ GPS location failed after 5s: $e');
      
      // Try last known position as fallback
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          print('📍 Using last known position: ${lastKnown.latitude}, ${lastKnown.longitude}');
          _cacheLocation(lastKnown);
          return lastKnown;
        }
      } catch (e2) {
        print('❌ Last known position also failed: $e2');
      }
      
      // Final fallback to Rotterdam
      final fallbackPosition = _createFallbackPosition();
      _cacheLocation(fallbackPosition);
      return fallbackPosition;
    }
  }

  /// Simple distance calculation to check if location changed significantly
  static bool _hasLocationChanged(double lat1, double lng1, double lat2, double lng2, {required double threshold}) {
    final distance = math.sqrt(math.pow(lat2 - lat1, 2) + math.pow(lng2 - lng1, 2));
    return distance > threshold;
  }

  /// Cache the location to prevent redundant GPS calls
  static void _cacheLocation(Position position) {
    _lastKnownLocation = position;
    _lastLocationTime = DateTime.now();
  }

  /// Get the last known location without making a new GPS request
  static Position? getLastKnownLocation() {
    if (_lastKnownLocation != null && _lastLocationTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastLocationTime!);
      if (timeSinceLastFetch < const Duration(minutes: 5)) {
        return _lastKnownLocation;
      }
    }
    return null;
  }

  /// Force refresh location (bypasses cache)
  static Future<Position> forceRefreshLocation() async {
    _lastKnownLocation = null;
    _lastLocationTime = null;
    return getCurrentLocation();
  }

  static Future<String?> getCurrentCity() async {
    try {
      final result = await getCurrentLocation();
      
      if (result.accuracy == 0) return defaultLocation['name'] as String;

      final placemarks = await placemarkFromCoordinates(
        result.latitude!,
        result.longitude!,
      );

      if (placemarks.isEmpty) return defaultLocation['name'] as String;

      final place = placemarks.first;
      final city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea;
      
      return city ?? defaultLocation['name'] as String;
    } catch (e) {
      return defaultLocation['name'] as String;
    }
  }

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  static Future<Position> getCoordinatesForCity(String cityName) async {
    try {
      final locations = await locationFromAddress(cityName);
      if (locations.isEmpty) {
        return Position(
          latitude: defaultLocation['latitude'] as double,
          longitude: defaultLocation['longitude'] as double,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
          isMocked: false,
        );
      }
      
      return Position(
        latitude: locations.first.latitude,
        longitude: locations.first.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
        isMocked: false,
      );
    } catch (e) {
      return Position(
        latitude: defaultLocation['latitude'] as double,
        longitude: defaultLocation['longitude'] as double,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
        isMocked: false,
      );
    }
  }

  /// Create a consistent fallback position for Rotterdam
  static Position _createFallbackPosition() {
    print('🏭 Using Rotterdam fallback coordinates');
    return Position(
      latitude: defaultLocation['latitude'] as double,
      longitude: defaultLocation['longitude'] as double,
      timestamp: DateTime.now(),
      accuracy: 1000, // 1km accuracy to indicate this is estimated
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
      isMocked: true, // Mark as mocked so app knows it's fallback
    );
  }
} 