import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';  // Add this import for ImageFilter
import 'dart:math' as math; // Add for random elements
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/auth/domain/providers/auth_provider.dart';
import 'package:wandermood/features/profile/presentation/screens/profile_screen.dart';
import 'package:wandermood/features/explore/presentation/widgets/mood_selection_widget.dart';
import '../widgets/compact_weather_widget.dart';
import '../widgets/interactive_weather_widget.dart';
import '../widgets/mood_tile.dart';
import 'package:wandermood/features/weather/presentation/widgets/hourly_weather_widget.dart';
import 'explore_screen.dart';
import 'agenda_screen.dart' as local_agenda;
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/location/presentation/widgets/location_dropdown.dart';
import 'trending_screen.dart' as local_trending;
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/mood/presentation/widgets/mood_selector.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/features/auth/providers/user_provider.dart';
import 'package:wandermood/features/weather/providers/weather_provider.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/plans/presentation/screens/plan_result_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/profile/presentation/widgets/profile_drawer.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';
import 'package:wandermood/features/home/presentation/screens/main_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// Define time of day enum
enum TimeOfDay {
  morning,
  afternoon,
  evening,
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showMoodSelector = false;
  bool _isMoodSelectorVisible = false;
  Set<String> _selectedMoods = {};
  String _greeting = '';
  String _timeGreeting = '';
  late AnimationController _animationController;
  MoodyFeature _currentMoodyFeature = MoodyFeature.none;
  int _selectedIndex = 0;
  final List<String> _funGreetings = [
    "What's cookin', good lookin'?",
    "Hey there, superstar!",
    "Well hello, adventurer!",
    "Howdy, partner!",
    "Greetings, explorer!",
  ];
  
  // Add more contextual greeting options
  final Map<String, List<String>> _contextualGreetings = {
    'morning': [
      "Ready for a new adventure today?",
      "Got any exciting plans this morning?",
      "Did you sleep well? Ready to explore?",
      "Let's make today amazing!",
      "The morning is perfect for planning adventures!",
    ],
    'afternoon': [
      "How's your day going so far?",
      "Found any cool places today?",
      "Afternoon is perfect for new discoveries!",
      "Need some travel inspiration?",
      "The day is young! Where to next?",
    ],
    'evening': [
      "Had a good day exploring?",
      "Looking for evening activities?",
      "Time to relax or keep exploring?",
      "Let's find something fun tonight!",
      "Any exciting plans for tomorrow?",
    ],
  };
  
  // Mock previous mood - in a real app, this would come from storage/database
  final String _previousMood = "Adventurous";
  final String _lastTravelDestination = "Barcelona";
  
  // Mock user interaction history (in a real app, this would be stored in a database)
  final Map<String, dynamic> _userPreferences = {
    'favoriteType': 'beach',
    'lastSearched': 'museums in Paris',
    'recommendationCount': 3,
    'hasViewedItinerary': true,
  };
  
  // Time tracking for background
  late TimeOfDay _currentTimeOfDay;
  
  // Define the screens to show for each tab
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _updateTimeOfDay();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _showRandomMoodyFeature();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _showRandomMoodyFeature() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentMoodyFeature = MoodyFeature.moodTracking;
        });
      }
    });
  }
  
  void _updateGreeting() {
    final hour = DateTime.now().hour;
    String timeKey = 'afternoon';
    String timeGreeting = "";
    
    if (hour < 12) {
      timeGreeting = "Good morning";
      timeKey = 'morning';
    } else if (hour < 17) {
      timeGreeting = "Good afternoon";
      timeKey = 'afternoon';
    } else {
      timeGreeting = "Good evening";
      timeKey = 'evening';
    }
    
    // Get user name from userData
    final userData = ref.read(userDataProvider);
    final userName = userData.when(
      data: (data) => data != null && data.containsKey('name') && data['name'] != null 
          ? data['name'] 
          : 'Friend',
      loading: () => 'Friend',
      error: (_, __) => 'Friend',
    );
    
    setState(() {
      // Personalized greeting based on user history and time of day
      final random = DateTime.now().millisecond % 5;
      
      switch (random) {
        case 0:
          _greeting = "$timeGreeting, $userName! ✨\n\nYou felt $_previousMood yesterday. Want to try similar activities today?";
          break;
        case 1:
          _greeting = "Hey $userName! $timeGreeting! 🌈\n\nRemember your trip to $_lastTravelDestination? Ready for new adventures?";
          break;
        case 2:
          final contextualGreetings = _contextualGreetings[timeKey] ?? _contextualGreetings['afternoon']!;
          final randomIndex = DateTime.now().microsecond % contextualGreetings.length;
          _greeting = "$timeGreeting, $userName! ✨\n\n${contextualGreetings[randomIndex]}";
          break;
        case 3:
          _greeting = "Welcome back, $userName! $timeGreeting! 🌊\n\nI noticed you like ${_userPreferences['favoriteType']} destinations. Want to explore more?";
          break;
        case 4:
          _greeting = "$timeGreeting, $userName! 🎯\n\nI've created ${_userPreferences['recommendationCount']} personalized travel recommendations for you!";
          break;
      }
    });
  }
  
  void _toggleMoodSelector() {
    setState(() {
      _showMoodSelector = !_showMoodSelector;
      _isMoodSelectorVisible = _showMoodSelector;
      if (_showMoodSelector) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _updateTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      _currentTimeOfDay = TimeOfDay.morning;
    } else if (hour >= 12 && hour < 18) {
      _currentTimeOfDay = TimeOfDay.afternoon;
    } else {
      _currentTimeOfDay = TimeOfDay.evening;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationStateProvider);
    final userData = ref.watch(userDataProvider);
    final weatherAsync = ref.watch(weatherProvider);
    
    // Fetch location if not already available
    locationAsync.whenData((state) {
      if (state.city == null) {
        Future.microtask(() {
          ref.read(locationNotifierProvider.notifier).getCurrentLocation();
        });
      }
    });

    // Initialize screens lazily here instead of in initState
    final screens = [
      _buildHomeContent(),
      const ExploreScreen(),
      const local_trending.TrendingScreen(),
      const local_agenda.AgendaScreen(),
      const ProfileScreen(),
    ];

    return DynamicTravelBackground(
      timeOfDay: _currentTimeOfDay,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const ProfileDrawer(),
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
        // Floating action button to show mood selector when card is hidden - with more vibrant color
        floatingActionButton: _selectedIndex == 0 && !_showMoodSelector ? FloatingActionButton(
          onPressed: _toggleMoodSelector,
          backgroundColor: const Color(0xFF2A6049),
          foregroundColor: Colors.white,
          elevation: 6, // Enhanced elevation
          child: const Icon(Icons.mood, color: Colors.white),
        ) : null,
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
                  _buildNavItem(0, Icons.home_outlined, 'Home', _selectedIndex == 0),
                  _buildNavItem(1, Icons.explore_outlined, 'Explore', _selectedIndex == 1),
                  _buildNavItem(2, Icons.local_fire_department, 'Trending', _selectedIndex == 2),
                  _buildNavItem(3, Icons.calendar_today_outlined, 'Agenda', _selectedIndex == 3),
                  _buildNavItem(4, Icons.person_outline, 'Profile', _selectedIndex == 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTopBar(AsyncValue<LocationState> locationAsync, AsyncValue<Map<String, dynamic>?> userData, AsyncValue<WeatherData?> weatherAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile and location group
          Expanded(
            child: Row(
              children: [
                // Profile button
                _buildProfileButton(),

                const SizedBox(width: 8),

                // Location dropdown - auto width
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showLocationDialog(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, 
                            color: const Color(0xFF2A6049).withOpacity(0.8),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              locationAsync.when(
                                data: (state) => state?.city ?? 'Select Location',
                                loading: () => 'Loading...',
                                error: (_, __) => 'Error loading location',
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF2E7D32),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, 
                            color: const Color(0xFF2A6049).withOpacity(0.8),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Weather button
          weatherAsync.when(
            data: (weather) => weather != null ? InkWell(
              onTap: () => _showWeatherDetails(context, weather),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wb_sunny, 
                    color: const Color(0xFFFFA000).withOpacity(0.8),
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${weather.temperature.round()}°',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF8F00),
                    ),
                  ),
                ],
              ),
            ) : const SizedBox(),
            loading: () => const ShimmerWeather(),
            error: (_, __) => const ErrorWeather(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton() {
    final profileData = ref.watch(profileProvider);
    
    return GestureDetector(
      onTap: () {
        _scaffoldKey.currentState?.openDrawer();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A6049), Color(0xFF2A6049)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2A6049).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: profileData.when(
            data: (profile) => profile?.imageUrl != null
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    image: DecorationImage(
                      image: NetworkImage(profile!.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Center(
                    child: Text(
                      profile?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2A6049),
                      ),
                    ),
                  ),
                ),
            loading: () => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2A6049),
                  ),
                ),
              ),
            ),
            error: (_, __) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFF2A6049),
              ),
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideX(begin: -0.2, end: 0);
  }

  Widget _buildSpeechBubble(String message, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Soft glow effect behind the bubble
          Positioned(
            left: -8,
            top: -8,
            right: -8,
            bottom: -8,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A6049).withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
          
          // Main bubble container with glassy styling
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
              bottomLeft: Radius.circular(4),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2A6049).withOpacity(0.15),
                      const Color(0xFF81C784).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                    bottomLeft: Radius.circular(4),
                  ),
                  border: Border.all(
                    color: const Color(0xFF388E3C).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message text with dark green color
                    Text(
                      message,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF1B5E20),
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    // Time indicator dots with green colors
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) => 
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A6049).withOpacity(0.6 - (index * 0.15)),
                            shape: BoxShape.circle,
                          ),
                        )
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Chat bubble tail
          Positioned(
            bottom: 15,
            left: -12,
            child: Transform(
              transform: Matrix4.rotationZ(0.8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2A6049).withOpacity(0.15),
                          const Color(0xFF81C784).withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFF388E3C).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Location dialog with modern styling
  void _showLocationDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.35,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            
            // Current location button
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'We use your current location to provide the most relevant recommendations.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'For the best experience, please enable location access.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // First, try to get location
                      ref.read(locationNotifierProvider.notifier).getCurrentLocation();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use Current Location'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final openResult = await Geolocator.openLocationSettings();
                      if (!openResult) {
                        // If we can't open settings directly, at least guide the user
                        if (context.mounted) {
                          showWanderMoodToast(
                            context,
                            message:
                                'Please enable location in your device settings to continue.',
                            duration: const Duration(seconds: 5),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Open Location Settings'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityItem(String cityName, IconData icon, WidgetRef ref) {
    return InkWell(
      onTap: () {
        // Now we always use current location instead of setting a specific city
        ref.read(locationNotifierProvider.notifier).getCurrentLocation();
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[700]),
            const SizedBox(width: 12),
            Text(
              cityName,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Weather details dialog with modern styling
  void _showWeatherDetails(BuildContext context, WeatherData weather) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            
            // Location and date
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    weather.location,
                    style: GoogleFonts.museoModerno(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5BB32A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today, ${DateTime.now().day} ${_getMonthName(DateTime.now().month)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            
            // Current weather
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF5BB32A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Now',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${weather.temperature.round()}',
                            style: GoogleFonts.poppins(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                          Text(
                            '°C',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        weather.condition,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  Image.network(
                    weather.iconUrl,
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.wb_sunny,
                        color: Colors.amber[700],
                        size: 80,
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Weather details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeatherDetailCard(
                    'Feels Like',
                    '${weather.details['feelsLike']}°',
                    Icons.thermostat,
                  ),
                  _buildWeatherDetailCard(
                    'Humidity',
                    '${weather.details['humidity']}%',
                    Icons.water_drop,
                  ),
                  _buildWeatherDetailCard(
                    'Wind',
                    '${weather.details['windSpeed']} km/h',
                    Icons.air,
                  ),
                ],
              ),
            ),
            
            // Hourly forecast title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hourly forecast',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
              ),
            ),
            
            // Hourly forecast (fake data)
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: 24,
                itemBuilder: (context, index) {
                  final hour = (DateTime.now().hour + index) % 24;
                  final temp = weather.temperature.round() - (index % 3);
                  final isNow = index == 0;
                  final isNight = hour > 18 || hour < 6;
                  
                  return Container(
                    margin: const EdgeInsets.only(right: 16.0),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: isNow ? const Color(0xFF5BB32A).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: isNow ? Border.all(
                        color: const Color(0xFF5BB32A),
                        width: 1.5,
                      ) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isNow ? 'Now' : '$hour:00',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Icon(
                          isNight ? Icons.nightlight_round : Icons.wb_sunny,
                          color: isNight ? Colors.indigo : Colors.amber,
                          size: 24,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$temp°',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // 3-day forecast title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '3-day forecast',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
              ),
            ),
            
            // 3-day forecast (fake data)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: 3,
                itemBuilder: (context, index) {
                  final day = DateTime.now().add(Duration(days: index));
                  final dayName = index == 0 ? 'Today' : _getDayName(day.weekday);
                  final highTemp = weather.temperature.round() + (index % 2);
                  final lowTemp = weather.temperature.round() - (2 + index);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: index == 0 ? const Color(0xFF5BB32A).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dayName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              index == 2 ? Icons.cloud : Icons.wb_sunny,
                              color: index == 2 ? Colors.grey : Colors.amber,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$highTemp° / $lowTemp°',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetailCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
  
  String _getDayName(int weekday) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return days[weekday - 1];
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isSelected) {
    final emoji = _getEmojiForTab(index);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A6049).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF2A6049) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getEmojiForTab(int index) {
    switch (index) {
      case 0:
        return '🏠'; // Home
      case 1:
        return '🌍'; // Explore
      case 2:
        return '🔥'; // Trending
      case 3:
        return '📅'; // Agenda
      case 4:
        return '👤'; // Profile
      default:
        return '❓';
    }
  }
  
  // Home content as a separate widget
  Widget _buildHomeContent() {
    return SafeArea(
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Top bar with profile, location and weather
                _buildTopBar(
                  ref.watch(locationStateProvider),
                  ref.watch(userDataProvider),
                  ref.watch(weatherProvider)
                ),
                
                // Moody character centered - with new positioning
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Speech bubble on the left side (with more vibrant color)
                      Positioned(
                        top: 60,
                        left: 30,
                        width: MediaQuery.of(context).size.width * 0.75,
                        child: _buildSpeechBubble(
                          _greeting,
                          onTap: null,
                        ).animate().fadeIn(duration: 1000.ms),
                      ),
                      
                      // Moody character positioned on the right - moved down
                      Positioned(
                        top: 200,
                        right: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 0.8,
                              colors: [
                                const Color(0xFFB3E5FC).withOpacity(0.6),  // Light blue center
                                const Color(0xFFE3F2FD).withOpacity(0.3),  // Very light blue
                                const Color(0xFFE3F2FD).withOpacity(0.0),  // Transparent outer
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                            boxShadow: [
                              // Soft outer glow
                              BoxShadow(
                                color: const Color(0xFFB3E5FC).withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                              // Inner shadow for depth
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                splashColor: const Color(0xFF2A6049).withOpacity(0.2),
                                highlightColor: Colors.transparent,
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  setState(() {
                                    _currentMoodyFeature = _showMoodSelector 
                                      ? MoodyFeature.none 
                                      : MoodyFeature.moodTracking;
                                    _updateGreeting();
                                  });
                                  Future.delayed(const Duration(milliseconds: 300), () {
                                    if (mounted) _toggleMoodSelector();
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      center: Alignment.topLeft,
                                      radius: 1.5,
                                      colors: [
                                        Colors.white.withOpacity(0.95),
                                        Colors.white.withOpacity(0.9),
                                      ],
                                    ),
                                  ),
                                  child: MoodyCharacter(
                                    size: 150,
                                    mood: 'default',
                                    currentFeature: _currentMoodyFeature,
                                    mouthScaleFactor: _showMoodSelector ? 1.2 : 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ).animate(
                        onPlay: (controller) => controller.repeat(),
                      ).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.05, 1.05),
                        duration: const Duration(milliseconds: 2000),
                        curve: Curves.easeInOut,
                      ),
                      
                      // Achievement badges section (below Moody)
                      Positioned(
                        top: 360,
                        left: 20,
                        right: 20,
                        child: AnimatedOpacity(
                          opacity: _showMoodSelector ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'How are you feeling today?',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tap the Moody character or the mood button below to select your mood!',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Mood selector panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _showMoodSelector ? 0 : -580,
            left: 0,
            right: 0,
            height: 580,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with close button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select your mood',
                          style: GoogleFonts.museoModerno(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF388E3C),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF388E3C)),
                          onPressed: _toggleMoodSelector,
                        ),
                      ],
                    ),
                  ),
                  
                  // Divider
                  const Divider(),
                  
                  // Mood selector
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: MoodSelector(
                        onMoodsSelected: (moods) {
                          setState(() {
                            _selectedMoods = moods;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DynamicTravelBackground extends StatelessWidget {
  final Widget child;
  final TimeOfDay timeOfDay;

  const DynamicTravelBackground({
    Key? key,
    required this.child,
    required this.timeOfDay,
  }) : super(key: key);
  
  List<Color> _getGradientColors() {
    return const [
      Color(0xFFFFFDF5),  // Lighter warm cream yellow
      Color(0xFFFFF9E8),  // Lighter warm yellow
    ];
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: child,
    );
  }
}

class ShimmerAvatar extends StatelessWidget {
  const ShimmerAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (controller) => controller.repeat())
      .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.2));
  }
}

class ErrorAvatar extends StatelessWidget {
  const ErrorAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFFFCDD2),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.error_outline, color: Color(0xFFD32F2F)),
    );
  }
}

class ShimmerWeather extends StatelessWidget {
  const ShimmerWeather({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
      .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.2));
  }
}

class ErrorWeather extends ConsumerWidget {
  const ErrorWeather({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCDD2).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD32F2F).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: IconButton(
        icon: const Icon(Icons.refresh, color: Color(0xFFD32F2F), size: 20),
        onPressed: () => ref.refresh(weatherProvider),
      ),
    );
  }
} 