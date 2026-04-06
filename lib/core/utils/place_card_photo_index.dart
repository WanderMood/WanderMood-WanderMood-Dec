import 'dart:math' as math;

/// Stable photo index for a place; varies when [refreshSeed] changes (e.g. Explore refresh).
int placeCardPhotoIndex(String placeId, int photoCount, {int refreshSeed = 0}) {
  final n = math.max(1, photoCount);
  final h = placeId.hashCode;
  return (h.abs() + refreshSeed) % n;
}
