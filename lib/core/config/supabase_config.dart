import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env_config.dart';

class SupabaseConfig {
  static String get url => EnvConfig.supabaseUrl;
  static String get anonKey => EnvConfig.supabaseAnonKey;
  
  static Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('Initializing Supabase...');
    }
    
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: !EnvConfig.isProduction,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    
    if (kDebugMode) {
      debugPrint('Supabase initialized successfully');
    }
  }
  
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  
  // Database references
  static String get usersTable => EnvConfig.usersTable;
  static String get moodsTable => EnvConfig.moodsTable;
  static String get activitiesTable => EnvConfig.activitiesTable;
  static String get userPreferencesTable => EnvConfig.userPreferencesTable;
  static String get recommendationsTable => EnvConfig.recommendationsTable;
  static String get weatherDataTable => EnvConfig.weatherDataTable;
  
  // Storage buckets
  static String get profileImagesBucket => EnvConfig.profileImagesBucket;
  static String get activityImagesBucket => EnvConfig.activityImagesBucket;
  
  // Functions
  static String get getCurrentWeatherFunction => EnvConfig.getCurrentWeatherFunction;
  static String get getRecommendationsFunction => EnvConfig.getRecommendationsFunction;
} 