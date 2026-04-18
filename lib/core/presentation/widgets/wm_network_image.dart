import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wandermood/core/cache/wandermood_image_cache_manager.dart';
import 'package:wandermood/core/utils/google_place_photo_device_url.dart';

bool isGooglePlacePhotoHttpUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return false;
  final uri = Uri.tryParse(trimmed);
  final host = uri?.host.toLowerCase() ?? '';
  return (host == 'maps.googleapis.com' && trimmed.contains('place/photo')) ||
      (host == 'places.googleapis.com' && trimmed.contains('/media'));
}

/// [ImageProvider] for [DecorationImage], [CircleAvatar.backgroundImage], etc.
CachedNetworkImageProvider wmCachedNetworkImageProvider(String url) =>
    CachedNetworkImageProvider(
      url,
      cacheManager: WanderMoodImageCacheManager.instance,
    );

/// Drop-in style replacement for [Image.network] using the app-wide 90-day disk cache.
class WmNetworkImage extends StatelessWidget {
  const WmNetworkImage(
    this.src, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.low,
    this.errorBuilder,
    this.scale = 1.0,
    this.progressIndicatorBuilder,
  });

  final String src;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final ImageErrorWidgetBuilder? errorBuilder;
  final double scale;

  /// When set, used while the image is downloading (same role as [Image.loadingBuilder]).
  final ProgressIndicatorBuilder? progressIndicatorBuilder;

  @override
  Widget build(BuildContext context) {
    // OctoImage (used by cached_network_image) asserts: do not set both
    // [placeholder] and [progressIndicatorBuilder].
    final Widget Function(BuildContext, String)? placeholder =
        progressIndicatorBuilder != null
            ? null
            : (BuildContext _, String __) => ColoredBox(
                  color: Colors.grey.shade200,
                  child: const SizedBox.expand(),
                );

    return CachedNetworkImage(
      imageUrl: src,
      cacheManager: WanderMoodImageCacheManager.instance,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      scale: scale,
      placeholder: placeholder,
      progressIndicatorBuilder: progressIndicatorBuilder,
      errorWidget: errorBuilder != null
          ? (c, url, err) => errorBuilder!(c, err, StackTrace.current)
          : (c, url, err) => ColoredBox(
                color: Colors.grey.shade300,
                child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade600),
              ),
    );
  }
}

/// Google Place photos from Explore / `places_cache` — same URL rules as list cards, hero,
/// and Foto’s tab. Always use this (or [deviceAccessibleGooglePlacePhotoUrl] + [WmNetworkImage])
/// for `place.photos` / Moody `photo_url` strings so behavior stays identical everywhere.
class WmPlacePhotoNetworkImage extends StatelessWidget {
  const WmPlacePhotoNetworkImage(
    this.src, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.low,
    this.errorBuilder,
    this.scale = 1.0,
    this.progressIndicatorBuilder,
  });

  final String src;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final ImageErrorWidgetBuilder? errorBuilder;
  final double scale;
  final ProgressIndicatorBuilder? progressIndicatorBuilder;

  @override
  Widget build(BuildContext context) {
    return WmNetworkImage(
      deviceAccessibleGooglePlacePhotoUrl(src),
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      filterQuality: filterQuality,
      errorBuilder: errorBuilder,
      scale: scale,
      progressIndicatorBuilder: progressIndicatorBuilder,
    );
  }
}

/// Hero / activity / planner URLs that may be **Google Place Photo** or normal HTTPS (Unsplash, etc.).
/// Use instead of raw [CachedNetworkImage] so release builds get the same key rewrite as list cards.
class WmPlaceOrHttpsNetworkImage extends StatelessWidget {
  const WmPlaceOrHttpsNetworkImage(
    this.src, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.low,
    this.errorBuilder,
    this.scale = 1.0,
    this.progressIndicatorBuilder,
  });

  final String src;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final ImageErrorWidgetBuilder? errorBuilder;
  final double scale;
  final ProgressIndicatorBuilder? progressIndicatorBuilder;

  @override
  Widget build(BuildContext context) {
    final trimmed = src.trim();
    if (trimmed.isEmpty) {
      return errorBuilder != null
          ? errorBuilder!(context, Exception('empty image URL'), StackTrace.current)
          : ColoredBox(
              color: Colors.grey.shade300,
              child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade600),
            );
    }
    if (isGooglePlacePhotoHttpUrl(trimmed)) {
      return WmPlacePhotoNetworkImage(
        trimmed,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        filterQuality: filterQuality,
        errorBuilder: errorBuilder,
        scale: scale,
        progressIndicatorBuilder: progressIndicatorBuilder,
      );
    }
    return WmNetworkImage(
      deviceAccessibleGooglePlacePhotoUrl(trimmed),
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      filterQuality: filterQuality,
      errorBuilder: errorBuilder,
      scale: scale,
      progressIndicatorBuilder: progressIndicatorBuilder,
    );
  }
}
