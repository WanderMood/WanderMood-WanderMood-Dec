import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/adventure/presentation/screens/adventure_plan_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/places/presentation/screens/place_detail_screen.dart';
import '../../features/places/presentation/screens/saved_places_screen.dart';
import '../../features/mood/presentation/pages/mood_history_screen.dart';
import '../../features/plans/presentation/screens/travel_plans_screen.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/onboarding/presentation/screens/location_permission_screen.dart';
import '../../features/onboarding/presentation/screens/mood_preference_screen.dart';
import '../../features/onboarding/presentation/screens/travel_interests_screen.dart';
import '../../features/onboarding/presentation/screens/budget_preference_screen.dart';
import '../../features/onboarding/presentation/screens/travel_style_screen.dart';
import '../../features/onboarding/presentation/screens/preferences_summary_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_loading_screen.dart';
import '../../features/dev/reset_screen.dart';
import '../../features/plans/presentation/screens/plan_generation_screen.dart';
import '../../core/config/supabase_config.dart';
import '../../features/mood/presentation/pages/mood_page.dart';
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
import '../../features/gamification/presentation/screens/gamification_screen.dart';
import '../../features/social/presentation/screens/create_post_screen.dart';
import '../../features/social/presentation/screens/create_story_screen.dart';
import '../../features/social/presentation/screens/post_detail_screen.dart';
import '../../features/social/presentation/screens/social_profile_screen.dart';
import '../../features/social/presentation/screens/message_hub_screen.dart';
import '../../features/social/presentation/screens/view_story_screen.dart';
import '../../features/social/domain/providers/social_providers.dart';
import '../../features/social/presentation/screens/user_profile_screen.dart';
import '../../features/social/presentation/screens/edit_social_profile_screen.dart';

part 'router.g.dart';

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
      
      // Main App Routes
      GoRoute(
        path: '/home',
        name: 'home',
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
        builder: (context, state) => const MoodPage(),
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
          return PlanGenerationScreen(selectedMoods: selectedMoods);
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
          // Get tab index from query parameters, default to 0 if not provided
          final tabIndexStr = state.uri.queryParameters['tab'];
          final tabIndex = tabIndexStr != null ? int.tryParse(tabIndexStr) ?? 0 : 0;
          return MainScreen(initialTabIndex: tabIndex);
        },
      ),
      
      // Social Feature Routes
      GoRoute(
        path: '/social/user-profile',
        name: 'user-profile',
        builder: (context, state) => const UserProfileScreen(),
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
          return SocialProfileScreen(userId: userId);
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
    redirect: (context, state) {
      final isAuthenticated = SupabaseConfig.auth.currentUser != null;
      final isOnAuthPage = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/register' ||
                          state.matchedLocation == '/onboarding';
      
      // Always allow splash screen
      if (state.matchedLocation == '/') {
        return null;
      }
      
      // If not authenticated and not on auth page, go to login
      if (!isAuthenticated && !isOnAuthPage) {
        return '/login';
      }
      
      // If authenticated and on auth page, go to home
      if (isAuthenticated && isOnAuthPage) {
        return '/home';
      }
      
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