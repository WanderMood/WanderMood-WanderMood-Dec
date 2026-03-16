import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/core/providers/secure_storage_provider.dart';
import '../../features/adventure/presentation/screens/adventure_plan_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/communication_preference_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/places/presentation/screens/place_detail_screen.dart';
import '../../features/places/presentation/screens/saved_places_screen.dart';
import '../../features/mood/presentation/screens/mood_history_screen.dart';
import '../../features/plans/presentation/screens/travel_plans_screen.dart';
import '../../features/onboarding/presentation/screens/mood_preference_screen.dart';
import '../../features/onboarding/presentation/screens/travel_interests_screen.dart';
import '../../features/onboarding/presentation/screens/social_vibe_screen.dart';
import '../../features/onboarding/presentation/screens/planning_pace_screen.dart';
import '../../features/onboarding/presentation/screens/travel_style_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_loading_screen.dart';
// import '../../features/dev/reset_screen.dart'; // Removed - debug only
import '../../features/plans/presentation/screens/plan_generation_screen.dart';
import '../../features/plans/presentation/screens/plan_loading_screen.dart';
import '../../features/plans/presentation/screens/day_plan_screen.dart';
import '../../features/plans/domain/models/activity.dart';
import '../../core/config/supabase_config.dart';
// Removed mood_page.dart import - page has been archived
import '../../features/weather/presentation/pages/weather_page.dart';
import '../../features/recommendations/presentation/pages/recommendations_page.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/language_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/support/presentation/screens/support_screen.dart';
import '../../features/home/presentation/screens/mood_home_screen.dart';
import '../../features/home/presentation/screens/main_screen.dart';
import '../../features/home/presentation/screens/agenda_screen.dart';
import '../../features/home/presentation/screens/view_receipt_screen.dart';
import '../../features/home/presentation/screens/edit_activity_screen.dart';
import '../../features/gamification/presentation/screens/gamification_screen.dart';
import '../../features/social/presentation/screens/create_post_screen.dart';
import '../../features/social/presentation/screens/create_story_screen.dart';
import '../../features/social/presentation/screens/post_detail_screen.dart';
import '../../features/social/presentation/screens/unified_profile_screen.dart';
import '../../features/social/presentation/screens/message_hub_screen.dart';
import '../../features/social/presentation/screens/view_story_screen.dart';
import '../../features/social/domain/providers/social_providers.dart';
import '../../features/social/presentation/screens/user_profile_screen.dart';
import '../../features/social/presentation/screens/edit_social_profile_screen.dart';
import '../../features/social/presentation/screens/create_diary_entry_screen.dart';
import '../../features/social/presentation/screens/diary_detail_screen.dart';
import '../../features/social/presentation/screens/diaries_platform_screen.dart';
import '../../features/social/presentation/screens/wanderfeed_coming_soon_screen.dart';
import '../../features/social/presentation/screens/travel_diary_profile_screen.dart';
import '../../features/auth/providers/auth_state_provider.dart';
import '../../features/auth/presentation/screens/magic_link_signup_screen.dart';
import '../providers/preferences_provider.dart';
import '../providers/feature_flags_provider.dart';
import '../../features/onboarding/presentation/screens/app_intro_screen.dart';
import '../../features/onboarding/presentation/screens/moody_demo_screen.dart';
import '../../features/onboarding/presentation/screens/guest_explore_screen.dart';
import '../../features/dev/reset_onboarding_screen.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
// import '../../admin/admin_screen.dart'; // Removed - debug only

part 'router.g.dart';

// Helper function to handle email verification
// CRITICAL FIX: With PKCE flow, Supabase Flutter processes deep links automatically
// We need to wait for it to process, then verify the session
Future<void> _handleEmailVerification(Uri uri, Ref ref) async {
  try {
    if (kDebugMode) debugPrint('🔗 Processing email verification deep link...');
    if (kDebugMode) debugPrint('   Deep link URI: ${uri.toString()}');
    
    // CRITICAL: With PKCE flow, Supabase Flutter automatically processes the deep link
    // Extract tokens/code from URL to manually process if auto-processing fails
    final accessToken = uri.queryParameters['access_token'];
    final refreshToken = uri.queryParameters['refresh_token'];
    final code = uri.queryParameters['code']; // For PKCE flow
    final type = uri.queryParameters['type'];
    
    if (kDebugMode) debugPrint('   URL parameters:');
    if (kDebugMode) debugPrint('   access_token exists: ${accessToken != null}');
    if (kDebugMode) debugPrint('   refresh_token exists: ${refreshToken != null}');
    if (kDebugMode) debugPrint('   code exists: ${code != null}');
    if (kDebugMode) debugPrint('   type: $type');
    
    // STEP 1: Wait for Supabase Flutter to automatically process the deep link (PKCE flow)
    // CRITICAL: After email verification, app may restart, so we need more time for session restoration
    if (kDebugMode) debugPrint('⏳ Waiting for Supabase to automatically process deep link (PKCE)...');
    for (int i = 0; i < 20; i++) { // Increased from 10 to 20 (4 seconds total) to allow more time
      await Future.delayed(const Duration(milliseconds: 200));
      final user = Supabase.instance.client.auth.currentUser;
      final session = Supabase.instance.client.auth.currentSession;
      
      if (user != null && session != null) {
        if (kDebugMode) debugPrint('✅ Supabase automatically processed deep link!');
        if (kDebugMode) debugPrint('   User ID: ${user.id}');
        if (kDebugMode) debugPrint('   Email confirmed: ${user.emailConfirmedAt != null}');
        break;
      }
    }
    
    // STEP 2: Check if session was established automatically
    var user = Supabase.instance.client.auth.currentUser;
    var currentSession = Supabase.instance.client.auth.currentSession;
    
    // STEP 3: If not established automatically, manually process it
    if (user == null || currentSession == null) {
      if (kDebugMode) debugPrint('⚠️ Session not established automatically, trying manual processing...');
      
      if (code != null) {
        // PKCE flow - exchange code for session
        if (kDebugMode) debugPrint('🔑 Manually exchanging code for session (PKCE flow)...');
        try {
          final response = await Supabase.instance.client.auth.exchangeCodeForSession(code);
          
          if (response.session == null) {
            throw Exception('Failed to exchange code for session');
          }
          
          if (kDebugMode) debugPrint('✅ Session established from PKCE code');
          if (kDebugMode) debugPrint('   User ID: ${response.session!.user.id}');
          if (kDebugMode) debugPrint('   Email confirmed: ${response.session!.user.emailConfirmedAt != null}');
          
          // Update references after manual processing
          user = Supabase.instance.client.auth.currentUser;
          currentSession = Supabase.instance.client.auth.currentSession;
        } catch (e) {
          if (kDebugMode) debugPrint('❌ Failed to exchange code for session: $e');
          // If code exchange fails, the link might be expired
          if (e.toString().contains('expired') || e.toString().contains('invalid')) {
            throw Exception('Email verification link has expired. Please request a new verification email.');
          }
          throw Exception('Failed to establish session: $e');
        }
      } else if (accessToken != null && refreshToken != null) {
        // Direct token flow (shouldn't happen with PKCE, but handle it)
        if (kDebugMode) debugPrint('🔑 Manually setting session from tokens (implicit flow)...');
        try {
          final response = await Supabase.instance.client.auth.setSession(accessToken);
          
          if (response.session == null) {
            throw Exception('Failed to establish session from deep link tokens');
          }
          
          if (kDebugMode) debugPrint('✅ Session established from tokens');
          user = Supabase.instance.client.auth.currentUser;
          currentSession = Supabase.instance.client.auth.currentSession;
        } catch (e) {
          if (kDebugMode) debugPrint('❌ Failed to set session from tokens: $e');
          throw Exception('Failed to establish session: $e');
        }
      } else {
        throw Exception('No authentication tokens or code found in deep link URL. The link may be invalid or expired.');
      }
    }
    
    // STEP 4: Verify all 3 conditions are true
    final sessionToken = currentSession?.accessToken;
    
    if (kDebugMode) debugPrint('🔍 Email verification - Final auth state check:');
    if (kDebugMode) debugPrint('   currentUser != null: ${user != null}');
    if (kDebugMode) debugPrint('   currentSession != null: ${currentSession != null}');
    if (kDebugMode) debugPrint('   accessToken != null: ${sessionToken != null}');
    if (user != null) {
      if (kDebugMode) debugPrint('   User ID: ${user.id}');
      if (kDebugMode) debugPrint('   Email confirmed at: ${user.emailConfirmedAt}');
    }
    
    // All 3 must be true for session to be established
    if (user == null || currentSession == null || sessionToken == null) {
      if (kDebugMode) debugPrint('❌ Session not established after email verification');
      if (kDebugMode) debugPrint('   Missing: user=${user == null}, session=${currentSession == null}, token=${sessionToken == null}');
      throw Exception('Session not established after email verification. Please try signing in again.');
    }
    
    // Verify that email is actually confirmed
    if (user.emailConfirmedAt == null) {
      if (kDebugMode) debugPrint('⚠️ User authenticated but email not confirmed yet');
      throw Exception('Email verification incomplete. Please check your email and click the verification link.');
    }
    
    final secure = ref.read(secureStorageServiceProvider);
    await secure.setHasSeenOnboarding(true);
    await secure.setHasCompletedPreferences(false);
    await secure.setLastAuthTimestamp(DateTime.now().millisecondsSinceEpoch);
    
    if (kDebugMode) debugPrint('✅ Email verification successful - all checks passed:');
    if (kDebugMode) debugPrint('   ✅ currentUser != null');
    if (kDebugMode) debugPrint('   ✅ currentSession != null');
    if (kDebugMode) debugPrint('   ✅ accessToken != null');
    if (kDebugMode) debugPrint('   ✅ Email confirmed');
  } catch (e) {
    if (kDebugMode) debugPrint('❌ Email verification error: $e');
    rethrow;
  }
}

// Helper function to check authentication state (supports bypass for testing)
Future<bool> _checkAuthenticationState() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    final session = Supabase.instance.client.auth.currentSession;
    final isAuthenticated = user != null && session != null;
    
    if (kDebugMode) debugPrint('🔍 Auth check - Supabase authenticated: $isAuthenticated');
    
    return isAuthenticated;
  } catch (e) {
    if (kDebugMode) debugPrint('❌ Error checking authentication state: $e');
    return false;
  }
}

@riverpod
GoRouter router(RouterRef ref) {
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
      GoRoute(
        path: '/guest-explore',
        name: 'guest-explore',
        builder: (context, state) => const GuestExploreScreen(),
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
      GoRoute(
        path: '/preferences/mood',
        name: 'mood-preferences',
        builder: (context, state) {
          return const MoodPreferenceScreen();
        },
      ),
      GoRoute(
        path: '/preferences/interests',
        name: 'travel-interests',
        builder: (context, state) {
          final isAuthenticated = SupabaseConfig.auth.currentUser != null;
          if (!isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/auth/signup'));
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return const TravelInterestsScreen();
        },
      ),
      GoRoute(
        path: '/preferences/social-vibe',
        name: 'social-vibe',
        builder: (context, state) {
          final isAuthenticated = SupabaseConfig.auth.currentUser != null;
          if (!isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/auth/signup'));
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return const OnboardingLoadingScreen();
        },
      ),
      
      // Authentication
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        name: 'auth-signup',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/verify-email',
        name: 'verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/auth-callback',
        name: 'auth-callback',
        builder: (context, state) {
          // CRITICAL: Pass the URI to extract tokens from deep link
          return FutureBuilder(
            future: _handleEmailVerification(state.uri, ref),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Confirming your email...'),
                      ],
                    ),
                  ),
                );
              }
              
              if (snapshot.hasError) {
                if (kDebugMode) debugPrint('❌ Email verification error: ${snapshot.error}');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go('/auth/signup');
                });
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text('Email verification failed. Please try again.'),
                      ],
                    ),
                  ),
                );
              }
              
              // Success - navigate to preferences
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go('/preferences/communication');
              });
              
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 48),
                      SizedBox(height: 16),
                      Text('Email confirmed! Starting your personalized journey...'),
                    ],
                  ),
                ),
              );
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
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
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
            onLoadingComplete: () {
              // This callback is handled inside PlanLoadingScreen
            },
          );
        },
      ),
      GoRoute(
        path: '/day-plan',
        name: 'day-plan',
        builder: (context, state) {
          final activities = state.extra as List<Activity>;
          return DayPlanScreen(
            activities: activities,
          );
        },
      ),
      GoRoute(
        path: '/gamification',
        name: 'gamification',
        builder: (context, state) => const GamificationScreen(),
      ),
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) {
          // Get tab index from query parameters or extra data
          final tabIndexStr = state.uri.queryParameters['tab'];
          final tabIndex = tabIndexStr != null ? int.tryParse(tabIndexStr) ?? 0 : 0;
          
          // Get extra data if provided
          final extra = state.extra as Map<String, dynamic>?;
          
          return MainScreen(
            initialTabIndex: tabIndex,
            extra: extra,
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
      GoRoute(
        path: '/edit-activity',
        name: 'edit-activity',
        builder: (context, state) {
          final activity = state.extra as Map<String, dynamic>;
          return EditActivityScreen(activity: activity);
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
      
      // Diary Feature Routes
      GoRoute(
        path: '/diaries',
        name: 'diaries-platform',
        builder: (context, state) => const WanderFeedComingSoonScreen(),
      ),
      GoRoute(
        path: '/diaries/create-entry',
        name: 'create-diary-entry',
        builder: (context, state) => const CreateDiaryEntryScreen(),
      ),
      GoRoute(
        path: '/diaries/entry/:id',
        name: 'diary-detail',
        builder: (context, state) {
          final entryId = state.pathParameters['id']!;
          return DiaryDetailScreen(entryId: entryId);
        },
      ),
      GoRoute(
        path: '/diaries/profile/:userId',
        name: 'travel-diary-profile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final username = state.uri.queryParameters['username'];
          return TravelDiaryProfileScreen(userId: userId, username: username);
        },
      ),
      
      // Admin route - ONLY available in debug mode for App Store compliance
      if (kDebugMode)
        GoRoute(
          path: '/admin',
          name: 'admin',
          builder: (context, state) {
            // Lazy import to avoid loading admin screen in production
            return const Scaffold(
              body: Center(
                child: Text('Admin screen disabled in production builds'),
              ),
            );
          },
        ),
      
      // Dev route to reset onboarding (debug only)
      if (kDebugMode)
        GoRoute(
          path: '/dev/reset-onboarding',
          name: 'reset-onboarding',
          builder: (context, state) {
            return const ResetOnboardingScreen();
          },
        ),
      
      // Settings and Support
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings/language',
        name: 'language',
        builder: (context, state) => const LanguageScreen(),
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
      GoRoute(
        path: '/plans',
        name: 'travel-plans',
        builder: (context, state) => const TravelPlansScreen(),
      ),
    ],
    redirect: (context, state) async {
      final authState = ref.read(authStateProvider);
      final currentLocation = state.matchedLocation;
      
      if (kDebugMode) debugPrint('🔍 Router redirect - Location: $currentLocation, Auth State: ${authState.runtimeType}');
      
      // Define route categories
      final isAuthPage = currentLocation == '/login' || 
                        currentLocation == '/register' ||
                        currentLocation == '/auth/signup' ||
                        currentLocation == '/auth/verify-email';
      
      final useNewFlow = ref.read(useNewOnboardingFlowProvider);
      
      final isOnboardingPage = currentLocation == '/onboarding' ||
                              currentLocation.startsWith('/preferences/');
      
      final isNewOnboardingPage = currentLocation == '/intro' ||
                                  currentLocation == '/demo' ||
                                  currentLocation == '/guest-explore' ||
                                  currentLocation == '/auth/magic-link';
      
      final isSplashPage = currentLocation == '/';
      
      final isMainAppPage = currentLocation == '/home' || 
                           currentLocation == '/main' ||
                           currentLocation.startsWith('/mood') ||
                           currentLocation.startsWith('/weather') ||
                           currentLocation.startsWith('/recommendations') ||
                           currentLocation.startsWith('/profile') ||
                           currentLocation.startsWith('/settings') ||
                           currentLocation.startsWith('/place') ||
                           currentLocation.startsWith('/plans') ||
                           currentLocation.startsWith('/social');
      
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
        if (kDebugMode) debugPrint('✅ User is on new onboarding page - allowing navigation');
        return null;
      }
      
      // If new flow is enabled and user tries to access old onboarding, redirect to new flow
      if (useNewFlow && isOnboardingPage && currentLocation == '/onboarding') {
        if (kDebugMode) debugPrint('🔄 Redirecting from old onboarding to new flow');
        return '/intro';
      }
      
      // CRITICAL: Always allow preferences pages - user is in onboarding flow
      // Don't redirect away from preferences even if there are temporary auth issues
      final isPreferencesPage = currentLocation.startsWith('/preferences/');
      if (isPreferencesPage) {
        if (kDebugMode) debugPrint('✅ User is on preferences page - allowing navigation');
        return null; // Allow preferences flow to continue
      }
      
      // Always allow old onboarding page when feature flag is disabled
      if (!useNewFlow && isOnboardingPage) {
        if (kDebugMode) debugPrint('✅ User is on old onboarding page - allowing navigation');
        return null;
      }
      
      // Handle auth state loading
      if (authState.isLoading) {
        if (kDebugMode) debugPrint('⏳ Auth state loading, staying on current route');
        return null; // Stay on current route while loading
      }
      
      // Handle auth state error
      if (authState.hasError) {
        if (kDebugMode) debugPrint('❌ Auth state error: ${authState.error}');
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
      
      if (kDebugMode) debugPrint('🔍 Router redirect - User: ${currentUser?.id}, Authenticated: $isAuthenticated');
      
      if (!isAuthenticated) {
        final secure = ref.read(secureStorageServiceProvider);
        final hasSeenOnboarding = await secure.getHasSeenOnboarding();
        final hasCompletedPreferences = await secure.getHasCompletedPreferences();

        if (hasSeenOnboarding && hasCompletedPreferences) {
          final lastAuthTime = await secure.getLastAuthTimestamp();
          final now = DateTime.now().millisecondsSinceEpoch;
          final fiveMinutesAgo = now - (5 * 60 * 1000);

          if (lastAuthTime != null && lastAuthTime > fiveMinutesAgo) {
            await secure.clearAuthSensitive();
            final useNewFlow = ref.read(useNewOnboardingFlowProvider);
            return useNewFlow ? '/intro' : '/onboarding';
          } else {
            if (!isAuthPage && !isOnboardingPage) {
              return '/auth/signup';
            }
          }
        }
        
        // CRITICAL: Don't redirect away from preferences pages even if auth appears null
        // User might be in the middle of preferences onboarding with temporary auth issues
        final isPreferencesPage = currentLocation.startsWith('/preferences/');
        if (isPreferencesPage) {
          if (kDebugMode) debugPrint('✅ User is on preferences page - allowing navigation despite auth state');
          return null; // Allow preferences flow to continue
        }
        
        if (hasSeenOnboarding) {
          // User has seen onboarding before but isn't authenticated
          // Send them to auth flow based on feature flag
          if (!isAuthPage && !isOnboardingPage && !isNewOnboardingPage) {
            if (kDebugMode) debugPrint('❌ Not authenticated but has seen onboarding before');
            if (useNewFlow) {
              if (kDebugMode) debugPrint('   Redirecting to magic link (NEW FLOW)');
              return '/auth/magic-link';
            } else {
              if (kDebugMode) debugPrint('   Redirecting to signup (OLD FLOW)');
              return '/auth/signup';
            }
          }
        } else {
          // Fresh user who hasn't seen onboarding screens
          if (!isOnboardingPage && !isNewOnboardingPage) {
            if (kDebugMode) debugPrint('❌ Not authenticated and fresh user, redirecting to onboarding');
            return useNewFlow ? '/intro' : '/onboarding';
          }
        }
        return null;
      }
      
      if (isAuthenticated) {
        try {
          final secure = ref.read(secureStorageServiceProvider);
          final hasCompletedPreferences = await secure.getHasCompletedPreferences();

          // Check for bypass flag from booking flow
          final extra = state.extra as Map<String, dynamic>?;
          final bypassPreferences = extra?['bypass_preferences'] == true;
          
          if (bypassPreferences) {
            if (kDebugMode) debugPrint('🚀 Bypass preferences flag detected - allowing navigation to main');
            return null;
          }

          // Always enforce the full preferences onboarding flow for new users
          if (!hasCompletedPreferences) {
            if (!currentLocation.startsWith('/preferences/')) {
              return '/preferences/communication';
            }
            // Allow navigation within preferences
            return null;
          }
          // If preferences are complete, allow main app
        } catch (e) {
          if (kDebugMode) debugPrint('❌ Error checking preferences: $e');
          if (isMainAppPage) {
            final useNewFlow = ref.read(useNewOnboardingFlowProvider);
            return useNewFlow ? '/intro' : '/onboarding';
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