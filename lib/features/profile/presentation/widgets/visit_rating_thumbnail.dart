import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/features/home/presentation/utils/activity_image_fallback.dart';
import 'package:wandermood/features/mood/models/activity_rating.dart';
import 'package:wandermood/features/plans/presentation/providers/place_photo_url_provider.dart';

String visitRatingVibeEmoji(ActivityRating rating) {
  if (rating.tags.isEmpty) return '✦';
  switch (rating.tags.first) {
    case 'Amazing':
      return '🤩';
    case 'Good':
      return '😊';
    case 'Okay':
      return '😐';
    case 'Meh':
      return '😞';
    default:
      return '✦';
  }
}

/// Preview for a saved visit: hero URL, then `places_cache` by place id, then vibe emoji.
class VisitRatingThumbnail extends ConsumerWidget {
  const VisitRatingThumbnail({
    super.key,
    required this.rating,
    this.size,
    this.width,
    this.height,
    this.borderRadius = 14,
    this.forestTint = const Color(0xFF2A6049),
  }) : assert(
          size != null || (width != null && height != null),
          'Provide size or both width and height',
        );

  final ActivityRating rating;
  final double? size;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color forestTint;

  double get _w => size ?? width!;
  double get _h => size ?? height!;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final direct = rating.heroImageUrl?.trim() ?? '';
    final pid = rating.googlePlaceId?.trim();
    final fallback = activityImageFallbackUrl(
      title: rating.activityName,
      mood: rating.mood,
    );
    final emoji = visitRatingVibeEmoji(rating);
    final emojiSize = math.min(_w, _h) * 0.45;

    Widget emojiPlaceholder() {
      return ColoredBox(
        color: forestTint.withValues(alpha: 0.12),
        child: Center(
          child: Text(emoji, style: TextStyle(fontSize: emojiSize)),
        ),
      );
    }

    late final Widget child;
    if (direct.isNotEmpty) {
      child = WmPlaceOrHttpsNetworkImage(
        direct,
        fit: BoxFit.cover,
        width: _w,
        height: _h,
        errorBuilder: (_, __, ___) => emojiPlaceholder(),
      );
    } else if (pid != null && pid.isNotEmpty) {
      final cached = ref.watch(placePhotoUrlProvider(pid));
      child = cached.when(
        data: (url) {
          final u = url?.trim() ?? '';
          if (u.isEmpty) return emojiPlaceholder();
          return WmPlaceOrHttpsNetworkImage(
            u,
            fit: BoxFit.cover,
            width: _w,
            height: _h,
            errorBuilder: (_, __, ___) => WmPlaceOrHttpsNetworkImage(
              fallback,
              fit: BoxFit.cover,
              width: _w,
              height: _h,
              errorBuilder: (_, ___, ____) => emojiPlaceholder(),
            ),
          );
        },
        loading: () => WmPlaceOrHttpsNetworkImage(
          fallback,
          fit: BoxFit.cover,
          width: _w,
          height: _h,
          errorBuilder: (_, __, ___) => emojiPlaceholder(),
        ),
        error: (_, __) => emojiPlaceholder(),
      );
    } else {
      child = emojiPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: _w, height: _h, child: child),
    );
  }
}
