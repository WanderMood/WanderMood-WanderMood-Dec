import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';  // Add this import for ImageFilter
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/auth/providers/user_provider.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/features/weather/providers/weather_provider.dart';
import 'package:wandermood/features/plans/presentation/screens/plan_loading_screen.dart';
import 'package:wandermood/features/plans/presentation/screens/plan_result_screen.dart';
import 'package:wandermood/features/home/presentation/screens/moody_conversation_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/gamification/providers/gamification_provider.dart';
import 'package:wandermood/features/weather/presentation/screens/weather_detail_screen.dart';
import 'package:flutter/rendering.dart';

class MoodHomeScreen extends ConsumerStatefulWidget {
  const MoodHomeScreen({super.key});

  @override
  ConsumerState<MoodHomeScreen> createState() => _MoodHomeScreenState();
}

class _MoodHomeScreenState extends ConsumerState<MoodHomeScreen> {
  final Set<String> _selectedMoods = {};
  String _timeGreeting = '';
  String _timeEmoji = '';
  bool _showMoodyConversation = false;
  
  @override
  void initState() {
    super.initState();
    _updateGreeting();
  }
  
  void _updateGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour >= 5 && hour < 12) {
        _timeGreeting = 'Good morning';
        _timeEmoji = '☀️'; // Morning sun
      } else if (hour >= 12 && hour < 17) {
        _timeGreeting = 'Good afternoon';
        _timeEmoji = '🌤️'; // Sun with clouds
      } else if (hour >= 17 && hour < 21) {
        _timeGreeting = 'Good evening';
        _timeEmoji = '🌆'; // Evening cityscape
      } else {
        _timeGreeting = 'Hi night owl';
        _timeEmoji = '🌙'; // Moon
      }
    });
  }

  final List<MoodOption> _moods = [
    MoodOption(
      emoji: '⛰️',
      label: 'Adventure',
      color: const Color(0xFFFFC266),
    ),
    MoodOption(
      emoji: '😌',
      label: 'Relaxed',
      color: const Color(0xFF90CDF4),
    ),
    MoodOption(
      emoji: '❤️',
      label: 'Romantic',
      color: const Color(0xFFF48FB1),
    ),
    MoodOption(
      emoji: '⚡',
      label: 'Energetic',
      color: const Color(0xFFFFD54F),
    ),
    MoodOption(
      emoji: '🎉',
      label: 'Excited',
      color: const Color(0xFFCE93D8),
    ),
    MoodOption(
      emoji: '🎁',
      label: 'Surprise',
      color: const Color(0xFFF8B195),
    ),
    MoodOption(
      emoji: '🍎',
      label: 'Foody',
      color: const Color(0xFFFF8A65),
    ),
    MoodOption(
      emoji: '🎭',
      label: 'Festive',
      color: const Color(0xFF81C784),
    ),
    MoodOption(
      emoji: '☘️',
      label: 'Mindful',
      color: const Color(0xFF66BB6A),
    ),
    MoodOption(
      emoji: '👨‍👩‍👧‍👦',
      label: 'Family fun',
      color: const Color(0xFF7986CB),
    ),
    MoodOption(
      emoji: '💡',
      label: 'Creative',
      color: const Color(0xFFFFEE58),
    ),
    MoodOption(
      emoji: '👨‍👩‍👧',
      label: 'Freactives',
      color: const Color(0xFF4FC3F7),
    ),
    MoodOption(
      emoji: '💎',
      label: 'Luxurious',
      color: const Color(0xFF9575CD),
    ),
  ];

  void _toggleMood(MoodOption mood) {
    setState(() {
      if (_selectedMoods.contains(mood.label)) {
        _selectedMoods.remove(mood.label);
      } else if (_selectedMoods.length < 3) {
        _selectedMoods.add(mood.label);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You can select up to 3 moods',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  void _generatePlan() {
    if (_selectedMoods.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PlanLoadingScreen(
            selectedMoods: _selectedMoods.toList(),
            onLoadingComplete: () {
              // Navigate to plan result screen after loading
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => PlanResultScreen(
                    selectedMoods: _selectedMoods.toList(),
                    moodString: _selectedMoods.join(" & "),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  // Show weather details dialog
  void _showWeatherDetails(BuildContext context) {
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
  }

  // Show location selection dialog
  void _showLocationDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Select Location',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Current location button
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF12B347).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Color(0xFF12B347),
                ),
              ),
              title: Text(
                'Current Location',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Using GPS',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () {
                // Close the dialog
                Navigator.pop(context);
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Using current location'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            
            const Divider(height: 32),
            
            // Recent locations
            Text(
              'Recent Locations',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            
            // Location list
            _buildLocationItem('Amsterdam', Icons.location_city),
            _buildLocationItem('Rotterdam', Icons.location_city),
            _buildLocationItem('Eindhoven', Icons.location_city),
            _buildLocationItem('Utrecht', Icons.landscape),
            _buildLocationItem('The Hague', Icons.beach_access),
            _buildLocationItem('Delft', Icons.house),
            
            const Spacer(),
            
            // Add new location button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Show search dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Search location feature coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New Location'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: const Color(0xFF12B347).withOpacity(0.5)),
                  foregroundColor: const Color(0xFF12B347),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build location item widget
  Widget _buildLocationItem(String city, IconData icon) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF12B347), size: 28),
          const SizedBox(height: 8),
          Text(
            city,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Show dialog for talking to Moody
  void _showMoodyTalkDialog(BuildContext context) {
    // Instead of showing a bottom sheet, set state to show conversation overlay
    setState(() {
      _showMoodyConversation = true;
    });
  }
  
  // Add method to hide the conversation
  void _hideMoodyConversation() {
    setState(() {
      _showMoodyConversation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationNotifierProvider);
    final userData = ref.watch(userDataProvider);
    final weatherAsync = ref.watch(weatherProvider);
    
    return Stack(
      children: [
        Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFDF5),  // Warm cream
              Color(0xFFFFF3E0),  // Warm yellow
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user avatar and location
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF12B347),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'U',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            color: const Color(0xFF12B347),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Location dropdown - now clickable
                    Expanded(
                      child: InkWell(
                        onTap: () => _showLocationDialog(context, ref),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFF12B347),
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Eindhoven',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Weather button - now clickable
                    InkWell(
                      onTap: () {
                        // Show weather details dialog
                        _showWeatherDetails(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final weatherAsync = ref.watch(weatherProvider);
                            
                            return weatherAsync.when(
                              data: (weather) {
                                if (weather == null) return _buildDefaultWeather();
                                
                                // Extract the icon code from the iconUrl
                                final iconCode = weather.iconUrl.split('/').last.replaceAll('@2x.png', '');
                                
                                return Row(
                                  children: [
                                    Image.network(
                                      weather.iconUrl,
                                      width: 24,
                                      height: 24,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        _getWeatherIcon(weather.condition),
                                        color: weather.condition.toLowerCase().contains('cloud') 
                                            ? Colors.grey 
                                            : const Color(0xFFFFB300),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${weather.temperature.round()}°',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => _buildDefaultWeather(),
                              error: (_, __) => _buildDefaultWeather(),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Greeting and Moody
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                    userData.when(
                                data: (data) {
                                  String firstName = '';
                                  if (data != null && data.containsKey('name') && data['name'] != null) {
                          firstName = data['name'].toString().split(' ')[0];
                                  } else {
                                    firstName = 'explorer';
                                  }
                                  return Center(
                                    child: Text(
                                      "$_timeGreeting $firstName $_timeEmoji",
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                                loading: () => Center(
                                  child: Text(
                                    "$_timeGreeting explorer $_timeEmoji",
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                error: (_, __) => Center(
                                  child: Text(
                                    "$_timeGreeting explorer $_timeEmoji",
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'How are you feeling today?',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Moody Character
              Center(
                child: GestureDetector(
                  onTap: () {
                        // Show conversation screen when tapping on Moody
                    _showMoodyTalkDialog(context);
                  },
                  child: MoodyCharacter(
                    size: 120,
                    mood: _selectedMoods.isEmpty ? 'default' : 'happy',
                  ),
                ),
              ),

              const SizedBox(height: 24),
              
                  // Update Talk to Moody input field
              GestureDetector(
                onTap: () {
                      // Show conversation screen when tapping on input field
                  _showMoodyTalkDialog(context);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Talk to me or select moods for your daily plan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.mic,
                        color: const Color(0xFF12B347).withOpacity(0.7),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Put mood tiles and button in a single scrollable container
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selected moods indicator
                      if (_selectedMoods.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Selected moods: ',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.black54,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _selectedMoods.join(', '),
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: const Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Grid of mood tiles
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), // Disable grid's own scrolling
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.0, // Enforce square aspect ratio
                        children: _moods.map((mood) {
                          final isSelected = _selectedMoods.contains(mood.label);
                          return GestureDetector(
                            onTap: () => _toggleMood(mood),
                            child: Container(
                              // Fixed size constraints to prevent overflow
                              constraints: const BoxConstraints(
                                minWidth: 80,
                                maxWidth: 80,
                                minHeight: 80,
                                maxHeight: 80,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    mood.color.withOpacity(1.0),
                                    mood.color.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected 
                                    ? mood.color.withOpacity(0.9) 
                                    : mood.color.withOpacity(0.4),
                                  width: isSelected ? 2.5 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected 
                                      ? mood.color.withOpacity(0.6)
                                      : mood.color.withOpacity(0.3),
                                    blurRadius: isSelected ? 10 : 5,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                                  child: Stack(
                                    children: [
                                      // Main content with emoji and label
                                      Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    mood.emoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 70, // Constrain text width
                                    child: Text(
                                      mood.label,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11, // Slightly smaller font
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1, // Limit to single line
                                      overflow: TextOverflow.ellipsis, // Handle long text
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Checkmark indicator (only shown when selected)
                                      if (isSelected)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: mood.color.withOpacity(0.8),
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 2,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.check,
                                                size: 12,
                                                color: Color(0xFF12B347),
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      // CTA Button directly below grid in the same scroll view
                      Container(
                        width: double.infinity,
                        height: 56,
                        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 30, top: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _selectedMoods.isEmpty ? null : _generatePlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedMoods.isEmpty 
                                ? const Color(0xFFD0D0D0) // Light gray for inactive state
                                : const Color(0xFF12B347), // Green for active state
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Let's create your perfect plan! 🎯",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
        
        // Add the MoodyConversationScreen overlay when active
        if (_showMoodyConversation)
          MoodyConversationScreen(
            onClose: _hideMoodyConversation,
          ),
      ],
    );
  }

  // Helper method to return default weather widget
  Widget _buildDefaultWeather() {
    return Row(
      children: [
        const Icon(
          Icons.wb_sunny,
          color: Color(0xFFFFB300),
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          '22°',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  // Helper method to determine weather icon based on condition
  IconData _getWeatherIcon(String condition) {
    final lowercaseCondition = condition.toLowerCase();
    if (lowercaseCondition.contains('cloud')) {
      return Icons.cloud;
    } else if (lowercaseCondition.contains('rain') || lowercaseCondition.contains('drizzle')) {
      return Icons.water_drop;
    } else if (lowercaseCondition.contains('snow')) {
      return Icons.ac_unit;
    } else if (lowercaseCondition.contains('storm') || lowercaseCondition.contains('thunder')) {
      return Icons.thunderstorm;
    } else if (lowercaseCondition.contains('mist') || lowercaseCondition.contains('fog')) {
      return Icons.water;
    } else {
      return Icons.wb_sunny;
    }
  }
}

class MoodOption {
  final String emoji;
  final String label;
  final Color color;

  const MoodOption({
    required this.emoji,
    required this.label,
    required this.color,
  });
} 