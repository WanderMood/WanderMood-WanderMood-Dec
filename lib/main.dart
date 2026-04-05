import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/api_keys.dart';
import 'features/auth/providers/user_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'core/domain/providers/location_notifier_provider.dart';
import 'features/location/services/location_service.dart';
import 'features/plans/data/services/schema_helper.dart';
import 'services/daily_cleanup_service.dart';
import 'core/providers/supabase_provider.dart';
import 'features/settings/presentation/providers/user_preferences_provider.dart';
import 'core/services/ai_chat_quota_service.dart';
import 'core/services/cached_magic_link_email_service.dart';
import 'features/gamification/providers/gamification_provider.dart' as gamification;
import 'package:geolocator/geolocator.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/presentation/providers/language_provider.dart';
import 'package:wandermood/core/notifications/notification_navigation.dart';
import 'package:wandermood/core/services/notification_service.dart';
import 'package:wandermood/core/providers/notification_provider.dart';

// Provider to initialize app data on startup
final appInitializerProvider = FutureProvider<bool>((ref) async {
  // Start listening to auth state changes 
  ref.watch(authStateChangesProvider);
  
  // **CRITICAL**: Synchronize SharedPreferences with Supabase auth state
  await _synchronizeAuthState();
  
  // **LOCATION PERMISSION**: Request location permission early to show popup
  await _requestLocationPermission();
  
  // Resolve city label from GPS for everyone (not only signed-in). Otherwise the
  // hub/explore briefly (or permanently) showed a hard-coded default city.
  await ref.read(locationNotifierProvider.notifier).getCurrentLocation();
  
  // Initialize database schema
  try {
    final schemaHelper = ref.read(schemaHelperProvider);
    await schemaHelper.createScheduledActivitiesTable();
  } catch (e) {
    debugPrint('Error initializing database schema: $e');
  }
  
  // Clean up old scheduled activities (past dates) on app start
  try {
    final client = ref.read(supabaseClientProvider);
    await DailyCleanupService(client).cleanupOldActivities();
  } catch (e) {
    debugPrint('Error during daily cleanup: $e');
  }
  
  // Record app visit for gamification
  try {
    await ref.read(gamification.gamificationProvider.notifier).recordAppVisit();
  } catch (e) {
    debugPrint('Error recording app visit: $e');
  }

  // Initialize local notifications + schedule recurring notifications.
  // We do this after auth sync so we can check if a user is logged in.
  try {
    NotificationService.instance.onNotificationPayload = (payload) {
      if (payload == null || payload.isEmpty) return;
      ref.read(notificationLaunchPayloadProvider.notifier).state = payload;
    };
    await NotificationService.instance.initialize();
    final coldStartPayload =
        NotificationService.instance.consumePendingLaunchPayload();
    if (coldStartPayload != null && coldStartPayload.isNotEmpty) {
      ref.read(notificationLaunchPayloadProvider.notifier).state =
          coldStartPayload;
    }
    await NotificationService.instance.requestPermission();
    if (Supabase.instance.client.auth.currentUser != null) {
      await ref.read(notificationSchedulerProvider).rescheduleAll();
    }
    // Activate gamification bridge (listens for streak/achievement events).
    ref.read(notificationBridgeProvider);
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
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
/// Wait for Supabase to restore session from secure storage
Future<void> _waitForSessionRestore() async {
  try {
    debugPrint('🔄 Waiting for Supabase session restoration...');
    
    // Give Supabase time to restore session from secure storage
    // This is especially important on hot restart and after email verification
    // CRITICAL: After email verification, app restarts and session needs more time to restore
    for (int i = 0; i < 20; i++) { // Increased from 5 to 20 (4 seconds total)
      await Future.delayed(const Duration(milliseconds: 200));
      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;
      
      if (session != null && user != null) {
        debugPrint('✅ Session restored: ${user.id}');
        
        // CRITICAL: Don't refresh session here - causes rate limiting during onboarding
        // Session is already valid if we found it, no need to refresh constantly
        debugPrint('✅ Session found and valid, skipping refresh to avoid rate limiting');
        
        return;
      }
    }
    
    debugPrint('ℹ️ No session found after waiting');
  } catch (e) {
    debugPrint('❌ Error waiting for session restore: $e');
  }
}

/// This fixes issues where users are authenticated in Supabase but flags aren't set locally
Future<void> _synchronizeAuthState() async {
  try {
    // First, wait for Supabase to restore any existing session
    await _waitForSessionRestore();
    
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    final session = Supabase.instance.client.auth.currentSession;
    
    final hasCompletedPreferences = prefs.getBool('hasCompletedPreferences') ?? false;
    
    debugPrint('🔄 Synchronizing auth state...');
    debugPrint('   Supabase User: ${user?.id}');
    debugPrint('   Supabase Session: ${session != null}');
    debugPrint('   Local hasCompletedPreferences: $hasCompletedPreferences');
    
    // If user is authenticated, mark onboarding as seen
    if (user != null && session != null) {
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      if (!hasSeenOnboarding) {
      await prefs.setBool('has_seen_onboarding', true);
        debugPrint('✅ Marked onboarding as seen');
      }
      
      // CRITICAL: Don't auto-mark preferences as completed just because they exist in DB
      // Preferences are saved during email verification (basic communication prefs),
      // but onboarding completion should only be set after the full onboarding flow
      // Only check if preferences exist, but don't set the flag here
      try {
        final response = await Supabase.instance.client
            .from('user_preferences')
            .select('*')
            .eq('user_id', user.id)
            .maybeSingle();
        
        if (response != null && response.isNotEmpty) {
          debugPrint('📋 User has preferences in database (may be partial from email verification)');
          // Don't set hasCompletedPreferences here - let onboarding_loading_screen.dart handle it
        }
      } catch (e) {
        debugPrint('📋 Could not check preferences: $e');
      }
    }
    
  } catch (e) {
    debugPrint('❌ Error synchronizing auth state: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Use --dart-define for API keys (never bundle .env in release)
    if (kDebugMode) {
      debugPrint('🔑 API keys loaded from --dart-define (release) or ApiKeys fallbacks (debug)');
    }
    
    // **CRITICAL**: Validate required API keys BEFORE initializing Supabase
    await _validateApiKeys();
    
    // Initialize Supabase with loaded environment variables
    await SupabaseConfig.initialize();
    
    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final magicLinkEmailCache = CachedMagicLinkEmailService(prefs);

    // Magic-link email cache: extend TTL while session is active; clear on sign-out.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        final email = data.session?.user.email;
        if (email != null && email.isNotEmpty) {
          if (event == AuthChangeEvent.signedIn) {
            debugPrint('✅ User signed in — magic-link email cache extended');
          }
          await magicLinkEmailCache.remember(email);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        await magicLinkEmailCache.clear();
        await AiChatQuotaService.clearPremiumCache();
      }
    });

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
  } catch (e, stackTrace) {
    debugPrint('❌ Error initializing app: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Show user-friendly error in debug, fail fast in release
    if (kDebugMode) {
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'App Initialization Error',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Check console for details',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Release: still run Flutter so users see an error instead of a blank launch screen
      // (rethrowing here leaves the native splash / white frame with no UI).
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'WanderMood couldn\'t start',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}

/// Validate that all required API keys are available
/// Throws exception if critical keys are missing
Future<void> _validateApiKeys() async {
  final missingKeys = <String>[];
  
  // Check Supabase keys (CRITICAL - app won't work without these)
  try {
    final supabaseUrl = ApiKeys.supabaseUrl;
    if (supabaseUrl.isEmpty || !supabaseUrl.startsWith('http')) {
      missingKeys.add('SUPABASE_URL');
    }
  } catch (e) {
    missingKeys.add('SUPABASE_URL');
  }
  
  try {
    final supabaseKey = ApiKeys.supabaseAnonKey;
    if (supabaseKey.isEmpty || supabaseKey.length < 50) {
      missingKeys.add('SUPABASE_ANON_KEY');
    }
  } catch (e) {
    missingKeys.add('SUPABASE_ANON_KEY');
  }
  
  // Check other keys (warnings only, not critical)
  try {
    final googlePlacesKey = ApiKeys.googlePlacesKey;
    if (googlePlacesKey.isEmpty || googlePlacesKey.length < 20) {
      debugPrint('⚠️ WARNING: GOOGLE_PLACES_API_KEY is missing or invalid');
    }
  } catch (e) {
    debugPrint('⚠️ WARNING: GOOGLE_PLACES_API_KEY is missing: $e');
  }

  final openAi = ApiKeys.openAiKey;
  if (openAi.isEmpty) {
    debugPrint(
      '⚠️ OPENAI_API_KEY is not set in the app bundle. Moody chat uses offline '
      'fallback; Explore card blurbs use the Supabase moody function (place_card_blurb) '
      'if deployed with OPENAI_API_KEY. For on-device OpenAI, use '
      '--dart-define=OPENAI_API_KEY=sk-...',
    );
  }
  
  // If critical keys are missing, throw error
  if (missingKeys.isNotEmpty) {
    final errorMessage = '''
❌ MISSING REQUIRED API KEYS:
${missingKeys.join('\n')}

For TestFlight/Release builds, provide keys via --dart-define:
flutter build ios --release --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key

For development, create a .env file in the project root with:
SUPABASE_URL=your_url
SUPABASE_ANON_KEY=your_key
''';
    
    if (kDebugMode) {
      debugPrint(errorMessage);
      // In debug, show warning but continue (might use fallbacks)
      debugPrint('⚠️ Continuing with fallback keys in debug mode...');
    } else {
      // In release, fail fast
      throw Exception(errorMessage);
    }
  } else {
    debugPrint('✅ All required API keys validated');
  }
}

class WanderMoodApp extends ConsumerWidget {
  const WanderMoodApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start app initialization
    ref.watch(appInitializerProvider);

    ref.listen<String?>(notificationLaunchPayloadProvider, (prev, next) {
      if (next == null || next.isEmpty) return;
      final router = ref.read(routerProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        applyNotificationNavigation(router, next);
        ref.read(notificationLaunchPayloadProvider.notifier).state = null;
      });
    });

    ref.listen<Locale?>(localeProvider, (previous, next) {
      if (previous == next) return;
      final init = ref.read(appInitializerProvider);
      if (!init.hasValue || init.hasError) return;
      if (Supabase.instance.client.auth.currentUser == null) return;
      unawaited(Future.microtask(() async {
        try {
          await ref.read(notificationSchedulerProvider).rescheduleAll();
        } catch (e) {
          debugPrint('Notification reschedule on locale change: $e');
        }
      }));
    });
    
    // Get the router instance
    final router = ref.watch(routerProvider);
    
    // Get user preferences for theme
    final userPrefs = ref.watch(userPreferencesProvider);
    
    // Get locale from locale provider
    final locale = ref.watch(localeProvider);
    
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
      // Localization configuration
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale, // null means use system locale
      localeResolutionCallback: (locale, supportedLocales) {
        // If locale is null (system default), use device locale
        if (locale == null) {
          final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
          // Check if device locale is supported
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == deviceLocale.languageCode) {
              return supportedLocale;
            }
          }
          // Fallback to English if device locale not supported
          return const Locale('en');
        }
        // Use the provided locale
        return locale;
      },
      routerConfig: router,
    );
  }
}
