import 'package:wandermood/core/utils/moody_clock.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'dynamic_my_day_provider.dart';
import 'package:wandermood/features/home/presentation/providers/my_day_free_time_cache_provider.dart';
import '../../../profile/presentation/widgets/profile_drawer.dart';
import '../../../profile/domain/providers/current_user_profile_provider.dart';
import '../../../profile/domain/providers/profile_provider.dart';
import '../../../weather/providers/weather_provider.dart';
import '../widgets/day_execution_hero_card.dart';
import '../widgets/my_day_free_time_carousel.dart';
import '../widgets/my_day_get_ready_sheet.dart';
import '../widgets/my_day_timeline_section.dart';
import '../widgets/my_day_weather_dialog.dart';
import 'package:wandermood/core/theme/time_based_theme.dart';
import '../../providers/time_suggestion_provider.dart';
import 'package:wandermood/core/presentation/painters/circle_pattern_painter.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/home/presentation/widgets/planner_activity_detail_sheet.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import '../widgets/travel_time_connector.dart';
import 'package:wandermood/features/home/presentation/utils/my_day_status_l10n.dart';
import 'package:wandermood/features/home/presentation/utils/my_day_display_title.dart';
import 'package:wandermood/features/home/presentation/utils/my_day_activity_id.dart';
import 'package:wandermood/features/home/presentation/utils/my_day_slot_period.dart';
import 'package:wandermood/core/services/connectivity_service.dart';
import 'package:wandermood/core/utils/offline_feedback.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/services/places_service.dart';
import 'package:wandermood/features/places/services/saved_places_service.dart';
import 'package:wandermood/core/services/taste_profile_service.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:share_plus/share_plus.dart';

class DynamicMyDayScreen extends ConsumerStatefulWidget {
  const DynamicMyDayScreen({super.key});

  @override
  ConsumerState<DynamicMyDayScreen> createState() => _DynamicMyDayScreenState();
}

class _DynamicMyDayScreenState extends ConsumerState<DynamicMyDayScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, bool> _collapsedSections = {}; // Track which sections are collapsed
  late DateTime _selectedDate;
  
  bool _hasInitialized = false; // Prevent invalidate on hot reload
  int _moodStreak = 0;

  String _safeActivityTitle(Map<String, dynamic> activity) {
    return activity['title']?.toString() ??
        AppLocalizations.of(context)!.dayPlanCardActivity;
  }

  /// UI labels only; maps/share still use [_safeActivityTitle].
  String _displayActivityTitle(Map<String, dynamic> activity) {
    final shortened = myDayShortActivityTitle(activity['title']?.toString());
    if (shortened.isNotEmpty) return shortened;
    return _safeActivityTitle(activity);
  }

  Widget _myDayHeroSwitcher({
    required String stateKey,
    required EnhancedActivityData activity,
    required Widget child,
  }) {
    final id = myDayStableActivityId(activity.rawData);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget c, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.024),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: c,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<String>('myday-hero-$stateKey-$id'),
        child: child,
      ),
    );
  }

  /// Resolves coordinates from scheduled-activity maps (`lat`/`lng` and/or `location` "lat,lng").
  ({double? lat, double? lng}) _activityLatLng(Map<String, dynamic> activity) {
    double? lat = (activity['lat'] as num?)?.toDouble();
    double? lng = (activity['lng'] as num?)?.toDouble();
    final loc = activity['location'];
    if (loc is String && loc.contains(',')) {
      final parts = loc.split(',');
      if (parts.length >= 2) {
        lat ??= double.tryParse(parts[0].trim());
        lng ??= double.tryParse(parts[1].trim());
      }
    }
    return (lat: lat, lng: lng);
  }

  Uri _googleWebDirectionsUri(double? lat, double? lng, String title) {
    if (lat != null && lng != null) {
      return Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
    }
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(title)}',
    );
  }

  Uri _googleAppDirectionsUri(double? lat, double? lng, String title) {
    if (lat != null && lng != null) {
      return Uri.parse('comgooglemaps://?daddr=$lat,$lng&directionsmode=driving');
    }
    return Uri.parse('comgooglemaps://?q=${Uri.encodeComponent(title)}');
  }

  Uri _appleMapsUri(double? lat, double? lng, String title) {
    if (lat != null && lng != null) {
      return Uri.parse('maps://?q=${Uri.encodeComponent(title)}&ll=$lat,$lng');
    }
    return Uri.parse('maps://?q=${Uri.encodeComponent(title)}');
  }
  
  @override
  void initState() {
    super.initState();
    final now = MoodyClock.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(selectedMyDayDateProvider.notifier).state = _selectedDate;
    });
    // CRITICAL: Only invalidate once (not on hot reload)
    // Refresh data when the screen loads - delay properly to avoid build cycle conflicts
    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.microtask(() {
          if (mounted) {
            ref.invalidate(scheduledActivitiesForTodayProvider);
            ref.invalidate(cachedActivitySuggestionsProvider);
          }
        });
      });
    }
    _loadMoodStreak();
  }

  Future<void> _loadMoodStreak() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('mood_streak')
        .eq('id', userId)
        .maybeSingle();
    if (!mounted) return;
    setState(() {
      _moodStreak = (profile?['mood_streak'] as int?) ?? 0;
    });
    if (mounted) {
      unawaited(ref.read(currentUserProfileProvider.notifier).refresh());
    }
  }

  Future<void> _updateMoodStreakFromCompletions() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final now = MoodyClock.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final todayIso = today.toIso8601String().split('T').first;
    final yesterdayIso = yesterday.toIso8601String().split('T').first;

    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getString('mood_streak_last_update');
    if (lastUpdate == todayIso) {
      await _loadMoodStreak();
      return;
    }

    final completedToday = await client
        .from('scheduled_activities')
        .select('id')
        .eq('user_id', userId)
        .eq('scheduled_date', todayIso)
        .eq('is_confirmed', true)
        .limit(1);

    if (completedToday.isEmpty) return;

    final completedYesterday = await client
        .from('scheduled_activities')
        .select('id')
        .eq('user_id', userId)
        .eq('scheduled_date', yesterdayIso)
        .eq('is_confirmed', true)
        .limit(1);

    final profile = await client
        .from('profiles')
        .select('mood_streak')
        .eq('id', userId)
        .maybeSingle();
    final currentStreak = (profile?['mood_streak'] as int?) ?? 0;
    final nextStreak = completedYesterday.isNotEmpty
        ? (currentStreak > 0 ? currentStreak + 1 : 1)
        : 1;

    await client
        .from('profiles')
        .update({
          'mood_streak': nextStreak,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
    await prefs.setString('mood_streak_last_update', todayIso);
    await _loadMoodStreak();
  }

  bool _timelineHasActivities(
    AsyncValue<Map<String, List<EnhancedActivityData>>> async,
  ) {
    return async.maybeWhen(
      data: (m) => m.values.fold<int>(0, (sum, list) => sum + list.length) > 0,
      orElse: () => false,
    );
  }

  /// Quick actions — white cards, forest border, soft lift shadow (premium floating).
  Widget _buildMyDayQuickActionsRow(AppLocalizations l10n) {
    const wmCard = Color(0xFFFFFFFF);
    const wmForest = Color(0xFF2A6049);
    const wmCharcoal = Color(0xFF1E1C18);

    Widget tile({
      required VoidCallback onTap,
      required IconData icon,
      required String label,
    }) {
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: (_) => HapticFeedback.lightImpact(),
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: wmCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: wmForest.withValues(alpha: 0.35), width: 1),
                boxShadow: const [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: wmForest, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: wmCharcoal,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tile(
          onTap: () => _navigateToTab(2),
          icon: Icons.auto_awesome_rounded,
          label: l10n.myDayPlanWithMoodyButton,
        ),
        const SizedBox(width: 12),
        tile(
          onTap: () => _navigateToTab(1),
          icon: Icons.explore_rounded,
          label: l10n.myDayExploreActivitiesButton,
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 DynamicMyDayScreen: Building My Day screen');
    final l10n = AppLocalizations.of(context)!;
    final currentStatus = ref.watch(currentActivityStatusProvider);
    final timelineActivities = ref.watch(timelineCategorizedActivitiesProvider);
    final currentStatusValue = currentStatus.valueOrNull;
    final headerSubtitle = _headerSubtitle(
      l10n: l10n,
      status: currentStatusValue,
    );
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: const ProfileDrawer(),
      backgroundColor: const Color(0xFFF5F0E8), // wmCream — match Explore / main shell
      body: currentStatusValue?['type'] == 'no_plan'
          ? _buildImmersiveNoPlanState(l10n)
          : CustomScrollView(
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              // Match Explore: do not pad the header's bottom with the home-indicator
              // inset — that reads as a large empty band above the timeline slivers.
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with profile button, title, and controls
                      _buildHeaderRow(isImmersive: false),
                      
                      const SizedBox(height: 12),
                      _buildDateNavigation(),
                      const SizedBox(height: 12),
                      
                      // Dynamic greeting message
                      Text(
                        headerSubtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF4A4640),
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                      if (_moodStreak > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF6E8),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFFE8E2D8),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '🔥 ${l10n.myDayMoodStreakBadge(_moodStreak)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2A6049),
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 12),
                      currentStatus.when(
                        data: (status) {
                          try {
                            return _buildSmartStatusCard(status);
                          } catch (_) {
                            return const SizedBox.shrink();
                          }
                        },
                        loading: () => _buildLoadingStatusCard(),
                        error: (error, stack) => _buildErrorStatusCard(),
                      ),
                      if (_timelineHasActivities(timelineActivities)) ...[
                        const SizedBox(height: 12),
                        _buildMyDayQuickActionsRow(l10n),
                        const SizedBox(height: 6),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFE8E2D8),
                        ),
                        const SizedBox(height: 14),
                      ] else
                        const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Timeline (time-of-day sections)
            ...timelineActivities.when(
              data: (activities) => _buildTimelineView(activities),
              loading: () => [_buildLoadingSliver()],
              error: (error, stack) => [_buildErrorSliver()],
            ),

            // Free Time Carousel
            SliverToBoxAdapter(
              child: _buildFreeTimeCarousel(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
    );
  }

  Widget _buildDateNavigation() {
    final todayNow = MoodyClock.now();
    final today = DateTime(todayNow.year, todayNow.month, todayNow.day);
    final isToday = _isSameDate(_selectedDate, today);
    final canGoBack = !isToday;

    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            icon: const Icon(Icons.chevron_left, color: Color(0xFF8C8780)),
            onPressed: canGoBack
                ? () => _setSelectedDate(_selectedDate.subtract(const Duration(days: 1)))
                : null,
          ),
          GestureDetector(
            onTap: () => _setSelectedDate(today),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isToday ? const Color(0xFFFFF6E8) : Colors.white,
                border: Border.all(
                  color: isToday ? const Color(0xFFE8E2D8) : const Color(0xFFE8E2D8),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isToday
                    ? AppLocalizations.of(context)!.timeLabelToday
                    : _formatDisplayDate(_selectedDate),
                style: GoogleFonts.poppins(
                  color: isToday ? const Color(0xFF2A6049) : const Color(0xFF1E1C18),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            icon: const Icon(Icons.chevron_right, color: Color(0xFF8C8780)),
            onPressed: () => _setSelectedDate(_selectedDate.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }

  void _setSelectedDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    setState(() {
      _selectedDate = normalized;
    });
    ref.read(selectedMyDayDateProvider.notifier).state = normalized;
    ref.invalidate(scheduledActivitiesForTodayProvider);
    ref.invalidate(todayActivitiesProvider);
    ref.invalidate(timelineCategorizedActivitiesProvider);
    ref.invalidate(currentActivityStatusProvider);
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDisplayDate(DateTime date) {
    final dayName = _getDayName(date);
    return '$dayName ${date.day} ${_getShortMonth(date)}';
  }

  String _getDayName(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final days = [l10n.dayMon, l10n.dayTue, l10n.dayWed, l10n.dayThu, l10n.dayFri, l10n.daySat, l10n.daySun];
    return days[date.weekday - 1];
  }

  String _getShortMonth(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final months = [l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr, l10n.monthMay, l10n.monthJun, l10n.monthJul, l10n.monthAug, l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec];
    return months[date.month - 1];
  }

  Widget _buildImmersiveNoPlanState(AppLocalizations l10n) {
    return Container(
      color: const Color(0xFFF5F0E8),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildHeaderRow(isImmersive: false),
              const SizedBox(height: 12),
              _buildDateNavigation(),
              const Spacer(),
              MoodyCharacter(
                size: 80,
                mood: 'happy',
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 16),
              Text(
                l10n.myDayEmptyDayTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1C18),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.myDayEmptyDaySubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF4A4640),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToTab(2),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A6049),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.myDayPlanWithMoodyButton,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _navigateToTab(1),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF2A6049), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    l10n.myDayExploreActivitiesButton,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2A6049),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/agenda'),
                child: Text(
                  l10n.drawerMyAgenda,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A6049),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImmersiveActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow({required bool isImmersive}) {
    final titleColor = isImmersive ? Colors.white : const Color(0xFF1E1C18);
    final profileBgColor = isImmersive ? Colors.white.withOpacity(0.2) : Colors.white;
    final profileBorder = isImmersive ? Border.all(color: Colors.white.withOpacity(0.5), width: 1) : null;
    final shadowColor = isImmersive ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.1);

    return Row(
      children: [
        // Profile button
        GestureDetector(
          onTap: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: profileBgColor,
              shape: BoxShape.circle,
              border: profileBorder,
              boxShadow: [
                if (!isImmersive)
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: isImmersive
                ? ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: _buildProfileAvatar(isImmersive: isImmersive),
                    ),
                  )
                : _buildProfileAvatar(isImmersive: isImmersive),
          ),
        ),
        const SizedBox(width: 16),
        
        // Title (wmTitle — design system)
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.navMyDay,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: titleColor,
              letterSpacing: -0.5,
              shadows: isImmersive
                  ? [Shadow(color: shadowColor, blurRadius: 4, offset: const Offset(0, 2))]
                  : null,
            ),
          ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
        ),
        
        // Weather pill only (no reset / refresh / agenda in header)
        Row(
          children: [
            Consumer(
              builder: (context, ref, child) {
                final weatherAsync = ref.watch(weatherProvider);
                
                return weatherAsync.when(
                  data: (weather) {
                    if (weather == null) {
                      return GestureDetector(
                        onTap: () => _showWeatherDialog(context, null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isImmersive ? Colors.white.withOpacity(0.15) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: isImmersive
                                ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
                                : Border.all(color: const Color(0xFFE8E2D8), width: 0.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: isImmersive ? ImageFilter.blur(sigmaX: 5, sigmaY: 5) : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_off, color: isImmersive ? Colors.white : const Color(0xFF8C8780), size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    '--°',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isImmersive ? Colors.white : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    
                    // Get appropriate weather icon
                    IconData weatherIcon;
                    Color dynamicIconColor;
                    switch (weather.condition.toLowerCase()) {
                      case 'clear':
                        weatherIcon = Icons.wb_sunny;
                        dynamicIconColor = isImmersive ? Colors.white : Colors.orange;
                        break;
                      case 'clouds':
                        weatherIcon = Icons.cloud;
                        dynamicIconColor = isImmersive ? Colors.white : Colors.grey[600]!;
                        break;
                      case 'rain':
                        weatherIcon = Icons.water_drop;
                        dynamicIconColor = isImmersive ? Colors.white : Colors.blue;
                        break;
                      case 'snow':
                        weatherIcon = Icons.ac_unit;
                        dynamicIconColor = isImmersive ? Colors.white : Colors.lightBlue;
                        break;
                      case 'thunderstorm':
                        weatherIcon = Icons.flash_on;
                        dynamicIconColor = isImmersive ? Colors.white : Colors.deepPurple;
                        break;
                      case 'mist':
                      case 'fog':
                        weatherIcon = Icons.blur_on;
                        dynamicIconColor = isImmersive ? Colors.white : Colors.grey[500]!;
                        break;
                      default:
                        weatherIcon = Icons.wb_sunny;
                        dynamicIconColor = isImmersive ? Colors.white : Colors.orange;
                    }
                    
                    return GestureDetector(
                      onTap: () => _showWeatherDialog(context, weather),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isImmersive ? Colors.white.withOpacity(0.15) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: isImmersive
                              ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
                              : Border.all(color: const Color(0xFFE8E2D8), width: 0.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: isImmersive ? ImageFilter.blur(sigmaX: 5, sigmaY: 5) : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(weatherIcon, color: dynamicIconColor, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  '${weather.temperature.round()}°',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isImmersive ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isImmersive ? Colors.white.withOpacity(0.15) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: isImmersive
                          ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
                          : Border.all(color: const Color(0xFFE8E2D8), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(isImmersive ? Colors.white : Colors.grey[600]!),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '...°',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isImmersive ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  error: (_, __) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isImmersive ? Colors.white.withOpacity(0.15) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: isImmersive
                          ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
                          : Border.all(color: const Color(0xFFE8E2D8), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '!°',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileAvatar({required bool isImmersive}) {
    return Consumer(
      builder: (context, ref, child) {
        final profileData = ref.watch(profileProvider);
        return profileData.when(
          data: (profile) => CircleAvatar(
            radius: 20,
            backgroundColor: isImmersive ? Colors.transparent : Colors.white,
            backgroundImage: profile?.imageUrl != null
                ? wmCachedNetworkImageProvider(profile!.imageUrl!)
                : null,
            child: profile?.imageUrl == null
                ? Text(
                    ((profile?.fullName?.trim().isNotEmpty ?? false)
                            ? profile!.fullName!.trim().substring(0, 1).toUpperCase()
                            : 'U'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isImmersive ? Colors.white : const Color(0xFF2A6049),
                    ),
                  )
                : null,
          ),
          loading: () => CircleAvatar(
            radius: 20,
            backgroundColor: isImmersive ? Colors.transparent : Colors.white,
            child: Icon(
              Icons.person,
              color: isImmersive ? Colors.white : const Color(0xFF2A6049),
              size: 20,
            ),
          ),
          error: (_, __) => CircleAvatar(
            radius: 20,
            backgroundColor: isImmersive ? Colors.transparent : Colors.white,
            child: Icon(
              Icons.person,
              color: isImmersive ? Colors.white : const Color(0xFF2A6049),
              size: 20,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmartStatusCard(Map<String, dynamic> status) {
    final enhancedActivity = status['enhancedActivity'] as EnhancedActivityData?;

    if (status['type'] == 'no_plan') {
      return _buildNoPlanGreetingCard();
    }

    if (status['type'] == 'active' && enhancedActivity != null) {
      return _myDayHeroSwitcher(
        stateKey: 'active',
        activity: enhancedActivity,
        child: DayExecutionHeroCard(
          activity: enhancedActivity,
          state: DayExecutionHeroState.active,
          onDirections: () => _showDirectionsOptions(status['activity']),
          onMarkDone: () => _markActivityDone(enhancedActivity),
        ),
      );
    }

    if (status['type'] == 'upcoming' && enhancedActivity != null) {
      return _myDayHeroSwitcher(
        stateKey: 'upcoming',
        activity: enhancedActivity,
        child: DayExecutionHeroCard(
          activity: enhancedActivity,
          state: DayExecutionHeroState.upcoming,
          onDirections: () => _showDirectionsOptions(status['activity']),
          onCheckIn: () => _checkInActivity(enhancedActivity),
        ),
      );
    }

    if (status['type'] == 'completed' && enhancedActivity != null) {
      return _myDayHeroSwitcher(
        stateKey: 'completed',
        activity: enhancedActivity,
        child: DayExecutionHeroCard(
          activity: enhancedActivity,
          state: DayExecutionHeroState.completed,
          onDirections: () => _showDirectionsOptions(status['activity']),
        ),
      );
    }

    if (status['type'] == 'free_time') {
      return _buildEnhancedFreeTimeCard(status);
    }

    return _buildEnhancedStatusCard(status);
  }

  Widget _buildNoPlanGreetingCard() {
    final l10n = AppLocalizations.of(context)!;
    final hour = MoodyClock.now().hour;
    final timeConfig = TimeBasedTheme.getConfigForHour(hour);

    final config = _emptyStateGreetingConfig(
      l10n: l10n,
      hour: hour,
      timeConfig: timeConfig,
    );

    // WanderMood v2 (Screen 2): no stock photo backgrounds — wmWhite card + tokens
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE8E2D8)),
        boxShadow: const [],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFF4E0),
            ),
            child: Icon(
              config.icon,
              size: 44,
              color: const Color(0xFF2A6049),
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Text(
            config.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1C18),
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: 10),
          Text(
            config.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF4A4640),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  Widget _buildEnhancedFreeTimeCard(Map<String, dynamic> status) {
    final hour = MoodyClock.now().hour;
    final timeConfig = TimeBasedTheme.getConfigForHour(hour);
    
    return Consumer(
      builder: (context, ref, child) {
        final l10n = AppLocalizations.of(context)!;
        final suggestion = ref.watch(timeSuggestionProvider);
        
        return Container(
            height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: timeConfig.gradientColors,
              ),
        boxShadow: [
          BoxShadow(
                  color: Colors.black.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
                  offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
        child: Stack(
          children: [
                // Background pattern
            Positioned.fill(
                  child: CustomPaint(
                    painter: CirclePatternPainter(
                      color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      // Title row
                  Row(
                    children: [
                      Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                        ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                          children: [
                                Icon(timeConfig.icon, size: 16, color: Colors.white),
                                const SizedBox(width: 8),
                            Text(
                                  timeConfig.name.toUpperCase(),
                              style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                          const Spacer(),
                          Text(
                            timeConfig.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                    ],
                  ),
                  
                      const Spacer(),
                  
                      // Dynamic suggestion
                      suggestion.when(
                        data: (text) => Text(
                          text,
                    style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        loading: () => const CircularProgressIndicator(color: Colors.white),
                        error: (_, __) => Text(
                          timeConfig.defaultSuggestion,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.2,
                          ),
                    ),
                  ),
                  
                  const Spacer(),
                  // Primary: plan with Moody (tab 2). Secondary: explore (tab 1).
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _navigateToTab(2);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2A6049),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              l10n.myDayPlanWithMoodyButton,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _navigateToTab(1);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.explore_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              l10n.myDayExploreActivitiesButton,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        );
      },
    );
  }

  Widget _buildEnhancedStatusCard(Map<String, dynamic> status) {
    final l10n = AppLocalizations.of(context)!;
    final type = status['type'] as String?;
    final titleText = myDayStatusTitleForType(l10n, type);
    final descriptionText = myDayStatusDescriptionForMap(l10n, status);
    final subtitleText = type == 'free_time'
        ? myDayPeriodShortLabel(l10n, status['period'] as String?)
        : (status['subtitle'] as String? ?? '');
    Color primaryColor;
    Color backgroundColor;
    IconData statusIcon;
    bool isUpcoming = false;
    
    const wmForest = Color(0xFF2A6049);
    const wmParchment = Color(0xFFE8E2D8);
    switch (status['type']) {
      case 'upcoming':
        primaryColor = wmForest;
        backgroundColor = Colors.white;
        statusIcon = Icons.schedule;
        isUpcoming = true;
        break;
      case 'completed':
        primaryColor = wmForest;
        backgroundColor = Colors.white;
        statusIcon = Icons.check_circle;
        break;
      default:
        primaryColor = wmForest;
        backgroundColor = Colors.white;
        statusIcon = Icons.explore;
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: wmParchment,
          width: isUpcoming ? 1.25 : 1,
        ),
        boxShadow: const [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6E8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE8E2D8).withValues(alpha: 0.8),
                    ),
                  ),
                  child: Icon(
                    statusIcon,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        style: GoogleFonts.museoModerno(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitleText,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        descriptionText,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Action buttons
            if ((status['action1'] != null || status['action2'] != null)) ...[
              const SizedBox(height: 20),
              if (isUpcoming && status['action2'] != null) 
                // Special case for "Coming Up" card - single "Get Ready" button
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A6049),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _handleStatusAction(status['action2'] as String, status),
                      child: Center(
                        child: Text(
                          isUpcoming ? l10n.myDayGetReadyButton : status['action2'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                // Standard two-button layout for other card types
                Row(
                  children: [
                    if (status['action1'] != null)
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF2A6049), width: 1.5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () => _handleStatusAction(status['action1'] as String, status),
                              child: Center(
                                child: Text(
                                  myDayActionButtonLabel(l10n, status['action1'] as String),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2A6049),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (status['action1'] != null && status['action2'] != null)
                      const SizedBox(width: 12),
                    if (status['action2'] != null)
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A6049),
                            border: null,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () => _handleStatusAction(status['action2'] as String, status),
                              child: Center(
                                child: Text(
                                  myDayActionButtonLabel(l10n, status['action2'] as String),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: status['type'] == 'upcoming' ? Colors.white : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ],
        ),
      ),
    ).animate()
      .slideY(begin: 0.3, duration: 600.ms, delay: 300.ms)
      .fadeIn(duration: 600.ms, delay: 300.ms)
      .scale(begin: const Offset(0.95, 0.95), duration: 400.ms)
      .shimmer(delay: 1000.ms, duration: 2000.ms, color: Colors.white.withOpacity(0.2));
  }

  Widget _buildRightNowCard(Map<String, dynamic> status) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showActivityDetails(status['activity']);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: WmPlaceOrHttpsNetworkImage(
                  status['imageUrl']?.toString() ??
                      'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&q=80',
                  fit: BoxFit.cover,
                  progressIndicatorBuilder: (context, url, progress) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2A6049).withOpacity(0.8),
                          const Color(0xFF4CAF50).withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.image, color: Colors.white, size: 60),
                    ),
                  ),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top section - Status and pulsing indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ).animate(onPlay: (controller) => controller.repeat())
                                    .scaleXY(begin: 0.8, end: 1.4, duration: 1000.ms)
                                    .then()
                                    .scaleXY(begin: 1.4, end: 0.8, duration: 1000.ms),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.myDayRightNow,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Tap indicator
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.touch_app,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Bottom section - Place name and details
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status['subtitle'],
                            style: GoogleFonts.museoModerno(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.myDayStatusDescActive,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                                                     ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
          ).animate()
        .slideY(begin: 0.3, duration: 600.ms, delay: 300.ms)
        .fadeIn(duration: 600.ms, delay: 300.ms)
        .scale(begin: const Offset(0.95, 0.95), duration: 400.ms)
        .shimmer(delay: 1500.ms, duration: 3000.ms, color: Colors.white.withOpacity(0.3));
  }

  Widget _buildLoadingStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A6049).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2A6049).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF2A6049),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A6049)),
            strokeWidth: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStatusCard() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.myDayStatusError,
                  style: GoogleFonts.museoModerno(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.myDayStatusUnableToLoad,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.error, color: Colors.red, size: 28),
        ],
      ),
    );
  }

  List<Widget> _buildTimelineView(Map<String, List<EnhancedActivityData>> activities) {
    final l10n = AppLocalizations.of(context)!;
    final viewDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final now = MoodyClock.now();
    final hasMorning = activities['morning']?.isNotEmpty == true;
    final hasAfternoon = activities['afternoon']?.isNotEmpty == true;
    final hasEvening = activities['evening']?.isNotEmpty == true;

    final firstVisibleSection = hasMorning
        ? 'morning'
        : hasAfternoon
            ? 'afternoon'
            : hasEvening
                ? 'evening'
                : null;

    Widget? crossSectionConnector(List<EnhancedActivityData> from, List<EnhancedActivityData> to) {
      final fromLoc = parseTravelLocation(from.last.rawData);
      final toLoc = parseTravelLocation(to.first.rawData);
      if (fromLoc == null || toLoc == null) return null;
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TravelTimeConnector(
            fromLat: fromLoc.lat,
            fromLng: fromLoc.lng,
            toLat: toLoc.lat,
            toLng: toLoc.lng,
          ),
        ),
      );
    }

    final widgets = <Widget>[];

    if (hasMorning) {
      widgets.add(_buildTimelineSection(
        'morning',
        myDayTimelineSectionTitle(
          l10n,
          period: 'morning',
          viewDay: viewDay,
          now: now,
        ),
        l10n.myDayTimelineSectionMorningSubtitle,
        activities['morning']!,
        isFirstSection: firstVisibleSection == 'morning',
      ));
      if (hasAfternoon) {
        final c = crossSectionConnector(activities['morning']!, activities['afternoon']!);
        if (c != null) widgets.add(c);
      } else if (hasEvening) {
        final c = crossSectionConnector(activities['morning']!, activities['evening']!);
        if (c != null) widgets.add(c);
      }
    }

    if (hasAfternoon) {
      widgets.add(_buildTimelineSection(
        'afternoon',
        myDayTimelineSectionTitle(
          l10n,
          period: 'afternoon',
          viewDay: viewDay,
          now: now,
        ),
        l10n.myDayTimelineSectionAfternoonSubtitle,
        activities['afternoon']!,
        isFirstSection: firstVisibleSection == 'afternoon',
      ));
      if (hasEvening) {
        final c = crossSectionConnector(activities['afternoon']!, activities['evening']!);
        if (c != null) widgets.add(c);
      }
    }

    if (hasEvening) {
      widgets.add(_buildTimelineSection(
        'evening',
        myDayTimelineSectionTitle(
          l10n,
          period: 'evening',
          viewDay: viewDay,
          now: now,
        ),
        l10n.myDayTimelineSectionEveningSubtitle,
        activities['evening']!,
        isFirstSection: firstVisibleSection == 'evening',
      ));
    }

    if (!hasMorning && !hasAfternoon && !hasEvening) {
      widgets.add(_buildEmptyTimelineSliver());
    }

    return widgets;
  }

  Widget _buildTimelineSection(
    String sectionId,
    String title,
    String subtitle,
    List<EnhancedActivityData> activities, {
    bool isFirstSection = false,
  }) {
    final sectionKey = sectionId;

    return MyDayTimelineSection(
      title: title,
      subtitle: subtitle,
      activities: activities,
      isFirstSection: isFirstSection,
      isCollapsed: _collapsedSections[sectionKey] ?? false,
      onToggleCollapse: () {
        setState(() {
          _collapsedSections[sectionKey] = !(_collapsedSections[sectionKey] ?? false);
        });
      },
      onActivityTap: (activity) => _showActivityDetails(activity.rawData),
      onDirectionsTap: _handleTimelinePrimaryAction,
      onMoreTap: _showActivityOptions,
      onCheckIn: _checkInActivity,
      onMarkDone: _markActivityDone,
      onGetReady: _showRichGetReadySheet,
      formatTime: _formatTime,
    );
  }

  Widget _buildLoadingSliver() {
    return SliverToBoxAdapter(
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A6049)),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorSliver() {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.myDayUnableLoadActivities,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(scheduledActivitiesForTodayProvider);
                  ref.invalidate(cachedActivitySuggestionsProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A6049),
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.planLoadingTryAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTimelineSliver() {
    final l10n = AppLocalizations.of(context)!;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [],
              ),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDDFCE5), Color(0xFFB6F1C4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const [],
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      size: 38,
                      color: Color(0xFF2A6049),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds, curve: Curves.easeInOut),
                  const SizedBox(height: 22),
                  Text(
                    l10n.myDayEmptyPlanTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF172033),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.myDayEmptyPlanSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      height: 1.6,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.goNamed('main', extra: {'tab': 2}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A6049),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            l10n.myDayPlanWithMoodyButton,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.goNamed('main', extra: {'tab': 1}),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        foregroundColor: const Color(0xFF334155),
                      ),
                      child: Text(
                        l10n.myDayExploreActivitiesButton,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
            const SizedBox(height: 36),
            Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFFF59E0B),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.myDayEmptyInspiredTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF172033),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0, curve: Curves.easeOut),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  _buildInspirationCard(
                    imageUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=800&auto=format&fit=crop',
                    icon: Icons.local_cafe_rounded,
                    title: l10n.myDayInspiredCafesTitle,
                    subtitle: l10n.myDayInspiredCafesSubtitle,
                    onTap: () => context.goNamed('main', extra: {'tab': 1}),
                  ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOut),
                  const SizedBox(width: 16),
                  _buildInspirationCard(
                    imageUrl: 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?q=80&w=800&auto=format&fit=crop',
                    icon: Icons.trending_up_rounded,
                    title: l10n.myDayInspiredTrendingTitle,
                    subtitle: l10n.myDayInspiredTrendingSubtitle,
                    onTap: () => context.goNamed('main', extra: {'tab': 1}),
                  ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOut),
                  const SizedBox(width: 16),
                  _buildInspirationCard(
                    imageUrl: 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?q=80&w=800&auto=format&fit=crop',
                    icon: Icons.explore_rounded,
                    title: l10n.myDayInspiredHiddenGemsTitle,
                    subtitle: l10n.myDayInspiredHiddenGemsSubtitle,
                    onTap: () => context.goNamed('main', extra: {'tab': 1}),
                  ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOut),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspirationCard({
    required String imageUrl,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: WmPlaceOrHttpsNetworkImage(
                  imageUrl,
                  fit: BoxFit.cover,
                  progressIndicatorBuilder: (context, url, progress) =>
                      Container(color: Colors.grey.shade200),
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.grey.shade200),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Icon(icon, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _headerSubtitle({
    required AppLocalizations l10n,
    required Map<String, dynamic>? status,
  }) {
    final statusType = status?['type'] as String?;

    if (statusType == 'no_plan') {
      return l10n.myDayNoPlanHeaderSubtitle;
    }

    final hour = MoodyClock.now().hour;
    if (hour < 12) {
      return l10n.myDayHeaderMorning;
    }
    if (hour < 17) {
      return l10n.myDayHeaderAfternoon;
    }
    return l10n.myDayHeaderEvening;
  }

  _EmptyGreetingConfig _emptyStateGreetingConfig({
    required AppLocalizations l10n,
    required int hour,
    required TimeOfDayConfig timeConfig,
  }) {
    if (hour < 12) {
      return _EmptyGreetingConfig(
        title: '${l10n.goodMorning}!',
        subtitle: l10n.myDayEmptyGreetingMorningBody,
        icon: Icons.wb_sunny_rounded,
        gradientColors: [
          const Color(0xFFFFF4C7),
          const Color(0xFFFFF8E1),
        ],
        borderColor: const Color(0xFFF6C26B),
        iconTint: const Color(0xFFF59E0B),
      );
    }

    if (hour < 17) {
      return _EmptyGreetingConfig(
        title: '${l10n.goodAfternoon}!',
        subtitle: l10n.myDayEmptyGreetingAfternoonBody,
        icon: timeConfig.icon,
        gradientColors: [
          const Color(0xFFE6F4FF),
          const Color(0xFFF1F8FF),
        ],
        borderColor: const Color(0xFF9DD0FF),
        iconTint: const Color(0xFF3B82F6),
      );
    }

    return _EmptyGreetingConfig(
      title: '${l10n.goodEvening}!',
      subtitle: l10n.myDayEmptyGreetingEveningBody,
      icon: timeConfig.icon,
      gradientColors: [
        const Color(0xFFF2E8FF),
        const Color(0xFFF9F4FF),
      ],
      borderColor: const Color(0xFFC9A7FF),
      iconTint: const Color(0xFF8B5CF6),
    );
  }

  void _handleStatusAction(String action, Map<String, dynamic> status) {
    // Provide immediate feedback for button press
    HapticFeedback.lightImpact();
    
    // Handle different status card actions (stable keys from provider + legacy English)
    switch (action) {
      case 'explore_nearby':
      case 'Explore Nearby':
        _navigateToTab(1);
        break;
      case 'ask_moody':
      case 'Ask Moody':
        _navigateToTab(2);
        break;
      case 'View Details':
        _showActivityDetails(status['activity']);
        break;
      case 'Get Ready':
        unawaited(_tryShowGetReadyFromStatus(status));
        break;
      case 'Get Directions':
        _showDirectionsOptions(status['activity']);
        break;
      case 'Rate Experience':
        // TODO: Open rating dialog
        break;
    }
  }

  void _handleTimelinePrimaryAction(EnhancedActivityData activity) {
    _openDirections(activity.rawData);
  }

  void _checkInActivity(EnhancedActivityData activity) {
    final activityId = myDayStableActivityId(activity.rawData);
    if (activityId.isEmpty) return;

    HapticFeedback.mediumImpact();
    ref.read(activityManagerProvider.notifier).checkInActivity(activityId);
    ref.invalidate(currentActivityStatusProvider);
    ref.invalidate(todayActivitiesProvider);

    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!.myDayCheckInPrompt,
    );
  }

  void _markActivityDone(EnhancedActivityData activity) {
    final activityId = myDayStableActivityId(activity.rawData);
    if (activityId.isEmpty) return;

    HapticFeedback.mediumImpact();
    ref.read(activityManagerProvider.notifier).markActivityDone(activityId);
    TasteProfileService.recordFromActivityRaw(
      activity.rawData,
      interactionType: 'completed',
      moodContext: ref.read(dailyMoodStateNotifierProvider).currentMood,
      timeSlot:
          TasteProfileService.inferTimeSlotFromHour(MoodyClock.now().hour),
    );
    final confirmId =
        activity.rawData['placeId'] as String? ??
        activity.rawData['id'] as String? ??
        activity.rawData['title'] as String? ??
        '';
    if (confirmId.isNotEmpty) {
      ref
          .read(scheduledActivityServiceProvider)
          .updateActivityConfirmation(confirmId, true)
          .then((_) => _updateMoodStreakFromCompletions());
    }
    ref.invalidate(currentActivityStatusProvider);
    ref.invalidate(todayActivitiesProvider);

    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!.myDayDonePrompt,
    );
  }

  Future<void> _showRichGetReadySheet(EnhancedActivityData activity) async {
    await showMyDayGetReadySheet(
      context: context,
      ref: ref,
      activity: activity,
      formatTime: _formatTime,
    );
  }

  /// Resolves [EnhancedActivityData] from provider when status maps omit it,
  /// then opens the modern get-ready sheet (never the legacy ListTile sheet).
  Future<void> _tryShowGetReadyFromStatus(Map<String, dynamic> status) async {
    final enhanced = status['enhancedActivity'] as EnhancedActivityData?;
    if (enhanced != null) {
      await _showRichGetReadySheet(enhanced);
      return;
    }
    final raw = status['activity'];
    if (raw is Map<String, dynamic>) {
      await _tryShowGetReadyFromRaw(raw);
    }
  }

  Future<void> _tryShowGetReadyFromRaw(Map<String, dynamic> raw) async {
    try {
      final list = await ref.read(todayActivitiesProvider.future);
      EnhancedActivityData? found;
      final rawId = raw['id'] as String?;
      if (rawId != null && rawId.isNotEmpty) {
        for (final e in list) {
          final id = e.rawData['id'] as String?;
          if (id == rawId) {
            found = e;
            break;
          }
        }
      }
      if (found == null) {
        final title = raw['title'] as String?;
        final st = raw['startTime'] as String?;
        if (title != null && st != null) {
          for (final e in list) {
            if (e.rawData['title'] == title && e.rawData['startTime'] == st) {
              found = e;
              break;
            }
          }
        }
      }
      if (!mounted) return;
      if (found != null) {
        await _showRichGetReadySheet(found);
      } else {
        _showActivityDetails(raw);
      }
    } catch (_) {
      if (!mounted) return;
      _showActivityDetails(raw);
    }
  }

  void _navigateToTab(int tabIndex) async {
    // Add haptic feedback immediately for instant response
    HapticFeedback.lightImpact();

    if (tabIndex == 2) {
      final connected = await ref.read(connectivityServiceProvider).isConnected;
      if (!mounted) return;
      if (!connected) {
        showOfflineSnackBar(context);
        return;
      }
    }
    
    // Show brief visual feedback
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      showWanderMoodToast(
        context,
        message: l10n.myDayTabActivated(
          tabIndex == 1 ? l10n.navExplore : l10n.navMoody,
        ),
        duration: const Duration(milliseconds: 600),
      );
    }
    
    // Small delay for better UX - lets user see the feedback
    await Future.delayed(const Duration(milliseconds: 250));
    
    // Use context.go() for navigation instead of modifying provider directly
    if (mounted) {
      context.go('/main', extra: {'tab': tabIndex});
    }
  }
  


  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Warm [PlacesService] so [PlaceDetailScreen] opens from carousel taps without waiting on cache I/O.
  void _cachePlaceFromCarouselForDetail(Map<String, dynamic> activity) {
    final routeId = resolvePlannerPlaceDetailRouteId(activity);
    if (routeId == null) return;
    final title = (activity['title'] as String?)?.trim();
    if (title == null || title.isEmpty) return;
    final coords = _activityLatLng(activity);
    final imageUrl = activity['imageUrl']?.toString() ?? '';
    final desc = activity['description']?.toString();
    final place = Place(
      id: routeId,
      name: title,
      address: '',
      location: PlaceLocation(lat: coords.lat ?? 0, lng: coords.lng ?? 0),
      photos: imageUrl.isNotEmpty ? [imageUrl] : [],
      description: desc,
      types: const ['point_of_interest'],
    );
    ref.read(placesServiceProvider.notifier).cachePlaceObject(place);
  }

  void _showActivityDetails(Map<String, dynamic> activity) {
    final routePlaceId = resolvePlannerPlaceDetailRouteId(activity);
    final scheduledLabel = activity['startTime'] != null
        ? _formatTime(DateTime.parse(activity['startTime'] as String))
        : null;
    final l10n = AppLocalizations.of(context)!;

    showPlannerActivityDetailSheet(
      context,
      activity: activity,
      scheduledTimeLabel: scheduledLabel,
      footerBuilder: (pop) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      pop();
                      _openDirections(activity);
                    },
                    icon: const Icon(Icons.directions),
                    label: Text(l10n.activityDetailDirections),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A6049),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      pop();
                      unawaited(_saveActivity(activity));
                    },
                    icon: const Icon(Icons.bookmark_outline),
                    label: Text(l10n.myDaySaveForLater),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2A6049),
                      side: const BorderSide(color: Color(0xFF2A6049)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (routePlaceId != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  pop();
                  _cachePlaceFromCarouselForDetail(activity);
                  if (!context.mounted) return;
                  context.pushNamed(
                    'place-detail',
                    pathParameters: {'id': routePlaceId},
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                label: Text(l10n.myDayOpenFullPlaceDetails),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2A6049),
                  side: const BorderSide(color: Color(0xFF2A6049)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showDirectionsOptions(Map<String, dynamic> activity) {
    final l10n = AppLocalizations.of(context)!;
    final displayTitle = _displayActivityTitle(activity);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          10 + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.activityDetailDirections,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.myDayDirectionsChooseFor(displayTitle),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.35,
                    color: const Color(0xFF4A4640),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final coords = _activityLatLng(activity);
                          final title = _safeActivityTitle(activity);
                          final googleAppUri =
                              _googleAppDirectionsUri(coords.lat, coords.lng, title);
                          final googleWebUri =
                              _googleWebDirectionsUri(coords.lat, coords.lng, title);
                          final canOpenGoogleApp =
                              await canLaunchUrl(googleAppUri);
                          Navigator.pop(sheetContext);
                          if (!mounted) return;
                          final uri =
                              canOpenGoogleApp ? googleAppUri : googleWebUri;
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        },
                        icon: const Icon(Icons.map, size: 20),
                        label: Text(l10n.myDayOpenGoogleMaps),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A6049),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final coords = _activityLatLng(activity);
                          final title = _safeActivityTitle(activity);
                          final appleUri =
                              _appleMapsUri(coords.lat, coords.lng, title);
                          Navigator.pop(sheetContext);
                          if (!mounted) return;
                          await launchUrl(appleUri,
                              mode: LaunchMode.externalApplication);
                        },
                        icon: const Icon(Icons.navigation, size: 20),
                        label: Text(l10n.myDayOpenAppleMaps),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2A6049),
                          side: const BorderSide(color: Color(0xFF2A6049)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 220.ms)
                .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
          ),
        ),
      ),
    );
  }

  /// Premium sheet row — white card, parchment border, forest icon well (matches Get Ready / Explore).
  Widget _activityOptionSheetTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    const wmForest = Color(0xFF2A6049);
    const wmForestTint = Color(0xFFEBF3EE);
    const wmParchment = Color(0xFFE8E2D8);
    const wmCharcoal = Color(0xFF1E1C18);
    const wmStone = Color(0xFF8C8780);

    final iconBg = destructive ? const Color(0xFFFFEBEE) : wmForestTint;
    final iconFg = destructive ? const Color(0xFFC62828) : wmForest;
    final titleColor = destructive ? const Color(0xFFC62828) : wmCharcoal;
    final subtitleColor = destructive ? const Color(0xFFCE8989) : wmStone;
    final cardColor = destructive ? const Color(0xFFFFF8F8) : Colors.white;
    final borderColor = destructive ? const Color(0xFFFFCDD2) : wmParchment;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTapDown: (_) => HapticFeedback.lightImpact(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconFg, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: subtitleColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActivityOptions(EnhancedActivityData activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F0E8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.of(sheetContext).padding.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E2D8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                AppLocalizations.of(context)!.myDayActivityOptionsTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1C18),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 20),
              if (activity.status == ActivityStatus.upcoming)
                _activityOptionSheetTile(
                  icon: Icons.rocket_launch_outlined,
                  title: AppLocalizations.of(context)!.myDayGetReadyButton,
                  subtitle: AppLocalizations.of(context)!.getReadyTitle,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    unawaited(_showRichGetReadySheet(activity));
                  },
                ),
              _activityOptionSheetTile(
                icon: Icons.info_outline_rounded,
                title: AppLocalizations.of(context)!.myDayViewDetails,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showActivityDetails(activity.rawData);
                },
              ),
              _activityOptionSheetTile(
                icon: Icons.bookmark_outline_rounded,
                title: AppLocalizations.of(context)!.myDaySaveForLater,
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(_saveActivity(activity.rawData));
                },
              ),
              if (activity.status == ActivityStatus.upcoming)
                _activityOptionSheetTile(
                  icon: Icons.place_rounded,
                  title: AppLocalizations.of(context)!.myDayImHere,
                  subtitle: AppLocalizations.of(context)!.myDayImHereSubtitle,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _checkInActivity(activity);
                  },
                ),
              if (activity.status == ActivityStatus.activeNow)
                _activityOptionSheetTile(
                  icon: Icons.check_circle_outline_rounded,
                  title: AppLocalizations.of(context)!.myDayDone,
                  subtitle: AppLocalizations.of(context)!.myDayDoneSubtitle,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _markActivityDone(activity);
                  },
                ),
              _activityOptionSheetTile(
                icon: Icons.ios_share_rounded,
                title: AppLocalizations.of(context)!.myDayShareActivity,
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(_shareActivityFromMap(activity.rawData));
                },
              ),
              _activityOptionSheetTile(
                icon: Icons.directions_rounded,
                title: AppLocalizations.of(context)!.activityDetailDirections,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openDirections(activity.rawData);
                },
              ),
              _activityOptionSheetTile(
                icon: Icons.delete_outline_rounded,
                title: AppLocalizations.of(context)!.myDayDeleteActivity,
                subtitle: AppLocalizations.of(context)!.myDayDeleteActivitySubtitle,
                destructive: true,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDeleteActivity(activity);
                },
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 200.ms)
              .slideY(begin: 0.03, end: 0, curve: Curves.easeOutCubic),
        ),
      ),
    );
  }

  Widget _buildFreeTimeCarousel() {
    final async = ref.watch(myDayFreeTimeActivitiesProvider);
    return async.when(
      data: (activities) => MyDayFreeTimeCarousel(
        activities: activities,
        onActivityTap: _showActivityDetails,
        onSaveTap: _saveActivity,
        onDirectionsTap: _openDirections,
      ),
      loading: () => MyDayFreeTimeCarousel(
        activities: const [],
        isLoading: true,
        onActivityTap: (_) {},
        onSaveTap: (_) {},
        onDirectionsTap: (_) {},
      ),
      error: (_, __) => MyDayFreeTimeCarousel(
        activities: const [],
        loadFailed: true,
        onActivityTap: (_) {},
        onSaveTap: (_) {},
        onDirectionsTap: (_) {},
      ),
    );
  }

  void _showWeatherDialog(BuildContext context, dynamic weather) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MyDayWeatherDialog(weather: weather);
      },
    );
  }

  Future<void> _saveActivity(Map<String, dynamic> activity) async {
    final l10n = AppLocalizations.of(context)!;
    final title =
        activity['title']?.toString().trim().isNotEmpty == true
            ? activity['title']!.toString().trim()
            : l10n.dayPlanCardActivity;
    try {
      final coords = _activityLatLng(activity);
      final rawId = activity['id']?.toString() ?? '';
      final placeIdField =
          activity['placeId']?.toString() ?? activity['place_id']?.toString();
      final id = (placeIdField != null && placeIdField.isNotEmpty)
          ? (placeIdField.startsWith('google_')
              ? placeIdField
              : 'google_$placeIdField')
          : 'myday_${rawId.isNotEmpty ? rawId : title.hashCode}';
      final lat = coords.lat ?? 0.0;
      final lng = coords.lng ?? 0.0;
      final imageUrl = activity['imageUrl']?.toString() ?? '';
      final address = activity['address']?.toString() ?? '';
      final place = Place(
        id: id,
        name: title,
        address: address,
        location: PlaceLocation(lat: lat, lng: lng),
        photos: imageUrl.isNotEmpty ? [imageUrl] : [],
        description: activity['description']?.toString(),
        types: const ['point_of_interest'],
      );
      await ref.read(savedPlacesServiceProvider).savePlace(place);
      if (!mounted) return;
      showWanderMoodToast(context, message: l10n.myDaySavedForLater(title));
    } catch (_) {
      if (!mounted) return;
      showWanderMoodToast(
        context,
        message: l10n.myDaySavePlaceFailed,
        isError: true,
      );
    }
  }

  Future<void> _shareActivityFromMap(Map<String, dynamic> activity) async {
    final l10n = AppLocalizations.of(context)!;
    final title = _safeActivityTitle(activity);
    final coords = _activityLatLng(activity);
    final buffer = StringBuffer(title);
    if (coords.lat != null && coords.lng != null) {
      buffer.writeln();
      buffer.write(
        'https://www.google.com/maps/search/?api=1&query=${coords.lat},${coords.lng}',
      );
    }
    try {
      await Share.share(buffer.toString(), subject: title);
    } catch (_) {
      if (!mounted) return;
      showWanderMoodToast(
        context,
        message: l10n.myDayShareFailed,
        isError: true,
      );
    }
  }

  void _confirmDeleteActivity(EnhancedActivityData activity) {
    final title = activity.rawData['title'] as String? ??
        AppLocalizations.of(context)!.dayPlanCardActivity;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.myDayDeleteConfirmTitle,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1C18),
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.myDayDeleteConfirmBody(title),
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _deleteActivity(activity);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.myDayDeleteActivityCta,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteActivity(EnhancedActivityData activity) async {
    final activityId = myDayStableActivityId(activity.rawData);
    final title = activity.rawData['title'] as String? ??
        AppLocalizations.of(context)!.dayPlanCardActivity;

    if (activityId.isEmpty) {
      showWanderMoodToast(
        context,
        message: AppLocalizations.of(context)!.myDayDeleteMissingId,
        isError: true,
      );
      return;
    }

    try {
      await ref.read(scheduledActivityServiceProvider).deleteScheduledActivity(activityId);
      ref.read(activityManagerProvider.notifier).clearLocalStatusForActivity(activityId);
      ref.invalidate(scheduledActivityServiceProvider);
      ref.invalidate(cachedActivitySuggestionsProvider);
      ref.invalidate(scheduledActivitiesForTodayProvider);
      ref.invalidate(todayActivitiesProvider);
      ref.invalidate(currentActivityStatusProvider);
      ref.invalidate(timelineCategorizedActivitiesProvider);

      if (!mounted) return;
      showWanderMoodToast(
        context,
        message: AppLocalizations.of(context)!.myDayDeletedFromPlan(title),
      );
    } catch (_) {
      if (!mounted) return;
      showWanderMoodToast(
        context,
        message: AppLocalizations.of(context)!.myDayDeleteFailed,
        isError: true,
      );
    }
  }

  void _openDirections(Map<String, dynamic> activity) async {
    try {
      final coords = _activityLatLng(activity);
      final lat = coords.lat;
      final lng = coords.lng;
      final title = _safeActivityTitle(activity);

      final appleUri = _appleMapsUri(lat, lng, title);
      final googleAppUri = _googleAppDirectionsUri(lat, lng, title);
      final googleWebUri = _googleWebDirectionsUri(lat, lng, title);

      final canOpenApple = await canLaunchUrl(appleUri);
      final canOpenGoogleApp = await canLaunchUrl(googleAppUri);

      if (!mounted) return;

      final options = <({String label, Uri uri})>[
        (
          label: AppLocalizations.of(context)!.myDayOpenGoogleMaps,
          uri: canOpenGoogleApp ? googleAppUri : googleWebUri,
        ),
        if (canOpenApple)
          (
            label: AppLocalizations.of(context)!.myDayOpenAppleMaps,
            uri: appleUri,
          ),
      ];

      if (options.length == 1) {
        await launchUrl(
          options.first.uri,
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E2D8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.myDayDirectionsNavigateTitle,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1C18),
                ),
              ),
              const SizedBox(height: 8),
              ...options.map(
                (opt) => ListTile(
                  leading: const Icon(Icons.map_outlined, color: Color(0xFF2A6049)),
                  title: Text(
                    opt.label,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E1C18),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await launchUrl(opt.uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      );
    } catch (e) {
      showWanderMoodToast(
        context,
        message: AppLocalizations.of(context)!.myDayUnableOpenDirections,
        isError: true,
      );
    }
  }

  void _showMoodyChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.chat_bubble_outline),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.myDayChatWithMoodyTitle,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.myDayChatWithMoodyComingSoon,
          style: GoogleFonts.poppins(
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for subtle dot pattern overlay
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    const double dotSize = 2.0;
    const double spacing = 20.0;
    
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmptyGreetingConfig {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color borderColor;
  final Color iconTint;

  const _EmptyGreetingConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.borderColor,
    required this.iconTint,
  });
}

/// Custom pressable button widget for enhanced UX
class _PressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _PressableButton({
    required this.child,
    required this.onPressed,
  });

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}