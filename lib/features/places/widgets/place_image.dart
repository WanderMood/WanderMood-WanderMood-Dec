import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wandermood/core/cache/wandermood_image_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/places/services/places_service.dart';
import 'package:wandermood/core/services/google_places_service.dart';
import 'package:wandermood/core/utils/logger.dart';

class PlaceImage extends ConsumerWidget {
  final String? photoReference;
  final String? placeType;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  const PlaceImage({
    Key? key,
    this.photoReference,
    this.placeType,
    this.width = 120,
    this.height = 120,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (photoReference == null || photoReference!.isEmpty) {
      return _buildFallbackImage();
    }

    // Handle asset images
    if (photoReference!.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          photoReference!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            Logger.error('Error loading asset image: $error');
            return _buildFallbackImage();
          },
        ),
      );
    }

    // Handle direct URLs
    if (photoReference!.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          cacheManager: WanderMoodImageCacheManager.instance,
          imageUrl: photoReference!,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => _buildLoadingContainer(),
          errorWidget: (context, url, error) {
            Logger.error('Error loading network image: $error');
            return _buildFallbackImage();
          },
        ),
      );
    }

    // Handle Google Places photo references
    final photoUrl = GooglePlacesService.getPhotoUrl(photoReference!, width.toInt());
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        cacheManager: WanderMoodImageCacheManager.instance,
        imageUrl: photoUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildLoadingContainer(),
        errorWidget: (context, url, error) {
          Logger.error('Error loading Google Places image: $error');
          return _buildFallbackImage();
        },
      ),
    );
  }

  Widget _buildLoadingContainer() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildFallbackImage() {
    String fallbackAsset;
    switch (placeType?.toLowerCase()) {
      case 'restaurant':
        fallbackAsset = 'assets/images/fallback_restaurant.png';
        break;
      case 'cafe':
        fallbackAsset = 'assets/images/fallback_cafe.png';
        break;
      case 'bar':
        fallbackAsset = 'assets/images/fallback_bar.png';
        break;
      case 'museum':
        fallbackAsset = 'assets/images/fallback_museum.png';
        break;
      case 'park':
        fallbackAsset = 'assets/images/fallback_park.png';
        break;
      case 'hotel':
        fallbackAsset = 'assets/images/fallback_hotel.png';
        break;
      default:
        fallbackAsset = 'assets/images/fallback_place.png';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey[600],
              size: width * 0.4,
            ),
          );
        },
      ),
    );
  }
} 