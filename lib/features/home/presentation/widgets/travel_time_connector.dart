import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/services/distance_service.dart';

/// Connector shown between two consecutive My Day activity cards.
/// Estimates travel time from straight-line (Haversine) distance with
/// realistic speed constants, with no extra API call.
class TravelTimeConnector extends StatelessWidget {
  const TravelTimeConnector({
    super.key,
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
  });

  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;

  static const double _walkingSpeedKmH = 5.0;
  static const double _cyclingSpeedKmH = 15.0;
  static const double _transitSpeedKmH = 25.0;

  // Straight-line has ~1.3× real-route multiplier for urban walking.
  static const double _routeMultiplier = 1.3;

  static const Color _wmForest = Color(0xFF2A6049);
  static const Color _wmStone = Color(0xFF8C8780);
  static const Color _wmParchment = Color(0xFFE8E2D8);

  _TravelEstimate _estimate(double km) {
    final realKm = km * _routeMultiplier;
    final walkMin = (realKm / _walkingSpeedKmH * 60).round();

    if (realKm < 0.25) {
      return _TravelEstimate(
        icon: Icons.directions_walk,
        label: walkMin <= 1 ? '< 1 min lopen' : '$walkMin min lopen',
        mode: 'walking',
        distanceLabel: DistanceService.formatDistance(km),
      );
    } else if (realKm < 1.5) {
      return _TravelEstimate(
        icon: Icons.directions_walk,
        label: '$walkMin min lopen',
        mode: 'walking',
        distanceLabel: DistanceService.formatDistance(km),
      );
    } else if (realKm < 4.0) {
      final cycleMin = (realKm / _cyclingSpeedKmH * 60).round();
      return _TravelEstimate(
        icon: Icons.directions_bike,
        label: '${cycleMin} min fietsen  ·  ${walkMin} min lopen',
        mode: 'cycling',
        distanceLabel: DistanceService.formatDistance(km),
      );
    } else {
      final transitMin = (realKm / _transitSpeedKmH * 60).round();
      return _TravelEstimate(
        icon: Icons.directions_transit,
        label: '≈ $transitMin min OV  ·  ${DistanceService.formatDistance(km)}',
        mode: 'transit',
        distanceLabel: DistanceService.formatDistance(km),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final km = DistanceService.calculateDistance(fromLat, fromLng, toLat, toLng);

    // Same location (< 50 m) — no connector needed.
    if (km < 0.05) return const SizedBox.shrink();

    final est = _estimate(km);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Vertical line + dot
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 14,
                  color: _wmParchment,
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _wmParchment,
                    shape: BoxShape.circle,
                    border: Border.all(color: _wmStone, width: 1),
                  ),
                ),
                Container(
                  width: 2,
                  height: 14,
                  color: _wmParchment,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(est.icon, size: 14, color: _wmStone),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              est.label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: _wmStone,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelEstimate {
  final IconData icon;
  final String label;
  final String mode;
  final String distanceLabel;

  const _TravelEstimate({
    required this.icon,
    required this.label,
    required this.mode,
    required this.distanceLabel,
  });
}

/// Parses a "lat,lng" location string stored in EnhancedActivityData.rawData.
/// Returns null if parsing fails.
({double lat, double lng})? parseTravelLocation(Map<String, dynamic> rawData) {
  final loc = rawData['location'];
  if (loc == null) return null;
  if (loc is String) {
    final parts = loc.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) return (lat: lat, lng: lng);
    }
  }
  return null;
}
