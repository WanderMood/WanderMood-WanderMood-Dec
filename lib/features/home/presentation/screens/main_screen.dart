import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/features/home/presentation/screens/explore_screen.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_screen.dart';
import 'package:wandermood/features/home/presentation/screens/redesigned_moody_hub.dart';
import 'package:wandermood/features/home/presentation/screens/moody_idle_screen.dart';
import 'package:wandermood/core/utils/moody_idle_checker.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart' show scheduledActivitiesForTodayProvider, todayActivitiesProvider, cachedActivitySuggestionsProvider;
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/features/profile/presentation/widgets/profile_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:google_fonts/google_fonts.dart';

// v2 bottom nav — Screen 11 (active = wmForest, pill bg = wmForestTint)
const Color _navWmForest = Color(0xFF2A6049);
const Color _navWmForestTint = Color(0xFFEBF3EE);

// Create a Provider for the tab controller
final mainTabProvider = StateProvider<int>((ref) => 0);

/// Bottom tabs: 0 My Day, 1 Explore, 2 Moody, 3 Profile (WanderFeed removed from bar).
/// Legacy: old Profile was index 4 → 3.
int normalizeMainTabIndex(int tab) {
  if (tab < 0) return 0;
  if (tab == 4) return 3;
  if (tab > 3) return 3;
  return tab;
}

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
  bool _idleGateCompleted = false;

  @override
  void initState() {
    super.initState();
    // Set the initial tab index in the provider - delayed to avoid lifecycle conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future(() async {
        if (!mounted) return;
        // Check if we have a tab index from route parameters
        final tabFromExtra = widget.extra?['tab'] as int?;
        final rawTab = tabFromExtra ?? widget.initialTabIndex;
        final finalTab = normalizeMainTabIndex(rawTab);
        debugPrint(
            '🎯 MainScreen: Setting tab to $finalTab (raw: $rawTab, extra: $tabFromExtra, initial: ${widget.initialTabIndex})');
        ref.read(mainTabProvider.notifier).state = finalTab;
        debugPrint('✅ MainScreen: Tab provider set to ${ref.read(mainTabProvider)}');

        // Places / Explore: no prefetch on launch — cache-first; Explore loads on open (Google Places prompt).

        await _showMoodyIdleGateIfNeeded();
      });
    });
  }

  /// After 30+ min away, full-screen Moody idle; then timestamps next session baseline.
  Future<void> _showMoodyIdleGateIfNeeded() async {
    if (!mounted || _idleGateCompleted) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      await MoodyIdleChecker.recordAppOpen();
      _idleGateCompleted = true;
      return;
    }

    final showIdle = await MoodyIdleChecker.shouldShowIdleScreen();
    if (!mounted) return;

    if (showIdle) {
      final idleState = MoodyIdleChecker.getIdleState();
      String? topInterest;
      try {
        final row = await Supabase.instance.client
            .from('user_preference_patterns')
            .select('top_rated_activities')
            .eq('user_id', user.id)
            .maybeSingle();
        if (row != null) {
          final list = row['top_rated_activities'] as List<dynamic>?;
          if (list != null && list.isNotEmpty) {
            topInterest = list.first.toString();
          }
        }
      } catch (e) {
        debugPrint('⚠️ Idle gate: preference patterns skipped: $e');
      }

      final prefs = ref.read(preferencesProvider);
      final prefsMap = <String, dynamic>{
        'communication_style': prefs.communicationStyle,
        'selected_moods': prefs.selectedMoods,
        'travel_interests': prefs.travelInterests,
        'planning_pace': prefs.planningPace,
        'budget_level': prefs.budgetLevel,
        'home_base': prefs.homeBase,
        'travel_styles': prefs.travelStyles,
      };

      if (mounted) {
        try {
          await Navigator.of(context).push<void>(
            PageRouteBuilder<void>(
              opaque: true,
              fullscreenDialog: true,
              pageBuilder: (ctx, _, __) => MoodyIdleScreen(
                idleState: idleState,
                userPreferences: prefsMap,
                topInterest: topInterest,
                onComplete: () => Navigator.of(ctx).pop(),
              ),
            ),
          );
        } catch (e, st) {
          debugPrint('⚠️ Idle gate push failed: $e\n$st');
        }
      }
    }

    await MoodyIdleChecker.recordAppOpen();
    _idleGateCompleted = true;
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
          final raw = tabFromExtra ?? widget.initialTabIndex;
          ref.read(mainTabProvider.notifier).state = normalizeMainTabIndex(raw);
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
  
  // Screens in the bottom navigation (WanderFeed removed from bar; route /diaries unchanged)
  final List<Widget> screens = [
    const DynamicMyDayScreen(),
    const ExploreScreen(),
    const RedesignedMoodyHub(),
    const UserProfileScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    final rawTabIndex = ref.watch(mainTabProvider);
    final selectedIndex = normalizeMainTabIndex(rawTabIndex);
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
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F0E8), // wmCream — QA / design system
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
                        border: Border.all(color: const Color(0xFFE8E2D8), width: 1), // wmParchment
                        boxShadow: const [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildRegularNavItem(context, ref, selectedIndex, 0, 'My Day', Icons.calendar_today_outlined, Icons.calendar_today, _navWmForest, _navWmForestTint),
                          _buildRegularNavItem(context, ref, selectedIndex, 1, 'Explore', Icons.explore_outlined, Icons.explore, _navWmForest, _navWmForestTint),
                          _buildCenterMoodyButton(context, ref, selectedIndex),
                          _buildRegularNavItem(context, ref, selectedIndex, 3, 'Profile', Icons.person_outline, Icons.person, _navWmForest, _navWmForestTint),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
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
      // Refresh My Day data whenever the user navigates to it so newly added
      // activities (e.g. from Explore) always reflect the correct status.
      if (index == 0) {
        ref.invalidate(scheduledActivitiesForTodayProvider);
        ref.invalidate(todayActivitiesProvider);
      }
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
                  color: isSelected ? _navWmForestTint : Colors.grey.shade100,
                  border: isSelected ? Border.all(color: _navWmForest.withOpacity(0.4), width: 1.5) : null,
                  boxShadow: const [],
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
                  color: isSelected ? _navWmForest : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 