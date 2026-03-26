import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/features/location/services/location_service.dart';
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

  final service = ref.watch(weatherServiceProvider.notifier);
  try {
    return await service.getCurrentWeather(loc);
  } catch (_) {
    return null;
  }
});

/// Hourly-style forecast rows from [WeatherService.getHourlyForecast].
final hourlyForecastProvider =
    FutureProvider.autoDispose<List<WeatherForecast>>((ref) async {
  final loc = await _resolveWeatherLocation(ref);
  if (loc == null) return [];

  final service = ref.watch(weatherServiceProvider.notifier);
  try {
    return await service.getHourlyForecast(loc);
  } catch (_) {
    return [];
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
