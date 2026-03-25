import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/config/supabase_config.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/plans/domain/enums/time_slot.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/core/utils/auth_helper.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'dart:async';

class PlanLoadingScreen extends ConsumerStatefulWidget {
  final List<String> selectedMoods;
  final DateTime? targetDate;

  const PlanLoadingScreen({
    super.key,
    required this.selectedMoods,
    this.targetDate,
  });

  @override
  ConsumerState<PlanLoadingScreen> createState() => _PlanLoadingScreenState();
}

class _PlanLoadingScreenState extends ConsumerState<PlanLoadingScreen> with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  Timer? _messageTimer;
  int _messageIndex = 0;
  double _messageOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startMessageCycle();
    _startApiCall();
  }

  void _initAnimations() {
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );
    _progressController.forward();
  }

  void _startMessageCycle() {
    _messageTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      setState(() => _messageOpacity = 0.0);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        final messages = _getMessages(l10n);
        setState(() {
          _messageIndex = (_messageIndex + 1) % messages.length;
          _messageOpacity = 1.0;
        });
      });
    });
  }

  Future<void> _startApiCall() async {
    await _generateActivitiesWithProperLoading();
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

    // Capture before any await. Prefer Flutter locale; fallback to platform (e.g. first frame).
    final languageCode = (() {
      try {
        return Localizations.localeOf(context).languageCode;
      } catch (_) {
        return WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      }
    })();
      
    // Keep loading visible long enough for the progress bar behavior.
    final minimumLoadingDuration = const Duration(seconds: 6);
    final loadingStartTime = DateTime.now();
    
    List<Activity> activities = [];
    String moodyMessage = '';
    String moodyReasoning = '';

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
      
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('currently_exploring')
          .eq('id', user.id)
          .maybeSingle();
      final isLocal = ((profile?['currently_exploring'] as String?)
                      ?.toLowerCase()
                      .trim() ??
                  'local') !=
              'traveling';

      final response = await dio.post(
        functionUrl,
        data: {
          'action': 'create_day_plan',
          'moods': widget.selectedMoods,
          'location': location.trim(),
          'is_local': isLocal,
          'language_code': languageCode,
          'coordinates': {
            'lat': position.latitude,
            'lng': position.longitude,
          },
          if (widget.targetDate != null)
            'target_date': DateTime(
              widget.targetDate!.year,
              widget.targetDate!.month,
              widget.targetDate!.day,
            ).toIso8601String(),
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
      moodyMessage = responseData['moodyMessage'] as String? ?? '';
      moodyReasoning = responseData['reasoning'] as String? ?? '';
      
      debugPrint('✅ Edge Function generated ${activitiesData.length} activities');
      debugPrint('📍 Location confirmed: ${locationData['city']} (${locationData['latitude']}, ${locationData['longitude']})');

      // 🔄 CRITICAL: Invalidate providers so My Day shows the new mood-generated activities
      debugPrint('🔄 Invalidating providers for mood-generated activities to appear in My Day...');
      ref.invalidate(scheduledActivityServiceProvider);
      ref.invalidate(scheduledActivitiesForTodayProvider);
      ref.invalidate(cachedActivitySuggestionsProvider);
      debugPrint('✅ Providers invalidated - My Day will now show mood-generated activities');

      // Convert the activities from the Edge Function response
      activities = activitiesData.map((activityJson) {
        final activity = activityJson as Map<String, dynamic>;
        
        // Override Edge Function dates to use selected target date (or today by default)
        final originalStartTime = DateTime.parse(activity['startTime'] as String);
        final target = widget.targetDate ?? DateTime.now();
        final plannedStartTime = DateTime(
          target.year,
          target.month,
          target.day,
          originalStartTime.hour, 
          originalStartTime.minute
        );
        
        debugPrint(
          '📅 Edge Function Fix: ${activity['name']} changed from '
          '${originalStartTime.day}/${originalStartTime.month}/${originalStartTime.year} '
          'to ${plannedStartTime.day}/${plannedStartTime.month}/${plannedStartTime.year}',
        );
        
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
          startTime: plannedStartTime,
          priceLevel: activity['priceLevel'] as String? ?? 'Free', // Handle null priceLevel
          placeId: activity['placeId'] as String?,
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
        final errorMessage = _getErrorMessage(context, e);
        await _showErrorState(errorMessage);
        return;
    }

    // CRITICAL: If Edge Function returned empty activities, show error state
    if (activities.isEmpty) {
      debugPrint('❌ Edge Function returned no activities');
      await _showErrorState(AppLocalizations.of(context)!.planLoadingErrorNoActivities);
      return;
    }

    // Wait for remaining time so loading feels consistent
    final elapsed = DateTime.now().difference(loadingStartTime);
    final remainingTime = minimumLoadingDuration - elapsed;
    
    if (remainingTime > Duration.zero) {
      debugPrint('⏳ Waiting ${remainingTime.inSeconds} more seconds for proper loading experience...');
      await Future.delayed(remainingTime);
    }

    // Filter activities based on current time to avoid suggesting past slots
    final now = DateTime.now();
    final hour = now.hour;
    
    // Create a new list with unique time slots
    List<Activity> validActivities = [];
    Set<TimeSlot> seenSlots = {};
    
    for (var a in activities) {
      // Time filtering
      if (hour >= 13 && a.timeSlotEnum == TimeSlot.morning) continue;
      if (hour >= 18 && a.timeSlotEnum == TimeSlot.afternoon) continue;
      
      // Deduplicate by time slot (only keep one activity per period)
      if (!seenSlots.contains(a.timeSlotEnum)) {
        seenSlots.add(a.timeSlotEnum);
        validActivities.add(a);
      }
    }
    
    // If filtering removed everything, fallback to one activity per unique time slot from original list
    if (validActivities.isEmpty) {
      seenSlots.clear();
      for (var a in activities) {
        if (!seenSlots.contains(a.timeSlotEnum)) {
          seenSlots.add(a.timeSlotEnum);
          validActivities.add(a);
        }
      }
    }
    
    // Sort by time slot index (morning -> afternoon -> evening -> night)
    validActivities.sort((a, b) => a.timeSlotEnum.index.compareTo(b.timeSlotEnum.index));
    
    // Take up to 3 activities
    final finalActivities = validActivities.take(3).toList();
    
    // Sort final activities by time slot index to ensure correct visual order (morning -> afternoon -> evening -> night)
    finalActivities.sort((a, b) => a.timeSlotEnum.index.compareTo(b.timeSlotEnum.index));

    debugPrint('✅ Loading complete! Navigating to day plan with ${finalActivities.length} activities');
    if (!mounted) return;

    await _progressController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 300),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    context.goNamed('day-plan', extra: {
      'activities': finalActivities,
      'moods': widget.selectedMoods,
      'moodyMessage': moodyMessage,
      'moodyReasoning': moodyReasoning,
    });
  }

  List<String> _getMessages(AppLocalizations l10n) => [
        l10n.moodHubMoodyThinking,
        l10n.planLoadingRotating2,
        l10n.planLoadingRotating3,
      ];

  String _getErrorMessage(BuildContext context, dynamic error) {
    final l10n = AppLocalizations.of(context)!;
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('api key') || errorString.contains('invalid key') || errorString.contains('unauthorized')) {
      return l10n.planLoadingErrorApiKey;
    }
    if (errorString.contains('network') || errorString.contains('connection') || errorString.contains('timeout')) {
      return l10n.planLoadingErrorNetwork;
    }
    if (errorString.contains('rate limit') || errorString.contains('quota')) {
      return l10n.planLoadingErrorService;
    }
    if (errorString.contains('location') || errorString.contains('permission')) {
      return l10n.planLoadingErrorLocation;
    }
    if (errorString.contains('not found') || errorString.contains('404')) {
      return l10n.planLoadingErrorNotFound;
    }
    return l10n.planLoadingErrorGeneric;
  }

  Future<void> _showErrorState(String message) async {
    if (!mounted) return;
    
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.planLoadingErrorTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to mood selection
            },
            child: Text(l10n.planLoadingTryAgain),
          ),
        ],
      ),
    );
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

  PaymentType _parsePaymentType(String costString) {
    if (costString.toLowerCase().contains('free') || costString == '€') {
      return PaymentType.free;
    } else if (costString.contains('€€€') || costString.toLowerCase().contains('expensive')) {
      return PaymentType.reservation;
    } else {
      return PaymentType.reservation;
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _breathController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messages = _getMessages(l10n);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F0E8),
        body: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: const Alignment(0, -0.3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _breathAnimation,
                      child: const MoodyCharacter(
                        size: 120,
                        mood: 'thinking',
                      ),
                    ),
                    const SizedBox(height: 28),
                    AnimatedOpacity(
                      opacity: _messageOpacity,
                      duration: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          messages[_messageIndex % messages.length],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E1C18),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 72,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 3,
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (_, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Stack(
                          children: [
                            Container(color: const Color(0xFFE8E2D8)),
                            FractionallySizedBox(
                              widthFactor: _progressAnimation.value,
                              child: Container(color: const Color(0xFF2A6049)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 