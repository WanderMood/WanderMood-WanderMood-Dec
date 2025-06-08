import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/home/presentation/screens/mood_home_screen.dart';
import 'package:wandermood/features/home/presentation/screens/explore_screen.dart';
import 'package:wandermood/features/profile/presentation/screens/profile_screen.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/features/auth/providers/user_provider.dart';
import 'package:wandermood/features/weather/providers/weather_provider.dart';
import 'package:wandermood/features/profile/presentation/widgets/profile_drawer.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';
import 'package:wandermood/core/domain/entities/location.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/providers/explore_places_provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/home/domain/providers/main_tab_provider.dart';
import 'package:wandermood/features/gamification/providers/gamification_provider.dart';
import 'package:wandermood/features/weather/presentation/screens/weather_detail_screen.dart';
import 'package:wandermood/features/social/presentation/screens/social_hub_screen.dart';
import 'package:wandermood/features/home/presentation/screens/daily_schedule_screen.dart';
import 'package:wandermood/features/plans/widgets/activity_detail_screen.dart';
import 'package:wandermood/features/home/presentation/screens/free_time_activities_screen.dart';

// Create a Provider for the tab controller
final mainTabProvider = StateProvider<int>((ref) => 0);

// Provider for nearby places - hardcoded Dutch places for the carousel
final nearbyPlacesProvider = FutureProvider<List<Place>>((ref) async {
  // Return a list of hardcoded places for Netherlands
  return [
    Place(
      id: 'van_gogh_museum',
      name: 'Van Gogh Museum',
      address: 'Museumplein 6, 1071 DJ Amsterdam',
      rating: 4.8,
      photos: ['assets/images/fallbacks/default.jpg'],
      types: ['museum', 'tourist_attraction'],
      location: const PlaceLocation(lat: 52.3584, lng: 4.8811),
      description: 'Museum dedicated to the works of Vincent van Gogh and his contemporaries',
      emoji: '🎨',
      tag: 'Culture',
      isAsset: true,
      activities: ['Art', 'Museum', 'Cultural Experience'],
    ),
    Place(
      id: 'strijp_s',
      name: 'Strijp-S',
      address: 'Torenallee 20, 5617 BC Eindhoven',
      rating: 4.6,
      photos: ['assets/images/fallbacks/default.jpg'],
      types: ['point_of_interest', 'cultural'],
      location: const PlaceLocation(lat: 51.4477, lng: 5.4543),
      description: 'Former Philips industrial complex turned into creative and cultural hub',
      emoji: '🏭',
      tag: 'Culture',
      isAsset: true,
      activities: ['Shopping', 'Dining', 'Cultural Experience'],
    ),
    Place(
      id: 'evoluon',
      name: 'Evoluon',
      address: 'Noord Brabantlaan 1A, 5652 LA Eindhoven',
      rating: 4.5,
      photos: ['assets/images/fallbacks/default.jpg'],
      types: ['tourist_attraction', 'landmark'],
      location: const PlaceLocation(lat: 51.4435, lng: 5.4474),
      description: 'Iconic flying saucer-shaped building and former science museum',
      emoji: '🛸',
      tag: 'Landmark',
      isAsset: true,
      activities: ['Sightseeing', 'Photography', 'Events'],
    ),
    Place(
      id: 'keukenhof',
      name: 'Keukenhof Gardens',
      address: 'Stationsweg 166A, 2161 AM Lisse',
      rating: 4.8,
      photos: ['assets/images/fallbacks/default.jpg'],
      types: ['tourist_attraction', 'park'],
      location: const PlaceLocation(lat: 52.2710, lng: 4.5465),
      description: 'One of the world\'s largest flower gardens with stunning tulip displays',
      emoji: '🌷',
      tag: 'Nature',
      isAsset: true,
      activities: ['Nature', 'Photography', 'Walking'],
    ),
    Place(
      id: 'van_abbemuseum',
      name: 'Van Abbemuseum',
      address: 'Bilderdijklaan 10, 5611 NH Eindhoven',
      rating: 4.4,
      photos: ['assets/images/fallbacks/default.jpg'],
      types: ['museum', 'art'],
      location: const PlaceLocation(lat: 51.4360, lng: 5.4834),
      description: 'Modern and contemporary art museum in Eindhoven',
      emoji: '🏛️',
      tag: 'Culture',
      isAsset: true,
      activities: ['Art', 'Museum', 'Cultural Experience'],
    ),
  ];
});

// MyDay Screen - Home
class MyDayScreen extends ConsumerStatefulWidget {
  const MyDayScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MyDayScreen> createState() => _MyDayScreenState();
}

class _MyDayScreenState extends ConsumerState<MyDayScreen> {
  List<Activity>? _scheduledActivities;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadScheduledActivities();
  }
  
  // Load activities from the service
  Future<void> _loadScheduledActivities() async {
      setState(() {
        _isLoading = true;
      });
    
    try {
      final scheduledActivityService = ref.read(scheduledActivityServiceProvider);
      final activities = await scheduledActivityService.getScheduledActivities();
      
      if (mounted) {
        setState(() {
          _scheduledActivities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading scheduled activities: $e');
      if (mounted) {
        setState(() {
          _scheduledActivities = [];
          _isLoading = false;
        });
      }
    }
  }
  
  // Helper method to format time
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    return '$formattedHour:$minute $period';
  }
  
  // Get greeting text based on time of day
  String _getGreetingText(int hour) {
    if (hour < 12) {
      return 'Good morning! Here\'s your day ahead.';
    } else if (hour < 17) {
      return 'Good afternoon! Here\'s what\'s coming up.';
    } else {
      return 'Good evening! Here\'s your schedule.';
    }
    }
    
  // Helper methods for current activity card
  String _getCurrentActivityStatus() {
    if (_scheduledActivities == null || _scheduledActivities!.isEmpty) {
      return 'Free Time';
    }
    
    final now = DateTime.now();
    // Find current activity
    for (final activity in _scheduledActivities!) {
      final activityEnd = activity.startTime.add(Duration(minutes: activity.duration));
      if (now.isAfter(activity.startTime) && now.isBefore(activityEnd)) {
        return 'Happening Now';
      }
    }
    
    // Find next activity
    final upcomingActivities = _scheduledActivities!
        .where((a) => a.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    if (upcomingActivities.isNotEmpty) {
      final nextActivity = upcomingActivities.first;
      final minutesUntil = nextActivity.startTime.difference(now).inMinutes;
      
      if (minutesUntil < 60) {
        return 'Starting Soon';
      } else {
        return 'Coming Up';
      }
    }
    
    return 'Free Time';
  }
  
  String _getCurrentOrNextActivityTime() {
    if (_scheduledActivities == null || _scheduledActivities!.isEmpty) {
      return 'All Day';
    }
    
    final now = DateTime.now();
    
    // Find current activity
    for (final activity in _scheduledActivities!) {
      final activityEnd = activity.startTime.add(Duration(minutes: activity.duration));
      if (now.isAfter(activity.startTime) && now.isBefore(activityEnd)) {
        return '${_formatTime(activity.startTime)} - ${_formatTime(activityEnd)}';
      }
    }
    
    // Find next activity
    final upcomingActivities = _scheduledActivities!
        .where((a) => a.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    if (upcomingActivities.isNotEmpty) {
      final nextActivity = upcomingActivities.first;
      final activityEnd = nextActivity.startTime.add(Duration(minutes: nextActivity.duration));
      return '${_formatTime(nextActivity.startTime)} - ${_formatTime(activityEnd)}';
  }
  
    return 'All Day';
  }
  
  String _getCurrentOrNextActivityName() {
    if (_scheduledActivities == null || _scheduledActivities!.isEmpty) {
      return 'No Scheduled Activities';
    }
    
    final now = DateTime.now();
    
    // Find current activity
    for (final activity in _scheduledActivities!) {
      final activityEnd = activity.startTime.add(Duration(minutes: activity.duration));
      if (now.isAfter(activity.startTime) && now.isBefore(activityEnd)) {
        return activity.name;
      }
    }
    
    // Find next activity
    final upcomingActivities = _scheduledActivities!
        .where((a) => a.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    if (upcomingActivities.isNotEmpty) {
      return upcomingActivities.first.name;
  }
  
    return 'Free Time - Explore Nearby Places';
  }
  
  String _getCurrentOrNextActivityLocation() {
    if (_scheduledActivities == null || _scheduledActivities!.isEmpty) {
      return 'Take some time to relax or explore';
    }
    
    final now = DateTime.now();
    
    // Find current activity
    for (final activity in _scheduledActivities!) {
      final activityEnd = activity.startTime.add(Duration(minutes: activity.duration));
      if (now.isAfter(activity.startTime) && now.isBefore(activityEnd)) {
        return activity.location.toString().contains('LatLng') 
            ? 'Rotterdam City Center' 
            : activity.location.toString();
      }
    }
    
    // Find next activity
    final upcomingActivities = _scheduledActivities!
        .where((a) => a.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    if (upcomingActivities.isNotEmpty) {
      return upcomingActivities.first.location.toString().contains('LatLng') 
          ? 'Rotterdam City Center' 
          : upcomingActivities.first.location.toString();
  }
  
    return 'Take some time to relax or explore';
  }
  
  bool _isCurrentActivityPastDue() {
    // This method is for checking if the current activity is past due
    // For simplicity, we'll always return false (no warning needed)
    return false;
  }

  // Get the main planned activities (upcoming only, max 3 for main screen)
  List<Activity> _getMainPlannedActivities() {
    if (_scheduledActivities == null || _scheduledActivities!.isEmpty) {
      return [];
    }
    
    print('📋 Total activities loaded: ${_scheduledActivities!.length}');
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Filter activities that are UPCOMING (not past)
    final upcomingActivities = _scheduledActivities!.where((activity) {
      final activityDate = DateTime(activity.startTime.year, activity.startTime.month, activity.startTime.day);
      final isToday = activityDate.isAtSameMomentAs(today);
      final isFuture = activityDate.isAfter(today);
      
      // For today's activities, only include if they haven't started yet
      if (isToday) {
        return activity.startTime.isAfter(now);
      }
      
      return isFuture;
    }).toList();
    
    // Remove duplicates by name
    final Map<String, Activity> uniqueActivities = {};
    for (final activity in upcomingActivities) {
      if (!uniqueActivities.containsKey(activity.name)) {
        uniqueActivities[activity.name] = activity;
      }
    }
    
    // Convert back to list and sort by start time
    final sortedActivities = uniqueActivities.values.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // Limit to 3 activities max for main screen
    final limitedActivities = sortedActivities.take(3).toList();
    
    print('🎯 Found ${limitedActivities.length} UPCOMING activities for Daily Schedule:');
    for (var activity in limitedActivities) {
      print('   ✅ ${activity.name} at ${activity.startTime}');
    }
    
    return limitedActivities;
  }

  // Get past activities (for "View All" section)
  List<Activity> _getPastActivities() {
    if (_scheduledActivities == null || _scheduledActivities!.isEmpty) {
      return [];
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Filter activities that have already passed
    final pastActivities = _scheduledActivities!.where((activity) {
      final activityDate = DateTime(activity.startTime.year, activity.startTime.month, activity.startTime.day);
      final isToday = activityDate.isAtSameMomentAs(today);
      final isPast = activityDate.isBefore(today);
      
      // For today's activities, include if they have already started/ended
      if (isToday) {
        final activityEnd = activity.startTime.add(Duration(minutes: activity.duration));
        return activityEnd.isBefore(now);
      }
      
      return isPast;
    }).toList();
    
    // Remove duplicates by name
    final Map<String, Activity> uniqueActivities = {};
    for (final activity in pastActivities) {
      if (!uniqueActivities.containsKey(activity.name)) {
        uniqueActivities[activity.name] = activity;
      }
    }
    
    // Convert back to list and sort by start time (most recent first)
    final sortedActivities = uniqueActivities.values.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    
    print('📅 Found ${sortedActivities.length} PAST activities');
    
    return sortedActivities;
  }

  // Get extra activities for free time (exclude main planned activities)  
  List<Activity> _getExtraActivities() {
    if (_scheduledActivities == null || _scheduledActivities!.isEmpty) {
      return [];
    }
    
    final mainActivities = _getMainPlannedActivities();
    final mainActivityIds = mainActivities.map((a) => a.id).toSet();
    
    return _scheduledActivities!.where((activity) => !mainActivityIds.contains(activity.id)).toList();
  }

  // Build an activity card with background image and overlay
  Widget _buildActivityCard({
    required String time,
    required String title,
    required String location,
    required String duration,
    required bool isConfirmed,
    required String imagePath,
    Activity? activity, // Add the activity object for navigation
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: activity != null ? () => _openActivityDetail(activity) : null,
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[400]!,
                          Colors.grey[600]!,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Dark overlay for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Time indicator at top left
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Duration indicator at top right  
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B7355).withOpacity(0.9), // Brown theme
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    duration,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // Activity title and location at bottom
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined, 
                          size: 16, 
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location.contains('LatLng') ? 'Rotterdam City Center' : location,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  // Method to open activity detail screen
  void _openActivityDetail(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(activity: activity),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greetingText = _getGreetingText(now.hour);
    final profileData = ref.watch(profileProvider);
    
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const ProfileDrawer(),
        body: SafeArea(
          child: _isLoading 
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                            Row(
                              children: [
                                // Profile avatar/button that works as a hamburger menu
                                Builder(
                                  builder: (context) => GestureDetector(
                                    onTap: () {
                                      // Open the drawer (hamburger menu)
                                      Scaffold.of(context).openDrawer();
                                    },
                                    child: profileData.when(
                                      data: (profile) => Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: profile?.imageUrl != null && profile!.imageUrl!.isNotEmpty
                                              ? DecorationImage(
                                                  image: NetworkImage(profile.imageUrl!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                          color: profile?.imageUrl == null ? Colors.white : null,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
              ),
            ],
          ),
                                        child: profile?.imageUrl == null
                                            ? Center(
                                                child: Text(
                                                  profile?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF12B347),
                ),
              ),
                                              )
                                            : null,
                                      ),
                                      loading: () => Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
              ),
            ],
          ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
                                              strokeWidth: 2,
                  ),
                ),
              ),
          ),
                                      error: (_, __) => Container(
                                        width: 40,
                                        height: 40,
            decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
            ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.person,
                                            color: Color(0xFF12B347),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'My Day',
                                  style: GoogleFonts.museoModerno(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF12B347),
            ),
          ),
        ],
      ),
                            Row(
                              children: [
                                // Trophy icon for achievements
                                IconButton(
                                  icon: const Icon(
                                    Icons.emoji_events_outlined,
                                    color: Color(0xFF12B347),
                                  ),
                                  onPressed: () => context.push('/gamification'),
                                ),
                                // Weather info
                                GestureDetector(
                                  onTap: () {
                                    // First give visual feedback
                                    Future.delayed(const Duration(milliseconds: 100), () {
                                      // Show a centered dialog instead of bottom sheet
                                      showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        barrierColor: Colors.black.withOpacity(0.5),
                                        builder: (context) => Dialog(
                                          backgroundColor: Colors.transparent,
                                          elevation: 0,
                                          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeOut,
                                            height: MediaQuery.of(context).size.height * 0.75,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(24),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 15,
                                                  spreadRadius: 5,
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(24),
                                              child: const WeatherDetailScreen(isModal: true),
                                            ),
                                          ),
                                        ),
                                      );
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: const Color(0xFF12B347).withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Consumer(
                                      builder: (context, ref, child) {
                                        final locationData = ref.watch(locationNotifierProvider);
                                        
                                        return locationData.when(
                                          data: (location) {
                                            final weatherData = ref.watch(weatherProvider);
                                            
                                            return weatherData.when(
                                              data: (weather) {
                                                if (weather == null) {
                                                  return Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.wb_sunny_rounded,
                                                        color: Color(0xFFFFA000),
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '--°',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }
                                                
                                                // Extract icon code from the iconUrl
                                                final iconCode = weather.iconUrl.split('/').last.replaceAll('@2x.png', '');
                                                
                                                return Row(
                                                  children: [
                                                    Image.network(
                                                      weather.iconUrl,
                                                      width: 24,
                                                      height: 24,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        // Select weather icon based on condition as fallback
                                                        IconData weatherIcon;
                                                        final condition = weather.condition.toLowerCase();
                                                        if (condition.contains('cloud')) {
                                                          weatherIcon = Icons.cloud;
                                                        } else if (condition.contains('rain')) {
                                                          weatherIcon = Icons.water_drop;
                                                        } else if (condition.contains('snow')) {
                                                          weatherIcon = Icons.ac_unit;
                                                        } else if (condition.contains('storm') || condition.contains('thunder')) {
                                                          weatherIcon = Icons.thunderstorm;
                                                        } else {
                                                          weatherIcon = Icons.wb_sunny_rounded;
                                                        }
                                                        
                                                        return Icon(
                                                          weatherIcon,
                                                          color: weatherIcon == Icons.wb_sunny_rounded 
                                                            ? const Color(0xFFFFA000) 
                                                            : weatherIcon == Icons.cloud 
                                                              ? Colors.grey 
                                                              : Colors.blue,
                                                          size: 20,
                                                        );
                                                      },
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${weather.temperature.round()}°',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                              loading: () => const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                              error: (_, __) => Row(
                        children: [
                                                  const Icon(
                                                    Icons.wb_sunny_rounded,
                                                    color: Color(0xFFFFA000),
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 4),
                          Text(
                                                    '--°',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          loading: () => const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          error: (_, __) => Row(
                                            children: [
                                              const Icon(
                                                Icons.wb_sunny_rounded,
                                                color: Color(0xFFFFA000),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '--°',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        greetingText,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
                // Current activity or next up card
              SliverToBoxAdapter(
                child: Container(
                    height: 200,
                  margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Background image
                        Positioned.fill(
                          child: Image.network(
                            'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800&h=400&fit=crop',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF12B347).withOpacity(0.1),
                              );
                            },
                          ),
                        ),
                        // Semi-transparent overlay for text readability
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.85),
                                  Colors.white.withOpacity(0.90),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Content
                        Row(
                          children: [
                            // Left green accent bar
                            Container(
                              width: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF12B347),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  bottomLeft: Radius.circular(24),
                                ),
                              ),
                            ),
                            // Content
                            Expanded(
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                    // Activity status (Completed/Confirmed/etc)
                                  Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF12B347).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                        _getCurrentActivityStatus(),
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        color: const Color(0xFF12B347),
                                      ),
                                    ),
                                  ),
                                    // Activity time
                                  Text(
                                    _getCurrentOrNextActivityTime(),
                                    style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                                const SizedBox(height: 16),
                                // Activity title
                              Text(
                                _getCurrentOrNextActivityName(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                                const SizedBox(height: 16),
                                // Activity location
                              Row(
                                children: [
                                    const Icon(Icons.location_on_outlined, color: Colors.black54, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                    _getCurrentOrNextActivityLocation(),
                                    style: GoogleFonts.poppins(
                                          fontSize: 16,
                                      color: Colors.black54,
                                        ),
                                    ),
                                  ),
                                ],
                              ),
                                const Spacer(),
                                // Warning message if needed
                                _isCurrentActivityPastDue() ? 
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.yellow.shade600, width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'BOTTOM OVERFLOWED BY 5.0 PIXELS',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.orange.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ) : const SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
                // Daily schedule header (moved up)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Schedule',
                          style: GoogleFonts.museoModerno(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const DailyScheduleScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'View All',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF12B347),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // No activities message
                if (_getMainPlannedActivities().isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_note_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No activities scheduled yet',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start exploring to find activities',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Main planned activity cards (only user's selected activities)
                if (_getMainPlannedActivities().isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final mainActivities = _getMainPlannedActivities();
                      if (index >= mainActivities.length) return null;
                      
                      final activity = mainActivities[index];
                      final formattedStartTime = _formatTime(activity.startTime);
                      
                      return _buildActivityCard(
                        time: formattedStartTime,
                        title: activity.name,
                        location: activity.location.toString(),
                        duration: '${activity.duration}min',
                        isConfirmed: true,
                        imagePath: activity.imageUrl,
                        activity: activity, // Pass the activity object
                      );
                    },
                    childCount: _getMainPlannedActivities().length,
                  ),
                ),

                // Your Activities (for free time) - moved down
              SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Free Time Activities',
                        style: GoogleFonts.museoModerno(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => const FreeTimeActivitiesScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'View All',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF12B347),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
                // Extra Activities Carousel (for free time)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 260,
                    child: _getExtraActivities().isEmpty
                    ? Consumer(
                        builder: (context, ref, child) {
                          final nearbyPlacesAsync = ref.watch(nearbyPlacesProvider);
                          
                          return nearbyPlacesAsync.when(
                            data: (places) {
                              if (places.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No nearby places found',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                );
                              }
                              
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: places.length,
                                itemBuilder: (context, index) {
                                  final place = places[index];
                                  return _buildNearbyPlaceCard(place, context);
                                },
                              );
                            },
                            loading: () => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
                      ),
                            ),
                            error: (error, stackTrace) => Center(
                              child: Text(
                                'Failed to load places',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _getExtraActivities().length,
                        itemBuilder: (context, index) {
                          final activity = _getExtraActivities()[index];
                          return _buildActivityBreakCard(activity, context);
                        },
                      ),
                  ),
                ),
                
                // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNearbyPlaceCard(Place place, BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/place/${place.id}'),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16, bottom: 8, top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: place.isAsset
                ? Image.asset(
                    place.photos.first,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Icon(Icons.image, color: Colors.grey[400], size: 40),
            ),
                  )
                : Image.network(
                    place.photos.first,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Icon(Icons.image, color: Colors.grey[400], size: 40),
                    ),
                  ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Text(
                    place.name,
              style: GoogleFonts.poppins(
                      fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (place.types.isNotEmpty)
                    Text(
                      place.types.first.replaceAll('_', ' ').split(' ').map((word) => 
                        word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
                      ).join(' '),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (place.rating > 0) ...[
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          place.rating.toStringAsFixed(1),
        style: GoogleFonts.poppins(
                            fontSize: 12,
          fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityBreakCard(Activity activity, BuildContext context) {
    // Calculate a random distance for demonstration
    final random = DateTime.now().millisecondsSinceEpoch % 20 + 5;
    final distanceText = '$random min away';
    
    return GestureDetector(
      onTap: () => context.push('/activity/${activity.id}'),
      child: Container(
        width: 270,
        margin: const EdgeInsets.only(right: 16, bottom: 8, top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            // Image with overlay for distance
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
                    activity.imageUrl,
                    height: 140,
                    width: double.infinity,
              fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Icon(Icons.image, color: Colors.grey[400], size: 40),
                ),
              ),
            ),
                // Distance indicator
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
              children: [
                        const Icon(
                          Icons.directions_walk,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distanceText,
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
                  ],
                ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    activity.name,
                        style: GoogleFonts.poppins(
                      fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  const SizedBox(height: 4),
                  Text(
                    activity.description.isNotEmpty 
                      ? activity.description 
                      : 'A perfect spot to enjoy during your free time between activities.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                      color: Colors.grey[600],
                        ),
                    maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                  ),
                ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

// Main Screen with bottom nav
class MainScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  
  // Provider accessor for external control
  static StateProvider<int> get tabControllerProvider => mainTabProvider;
  
  const MainScreen({
    Key? key, 
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    // Set the initial tab index in the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mainTabProvider.notifier).state = widget.initialTabIndex;
    });
  }
  
  @override
  void didUpdateWidget(MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the tab provider if initialTabIndex changes
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      ref.read(mainTabProvider.notifier).state = widget.initialTabIndex;
    }
  }
  
  // Screens in the bottom navigation
  final List<Widget> screens = [
    const MyDayScreen(),  // My Day is now first
    const ExploreScreen(),
    const MoodHomeScreen(),  // Moody is in the center
    const SocialHubScreen(), // Replacing AgendaScreen with SocialHubScreen
    const ProfileScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    // Watch the tab provider
    final selectedIndex = ref.watch(mainTabProvider);
    
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: selectedIndex,
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.calendar_today, 'My Day', selectedIndex == 0),
                  _buildNavItem(1, Icons.explore_outlined, 'Explore', selectedIndex == 1),
                  _buildNavItem(2, Icons.mood, 'Moody', selectedIndex == 2),
                  _buildNavItem(3, Icons.people_outline, 'Social', selectedIndex == 3),
                  GestureDetector(
                    onTap: () {
                      // Always show the regular profile screen
                      ref.read(mainTabProvider.notifier).state = 4;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: selectedIndex == 4 ? const Color(0xFF12B347).withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 24,
                            color: selectedIndex == 4 ? const Color(0xFF12B347) : Colors.grey.shade600,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Profile',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: selectedIndex == 4 ? FontWeight.w700 : FontWeight.w500,
                              color: selectedIndex == 4 ? const Color(0xFF12B347) : Colors.grey.shade600,
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
        ),
      ),
    );
  }
  
  Widget _buildNavItem(int index, IconData icon, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        ref.read(mainTabProvider.notifier).state = index;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF12B347).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? const Color(0xFF12B347) : Colors.grey.shade600,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF12B347) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 