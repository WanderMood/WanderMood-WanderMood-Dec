import '../constants/api_keys.dart';

/// Deprecated: Use ApiKeys directly. Kept for backward compatibility.
class SupabaseConstants {
  static String get supabaseUrl => ApiKeys.supabaseUrl;
  static String get supabaseAnonKey => ApiKeys.supabaseAnonKey;
} 