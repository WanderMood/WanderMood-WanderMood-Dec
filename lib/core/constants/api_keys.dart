import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class ApiKeys {
  // 🔑 API Keys loaded from environment variables for security
  // Set these in .env file or as build-time environment variables via --dart-define
  
  /// Google Places API Key
  /// Priority: .env file → build-time env → fallback (for development only)
  static String get googlePlacesKey {
    // Try .env file first (dotenv must be loaded before accessing)
    try {
      if (dotenv.isInitialized) {
        final envKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
        if (envKey != null && envKey.isNotEmpty && envKey != 'YOUR_GOOGLE_PLACES_API_KEY_HERE') {
          return envKey;
        }
      }
    } catch (e) {
      // dotenv might not be loaded yet, continue to next option
      if (kDebugMode) {
        debugPrint('⚠️ dotenv not loaded for GOOGLE_PLACES_API_KEY: $e');
      }
    }
    
    // Try build-time environment variable
    final buildKey = const String.fromEnvironment('GOOGLE_PLACES_API_KEY');
    if (buildKey.isNotEmpty && buildKey != 'YOUR_GOOGLE_PLACES_API_KEY_HERE') {
      return buildKey;
    }
    
    // Fallback only for development (will fail in production if not set)
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: Using fallback Google Places API key. Set GOOGLE_PLACES_API_KEY in .env or build args.');
      return 'AIzaSyAzmi2Z4Y0Z4ZMLTtiZcbZseOHwAlMux60';
    }
    
    throw Exception('GOOGLE_PLACES_API_KEY not found. Set it in .env file or build arguments.');
  }
  
  /// OpenAI API Key
  /// Priority: .env file → build-time env → empty (will use mock responses)
  static String get openAiKey {
    // Try .env file first (dotenv must be loaded before accessing)
    try {
      if (dotenv.isInitialized) {
        final envKey = dotenv.env['OPENAI_API_KEY'];
        if (envKey != null && envKey.isNotEmpty && envKey != 'YOUR_OPENAI_API_KEY_HERE') {
          return envKey;
        }
      }
    } catch (e) {
      // dotenv might not be loaded yet, continue to next option
      if (kDebugMode) {
        debugPrint('⚠️ dotenv not loaded for OPENAI_API_KEY: $e');
      }
    }
    
    // Try build-time environment variable
    final buildKey = const String.fromEnvironment('OPENAI_API_KEY');
    if (buildKey.isNotEmpty && buildKey != 'YOUR_OPENAI_API_KEY_HERE') {
      return buildKey;
    }
    
    // Return empty - services should handle missing key gracefully
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: OpenAI API key not found. AI features will use mock responses.');
    }
    return '';
  }
  
  /// OpenWeather API Key
  /// Priority: .env file → build-time env → fallback (for development only)
  static String get openWeather {
    // Try .env file first (dotenv must be loaded before accessing)
    try {
      if (dotenv.isInitialized) {
        final envKey = dotenv.env['OPENWEATHER_API_KEY'];
        if (envKey != null && envKey.isNotEmpty && envKey != 'YOUR_OPENWEATHER_API_KEY_HERE') {
          return envKey;
        }
      }
    } catch (e) {
      // dotenv might not be loaded yet, continue to next option
      if (kDebugMode) {
        debugPrint('⚠️ dotenv not loaded for OPENWEATHER_API_KEY: $e');
      }
    }
    
    // Try build-time environment variable
    final buildKey = const String.fromEnvironment('OPENWEATHER_API_KEY');
    if (buildKey.isNotEmpty && buildKey != 'YOUR_OPENWEATHER_API_KEY_HERE') {
      return buildKey;
    }
    
    // Fallback only for development
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: Using fallback OpenWeather API key. Set OPENWEATHER_API_KEY in .env or build args.');
      return 'd158323777e324a2537591bc7fa6ca17';
    }
    
    throw Exception('OPENWEATHER_API_KEY not found. Set it in .env file or build arguments.');
  }
  
  /// Supabase URL
  /// Priority: .env file → build-time env → fallback (for development only)
  static String get supabaseUrl {
    // Try .env file first (dotenv must be loaded before accessing)
    try {
      if (dotenv.isInitialized) {
        final envUrl = dotenv.env['SUPABASE_URL'];
        if (envUrl != null && envUrl.isNotEmpty && envUrl != 'YOUR_SUPABASE_URL_HERE') {
          return envUrl;
        }
      }
    } catch (e) {
      // dotenv might not be loaded yet, continue to next option
      if (kDebugMode) {
        debugPrint('⚠️ dotenv not loaded for SUPABASE_URL: $e');
      }
    }
    
    // Try build-time environment variable
    final buildUrl = const String.fromEnvironment('SUPABASE_URL');
    if (buildUrl.isNotEmpty && buildUrl != 'YOUR_SUPABASE_URL_HERE') {
      return buildUrl;
    }
    
    // Fallback only for development
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: Using fallback Supabase URL. Set SUPABASE_URL in .env or build args.');
      if (dotenv.isInitialized) {
        debugPrint('⚠️ Attempted to load from dotenv: ${dotenv.env['SUPABASE_URL']}');
      } else {
        debugPrint('⚠️ dotenv is not initialized - .env file not found or not loaded');
      }
      return 'https://oojpipspxwdmiyaymldo.supabase.co';
    }
    
    throw Exception('SUPABASE_URL not found. Set it in .env file or build arguments.');
  }
  
  /// Supabase Anonymous Key
  /// Priority: .env file → build-time env → fallback (for development only)
  static String get supabaseAnonKey {
    // Try .env file first (dotenv must be loaded before accessing)
    try {
      if (dotenv.isInitialized) {
        final envKey = dotenv.env['SUPABASE_ANON_KEY'];
        if (envKey != null && envKey.isNotEmpty && envKey != 'YOUR_SUPABASE_ANON_KEY_HERE') {
          return envKey;
        }
      }
    } catch (e) {
      // dotenv might not be loaded yet, continue to next option
      if (kDebugMode) {
        debugPrint('⚠️ dotenv not loaded for SUPABASE_ANON_KEY: $e');
      }
    }
    
    // Try build-time environment variable
    final buildKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
    if (buildKey.isNotEmpty && buildKey != 'YOUR_SUPABASE_ANON_KEY_HERE') {
      return buildKey;
    }
    
    // Fallback only for development
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: Using fallback Supabase anon key. Set SUPABASE_ANON_KEY in .env or build args.');
      if (dotenv.isInitialized) {
        debugPrint('⚠️ Attempted to load from dotenv: ${dotenv.env['SUPABASE_ANON_KEY']}');
      } else {
        debugPrint('⚠️ dotenv is not initialized - .env file not found or not loaded');
      }
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9vanBpcHNweHdkbWl5YXltbGRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYxNjkzMzEsImV4cCI6MjA4MTc0NTMzMX0.zFlCGZw-EjmyLi4E9v3S5V7DAmwXqbcBE-JMxBpotQg';
    }
    
    throw Exception('SUPABASE_ANON_KEY not found. Set it in .env file or build arguments.');
  }
  
  /// Google Maps API Key
  /// Note: This is used for reference/documentation. The actual key must be set in native files:
  /// - iOS: ios/Runner/AppDelegate.swift
  /// - Android: android/app/src/main/AndroidManifest.xml
  /// Priority: .env file → build-time env → fallback (for development only)
  static String get googleMapsKey {
    // Try .env file first (dotenv must be loaded before accessing)
    try {
      if (dotenv.isInitialized) {
        final envKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
        if (envKey != null && envKey.isNotEmpty && envKey != 'YOUR_GOOGLE_MAPS_API_KEY_HERE') {
          return envKey;
        }
      }
    } catch (e) {
      // dotenv might not be loaded yet, continue to next option
      if (kDebugMode) {
        debugPrint('⚠️ dotenv not loaded for GOOGLE_MAPS_API_KEY: $e');
      }
    }
    
    // Try build-time environment variable
    final buildKey = const String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (buildKey.isNotEmpty && buildKey != 'YOUR_GOOGLE_MAPS_API_KEY_HERE') {
      return buildKey;
    }
    
    // Fallback only for development
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: Using fallback Google Maps API key. Set GOOGLE_MAPS_API_KEY in .env or build args.');
      debugPrint('⚠️ NOTE: Google Maps key must also be set in native files (AppDelegate.swift and AndroidManifest.xml)');
      return 'AIzaSyDFqiRdkEvgQUZisLAgm97aJyFBGznkg0k';
    }
    
    throw Exception('GOOGLE_MAPS_API_KEY not found. Set it in .env file or build arguments.');
  }
} 