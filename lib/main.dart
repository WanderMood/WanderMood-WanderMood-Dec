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
import 'package:geolocator/geolocator.dart';

// Provider to initialize app data on startup
final appInitializerProvider = FutureProvider<bool>((ref) async {
  // Start listening to auth state changes 
  ref.watch(authStateChangesProvider);
  
  // **CRITICAL**: Synchronize SharedPreferences with Supabase auth state
  await _synchronizeAuthState();
  
  // **LOCATION PERMISSION**: Request location permission early to show popup
  await _requestLocationPermission();
  
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

/// Request location permission early to show the iOS permission popup
Future<void> _requestLocationPermission() async {
  try {
    debugPrint('📍 Checking location permission...');
    
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('⚠️ Location services are disabled');
      return;
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('📍 Current location permission: $permission');

    if (permission == LocationPermission.denied) {
      // Request permission - this will show the iOS popup
      debugPrint('📍 Requesting location permission...');
      permission = await Geolocator.requestPermission();
      debugPrint('📍 Location permission result: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('❌ Location permission denied by user');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Location permission permanently denied');
      return;
    }

    debugPrint('✅ Location permission granted: $permission');
  } catch (e) {
    debugPrint('❌ Error requesting location permission: $e');
  }
}

/// Synchronize SharedPreferences with actual Supabase auth state
/// This fixes issues where users are authenticated in Supabase but flags aren't set locally
Future<void> _synchronizeAuthState() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    final session = Supabase.instance.client.auth.currentSession;
    
    final hasCompletedAuth = prefs.getBool('hasCompletedAuth') ?? false;
    final hasCompletedPreferences = prefs.getBool('hasCompletedPreferences') ?? false;
    
    debugPrint('🔄 Synchronizing auth state...');
    debugPrint('   Supabase User: ${user?.id}');
    debugPrint('   Supabase Session: ${session != null}');
    debugPrint('   Local hasCompletedAuth: $hasCompletedAuth');
    debugPrint('   Local hasCompletedPreferences: $hasCompletedPreferences');
    
    // If user is authenticated in Supabase but not marked as completed locally
    if (user != null && session != null && !hasCompletedAuth) {
      debugPrint('🔧 FIXING: User is authenticated in Supabase but not marked locally');
      await prefs.setBool('hasCompletedAuth', true);
              await prefs.setBool('has_seen_onboarding', true);
      
      // Check if user has preferences in database
      try {
        final response = await Supabase.instance.client
            .from('user_preferences')
            .select('*')
            .eq('user_id', user.id)
            .single();
        
        if (response.isNotEmpty) {
          debugPrint('🔧 FIXING: User has preferences in database, marking as completed');
          await prefs.setBool('hasCompletedPreferences', true);
        } else {
          debugPrint('📋 User has no preferences in database yet');
        }
      } catch (e) {
        debugPrint('📋 User has no preferences in database yet: $e');
      }
      
      debugPrint('✅ Auth state synchronized successfully!');
    }
    
    // If user is NOT authenticated in Supabase but marked as completed locally
    if (user == null && hasCompletedAuth) {
      debugPrint('🔧 FIXING: Local state says authenticated but Supabase says not');
      await prefs.setBool('hasCompletedAuth', false);
      await prefs.setBool('hasCompletedPreferences', false);
      debugPrint('✅ Cleared inconsistent local auth state');
    }
    
  } catch (e) {
    debugPrint('❌ Error synchronizing auth state: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    await dotenv.load(fileName: '.env');
    
    // Initialize Supabase with loaded environment variables
    await SupabaseConfig.initialize();
    
    // Handle deep links for email verification
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        debugPrint('✅ User signed in via email verification');
      }
    });
    
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
      showPerformanceOverlay: false,
      showSemanticsDebugger: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: userPrefs.getThemeMode(),
      routerConfig: router,
    );
  }
}
