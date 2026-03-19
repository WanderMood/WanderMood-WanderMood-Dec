import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/features/home/presentation/screens/explore_screen.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_screen.dart';
import 'package:wandermood/features/plans/widgets/activity_detail_screen.dart';
import 'package:wandermood/features/home/presentation/screens/free_time_activities_screen.dart';
import 'package:wandermood/features/home/presentation/screens/mood_home_screen.dart';
import 'package:wandermood/features/home/presentation/screens/redesigned_moody_hub.dart';
import 'package:wandermood/features/social/presentation/screens/wanderfeed_coming_soon_screen.dart';
import 'package:wandermood/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/features/profile/presentation/widgets/profile_drawer.dart';
import 'package:wandermood/features/places/providers/moody_explore_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/utils/auth_helper.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:google_fonts/google_fonts.dart';

// Create a Provider for the tab controller
final mainTabProvider = StateProvider<int>((ref) => 0);

// Provider to check if user has seen Moody intro overlay
// Made public so it can be invalidated from MoodyHubScreen when intro is dismissed
final hasSeenIntroProvider = FutureProvider<bool>((ref) async {
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
  bool _hasPrefetched = false; // Prevent prefetch on hot reload
  
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
          
          // CRITICAL: Only prefetch once (not on hot reload)
          // User is authenticated, session established, preferences set - perfect timing
          if (!_hasPrefetched) {
            _hasPrefetched = true;
            _prefetchPlacesInBackground();
          }
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
          ref.invalidate(scheduledActivitiesForTodayProvider);
          ref.invalidate(cachedActivitySuggestionsProvider);
          ref.invalidate(todayActivitiesProvider);
        }
      }
    });
  }
  
  // Screens in the bottom navigation
  final List<Widget> screens = [
    const DynamicMyDayScreen(),
    const ExploreScreen(),
    const RedesignedMoodyHub(),
    const WanderFeedComingSoonScreen(),
    const UserProfileScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(mainTabProvider);
    final dailyMoodState = ref.watch(dailyMoodStateNotifierProvider);
    final hasSeenIntroAsync = ref.watch(hasSeenIntroProvider);
    
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
      extendBody: true, // Allow body to extend behind the floating nav bar
      body: screens[selectedIndex],
      bottomNavigationBar: shouldHideBottomNav
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), // Reduced bottom padding to 8
              child: SafeArea(
                top: false,
                bottom: false, // Keep false to manually control position
                child: Container(
                  padding: const EdgeInsets.only(top: 8, left: 6, right: 6, bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFF3F4F6), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildRegularNavItem(context, ref, selectedIndex, 0, 'My Day', Icons.calendar_today_outlined, Icons.calendar_today, const Color(0xFFF97316), const Color(0xFFFFF7ED)),
                      _buildRegularNavItem(context, ref, selectedIndex, 1, 'Explore', Icons.explore_outlined, Icons.explore, const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
                      _buildCenterMoodyButton(context, ref, selectedIndex),
                      _buildRegularNavItem(context, ref, selectedIndex, 3, 'WanderFeed', Icons.people_outline, Icons.people, const Color(0xFFA855F7), const Color(0xFFF5F3FF)),
                      _buildRegularNavItem(context, ref, selectedIndex, 4, 'Profile', Icons.person_outline, Icons.person, const Color(0xFFEC4899), const Color(0xFFFDF2F8)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildRegularNavItem(
    BuildContext context,
    WidgetRef ref,
    int selectedIndex,
    int index,
    String label,
    IconData icon,
    IconData selectedIcon,
    Color activeColor,
    Color activeBgColor,
  ) {
    final isSelected = selectedIndex == index;
    // Special handling: if we are on Explore (index 1), My Day (index 0) should NOT be highlighted.
    // The default logic `selectedIndex == index` handles this correctly, as selectedIndex will be 1.
    
    final onTap = () {
      ref.read(mainTabProvider.notifier).state = index;
    };

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? activeBgColor : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  size: 20,
                  color: isSelected ? activeColor : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? activeColor : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterMoodyButton(BuildContext context, WidgetRef ref, int selectedIndex) {
    final isSelected = selectedIndex == 2;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(mainTabProvider.notifier).state = 2,
        customBorder: const CircleBorder(),
        child: Transform.translate(
          offset: const Offset(0, -6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF12B347).withOpacity(0.12) : Colors.grey.shade100,
                  border: isSelected ? Border.all(color: const Color(0xFF12B347).withOpacity(0.4), width: 1.5) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: MoodyCharacter(
                    size: 28,
                    mood: isSelected ? 'happy' : 'default',
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Moody',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF059669) : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 