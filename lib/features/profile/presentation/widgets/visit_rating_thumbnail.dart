import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/features/mood/models/activity_rating.dart';
import 'package:wandermood/features/profile/presentation/providers/visit_rating_photo_provider.dart';
import 'package:wandermood/features/profile/presentation/utils/visit_place_photo_policy.dart';

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

/// Preview for a saved visit — **only** real venue/cached/Google photos; otherwise emoji (no stock photos).
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

    final async = ref.watch(visitRatingPhotoUrlProvider(VisitRatingPhotoKey.from(rating)));

    final Widget child = async.when(
      data: (url) {
        final u = url?.trim() ?? '';
        if (u.isEmpty || isStockOrDecorativeImageUrl(u)) {
          return emojiPlaceholder();
        }
        return WmPlaceOrHttpsNetworkImage(
          u,
          fit: BoxFit.cover,
          width: _w,
          height: _h,
          errorBuilder: (_, __, ___) => emojiPlaceholder(),
        );
      },
      loading: () => ColoredBox(
        color: forestTint.withValues(alpha: 0.08),
        child: Center(
          child: SizedBox(
            width: math.min(28, _w * 0.45),
            height: math.min(28, _h * 0.45),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: forestTint.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
      error: (_, __) => emojiPlaceholder(),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: _w, height: _h, child: child),
    );
  }
}
