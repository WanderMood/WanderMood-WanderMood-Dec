import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/features/location/services/location_service.dart';
import 'package:wandermood/features/weather/application/enhanced_weather_service.dart';
import 'package:wandermood/features/weather/application/weather_service.dart';
import 'package:wandermood/features/weather/domain/models/weather.dart';
import 'package:wandermood/features/weather/domain/models/weather_forecast.dart';
import 'package:wandermood/features/weather/domain/models/weather_location.dart';

/// Resolves coordinates for OpenWeather: prefer GPS ([userLocationProvider]), else geocode city ([locationNotifierProvider]).
Future<WeatherLocation?> _resolveWeatherLocation(Ref ref) async {
  final pos = await ref.watch(userLocationProvider.future);
  final city = ref.watch(locationNotifierProvider).asData?.value?.trim();

  if (pos != null) {
    String label = (city != null && city.isNotEmpty) ? city : '';
    if (label.isEmpty || label.toLowerCase() == 'rotterdam') {
      try {
        final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        final detected = marks.isNotEmpty
            ? (marks.first.locality ??
                marks.first.subAdministrativeArea ??
                marks.first.administrativeArea ??
                '')
            : '';
        if (detected.trim().isNotEmpty) {
          label = detected.trim();
        }
      } catch (_) {}
    }
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

/// Provider for current weather data (OpenWeather via [WeatherService]).
final weatherProvider = FutureProvider.autoDispose<Weather?>((ref) async {
  final loc = await _resolveWeatherLocation(ref);
  if (loc == null) return null;

  final edgeService = ref.watch(enhancedWeatherServiceProvider.notifier);
  final fallbackService = ref.watch(weatherServiceProvider.notifier);
  try {
    final weather = await edgeService.getCurrentWeather(loc);
    if (kDebugMode) {
      debugPrint('🌦️ Home weather source=edge location=${loc.name}');
    }
    return weather;
  } catch (_) {
    try {
      final weather = await fallbackService.getCurrentWeather(loc);
      if (kDebugMode) {
        debugPrint('🌦️ Home weather source=fallback-direct location=${loc.name}');
      }
      return weather;
    } catch (_) {
      return null;
    }
  }
});

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
