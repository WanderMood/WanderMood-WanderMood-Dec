/// Thrown when Explore or plan generation cannot proceed without a city or GPS fix.
///
/// Screens should detect this type and show [AppLocalizations] strings — not [toString].
class ExploreLocationException implements Exception {
  const ExploreLocationException(this.reason);

  final ExploreLocationReason reason;

  @override
  String toString() => 'ExploreLocationException($reason)';
}

enum ExploreLocationReason {
  missingCity,
  missingCoordinates,
  invalidCoordinates,
}
