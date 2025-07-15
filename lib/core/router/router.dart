import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../../features/dev/reset_screen.dart';
import '../../features/plans/presentation/screens/plan_generation_screen.dart';
import '../../features/plans/presentation/screens/plan_loading_screen.dart';
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
import '../../features/mood/presentation/screens/standalone_mood_selection_screen.dart';  // Add standalone screen
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
import '../../features/social/presentation/screens/travel_diary_profile_screen.dart';
import '../../features/auth/providers/auth_state_provider.dart';
import '../providers/preferences_provider.dart';
import '../../admin/admin_screen.dart';

part 'router.g.dart';

// Helper function to handle email verification
Future<void> _handleEmailVerification() async {
  try {
    // Wait a moment for auth state to update
    await Future.delayed(const Duration(milliseconds: 500));
    
    final user = Supabase.instance.client.auth.currentUser;
    final session = Supabase.instance.client.auth.currentSession;
    
    debugPrint('🔍 Email verification - User: ${user?.id}, Session: ${session?.user?.id}');
    
    if (user != null && session != null) {
      // Store user state in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedAuth', true);
      await prefs.setBool('hasCompletedOnboarding', false);
      await prefs.setBool('hasCompletedPreferences', false);
      
      debugPrint('✅ Email verification successful, user authenticated');
    } else {
      throw Exception('User not authenticated after email verification');
    }
  } catch (e) {
    debugPrint('❌ Email verification error: $e');
    rethrow;
  }
}

// Helper function to check authentication state (supports bypass for testing)
Future<bool> _checkAuthenticationState() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if user has completed auth (either through Supabase or bypass)
    final hasCompletedAuth = prefs.getBool('hasCompletedAuth') ?? false;
    
    // Also check Supabase auth state
    final user = Supabase.instance.client.auth.currentUser;
    final session = Supabase.instance.client.auth.currentSession;
    final supabaseAuthenticated = user != null && session != null;
    
    debugPrint('🔍 Auth check - Local: $hasCompletedAuth, Supabase: $supabaseAuthenticated');
    
    // User is authenticated if either local flag is set OR Supabase auth is valid
    return hasCompletedAuth || supabaseAuthenticated;
  } catch (e) {
    debugPrint('❌ Error checking authentication state: $e');
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
          return FutureBuilder(
            future: _handleEmailVerification(),
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
                debugPrint('❌ Email verification error: ${snapshot.error}');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go('/login');
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
        builder: (context, state) => const StandaloneMoodSelectionScreen(),  // Use standalone version
      ),
      
      // Moody Experience (using standalone mood selection)
      GoRoute(
        path: '/moody',
        name: 'moody-standalone',
        builder: (context, state) => const StandaloneMoodSelectionScreen(),
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
        builder: (context, state) => const DiariesPlatformScreen(),
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
      
      // Admin (temporary for debugging)
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminScreen(),
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
      
      debugPrint('🔍 Router redirect - Location: $currentLocation, Auth State: ${authState.runtimeType}');
      
      // Define route categories
      final isAuthPage = currentLocation == '/login' || 
                        currentLocation == '/register' ||
                        currentLocation == '/auth/signup' ||
                        currentLocation == '/auth/verify-email';
      
      final isOnboardingPage = currentLocation == '/onboarding' ||
                              currentLocation.startsWith('/preferences/');
      
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
      
      // Handle auth state loading
      if (authState.isLoading) {
        debugPrint('⏳ Auth state loading, staying on current route');
        return null; // Stay on current route while loading
      }
      
      // Handle auth state error
      if (authState.hasError) {
        debugPrint('❌ Auth state error: ${authState.error}');
        if (!isAuthPage && !isSplashPage) {
          return '/onboarding';
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
        final hasCompletedAuth = prefs.getBool('hasCompletedAuth') ?? false;
        
        debugPrint('🔍 Not authenticated - hasSeenOnboarding: $hasSeenOnboarding, hasCompletedAuth: $hasCompletedAuth');
        
        // CACHE PROBLEM DETECTION: Only clear cache if there's a genuine inconsistency
        // Don't clear cache for users who legitimately completed onboarding but haven't authenticated yet
        if (hasSeenOnboarding && !hasCompletedAuth) {
          // Check if user has completed preferences too - if so, this might be a legitimate state
          // where they completed onboarding but need to authenticate
          final hasCompletedPreferences = prefs.getBool('hasCompletedPreferences') ?? false;
          
          // Only clear cache if user claims to have completed everything but has no auth
          // This indicates a genuine cache corruption issue
          if (hasCompletedPreferences) {
            debugPrint('⚠️ Router detected cache problem: completed everything but no auth');
            debugPrint('🔧 Clearing problematic cache state...');
            await prefs.clear();
            debugPrint('✅ Cache cleared, redirecting to fresh onboarding');
            return '/onboarding';
          } else {
            debugPrint('✅ User has seen onboarding but not completed preferences - legitimate state');
          }
        }
        
        if (hasSeenOnboarding) {
          // User has seen "Meet Moody" before but isn't authenticated
          // Send them to auth flow, not back to onboarding
          if (!isAuthPage && !isOnboardingPage) {
            debugPrint('❌ Not authenticated but has seen onboarding before, redirecting to signup');
            return '/auth/signup';
          }
        } else {
          // Fresh user who hasn't seen "Meet Moody" screens
          if (!isOnboardingPage) {
            debugPrint('❌ Not authenticated and fresh user, redirecting to onboarding');
            return '/onboarding';
          }
        }
        return null;
      }
      
      // User is authenticated - check onboarding and preferences completion
      if (isAuthenticated) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final hasCompletedPreferences = prefs.getBool('hasCompletedPreferences') ?? false;

          // Check for bypass flag from booking flow
          final extra = state.extra as Map<String, dynamic>?;
          final bypassPreferences = extra?['bypass_preferences'] == true;
          
          if (bypassPreferences) {
            debugPrint('🚀 Bypass preferences flag detected - allowing navigation to main');
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
          debugPrint('❌ Error checking preferences: $e');
          if (isMainAppPage) {
            return '/onboarding';
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