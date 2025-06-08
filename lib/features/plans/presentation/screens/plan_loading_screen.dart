import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/plans/domain/enums/time_slot.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/features/plans/services/activity_generator_service.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/features/plans/presentation/screens/day_plan_screen.dart';

class PlanLoadingScreen extends ConsumerStatefulWidget {
  final List<String> selectedMoods;
  final Function() onLoadingComplete;

  const PlanLoadingScreen({
    super.key,
    required this.selectedMoods,
    required this.onLoadingComplete,
  });

  @override
  ConsumerState<PlanLoadingScreen> createState() => _PlanLoadingScreenState();
}

class _PlanLoadingScreenState extends ConsumerState<PlanLoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentMessageIndex = 0;
  int _currentGradientIndex = 0;

  final List<String> _loadingMessages = [
    "Scanning your vibes…🔍💫",
    "Checking nearby gems you'd love…🗺️✨",
    "Matching your mood with magic…🔮🧠",
    "", // This will be filled dynamically
    "Almost there… just polishing the final touches! 🌟"
  ];

  // Onboarding gradients
  final List<List<Color>> _gradients = [
    [
      const Color(0xFFFFF3C4), // Very Soft Yellow (Meet Moody)
      const Color(0xFFFFE0A1), // Light Warm Yellow
    ],
    [
      const Color(0xFFFFB3B3), // Very Soft Red (Travel by Mood)
      const Color(0xFFFF9999), // Light Warm Red
    ],
    [
      const Color(0xFFD4C4FB), // Very Soft Lavender (Your Day Your Way)
      const Color(0xFFE2D6FC), // Light Lavender
    ],
    [
      const Color(0xFFFFD3A1), // Very Soft Orange (Every Day's a Mood)
      const Color(0xFFFFBF7F), // Light Warm Orange
    ],
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Set the dynamic message
    _loadingMessages[3] = "Crafting the perfect plan for: ${widget.selectedMoods.join(", ")}! 🍔💖🎉";

    // Start the UI animations and API call
    _startLoadingProcess();
  }

  void _startLoadingProcess() {
    // Start message and gradient animation
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return false;
      setState(() {
        _currentMessageIndex = (_currentMessageIndex + 1) % _loadingMessages.length;
        _currentGradientIndex = (_currentGradientIndex + 1) % _gradients.length;
      });
      return true;
    });

    // Generate real activities from Google Places API
    _generateRealActivities();
  }

  Future<void> _generateRealActivities() async {
    try {
      debugPrint('🎯 Starting real activity generation for moods: ${widget.selectedMoods}');
      
      // Get user's current location using Future.microtask to avoid provider modification during build
      String? userLocation;
      double? lat;
      double? lng;
      
      try {
        // Delay the provider access to avoid build cycle conflicts
        await Future.microtask(() {});
        
        // Try to get location from the location provider
        final locationNotifier = ref.read(locationNotifierProvider.notifier);
        userLocation = await locationNotifier.getCurrentLocation();
        
        // For coordinates, use Rotterdam as default (you can enhance this to get actual coordinates)
        lat = 51.9225; // Rotterdam coordinates
        lng = 4.4792;
        
        debugPrint('📍 Using location: $userLocation at ($lat, $lng)');
      } catch (e) {
        debugPrint('⚠️ Location error: $e, using default location');
        userLocation = 'Rotterdam';
        lat = 51.9225;
        lng = 4.4792;
      }

      // Generate activities using the ActivityGeneratorService
      debugPrint('🔍 Starting API calls to Google Places...');
      final activities = await ActivityGeneratorService.generateActivities(
        selectedMoods: widget.selectedMoods,
        userLocation: userLocation,
        lat: lat,
        lng: lng,
      );

      debugPrint('✅ Generated ${activities.length} activities');
      
      // Log the activity names to see what we got
      for (int i = 0; i < activities.length; i++) {
        debugPrint('Activity ${i + 1}: ${activities[i].name} (${activities[i].rating} stars)');
      }

      // Wait for minimum loading time (6 seconds) for UX
      await Future.delayed(const Duration(seconds: 6));

      if (mounted) {
        // Navigate to DayPlanScreen with the real activities
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DayPlanScreen(
              activities: activities,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error generating activities: $e');
      
      // Fallback to sample activities if API fails
      final fallbackActivities = [
        Activity(
          id: 'fallback-morning',
          name: 'Local ${widget.selectedMoods.isNotEmpty ? widget.selectedMoods.first : "Adventure"} Morning',
          description: 'Start your day with a ${widget.selectedMoods.join(" and ").toLowerCase()} experience in your area.',
          startTime: DateTime.now().add(const Duration(hours: 1)),
          duration: 60,
          imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b',
          tags: ['Local 🏠', 'Morning 🌅', '${widget.selectedMoods.isNotEmpty ? widget.selectedMoods.first : "Adventure"} ✨'],
          rating: 4.5,
          timeSlot: 'morning',
          timeSlotEnum: TimeSlot.morning,
          location: const LatLng(51.9225, 4.4792),
          paymentType: PaymentType.free,
        ),
        Activity(
          id: 'fallback-afternoon',
          name: 'Local ${widget.selectedMoods.isNotEmpty ? widget.selectedMoods.first : "Adventure"} Afternoon',
          description: 'Continue your ${widget.selectedMoods.join(" and ").toLowerCase()} day with local discoveries.',
          startTime: DateTime.now().add(const Duration(hours: 6)),
          duration: 90,
          imageUrl: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085',
          tags: ['Local 🏠', 'Afternoon ☀️', '${widget.selectedMoods.isNotEmpty ? widget.selectedMoods.first : "Adventure"} ✨'],
          rating: 4.3,
          timeSlot: 'afternoon',
          timeSlotEnum: TimeSlot.afternoon,
          location: const LatLng(51.9225, 4.4792),
          paymentType: PaymentType.reservation,
        ),
      ];

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DayPlanScreen(
              activities: fallbackActivities,
            ),
          ),
        );
      }
    }
  }

  String _getCurrentMessage() {
    if (_currentMessageIndex == 3) {
      return "Crafting the perfect plan for: ${widget.selectedMoods.join(", ")}! 🍔💖🎉";
    }
    return _loadingMessages[_currentMessageIndex];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            // Pop back to the mood selection screen
            Navigator.of(context).pop();
          },
        ),
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _gradients[_currentGradientIndex],
          ),
        ),
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Moody Character
                Container(
                  height: 160,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MoodyCharacter(
                        size: 140,
                        mood: 'thinking',
                      ).animate(
                        onPlay: (controller) => controller.repeat(),
                      ).scale(
                        duration: const Duration(milliseconds: 2000),
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1.05, 1.05),
                        curve: Curves.easeInOut,
                      ),
                      const SizedBox(height: 8),
                      // Pulsing dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.9),
                            ),
                          ).animate(
                            onPlay: (controller) => controller.repeat(),
                          ).scale(
                            duration: const Duration(milliseconds: 800),
                            delay: Duration(milliseconds: index * 300),
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.2, 1.2),
                            curve: Curves.easeInOut,
                          ).fadeIn(
                            duration: const Duration(milliseconds: 400),
                            delay: Duration(milliseconds: index * 300),
                            curve: Curves.easeIn,
                          ).fadeOut(
                            delay: Duration(milliseconds: 400 + index * 300),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Selected Moods Display
                Text(
                  "Creating your ${widget.selectedMoods.join(" & ")} plan",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.3,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 2.0,
                        color: Colors.black.withOpacity(0.2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Loading Message
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Padding(
                    key: ValueKey(_currentMessageIndex),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _getCurrentMessage(),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        height: 1.4,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 2.0,
                            color: Colors.black.withOpacity(0.15),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Loading indicator
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black87.withOpacity(0.8)),
                    strokeWidth: 2,
                  ),
                ),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 