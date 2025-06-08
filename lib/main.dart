import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'core/config/supabase_config.dart';
import 'features/auth/providers/user_provider.dart';
import 'core/domain/providers/location_notifier_provider.dart';
import 'features/location/services/location_service.dart';
import 'features/plans/data/services/schema_helper.dart';
import 'features/settings/presentation/providers/user_preferences_provider.dart';
import 'features/gamification/providers/gamification_provider.dart' as gamification;
import 'package:wandermood/features/places/providers/explore_places_provider.dart';

// Provider to initialize app data on startup
final appInitializerProvider = FutureProvider<bool>((ref) async {
  // Start listening to auth state changes 
  ref.watch(authStateChangesProvider);
  
  // Initialize location
  if (Supabase.instance.client.auth.currentUser != null) {
    await ref.read(locationNotifierProvider.notifier).getCurrentLocation();
  }
  
  // Initialize database schema
  try {
    final schemaHelper = ref.read(schemaHelperProvider);
    await schemaHelper.createScheduledActivitiesTable();
  } catch (e) {
    debugPrint('Error initializing database schema: $e');
  }
  
  // Record app visit for gamification
  try {
    await ref.read(gamification.gamificationProvider.notifier).recordAppVisit();
  } catch (e) {
    debugPrint('Error recording app visit: $e');
  }
  
  return true;
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    await dotenv.load(fileName: '.env');
    
    // Initialize Supabase with loaded environment variables
    await SupabaseConfig.initialize();
    
    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    
    // 🧹 CLEANUP: Clear expired API cache on app start
    ExplorePlaces.clearExpiredCache();
    
    debugPrint('App initialized with Rotterdam as default location: ${LocationService.defaultLocation}');
    
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          gamification.sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const WanderMoodApp(),
      ),
    );
  } catch (e) {
    debugPrint('Error initializing app: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      ),
    );
  }
}

class WanderMoodApp extends ConsumerWidget {
  const WanderMoodApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start app initialization
    ref.watch(appInitializerProvider);
    
    // Get the router instance
    final router = ref.watch(routerProvider);
    
    // Get user preferences for theme
    final userPrefs = ref.watch(userPreferencesProvider);
    
    return MaterialApp.router(
      title: 'WanderMood',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: userPrefs.getThemeMode(),
      routerConfig: router,
    );
  }
}
