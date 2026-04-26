import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/places/data/moody_place_blurb_facts.dart';
import 'package:wandermood/features/places/data/place_card_ui_description.dart';

/// Server-side Moody blurb when the app has no `OPENAI_API_KEY` (uses Edge `OPENAI_API_KEY`).
Future<String> moodyPlaceCardBlurbFromEdge({
  required String facts,
  required String languageCode,
  String? placeId,
}) async {
  final trimmed = clampMoodyPlaceBlurbFactsForEdge(facts);
  if (trimmed.isEmpty) return '';
  if (kDebugMode && facts.trim().length > kMoodyPlaceBlurbFactsMaxChars) {
    debugPrint(
      'moody place_card_blurb: facts clamped ${facts.trim().length} → ${trimmed.length} chars',
    );
  }
  try {
    final body = <String, dynamic>{
      'action': 'place_card_blurb',
      'facts': trimmed,
      'languageCode': languageCode,
    };
    if (placeId != null && placeId.isNotEmpty) body['placeId'] = placeId;
    final res = await Supabase.instance.client.functions.invoke(
      'moody',
      body: body,
    );
    if (res.status != 200) {
      debugPrint('moody place_card_blurb edge failed with status: ${res.status}');
      return '';
    }
    final raw = res.data;
    if (raw is Map) {
      final ok = raw['success'];
      if (ok == false && kDebugMode) {
        debugPrint('moody place_card_blurb edge success=false error=${raw['error']}');
      }
      final b = raw['blurb'];
      debugPrint('moody place_card_blurb edge returned blurb: $b');
      if (b is String && b.trim().isNotEmpty) return b.trim();
    }
  } catch (e) {
    debugPrint('moody place_card_blurb edge: $e');
  }
  return '';
}

/// Grounded multi-section Explore card copy (persona v3 on the edge).
Future<PlaceExploreRichResult?> moodyPlaceExploreRichFromEdge({
  required String facts,
  required String languageCode,
  String communicationStyle = 'friendly',
  String? placeId,
}) async {
  final trimmed = clampMoodyPlaceBlurbFactsForEdge(facts);
  if (trimmed.isEmpty) return null;
  if (kDebugMode && facts.trim().length > kMoodyPlaceBlurbFactsMaxChars) {
    debugPrint(
      'moody place_explore_rich: facts clamped ${facts.trim().length} → ${trimmed.length} chars',
    );
  }
  try {
    final body = <String, dynamic>{
      'action': 'place_explore_rich',
      'facts': trimmed,
      'languageCode': languageCode,
      'communicationStyle': communicationStyle,
    };
    if (placeId != null && placeId.isNotEmpty) body['placeId'] = placeId;
    final res = await Supabase.instance.client.functions.invoke(
      'moody',
      body: body,
    );
    if (res.status != 200) {
      if (kDebugMode) {
        debugPrint(
          'moody place_explore_rich edge failed with status: ${res.status}',
        );
      }
      return null;
    }
    final raw = res.data;
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    if (map['success'] == false) {
      if (kDebugMode) {
        debugPrint(
          'moody place_explore_rich success=false error=${map['error']}',
        );
      }
      return null;
    }
    final parsed = PlaceExploreRichResult.tryParse(map);
    if (parsed != null && parsed.isValid) {
      if (kDebugMode) {
        debugPrint(
          'moody place_explore_rich ok len=${parsed.sectionsJoined.length}',
        );
      }
      return parsed;
    }
  } catch (e) {
    debugPrint('moody place_explore_rich edge: $e');
  }
  return null;
}

Future<String> moodyPlaceDetailBlurbFromEdge({
  required String facts,
  required String languageCode,
  String? placeId,
}) async {
  final trimmed = clampMoodyPlaceBlurbFactsForEdge(facts);
  if (trimmed.isEmpty) return '';
  if (kDebugMode && facts.trim().length > kMoodyPlaceBlurbFactsMaxChars) {
    debugPrint(
      'moody place_detail_blurb: facts clamped ${facts.trim().length} → ${trimmed.length} chars',
    );
  }
  try {
    final body = <String, dynamic>{
      'action': 'place_detail_blurb',
      'facts': trimmed,
      'languageCode': languageCode,
    };
    if (placeId != null && placeId.isNotEmpty) body['placeId'] = placeId;
    final res = await Supabase.instance.client.functions.invoke(
      'moody',
      body: body,
    );
    if (res.status != 200) {
      debugPrint('moody place_detail_blurb edge failed with status: ${res.status}');
      return '';
    }
    final raw = res.data;
    if (raw is Map) {
      final ok = raw['success'];
      if (ok == false && kDebugMode) {
        debugPrint('moody place_detail_blurb edge success=false error=${raw['error']}');
      }
      final b = raw['blurb'];
      debugPrint('moody place_detail_blurb edge returned blurb: $b');
      if (b is String && b.trim().isNotEmpty) return b.trim();
    }
  } catch (e) {
    debugPrint('moody place_detail_blurb edge: $e');
  }
  return '';
}
