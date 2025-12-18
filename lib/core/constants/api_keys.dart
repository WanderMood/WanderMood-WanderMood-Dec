import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class ApiKeys {
  // 🔑 API Keys loaded from environment variables for security
  // Set these in .env file or as build-time environment variables
  
  /// Google Places API Key
  /// Priority: .env file → build-time env → fallback (for development only)
  static String get googlePlacesKey {
    // Try .env file first
    final envKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    // Try build-time environment variable
    final buildKey = const String.fromEnvironment('GOOGLE_PLACES_API_KEY');
    if (buildKey.isNotEmpty) {
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
    final envKey = dotenv.env['OPENAI_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    final buildKey = const String.fromEnvironment('OPENAI_API_KEY');
    if (buildKey.isNotEmpty) {
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
    final envKey = dotenv.env['OPENWEATHER_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    final buildKey = const String.fromEnvironment('OPENWEATHER_API_KEY');
    if (buildKey.isNotEmpty) {
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
    final envUrl = dotenv.env['SUPABASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    
    final buildUrl = const String.fromEnvironment('SUPABASE_URL');
    if (buildUrl.isNotEmpty) {
      return buildUrl;
    }
    
    // Fallback only for development
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: Using fallback Supabase URL. Set SUPABASE_URL in .env or build args.');
      return 'https://ymxehzmgeqccuvbvjwtq.supabase.co';
    }
    
    throw Exception('SUPABASE_URL not found. Set it in .env file or build arguments.');
  }
  
  /// Supabase Anonymous Key
  /// Priority: .env file → build-time env → fallback (for development only)
  static String get supabaseAnonKey {
    final envKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    final buildKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
    if (buildKey.isNotEmpty) {
      return buildKey;
    }
    
    // Fallback only for development
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: Using fallback Supabase anon key. Set SUPABASE_ANON_KEY in .env or build args.');
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlteGVoem1nZXFjY3V2YnZqd3RxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4ODU4NzIsImV4cCI6MjA4MTQ2MTg3Mn0.qTUcVZxl8PP_S48t9XQKBYvuF4QWtdKvzYPsAKr0isc';
    }
    
    throw Exception('SUPABASE_ANON_KEY not found. Set it in .env file or build arguments.');
  }
} 