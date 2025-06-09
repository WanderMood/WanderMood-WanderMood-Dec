import 'dart:math' as math;

class DistanceService {
  /// Calculate distance between two points using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    // Convert degrees to radians
    double lat1Rad = _degreesToRadians(lat1);
    double lon1Rad = _degreesToRadians(lon1);
    double lat2Rad = _degreesToRadians(lat2);
    double lon2Rad = _degreesToRadians(lon2);

    // Calculate differences
    double deltaLat = lat2Rad - lat1Rad;
    double deltaLon = lon2Rad - lon1Rad;

    // Haversine formula
    double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * 
        math.sin(deltaLon / 2) * math.sin(deltaLon / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 0.1) {
      return '<100m';
    } else if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()}m';
    } else if (distanceKm < 10.0) {
      return '${distanceKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceKm.round()}km';
    }
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Get user-friendly distance description
  static String getDistanceDescription(double distanceKm) {
    if (distanceKm < 0.5) {
      return 'Very close';
    } else if (distanceKm < 2.0) {
      return 'Walking distance';
    } else if (distanceKm < 5.0) {
      return 'Short drive';
    } else if (distanceKm < 15.0) {
      return 'Nearby';
    } else {
      return 'Further away';
    }
  }
} 