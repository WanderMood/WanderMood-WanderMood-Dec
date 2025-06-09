import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';

final imageServiceProvider = Provider<ImageService>((ref) => ImageService());

class ImageService {
  final _cache = DefaultCacheManager();
  
  // Predefined fallback images for different place types - using real images
  final Map<String, String> _fallbackImages = {
    'restaurant': 'assets/images/tom-podmore-3mEK924ZuTs-unsplash.jpg',
    'cafe': 'assets/images/diego-jimenez-A-NVHPka9Rk-unsplash.jpg',
    'bar': 'assets/images/pedro-lastra-Nyvq2juw4_o-unsplash.jpg',
    'museum': 'assets/images/pietro-de-grandi-T7K4aEPoGGk-unsplash.jpg',
    'park': 'assets/images/dino-reichmuth-A5rCN8626Ck-unsplash.jpg',
    'hotel': 'assets/images/mesut-kaya-eOcyhe5-9sQ-unsplash.jpg',
    'default': 'assets/images/philipp-kammerer-6Mxb_mZ_Q8E-unsplash.jpg',
  };

  Future<String> getImageUrl(String? photoReference, String placeType, {int maxWidth = 600, int maxHeight = 400}) async {
    // Force using fallback images (Google Places API disabled)
    debugPrint('🚫 Google Places Photo API disabled - using fallback image for type: $placeType');
    return _getFallbackImageUrl(placeType);
  }

  String _getFallbackImageUrl(String placeType) {
    final fallbackImage = _fallbackImages[placeType.toLowerCase()] ?? _fallbackImages['default']!;
    debugPrint('🖼️ Using fallback image for type: $placeType');
    return fallbackImage;
  }

  Future<void> preloadFallbackImages(BuildContext context) async {
    for (final image in _fallbackImages.values) {
      precacheImage(AssetImage(image), context);
    }
  }

  Future<void> clearCache() async {
    await _cache.emptyCache();
    debugPrint('🧹 Image cache cleared');
  }
} 