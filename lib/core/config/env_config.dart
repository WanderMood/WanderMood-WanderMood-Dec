import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/api_keys.dart';

class EnvConfig {
  static bool get isProduction => true; // Force production mode
  static bool get enableLogging => kDebugMode; // Enable logging in debug mode
  
  // Supabase Configuration
  static String get supabaseUrl => ApiKeys.supabaseUrl;  // Always use production URL
  static String get supabaseAnonKey => ApiKeys.supabaseAnonKey;  // Always use production key
    
  // Other API Keys
  static String get openWeatherKey => ApiKeys.openWeather;
  static String get openAiKey => ApiKeys.openAiKey;
  static String get googlePlacesKey => ApiKeys.googlePlacesKey;

  // Database Tables
  static const String usersTable = 'users';
  static const String moodsTable = 'moods';
  static const String activitiesTable = 'activities';
  static const String userPreferencesTable = 'user_preferences';
  static const String recommendationsTable = 'recommendations';
  static const String weatherDataTable = 'weather_data';

  // Storage Buckets
  static const String profileImagesBucket = 'profile_images';
  static const String activityImagesBucket = 'activity_images';

  // Functions
  static const String getCurrentWeatherFunction = 'get_current_weather';
  static const String getRecommendationsFunction = 'get_recommendations';

  // Development Settings
  static bool get shouldMockData => false; // Disable mocking
} 