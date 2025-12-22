import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/features/home/presentation/screens/explore_screen.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_screen.dart';
import 'package:wandermood/features/plans/widgets/activity_detail_screen.dart';
import 'package:wandermood/features/home/presentation/screens/free_time_activities_screen.dart';
import 'package:wandermood/features/home/presentation/screens/mood_home_screen.dart';
import 'package:wandermood/features/home/providers/dynamic_my_day_provider.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/features/profile/presentation/widgets/profile_drawer.dart';
import 'package:wandermood/features/places/providers/moody_explore_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/utils/auth_helper.dart';

// Create a Provider for the tab controller
final mainTabProvider = StateProvider<int>((ref) => 0);

// Provider to check if user has seen Moody intro overlay
final _hasSeenIntroProvider = FutureProvider<bool>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_seen_moody_intro') ?? false;
  } catch (e) {
    return false;
  }
});

// Main Screen with bottom nav
class MainScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  final Map<String, dynamic>? extra;
  
  // Provider accessor for external control
  static StateProvider<int> get tabControllerProvider => mainTabProvider;
  
  const MainScreen({
    Key? key, 
    this.initialTabIndex = 0,
    this.extra,
  }) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    // Set the initial tab index in the provider - delayed to avoid lifecycle conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
              if (mounted) {
      // Check if we have a tab index from route parameters
      final tabFromExtra = widget.extra?['tab'] as int?;
        final finalTab = tabFromExtra ?? widget.initialTabIndex;
        debugPrint('🎯 MainScreen: Setting tab to $finalTab (extra: $tabFromExtra, initial: ${widget.initialTabIndex})');
        ref.read(mainTabProvider.notifier).state = finalTab;
        debugPrint('✅ MainScreen: Tab provider set to ${ref.read(mainTabProvider)}');
          
          // FIX #2: Delay prefetch until session is guaranteed (async, non-blocking)
          // User is authenticated, session established, preferences set - perfect timing
          _prefetchPlacesInBackground();
      }
      });
    });
  }
  
  /// Prefetch places in background for instant Explore screen
  /// 
  /// FIX #2: Delay prefetch until session is guaranteed
  /// Only runs if all 3 conditions are true:
  /// - currentUser != null
  /// - currentSession != null
  /// - accessToken != null
  /// 
  /// If prefetch fails, Explore will load on demand anyway
  Future<void> _prefetchPlacesInBackground() async {
    try {
      // FIX #2: Ensure session is valid before prefetch
      await AuthHelper.ensureValidSession();
      
      // FIX #2: Verify all 3 conditions are true
      final user = Supabase.instance.client.auth.currentUser;
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;
      
      debugPrint('🔑 Prefetch Auth Check (Fix #2):');
      debugPrint('   currentUser != null: ${user != null}');
      debugPrint('   currentSession != null: ${session != null}');
      debugPrint('   accessToken != null: ${token != null}');
      if (token != null) {
        debugPrint('   Token preview: ${token.substring(0, 20)}...');
      }
      
      // FIX #2: Only prefetch if ALL 3 are true
      if (user == null || session == null || token == null) {
        debugPrint('⚠️ Prefetch blocked: Missing auth state (user: ${user != null}, session: ${session != null}, token: ${token != null})');
        return;
      }
      
      debugPrint('✅ All auth checks passed - starting background prefetch...');
      
      // Non-blocking - don't await, let it run in background
      ref.read(moodyExploreAutoProvider.future).then((places) {
        debugPrint('✅ Background prefetch complete: ${places.length} places ready for Explore');
      }).catchError((e) {
        debugPrint('⚠️ Background prefetch failed: $e (Explore will load on demand)');
        // This is fine - Explore screen will load places when user navigates to it
      });
    } catch (e) {
      debugPrint('⚠️ Could not start background prefetch: $e');
      // Non-critical - Explore will load on demand
    }
  }
  
  @override
  void didUpdateWidget(MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the tab provider if initialTabIndex changes or if we have new extra data
    Future.microtask(() {
      if (mounted) {
        final tabFromExtra = widget.extra?['tab'] as int?;
        final shouldRefresh = widget.extra?['refresh'] as bool? ?? false;
        
        if (oldWidget.initialTabIndex != widget.initialTabIndex || tabFromExtra != null) {
          ref.read(mainTabProvider.notifier).state = tabFromExtra ?? widget.initialTabIndex;
        }
        
        // If refresh flag is set, invalidate providers to force refresh
        if (shouldRefresh) {
          ref.invalidate(cachedActivitySuggestionsProvider);
          ref.invalidate(todayActivitiesProvider);
        }
      }
    });
  }
  
  // Screens in the bottom navigation
  final List<Widget> screens = [
    const DynamicMyDayScreen(),  // My Day is now first - using dynamic screen
    const ExploreScreen(),
    const MoodHomeScreen(), // Moody tab now uses MoodHomeScreen
            const SizedBox.shrink(), // Placeholder - Feed is now a standalone route
            const SizedBox.shrink(), // Placeholder - Profile navigates directly to profile screen
  ];
  
  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(mainTabProvider);
    final dailyMoodState = ref.watch(dailyMoodStateNotifierProvider);
    final hasSeenIntroAsync = ref.watch(_hasSeenIntroProvider);
    
    // Get hasSeenIntro value from AsyncValue (default to false if loading/error)
    final hasSeenIntro = hasSeenIntroAsync.when(
      data: (value) => value,
      loading: () => false,
      error: (_, __) => false,
    );
    
    // Hide bottom nav ONLY when:
    // 1. On Moody tab (index 2)
    // 2. User hasn't selected a mood yet
    // 3. AND user hasn't seen the intro overlay yet (so they focus on intro)
    // Once intro is skipped/dismissed, show nav bar so user can navigate
    final shouldHideBottomNav = selectedIndex == 2 && 
                                 !dailyMoodState.hasSelectedMoodToday && 
                                 !hasSeenIntro;
    
    debugPrint('📱 MainScreen build: selectedIndex = $selectedIndex');
    debugPrint('📱 MainScreen build: showing screen ${screens[selectedIndex].runtimeType}');
    debugPrint('📱 MainScreen build: hasSeenIntro = $hasSeenIntro');
    debugPrint('📱 MainScreen build: shouldHideBottomNav = $shouldHideBottomNav');
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5), // Match app's beige background
      drawer: const ProfileDrawer(),
      extendBody: false, // Prevent body from extending behind bottom nav bar
      body: screens[selectedIndex],
      bottomNavigationBar: shouldHideBottomNav ? null : Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: true, // CRITICAL: Ensure nav bar extends to device bottom
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) {
              // Handle special cases for Feed and Profile
              if (index == 3) {
                // Navigate to Feed screen
                context.push('/diaries');
                return;
              } else if (index == 4) {
                // Navigate directly to Profile screen
                context.push('/profile');
                return;
              }
              
              // Update the tab provider for normal tabs
              ref.read(mainTabProvider.notifier).state = index;
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 10.0,
            unselectedFontSize: 10.0,
            iconSize: 20.0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'My Day',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.explore),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.mood),
                label: 'Moody',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'WanderFeed',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Profile menu removed - now navigates directly to profile screen
}
 