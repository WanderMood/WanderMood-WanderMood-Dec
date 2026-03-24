import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/constants/api_keys.dart';
import 'package:flutter/foundation.dart';

// Weather data model
class WeatherData {
  final String location;
  final double temperature;
  final String condition;
  final String iconUrl;
  final Map<String, dynamic> details;
  final double? latitude;
  final double? longitude;

  WeatherData({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.iconUrl,
    required this.details,
    this.latitude,
    this.longitude,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json, String location) {
    return WeatherData(
      location: location,
      temperature: json['current']['temp_c'],
      condition: json['current']['condition']['text'],
      iconUrl: 'https:${json['current']['condition']['icon']}',
      details: {
        'feelsLike': json['current']['feelslike_c'],
        'humidity': json['current']['humidity'],
        'windSpeed': json['current']['wind_kph'],
        'uv': json['current']['uv'],
        'precip': json['current']['precip_mm'],
      },
    );
  }

  factory WeatherData.fromOpenWeatherMap(Map<String, dynamic> json, String location) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final coord = json['coord'] as Map<String, dynamic>?;
    final sys = json['sys'] as Map<String, dynamic>?;
    
    return WeatherData(
      location: location,
      temperature: (main['temp'] as num).toDouble(),
      condition: weather['main'],
      iconUrl: 'https://openweathermap.org/img/wn/${weather['icon']}@2x.png',
      details: {
        'feelsLike': main['feels_like'],
        'humidity': main['humidity'],
        'windSpeed': json['wind']['speed'],
        'pressure': main['pressure'],
        'description': weather['description'],
        'temp_min': main['temp_min'],
        'temp_max': main['temp_max'],
        'sunrise': sys?['sunrise'],
        'sunset': sys?['sunset'],
      },
      latitude: coord?['lat']?.toDouble(),
      longitude: coord?['lon']?.toDouble(),
    );
  }
}

// Mock weather data for demo purposes
WeatherData getMockWeatherData(String location) {
  return WeatherData(
    location: location,
    temperature: 22,
    condition: 'Clear',
    iconUrl: 'https://openweathermap.org/img/wn/01d@2x.png',
    details: {
      'feelsLike': 23,
      'humidity': 65,
      'windSpeed': 5.2,
      'pressure': 1013,
      'description': 'clear sky',
      'temp_min': 20,
      'temp_max': 24,
      'sunrise': DateTime.now().add(const Duration(hours: -6)).millisecondsSinceEpoch,
      'sunset': DateTime.now().add(const Duration(hours: 6)).millisecondsSinceEpoch,
    },
    latitude: 52.3676,
    longitude: 4.9041,
  );
}

// Weather provider that depends on location
final weatherProvider = FutureProvider.autoDispose<WeatherData?>((ref) async {
  final locationState = await ref.watch(locationNotifierProvider.future);
  if (locationState == null) return null;
  
  // Get API key from ApiKeys (--dart-define or compile-time default for release).
  String apiKey = '';
  try {
    apiKey = ApiKeys.openWeather;
  } catch (_) {
    apiKey = '';
  }
  debugPrint('🌤️ Weather API Key: ${apiKey.isEmpty ? 'EMPTY' : 'EXISTS (${apiKey.length} chars)'}');
  debugPrint('🌤️ Weather location: $locationState');
  
  // Use real API if key is available
  if (apiKey.isNotEmpty) {
    try {
      final url = 'https://api.openweathermap.org/data/2.5/weather?q=$locationState&appid=$apiKey&units=metric';
      debugPrint('🌤️ Weather URL: $url');
      
      final response = await http.get(Uri.parse(url));
      debugPrint('🌤️ Weather API response code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('🌤️ Weather API response: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
        return WeatherData.fromOpenWeatherMap(data, locationState);
      } else {
        debugPrint('🌤️ Weather API error: ${response.body}');
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data if API fails
      debugPrint('🌤️ Weather API exception: $e');
      return getMockWeatherData(locationState);
    }
  } else {
    // Use mock data if no valid API key
    debugPrint('🌤️ Using mock data: No valid API key');
    return getMockWeatherData(locationState);
  }
}); 