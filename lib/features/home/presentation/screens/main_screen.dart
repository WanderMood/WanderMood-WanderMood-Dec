import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/features/home/presentation/screens/explore_screen.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_screen.dart';
import 'package:wandermood/features/home/presentation/screens/redesigned_moody_hub.dart';
import 'package:wandermood/features/home/presentation/screens/moody_idle_screen.dart';
import 'package:wandermood/core/utils/moody_idle_checker.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/features/social/presentation/screens/wanderfeed_coming_soon_screen.dart';
import 'package:wandermood/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/features/profile/presentation/widgets/profile_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/home/presentation/widgets/hoe_was_je_dag_sheet.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:google_fonts/google_fonts.dart';

// v2 bottom nav — Screen 11 (active = wmForest, pill bg = wmForestTint)
const Color _navWmForest = Color(0xFF2A6049);
const Color _navWmForestTint = Color(0xFFEBF3EE);

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
        final finalTab = tabFromExtra ?? widget.initialTabIndex;
        debugPrint(
            '🎯 MainScreen: Setting tab to $finalTab (extra: $tabFromExtra, initial: ${widget.initialTabIndex})');
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

  /// Debug-only: open any [MoodyIdleState] for UI review (stripped from release).
  Future<void> _showMoodyIdleStatePreviewPicker(BuildContext context) async {
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

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Preview Moody idle (debug)',
                  style: Theme.of(sheetCtx).textTheme.titleMedium,
                ),
              ),
              for (final s in MoodyIdleState.values)
                ListTile(
                  title: Text(s.name),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    Navigator.of(context).push<void>(
                      PageRouteBuilder<void>(
                        opaque: true,
                        fullscreenDialog: true,
                        pageBuilder: (ctx, _, __) => MoodyIdleScreen(
                          idleState: s,
                          userPreferences: prefsMap,
                          topInterest: null,
                          afternoonInterestCategory:
                              s == MoodyIdleState.afternoon ? 'food' : null,
                          onComplete: () => Navigator.of(ctx).pop(),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// Debug-only: open [HoeWasJeDagSheet] without 20:00 / DB gates (stripped from release).
  Future<void> _showHoeWasJeDagDebugPreview(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('HoeWasJeDag debug: no signed-in user');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to preview Hoe was je dag')),
        );
      }
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      useSafeArea: true,
      builder: (sheetContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: HoeWasJeDagSheet(
            completedActivities: const [
              'Debug: museum bezoek',
              'Debug: avondwandeling',
            ],
            userId: user.id,
          ),
        );
      },
    );
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
                          _buildRegularNavItem(context, ref, selectedIndex, 3, 'WanderFeed', Icons.people_outline, Icons.people, _navWmForest, _navWmForestTint),
                          _buildRegularNavItem(context, ref, selectedIndex, 4, 'Profile', Icons.person_outline, Icons.person, _navWmForest, _navWmForestTint),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        if (kDebugMode)
          Positioned(
            right: 8,
            bottom: shouldHideBottomNav ? 16 : 88,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF2A6049).withValues(alpha: 0.92),
                  child: InkWell(
                    onTap: () => _showMoodyIdleStatePreviewPicker(context),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bedtime_outlined, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Idle',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF4A4640).withValues(alpha: 0.92),
                  child: InkWell(
                    onTap: () => _showHoeWasJeDagDebugPreview(context),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.nightlight_round, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'EOD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
 