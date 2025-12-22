import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/config/supabase_config.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/plans/domain/enums/time_slot.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/features/plans/services/activity_generator_service.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/core/services/wandermood_ai_service.dart' as ai_service;
import 'package:wandermood/features/location/services/location_service.dart';
import 'package:wandermood/core/models/ai_recommendation.dart';
import 'package:wandermood/features/plans/presentation/screens/day_plan_screen.dart';
import 'package:wandermood/core/extensions/string_extensions.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/core/utils/auth_helper.dart';
import 'dart:convert';

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

    // Generate activities with guaranteed 6-8 second experience
    _generateActivitiesWithProperLoading();
  }
  
  /// Wait for session to be fully ready (not just valid)
  /// This prevents race conditions during email verification
  Future<void> _waitForSessionReady() async {
    // Wait up to 2 seconds for session to be fully established
    for (int i = 0; i < 20; i++) {
      final user = Supabase.instance.client.auth.currentUser;
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;
      
      // All 3 must be true for session to be ready
      if (user != null && session != null && token != null && token.isNotEmpty) {
        debugPrint('✅ Session ready for day plan: user=${user.id}');
        return;
      }
      
      // Wait 100ms before checking again
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // If we get here, session is still not ready after 2 seconds
    final user = Supabase.instance.client.auth.currentUser;
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    
    if (user == null || session == null || token == null) {
      throw Exception('Session not ready after waiting. Please sign in again.');
    }
  }

  Future<void> _generateActivitiesWithProperLoading() async {
    debugPrint('🚀 Starting activity generation using Supabase Edge Function for moods: ${widget.selectedMoods}');
      
    // Start the minimum loading timer (6-8 seconds)
    final minimumLoadingDuration = const Duration(seconds: 6);
    final loadingStartTime = DateTime.now();
    
    List<Activity> activities = [];
      
      try {
      // CRITICAL: Ensure session is valid before calling Edge Function
      await AuthHelper.ensureValidSession();
      
      // CRITICAL FIX: Wait for session to be fully ready (prevents race conditions)
      await _waitForSessionReady();
      
      // Get current user ID
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔗 Calling moody Edge Function: create_day_plan...');
      
      // CRITICAL: Get location and coordinates (required by Edge Function)
      final locationAsync = ref.read(locationNotifierProvider);
      final location = locationAsync.value;
      
      // CRITICAL: Validate location exists - no defaults allowed
      if (location == null || location.isEmpty || location.trim().isEmpty) {
        throw Exception('Location is required. Please enable location services or set your location in settings.');
      }
      
      // CRITICAL: Get GPS coordinates - use .future to get the Future directly
      final position = await ref.read(userLocationProvider.future);
      
      if (position == null) {
        throw Exception('GPS coordinates are required. Please enable location services.');
      }
      
      debugPrint('📍 Using location: $location at (${position.latitude}, ${position.longitude})');
      
      // FIX #1: Explicitly pass Authorization header
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;
      
      // CRITICAL: All 3 must be true - user, session, and token
      if (user == null || session == null || token == null) {
        throw Exception('Session not ready. Please wait a moment and try again.');
      }
      
      // Use Dio to explicitly send Authorization header
      final dio = Dio();
      final supabaseUrl = SupabaseConfig.url;
      final functionUrl = '$supabaseUrl/functions/v1/moody';
      
      debugPrint('🔑 Calling Edge Function with explicit Authorization header');
      debugPrint('   Token preview: ${token.substring(0, 20)}...');
      
      final response = await dio.post(
        functionUrl,
        data: {
          'action': 'create_day_plan',
          'moods': widget.selectedMoods,
          'location': location.trim(),
          'coordinates': {
            'lat': position.latitude,
            'lng': position.longitude,
          },
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'apikey': SupabaseConfig.anonKey,
        },
        ),
      );
        
      debugPrint('📡 Edge Function response status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        final errorData = response.data;
        if (kDebugMode) {
          debugPrint('❌ Edge Function error: Status ${response.statusCode}, Data: $errorData');
        }
        final errorMessage = (errorData as Map<String, dynamic>?)?['message'] ?? 
                            (errorData as Map<String, dynamic>?)?['error'] ?? 
                            'Service error. Please try again.';
        throw Exception(errorMessage);
      }

      final responseData = response.data as Map<String, dynamic>;
      
      // CRITICAL: Check if Edge Function returned empty state
      if (!responseData['success'] || responseData['total_found'] == 0) {
        final errorMessage = responseData['message'] ?? 
                            responseData['error'] ?? 
                            'No activities found for your selected moods and location.';
        debugPrint('⚠️ Edge Function returned empty state: $errorMessage');
        await _showErrorState(errorMessage);
        return;
      }

      final activitiesData = responseData['activities'] as List<dynamic>;
      final locationData = responseData['location'] as Map<String, dynamic>;
      
      debugPrint('✅ Edge Function generated ${activitiesData.length} activities');
      debugPrint('📍 Location confirmed: ${locationData['city']} (${locationData['latitude']}, ${locationData['longitude']})');

      // 🔄 CRITICAL: Invalidate providers so My Day shows the new mood-generated activities
      debugPrint('🔄 Invalidating providers for mood-generated activities to appear in My Day...');
      ref.invalidate(scheduledActivityServiceProvider);
      ref.invalidate(cachedActivitySuggestionsProvider);
      debugPrint('✅ Providers invalidated - My Day will now show mood-generated activities');

      // Convert the activities from the Edge Function response
      activities = activitiesData.map((activityJson) {
        final activity = activityJson as Map<String, dynamic>;
        
        // 🔧 CRITICAL FIX: Override Edge Function dates to use TODAY instead of July 14, 2025
        final originalStartTime = DateTime.parse(activity['startTime'] as String);
        final today = DateTime.now();
        final todayStartTime = DateTime(
          today.year, 
          today.month, 
          today.day, 
          originalStartTime.hour, 
          originalStartTime.minute
        );
        
        debugPrint('📅 Edge Function Fix: ${activity['name']} changed from ${originalStartTime.day}/${originalStartTime.month}/${originalStartTime.year} to ${todayStartTime.day}/${todayStartTime.month}/${todayStartTime.year}');
        
        return Activity(
          id: activity['id'] as String,
          name: activity['name'] as String,
          description: activity['description'] as String,
          timeSlot: activity['timeSlot'] as String,
          timeSlotEnum: _parseTimeSlot(activity['timeSlot'] as String),
          duration: activity['duration'] as int,
          location: LatLng(
            activity['location']['latitude'] as double,
            activity['location']['longitude'] as double,
          ),
          paymentType: _parsePaymentType(activity['paymentType'] as String),
          imageUrl: activity['imageUrl'] as String? ?? '', // Handle null imageUrl
          rating: (activity['rating'] as num).toDouble(),
          tags: List<String>.from(activity['tags'] as List),
          startTime: todayStartTime, // 🔧 Use today's date instead of Edge Function date
          priceLevel: activity['priceLevel'] as String? ?? 'Free', // Handle null priceLevel
        refreshCount: 0,
        );
      }).toList();

      debugPrint('✅ Successfully converted ${activities.length} activities from Edge Function');
      
      // Show some activity names for verification
      for (final activity in activities.take(3)) {
        debugPrint('   🎯 Generated: ${activity.name} (${activity.timeSlot})');
      }

    } catch (e) {
      debugPrint('❌ Edge Function failed: $e');
      
      // CRITICAL: No fallback - Edge Function is the only data authority
      // Show error state instead of generating fake data
      final errorMessage = _getErrorMessage(e);
        await _showErrorState(errorMessage);
        return;
    }

    // CRITICAL: If Edge Function returned empty activities, show error state
    if (activities.isEmpty) {
      debugPrint('❌ Edge Function returned no activities');
      await _showErrorState('No activities found for your selected moods and location. Please try different moods or check your location settings.');
      return;
    }

    // Wait for the remaining loading time to ensure 6-8 second experience
    final elapsed = DateTime.now().difference(loadingStartTime);
    final remainingTime = minimumLoadingDuration - elapsed;
    
    if (remainingTime > Duration.zero) {
      debugPrint('⏳ Waiting ${remainingTime.inSeconds} more seconds for proper loading experience...');
      await Future.delayed(remainingTime);
    }

    debugPrint('✅ Loading complete! Navigating to day plan with ${activities.length} activities');
    
    // Navigate to the day plan screen using go_router
    if (mounted) {
      context.goNamed('day-plan', extra: activities);
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('api key') || errorString.contains('invalid key') || errorString.contains('unauthorized')) {
      return 'API key configuration error. Please contact support if this persists.';
    }
    
    if (errorString.contains('network') || errorString.contains('connection') || errorString.contains('timeout')) {
      return 'Network connection error. Please check your internet connection and try again.';
    }
    
    if (errorString.contains('rate limit') || errorString.contains('quota')) {
      return 'Service temporarily unavailable due to high demand. Please try again in a few minutes.';
    }
    
    if (errorString.contains('location') || errorString.contains('permission')) {
      return 'Location access required. Please enable location services and try again.';
    }
    
    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'Service unavailable. Please try again later or contact support.';
    }
    
    // Generic error message
    return 'Unable to generate activities. Please try again or select different moods.';
  }

  Future<void> _showErrorState(String message) async {
    if (!mounted) return;
    
    // Show error dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Oops! Something went wrong'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to mood selection
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Future<List<Activity>> _generateDynamicActivities() async {
    debugPrint('🔄 Generating dynamic activities using Google Places API...');
    
    try {
      // Force Rotterdam coordinates for mood-based activity generation
      final lat = 51.9225; // Rotterdam coordinates
      final lng = 4.4792;
      
      debugPrint('📍 Using Rotterdam location for dynamic activities: ($lat, $lng)');
      
      // Use the improved ActivityGeneratorService to get REAL activities
      final activities = await ActivityGeneratorService.generateActivities(
        selectedMoods: widget.selectedMoods,
        userLocation: 'Rotterdam',
        lat: lat,
        lng: lng,
      );
      
      debugPrint('✅ Generated ${activities.length} dynamic activities');
      
      if (activities.isEmpty) {
        debugPrint('❌ No activities generated - this should not happen with proper API integration');
        throw Exception('No activities found for selected moods');
      }
      
      return activities;
    } catch (e) {
      debugPrint('❌ Error generating dynamic activities: $e');
      // Throw with specific error message
      throw Exception(_getErrorMessage(e));
    }
  }
  
  String _getTimeEmoji(TimeSlot timeSlot) {
    switch (timeSlot) {
      case TimeSlot.morning:
        return '🌅';
      case TimeSlot.afternoon:
        return '☀️';
      case TimeSlot.evening:
        return '🌆';
      case TimeSlot.night:
        return '🌙';
    }
  }

  String _getCurrentMessage() {
    if (_currentMessageIndex == 3) {
      return "Crafting the perfect plan for: ${widget.selectedMoods.join(", ")}! 🍔💖🎉";
    }
    return _loadingMessages[_currentMessageIndex];
  }

  // Helper methods for AI recommendation conversion
  String _getTimeSlot() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  LatLng _extractLocationFromRecommendation(AIRecommendation rec, double fallbackLat, double fallbackLng) {
    // If the recommendation has location data, use it
    if (rec.location != null) {
      final lat = rec.location!['latitude'] as double?;
      final lng = rec.location!['longitude'] as double?;
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    
    // Fall back to user location
    return LatLng(fallbackLat, fallbackLng);
  }

  String _getFallbackImageForType(String type) {
    final imageMap = {
      'restaurant': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400',
      'cafe': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400',
      'bar': 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400',
      'museum': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
      'park': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400',
      'attraction': 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=400',
      'shopping': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
    };
    
    return imageMap[type.toLowerCase()] ?? 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400';
  }

  TimeSlot _parseTimeSlot(String timeSlotString) {
    switch (timeSlotString.toLowerCase()) {
      case 'morning':
        return TimeSlot.morning;
      case 'afternoon':
        return TimeSlot.afternoon;
      case 'evening':
        return TimeSlot.evening;
      case 'night':
        return TimeSlot.night;
      default:
        return TimeSlot.afternoon;
    }
  }

  int _parseDuration(String durationString) {
    // Extract numbers from duration string (e.g., "90 minutes" -> 90)
    final regex = RegExp(r'\d+');
    final match = regex.firstMatch(durationString);
    return match != null ? int.parse(match.group(0)!) : 90;
  }

  PaymentType _parsePaymentType(String costString) {
    if (costString.toLowerCase().contains('free') || costString == '€') {
      return PaymentType.free;
    } else if (costString.contains('€€€') || costString.toLowerCase().contains('expensive')) {
      return PaymentType.reservation;
    } else {
      return PaymentType.reservation;
    }
  }

  DateTime _getStartTimeForSlot(TimeSlot timeSlot) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (timeSlot) {
      case TimeSlot.morning:
        return today.add(const Duration(hours: 9));
      case TimeSlot.afternoon:
        return today.add(const Duration(hours: 14));
      case TimeSlot.evening:
        return today.add(const Duration(hours: 19));
      case TimeSlot.night:
        return today.add(const Duration(hours: 22));
    }
  }

  String _parsePriceLevel(String costString) {
    if (costString.toLowerCase().contains('free') || costString == '€') {
      return '0';
    } else if (costString.contains('€€€')) {
      return '3';
    } else if (costString.contains('€€')) {
      return '2';
    } else {
      return '1';
    }
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