import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String? name;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.name,
  });
}

class LocationService {
  Future<LocationData?> getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get place name
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String? locationName;
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        locationName = place.locality ?? place.subLocality ?? place.administrativeArea;
      }

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        name: locationName,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting location: $e');
      return null;
    }
  }

  Future<LocationData?> getLocationFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return LocationData(
          latitude: location.latitude,
          longitude: location.longitude,
          name: address,
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting location from address: $e');
      return null;
    }
  }
} 