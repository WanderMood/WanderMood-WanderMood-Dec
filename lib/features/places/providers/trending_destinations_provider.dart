import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/presentation/providers/language_provider.dart';
import 'package:wandermood/core/utils/places_cache_utils.dart';
import '../models/place.dart';

part 'trending_destinations_provider.g.dart';

@riverpod
class TrendingDestinations extends _$TrendingDestinations {
  @override
  Future<List<Place>> build({String? city}) async {
    final cityName = (city ?? ref.watch(locationNotifierProvider).asData?.value)
            ?.trim() ??
        '';
    if (cityName.isEmpty) return [];

    try {
      final places = await PlacesCacheUtils.tryLoadExplorePlaces(
        Supabase.instance.client,
        'trending',
        cityName,
        languageCode: PlacesCacheUtils.effectiveExploreLanguageTag(
          appLocale: ref.watch(localeProvider),
        ),
      );
      if (places == null || places.isEmpty) return [];
      final sorted = List<Place>.from(places)
        ..sort((a, b) => b.rating.compareTo(a.rating));
      return sorted.take(12).toList();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('TrendingDestinations cache read failed: $e\n$st');
      }
      return [];
    }
  }
}
