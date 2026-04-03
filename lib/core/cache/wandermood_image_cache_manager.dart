import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Single [CacheManager] for all remote images in the app.
///
/// - [stalePeriod]: entries stay “fresh” for 90 days before background revalidation.
/// - [maxNrOfCacheObjects]: high cap so LRU eviction is unlikely before age-based staleness.
class WanderMoodImageCacheManager {
  WanderMoodImageCacheManager._();

  static const String _cacheKey = 'wandermood_image_cache_v1';

  static final CacheManager instance = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 90),
      maxNrOfCacheObjects: 10000,
    ),
  );
}
