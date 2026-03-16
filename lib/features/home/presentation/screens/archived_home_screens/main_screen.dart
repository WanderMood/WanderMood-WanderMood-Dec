import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'package:wandermood/features/auth/providers/user_provider.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/features/weather/providers/weather_provider.dart';
import 'package:wandermood/features/profile/presentation/screens/profile_screen.dart';

// Placeholder screens for other sections
class TrendingScreen extends ConsumerWidget {
  const TrendingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => const Center(child: Text('Trending'));
}

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => const Center(child: Text('Agenda'));
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
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
    if (locationState is AsyncData && locationState.value == null) {
      ref.read(locationNotifierProvider.notifier).getCurrentLocation();
    }
    
    // Start fetching weather data
    ref.read(weatherProvider);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
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
                  _buildNavItem(0, 'Home'),
                  _buildNavItem(1, 'Explore'),
                  _buildNavItem(2, 'Trending'),
                  _buildNavItem(3, 'Agenda'),
                  _buildNavItem(4, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label) {
    final isSelected = _selectedIndex == index;
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
          color: isSelected ? const Color(0xFF12B347).withOpacity(0.1) : Colors.transparent,
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
                color: isSelected ? const Color(0xFF12B347) : Colors.grey.shade600,
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
} 