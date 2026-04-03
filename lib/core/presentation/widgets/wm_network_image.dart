import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wandermood/core/cache/wandermood_image_cache_manager.dart';

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
    final placeholder = progressIndicatorBuilder != null
        ? (BuildContext c, String url) => progressIndicatorBuilder!(
              c,
              url,
              DownloadProgress(url, null, 0),
            )
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
