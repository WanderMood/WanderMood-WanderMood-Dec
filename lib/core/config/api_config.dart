import 'package:flutter/foundation.dart';
import '../constants/api_keys.dart';

class ApiConfig {
  // Get a free API key from: https://home.openweathermap.org/api_keys
  // Uses environment variables for security
  static String get openWeatherMapKey => ApiKeys.openWeather;
  static const String openWeatherMapBaseUrl = 'https://api.openweathermap.org/data/2.5';
  
  // Weather API endpoints
  static String currentWeatherEndpoint(double lat, double lon) => 
    '$openWeatherMapBaseUrl/weather?lat=$lat&lon=$lon&appid=$openWeatherMapKey&units=metric';
  
  static String forecastEndpoint(double lat, double lon) => 
    '$openWeatherMapBaseUrl/forecast?lat=$lat&lon=$lon&appid=$openWeatherMapKey&units=metric';
    
  static String oneCallEndpoint(double lat, double lon) =>
    'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&appid=$openWeatherMapKey&units=metric&exclude=minutely';

  // 🚨 GLOBAL API KILL SWITCH - Set to false to disable ALL Google Places API calls
  static const bool enableGooglePlacesApi = true; // ✅ ENABLED FOR NEW PLACES API
  
  // 💰 COST MONITORING
  static const double maxDailyCost = 10.0; // Maximum daily cost in USD
  static const Map<String, double> apiCosts = {
    'nearby_search': 0.032,      // Per request
    'text_search': 0.032,        // Per request
    'place_details': 0.017,      // Per request
    'place_photo': 0.007,        // Per request
    'geocoding': 0.005,          // Per request
  };
  
  // 📊 USAGE LIMITS
  static const int maxDailyRequests = 100;
  static const int maxRequestsPerMinute = 5;
  
  // 🔄 CACHE SETTINGS
  static const Duration cacheValidDuration = Duration(days: 7);
  static const bool enablePersistentCache = true;
  static const bool enableOfflineMode = false; // ✅ DISABLED for real API usage
  
  // 📍 FALLBACK SETTINGS
  static const bool useFallbackData = true;
  static const bool enableMockData = true;
  
  // 🛡️ SAFETY CHECKS
  static bool get shouldUseApi => enableGooglePlacesApi && !enableOfflineMode;
  static bool get shouldUseFallbacks => !enableGooglePlacesApi || enableOfflineMode;
  
  // 💡 DEVELOPER MODES
  static const bool enableDebugLogs = true;
  static const bool enableApiCostTracking = true;
  
  // 🔧 DEV MODE: Use Supabase cache instead of live API calls (saves costs)
  // Set to true to use cached data only, false to use live API calls
  // In dev mode, if cache is missing, returns empty results instead of making API calls
  static const bool useDevModeCache = kDebugMode; // Automatically true in debug builds
  
  // ⚠️ ERROR HANDLING
  static const Duration apiTimeout = Duration(seconds: 5);
  static const int maxRetryAttempts = 0; // No retries to prevent cost escalation
} 