import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/weather/domain/models/weather.dart';
import '../../../features/weather/application/weather_service.dart';
import '../../../features/location/providers/location_provider.dart';

/// Provider for current weather data
final weatherProvider = FutureProvider.autoDispose<Weather?>((ref) async {
  final location = await ref.watch(currentLocationProvider.future);
  if (location == null) return null;
  
  final weatherService = ref.watch(weatherServiceProvider);
  return await weatherService.getCurrentWeather(location);
});

/// Provider for hourly forecast
final hourlyForecastProvider = FutureProvider.autoDispose<List<Weather>>((ref) async {
  final location = await ref.watch(currentLocationProvider.future);
  if (location == null) return [];
  
  final weatherService = ref.watch(weatherServiceProvider);
  return await weatherService.getHourlyForecast(location);
});

/// Provider for daily forecast
final dailyForecastProvider = FutureProvider.autoDispose<List<Weather>>((ref) async {
  final location = await ref.watch(currentLocationProvider.future);
  if (location == null) return [];
  
  final weatherService = ref.watch(weatherServiceProvider);
  return await weatherService.getDailyForecast(location);
}); 