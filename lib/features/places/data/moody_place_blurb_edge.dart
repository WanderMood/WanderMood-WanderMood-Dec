import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/places/data/moody_place_blurb_facts.dart';

/// Server-side Moody blurb when the app has no `OPENAI_API_KEY` (uses Edge `OPENAI_API_KEY`).
Future<String> moodyPlaceCardBlurbFromEdge({
  required String facts,
  required String languageCode,
}) async {
  final trimmed = clampMoodyPlaceBlurbFactsForEdge(facts);
  if (trimmed.isEmpty) return '';
  if (kDebugMode && facts.trim().length > kMoodyPlaceBlurbFactsMaxChars) {
    debugPrint(
      'moody place_card_blurb: facts clamped ${facts.trim().length} → ${trimmed.length} chars',
    );
  }
  try {
    final res = await Supabase.instance.client.functions.invoke(
      'moody',
      body: {
        'action': 'place_card_blurb',
        'facts': trimmed,
        'languageCode': languageCode,
      },
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

Future<String> moodyPlaceDetailBlurbFromEdge({
  required String facts,
  required String languageCode,
}) async {
  final trimmed = clampMoodyPlaceBlurbFactsForEdge(facts);
  if (trimmed.isEmpty) return '';
  if (kDebugMode && facts.trim().length > kMoodyPlaceBlurbFactsMaxChars) {
    debugPrint(
      'moody place_detail_blurb: facts clamped ${facts.trim().length} → ${trimmed.length} chars',
    );
  }
  try {
    final res = await Supabase.instance.client.functions.invoke(
      'moody',
      body: {
        'action': 'place_detail_blurb',
        'facts': trimmed,
        'languageCode': languageCode,
      },
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
