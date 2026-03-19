import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:wandermood/l10n/app_localizations.dart';
import 'dynamic_my_day_provider.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';
import '../../../profile/presentation/widgets/profile_drawer.dart';
import '../../../profile/domain/providers/profile_provider.dart';
import '../../../weather/providers/weather_provider.dart';
import '../../../places/providers/explore_places_provider.dart';
import '../../../places/providers/moody_explore_provider.dart';
import '../../../places/models/place.dart';
import '../../../../core/domain/providers/location_notifier_provider.dart';
import '../../../../core/providers/user_location_provider.dart';
import 'main_screen.dart';
import '../widgets/day_execution_hero_card.dart';
import '../widgets/my_day_free_time_carousel.dart';
import '../widgets/my_day_get_ready_sheet.dart';
import '../widgets/my_day_timeline_section.dart';
import '../widgets/my_day_weather_dialog.dart';
import 'package:wandermood/core/theme/time_based_theme.dart';
import '../../providers/time_suggestion_provider.dart';
import 'package:wandermood/core/presentation/painters/circle_pattern_painter.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';

class DynamicMyDayScreen extends ConsumerStatefulWidget {
  const DynamicMyDayScreen({super.key});

  @override
  ConsumerState<DynamicMyDayScreen> createState() => _DynamicMyDayScreenState();
}

class _DynamicMyDayScreenState extends ConsumerState<DynamicMyDayScreen> {
  String _selectedView = 'timeline'; // 'timeline' or 'list'
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, bool> _collapsedSections = {}; // Track which sections are collapsed
  
  bool _hasInitialized = false; // Prevent invalidate on hot reload
  DateTime? _lastRefreshTime; // ✅ Debounce refresh button
  
  @override
  void initState() {
    super.initState();
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
      backgroundColor: Colors.transparent,
      body: currentStatusValue?['type'] == 'no_plan'
          ? _buildImmersiveNoPlanState(l10n)
          : SwirlBackground(
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with profile button, title, and controls
                      _buildHeaderRow(isImmersive: false),
                      
                      const SizedBox(height: 12),
                      
                      // Dynamic greeting message
                      Text(
                        headerSubtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                      
                      const SizedBox(height: 12),
                      currentStatus.when(
                        data: (status) => _buildSmartStatusCard(status),
                        loading: () => _buildLoadingStatusCard(),
                        error: (error, stack) => _buildErrorStatusCard(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 0)),

            // Timeline or List View
            if (_selectedView == 'timeline')
              ...timelineActivities.when(
                data: (activities) => _buildTimelineView(activities),
                loading: () => [_buildLoadingSliver()],
                error: (error, stack) => [_buildErrorSliver()],
              )
            else
              ...timelineActivities.when(
                data: (activities) => _buildListView(activities),
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
      ),
    );
  }

  Widget _buildImmersiveNoPlanState(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    // We'll use the city from weather data since userLocationProvider only gives coordinates
    final weatherAsync = ref.watch(weatherProvider);
    final cityName = weatherAsync.valueOrNull?.location ?? 'your city';

    String bgImageUrl;
    String greeting;
    String subtitle;

    if (hour < 12) {
      bgImageUrl = 'https://images.unsplash.com/photo-1513622470522-26c308a908f7?q=80&w=1200&auto=format&fit=crop'; // Morning coffee/sunrise city
      greeting = l10n.goodMorning;
      subtitle = "The day is a blank canvas. What's the vibe?";
    } else if (hour < 17) {
      bgImageUrl = 'https://images.unsplash.com/photo-1514924013411-cbf25faa35bb?q=80&w=1200&auto=format&fit=crop'; // Vibrant city street day
      greeting = l10n.goodAfternoon;
      subtitle = "Ready for an adventure? What's the vibe?";
    } else {
      bgImageUrl = 'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?q=80&w=1200&auto=format&fit=crop'; // Beautiful city night
      greeting = l10n.goodEvening;
      subtitle = "The night is young. What's the vibe?";
    }

    return Stack(
      children: [
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: bgImageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.black87),
            errorWidget: (context, url, error) => Container(color: Colors.black87),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeaderRow(isImmersive: true),
                
                const Spacer(),
                
                Text(
                  '$greeting in $cityName!',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                
                const SizedBox(height: 12),
                
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                
                const SizedBox(height: 32),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildImmersiveActionButton(
                        icon: Icons.restaurant,
                        label: 'Grab a bite',
                        onTap: () => _navigateToTab(1),
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildImmersiveActionButton(
                        icon: Icons.explore_rounded,
                        label: 'Explore',
                        onTap: () => _navigateToTab(1),
                      ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildImmersiveActionButton(
                        icon: Icons.nightlife,
                        label: 'Nightlife',
                        onTap: () => _navigateToTab(1),
                      ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                GestureDetector(
                  onTap: () => _navigateToTab(2),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16C45B), Color(0xFF0E8E38)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16C45B).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Let Moody Plan It',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(vertical: 16),
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
    final titleColor = isImmersive ? Colors.white : const Color(0xFF12B347);
    final iconColor = isImmersive ? Colors.white : const Color(0xFF12B347);
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
        
        // Title
        Expanded(
          child: Text(
            'My Day',
            style: GoogleFonts.museoModerno(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: titleColor,
              letterSpacing: 0.5,
              shadows: isImmersive
                  ? [Shadow(color: shadowColor, blurRadius: 4, offset: const Offset(0, 2))]
                  : null,
            ),
          ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
        ),
        
        // Agenda and refresh
        Row(
          children: [
            // Temporary clear button for testing
            if (kDebugMode)
              IconButton(
                onPressed: () async {
                  try {
                    await ref.read(scheduledActivityServiceProvider).clearAllScheduledActivities();
                    ref.invalidate(scheduledActivitiesForTodayProvider);
                    ref.invalidate(cachedActivitySuggestionsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Plan cleared! (Debug)')),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error clearing: \$e');
                  }
                },
                icon: Icon(
                  Icons.delete_sweep,
                  color: Colors.redAccent,
                  size: 24,
                  shadows: isImmersive
                      ? [Shadow(color: shadowColor, blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
              ),
            // Agenda button
            IconButton(
              onPressed: () {
                context.push('/agenda');
              },
              icon: Icon(
                Icons.calendar_month,
                color: iconColor,
                size: 24,
                shadows: isImmersive
                    ? [Shadow(color: shadowColor, blurRadius: 4, offset: const Offset(0, 2))]
                    : null,
              ),
            ),
            // Refresh button
            IconButton(
              onPressed: () {
                final now = DateTime.now();
                if (_lastRefreshTime == null || now.difference(_lastRefreshTime!).inSeconds > 2) {
                  _lastRefreshTime = now;
                  debugPrint('🔄 My Day: Manual refresh triggered');
                  ref.invalidate(scheduledActivitiesForTodayProvider);
                  ref.invalidate(cachedActivitySuggestionsProvider);
                } else {
                  debugPrint('⏸️ My Day: Refresh blocked (debounced)');
                }
              },
              icon: Icon(
                Icons.refresh,
                color: iconColor,
                size: 24,
                shadows: isImmersive
                    ? [Shadow(color: shadowColor, blurRadius: 4, offset: const Offset(0, 2))]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            // Weather widget
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
                            color: isImmersive ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: isImmersive ? Border.all(color: Colors.white.withOpacity(0.3), width: 1) : null,
                            boxShadow: isImmersive ? null : [
                              BoxShadow(
                                color: shadowColor,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: isImmersive ? ImageFilter.blur(sigmaX: 5, sigmaY: 5) : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_off, color: isImmersive ? Colors.white : Colors.grey, size: 20),
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
                          color: isImmersive ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: isImmersive ? Border.all(color: Colors.white.withOpacity(0.3), width: 1) : null,
                          boxShadow: isImmersive ? null : [
                            BoxShadow(
                              color: shadowColor,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                      color: isImmersive ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: isImmersive ? Border.all(color: Colors.white.withOpacity(0.3), width: 1) : null,
                      boxShadow: isImmersive ? null : [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                      color: isImmersive ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: isImmersive ? Border.all(color: Colors.white.withOpacity(0.3), width: 1) : null,
                      boxShadow: isImmersive ? null : [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                ? NetworkImage(profile!.imageUrl!)
                : null,
            child: profile?.imageUrl == null
                ? Text(
                    profile?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isImmersive ? Colors.white : const Color(0xFF12B347),
                    ),
                  )
                : null,
          ),
          loading: () => CircleAvatar(
            radius: 20,
            backgroundColor: isImmersive ? Colors.transparent : Colors.white,
            child: Icon(
              Icons.person,
              color: isImmersive ? Colors.white : const Color(0xFF12B347),
              size: 20,
            ),
          ),
          error: (_, __) => CircleAvatar(
            radius: 20,
            backgroundColor: isImmersive ? Colors.transparent : Colors.white,
            child: Icon(
              Icons.person,
              color: isImmersive ? Colors.white : const Color(0xFF12B347),
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
      return DayExecutionHeroCard(
        activity: enhancedActivity,
        state: DayExecutionHeroState.active,
        onDirections: () => _showDirectionsOptions(status['activity']),
      );
    }

    if (status['type'] == 'awaiting_completion' && enhancedActivity != null) {
      return DayExecutionHeroCard(
        activity: enhancedActivity,
        state: DayExecutionHeroState.awaitingCompletion,
        onDirections: () => _showDirectionsOptions(status['activity']),
        onMarkDone: () => _markActivityDone(enhancedActivity),
        onStillHere: () => _keepActivityActive(enhancedActivity),
      );
    }

    if (status['type'] == 'upcoming' && enhancedActivity != null) {
      return DayExecutionHeroCard(
        activity: enhancedActivity,
        state: DayExecutionHeroState.upcoming,
        onDirections: () => _showDirectionsOptions(status['activity']),
        onGetReady: () => _showRichGetReadySheet(enhancedActivity),
      );
    }

    if (status['type'] == 'completed' && enhancedActivity != null) {
      return DayExecutionHeroCard(
        activity: enhancedActivity,
        state: DayExecutionHeroState.completed,
        onDirections: () => _showDirectionsOptions(status['activity']),
      );
    }

    if (status['type'] == 'free_time') {
      return _buildEnhancedFreeTimeCard(status);
    }

    return _buildEnhancedStatusCard(status);
  }

  Widget _buildNoPlanGreetingCard() {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    final timeConfig = TimeBasedTheme.getConfigForHour(hour);

    final config = _emptyStateGreetingConfig(
      l10n: l10n,
      hour: hour,
      timeConfig: timeConfig,
    );

    String bgImageUrl;
    if (hour < 12) {
      bgImageUrl = 'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?q=80&w=1200&auto=format&fit=crop';
    } else if (hour < 17) {
      bgImageUrl = 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1200&auto=format&fit=crop';
    } else {
      bgImageUrl = 'https://images.unsplash.com/photo-1514565131-fce0801e5785?q=80&w=1200&auto=format&fit=crop';
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: config.borderColor.withOpacity(0.3),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: bgImageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: config.gradientColors.first,
              ),
              errorWidget: (context, url, error) => Container(
                color: config.gradientColors.first,
              ),
            ),
          ),
          // Dark/Gradient Overlay for text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.white.withOpacity(0.1),
                        child: Icon(
                          config.icon,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                Text(
                  config.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
                const SizedBox(height: 10),
                Text(
                  config.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  Widget _buildEnhancedFreeTimeCard(Map<String, dynamic> status) {
    final hour = DateTime.now().hour;
    final timeConfig = TimeBasedTheme.getConfigForHour(hour);
    
    return Consumer(
      builder: (context, ref, child) {
        final suggestion = ref.watch(timeSuggestionProvider);
        
        return GestureDetector(
          onTap: () => _navigateToTab(1), // Navigate to explore tab
          child: Container(
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
                  
                      // Action buttons
                  Row(
                    children: [
                          _buildActionButton(
                            'Explore Nearby',
                                    Icons.explore,
                            () => _navigateToTab(1),
                                  ),
                          const SizedBox(width: 12),
                          _buildActionButton(
                            'Ask Moody',
                            Icons.chat_bubble_outline,
                            () => _navigateToTab(2), // Navigate to Moody Hub (tab 2)
                                    ),
                        ],
                                  ),
                                ],
                              ),
                            ),
              ],
                        ),
                      ),
        );
      },
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
                          child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
                                ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
              Icon(icon, size: 16, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                label,
                                    style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
    );
  }

  Widget _buildEnhancedStatusCard(Map<String, dynamic> status) {
    Color primaryColor;
    Color backgroundColor;
    IconData statusIcon;
    bool isUpcoming = false;
    
    switch (status['type']) {
      case 'upcoming':
        primaryColor = const Color(0xFF2196F3); // Blue for icon and top border
        backgroundColor = Colors.white; // White background
        statusIcon = Icons.schedule;
        isUpcoming = true;
        break;
      case 'completed':
        primaryColor = const Color(0xFF4CAF50);
        backgroundColor = const Color(0xFFE8F5E8);
        statusIcon = Icons.check_circle;
        break;
      default:
        primaryColor = const Color(0xFF12B347);
        backgroundColor = const Color(0xFFE8F5E8);
        statusIcon = Icons.explore;
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: isUpcoming 
            ? Border(top: BorderSide(color: primaryColor, width: 4)) 
            : Border.all(color: primaryColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
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
                    color: primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
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
                        status['title'],
                        style: GoogleFonts.museoModerno(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status['subtitle'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status['description'],
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
                    color: const Color(0xFF12B347),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF12B347).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _handleStatusAction(status['action2'], status),
                      child: Center(
                        child: Text(
                          isUpcoming ? 'Get Ready' : status['action2'],
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
                            border: Border.all(color: const Color(0xFF12B347), width: 1.5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () => _handleStatusAction(status['action1'], status),
                              child: Center(
                                child: Text(
                                  status['action1'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF12B347),
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
                            color: const Color(0xFF12B347),
                            border: null,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF12B347).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () => _handleStatusAction(status['action2'], status),
                              child: Center(
                                child: Text(
                                  status['action2'],
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
                child: CachedNetworkImage(
                  imageUrl: status['imageUrl'] ?? 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&q=80',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF12B347).withOpacity(0.8),
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
                                  'RIGHT NOW',
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
                            status['description'],
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
        color: const Color(0xFF12B347).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF12B347).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF12B347),
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
            strokeWidth: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStatusCard() {
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
                  '⚠️ ERROR',
                  style: GoogleFonts.museoModerno(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unable to load status',
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

    return [
      // Morning Section
      if (hasMorning)
        _buildTimelineSection(
          '🌅 Morning',
          'Start your day right',
          activities['morning']!,
          isFirstSection: firstVisibleSection == 'morning',
        ),
      
      // Afternoon Section  
      if (hasAfternoon)
        _buildTimelineSection(
          '🌞 Afternoon',
          'Peak adventure time',
          activities['afternoon']!,
          isFirstSection: firstVisibleSection == 'afternoon',
        ),
      
      // Evening Section
      if (hasEvening)
        _buildTimelineSection(
          '🌆 Evening',
          'Wind down and enjoy',
          activities['evening']!,
          isFirstSection: firstVisibleSection == 'evening',
        ),
      
      // Empty state if no activities
      if (activities.values.every((list) => list.isEmpty))
        _buildEmptyTimelineSliver(),
    ];
  }

  List<Widget> _buildListView(Map<String, List<EnhancedActivityData>> activities) {
    final allActivities = [
      ...activities['active'] ?? [],
      ...activities['awaiting'] ?? [],
      ...activities['upcoming'] ?? [],
      ...activities['completed'] ?? [],
    ];

    if (allActivities.isEmpty) {
      return [_buildEmptyTimelineSliver()];
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: allActivities.asMap().entries.map((entry) {
              final index = entry.key;
              final activity = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: MyDayTimelineActivityCard(
                  activity: activity,
                  onTap: () => _showActivityDetails(activity.rawData),
                  onDirectionsTap: () => _handleTimelinePrimaryAction(activity),
                  onMoreTap: () => _showActivityOptions(activity),
                  formatTime: _formatTime,
                ).animate(delay: (index * 100).ms)
                  .slideX(begin: 0.3, duration: 600.ms)
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.9, 0.9), duration: 400.ms),
              );
            }).toList(),
          ),
        ),
      ),
    ];
  }

  Widget _buildTimelineSection(
    String title,
    String subtitle,
    List<EnhancedActivityData> activities, {
    bool isFirstSection = false,
  }) {
    final sectionKey = title
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('🌅', '')
        .replaceAll('🌞', '')
        .replaceAll('🌆', '')
        .trim();

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
      formatTime: _formatTime,
    );
  }

  Widget _buildLoadingSliver() {
    return SliverToBoxAdapter(
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
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
                'Unable to load activities',
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
                  backgroundColor: const Color(0xFF12B347),
                  foregroundColor: Colors.white,
                ),
                child: Text('Retry'),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
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
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF12B347).withOpacity(0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      size: 38,
                      color: Color(0xFF12B347),
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
                        backgroundColor: const Color(0xFF16C45B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
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
                            l10n.myDayEmptyCreateButton,
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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.goNamed('main', extra: {'tab': 1}),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                            l10n.myDayEmptyBrowseButton,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.goNamed('main', extra: {'tab': 2}),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                            l10n.myDayEmptyAskMoodyButton,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey.shade200),
                  errorWidget: (context, url, error) => Container(color: Colors.grey.shade200),
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

    final hour = DateTime.now().hour;
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
    
    // Handle different status card actions
    switch (action) {
      case 'View Details':
        _showActivityDetails(status['activity']);
        break;
      case 'Get Ready':
        final enhancedActivity = status['enhancedActivity'] as EnhancedActivityData?;
        if (enhancedActivity != null) {
          _showRichGetReadySheet(enhancedActivity);
        } else {
          _prepareForActivity(status['activity']);
        }
        break;
      case 'Get Directions':
        _showDirectionsOptions(status['activity']);
        break;
      case 'Rate Experience':
        // TODO: Open rating dialog
        break;
      case 'Explore Nearby':
        debugPrint('🎯 Explore Nearby button pressed');
        _navigateToTab(1);
        break;
      case 'Ask Moody':
        debugPrint('🎯 Ask Moody button pressed');
        _navigateToTab(2);
        break;
    }
  }

  void _handleTimelinePrimaryAction(EnhancedActivityData activity) {
    if (activity.status == ActivityStatus.awaitingCompletion) {
      _markActivityDone(activity);
      return;
    }

    _openDirections(activity.rawData);
  }

  void _markActivityDone(EnhancedActivityData activity) {
    final activityId =
        activity.rawData['id'] as String? ??
        activity.rawData['title'] as String? ??
        '';
    if (activityId.isEmpty) return;

    ref.read(activityManagerProvider.notifier).clearCompletionPromptSnooze(
          activityId,
        );
    ref.read(activityManagerProvider.notifier).updateActivityStatus(
          activityId,
          ActivityStatus.completed,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Marked as done. You can review it now.',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF12B347),
      ),
    );
  }

  void _keepActivityActive(EnhancedActivityData activity) {
    final activityId =
        activity.rawData['id'] as String? ??
        activity.rawData['title'] as String? ??
        '';
    if (activityId.isEmpty) return;

    ref.read(activityManagerProvider.notifier).snoozeCompletionPrompt(
          activityId,
          duration: const Duration(minutes: 45),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Okay, we will check back in about 45 minutes.',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFFF59E0B),
      ),
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
  
  void _prepareForActivity(Map<String, dynamic> activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: Color(0xFF2196F3),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get Ready',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2196F3),
                        ),
                      ),
                      Text(
                        activity['title'] ?? 'Your upcoming activity',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Get Directions option
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              title: Text(
                'Get Directions',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Opens in maps app',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDirectionsOptions(activity);
              },
            ),
            
            const Divider(height: 16),
            
            // Call Venue option
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phone_outlined,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              title: Text(
                'Call Venue',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Confirm details or ask questions',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () {
                final phone = activity['phone'] ?? '';
                if (phone.isNotEmpty) {
                  launchUrl(Uri.parse('tel:$phone'));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No phone number available'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            
            const Divider(height: 16),
            
            // Add to Calendar option
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              title: Text(
                'Add to Calendar',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Set reminder and details',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () {
                // TODO: Implement calendar integration
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added to calendar'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // I'm Ready button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You\'re all set! Have a great time!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Color(0xFF12B347),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF12B347),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'I\'m Ready!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToTab(int tabIndex) async {
    // Add haptic feedback immediately for instant response
    HapticFeedback.lightImpact();
    
    // Show brief visual feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${tabIndex == 1 ? "Explore" : "Moody"} activated!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF12B347),
          duration: const Duration(milliseconds: 600),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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

  void _showActivityDetails(Map<String, dynamic> activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      // Activity image
                      Container(
                        height: 200,
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: activity['imageUrl'] ?? 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&q=80',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF12B347).withOpacity(0.8),
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
                      ),
                      
                      // Activity details
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              activity['title'] ?? 'Activity',
                              style: GoogleFonts.museoModerno(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Description
                            Text(
                              activity['description'] ?? 'A wonderful activity to enjoy',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Activity info
                            _buildInfoRow('Duration', '${activity['duration'] ?? 60} minutes'),
                            _buildInfoRow('Category', _capitalizeFirst(activity['category'] ?? 'General')),
                            _buildInfoRow('Best Time', _capitalizeFirst(activity['timeOfDay'] ?? 'Anytime')),
                            if (activity['startTime'] != null)
                              _buildInfoRow('Scheduled', _formatTime(DateTime.parse(activity['startTime']))),
                            
                            const SizedBox(height: 24),

                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _openDirections(activity);
                                    },
                                    icon: const Icon(Icons.directions),
                                    label: const Text('Get Directions'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF12B347),
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
                                      Navigator.pop(context);
                                      _saveActivity(activity);
                                    },
                                    icon: const Icon(Icons.bookmark_outline),
                                    label: const Text('Save for Later'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF12B347),
                                      side: const BorderSide(color: Color(0xFF12B347)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Extra bottom padding for safe area
                            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDirectionsOptions(Map<String, dynamic> activity) {
    // Show directions modal for booked activities
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Get Directions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose how you\'d like to get directions to ${activity['title']}',
              style: GoogleFonts.poppins(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.map),
                    label: const Text('Google Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF12B347),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.navigation),
                    label: const Text('Apple Maps'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF12B347),
                      side: const BorderSide(color: Color(0xFF12B347)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  void _showActivityOptions(EnhancedActivityData activity) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Activity Options',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            
            // View Details option
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFF12B347)),
              title: Text(
                'View Details',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _showActivityDetails(activity.rawData);
              },
            ),
            
            // Save for Later option
            ListTile(
              leading: const Icon(Icons.bookmark_outline, color: Color(0xFF12B347)),
              title: Text(
                'Save for Later',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _saveActivity(activity.rawData);
              },
            ),
            
            if (activity.status == ActivityStatus.awaitingCompletion)
              ListTile(
                leading: const Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFFF59E0B),
                ),
                title: Text(
                  'Still Here',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Keep this activity active a bit longer',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _keepActivityActive(activity);
                },
              ),
            if (activity.status == ActivityStatus.awaitingCompletion)
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF12B347),
                ),
                title: Text(
                  'Mark as Done',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Unlock review for this activity',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _markActivityDone(activity);
                },
              ),

            // Share option
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFF12B347)),
              title: Text(
                'Share Activity',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Share functionality coming soon!'),
                    backgroundColor: const Color(0xFF12B347),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions, color: Color(0xFF12B347)),
              title: Text(
                'Get Directions',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _openDirections(activity.rawData);
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildFreeTimeCarousel() {
    final activities = _getFreeTimeActivities();

    return MyDayFreeTimeCarousel(
      activities: activities,
      onActivityTap: _showActivityDetails,
      onSaveTap: _saveActivity,
      onDirectionsTap: _openDirections,
    );
  }

  List<Map<String, dynamic>> _getFreeTimeActivities() {
    // Get user's actual city from location provider
    final locationAsync = ref.watch(locationNotifierProvider);
    final city = locationAsync.valueOrNull ?? 'Rotterdam';
    
    // Get user's current position for accurate distance calculation
    final userPositionAsync = ref.watch(userLocationProvider);
    final userPosition = userPositionAsync.valueOrNull;
    
    // Use Edge Function data instead of old Google Places API
    return ref.watch(moodyExploreAutoProvider).when(
      data: (places) {
        if (places.isEmpty) {
          // Fallback to a few real places if API fails
          return [
            {
              'title': 'Markthal Rotterdam',
              'description': 'Iconic food market with local and international cuisine',
              'category': 'food',
              'distance': '1.2 km',
              'duration': 90,
              'imageUrl': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400&q=80',
            },
            {
              'title': 'Kralingse Bos',
              'description': 'Beautiful park with walking trails and lake',
              'category': 'nature',
              'distance': '3.5 km',
              'duration': 120,
              'imageUrl': 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&q=80',
            },
          ];
        }
        
        // Shuffle places to show different ones each time
        final shuffledPlaces = List<Place>.from(places)..shuffle(Random());
        
        // Convert real places to the format expected by the carousel (take 5 random ones)
        return shuffledPlaces.take(5).map((place) {
          // Determine category based on place types
          String category = 'culture';
          if (place.types.contains('restaurant') || place.types.contains('cafe') || place.types.contains('food')) {
            category = 'food';
          } else if (place.types.contains('park') || place.types.contains('nature')) {
            category = 'nature';
          } else if (place.types.contains('gym') || place.types.contains('fitness')) {
            category = 'exercise';
          }
          
          // Get image URL - use first photo if available, otherwise fallback
          String imageUrl = 'assets/images/fallbacks/default.jpg'; // Default fallback
          if (place.photos.isNotEmpty) {
            imageUrl = place.photos.first;
          } else {
            // Category-specific fallback images using existing assets
            switch (category) {
              case 'food':
                imageUrl = 'assets/images/fallbacks/restaurant.jpg';
                break;
              case 'nature':
                imageUrl = 'assets/images/fallbacks/park.jpg';
                break;
              case 'exercise':
                imageUrl = 'assets/images/fallbacks/default.jpg';
                break;
              default:
                imageUrl = 'assets/images/fallbacks/default.jpg';
            }
          }
          
          // Calculate estimated duration based on place type
          int duration = 60; // Default 1 hour
          if (place.types.contains('restaurant')) {
            duration = 90;
          } else if (place.types.contains('museum')) {
            duration = 120;
          } else if (place.types.contains('park')) {
            duration = 75;
          }
          
          // Calculate distance from user's actual location (or city center as fallback)
          double userLat, userLng;
          if (userPosition != null) {
            userLat = userPosition.latitude;
            userLng = userPosition.longitude;
          } else {
            // Fallback to city center coordinates
            final cityCoords = _getCityCoordinates(city);
            userLat = cityCoords['lat']!;
            userLng = cityCoords['lng']!;
          }
          
          final distance = _calculateDistance(
            userLat, userLng,
            place.location.lat, place.location.lng,
          );
          
          return {
            'title': place.name,
            'description': place.description ?? 'Discover this amazing place in $city',
            'category': category,
            'distance': '${distance.toStringAsFixed(1)} km',
            'duration': duration,
            'imageUrl': imageUrl,
            'place': place, // Store the original place object for navigation
          };
        }).toList();
      },
      loading: () => [
        {
          'title': 'Loading...',
          'description': 'Finding great activities near you',
          'category': 'loading',
          'distance': '--',
          'duration': 0,
          'imageUrl': 'assets/images/fallbacks/default.jpg',
        }
      ],
      error: (error, stack) => [
        {
          'title': 'Markthal Rotterdam',
          'description': 'Iconic food market with local and international cuisine',
          'category': 'food',
          'distance': '1.2 km',
          'duration': 90,
          'imageUrl': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400&q=80',
        },
        {
          'title': 'Erasmus Bridge',
          'description': 'Iconic bridge perfect for photos and walks',
          'category': 'culture',
          'distance': '0.8 km',
          'duration': 30,
          'imageUrl': 'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=400&q=80',
        },
      ],
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

  // Helper method to calculate distance between two coordinates using Haversine formula
  // Helper method to get city coordinates
  Map<String, double> _getCityCoordinates(String cityName) {
    final cityCoords = <String, Map<String, double>>{
      'Rotterdam': {'lat': 51.9225, 'lng': 4.4792},
      'Amsterdam': {'lat': 52.3676, 'lng': 4.9041},
      'The Hague': {'lat': 52.0705, 'lng': 4.3007},
      'Utrecht': {'lat': 52.0907, 'lng': 5.1214},
      'Eindhoven': {'lat': 51.4416, 'lng': 5.4697},
      'Groningen': {'lat': 53.2194, 'lng': 6.5665},
      'Delft': {'lat': 52.0067, 'lng': 4.3556},
    };
    return cityCoords[cityName] ?? cityCoords['Rotterdam']!;
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreeToRadian(lat2 - lat1);
    final double dLng = _degreeToRadian(lng2 - lng1);
    final double lat1Rad = _degreeToRadian(lat1);
    final double lat2Rad = _degreeToRadian(lat2);
    
    final double a = 
        pow(sin(dLat / 2), 2) +
        cos(lat1Rad) * cos(lat2Rad) * 
        pow(sin(dLng / 2), 2);
    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _degreeToRadian(double degree) {
    return degree * (pi / 180);
  }

  void _saveActivity(Map<String, dynamic> activity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${activity['title']} saved for later!',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF12B347),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _showActivityDetails(activity),
        ),
      ),
    );
  }

  void _openDirections(Map<String, dynamic> activity) async {
    try {
      // Check if maps are available
      final availableMaps = await MapLauncher.installedMaps;
      
      if (availableMaps.isNotEmpty) {
        // Use the first available map app
        await availableMaps.first.showMarker(
          coords: Coords(40.7128, -74.0060), // Default NYC coordinates
          title: activity['title'] ?? 'Activity Location',
          description: activity['description'] ?? '',
        );
      } else {
        // Fallback to Google Maps web
        final url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(activity['title'] ?? 'Activity')}'
        );
        
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not open maps';
        }
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open directions',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
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
              'Chat with Moody',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Coming soon! Moody will be able to help you plan your day and suggest activities based on your mood and preferences.',
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
