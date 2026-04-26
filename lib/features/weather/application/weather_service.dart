import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/models/weather_forecast.dart';
import '../domain/models/weather_alert.dart';
import '../domain/models/weather_location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'weather_cache_service.dart';
import 'package:wandermood/features/location/providers/location_provider.dart';
import 'package:wandermood/features/location/services/location_service.dart';
import 'package:wandermood/features/weather/domain/models/weather.dart';
import 'package:wandermood/core/config/api_config.dart';

part 'weather_service.g.dart';

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}

@riverpod
class WeatherService extends _$WeatherService {
  final _cacheService = WeatherCacheService();
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  String get _apiKey => ApiConfig.openWeatherMapKey;

  @override
  FutureOr<Weather?> build() async {
    final locationState = ref.watch(locationNotifierProvider);
    
    return locationState.when(
      data: (location) async {
        if (location == null) return null;
        
        try {
          // Get coordinates for the location
          final coordinates = await LocationService.getCoordinatesForCity(location);
          
          final locationData = WeatherLocation(
            id: location.toLowerCase(),
            name: location,
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
          );
          
          return getCurrentWeather(locationData);
        } catch (e) {
          print('Error getting coordinates: $e');
          return null;
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  Future<Weather> getCurrentWeather(WeatherLocation location) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception('OpenWeather API key is not configured');
      }

      print('Getting weather for ${location.name} at ${location.latitude}, ${location.longitude}');
      final url = '$_baseUrl/weather?lat=${location.latitude}&lon=${location.longitude}&appid=$_apiKey&units=metric';
      print('Fetching weather from: $url');
      
      final response = await http.get(Uri.parse(url));
      print('Weather API response code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Weather data received: ${data['main']['temp']}°C, ${data['weather'][0]['main']}');
        return Weather(
          temperature: data['main']['temp'].toDouble(),
          condition: data['weather'][0]['main'],
          humidity: data['main']['humidity'],
          windSpeed: data['wind']['speed'].toDouble(),
          icon: data['weather'][0]['icon'],
          description: data['weather'][0]['description'],
          feelsLike: data['main']['feels_like'].toDouble(),
          minTemp: data['main']['temp_min'].toDouble(),
          maxTemp: data['main']['temp_max'].toDouble(),
          pressure: data['main']['pressure'],
          sunrise: DateTime.fromMillisecondsSinceEpoch(data['sys']['sunrise'] * 1000),
          sunset: DateTime.fromMillisecondsSinceEpoch(data['sys']['sunset'] * 1000),
          location: location,
        );
      } else {
        print('Weather API error: ${response.body}');
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching weather: $e');
      throw Exception('Failed to load weather data: $e');
    }
  }

  // Get hourly forecast for next 24 hours
  Future<List<WeatherForecast>> getHourlyForecast(WeatherLocation location) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception('OpenWeather API key is not configured');
      }

      // Try to load cached forecasts first
      final cachedForecasts = await _cacheService.getCachedForecasts(location);
      if (cachedForecasts != null) {
        return cachedForecasts;
      }

      print('Getting hourly forecast for ${location.name} at ${location.latitude}, ${location.longitude}');
      final url = '$_baseUrl/forecast?lat=${location.latitude}&lon=${location.longitude}&appid=$_apiKey&units=metric';
      print('Fetching forecast from: $url');
      
      final response = await http.get(Uri.parse(url));
      print('Forecast API response code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Extract the 3-hour interval forecasts
        final List<dynamic> threeHourIntervalList = data['list'];
        
        // Get the current time and define the 24-hour range
        final now = DateTime.now();
        final todayMidnight = DateTime(now.year, now.month, now.day);
        final tomorrowMidnight = todayMidnight.add(const Duration(days: 1));
        
        // Create a list for interpolated hourly forecasts
        final List<WeatherForecast> hourlyForecasts = [];
        
        // Get API data points (limited to the next few forecast periods)
        final apiDataPoints = threeHourIntervalList.take(9).map((item) {
          final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          return {
            'date': date,
            'temp': (item['main']['temp'] as num).toDouble(),
            'conditions': item['weather'][0]['main'] as String,
            'icon': item['weather'][0]['icon'] as String,
            'description': item['weather'][0]['description'] as String,
            'pop': item['pop'] != null ? (item['pop'] as num).toDouble() * 100 : 0.0,
            'humidity': (item['main']['humidity'] as num).toDouble(),
            'min_temp': (item['main']['temp_min'] as num).toDouble(),
            'max_temp': (item['main']['temp_max'] as num).toDouble(),
            'precipitation': item['rain'] != null && item['rain']['3h'] != null 
                ? (item['rain']['3h'] as num).toDouble() 
                : 0.0,
          };
        }).toList();
        
        // Generate 24 hourly forecasts starting from the current hour
        for (int i = 0; i < 24; i++) {
          final forecastTime = DateTime(now.year, now.month, now.day, now.hour + i);
          
          // Find surrounding data points from the API
          Map<String, dynamic>? before;
          Map<String, dynamic>? after;
          
          for (int j = 0; j < apiDataPoints.length - 1; j++) {
            final current = apiDataPoints[j];
            final next = apiDataPoints[j + 1];
            
            if (forecastTime.isAfter(current['date'] as DateTime) && forecastTime.isBefore(next['date'] as DateTime)) {
              before = current;
              after = next;
              break;
            } else if (j == 0 && forecastTime.isBefore(current['date'] as DateTime)) {
              // Before the first data point, use the first two
              before = apiDataPoints[0];
              after = apiDataPoints[1];
              break;
            } else if (j == apiDataPoints.length - 2 && forecastTime.isAfter(next['date'] as DateTime)) {
              // After the last data point, use the last two
              before = apiDataPoints[apiDataPoints.length - 2];
              after = apiDataPoints[apiDataPoints.length - 1];
              break;
            }
          }
          
          // If we don't have before/after (unusual case), use first two data points
          if (before == null || after == null) {
            if (apiDataPoints.length >= 2) {
              before = apiDataPoints[0];
              after = apiDataPoints[1]; 
            } else if (apiDataPoints.isNotEmpty) {
              // Only one data point available, use it for everything
              before = after = apiDataPoints[0];
            } else {
              // No data available, skip this hour
              continue;
            }
          }
          
          // Interpolate temperature based on time between data points
          final beforeTime = before['date'] as DateTime;
          final afterTime = after['date'] as DateTime;
          final beforeTemp = before['temp'] as double;
          final afterTemp = after['temp'] as double;
          
          double interpolatedTemp;
          double interpolatedPop;
          double interpolatedHumidity;
          
          if (beforeTime == afterTime) {
            // Same time (edge case), no interpolation needed
            interpolatedTemp = beforeTemp;
            interpolatedPop = before['pop'] as double;
            interpolatedHumidity = before['humidity'] as double;
          } else {
            // Calculate the ratio of time elapsed
            final totalDuration = afterTime.difference(beforeTime).inMinutes;
            final elapsedDuration = forecastTime.difference(beforeTime).inMinutes;
            final ratio = totalDuration > 0 ? elapsedDuration / totalDuration : 0.0;
            
            // Linear interpolation: value = start + ratio * (end - start)
            interpolatedTemp = beforeTemp + ratio * (afterTemp - beforeTemp);
            interpolatedPop = (before['pop'] as double) + ratio * ((after['pop'] as double) - (before['pop'] as double));
            interpolatedHumidity = (before['humidity'] as double) + ratio * ((after['humidity'] as double) - (before['humidity'] as double));
          }
          
          // Format the hour string
          final hour = forecastTime.hour;
          final formattedHour = hour == 0 ? '12 AM' : hour == 12 ? '12 PM' : hour > 12 ? '${hour - 12} PM' : '$hour AM';
          
          // Use the weather condition from the closest data point
          final beforeDiff = (forecastTime.difference(beforeTime).inMinutes).abs();
          final afterDiff = (forecastTime.difference(afterTime).inMinutes).abs();
          final closestPoint = beforeDiff <= afterDiff ? before : after;
          
          hourlyForecasts.add(WeatherForecast(
            time: formattedHour,
            date: forecastTime,
            temperature: interpolatedTemp,
            conditions: closestPoint['conditions'] as String,
            icon: closestPoint['icon'] as String,
            description: closestPoint['description'] as String,
            precipitationProbability: interpolatedPop,
            humidity: interpolatedHumidity,
            maxTemperature: (closestPoint['max_temp'] as double),
            minTemperature: (closestPoint['min_temp'] as double),
            precipitation: (closestPoint['precipitation'] as double),
            sunrise: DateTime.now(),
            sunset: DateTime.now(),
            uvIndex: 0,
          ));
        }
        
        // Cache the forecasts
        await _cacheService.cacheForecasts(location, hourlyForecasts);
        
        print('Generated ${hourlyForecasts.length} hourly forecasts');
        return hourlyForecasts;
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to load weather forecast: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching hourly forecasts: $e');
      return [];
    }
  }

  // Get daily forecast for next days (up to 7, depending on API horizon)
  Future<List<WeatherForecast>> getDailyForecast(WeatherLocation location) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception('OpenWeather API key is not configured');
      }

      print('Getting daily forecast for ${location.name} at ${location.latitude}, ${location.longitude}');
      
      // For daily forecasts, we need to use a different endpoint
      final url = 'https://api.openweathermap.org/data/2.5/forecast/daily?lat=${location.latitude}&lon=${location.longitude}&cnt=7&appid=$_apiKey&units=metric';
      
      // Since free API doesn't have daily endpoint, we'll use the standard forecast and aggregate by day
      final hourlyUrl = '$_baseUrl/forecast?lat=${location.latitude}&lon=${location.longitude}&appid=$_apiKey&units=metric';
      print('Fetching daily forecast from: $hourlyUrl');
      
      final response = await http.get(Uri.parse(hourlyUrl));
      print('Daily forecast API response code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Extract the hourly forecasts list
        final List<dynamic> hourlyList = data['list'];
        
        // Group forecasts by day (DateTime keys avoid string parse/sort issues).
        final Map<DateTime, List<dynamic>> forecastsByDay = {};
        
        for (var item in hourlyList) {
          final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final dateKey = DateTime(date.year, date.month, date.day);
          
          if (!forecastsByDay.containsKey(dateKey)) {
            forecastsByDay[dateKey] = [];
          }
          
          forecastsByDay[dateKey]!.add(item);
        }
        
        // Create daily forecasts (excluding today)
        final List<WeatherForecast> dailyForecasts = [];
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        // Sort days
        final sortedDays = forecastsByDay.keys.toList()..sort();
        
        // Skip today and take the next available days (target up to 7).
        for (final day in sortedDays.where((d) => d != today).take(7)) {
          final forecasts = forecastsByDay[day]!;
          
          // Calculate max and min temperatures for the day
          double maxTemp = -100;
          double minTemp = 100;
          String mostCommonCondition = '';
          Map<String, int> conditionCounts = {};
          String mostCommonIcon = '';
          
          for (final item in forecasts) {
            final temp = item['main']['temp'].toDouble();
            if (temp > maxTemp) maxTemp = temp;
            if (temp < minTemp) minTemp = temp;
            
            final condition = item['weather'][0]['main'];
            conditionCounts[condition] = (conditionCounts[condition] ?? 0) + 1;
            
            if (mostCommonCondition.isEmpty || 
                (conditionCounts[condition] ?? 0) > (conditionCounts[mostCommonCondition] ?? 0)) {
              mostCommonCondition = condition;
              mostCommonIcon = item['weather'][0]['icon'];
            }
          }
          
          // Create forecast for this day.
          final dayOfWeek = _getDayOfWeek(day.weekday);
          
          dailyForecasts.add(WeatherForecast(
            date: day,
            maxTemperature: maxTemp,
            minTemperature: minTemp,
            time: dayOfWeek,
            conditions: mostCommonCondition,
            icon: mostCommonIcon,
            precipitationProbability: forecasts.fold(0.0, (sum, item) => sum + (item['pop'] * 100)) / forecasts.length,
            humidity: forecasts.fold(0.0, (sum, item) => sum + item['main']['humidity']) / forecasts.length,
            sunrise: DateTime.now(),
            sunset: DateTime.now(),
          ));
        }
        
        return dailyForecasts;
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to load daily forecast: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching daily forecasts: $e');
      return [];
    }
  }

  String _getDayOfWeek(int day) {
    switch (day) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  Future<List<WeatherAlert>> getWeatherAlerts(WeatherLocation location) async {
    // Alerts are not available in the free API
    return [];
  }

  Future<void> clearCache() async {
    await _cacheService.clearCache();
  }
} 