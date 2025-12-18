import '../constants/api_keys.dart' as constants;

/// Legacy wrapper for ApiKeys - delegates to constants/api_keys.dart
/// This file exists for backward compatibility
class ApiKeys {
  /// Google Places API Key (delegates to constants)
  static String get googlePlacesKey => constants.ApiKeys.googlePlacesKey;
  
  /// OpenAI API Key (delegates to constants)
  static String get openAiKey => constants.ApiKeys.openAiKey;
  
  /// OpenWeather API Key (delegates to constants)
  static String get openWeather => constants.ApiKeys.openWeather;
  
  /// Supabase URL (delegates to constants)
  static String get supabaseUrl => constants.ApiKeys.supabaseUrl;
  
  /// Supabase Anonymous Key (delegates to constants)
  static String get supabaseAnonKey => constants.ApiKeys.supabaseAnonKey;
  
  /// Legacy method name - delegates to googlePlacesKey
  static String get googlePlacesApi => googlePlacesKey;
} 