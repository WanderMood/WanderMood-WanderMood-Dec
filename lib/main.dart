import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/api_keys.dart';
import 'core/domain/providers/location_notifier_provider.dart';
import 'features/location/services/location_service.dart';
import 'features/plans/data/services/schema_helper.dart';
import 'package:wandermood/core/services/daily_cleanup_service.dart';
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
import 'package:wandermood/features/group_planning/domain/group_planning_deep_link.dart';
import 'package:wandermood/features/places/data/moody_place_blurb_cache.dart';
import 'package:wandermood/features/places/data/moody_place_card_ui_cache.dart';

// Provider to initialize app data on startup
final appInitializerProvider = FutureProvider<bool>((ref) async {
  // Do not [ref.watch] authStateChangesProvider here: that stream fires multiple
  // times during cold start (session restore, etc.) and would invalidate this
  // [FutureProvider], re-running notifications/location/DB init in parallel and
  // risking native crashes (EXC_BAD_ACCESS). Session restore is handled below;
  // [authStateChangesProvider] is already watched from profile/auth providers.
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Single [runApp]: on iOS (implicit engine), a second [runApp] after async init
  // often never replaces the first tree — users stayed on the green placeholder.
  runApp(const _WanderMoodBootstrap());
}

/// Boots async (Supabase, prefs), then swaps in [ProviderScope] + [WanderMoodApp].
class _WanderMoodBootstrap extends StatefulWidget {
  const _WanderMoodBootstrap();

  @override
  State<_WanderMoodBootstrap> createState() => _WanderMoodBootstrapState();
}

class _WanderMoodBootstrapState extends State<_WanderMoodBootstrap> {
  Widget? _root;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      if (kDebugMode) {
        debugPrint(
          '🔑 API keys loaded from --dart-define (release) or ApiKeys fallbacks (debug)',
        );
      }

      await _validateApiKeys();

      await SupabaseConfig.initialize().timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw TimeoutException(
          'Supabase.initialize() took longer than 45s. '
          'Check network, clock, and Supabase project status.',
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final magicLinkEmailCache = CachedMagicLinkEmailService(prefs);

      // Prehydrate Moody place caches so Explore cards can sync-read rich copy
      // on the very first frame instead of flashing skeleton → plain → rich.
      // Disk read is a few ms; we do it in parallel so it costs nothing extra.
      await Future.wait([
        MoodyPlaceCardUiCache.ensureHydrated(),
        MoodyPlaceBlurbCache.ensureHydrated(),
      ]);

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
          await Future.wait([
            MoodyPlaceCardUiCache.clearPersistent(),
            MoodyPlaceBlurbCache.clearPersistent(),
          ]);
        }
      });

      debugPrint(
        'App initialized with Rotterdam as default location: ${LocationService.defaultLocation}',
      );

      if (!mounted) return;
      setState(() {
        _root = ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            gamification.sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const WanderMoodApp(),
        );
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing app: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _root = MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      kDebugMode
                          ? 'App Initialization Error'
                          : 'WanderMood couldn\'t start',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                    if (kDebugMode) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Check console for details',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _root ??
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: _EngineWarmupPlaceholder(),
        );
  }
}

/// Same forest tone as [SplashScreen] — shown until bootstrap finishes.
class _EngineWarmupPlaceholder extends StatelessWidget {
  const _EngineWarmupPlaceholder();

  static const Color _wmForest = Color(0xFF2A6049);

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _wmForest,
      child: Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        ),
      ),
    );
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

class WanderMoodApp extends ConsumerStatefulWidget {
  const WanderMoodApp({super.key});

  @override
  ConsumerState<WanderMoodApp> createState() => _WanderMoodAppState();
}

class _WanderMoodAppState extends ConsumerState<WanderMoodApp> {
  StreamSubscription<Uri>? _appLinkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initGroupPlanningDeepLinks());
  }

  Future<void> _initGroupPlanningDeepLinks() async {
    final appLinks = AppLinks();
    try {
      final initial = await appLinks.getInitialLink();
      _handleGroupPlanningUri(initial);
    } catch (e) {
      debugPrint('AppLinks getInitialLink: $e');
    }
    _appLinkSubscription = appLinks.uriLinkStream.listen(
      _handleGroupPlanningUri,
      onError: (Object e) => debugPrint('AppLinks stream: $e'),
    );
  }

  void _handleGroupPlanningUri(Uri? uri) {
    if (uri == null || !mounted) return;
    final location = groupPlanningJoinLocationFromUri(uri);
    if (location == null) return;
    final router = ref.read(routerProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      debugPrint('🔗 Deep link → $location');
      router.go(location);
    });
  }

  @override
  void dispose() {
    _appLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Start app initialization
    ref.watch(appInitializerProvider);

    ref.listen<String?>(notificationLaunchPayloadProvider, (prev, next) {
      if (next == null || next.isEmpty) return;
      final router = ref.read(routerProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        applyNotificationNavigation(router, next, ref);
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

    final router = ref.watch(routerProvider);
    final userPrefs = ref.watch(userPreferencesProvider);
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      // During go_router transitions the child can be null briefly (splash → main,
      // hot restart, shell rebuilds). [SizedBox.shrink] left a bare cream layer that
      // users read as a stuck white/blank screen — show a tiny loader instead.
      builder: (context, child) {
        return ColoredBox(
          color: AppTheme.cream,
          child: child ??
              const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF2A6049),
                  ),
                ),
              ),
        );
      },
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) {
          final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == deviceLocale.languageCode) {
              return supportedLocale;
            }
          }
          return const Locale('en');
        }
        return locale;
      },
      routerConfig: router,
    );
  }
}
