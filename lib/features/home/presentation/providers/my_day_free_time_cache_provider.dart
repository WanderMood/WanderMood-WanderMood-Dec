import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/core/presentation/providers/language_provider.dart';
import 'package:wandermood/core/utils/places_cache_utils.dart';
import 'package:wandermood/features/location/services/location_service.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/providers/moody_explore_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// My Day "Free time" carousel: prefers Supabase `places_cache` aggregate row, then
/// one `get_explore` call when cache is empty and coordinates are available.
final myDayFreeTimeActivitiesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final city =
      ref.watch(locationNotifierProvider).asData?.value?.trim();
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

  double? lat;
  double? lng;

  final hasNonEmptyPlaces = places != null && places.isNotEmpty;

  if (hasNonEmptyPlaces) {
    // Do not block the carousel on GPS when we already have `places_cache` data.
    final snap = ref.watch(userLocationProvider).asData?.value;
    if (snap != null &&
        (snap.latitude.abs() > 0.0001 || snap.longitude.abs() > 0.0001)) {
      lat = snap.latitude;
      lng = snap.longitude;
    }
  } else {
    try {
      final pos = await ref
          .watch(userLocationProvider.future)
          .timeout(const Duration(seconds: 8));
      if (pos != null &&
          (pos.latitude.abs() > 0.0001 || pos.longitude.abs() > 0.0001)) {
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } on TimeoutException {
      lat = null;
      lng = null;
    } catch (_) {
      lat = null;
      lng = null;
    }

    if (lat == null || lng == null) {
      try {
        final p = await LocationService.getCoordinatesForCity(city);
        lat = p.latitude;
        lng = p.longitude;
      } catch (_) {
        lat = null;
        lng = null;
      }
    }

    if (lat != null &&
        lng != null &&
        (lat.abs() > 0.0001 || lng.abs() > 0.0001)) {
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
    maxItems: 10,
  );
});
