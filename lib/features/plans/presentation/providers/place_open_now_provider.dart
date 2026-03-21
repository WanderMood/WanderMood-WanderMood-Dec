import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opening hours / open-now are not stored in `places_cache` explore cards.
/// Avoids Google Place Details from plan surfaces.
final placeOpenNowProvider =
    FutureProvider.autoDispose.family<bool?, String>((ref, placeId) async {
  return null;
});
