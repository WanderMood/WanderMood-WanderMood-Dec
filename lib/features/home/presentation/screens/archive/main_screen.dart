import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
// Import home screen content/widgets but not the HomeScreen itself
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/auth/providers/user_provider.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/features/weather/providers/weather_provider.dart';
import 'package:wandermood/features/profile/presentation/screens/profile_screen.dart';
import 'package:wandermood/features/home/presentation/widgets/winking_moody.dart';
import 'explore_screen.dart';

class MoodTile extends StatelessWidget {
  final String label;
  final String emoji;
  final Color backgroundColor;
  final bool isSelected;
  final VoidCallback onTap;

  const MoodTile({
    super.key,
    required this.label,
    required this.emoji,
    required this.backgroundColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Home content widget to replace direct HomeScreen usage
class HomeContent extends ConsumerStatefulWidget {
  const HomeContent({super.key});

  @override
  ConsumerState<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<HomeContent> {
  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(userDataProvider).maybeWhen(
      data: (data) => data?['name'] ?? 'Friend',
      orElse: () => 'Friend',
    );
    
    final locationState = ref.watch(locationNotifierProvider);
    final location = locationState.city ?? 'Select Location';
    final weather = ref.watch(weatherProvider);
    final temperature = weather.maybeWhen(
      data: (data) => '${data?.temperature?.round() ?? '--'}°',
      orElse: () => '--°',
    );

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with profile, location and weather
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Profile picture
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2A6049),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://via.placeholder.com/48',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF2A6049),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2A6049),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Temperature
                  Row(
                    children: [
                      const Icon(
                        Icons.wb_sunny,
                        color: Color(0xFFFFB74D),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        temperature,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2E3E5C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Moody character
                    Center(
                      child: const WinkingMoody(size: 120)
                        .animate()
                        .scale(
                          duration: const Duration(milliseconds: 2000),
                          curve: Curves.easeInOut,
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1.05, 1.05),
                        ),
                    ),

                    const SizedBox(height: 32),

                    // How are you feeling text
                    Text(
                      'How are you feeling today?',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2A6049),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Tap the Moody character or the mood button below to select your mood!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF2E3E5C).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Floating action button for mood selection
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    // TODO: Implement mood selection
                  },
                  backgroundColor: const Color(0xFF2A6049),
                  child: const Icon(Icons.mood, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder screens for other sections
class TrendingScreen extends ConsumerWidget {
  const TrendingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => const Center(child: Text('Trending Coming Soon'));
}

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => const Center(child: Text('Agenda Coming Soon'));
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const ExploreScreen(),
    const TrendingScreen(),
    const AgendaScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Initialize data after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }
  
  void _initializeData() {
    // Start listening to user data
    ref.read(userDataProvider);
    
    // Initialize location if not already set
    final locationState = ref.read(locationNotifierProvider);
    if (locationState.currentLatitude == null || locationState.currentLongitude == null) {
      ref.read(locationNotifierProvider.notifier).getCurrentLocation();
    }
    
    // Start fetching weather data
    ref.read(weatherProvider);
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationNotifierProvider);
    
    if (locationState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing...'),
          ],
        ),
      );
    }
    
    if (locationState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${locationState.error}'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(locationNotifierProvider.notifier).retryLocationAccess();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (!locationState.hasLocation) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting your location...'),
          ],
        ),
      );
    }
    
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: Colors.white,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department),
            label: 'Trending',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 