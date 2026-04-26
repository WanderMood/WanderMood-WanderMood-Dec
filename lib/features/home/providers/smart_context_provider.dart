import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/context_manager.dart';
import '../../weather/domain/models/weather.dart';
import '../../weather/domain/models/weather_location.dart';
import '../../mood/providers/current_mood_provider.dart';
import '../../weather/providers/weather_provider.dart';
import '../../location/providers/location_provider.dart';

/// Provider for smart context that combines mood, weather, and time
final smartContextProvider = Provider<SmartContext>((ref) {
  // Get current mood from mood provider
  final mood = ref.watch(currentMoodProvider);
  
  // Get current weather from provider and convert to Weather model
  final weatherData = ref.watch(weatherProvider).value;
  final weather = weatherData != null ? Weather(
    condition: weatherData.condition,
    temperature: weatherData.temperature,
    humidity: weatherData.details['humidity'] ?? 0,
    windSpeed: weatherData.details['windSpeed'] ?? 0.0,
    location: WeatherLocation(
      id: 'current_location',
      name: weatherData.location,
      latitude: 0.0,  // These could be added to WeatherData if needed
      longitude: 0.0,
    ),
    icon: weatherData.iconUrl,
    description: weatherData.details['description'],
    feelsLike: weatherData.details['feelsLike']?.toDouble(),
    minTemp: weatherData.details['temp_min']?.toDouble(),
    maxTemp: weatherData.details['temp_max']?.toDouble(),
    pressure: weatherData.details['pressure'],
    sunrise: null,  // These could be added to WeatherData if needed
    sunset: null,
  ) : null;
  
  // Get current location
  final location = ref.watch(locationNotifierProvider).value;
  
  // Create smart context
  return ContextManager.createSmartContext(
    userMood: mood,
    weather: weather,
    userLocation: location,
  );
});

/// Provider for contextual recommendations text
final contextualRecommendationsProvider = Provider<String>((ref) {
  final context = ref.watch(smartContextProvider);
  return context.getContextSummary();
});

/// Provider to check if context data is available
final hasContextDataProvider = Provider<bool>((ref) {
  final mood = ref.watch(currentMoodProvider);
  final weather = ref.watch(weatherProvider).value;
  
  return mood != null || weather != null;
});

/// Provider for context-aware activity suggestions
final contextualSuggestionsProvider = Provider<List<String>>((ref) {
  final context = ref.watch(smartContextProvider);
  return context.recommendations;
});

/// Provider for weather-aware indoor/outdoor preference
final weatherRecommendationProvider = Provider<String>((ref) {
  final context = ref.watch(smartContextProvider);
  return context.weatherContext.recommendation;
}); 