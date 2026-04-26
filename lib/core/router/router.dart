import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/adventure/presentation/screens/adventure_plan_screen.dart';
// email_verification_screen.dart archived — app uses magic link only
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/communication_preference_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/places/presentation/screens/place_detail_screen.dart';
import '../../features/places/presentation/screens/saved_places_screen.dart';
import '../../features/mood/presentation/screens/mood_history_screen.dart';
import '../../features/onboarding/presentation/screens/travel_interests_screen.dart';
import '../../features/onboarding/presentation/screens/social_vibe_screen.dart';
import '../../features/onboarding/presentation/screens/planning_pace_screen.dart';
import '../../features/onboarding/presentation/screens/travel_style_screen.dart';
import '../../features/onboarding/presentation/screens/combined_travel_preferences_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_loading_screen.dart';
import '../../features/plans/presentation/screens/plan_loading_screen.dart';
import '../../features/plans/presentation/screens/day_plan_screen.dart';
import '../../features/plans/domain/models/activity.dart';
import '../../core/config/supabase_config.dart';
import '../../features/weather/presentation/pages/weather_page.dart';
import '../../features/recommendations/presentation/pages/recommendations_page.dart';
import '../../features/profile/presentation/screens/user_profile_screen.dart' as profile;
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/share_profile_screen.dart';
import '../../features/profile/presentation/screens/globe_screen.dart';
import '../../features/profile/presentation/screens/notifications_screen.dart';
import '../../features/notifications/presentation/notification_centre_screen.dart';
import '../../features/profile/presentation/screens/comprehensive_settings_screen.dart';
import '../../features/profile/presentation/screens/preferences_screen.dart';
import '../../features/profile/presentation/screens/account_security_screen.dart';
import '../../features/profile/presentation/screens/privacy_settings_screen.dart';
import '../../features/profile/presentation/screens/location_settings_screen.dart';
import '../../features/profile/presentation/screens/location_picker_screen.dart';
import '../../features/profile/presentation/screens/language_settings_screen.dart';
import '../../features/profile/presentation/screens/theme_settings_screen.dart';
import '../../features/profile/presentation/screens/achievements_settings_screen.dart';
import '../../features/profile/presentation/screens/subscription_screen.dart';
import '../../features/profile/presentation/screens/premium_upgrade_screen.dart';
import '../../features/profile/presentation/screens/data_storage_screen.dart';
import '../../features/profile/presentation/screens/help_support_screen.dart';
import '../../features/profile/presentation/screens/delete_account_screen.dart';
import '../../features/profile/presentation/screens/two_factor_auth_screen.dart';
import '../../features/profile/presentation/screens/active_sessions_screen.dart';
import '../../features/support/presentation/screens/support_screen.dart';
import '../../features/home/presentation/screens/mood_home_screen.dart';
import '../../features/home/presentation/screens/main_screen.dart';
import '../../features/home/presentation/screens/agenda_screen.dart';
import '../../features/home/presentation/screens/view_receipt_screen.dart';
import '../../features/gamification/presentation/screens/gamification_screen.dart';
import '../../features/group_planning/presentation/group_planning_hub_screen.dart';
import '../../features/group_planning/presentation/group_planning_create_screen.dart';
import '../../features/group_planning/presentation/group_planning_join_screen.dart';
import '../../features/group_planning/presentation/group_planning_lobby_screen.dart';
import '../../features/group_planning/presentation/group_planning_page_transitions.dart';
import '../../features/group_planning/presentation/group_planning_result_screen.dart';
import '../../features/group_planning/presentation/group_planning_reveal_screen.dart';
import '../../features/group_planning/presentation/group_planning_scan_screen.dart';
import '../../features/group_planning/presentation/group_planning_invite_wanderer_screen.dart';
import '../../features/group_planning/presentation/group_planning_day_picker_screen.dart';
import '../../features/group_planning/presentation/group_planning_match_loading_screen.dart';
import '../../features/group_planning/presentation/group_planning_time_picker_screen.dart';
import '../../features/group_planning/presentation/group_planning_confirmation_screen.dart';
import '../../features/social/presentation/screens/create_post_screen.dart';
import '../../features/social/presentation/screens/create_story_screen.dart';
import '../../features/social/presentation/screens/post_detail_screen.dart';
import '../../features/social/presentation/screens/unified_profile_screen.dart';
import '../../features/social/presentation/screens/message_hub_screen.dart';
import '../../features/social/presentation/screens/view_story_screen.dart';
import '../../features/social/domain/providers/social_providers.dart';
import '../../features/social/presentation/screens/edit_social_profile_screen.dart';
// Note: social/user_profile_screen.dart removed — all social profile routes use UnifiedProfileScreen
import '../../features/auth/providers/auth_state_provider.dart';
import '../../features/auth/presentation/screens/magic_link_signup_screen.dart';
import '../../features/auth/presentation/screens/auth_welcome_screen.dart';
import '../providers/preferences_provider.dart';
import '../providers/feature_flags_provider.dart';
import '../../features/onboarding/presentation/screens/app_intro_screen.dart';
import '../../features/onboarding/presentation/screens/moody_demo_screen.dart';
import '../../features/onboarding/presentation/screens/guest_day_plan_screen.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
// import '../../admin/admin_screen.dart'; // Removed - debug only

part 'router.g.dart';

/// Inline scaffold tokens (auth callback + preference redirect loaders only)
const Color _routerWmCream = Color(0xFFF5F0E8);
const Color _routerWmForest = Color(0xFF2A6049);
const Color _routerWmWhite = Color(0xFFFFFFFF);
const Color _routerWmCharcoal = Color(0xFF1E1C18);
const Color _routerWmError = Color(0xFFE05C5C);

// Helper function to handle email verification
// CRITICAL FIX: With PKCE flow, Supabase Flutter processes deep links automatically
// We need to wait for it to process, then verify the session
Future<void> _handleEmailVerification(Uri uri) async {
  try {
    debugPrint('🔗 Processing email verification deep link...');
    debugPrint('   Deep link URI: ${uri.toString()}');
    
    // CRITICAL: With PKCE flow, Supabase Flutter automatically processes the deep link
    // Extract tokens/code from URL to manually process if auto-processing fails
    final accessToken = uri.queryParameters['access_token'];
    final refreshToken = uri.queryParameters['refresh_token'];
    final code = uri.queryParameters['code']; // For PKCE flow
    final type = uri.queryParameters['type'];
    
    debugPrint('   URL parameters:');
    debugPrint('   access_token exists: ${accessToken != null}');
    debugPrint('   refresh_token exists: ${refreshToken != null}');
    debugPrint('   code exists: ${code != null}');
    debugPrint('   type: $type');
    
    // STEP 1: Wait for Supabase Flutter to automatically process the deep link (PKCE flow)
    // CRITICAL: After email verification, app may restart, so we need more time for session restoration
    debugPrint('⏳ Waiting for Supabase to automatically process deep link (PKCE)...');
    for (int i = 0; i < 20; i++) { // Increased from 10 to 20 (4 seconds total) to allow more time
      await Future.delayed(const Duration(milliseconds: 200));
      final user = Supabase.instance.client.auth.currentUser;
      final session = Supabase.instance.client.auth.currentSession;
      
      if (user != null && session != null) {
        debugPrint('✅ Supabase automatically processed deep link!');
        debugPrint('   User ID: ${user.id}');
        debugPrint('   Email confirmed: ${user.emailConfirmedAt != null}');
        break;
      }
    }
    
    // STEP 2: Check if session was established automatically
    var user = Supabase.instance.client.auth.currentUser;
    var currentSession = Supabase.instance.client.auth.currentSession;
    
    // STEP 3: If not established automatically, manually process it
    if (user == null || currentSession == null) {
      debugPrint('⚠️ Session not established automatically, trying manual processing...');
      
      if (code != null) {
        // PKCE flow - exchange code for session
        debugPrint('🔑 Manually exchanging code for session (PKCE flow)...');
        try {
          final response = await Supabase.instance.client.auth.exchangeCodeForSession(code);
          
          if (response.session == null) {
            throw Exception('Failed to exchange code for session');
          }
          
          debugPrint('✅ Session established from PKCE code');
          debugPrint('   User ID: ${response.session!.user.id}');
          debugPrint('   Email confirmed: ${response.session!.user.emailConfirmedAt != null}');
          
          // Update references after manual processing
          user = Supabase.instance.client.auth.currentUser;
          currentSession = Supabase.instance.client.auth.currentSession;
        } catch (e) {
          debugPrint('❌ Failed to exchange code for session: $e');
          // If code exchange fails, the link might be expired
          if (e.toString().contains('expired') || e.toString().contains('invalid')) {
            throw Exception('Email verification link has expired. Please request a new verification email.');
          }
          throw Exception('Failed to establish session: $e');
        }
      } else if (accessToken != null && refreshToken != null) {
        // Direct token flow (shouldn't happen with PKCE, but handle it)
        debugPrint('🔑 Manually setting session from tokens (implicit flow)...');
        try {
          final response = await Supabase.instance.client.auth.setSession(accessToken);
          
          if (response.session == null) {
            throw Exception('Failed to establish session from deep link tokens');
          }
          
          debugPrint('✅ Session established from tokens');
          user = Supabase.instance.client.auth.currentUser;
          currentSession = Supabase.instance.client.auth.currentSession;
        } catch (e) {
          debugPrint('❌ Failed to set session from tokens: $e');
          throw Exception('Failed to establish session: $e');
        }
      } else {
        throw Exception('No authentication tokens or code found in deep link URL. The link may be invalid or expired.');
      }
    }
    
    // STEP 4: Verify all 3 conditions are true
    final sessionToken = currentSession?.accessToken;
    
    debugPrint('🔍 Email verification - Final auth state check:');
    debugPrint('   currentUser != null: ${user != null}');
    debugPrint('   currentSession != null: ${currentSession != null}');
    debugPrint('   accessToken != null: ${sessionToken != null}');
    if (user != null) {
      debugPrint('   User ID: ${user.id}');
      debugPrint('   Email confirmed at: ${user.emailConfirmedAt}');
    }
    
    // All 3 must be true for session to be established
    if (user == null || currentSession == null || sessionToken == null) {
      debugPrint('❌ Session not established after email verification');
      debugPrint('   Missing: user=${user == null}, session=${currentSession == null}, token=${sessionToken == null}');
      throw Exception('Session not established after email verification. Please try signing in again.');
    }
    
    // Verify that email is actually confirmed
    if (user.emailConfirmedAt == null) {
      debugPrint('⚠️ User authenticated but email not confirmed yet');
      throw Exception('Email verification incomplete. Please check your email and click the verification link.');
    }
    
    // Store user state in SharedPreferences — align with DB (returning users skip onboarding)
    final prefs = await SharedPreferences.getInstance();

    var hasCompletedPreferences = false;
    try {
      final row = await Supabase.instance.client
          .from('user_preferences')
          .select('has_completed_preferences')
          .eq('user_id', user.id)
          .maybeSingle();

      if (row != null && row['has_completed_preferences'] == true) {
        hasCompletedPreferences = true;
        debugPrint(
          '✅ Magic link: returning user — has_completed_preferences=true (synced to prefs)',
        );
      } else {
        debugPrint(
          '🆕 Magic link: new or incomplete onboarding — preferences flow needed',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Could not read has_completed_preferences: $e');
    }

    await prefs.setBool('hasCompletedPreferences', hasCompletedPreferences);
    // Do not overwrite has_completed_preferences in the DB here — respect server truth.

    await prefs.setBool('has_seen_onboarding', true); // CRITICAL: Mark onboarding as seen so router doesn't redirect back
    await prefs.setInt('last_auth_timestamp', DateTime.now().millisecondsSinceEpoch);
    
    debugPrint('✅ Email verification successful - all checks passed:');
    debugPrint('   ✅ currentUser != null');
    debugPrint('   ✅ currentSession != null');
    debugPrint('   ✅ accessToken != null');
    debugPrint('   ✅ Email confirmed');
    debugPrint('   ✅ hasCompletedPreferences (local) = $hasCompletedPreferences');
  } catch (e) {
    debugPrint('❌ Email verification error: $e');
    rethrow;
  }
}

// Helper function to check authentication state (supports bypass for testing)
Future<bool> _checkAuthenticationState() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // SIMPLIFIED: Only check Supabase auth state (no local flags needed)
    final user = Supabase.instance.client.auth.currentUser;
    final session = Supabase.instance.client.auth.currentSession;
    final isAuthenticated = user != null && session != null;
    
    debugPrint('🔍 Auth check - Supabase authenticated: $isAuthenticated');
    
    return isAuthenticated;
  } catch (e) {
    debugPrint('❌ Error checking authentication state: $e');
    return false;
  }
}

/// [keepAlive]: GoRouter must not be auto-disposed while the app runs — disposing it during
/// auth [StreamProvider] updates or hot restart can crash the VM worker (e.g. EXC_BAD_ACCESS).
@Riverpod(keepAlive: true)
GoRouter router(RouterRef ref) {
  // Drive router reevaluation from Riverpod updates directly.
  // Keeping this simple avoids notifier/listener lifecycle races on startup/hot-restart.
  final authStateSnapshot = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Splash and Onboarding
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // NEW ONBOARDING FLOW SCREENS (Feature Flag Controlled)
      // These screens are part of the new value-first onboarding experience
      GoRoute(
        path: '/intro',
        name: 'intro',
        builder: (context, state) => const AppIntroScreen(),
      ),
      GoRoute(
        path: '/demo',
        name: 'demo',
        builder: (context, state) => const MoodyDemoScreen(),
      ),
      // Legacy path from older onboarding; mood may still be in [guestDemoMoodProvider].
      GoRoute(
        path: '/guest-explore',
        redirect: (context, state) => '/demo',
      ),
      GoRoute(
        path: '/guest-day-plan',
        name: 'guest-day-plan',
        builder: (context, state) => const GuestDayPlanScreen(),
      ),
      GoRoute(
        path: '/auth/magic-link',
        name: 'magic-link',
        builder: (context, state) => const MagicLinkSignupScreen(),
      ),
      
      // Full Onboarding Flow (Authentication Required)
      GoRoute(
        path: '/preferences/communication',
        name: 'communication-preferences',
        builder: (context, state) {
          return const CommunicationPreferenceScreen();
        },
      ),
      // Mood-voorkeurscherm uit onboarding gehaald; oude links → interesses.
      GoRoute(
        path: '/preferences/mood',
        redirect: (context, state) => '/preferences/interests',
      ),
      GoRoute(
        path: '/preferences/interests',
        name: 'travel-interests',
        builder: (context, state) {
          final isAuthenticated = SupabaseConfig.auth.currentUser != null;
          if (!isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/auth/signup'));
            return const Scaffold(
              backgroundColor: _routerWmCream,
              body: Center(
                child: CircularProgressIndicator(color: _routerWmForest),
              ),
            );
          }
          return const TravelInterestsScreen();
        },
      ),
      GoRoute(
        path: '/preferences/travel-preferences',
        name: 'combined-travel-preferences',
        builder: (context, state) {
          final isAuthenticated = SupabaseConfig.auth.currentUser != null;
          if (!isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/auth/signup'));
            return const Scaffold(
              backgroundColor: _routerWmCream,
              body: Center(
                child: CircularProgressIndicator(color: _routerWmForest),
              ),
            );
          }
          return const CombinedTravelPreferencesScreen();
        },
      ),
      GoRoute(
        path: '/preferences/social-vibe',
        name: 'social-vibe',
        builder: (context, state) {
          final isAuthenticated = SupabaseConfig.auth.currentUser != null;
          if (!isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/auth/signup'));
            return const Scaffold(
              backgroundColor: _routerWmCream,
              body: Center(
                child: CircularProgressIndicator(color: _routerWmForest),
              ),
            );
          }
          return const SocialVibeScreen();
        },
      ),
      GoRoute(
        path: '/preferences/planning-pace',
        name: 'planning-pace',
        builder: (context, state) {
          final isAuthenticated = SupabaseConfig.auth.currentUser != null;
          if (!isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/auth/signup'));
            return const Scaffold(
              backgroundColor: _routerWmCream,
              body: Center(
                child: CircularProgressIndicator(color: _routerWmForest),
              ),
            );
          }
          return const PlanningPaceScreen();
        },
      ),
      GoRoute(
        path: '/preferences/style',
        name: 'travel-style',
        builder: (context, state) {
          final isAuthenticated = SupabaseConfig.auth.currentUser != null;
          if (!isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/auth/signup'));
            return const Scaffold(
              backgroundColor: _routerWmCream,
              body: Center(
                child: CircularProgressIndicator(color: _routerWmForest),
              ),
            );
          }
          return const TravelStyleScreen();
        },
      ),
      GoRoute(
        path: '/preferences/loading',
        name: 'preferences-loading',
        builder: (context, state) {
          final isAuthenticated = SupabaseConfig.auth.currentUser != null;
          if (!isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/auth/signup'));
            return const Scaffold(
              backgroundColor: _routerWmCream,
              body: Center(
                child: CircularProgressIndicator(color: _routerWmForest),
              ),
            );
          }
          return const OnboardingLoadingScreen();
        },
      ),
      
      // Authentication (magic link only — no password / email-password routes)
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const MagicLinkSignupScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        name: 'auth-signup',
        builder: (context, state) => const MagicLinkSignupScreen(),
      ),
      // email_verification archived — magic link only; redirect to signup
      GoRoute(
        path: '/auth/verify-email',
        name: 'verify-email',
        redirect: (context, state) => '/auth/magic-link',
      ),
      GoRoute(
        path: '/auth-callback',
        name: 'auth-callback',
        builder: (context, state) {
          // CRITICAL: Pass the URI to extract tokens from deep link
          return FutureBuilder(
            future: _handleEmailVerification(state.uri),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                final l10n = AppLocalizations.of(context);
                return Scaffold(
                  backgroundColor: _routerWmForest,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: _routerWmWhite),
                        const SizedBox(height: 16),
                        Text(
                          l10n?.authCallbackConfirmingEmail ?? 'Confirming your email…',
                          style: const TextStyle(
                            color: _routerWmWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              if (snapshot.hasError) {
                debugPrint('❌ Email verification error: ${snapshot.error}');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go('/auth/signup');
                });
                final l10n = AppLocalizations.of(context);
                return Scaffold(
                  backgroundColor: _routerWmCream,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: _routerWmError, size: 48),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            l10n?.authCallbackVerificationFailed ??
                                'Email verification failed. Please try again.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _routerWmCharcoal,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              debugPrint(
                '✅ Magic link verified — showing auth welcome, then preferences or main',
              );
              return const AuthWelcomeScreen();
            },
          );
        },
      ),
      
      // Main App Routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainScreen(),  // Fixed: Use MainScreen instead of standalone mood selection
      ),
      
      // Moody Experience (using standalone mood selection)
      GoRoute(
        path: '/moody',
        name: 'moody-standalone',
        builder: (context, state) => const MoodHomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const profile.UserProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/share-profile',
        name: 'share-profile',
        builder: (context, state) => const ShareProfileScreen(),
      ),
      GoRoute(
        path: '/profile/globe',
        name: 'globe',
        builder: (context, state) => const GlobeScreen(),
      ),
      GoRoute(
        path: '/mood',
        name: 'mood',
        builder: (context, state) => const MoodHomeScreen(),
      ),
      GoRoute(
        path: '/moods/history',
        name: 'mood-history',
        builder: (context, state) => const MoodHistoryScreen(),
      ),
      GoRoute(
        path: '/weather',
        name: 'weather',
        builder: (context, state) => const WeatherPage(),
      ),
      GoRoute(
        path: '/recommendations',
        name: 'recommendations',
        builder: (context, state) => const RecommendationsPage(),
      ),
      GoRoute(
        path: '/adventure-plan',
        name: 'adventure-plan',
        builder: (context, state) => const AdventurePlanScreen(),
      ),
      GoRoute(
        path: '/generate-plan',
        name: 'generate-plan',
        builder: (context, state) {
          final selectedMoods = state.extra as List<String>;
          return PlanLoadingScreen(
            selectedMoods: selectedMoods,
          );
        },
      ),
      GoRoute(
        path: '/day-plan',
        name: 'day-plan',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) return const DayPlanScreen(activities: [], selectedMoods: []);
          final activities = extra['activities'] as List<Activity>? ?? [];
          final moods = (extra['moods'] as List<dynamic>?)?.cast<String>() ?? <String>[];
          final moodyMessage = extra['moodyMessage'] as String? ?? '';
          final moodyReasoning = extra['moodyReasoning'] as String? ?? '';
          return DayPlanScreen(
            activities: activities,
            selectedMoods: moods,
            moodyMessage: moodyMessage,
            moodyReasoning: moodyReasoning,
          );
        },
      ),
      GoRoute(
        path: '/gamification',
        name: 'gamification',
        builder: (context, state) => const GamificationScreen(),
      ),
      GoRoute(
        path: '/group-planning',
        name: 'group-planning',
        pageBuilder: (context, state) => moodMatchTransitionPage<void>(
          key: state.pageKey,
          child: const GroupPlanningHubScreen(),
        ),
      ),
      GoRoute(
        path: '/group-planning/create',
        name: 'group-planning-create',
        pageBuilder: (context, state) => moodMatchTransitionPage<void>(
          key: state.pageKey,
          child: const GroupPlanningCreateScreen(),
        ),
      ),
      GoRoute(
        path: '/group-planning/lobby/:sessionId',
        name: 'group-planning-lobby',
        pageBuilder: (context, state) {
          final id = state.pathParameters['sessionId']!;
          final extra = state.extra;
          final joinCode = extra is Map<String, dynamic>
              ? extra['joinCode'] as String?
              : null;
          final autoShowInvite = extra is Map<String, dynamic>
              ? extra['autoShowInvite'] as bool? ?? false
              : false;
          return moodMatchTransitionPage<void>(
            key: state.pageKey,
            child: GroupPlanningLobbyScreen(
              sessionId: id,
              joinCode: joinCode,
              autoShowInvite: autoShowInvite,
            ),
          );
        },
      ),
      GoRoute(
        path: '/group-planning/invite-wm/:sessionId',
        name: 'group-planning-invite-wm',
        redirect: (context, state) {
          final extra = state.extra;
          final joinCode = extra is Map<String, dynamic>
              ? extra['joinCode'] as String?
              : null;
          if (joinCode == null || joinCode.trim().isEmpty) {
            return '/group-planning';
          }
          return null;
        },
        pageBuilder: (context, state) {
          final id = state.pathParameters['sessionId']!;
          final joinCode =
              (state.extra as Map<String, dynamic>)['joinCode'] as String;
          return moodMatchTransitionPage<void>(
            key: state.pageKey,
            child: GroupPlanningInviteWandererScreen(
              sessionId: id,
              joinCode: joinCode.trim(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/group-planning/scan',
        name: 'group-planning-scan',
        pageBuilder: (context, state) => moodMatchTransitionPage<void>(
          key: state.pageKey,
          child: const GroupPlanningScanScreen(),
        ),
      ),
      GoRoute(
        path: '/group-planning/join',
        name: 'group-planning-join',
        pageBuilder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return moodMatchTransitionPage<void>(
            key: state.pageKey,
            child: GroupPlanningJoinScreen(initialCode: code),
          );
        },
      ),
      GoRoute(
        path: '/group-planning/reveal/:sessionId',
        name: 'group-planning-reveal',
        pageBuilder: (context, state) {
          final id = state.pathParameters['sessionId']!;
          return moodMatchTransitionPage<void>(
            key: state.pageKey,
            child: GroupPlanningRevealScreen(sessionId: id),
          );
        },
      ),
      GoRoute(
        path: '/group-planning/result/:sessionId',
        name: 'group-planning-result',
        pageBuilder: (context, state) {
          final id = state.pathParameters['sessionId']!;
          return moodMatchTransitionPage<void>(
            key: state.pageKey,
            child: GroupPlanningResultScreen(sessionId: id),
          );
        },
      ),
      GoRoute(
        path: '/group-planning/day-picker/:sessionId',
        name: 'group-planning-day-picker',
        pageBuilder: (context, state) {
          final id = state.pathParameters['sessionId']!;
          return moodMatchTransitionPage<void>(
            key: state.pageKey,
            child: GroupPlanningDayPickerScreen(sessionId: id),
          );
        },
      ),
      GoRoute(
        path: '/group-planning/match-loading/:sessionId',
        name: 'group-planning-match-loading',
        pageBuilder: (context, state) {
          final id = state.pathParameters['sessionId']!;
          return moodMatchTransitionPage<void>(
            key: state.pageKey,
            child: GroupPlanningMatchLoadingScreen(sessionId: id),
          );
        },
      ),
      GoRoute(
        path: '/group-planning/time-picker/:sessionId',
        name: 'group-planning-time-picker',
        pageBuilder: (context, state) {
          final id = state.pathParameters['sessionId']!;
          final date = state.uri.queryParameters['date'] ?? '';
          return moodMatchTransitionPage<void>(
            key: state.pageKey,
            child: GroupPlanningTimePickerScreen(
              sessionId: id,
              plannedDate: date,
            ),
          );
        },
      ),
      GoRoute(
        path: '/group-planning/confirmation/:sessionId',
        name: 'group-planning-confirmation',
        pageBuilder: (context, state) {
          final id = state.pathParameters['sessionId']!;
          final date = state.uri.queryParameters['date'] ?? '';
          final slot = state.uri.queryParameters['slot'] ?? 'morning';
          return moodMatchTransitionPage<void>(
            key: state.pageKey,
            child: GroupPlanningConfirmationScreen(
              sessionId: id,
              scheduledDate: date,
              timeSlot: slot,
            ),
          );
        },
      ),
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) {
          // Tab index: query wins; default 0 when absent (do not force extra.tab or
          // MainScreen resets the bottom nav on every rebuild).
          final tabIndexStr = state.uri.queryParameters['tab'];
          final tabIndex = tabIndexStr != null ? int.tryParse(tabIndexStr) ?? 0 : 0;

          final mergedExtra = Map<String, dynamic>.from(
            (state.extra as Map<String, dynamic>?) ?? {},
          );
          if (state.uri.queryParameters.containsKey('tab')) {
            mergedExtra['tab'] = tabIndex;
          }
          final moodAction = state.uri.queryParameters['moodAction'];
          if (moodAction != null && moodAction.isNotEmpty) {
            mergedExtra['moodAction'] = moodAction;
          }

          return MainScreen(
            initialTabIndex: tabIndex,
            extra: mergedExtra.isEmpty ? null : mergedExtra,
          );
        },
      ),
      GoRoute(
        path: '/agenda',
        name: 'agenda',
        builder: (context, state) => const AgendaScreen(),
      ),
      GoRoute(
        path: '/view-receipt',
        name: 'view-receipt',
        builder: (context, state) {
          final activity = state.extra as Map<String, dynamic>;
          return ViewReceiptScreen(activity: activity);
        },
      ),
      // Social Feature Routes
      GoRoute(
        path: '/social/user-profile',
        name: 'user-profile',
        builder: (context, state) {
          // Get current user's ID and show their profile using the unified screen
          final currentUserId = ref.read(authStateProvider).maybeWhen(
            data: (user) => user?.id ?? 'user1', // fallback for demo
            orElse: () => 'user1',
          );
          return UnifiedProfileScreen(userId: currentUserId);
        },
      ),
      GoRoute(
        path: '/social/edit-profile',
        name: 'edit-social-profile',
        builder: (context, state) => const EditSocialProfileScreen(),
      ),
      GoRoute(
        path: '/social/create-post',
        name: 'create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/social/create-story',
        name: 'create-story',
        builder: (context, state) => const CreateStoryScreen(),
      ),
      GoRoute(
        path: '/social/post/:id',
        name: 'post-detail',
        builder: (context, state) {
          final postId = state.pathParameters['id']!;
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/social/profile/:id',
        name: 'social-profile',
        builder: (context, state) {
          final userId = state.pathParameters['id']!;
          return UnifiedProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/social/messages',
        name: 'messages',
        builder: (context, state) => const MessageHubScreen(),
      ),
      GoRoute(
        path: '/social/stories',
        name: 'view-stories',
        builder: (context, state) {
          final profiles = ref.read(socialProfilesProvider);
          final initialIndex = int.tryParse(
            state.uri.queryParameters['index'] ?? '0'
          ) ?? 0;
          return ViewStoryScreen(
            profiles: profiles,
            initialIndex: initialIndex,
          );
        },
      ),

      // Admin route - ONLY available in debug mode for App Store compliance
      if (kDebugMode)
        GoRoute(
          path: '/admin',
          name: 'admin',
          builder: (context, state) {
            // Lazy import to avoid loading admin screen in production
            return Scaffold(
              body: Center(
                child: Text(
                  AppLocalizations.of(context)!.devAdminScreenDisabled,
                ),
              ),
            );
          },
        ),
      
      // Settings and Support
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const ComprehensiveSettingsScreen(),
      ),
      
      // Privacy & Security Settings
      GoRoute(
        path: '/settings/account-security',
        name: 'account-security',
        builder: (context, state) => const AccountSecurityScreen(),
      ),
      GoRoute(
        path: '/settings/2fa',
        name: '2fa',
        builder: (context, state) => const TwoFactorAuthScreen(),
      ),
      GoRoute(
        path: '/settings/sessions',
        name: 'active-sessions',
        builder: (context, state) => const ActiveSessionsScreen(),
      ),
      GoRoute(
        path: '/settings/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      
      // App Settings
      GoRoute(
        path: '/settings/notifications',
        name: 'settings-notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationCentreScreen(),
      ),
      GoRoute(
        path: '/settings/location',
        name: 'location-settings',
        builder: (context, state) => const LocationSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/location/picker',
        name: 'location-picker',
        builder: (context, state) => const LocationPickerScreen(),
      ),
      GoRoute(
        path: '/settings/language',
        name: 'language-settings',
        builder: (context, state) => const LanguageSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/theme',
        name: 'theme-settings',
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      
      // More Settings
      GoRoute(
        path: '/settings/achievements',
        name: 'achievements-settings',
        builder: (context, state) => const AchievementsSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/subscription',
        name: 'subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/settings/premium-upgrade',
        name: 'premium-upgrade',
        builder: (context, state) => const PremiumUpgradeScreen(),
      ),
      GoRoute(
        path: '/settings/data',
        name: 'data-storage',
        builder: (context, state) => const DataStorageScreen(),
      ),
      GoRoute(
        path: '/settings/help',
        name: 'help-support',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      
      // Danger Zone
      GoRoute(
        path: '/settings/delete-account',
        name: 'delete-account',
        builder: (context, state) => const DeleteAccountScreen(),
      ),
      
      // Legacy routes
      GoRoute(
        path: '/settings/preferences',
        name: 'preferences',
        builder: (context, state) => const PreferencesScreen(),
      ),
      // Convenience route alias for /preferences
      GoRoute(
        path: '/preferences',
        redirect: (context, state) => '/settings/preferences',
      ),
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) => const SupportScreen(),
      ),
      
      // Places and Planning
      GoRoute(
        path: '/place/:id',
        name: 'place-detail',
        builder: (context, state) {
          final placeId = state.pathParameters['id']!;
          return PlaceDetailScreen(placeId: placeId);
        },
      ),
      GoRoute(
        path: '/places/saved',
        name: 'saved-places',
        builder: (context, state) => const SavedPlacesScreen(),
      ),
    ],
    redirect: (context, state) async {
      // Legacy WanderFeed / diary URLs (no GoRoutes — handled here so deep links don’t 404).
      final rawPath = state.uri.path;
      final path = rawPath.endsWith('/') && rawPath.length > 1
          ? rawPath.substring(0, rawPath.length - 1)
          : rawPath;
      if (path == '/social/discovery' ||
          path == '/travelers/discovery' ||
          path == '/diaries' ||
          path.startsWith('/diaries/')) {
        return '/main';
      }

      final authState = authStateSnapshot;
      final currentLocation = state.matchedLocation;
      
      debugPrint('🔍 Router redirect - Location: $currentLocation, Auth State: ${authState.runtimeType}');
      
      // Define route categories
      final isAuthPage = currentLocation == '/register' ||
                        currentLocation == '/auth/signup' ||
                        currentLocation == '/auth/verify-email' ||
                        currentLocation == '/auth/magic-link';
      
      final useNewFlow = ref.read(useNewOnboardingFlowProvider);
      
      final isOnboardingPage = currentLocation == '/onboarding' ||
                              currentLocation.startsWith('/preferences/');
      
      final isNewOnboardingPage = currentLocation == '/intro' ||
                                  currentLocation == '/demo' ||
                                  currentLocation == '/guest-day-plan' ||
                                  currentLocation == '/auth/magic-link';
      
      // Treat root reliably if matchedLocation and uri.path disagree (edge cases).
      final uriPath = state.uri.path.isEmpty ? '/' : state.uri.path;
      final isSplashPage = currentLocation == '/' || uriPath == '/';
      
      final isMainAppPage = currentLocation == '/home' || 
                           currentLocation == '/main' ||
                           currentLocation.startsWith('/mood') ||
                           currentLocation.startsWith('/weather') ||
                           currentLocation.startsWith('/recommendations') ||
                           currentLocation.startsWith('/profile') ||
                           currentLocation.startsWith('/settings') ||
                           currentLocation.startsWith('/place') ||
                           currentLocation.startsWith('/social') ||
                           currentLocation.startsWith('/group-planning');
      
      // Always allow splash screen
      if (isSplashPage) {
        return null;
      }
      
      // Always allow auth pages
      if (isAuthPage) {
        return null;
      }
      
      // Always allow new onboarding pages when feature flag is enabled
      // This allows users to access new onboarding even if they've seen old onboarding
      if (useNewFlow && isNewOnboardingPage) {
        debugPrint('✅ User is on new onboarding page - allowing navigation');
        return null;
      }
      
      // If new flow is enabled and user tries to access old onboarding, redirect to new flow
      if (useNewFlow && isOnboardingPage && currentLocation == '/onboarding') {
        debugPrint('🔄 Redirecting from old onboarding to new flow');
        return '/intro';
      }
      
      // CRITICAL: Always allow preferences pages - user is in onboarding flow
      // Don't redirect away from preferences even if there are temporary auth issues
      final isPreferencesPage = currentLocation.startsWith('/preferences/');
      if (isPreferencesPage) {
        debugPrint('✅ User is on preferences page - allowing navigation');
        return null; // Allow preferences flow to continue
      }
      
      // Always allow old onboarding page when feature flag is disabled
      if (!useNewFlow && isOnboardingPage) {
        debugPrint('✅ User is on old onboarding page - allowing navigation');
        return null;
      }
      
      // Handle auth state loading
      if (authState.isLoading) {
        debugPrint('⏳ Auth state loading, staying on current route');
        return null; // Stay on current route while loading
      }
      
      // Handle auth state error
      if (authState.hasError) {
        debugPrint('❌ Auth state error: ${authState.error}');
        // CRITICAL: Don't redirect away from preferences during auth errors (e.g., rate limiting)
        // User is in the middle of onboarding and should be allowed to continue
        if (!isAuthPage && !isSplashPage && !isPreferencesPage) {
          final useNewFlow = ref.read(useNewOnboardingFlowProvider);
          return useNewFlow ? '/intro' : '/onboarding';
        }
        return null;
      }
      
      // Get current user from auth state
      final currentUser = authState.asData?.value;
      final isAuthenticated = currentUser != null;
      
      debugPrint('🔍 Router redirect - User: ${currentUser?.id}, Authenticated: $isAuthenticated');
      
      // If not authenticated, redirect to onboarding (except for onboarding pages)
      if (!isAuthenticated) {
        // Check if user has seen onboarding before
        final prefs = await SharedPreferences.getInstance();
        final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
        
        debugPrint('🔍 Not authenticated - hasSeenOnboarding: $hasSeenOnboarding');
        
        // CACHE PROBLEM DETECTION: Only clear cache if there's a genuine inconsistency
        // Don't clear cache for users who legitimately completed onboarding but haven't authenticated yet
        // CRITICAL: Only clear cache if user claims to have completed everything AND
        // we can verify they were recently authenticated (indicating session expiry, not initial state)
        // Don't clear on temporary auth issues like rate limiting
        final hasCompletedPreferences = prefs.getBool('hasCompletedPreferences') ?? false;
        
        if (hasSeenOnboarding && hasCompletedPreferences) {
          // Check if there's a recent session timestamp to distinguish between:
          // 1. User was authenticated but session expired (clear cache)
          // 2. User never authenticated in this session (don't clear - might be rate limiting)
          final lastAuthTime = prefs.getInt('last_auth_timestamp');
          final now = DateTime.now().millisecondsSinceEpoch;
          final fiveMinutesAgo = now - (5 * 60 * 1000);
          
          if (lastAuthTime != null && lastAuthTime > fiveMinutesAgo) {
            // User was authenticated recently but now isn't - likely session expiry
            debugPrint('⚠️ Router detected cache problem: completed everything but no auth (recent auth detected)');
            debugPrint('🔧 Clearing problematic cache state...');
            await prefs.clear();
            debugPrint('✅ Cache cleared, redirecting to fresh onboarding');
            final useNewFlow = ref.read(useNewOnboardingFlowProvider);
            return useNewFlow ? '/intro' : '/onboarding';
          } else {
            // No recent auth - might be temporary issue, don't clear cache
            debugPrint('⚠️ User not authenticated but no recent auth detected - might be temporary (rate limiting?)');
            debugPrint('✅ Not clearing cache - redirecting to signup instead');
            if (!isAuthPage && !isOnboardingPage) {
              return '/auth/signup';
            }
          }
        } else if (hasSeenOnboarding && !hasCompletedPreferences) {
          debugPrint('✅ User has seen onboarding but not completed preferences - legitimate state');
        }
        
        // CRITICAL: Don't redirect away from preferences pages even if auth appears null
        // User might be in the middle of preferences onboarding with temporary auth issues
        final isPreferencesPage = currentLocation.startsWith('/preferences/');
        if (isPreferencesPage) {
          debugPrint('✅ User is on preferences page - allowing navigation despite auth state');
          return null; // Allow preferences flow to continue
        }
        
        if (hasSeenOnboarding) {
          // User has seen onboarding before but isn't authenticated
          // Send them to auth flow based on feature flag
          if (!isAuthPage && !isOnboardingPage && !isNewOnboardingPage) {
            debugPrint('❌ Not authenticated but has seen onboarding before');
            if (useNewFlow) {
              debugPrint('   Redirecting to magic link (NEW FLOW)');
              return '/auth/magic-link';
            } else {
              debugPrint('   Redirecting to signup (OLD FLOW)');
              return '/auth/signup';
            }
          }
        } else {
          // Fresh user who hasn't seen onboarding screens
          if (!isOnboardingPage && !isNewOnboardingPage) {
            debugPrint('❌ Not authenticated and fresh user, redirecting to onboarding');
            return useNewFlow ? '/intro' : '/onboarding';
          }
        }
        return null;
      }
      
      // User is authenticated - check onboarding and preferences completion
      if (isAuthenticated) {
        try {
          final prefs = await SharedPreferences.getInstance();
          
          // OPTIMIZED: Check SharedPreferences first (fast), then database as fallback
          // This reduces database calls while ensuring accuracy
          bool hasCompletedPreferences = prefs.getBool('hasCompletedPreferences') ?? false;
          
          // Only check database if flag is missing or if we're on a critical route
          // This prevents unnecessary database calls on every route change
          if (!hasCompletedPreferences || isMainAppPage || currentLocation == '/' || currentLocation == '/home' || currentLocation == '/main') {
            if (currentUser != null) {
              try {
                final response = await Supabase.instance.client
                    .from('user_preferences')
                    .select('has_completed_preferences')
                    .eq('user_id', currentUser.id)
                    .maybeSingle();
                
                if (response != null && response['has_completed_preferences'] == true) {
                  hasCompletedPreferences = true;
                  // Sync to local cache for future fast access
                  await prefs.setBool('hasCompletedPreferences', true);
                  debugPrint('✅ User has completed preferences in database - synced to local');
                } else {
                  hasCompletedPreferences = false;
                  // Sync to local cache for future fast access
                  await prefs.setBool('hasCompletedPreferences', false);
                  debugPrint('🆕 User has NOT completed preferences in database - forcing preferences flow');
                }
              } catch (e) {
                debugPrint('⚠️ Could not check preferences from database: $e');
                // Use existing local cache value if database check fails
                debugPrint('   Using cached value: $hasCompletedPreferences');
              }
            }
          } else {
            debugPrint('⚡ Using cached preferences flag (fast path)');
          }

          debugPrint('🔍 Authenticated user - hasCompletedPreferences: $hasCompletedPreferences, currentLocation: $currentLocation');

          // Check for bypass flag (e.g. onboarding shortcuts)
          final extra = state.extra as Map<String, dynamic>?;
          final bypassPreferences = extra?['bypass_preferences'] == true;
          
          if (bypassPreferences) {
            debugPrint('🚀 Bypass preferences flag detected - allowing navigation to main');
            return null;
          }

          // CRITICAL: Always enforce the full preferences onboarding flow for new users
          // This catches users who try to navigate to main app after magic link authentication
          if (!hasCompletedPreferences) {
            // Allow navigation within preferences flow
            if (currentLocation.startsWith('/preferences/')) {
              debugPrint('✅ User is in preferences flow - allowing navigation');
              return null;
            }
            
            // Block access to main app routes if preferences not completed
            if (isMainAppPage || currentLocation == '/' || currentLocation == '/home' || currentLocation == '/main') {
              debugPrint('🚫 Blocking access to main app - redirecting to preferences');
              return '/preferences/communication';
            }
            
            // For any other route, redirect to preferences
            debugPrint('🚫 User has not completed preferences - redirecting to preferences');
            return '/preferences/communication';
          }
          
          // If preferences are complete, allow main app
          debugPrint('✅ User has completed preferences - allowing navigation');
        } catch (e) {
          debugPrint('❌ Error checking preferences: $e');
          // On error, if user is trying to access main app, redirect to preferences
          if (isMainAppPage || currentLocation == '/' || currentLocation == '/home' || currentLocation == '/main') {
            debugPrint('🚫 Error checking preferences but on main app - redirecting to preferences');
            return '/preferences/communication';
          }
        }
      }
      
      // Allow the route
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Error: ${state.error}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    ),
  );
} 