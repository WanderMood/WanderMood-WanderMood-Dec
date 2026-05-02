import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/features/home/presentation/screens/explore_screen.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_screen.dart';
import 'package:wandermood/features/home/presentation/screens/redesigned_moody_hub.dart';
import 'package:wandermood/features/home/presentation/screens/moody_idle_screen.dart';
import 'package:wandermood/core/notifications/engagement_in_app_nudges.dart';
import 'package:wandermood/core/utils/moody_idle_checker.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:wandermood/features/home/presentation/screens/agenda_screen.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart' show scheduledActivitiesForTodayProvider, todayActivitiesProvider, cachedActivitySuggestionsProvider, selectedMyDayDateProvider;
import 'package:wandermood/features/profile/presentation/widgets/profile_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/services/connectivity_service.dart';
import 'package:wandermood/core/providers/notification_provider.dart';
import 'package:wandermood/features/home/presentation/main_app_tour.dart';
import 'package:wandermood/features/home/presentation/providers/main_navigation_provider.dart';

// v2 bottom nav — Screen 11 (active = wmForest, pill bg = wmForestTint)
const Color _navWmForest = Color(0xFF2A6049);
const Color _navWmForestTint = Color(0xFFEBF3EE);
const Color _wmSkyTint = Color(0xFFEDF5F9);
const Color _wmSky = Color(0xFFA8C8DC);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmDusk = Color(0xFF4A4640);
const Color _wmStone = Color(0xFF8C8780);

// Provider to check if user has seen Moody intro overlay
// Made public so it can be invalidated from the Moody tab when intro is dismissed
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
  bool _moodCheckInDeepLinkConsumed = false;
  bool _showWeekendBanner = false;
  DateTime? _weekendSaturday;
  DateTime? _weekendSunday;
  bool _weekendBannerDismissed = false;
  final List<GlobalKey> _mainTourNavKeys =
      List<GlobalKey>.generate(5, (_) => GlobalKey());
  final List<GlobalKey> _mainTourContentKeys =
      List<GlobalKey>.generate(5, (_) => GlobalKey());
  bool _mainTourShowing = false;

  /// Built once so tab state is preserved; keys wire the interactive main app tour.
  late final List<Widget> _tabScreens = [
    DynamicMyDayScreen(mainAppTourContentKey: _mainTourContentKeys[0]),
    ExploreScreen(mainAppTourContentKey: _mainTourContentKeys[1]),
    RedesignedMoodyHub(mainAppTourContentKey: _mainTourContentKeys[2]),
    AgendaScreen(mainAppTourContentKey: _mainTourContentKeys[3]),
    UserProfileScreen(mainAppTourContentKey: _mainTourContentKeys[4]),
  ];

  /// Tabs the user has opened at least once — kept in the tree with [Offstage]
  /// so switching back (e.g. Moody) does not rebuild from scratch every tap.
  final Set<int> _mountedTabIndices = <int>{};

  /// Align [mainTabProvider] with [widget.initialTabIndex] / [widget.extra]
  /// without clobbering an in-session tab (e.g. Profile) when GoRouter
  /// rebuilds [MainScreen] with default `initialTabIndex: 0`.
  void _applyMainTabFromRoute() {
    final tabFromExtra = widget.extra?['tab'] as int?;
    final rawTab = tabFromExtra ?? widget.initialTabIndex;
    final finalTab = normalizeMainTabIndex(rawTab);
    final currentTab = ref.read(mainTabProvider);
    final hasExplicitOverride =
        tabFromExtra != null || widget.initialTabIndex != 0;
    if (hasExplicitOverride || currentTab == 0) {
      ref.read(mainTabProvider.notifier).state = finalTab;
    }
  }

  void _tryConsumeMoodCheckInDeepLink() {
    final action = widget.extra?['moodAction'] as String?;
    if (action != 'moodCheckIn' || _moodCheckInDeepLinkConsumed) return;
    if (!mounted) return;
    final tab = normalizeMainTabIndex(ref.read(mainTabProvider));
    if (tab != 2) return;
    _moodCheckInDeepLinkConsumed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.pushNamed('moody-standalone');
    });
  }

  void _applyTargetDateFromExtra() {
    final targetDateString = widget.extra?['targetDate'] as String?;
    final parsedTargetDate =
        targetDateString != null ? DateTime.tryParse(targetDateString) : null;
    if (parsedTargetDate != null) {
      final dateOnly = DateTime(
        parsedTargetDate.year,
        parsedTargetDate.month,
        parsedTargetDate.day,
      );
      ref.read(selectedMyDayDateProvider.notifier).state = dateOnly;
    }
  }

  static bool _tabExtraChanged(
    Map<String, dynamic>? oldExtra,
    Map<String, dynamic>? newExtra,
  ) {
    return oldExtra?['tab'] != newExtra?['tab'];
  }

  @override
  void initState() {
    super.initState();
    final initialTab = normalizeMainTabIndex(
      widget.extra?['tab'] as int? ?? widget.initialTabIndex,
    );
    _mountedTabIndices.add(initialTab);
    // Defer provider writes: Riverpod forbids modifying providers during
    // mount/build (throws from StateNotifier). didUpdateWidget uses the same pattern.
    Future.microtask(() {
      if (!mounted) return;
      _applyMainTabFromRoute();
      _applyTargetDateFromExtra();
      _tryConsumeMoodCheckInDeepLink();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future(() async {
        if (!mounted) return;
        await _showMoodyIdleGateIfNeeded();
        await _checkForWeekendSuggestion();
        if (!mounted) return;
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          final prefsEng = ref.read(preferencesProvider);
          await EngagementInAppNudges.runAfterMainVisible(
            userId: uid,
            locale: Localizations.localeOf(context),
            homeBase: prefsEng.homeBase,
          );
        }
        if (!mounted) return;
        await _maybeShowMainAppTourAuto();
      });
    });
  }

  Future<void> _maybeShowMainAppTourAuto() async {
    if (!mounted || _mainTourShowing) return;
    final done = await isMainAppTourCompleted();
    if (!mounted || done) return;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || _mainTourShowing) return;
    _presentMainAppTour();
  }

  void _presentMainAppTour() {
    if (_mainTourShowing || !mounted) return;
    setState(() => _mainTourShowing = true);
    showMainAppTour(
      context: context,
      ref: ref,
      contentKeys: _mainTourContentKeys,
      onSessionEnd: () {
        _mainTourShowing = false;
        if (mounted) setState(() {});
      },
    );
  }

  /// First open in morning (06–12) or evening (17–22) each day: full-screen idle gate;
  /// then timestamps next session baseline.
  Future<void> _showMoodyIdleGateIfNeeded() async {
    if (!mounted || _idleGateCompleted) return;

    if (ref.read(suppressMoodyIdleOnceProvider)) {
      ref.read(suppressMoodyIdleOnceProvider.notifier).state = false;
      await MoodyIdleChecker.recordAppOpen();
      _idleGateCompleted = true;
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      await MoodyIdleChecker.recordAppOpen();
      _idleGateCompleted = true;
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final decision = await MoodyIdleChecker.evaluateIdleGate(l10n);
    if (!mounted) return;

    if (decision != null) {
      await MoodyIdleChecker.ensureFirstInstallLocalDayIfMissing();
      final idleState = decision.visualState;
      var hasPlan = false;
      try {
        final acts = await ref.read(scheduledActivitiesForTodayProvider.future);
        hasPlan = acts.isNotEmpty;
      } catch (_) {}
      final wakeMessage =
          hasPlan ? l10n.moodyIdleWakeOpenPlan : l10n.moodyIdleWakeChooseMood;
      String? topInterest;
      try {
        final row = await Supabase.instance.client
            .from('user_preference_patterns')
            // Avoid hardcoding columns; some environments may diverge.
            .select('*')
            .eq('user_id', user.id)
            .maybeSingle();
        if (row != null) {
          final v = row['top_rated_activities'];
          final list = v is List ? v : null;
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
                wakeMessage: wakeMessage,
                idleOpeningLine: decision.openingLine,
                userPreferences: prefsMap,
                topInterest: topInterest,
                onComplete: () {
                  MoodyIdleChecker.completeIdleGate(decision).then((_) {
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      ref.read(mainTabProvider.notifier).state =
                          hasPlan ? 0 : 2;
                    });
                  });
                },
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

  Future<void> _checkForWeekendSuggestion() async {
    if (!mounted || _weekendBannerDismissed) return;

    final prefs = ref.read(preferencesProvider);
    final planningPace = (prefs.planningPace).toLowerCase();
    final isPlannedUser =
        planningPace.contains('gepland') || planningPace.contains('planned');
    if (!isPlannedUser) return;

    final now = DateTime.now();
    final dayOfWeek = now.weekday; // 1=Mon, 7=Sun
    if (dayOfWeek < DateTime.thursday || dayOfWeek > DateTime.friday) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final saturday = now.add(Duration(days: DateTime.saturday - dayOfWeek));
    final sunday = saturday.add(const Duration(days: 1));

    final satDateOnly = DateTime(saturday.year, saturday.month, saturday.day);
    final sunDateOnly = DateTime(sunday.year, sunday.month, sunday.day);
    final satStr =
        '${satDateOnly.year}-${satDateOnly.month.toString().padLeft(2, '0')}-${satDateOnly.day.toString().padLeft(2, '0')}';
    final sunStr =
        '${sunDateOnly.year}-${sunDateOnly.month.toString().padLeft(2, '0')}-${sunDateOnly.day.toString().padLeft(2, '0')}';

    try {
      final existing = await Supabase.instance.client
          .from('scheduled_activities')
          .select('id')
          .eq('user_id', userId)
          .inFilter('scheduled_date', [satStr, sunStr]);

      if (!mounted) return;
      if ((existing as List).isEmpty) {
        setState(() {
          _weekendSaturday = satDateOnly;
          _weekendSunday = sunDateOnly;
          _showWeekendBanner = true;
        });
      }
    } catch (_) {
      // Keep silent if suggestion check fails.
    }
  }

  @override
  void didUpdateWidget(MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldMoodAction = oldWidget.extra?['moodAction'] as String?;
    final newMoodAction = widget.extra?['moodAction'] as String?;
    if (oldMoodAction != newMoodAction && newMoodAction == 'moodCheckIn') {
      _moodCheckInDeepLinkConsumed = false;
    }
    final tabRouteChanged = oldWidget.initialTabIndex != widget.initialTabIndex ||
        _tabExtraChanged(oldWidget.extra, widget.extra);

    Future.microtask(() {
      if (!mounted) return;

      if (tabRouteChanged) {
        _applyMainTabFromRoute();
      }

      final targetDateString = widget.extra?['targetDate'] as String?;
      final parsedTargetDate =
          targetDateString != null ? DateTime.tryParse(targetDateString) : null;
      if (parsedTargetDate != null) {
        final dateOnly = DateTime(
          parsedTargetDate.year,
          parsedTargetDate.month,
          parsedTargetDate.day,
        );
        ref.read(selectedMyDayDateProvider.notifier).state = dateOnly;
      }

      final shouldRefresh = widget.extra?['refresh'] as bool? ?? false;
      if (shouldRefresh) {
        ref.invalidate(scheduledActivitiesForTodayProvider);
        ref.invalidate(cachedActivitySuggestionsProvider);
        ref.invalidate(todayActivitiesProvider);
      }

      _tryConsumeMoodCheckInDeepLink();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rawTabIndex = ref.watch(mainTabProvider);
    final selectedIndex = normalizeMainTabIndex(rawTabIndex);
    _mountedTabIndices.add(selectedIndex);
    final connectivityAsync = ref.watch(isConnectedProvider);
    final isConnected = connectivityAsync.valueOrNull ?? true;

    ref.listen<int>(mainAppTourRequestProvider, (previous, next) {
      if (next == 0) return;
      if (previous == next) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _mainTourShowing) return;
        _presentMainAppTour();
      });
    });

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F0E8), // wmCream — QA / design system
          drawer: const ProfileDrawer(),
          extendBody: true, // Allow body to extend behind the floating nav bar
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isConnected)
                Container(
                  width: double.infinity,
                  color: const Color(0xFFE05C5C),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        l10n.mainNavNoConnection,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    for (final i in _mountedTabIndices)
                      Offstage(
                        offstage: selectedIndex != i,
                        child: TickerMode(
                          enabled: selectedIndex == i,
                          child: _tabScreens[i],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Padding(
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
                        children: [
                          Expanded(
                            child: KeyedSubtree(
                              key: _mainTourNavKeys[0],
                              child: _buildRegularNavItem(context, ref, selectedIndex, 0, l10n.navMyDay, Icons.calendar_today_outlined, Icons.calendar_today, _navWmForest, _navWmForestTint),
                            ),
                          ),
                          Expanded(
                            child: KeyedSubtree(
                              key: _mainTourNavKeys[1],
                              child: _buildRegularNavItem(context, ref, selectedIndex, 1, l10n.navExplore, Icons.explore_outlined, Icons.explore, _navWmForest, _navWmForestTint),
                            ),
                          ),
                          Expanded(
                            child: KeyedSubtree(
                              key: _mainTourNavKeys[2],
                              child: _buildCenterMoodyButton(context, ref, selectedIndex, l10n.navMoody),
                            ),
                          ),
                          Expanded(
                            child: KeyedSubtree(
                              key: _mainTourNavKeys[3],
                              child: _buildRegularNavItem(context, ref, selectedIndex, 3, l10n.navAgenda, Icons.calendar_month_outlined, Icons.calendar_month, _navWmForest, _navWmForestTint),
                            ),
                          ),
                          Expanded(
                            child: KeyedSubtree(
                              key: _mainTourNavKeys[4],
                              child: _buildRegularNavItem(context, ref, selectedIndex, 4, l10n.navProfile, Icons.person_outline, Icons.person, _navWmForest, _navWmForestTint),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        if (_showWeekendBanner &&
            selectedIndex == 0 &&
            _weekendSaturday != null &&
            _weekendSunday != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 98,
            child: _buildWeekendBanner(_weekendSaturday!, _weekendSunday!),
          ),
      ],
    );
  }

  Widget _buildWeekendBanner(DateTime saturday, DateTime sunday) {
    final l10n = AppLocalizations.of(context)!;
    Widget weekendPlanButton(String label, DateTime date) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/moody', extra: {
            'targetDate': DateTime(date.year, date.month, date.day).toIso8601String(),
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _navWmForest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _wmSkyTint,
        border: Border.all(color: _wmSky),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🗓️', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.myDayWeekendEmptyTitle,
                  style: GoogleFonts.poppins(
                    color: _wmCharcoal,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.myDayWeekendEmptySubtitle,
                  style: GoogleFonts.poppins(
                    color: _wmDusk,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    weekendPlanButton(l10n.myDayWeekendSaturdayShort('${saturday.day}'), saturday),
                    const SizedBox(width: 8),
                    weekendPlanButton(l10n.myDayWeekendSundayShort('${sunday.day}'), sunday),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: _wmStone, size: 18),
            onPressed: () {
              setState(() {
                _showWeekendBanner = false;
                _weekendBannerDismissed = true;
              });
            },
          ),
        ],
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
      if (!isSelected) {
        HapticFeedback.selectionClick();
      }
      ref.read(mainTabProvider.notifier).state = index;
      // Refresh My Day data whenever the user navigates to it so newly added
      // activities (e.g. from Explore) always reflect the correct status.
      if (index == 0) {
        ref.invalidate(scheduledActivitiesForTodayProvider);
        ref.invalidate(todayActivitiesProvider);
      }
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
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
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  height: 1.05,
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

  Widget _buildCenterMoodyButton(
    BuildContext context,
    WidgetRef ref,
    int selectedIndex,
    String moodyLabel,
  ) {
    final isSelected = selectedIndex == 2;
    // Match [_buildRegularNavItem] structure — never use [SizedBox.expand] here:
    // the bar is a [Row] with intrinsic height; expand breaks layout (nav drifts,
    // body goes blank). Full tab width via [SizedBox(width: double.infinity)] inside
    // [Expanded]; icon slot ≥44×44 (iOS minimum touch target); character slightly
    // larger than Material icons so the center tab reads as the hero control.
    void openMoodyHub() {
      if (!isSelected) {
        HapticFeedback.selectionClick();
      }
      ref.read(mainTabProvider.notifier).state = 2;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: openMoodyHub,
        borderRadius: BorderRadius.circular(999),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: Center(
                      child: MoodyCharacter(
                        size: 36,
                        mood: isSelected ? 'happy' : 'default',
                        onTap: openMoodyHub,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    moodyLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      height: 1.05,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? _navWmForest : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
 