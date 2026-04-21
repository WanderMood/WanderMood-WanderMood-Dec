import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/features/plans/presentation/providers/place_photo_url_provider.dart';

/// Category/title-based Unsplash fallback when a scheduled activity has no
/// real photo (e.g. AI recommendation without a Google Place match, or a
/// Mood Match plan saved before the image pipeline forwarded photos).
///
/// Centralised here so My Day and My Plans render the same graceful fallback
/// instead of one showing a broken-image placeholder.
String activityImageFallbackUrl({
  String? category,
  String? title,
  String? mood,
}) {
  final cat = (category ?? '').toLowerCase();
  final ttl = (title ?? '').toLowerCase();
  final md = (mood ?? '').toLowerCase();

  if (cat.contains('nature') ||
      ttl.contains('garden') ||
      ttl.contains('park') ||
      md.contains('calm') ||
      md.contains('relaxed')) {
    return 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&q=80';
  }
  if (cat.contains('cultural') ||
      ttl.contains('museum') ||
      ttl.contains('gallery') ||
      ttl.contains('theater') ||
      ttl.contains('theatre')) {
    return 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&q=80';
  }
  if (cat.contains('food') ||
      ttl.contains('market') ||
      ttl.contains('restaurant') ||
      ttl.contains('cafe') ||
      ttl.contains('coffee') ||
      ttl.contains('bar') ||
      ttl.contains('lunch') ||
      ttl.contains('dinner')) {
    return 'https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=400&q=80';
  }
  if (cat.contains('outdoor') ||
      ttl.contains('walk') ||
      ttl.contains('hike') ||
      ttl.contains('beach')) {
    return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&q=80';
  }
  // Generic activity image (same as agenda default).
  return 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&q=80';
}

/// Convenience overload for `Map<String, dynamic>` activity rows as returned
/// by [scheduled_activity_service] / Mood Match planner.
String activityImageFallbackFromRaw(Map<String, dynamic> raw) {
  return activityImageFallbackUrl(
    category: raw['category']?.toString(),
    title: (raw['title'] ?? raw['name'] ?? raw['place_name'])?.toString(),
    mood: raw['mood']?.toString(),
  );
}

/// Image widget for a scheduled activity that resolves real Google Place photos
/// even when `image_url` is empty (rows saved before the image pipeline was
/// fixed). Resolution order:
///   1. `imageUrl` on the row
///   2. `places_cache` lookup via [placePhotoUrlProvider] when `placeId` is set
///   3. Category-based Unsplash fallback (same as My Plans legacy default)
///
/// The final `errorBuilder` drops into an optional caller-provided placeholder
/// so the card never shows a broken-image glyph.
class ActivityPhoto extends ConsumerWidget {
  const ActivityPhoto({
    super.key,
    required this.directUrl,
    required this.placeId,
    required this.category,
    required this.title,
    this.mood,
    this.fit = BoxFit.cover,
    this.progressIndicatorBuilder,
    this.placeholderBuilder,
  });

  final String directUrl;
  final String? placeId;
  final String? category;
  final String? title;
  final String? mood;
  final BoxFit fit;
  final ProgressIndicatorBuilder? progressIndicatorBuilder;
  final WidgetBuilder? placeholderBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final direct = directUrl.trim();
    final fallback = activityImageFallbackUrl(
      category: category,
      title: title,
      mood: mood,
    );

    // Row already has a real photo — use it directly.
    if (direct.isNotEmpty) {
      return _buildImage(context, direct, fallback);
    }

    // No photo on the row yet, but we have a place_id → try places_cache.
    final pid = placeId?.trim();
    if (pid != null && pid.isNotEmpty) {
      final cached = ref.watch(placePhotoUrlProvider(pid));
      return cached.when(
        data: (url) {
          final src = url?.trim() ?? '';
          return _buildImage(context, src.isNotEmpty ? src : fallback, fallback);
        },
        loading: () => _buildImage(context, fallback, fallback),
        error: (_, __) => _buildImage(context, fallback, fallback),
      );
    }

    return _buildImage(context, fallback, fallback);
  }

  Widget _buildImage(BuildContext context, String src, String fallback) {
    return WmPlaceOrHttpsNetworkImage(
      src,
      fit: fit,
      progressIndicatorBuilder: progressIndicatorBuilder,
      errorBuilder: (context, error, stackTrace) {
        // Primary failed — try fallback before giving up to placeholder.
        if (src != fallback) {
          return WmPlaceOrHttpsNetworkImage(
            fallback,
            fit: fit,
            errorBuilder: (context, _, __) =>
                placeholderBuilder?.call(context) ??
                const ColoredBox(color: Color(0xFFE0E0E0)),
          );
        }
        return placeholderBuilder?.call(context) ??
            const ColoredBox(color: Color(0xFFE0E0E0));
      },
    );
  }
}
