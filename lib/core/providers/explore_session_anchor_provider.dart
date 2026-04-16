import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Locked Explore city + coordinates for the current app session.
/// Avoids reloading Explore when GPS drifts (e.g. train); refresh only via
/// pull-to-refresh / cold start / manual city pick.
class ExploreSessionAnchor {
  const ExploreSessionAnchor({
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  final String city;
  final double latitude;
  final double longitude;
}

final exploreSessionAnchorProvider =
    StateProvider<ExploreSessionAnchor?>((ref) => null);

/// Incremented when the user picks a city from [LocationDropdown] so Explore
/// can re-anchor and reload.
final exploreManualCityPickTickProvider = StateProvider<int>((ref) => 0);
