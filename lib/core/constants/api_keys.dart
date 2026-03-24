import 'package:flutter/foundation.dart';

/// API key resolution order for all keys:
///   1. Build-time --dart-define (production builds)
///   2. Hardcoded debug fallback (debug only — real dev keys baked in)
class ApiKeys {
  /// Google Places API Key
  static String get googlePlacesKey {
    const buildKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
    if (buildKey.isNotEmpty && buildKey != 'YOUR_GOOGLE_PLACES_API_KEY_HERE') {
      return buildKey;
    }
    if (kDebugMode) return 'AIzaSyAzmi2Z4Y0Z4ZMLTtiZcbZseOHwAlMux60';
    throw Exception(
        'GOOGLE_PLACES_API_KEY not configured. Pass via --dart-define=GOOGLE_PLACES_API_KEY=...');
  }

  /// OpenAI API Key — optional, services use mock responses when empty.
  static String get openAiKey {
    const buildKey = String.fromEnvironment('OPENAI_API_KEY');
    final normalized = buildKey.trim();
    final looksLikePlaceholder =
        normalized == 'YOUR_OPENAI_API_KEY_HERE' ||
        normalized == 'sk-your-key-here' ||
        normalized.toLowerCase().contains('your-key-here');
    if (normalized.isNotEmpty && !looksLikePlaceholder) {
      return normalized;
    }
    return '';
  }

  /// Same dev key as previous kDebug fallback; override with `--dart-define=OPENWEATHER_API_KEY=...`.
  static const String _defaultOpenWeatherKey =
      'd158323777e324a2537591bc7fa6ca17';

  /// OpenWeather API Key
  static String get openWeather {
    const buildKey = String.fromEnvironment(
      'OPENWEATHER_API_KEY',
      defaultValue: _defaultOpenWeatherKey,
    );
    if (buildKey.isEmpty || buildKey == 'YOUR_OPENWEATHER_API_KEY_HERE') {
      throw Exception(
          'OPENWEATHER_API_KEY not configured. Pass via --dart-define=OPENWEATHER_API_KEY=...');
    }
    return buildKey;
  }

  /// Default production Supabase (same project as local debug). Override with
  /// `--dart-define=SUPABASE_URL=...` for TestFlight/CI without baking keys.
  static const String _defaultSupabaseUrl =
      'https://oojpipspxwdmiyaymldo.supabase.co';

  /// Supabase anon JWT for [_defaultSupabaseUrl]. RLS still applies server-side.
  static const String _defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9vanBpcHNweHdkbWl5YXltbGRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYxNjkzMzEsImV4cCI6MjA4MTc0NTMzMX0.zFlCGZw-EjmyLi4E9v3S5V7DAmwXqbcBE-JMxBpotQg';

  /// Supabase Project URL
  static String get supabaseUrl {
    const buildUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: _defaultSupabaseUrl,
    );
    if (buildUrl.isEmpty || buildUrl == 'YOUR_SUPABASE_URL_HERE') {
      throw Exception(
          'SUPABASE_URL not configured. Pass via --dart-define=SUPABASE_URL=...');
    }
    return buildUrl;
  }

  /// Supabase Anonymous Key
  static String get supabaseAnonKey {
    const buildKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: _defaultSupabaseAnonKey,
    );
    if (buildKey.isEmpty ||
        buildKey == 'YOUR_SUPABASE_ANON_KEY_HERE' ||
        buildKey.length < 50) {
      throw Exception(
          'SUPABASE_ANON_KEY not configured. Pass via --dart-define=SUPABASE_ANON_KEY=...');
    }
    return buildKey;
  }

  /// Google Maps API Key
  /// Note: must also be set natively in AppDelegate.swift and AndroidManifest.xml.
  static String get googleMapsKey {
    const buildKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (buildKey.isNotEmpty && buildKey != 'YOUR_GOOGLE_MAPS_API_KEY_HERE') {
      return buildKey;
    }
    if (kDebugMode) return 'AIzaSyDFqiRdkEvgQUZisLAgm97aJyFBGznkg0k';
    throw Exception(
        'GOOGLE_MAPS_API_KEY not configured. Pass via --dart-define=GOOGLE_MAPS_API_KEY=...');
  }
}
