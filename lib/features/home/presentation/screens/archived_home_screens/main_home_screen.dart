import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
// Commented out unavailable imports
// import 'package:wandermood/features/explore/presentation/screens/explore_screen.dart';
// import 'package:wandermood/features/home/presentation/screens/agenda_screen.dart' as local_agenda;
// import 'package:wandermood/features/home/presentation/screens/trending_screen.dart' as local_trending;
import 'package:wandermood/features/profile/presentation/screens/profile_screen.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/features/auth/providers/user_provider.dart';
import 'package:wandermood/features/weather/providers/weather_provider.dart';
import 'package:wandermood/features/profile/presentation/widgets/profile_drawer.dart';
import 'package:wandermood/features/plans/presentation/screens/adventure_wheel_screen.dart';
import 'package:wandermood/features/location/presentation/widgets/location_dropdown.dart';
import 'package:wandermood/features/weather/presentation/widgets/compact_weather_widget.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/plans/domain/enums/time_slot.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

// Home screen after unlocking app (with nav bar and today's plan)
class MainHomeScreen extends ConsumerStatefulWidget {
  const MainHomeScreen({super.key});

  @override
  ConsumerState<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends ConsumerState<MainHomeScreen> {
  int _selectedIndex = 0;
  final List<Activity> _mockActivities = [
    Activity(
      id: '1',
      name: 'Botanical Garden Tour',
      description: 'Explore the beautiful botanical gardens with over 5,000 plant species.',
      imageUrl: 'assets/images/activities/botanical_garden.jpg',
      rating: 4.7,
      startTime: DateTime.now().add(const Duration(hours: 1)),
      duration: 120,
      timeSlot: 'Morning',
      timeSlotEnum: TimeSlot.morning,
      tags: ['Nature', 'Peaceful', 'Educational'],
      isPaid: false,
      location: const LatLng(52.5200, 13.4050), // Example location
    ),
    Activity(
      id: '2',
      name: 'City Museum Visit',
      description: 'Discover the rich history of the city at this interactive museum.',
      imageUrl: 'assets/images/activities/museum.jpg',
      rating: 4.5,
      startTime: DateTime.now().add(const Duration(hours: 3)),
      duration: 90,
      timeSlot: 'Afternoon',
      timeSlotEnum: TimeSlot.afternoon,
      tags: ['Cultural', 'Educational', 'Indoor'],
      isPaid: true,
      price: 15.99,
      paymentType: PaymentType.ticket,
      location: const LatLng(52.5200, 13.4050), // Example location
    ),
    Activity(
      id: '3',
      name: 'Sunset Beach Walk',
      description: 'Enjoy a peaceful walk along the coastline as the sun sets.',
      imageUrl: 'assets/images/activities/beach.jpg',
      rating: 4.9,
      startTime: DateTime.now().add(const Duration(hours: 6)),
      duration: 60,
      timeSlot: 'Evening',
      timeSlotEnum: TimeSlot.evening,
      tags: ['Nature', 'Peaceful', 'Romantic'],
      isPaid: false,
      location: const LatLng(52.5200, 13.4050), // Example location
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    // Initialize screens with placeholder widgets for missing screens
    final screens = [
      _buildDayPlanContent(),
      // Placeholder widgets for missing screens
      const Center(child: Text('Explore Screen', style: TextStyle(fontSize: 24))),
      const Center(child: Text('Trending Screen', style: TextStyle(fontSize: 24))),
      const Center(child: Text('Agenda Screen', style: TextStyle(fontSize: 24))),
      const ProfileScreen(),
    ];

    return SwirlBackground(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          extendBody: true,
          drawer: const ProfileDrawer(),
          body: IndexedStack(
            index: _selectedIndex,
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
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF2A6049),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdventureWheelScreen(
                    activities: _mockActivities,
                    onActivitySelect: (activity) {
                      // Handle activity selection
                      Navigator.pop(context);
                      showWanderMoodToast(
                        context,
                        message: 'Added ${activity.name} to your day!',
                        backgroundColor: const Color(0xFF2A6049),
                      );
                    },
                  ),
                ),
              );
            },
            child: const Icon(
              Icons.casino,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
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

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "morning";
    } else if (hour < 17) {
      return "afternoon";
    } else {
      return "evening";
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Profile button
        InkWell(
          onTap: () {
            Scaffold.of(context).openDrawer();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Center(
                    child: Text(
                      "👤",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Good ${_getTimeOfDay()} explorer 👋",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        "Sarah Johnson",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Location dropdown
        const LocationDropdown(),
        
        // Weather widget
        const CompactWeatherWidget(),
      ],
    );
  }

  Widget _buildDayPlanContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar with profile, location and weather
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildTopBar(),
            ),

            // Today's Plan Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Your Day Plan",
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdventureWheelScreen(
                                activities: _mockActivities,
                                onActivitySelect: (activity) {
                                  // Handle activity selection
                                  Navigator.pop(context);
                                  showWanderMoodToast(
                                    context,
                                    message: 'Added ${activity.name} to your day!',
                                    backgroundColor: const Color(0xFF2A6049),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.casino,
                          color: Color(0xFF2A6049),
                        ),
                        label: Text(
                          "Surprise Me!",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2A6049),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatDate(DateTime.now()),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // AI Message
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Center(
                      child: Text(
                        "✨",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Good ${_getTimeOfDay()} explorer 👋",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "I've prepared a wonderful day based on your mood. You can tap the wheel icon for a spontaneous adventure!",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Time slots
            _buildTimeSlots(),
            
            // Activity cards
            ..._mockActivities.map((activity) => _buildActivityCard(
              _formatTime(activity.startTime),
              "${activity.duration} min",
              activity.name,
              activity.description,
              activity.imageUrl,
              activity.tags,
              activity.rating,
            )).toList(),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _buildTimeSlots() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTimeSlotButton("🌅 Morning", "(2)", true),
          const SizedBox(width: 12),
          _buildTimeSlotButton("☀️ Afternoon", "(4)", false),
          const SizedBox(width: 12),
          _buildTimeSlotButton("🌙 Evening", "(3)", false),
        ],
      ),
    );
  }

  Widget _buildTimeSlotButton(String title, String count, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFE082) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? Border.all(color: const Color(0xFFFFB300), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? const Color(0xFFFF8F00) : Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: isSelected ? const Color(0xFFFF8F00) : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    String timeSlot,
    String duration,
    String title,
    String description,
    String imageUrl,
    List<String> tags,
    double rating,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    Text(
                      timeSlot,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    Text(
                      " ($duration)",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF2E7D32).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: Row(
                    children: [
                      const Icon(Icons.refresh, size: 14, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 4),
                      Text(
                        "Not feeling this?",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                image: DecorationImage(
                  image: AssetImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Color(0xFFFFB300)),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFFB300),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 12),

                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2A6049)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "Directions",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2A6049),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: null, // Disabled button
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Added",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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
  }
} 