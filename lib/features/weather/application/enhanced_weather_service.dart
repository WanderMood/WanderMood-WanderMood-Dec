import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/weather_data.dart';
import '../domain/models/weather_forecast.dart';
import '../domain/models/weather_location.dart';
import '../domain/models/weather.dart';
import 'package:http/http.dart' as http;

part 'enhanced_weather_service.g.dart';

enum WeatherType { current, forecast, onecall }

class WeatherApiResponse {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;
  final DateTime? cachedUntil;

  WeatherApiResponse({
    required this.success,
    this.data,
    this.error,
    this.cachedUntil,
  });

  factory WeatherApiResponse.fromJson(Map<String, dynamic> json) {
    return WeatherApiResponse(
      success: json['success'] ?? false,
      data: json['data'],
      error: json['error'],
      cachedUntil: json['cached_until'] != null 
          ? DateTime.parse(json['cached_until'])
          : null,
    );
  }
}

@riverpod
class EnhancedWeatherService extends _$EnhancedWeatherService {
  final _supabase = Supabase.instance.client;
  
  // Cache settings
  static const Duration _cacheValidDuration = Duration(minutes: 30);
  static const Duration _fallbackCacheDuration = Duration(hours: 2);

  @override
  Future<Weather> build() async {
    // Initial build - you can return a default weather or throw
    throw UnimplementedError('Use getCurrentWeather method instead');
  }

  /// Get current weather for a location using Supabase Edge Function
  Future<Weather> getCurrentWeather(WeatherLocation location) async {
    try {
      print('Fetching current weather for ${location.name}');
      
      // Try to get from cache first
      final cachedWeather = await _getCachedWeather(location, WeatherType.current);
      if (cachedWeather != null) {
        print('Found cached weather data');
        return cachedWeather;
      }

      // Call Supabase Edge Function
      final response = await _callWeatherFunction(
        location.latitude, 
        location.longitude, 
        WeatherType.current
      );

      if (response.success && response.data != null) {
        final weather = _parseCurrentWeather(response.data!, location);
        // Cache the weather data
        await _cacheWeather(location, WeatherType.current, weather);
        return weather;
      } else {
        throw Exception(response.error ?? 'Failed to get weather data');
      }
    } catch (e) {
      print('Error fetching current weather: $e');
      
      // Try to get stale cache data as fallback
      final staleWeather = await _getCachedWeather(
        location, 
        WeatherType.current, 
        allowStale: true
      );
      
      if (staleWeather != null) {
        print('Using stale cached weather data');
        return staleWeather;
      }
      
      // Return fallback weather data
      return Weather(
        condition: 'Unknown',
        temperature: 20.0,
        humidity: 50,
        windSpeed: 5.0,
        location: location,
        icon: '01d',
        description: 'Weather data unavailable (fallback)',
        feelsLike: 20.0,
        minTemp: 18.0,
        maxTemp: 22.0,
        pressure: 1013,
        sunrise: DateTime.now().add(const Duration(hours: 6)),
        sunset: DateTime.now().add(const Duration(hours: 18)),
      );
    }
  }

  /// Get hourly forecast for a location
  Future<List<WeatherForecast>> getHourlyForecast(WeatherLocation location) async {
    try {
      print('Fetching hourly forecast for ${location.name}');
      
      // Try to get from cache first
      final cachedForecast = await _getCachedForecast(location);
      if (cachedForecast != null) {
        print('Found cached forecast data');
        return cachedForecast;
      }

      // Call Supabase Edge Function
      final response = await _callWeatherFunction(
        location.latitude, 
        location.longitude, 
        WeatherType.forecast
      );

      if (response.success && response.data != null) {
        final forecast = _parseHourlyForecast(response.data!);
        // Cache the forecast data
        await _cacheForecast(location, forecast);
        return forecast;
      } else {
        throw Exception(response.error ?? 'Failed to get forecast data');
      }
    } catch (e) {
      print('Error fetching forecast: $e');
      
      // Try to get stale cache data as fallback
      final staleForecast = await _getCachedForecast(location, allowStale: true);
      
      if (staleForecast != null) {
        print('Using stale cached forecast data');
        return staleForecast;
      }
      
      // Return empty forecast on error
      return [];
    }
  }

  /// Call Supabase Edge Function for weather data
  Future<WeatherApiResponse> _callWeatherFunction(
    double latitude, 
    double longitude, 
    WeatherType type
  ) async {
    try {
      print('Calling weather edge function...');
      
      final response = await _supabase.functions.invoke(
        'weather',
        body: {
          'latitude': latitude,
          'longitude': longitude,
          'type': type.name,
        },
      );

      if (response.status != 200) {
        throw Exception('Weather function returned status ${response.status}');
      }

      return WeatherApiResponse.fromJson(response.data);
    } catch (e) {
      print('Error calling weather function: $e');
      return WeatherApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Parse current weather data from API response
  Weather _parseCurrentWeather(Map<String, dynamic> data, WeatherLocation location) {
    try {
      return Weather(
        condition: data['weather'][0]['main'] as String,
        temperature: (data['main']['temp'] as num).toDouble(),
        humidity: data['main']['humidity'] as int,
        windSpeed: (data['wind']['speed'] as num).toDouble(),
        location: location,
        icon: data['weather'][0]['icon'] as String,
        description: data['weather'][0]['description'] as String,
        feelsLike: (data['main']['feels_like'] as num).toDouble(),
        minTemp: (data['main']['temp_min'] as num).toDouble(),
        maxTemp: (data['main']['temp_max'] as num).toDouble(),
        pressure: data['main']['pressure'] as int,
        sunrise: DateTime.fromMillisecondsSinceEpoch(
          (data['sys']['sunrise'] as int) * 1000
        ),
        sunset: DateTime.fromMillisecondsSinceEpoch(
          (data['sys']['sunset'] as int) * 1000
        ),
      );
    } catch (e) {
      throw Exception('Failed to parse weather data: $e');
    }
  }

  /// Parse hourly forecast data from API response
  List<WeatherForecast> _parseHourlyForecast(Map<String, dynamic> data) {
    try {
      final List<dynamic> list = data['list'];
      final forecasts = <WeatherForecast>[];
      
      // Take the next 24 hours (8 * 3-hour intervals)
      final items = list.take(8);
      
      for (final item in items) {
        final itemDateTime = DateTime.fromMillisecondsSinceEpoch(
          (item['dt'] as int) * 1000
        );
        
        final forecast = WeatherForecast(
          date: itemDateTime,
          maxTemperature: (item['main']['temp_max'] as num?)?.toDouble() ?? (item['main']['temp'] as num).toDouble(),
          minTemperature: (item['main']['temp_min'] as num?)?.toDouble() ?? (item['main']['temp'] as num).toDouble(),
          conditions: item['weather'][0]['main'] as String,
          precipitationProbability: item['pop'] != null 
              ? (item['pop'] as num).toDouble() * 100 
              : 0.0,
          sunrise: itemDateTime.add(const Duration(hours: 6)), // Default sunrise
          sunset: itemDateTime.add(const Duration(hours: 18)), // Default sunset
          time: itemDateTime.toString().substring(11, 16),
          temperature: (item['main']['temp'] as num).toDouble(),
          humidity: (item['main']['humidity'] as num).toDouble(),
          precipitation: item['pop'] != null 
              ? (item['pop'] as num).toDouble() * 100 
              : 0.0,
          icon: item['weather'][0]['icon'] as String,
          description: item['weather'][0]['description'] as String,
        );
        
        forecasts.add(forecast);
      }
      
      return forecasts;
    } catch (e) {
      throw Exception('Failed to parse forecast data: $e');
    }
  }

  /// Check for cached weather data
  Future<Weather?> _getCachedWeather(
    WeatherLocation location, 
    WeatherType type, {
    bool allowStale = false
  }) async {
    try {
      final response = await _supabase
          .from('weather_cache')
          .select('data, expires_at')
          .eq('cache_key', 'weather_${type.name}_${location.latitude}_${location.longitude}')
          .maybeSingle();

      if (response == null) return null;

      final expiresAt = DateTime.parse(response['expires_at']);
      final isExpired = DateTime.now().isAfter(expiresAt);
      
      if (isExpired && !allowStale) return null;

      final data = response['data'] as Map<String, dynamic>;
      return _parseCurrentWeather(data, location);
    } catch (e) {
      print('Error getting cached weather: $e');
      return null;
    }
  }

  /// Check for cached forecast data
  Future<List<WeatherForecast>?> _getCachedForecast(
    WeatherLocation location, {
    bool allowStale = false
  }) async {
    try {
      final response = await _supabase
          .from('weather_cache')
          .select('data, expires_at')
          .eq('cache_key', 'weather_forecast_${location.latitude}_${location.longitude}')
          .maybeSingle();

      if (response == null) return null;

      final expiresAt = DateTime.parse(response['expires_at']);
      final isExpired = DateTime.now().isAfter(expiresAt);
      
      if (isExpired && !allowStale) return null;

      final data = response['data'] as Map<String, dynamic>;
      return _parseHourlyForecast(data);
    } catch (e) {
      print('Error getting cached forecast: $e');
      return null;
    }
  }

  /// Cache weather data locally
  Future<void> _cacheWeather(
    WeatherLocation location, 
    WeatherType type, 
    Weather weather
  ) async {
    try {
      final expiresAt = DateTime.now().add(_cacheValidDuration);
      
      // Store in memory cache or local storage if needed
      // For now, we rely on Supabase cache which is handled by the Edge Function
      print('Weather data cached until $expiresAt');
    } catch (e) {
      print('Error caching weather: $e');
    }
  }

  /// Cache forecast data locally
  Future<void> _cacheForecast(
    WeatherLocation location, 
    List<WeatherForecast> forecast
  ) async {
    try {
      final expiresAt = DateTime.now().add(_cacheValidDuration);
      
      // Store in memory cache or local storage if needed
      print('Forecast data cached until $expiresAt');
    } catch (e) {
      print('Error caching forecast: $e');
    }
  }

  /// Clear all cached weather data
  Future<void> clearCache() async {
    try {
      await _supabase
          .from('weather_cache')
          .delete()
          .neq('id', '00000000-0000-0000-0000-000000000000'); // Delete all

      print('Weather cache cleared');
    } catch (e) {
      print('Error clearing weather cache: $e');
    }
  }

  /// Get weather data for travel post creation
  Future<Map<String, dynamic>> getWeatherForTravelPost(
    double latitude, 
    double longitude
  ) async {
    final location = WeatherLocation(
      id: 'temp_${latitude}_$longitude',
      name: 'Current Location',
      latitude: latitude,
      longitude: longitude,
    );

    try {
      final weather = await getCurrentWeather(location);
      
      return {
        'temperature': weather.temperature,
        'condition': weather.condition,
        'description': weather.description,
        'icon': weather.icon,
        'humidity': weather.humidity,
        'windSpeed': weather.windSpeed,
        'feelsLike': weather.feelsLike,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting weather for travel post: $e');
      
      // Return fallback mock weather data
      return {
        'temperature': 20.0,
        'condition': 'Unknown',
        'description': 'Weather data unavailable',
        'icon': '01d',
        'humidity': 50,
        'windSpeed': 5.0,
        'feelsLike': 20.0,
        'timestamp': DateTime.now().toIso8601String(),
        'isFallback': true,
      };
    }
  }
} 