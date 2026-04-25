import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/features/location/services/location_service.dart';
import 'package:wandermood/features/weather/application/enhanced_weather_service.dart';
import 'package:wandermood/features/weather/application/weather_service.dart';
import 'package:wandermood/features/weather/domain/models/weather.dart';
import 'package:wandermood/features/weather/domain/models/weather_forecast.dart';
import 'package:wandermood/features/weather/domain/models/weather_location.dart';

String? _weatherDisplaySettlementFromPlacemarks(List<Placemark> marks) {
  bool isMacro(String value) {
    final t = value.toLowerCase().trim();
    const blocked = {
      'zuid-holland',
      'noord-holland',
      'noord-brabant',
      'gelderland',
      'utrecht',
      'overijssel',
      'groningen',
      'friesland',
      'drenthe',
      'limburg',
      'zeeland',
      'flevoland',
      'the netherlands',
      'netherlands',
      'nederland',
      'holland',
      'europe',
    };
    return blocked.contains(t);
  }

  String? pick(String? raw) {
    final t = raw?.trim();
    if (t == null || t.length < 2) return null;
    if (isMacro(t)) return null;
    return t;
  }

  // Prefer municipality/city-level names over neighborhoods.
  for (final p in marks) {
    final city = pick(p.subAdministrativeArea);
    if (city != null) return city;
  }
  for (final p in marks) {
    final city = pick(p.locality);
    if (city != null) return city;
  }
  for (final p in marks) {
    final city = pick(p.administrativeArea);
    if (city != null) return city;
  }
  return null;
}

/// Resolves coordinates for OpenWeather: prefer GPS ([userLocationProvider]), else geocode city ([locationNotifierProvider]).
Future<WeatherLocation?> _resolveWeatherLocation(Ref ref) async {
  final pos = await ref.watch(userLocationProvider.future);
  final city = ref.watch(locationNotifierProvider).asData?.value?.trim();

  if (pos != null) {
    String label = (city != null && city.isNotEmpty) ? city : '';
    try {
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final detected = _weatherDisplaySettlementFromPlacemarks(marks);
      if (detected != null && detected.isNotEmpty) {
        label = detected;
      }
    } catch (_) {}
    if (label.isEmpty) label = 'Current location';
    return WeatherLocation(
      id:
          '${pos.latitude.toStringAsFixed(4)}_${pos.longitude.toStringAsFixed(4)}',
      name: label,
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
  }

  final fallbackCity =
      (city != null && city.isNotEmpty) ? city : 'Rotterdam';
  try {
    final coordinates =
        await LocationService.getCoordinatesForCity(fallbackCity);
    return WeatherLocation(
      id: fallbackCity.toLowerCase(),
      name: fallbackCity,
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
    );
  } catch (_) {
    return null;
  }
}

const Duration _weatherCacheFreshWindow = Duration(minutes: 30);
const String _weatherCacheDataPrefix = 'home_weather_cache_data_';
const String _weatherCacheTimestampPrefix = 'home_weather_cache_ts_';

class _CachedWeather {
  final Weather weather;
  final DateTime fetchedAt;

  const _CachedWeather({
    required this.weather,
    required this.fetchedAt,
  });
}

/// Provider for current weather data (OpenWeather via [WeatherService]).
final weatherProvider =
    AsyncNotifierProvider<WeatherProviderNotifier, Weather?>(
      WeatherProviderNotifier.new,
    );

class WeatherProviderNotifier extends AsyncNotifier<Weather?> {
  @override
  Future<Weather?> build() async {
    final loc = await _resolveWeatherLocation(ref);
    if (loc == null) return null;

    final cached = await _readCachedWeather(loc);
    if (cached != null) {
      final cacheAge = DateTime.now().difference(cached.fetchedAt);
      final isFresh = cacheAge < _weatherCacheFreshWindow;
      if (kDebugMode) {
        debugPrint(
          '🌦️ Home weather source=cache location=${loc.name} ageMinutes=${cacheAge.inMinutes}',
        );
      }

      if (!isFresh) {
        unawaited(_refreshWeatherInBackground(loc));
      }
      return cached.weather;
    }

    return _fetchAndCacheWeather(loc);
  }

  Future<void> _refreshWeatherInBackground(WeatherLocation loc) async {
    final refreshed = await _fetchAndCacheWeather(loc);
    if (refreshed != null) {
      try {
        state = AsyncData(refreshed);
      } catch (_) {}
    }
  }

  Future<Weather?> _fetchAndCacheWeather(WeatherLocation loc) async {
    final edgeService = ref.read(enhancedWeatherServiceProvider.notifier);
    final fallbackService = ref.read(weatherServiceProvider.notifier);

    try {
      final weather = await edgeService.getCurrentWeather(loc);
      if (kDebugMode) {
        debugPrint('🌦️ Home weather source=edge location=${loc.name}');
      }
      await _writeCachedWeather(loc, weather);
      return weather;
    } catch (_) {
      try {
        final weather = await fallbackService.getCurrentWeather(loc);
        if (kDebugMode) {
          debugPrint(
            '🌦️ Home weather source=fallback-direct location=${loc.name}',
          );
        }
        await _writeCachedWeather(loc, weather);
        return weather;
      } catch (_) {
        return null;
      }
    }
  }

  Future<_CachedWeather?> _readCachedWeather(WeatherLocation loc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cacheKeyForLocation(loc);
      final weatherJson = prefs.getString('$_weatherCacheDataPrefix$key');
      final timestampMs = prefs.getInt('$_weatherCacheTimestampPrefix$key');
      if (weatherJson == null || timestampMs == null) return null;

      final decoded = Weather.fromJson(
        Map<String, dynamic>.from(
          (jsonDecode(weatherJson) as Map).cast<String, dynamic>(),
        ),
      );
      return _CachedWeather(
        weather: decoded,
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(timestampMs),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCachedWeather(WeatherLocation loc, Weather weather) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cacheKeyForLocation(loc);
      await prefs.setString(
        '$_weatherCacheDataPrefix$key',
        jsonEncode(weather.toJson()),
      );
      await prefs.setInt(
        '$_weatherCacheTimestampPrefix$key',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  String _cacheKeyForLocation(WeatherLocation loc) =>
      '${loc.latitude.toStringAsFixed(4)}_${loc.longitude.toStringAsFixed(4)}';
}

/// Hourly-style forecast rows (edge function first, direct API fallback).
final hourlyForecastProvider =
    FutureProvider.autoDispose<List<WeatherForecast>>((ref) async {
  final loc = await _resolveWeatherLocation(ref);
  if (loc == null) return [];

  final edgeService = ref.watch(enhancedWeatherServiceProvider.notifier);
  final fallbackService = ref.watch(weatherServiceProvider.notifier);
  try {
    final forecast = await edgeService.getHourlyForecast(loc);
    if (kDebugMode) {
      debugPrint(
        '🌦️ Home hourly source=edge location=${loc.name} count=${forecast.length}',
      );
    }
    return forecast;
  } catch (_) {
    try {
      final forecast = await fallbackService.getHourlyForecast(loc);
      if (kDebugMode) {
        debugPrint(
          '🌦️ Home hourly source=fallback-direct location=${loc.name} count=${forecast.length}',
        );
      }
      return forecast;
    } catch (_) {
      return [];
    }
  }
});

/// Daily-style forecast rows from [WeatherService.getDailyForecast].
final dailyForecastProvider =
    FutureProvider.autoDispose<List<WeatherForecast>>((ref) async {
  final loc = await _resolveWeatherLocation(ref);
  if (loc == null) return [];

  final service = ref.watch(weatherServiceProvider.notifier);
  try {
    return await service.getDailyForecast(loc);
  } catch (_) {
    return [];
  }
});
