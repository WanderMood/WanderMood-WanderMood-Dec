import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wandermood/features/weather/application/weather_service.dart';
import 'package:wandermood/features/weather/domain/models/weather_forecast.dart';
import 'package:wandermood/features/location/providers/location_provider.dart';
import 'package:wandermood/features/location/services/location_service.dart';
import 'package:wandermood/features/weather/domain/models/weather_location.dart';

part 'weather_forecast_provider.g.dart';

// Provider for hourly forecasts (24 hours)
@riverpod
Future<List<WeatherForecast>> hourlyForecast(HourlyForecastRef ref) async {
  final locationState = await ref.watch(locationNotifierProvider.future);
  final weatherService = ref.watch(weatherServiceProvider.notifier);
  
  if (locationState == null) return [];
  
  try {
    // Get coordinates for the location
    final coordinates = await LocationService.getCoordinatesForCity(locationState);
    
    final locationData = WeatherLocation(
      id: locationState.toLowerCase(),
      name: locationState,
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
    );
    
    return await weatherService.getHourlyForecast(locationData);
  } catch (e) {
    print('Error getting hourly forecast: $e');
    return [];
  }
}

// Provider for daily forecasts (up to 7 days; API may return fewer)
@riverpod
Future<List<WeatherForecast>> dailyForecast(DailyForecastRef ref) async {
  final locationState = await ref.watch(locationNotifierProvider.future);
  final weatherService = ref.watch(weatherServiceProvider.notifier);
  
  if (locationState == null) return [];
  
  try {
    // Get coordinates for the location
    final coordinates = await LocationService.getCoordinatesForCity(locationState);
    
    final locationData = WeatherLocation(
      id: locationState.toLowerCase(),
      name: locationState,
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
    );
    
    return await weatherService.getDailyForecast(locationData);
  } catch (e) {
    print('Error getting daily forecast: $e');
    return [];
  }
} 