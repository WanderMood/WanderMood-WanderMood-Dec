import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'dynamic_my_day_provider.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';
import '../../../profile/presentation/widgets/profile_drawer.dart';
import '../../../profile/domain/providers/profile_provider.dart';
import '../../../weather/providers/weather_provider.dart';
import '../../../places/providers/explore_places_provider.dart';
import 'main_screen.dart';
import 'package:wandermood/core/theme/time_based_theme.dart';
import '../../providers/time_suggestion_provider.dart';
import 'package:wandermood/core/presentation/painters/circle_pattern_painter.dart';

class DynamicMyDayScreen extends ConsumerStatefulWidget {
  const DynamicMyDayScreen({super.key});

  @override
  ConsumerState<DynamicMyDayScreen> createState() => _DynamicMyDayScreenState();
}

class _DynamicMyDayScreenState extends ConsumerState<DynamicMyDayScreen> {
  String _selectedView = 'timeline'; // 'timeline' or 'list'
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, bool> _collapsedSections = {}; // Track which sections are collapsed
  
  @override
  void initState() {
    super.initState();
    // Refresh data when the screen loads - delay properly to avoid build cycle conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
        if (mounted) {
      ref.invalidate(cachedActivitySuggestionsProvider);
        }
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 DynamicMyDayScreen: Building My Day screen');
    final greetingMessage = ref.watch(greetingMessageProvider);
    final currentStatus = ref.watch(currentActivityStatusProvider);
    final timelineActivities = ref.watch(timelineCategorizedActivitiesProvider);
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: const ProfileDrawer(),
      backgroundColor: Colors.transparent,
      body: SwirlBackground(
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
                      Row(
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
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Consumer(
                                builder: (context, ref, child) {
                                  final profileData = ref.watch(profileProvider);
                                  return profileData.when(
                                    data: (profile) => CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.white,
                                      backgroundImage: profile?.imageUrl != null
                                          ? NetworkImage(profile!.imageUrl!)
                                          : null,
                                      child: profile?.imageUrl == null
                                          ? Text(
                                              profile?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF12B347),
                                              ),
                                            )
                                          : null,
                                    ),
                                    loading: () => CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.person,
                                        color: const Color(0xFF12B347),
                                        size: 20,
                                      ),
                                    ),
                                    error: (_, __) => CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.person,
                                        color: const Color(0xFF12B347),
                                        size: 20,
                                      ),
                                    ),
                                  );
                                },
                              ),
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
                                color: const Color(0xFF12B347),
                                letterSpacing: 0.5,
                              ),
                            ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
                          ),
                          
                          // Agenda and refresh
                          Row(
                            children: [
                              // Agenda button
                              IconButton(
                                onPressed: () {
                                  context.push('/agenda');
                                },
                                icon: const Icon(
                                  Icons.calendar_month,
                                  color: Color(0xFF12B347),
                                  size: 24,
                                ),
                              ),
                              // Refresh button
                              IconButton(
                                onPressed: () {
                                  // Refresh activities
                                  ref.invalidate(cachedActivitySuggestionsProvider);
                                },
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Color(0xFF12B347),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Weather widget - now with real data and clickable!
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
                                              color: Colors.white.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.cloud_off, color: Colors.grey, size: 20),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '--°',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                      
                                      // Get appropriate weather icon
                                      IconData weatherIcon;
                                      Color iconColor;
                                      switch (weather.condition.toLowerCase()) {
                                        case 'clear':
                                          weatherIcon = Icons.wb_sunny;
                                          iconColor = Colors.orange;
                                          break;
                                        case 'clouds':
                                          weatherIcon = Icons.cloud;
                                          iconColor = Colors.grey[600]!;
                                          break;
                                        case 'rain':
                                          weatherIcon = Icons.water_drop;
                                          iconColor = Colors.blue;
                                          break;
                                        case 'snow':
                                          weatherIcon = Icons.ac_unit;
                                          iconColor = Colors.lightBlue;
                                          break;
                                        case 'thunderstorm':
                                          weatherIcon = Icons.flash_on;
                                          iconColor = Colors.deepPurple;
                                          break;
                                        case 'mist':
                                        case 'fog':
                                          weatherIcon = Icons.blur_on;
                                          iconColor = Colors.grey[500]!;
                                          break;
                                        default:
                                          weatherIcon = Icons.wb_sunny;
                                          iconColor = Colors.orange;
                                      }
                                      
                                      return GestureDetector(
                                        onTap: () => _showWeatherDialog(context, weather),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.9),
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(weatherIcon, color: iconColor, size: 20),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${weather.temperature.round()}°',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    loading: () => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
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
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '...°',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    error: (_, __) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
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
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Dynamic greeting message
                      Text(
                        greetingMessage,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Smart Status Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: currentStatus.when(
                  data: (status) => _buildSmartStatusCard(status),
                  loading: () => _buildLoadingStatusCard(),
                  error: (error, stack) => _buildErrorStatusCard(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

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

  Widget _buildSmartStatusCard(Map<String, dynamic> status) {
    // If it's the "Right Now" card, create a hero card
    if (status['type'] == 'active') {
      return _buildRightNowCard(status);
    }
    
    // For free time card, create the stunning new design
    if (status['type'] == 'free_time') {
      return _buildEnhancedFreeTimeCard(status);
    }
    
    // For other types (upcoming, completed), use enhanced versions
    return _buildEnhancedStatusCard(status);
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
                            () => _showMoodyChatDialog(),
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
    
    switch (status['type']) {
      case 'upcoming':
        primaryColor = const Color(0xFFFF9800);
        backgroundColor = const Color(0xFFFFF3E0);
        statusIcon = Icons.schedule;
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
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
              Row(
                children: [
                  if (status['action1'] != null)
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryColor, width: 1.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _handleStatusAction(status['action1'], status),
                            child: Center(
                              child: Text(
                                status['action1'],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
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
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _handleStatusAction(status['action2'], status),
                            child: Center(
                              child: Text(
                                status['action2'],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
    return [
      // Morning Section
      if (activities['morning']?.isNotEmpty == true)
        _buildTimelineSection('🌅 Morning', 'Start your day right', activities['morning']!),
      
      // Afternoon Section  
      if (activities['afternoon']?.isNotEmpty == true)
        _buildTimelineSection('🌞 Afternoon', 'Peak adventure time', activities['afternoon']!),
      
      // Evening Section
      if (activities['evening']?.isNotEmpty == true)
        _buildTimelineSection('🌆 Evening', 'Wind down and enjoy', activities['evening']!),
      
      // Empty state if no activities
      if (activities.values.every((list) => list.isEmpty))
        _buildEmptyTimelineSliver(),
    ];
  }

  List<Widget> _buildListView(Map<String, List<EnhancedActivityData>> activities) {
    final allActivities = [
      ...activities['active'] ?? [],
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
                child: _buildEnhancedActivityCard(activity).animate(delay: (index * 100).ms)
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

  Widget _buildTimelineSection(String title, String subtitle, List<EnhancedActivityData> activities) {
    // Check if all activities in this section are completed
    bool allCompleted = activities.every((activity) => 
      activity.status == ActivityStatus.completed
    );
    
    // Get the section key for tracking collapse state
    String sectionKey = title.toLowerCase().replaceAll(' ', '_').replaceAll('🌅', '').replaceAll('🌞', '').replaceAll('🌆', '').trim();
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                if (allCompleted) {
                  setState(() {
                    _collapsedSections[sectionKey] = !(_collapsedSections[sectionKey] ?? false);
                  });
                }
              },
              child: Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.museoModerno(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: allCompleted ? const Color(0xFF12B347) : const Color(0xFF12B347),
                    ),
                  ),
                  if (allCompleted) ...[
                    const SizedBox(width: 8),
                    Icon(
                      (_collapsedSections[sectionKey] ?? false) 
                          ? Icons.expand_more 
                          : Icons.expand_less,
                      color: const Color(0xFF12B347),
                      size: 18,
                    ),
                  ],
                  const Spacer(),
                  if (allCompleted) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12B347).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF12B347).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF12B347),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'All Done',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF12B347),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '${activities.length} ${activities.length == 1 ? 'activity' : 'activities'}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: allCompleted ? const Color(0xFF12B347) : Colors.grey[600],
                      fontWeight: allCompleted ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              allCompleted ? 'Great job completing this section!' : subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: allCompleted ? const Color(0xFF12B347) : Colors.grey[600],
                fontWeight: allCompleted ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 16),
            // Show activities only if not collapsed
            if (!allCompleted || !(_collapsedSections[sectionKey] ?? false))
              ...activities.asMap().entries.map((entry) {
                final index = entry.key;
                final activity = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildEnhancedActivityCard(activity).animate(delay: (index * 100).ms)
                    .slideX(begin: 0.3, duration: 600.ms)
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.9, 0.9), duration: 400.ms),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedActivityCard(EnhancedActivityData activity) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (activity.status) {
      case ActivityStatus.activeNow:
        statusColor = Colors.red;
        statusText = 'RIGHT NOW';
        statusIcon = Icons.play_circle_filled;
        break;
      case ActivityStatus.upcoming:
        statusColor = Colors.orange;
        statusText = 'UPCOMING';
        statusIcon = Icons.schedule;
        break;
      case ActivityStatus.completed:
        statusColor = Colors.green;
        statusText = 'COMPLETED';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = const Color(0xFF12B347);
        statusText = 'SCHEDULED';
        statusIcon = Icons.event;
    }
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showActivityDetails(activity.rawData);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 15),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: statusColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image with color filter for intensity
              Positioned.fill(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.1),
                    BlendMode.multiply,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: activity.rawData['imageUrl'] ?? '',
                    fit: BoxFit.cover,
                    color: Colors.transparent,
                    colorBlendMode: BlendMode.multiply,
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
                            statusColor.withOpacity(0.8),
                            statusColor.withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.white, size: 40),
                      ),
                    ),
                  ),
                ),
              ),

              // Intense overlay for dramatic effect
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.2, 1.0],
                    ),
                  ),
                ),
              ),

              // Content - simplified
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row - time and status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Time badge - no border
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_formatTime(activity.startTime)} • ${activity.rawData['duration']}m',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Status badge - no border
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Bottom content - just title, no container
                      Text(
                        activity.rawData['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.8),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No activities planned for today',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ready to plan something amazing?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => context.goNamed('main', extra: {'tab': 1}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF12B347),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('Explore Places'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () => context.goNamed('main', extra: {'tab': 2}),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF12B347),
                      side: const BorderSide(color: Color(0xFF12B347)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('Ask Moody'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleStatusAction(String action, Map<String, dynamic> status) {
    // Provide immediate feedback for button press
    HapticFeedback.lightImpact();
    
    // Handle different status card actions
    switch (action) {
      case 'View Details':
        // TODO: Navigate to activity details
        break;
      case 'Get Directions':
        // TODO: Open maps
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
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.bookmark_outline),
                                    label: const Text('Save for Later'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF12B347),
                                      side: const BorderSide(color: Color(0xFF12B347)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      // TODO: Add navigation to maps or more details
                                    },
                                    icon: const Icon(Icons.directions),
                                    label: const Text('Get Directions'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF12B347),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                '✨ Free Time Activities',
                style: GoogleFonts.museoModerno(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF12B347),
                ),
              ),
              const Spacer(),
              Text(
                'Near you',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Discover what you can do right now',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Horizontal scrollable carousel
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _getFreeTimeActivities().length,
            itemBuilder: (context, index) {
              final activity = _getFreeTimeActivities()[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildFreeTimeCard(activity).animate(delay: (index * 200).ms)
                  .slideX(begin: 0.3, duration: 600.ms)
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.9, 0.9), duration: 400.ms),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFreeTimeCard(Map<String, dynamic> activity) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showActivityDetails(activity);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 280,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 25,
              offset: const Offset(0, 12),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFF12B347).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image with color filter for intensity
              Positioned.fill(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.1),
                    BlendMode.multiply,
                  ),
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
                        child: Icon(Icons.image, color: Colors.white, size: 40),
                      ),
                    ),
                  ),
                ),
              ),

              // Intense overlay for dramatic effect
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.2, 1.0],
                    ),
                  ),
                ),
              ),

              // Content - simplified
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Distance and category badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Distance badge - no border
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.place,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  activity['distance'] ?? '0.5 km',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF12B347),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getCategoryIcon(activity['category'] ?? ''),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Title - just text, no container
                      Text(
                        activity['title'] ?? 'Activity',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.8),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Description - smaller text
                      Text(
                        activity['description'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Action buttons - no borders
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _saveActivity(activity),
                                  child: Center(
                                    child: Text(
                                      'Save',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF12B347),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _openDirections(activity),
                                  child: Center(
                                    child: Text(
                                      'Directions',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFreeTimeActivities() {
    // Use real places data from explorePlacesProvider instead of mock data
    return ref.watch(explorePlacesProvider(city: 'Rotterdam')).when(
      data: (places) {
        if (places.isEmpty) {
          // Fallback to a few real Rotterdam places if API fails
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
        
        // Convert real places to the format expected by the carousel
        return places.take(5).map((place) {
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
          
          // Calculate distance from Rotterdam center (default user location)
          final rotterdamLat = 51.9225;
          final rotterdamLng = 4.4792;
          final distance = _calculateDistance(
            rotterdamLat, rotterdamLng,
            place.location.lat, place.location.lng,
          );
          
          return {
            'title': place.name,
            'description': place.description ?? 'Discover this amazing place in Rotterdam',
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weather in Rotterdam',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.blue.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (weather != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getWeatherIconForDialog(weather.condition),
                        size: 64,
                        color: _getWeatherColorForDialog(weather.condition),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${weather.temperature.round()}°C',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          Text(
                            weather.condition,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildWeatherDetail('Feels Like', '${weather.details['feelsLike']?.round() ?? '--'}°C'),
                        const SizedBox(height: 8),
                        _buildWeatherDetail('Humidity', '${weather.details['humidity'] ?? '--'}%'),
                        const SizedBox(height: 8),
                        _buildWeatherDetail('Description', weather.details['description'] ?? 'Clear skies'),
                      ],
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.cloud_off,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Weather data unavailable',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'Please check your internet connection',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeatherDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.blue.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIconForDialog(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.water_drop;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'mist':
      case 'fog':
        return Icons.blur_on;
      default:
        return Icons.wb_sunny;
    }
  }

  Color _getWeatherColorForDialog(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Colors.orange;
      case 'clouds':
        return Colors.grey.shade600;
      case 'rain':
        return Colors.blue;
      case 'snow':
        return Colors.lightBlue;
      case 'thunderstorm':
        return Colors.deepPurple;
      case 'mist':
      case 'fog':
        return Colors.grey.shade500;
      default:
        return Colors.orange;
    }
  }

  // Helper method to calculate distance between two coordinates using Haversine formula
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

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return '🍽️';
      case 'exercise':
        return '🏃‍♂️';
      case 'culture':
        return '🎨';
      case 'entertainment':
        return '🎭';
      case 'shopping':
        return '🛍️';
      case 'social':
        return '👥';
      case 'nature':
        return '🌳';
      default:
        return '📍';
    }
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