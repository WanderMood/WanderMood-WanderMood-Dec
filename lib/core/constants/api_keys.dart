import 'package:flutter/foundation.dart';

/// All API keys are loaded exclusively via --dart-define at build time.
/// NEVER hardcode keys here. For local development, use a launch configuration
/// or a shell script that passes --dart-define flags.
///
/// Build example:
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ... \
///   --dart-define=OPENAI_API_KEY=sk-... \
///   --dart-define=OPENWEATHER_API_KEY=abc123 \
///   --dart-define=GOOGLE_PLACES_API_KEY=AIza... \
///   --dart-define=GOOGLE_MAPS_API_KEY=AIza...
class ApiKeys {
  static const String _missing = '';

  static String get googlePlacesKey {
    const key = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
    if (key.isEmpty && kDebugMode) {
      debugPrint('WARNING: GOOGLE_PLACES_API_KEY not set via --dart-define');
    }
    return key;
  }

  static String get openAiKey {
    const key = String.fromEnvironment('OPENAI_API_KEY');
    if (key.isEmpty && kDebugMode) {
      debugPrint('WARNING: OPENAI_API_KEY not set via --dart-define');
    }
    return key;
  }

  static String get openWeather {
    const key = String.fromEnvironment('OPENWEATHER_API_KEY');
    if (key.isEmpty && kDebugMode) {
      debugPrint('WARNING: OPENWEATHER_API_KEY not set via --dart-define');
    }
    return key;
  }

  static String get supabaseUrl {
    const url = String.fromEnvironment('SUPABASE_URL');
    if (url.isEmpty) {
      if (kDebugMode) {
        debugPrint('CRITICAL: SUPABASE_URL not set via --dart-define');
      }
      return _missing;
    }
    return url;
  }

  static String get supabaseAnonKey {
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (key.isEmpty) {
      if (kDebugMode) {
        debugPrint('CRITICAL: SUPABASE_ANON_KEY not set via --dart-define');
      }
      return _missing;
    }
    return key;
  }

  static String get googleMapsKey {
    const key = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (key.isEmpty && kDebugMode) {
      debugPrint('WARNING: GOOGLE_MAPS_API_KEY not set via --dart-define');
    }
    return key;
  }
} 