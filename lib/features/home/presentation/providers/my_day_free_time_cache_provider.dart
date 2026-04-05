import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/core/presentation/providers/language_provider.dart';
import 'package:wandermood/core/utils/places_cache_utils.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/providers/moody_explore_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// My Day "Free time" carousel: prefers Supabase `places_cache` aggregate row, then
/// one `get_explore` call when cache is empty and coordinates are available.
final myDayFreeTimeActivitiesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final city = ref.watch(locationNotifierProvider).value?.trim();
  if (city == null || city.isEmpty) return [];

  final langTag = PlacesCacheUtils.effectiveExploreLanguageTag(
    appLocale: ref.watch(localeProvider),
  );

  List<Place>? places = await PlacesCacheUtils.tryLoadExplorePlaces(
    Supabase.instance.client,
    'discovery',
    city,
    languageCode: langTag,
  );

  final pos = await ref.watch(userLocationProvider.future);
  final lat = pos?.latitude;
  final lng = pos?.longitude;
  final hasCoords = lat != null &&
      lng != null &&
      (lat.abs() > 0.0001 || lng.abs() > 0.0001);

  if ((places == null || places.isEmpty) && hasCoords) {
    try {
      final service = ref.read(moodyEdgeFunctionServiceProvider);
      places = await service.getExplore(
        location: city,
        latitude: lat,
        longitude: lng,
        section: 'discovery',
        languageCode: langTag,
      );
    } catch (_) {
      places = null;
    }
  }

  if (places == null || places.isEmpty) return [];

  final appLocale = ref.watch(localeProvider);
  final effectiveLocale = appLocale ?? ui.PlatformDispatcher.instance.locale;
  AppLocalizations l10n;
  try {
    l10n = lookupAppLocalizations(effectiveLocale);
  } catch (_) {
    try {
      l10n = lookupAppLocalizations(Locale(effectiveLocale.languageCode));
    } catch (_) {
      l10n = lookupAppLocalizations(const Locale('en'));
    }
  }

  return PlacesCacheUtils.toMyDayFreeTimeCarouselMaps(
    places,
    l10n: l10n,
    userLat: lat,
    userLng: lng,
    maxItems: 36,
  );
});
