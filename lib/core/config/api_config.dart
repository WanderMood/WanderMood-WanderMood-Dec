class ApiConfig {
  // Get a free API key from: https://home.openweathermap.org/api_keys
  static const String openWeatherMapKey = 'e7f5d9e5c6c9c0c6c9c0c6c9c0c6c9c0'; // New API key
  static const String openWeatherMapBaseUrl = 'https://api.openweathermap.org/data/2.5';
  
  // Weather API endpoints
  static String currentWeatherEndpoint(double lat, double lon) => 
    '$openWeatherMapBaseUrl/weather?lat=$lat&lon=$lon&appid=$openWeatherMapKey&units=metric';
  
  static String forecastEndpoint(double lat, double lon) => 
    '$openWeatherMapBaseUrl/forecast?lat=$lat&lon=$lon&appid=$openWeatherMapKey&units=metric';
    
  static String oneCallEndpoint(double lat, double lon) =>
    'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&appid=$openWeatherMapKey&units=metric&exclude=minutely';

  // 🚨 GLOBAL API KILL SWITCH - Set to false to disable ALL Google Places API calls
  static const bool enableGooglePlacesApi = false;
  
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
  static const bool enableOfflineMode = true;
  
  // 📍 FALLBACK SETTINGS
  static const bool useFallbackData = true;
  static const bool enableMockData = true;
  
  // 🛡️ SAFETY CHECKS
  static bool get shouldUseApi => enableGooglePlacesApi && !enableOfflineMode;
  static bool get shouldUseFallbacks => !enableGooglePlacesApi || enableOfflineMode;
  
  // 💡 DEVELOPER MODES
  static const bool enableDebugLogs = true;
  static const bool enableApiCostTracking = true;
  
  // ⚠️ ERROR HANDLING
  static const Duration apiTimeout = Duration(seconds: 5);
  static const int maxRetryAttempts = 0; // No retries to prevent cost escalation
} 