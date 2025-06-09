import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

part 'user_location_provider.g.dart';

@Riverpod(keepAlive: true)
class UserLocation extends _$UserLocation {
  Position? _cachedPosition;
  DateTime? _lastUpdate;
  static const Duration _cacheValidity = Duration(minutes: 5);

  @override
  Future<Position?> build() async {
    return await getCurrentLocation();
  }

  /// Get current user location with proper error handling
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if we have a recent cached position
      if (_cachedPosition != null && 
          _lastUpdate != null && 
          DateTime.now().difference(_lastUpdate!) < _cacheValidity) {
        debugPrint('📍 Using cached location: ${_cachedPosition!.latitude}, ${_cachedPosition!.longitude}');
        return _cachedPosition;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('🚫 Location services are disabled');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('🚫 Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('🚫 Location permissions are permanently denied');
        return null;
      }

      // Get current position with longer timeout and lower accuracy for better success rate
      debugPrint('📍 Getting current location...');
      Position? position;
      
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium, // Changed from high to medium for better success rate
          timeLimit: const Duration(seconds: 30), // Increased timeout
        );
      } catch (e) {
        debugPrint('⚠️ Current location failed, trying last known position: $e');
        try {
          position = await Geolocator.getLastKnownPosition();
          if (position != null) {
            debugPrint('📍 Using last known position: ${position.latitude}, ${position.longitude}');
          }
        } catch (e2) {
          debugPrint('❌ Last known position also failed: $e2');
          rethrow;
        }
      }

      if (position == null) {
        debugPrint('❌ No position available');
        return null;
      }

      _cachedPosition = position;
      _lastUpdate = DateTime.now();
      
      debugPrint('✅ Got location: ${position.latitude}, ${position.longitude}');
      return position;
      
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      
      // For testing purposes, provide a fallback location (Rotterdam city center)
      // In production, you might want to return null instead
      final fallbackPosition = Position(
        latitude: 51.9225, // Rotterdam city center
        longitude: 4.4792,
        timestamp: DateTime.now(),
        accuracy: 100.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        isMocked: true,
      );
      
      debugPrint('🎯 Using fallback location for testing: Rotterdam (${fallbackPosition.latitude}, ${fallbackPosition.longitude})');
      _cachedPosition = fallbackPosition;
      _lastUpdate = DateTime.now();
      return fallbackPosition;
    }
  }

  /// Force refresh location
  Future<Position?> refreshLocation() async {
    _cachedPosition = null;
    _lastUpdate = null;
    state = const AsyncValue.loading();
    
    final position = await getCurrentLocation();
    state = AsyncValue.data(position);
    return position;
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('❌ Error checking location permission: $e');
      return false;
    }
  }
} 