import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final extractPlaceFromUrlServiceProvider =
    Provider<ExtractPlaceFromUrlService>((ref) {
  return ExtractPlaceFromUrlService(Supabase.instance.client);
});

class ExtractedPlacePayload {
  const ExtractedPlacePayload({
    required this.placeId,
    required this.placeName,
    required this.source,
    required this.confidence,
    required this.placeData,
    this.sourceThumbnailUrl,
  });

  final String placeId;
  final String placeName;
  final String source;
  final String confidence;
  final Map<String, dynamic> placeData;
  final String? sourceThumbnailUrl;

  String? get photoUrl {
    final direct = placeData['photo_url'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;
    final photos = placeData['photos'];
    if (photos is List && photos.isNotEmpty) {
      return photos.first?.toString();
    }
    return null;
  }

  String? get city =>
      placeData['city'] as String? ??
      placeData['locality'] as String?;

  String? get primaryType {
    final types = placeData['types'];
    if (types is List && types.isNotEmpty) {
      return types.first?.toString();
    }
    return placeData['primary_type'] as String?;
  }

  double? get rating {
    final r = placeData['rating'];
    if (r is num) return r.toDouble();
    return double.tryParse('$r');
  }
}

class ExtractPlaceFromUrlService {
  ExtractPlaceFromUrlService(this._client);

  final SupabaseClient _client;

  Future<ExtractedPlacePayload?> extract({
    required String url,
    required String city,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'extract-place-from-url',
        body: {
          'url': url,
          'city': city,
          'save': false,
        },
      );

      if (response.status != 200) {
        if (kDebugMode) {
          debugPrint(
            'extract-place-from-url failed: ${response.status} ${response.data}',
          );
        }
        return null;
      }

      final raw = response.data;
      if (raw is! Map<String, dynamic>) return null;
      if (raw['success'] != true) return null;

      final placeId = raw['place_id'] as String?;
      final placeName = raw['place_name'] as String?;
      if (placeId == null ||
          placeId.isEmpty ||
          placeName == null ||
          placeName.isEmpty) {
        return null;
      }

      final placeData = Map<String, dynamic>.from(
        (raw['place_data'] as Map?)?.cast<String, dynamic>() ?? {},
      );

      return ExtractedPlacePayload(
        placeId: placeId,
        placeName: placeName,
        source: (raw['source'] as String?) ?? 'manual',
        confidence: (raw['confidence'] as String?) ?? 'medium',
        placeData: placeData,
        sourceThumbnailUrl: raw['source_thumbnail_url'] as String?,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('extract-place-from-url error: $e');
      return null;
    }
  }
}
