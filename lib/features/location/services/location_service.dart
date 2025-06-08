import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
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

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
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

    if (permission == LocationPermission.deniedForever) {
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

    try {
      return await Geolocator.getCurrentPosition();
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
} 