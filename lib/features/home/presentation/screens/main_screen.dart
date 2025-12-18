import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/home/presentation/screens/explore_screen.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_screen.dart';
import 'package:wandermood/features/plans/widgets/activity_detail_screen.dart';
import 'package:wandermood/features/home/presentation/screens/free_time_activities_screen.dart';
import 'package:wandermood/features/home/presentation/screens/mood_home_screen.dart';
import 'package:wandermood/features/home/providers/dynamic_my_day_provider.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';

// Create a Provider for the tab controller
final mainTabProvider = StateProvider<int>((ref) => 0);

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
      }
      });
    });
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
    
    // Hide bottom nav when on Moody tab (index 2) and user hasn't selected a mood yet
    final shouldHideBottomNav = selectedIndex == 2 && !dailyMoodState.hasSelectedMoodToday;
    
    debugPrint('📱 MainScreen build: selectedIndex = $selectedIndex');
    debugPrint('📱 MainScreen build: showing screen ${screens[selectedIndex].runtimeType}');
    debugPrint('📱 MainScreen build: shouldHideBottomNav = $shouldHideBottomNav');
    
    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: shouldHideBottomNav ? null : BottomNavigationBar(
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
        backgroundColor: Colors.white,
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
    );
  }

  // Profile menu removed - now navigates directly to profile screen
}
 