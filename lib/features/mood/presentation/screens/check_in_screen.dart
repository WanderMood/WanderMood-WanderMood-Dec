import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../profile/data/providers/visited_places_provider.dart';
import '../../../profile/domain/providers/current_user_profile_provider.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../home/presentation/screens/dynamic_my_day_provider.dart';
import '../../providers/daily_mood_state_provider.dart';
import '../../models/check_in.dart';
import '../../models/activity_rating.dart';
import '../../services/check_in_service.dart';
import '../../domain/providers/effective_mood_streak_provider.dart';
import '../../services/moody_ai_service.dart';
import '../../services/activity_rating_service.dart';
import '../widgets/activity_rating_sheet.dart';
import 'dart:math' as math;
import 'package:wandermood/l10n/app_localizations.dart';

enum _CheckInMorningLine { none, afterTired, fresh }

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final List<String> _selectedReactions = [];
  String? _selectedMood;
  String? _selectedActivity;
  bool _isSending = false;
  _CheckInMorningLine _morningGreetingLine = _CheckInMorningLine.none;
  int _streak = 0;

  late AnimationController _moodyAnimationController;
  late Animation<double> _moodyScaleAnimation;
  late AnimationController _floatController;

  List<Map<String, dynamic>> _quickMoods(AppLocalizations l10n) => [
        {
          'emoji': '😊',
          'label': l10n.checkInMoodGreatLabel,
          'value': 'great',
          'subtitle': l10n.checkInMoodGreatSubtitle,
          'gradient': [const Color(0xFFFFD166), const Color(0xFFFF9A00)],
        },
        {
          'emoji': '😴',
          'label': l10n.checkInMoodTiredLabel,
          'value': 'tired',
          'subtitle': l10n.checkInMoodTiredSubtitle,
          'gradient': [const Color(0xFF7B68EE), const Color(0xFF9F7AEA)],
        },
        {
          'emoji': '🎉',
          'label': l10n.checkInMoodAmazingLabel,
          'value': 'amazing',
          'subtitle': l10n.checkInMoodAmazingSubtitle,
          'gradient': [const Color(0xFFFF6B9D), const Color(0xFFFFA06B)],
        },
        {
          'emoji': '😐',
          'label': l10n.checkInMoodOkayLabel,
          'value': 'okay',
          'subtitle': l10n.checkInMoodOkaySubtitle,
          'gradient': [const Color(0xFF94A3B8), const Color(0xFFCBD5E0)],
        },
        {
          'emoji': '🤔',
          'label': l10n.checkInMoodThoughtfulLabel,
          'value': 'thoughtful',
          'subtitle': l10n.checkInMoodThoughtfulSubtitle,
          'gradient': [const Color(0xFF6366F1), const Color(0xFF818CF8)],
        },
        {
          'emoji': '😌',
          'label': l10n.checkInMoodChillLabel,
          'value': 'chill',
          'subtitle': l10n.checkInMoodChillSubtitle,
          'gradient': [const Color(0xFF2A6049), const Color(0xFF6DE89A)],
        },
      ];

  List<Map<String, dynamic>> _activityRows(AppLocalizations l10n) => [
        {'id': 'Explored places', 'label': l10n.checkInTagExploredPlaces},
        {'id': 'Had great food', 'label': l10n.checkInTagGreatFood},
        {'id': 'Met friends', 'label': l10n.checkInTagMetFriends},
        {'id': 'Relaxed', 'label': l10n.checkInTagRelaxed},
        {'id': 'Worked out', 'label': l10n.checkInTagWorkedOut},
        {'id': 'Creative time', 'label': l10n.checkInTagCreativeTime},
        {'id': 'Adventure', 'label': l10n.checkInTagAdventure},
        {'id': 'Self-care', 'label': l10n.checkInTagSelfCare},
      ];

  List<Map<String, dynamic>> _quickReactions(AppLocalizations l10n) => [
        {'emoji': '❤️', 'id': 'Loved it', 'label': l10n.checkInReactionLovedIt},
        {'emoji': '🔥', 'id': 'On fire', 'label': l10n.checkInReactionOnFire},
        {'emoji': '✨', 'id': 'Magical', 'label': l10n.checkInReactionMagical},
        {'emoji': '😅', 'id': 'Exhausted', 'label': l10n.checkInReactionExhausted},
        {'emoji': '🤩', 'id': 'Amazing', 'label': l10n.checkInReactionAmazing},
        {'emoji': '😌', 'id': 'Peaceful', 'label': l10n.checkInReactionPeaceful},
      ];

  String _headerGreeting(AppLocalizations l10n) {
    switch (_morningGreetingLine) {
      case _CheckInMorningLine.afterTired:
        return l10n.checkInGreetingMorningAfterTired;
      case _CheckInMorningLine.fresh:
        return l10n.checkInGreetingMorningFresh;
      case _CheckInMorningLine.none:
        return l10n.checkInGreetingDefault;
    }
  }

  @override
  void initState() {
    super.initState();
    _moodyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _moodyScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _moodyAnimationController,
      curve: Curves.easeInOut,
    ));

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Load previous check-in to personalize greeting
    _loadPreviousCheckIn();
    _loadStreak();
  }

  @override
  void dispose() {
    _textController.dispose();
    _moodyAnimationController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  // Get time-based gradient colors
  List<Color> _getTimeBasedGradient() {
    final hour = MoodyClock.now().hour;

    if (hour >= 5 && hour < 12) {
      // Morning - Sunrise gradient
      return [
        const Color(0xFFFFF3E0),
        const Color(0xFFFFE0B2),
        const Color(0xFFFFCC80),
      ];
    } else if (hour >= 12 && hour < 17) {
      // Afternoon - Bright blue sky
      return [
        const Color(0xFFE3F2FD),
        const Color(0xFFBBDEFB),
        const Color(0xFF90CAF9),
      ];
    } else if (hour >= 17 && hour < 20) {
      // Evening - Sunset gradient
      return [
        const Color(0xFFFCE4EC),
        const Color(0xFFF8BBD0),
        const Color(0xFFF48FB1),
      ];
    } else {
      // Night - Deep twilight
      return [
        const Color(0xFFE8EAF6),
        const Color(0xFFC5CAE9),
        const Color(0xFF9FA8DA),
      ];
    }
  }

  Future<void> _loadStreak() async {
    final checkInService = CheckInService(Supabase.instance.client);
    final streak = await checkInService.getUnifiedEngagementStreak();
    if (mounted) {
      setState(() {
        _streak = streak;
      });
    }
  }

  Future<Map<String, dynamic>?> _getLocationData() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('🌍 Location: service disabled, using fallback');
        return _getSimulatorFallback();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('🌍 Location: permission denied, using fallback');
          return _getSimulatorFallback();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('🌍 Location: permission denied forever, using fallback');
        return _getSimulatorFallback();
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        debugPrint('🌍 Location: getCurrentPosition failed: $e');
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        debugPrint('🌍 Location: no position, using fallback (Amsterdam)');
        return _getSimulatorFallback();
      }

      String? city;
      String? country;
      String? placeName;

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = place.locality ?? place.subLocality;
          country = place.country;
          placeName = place.name;

          if (placeName != null && RegExp(r'^[0-9]+$').hasMatch(placeName)) {
            placeName = city;
          }
        }
      } catch (e) {
        debugPrint('🌍 Geocoding failed: $e');
      }

      debugPrint('🌍 Location OK: ${position.latitude}, ${position.longitude} → $city, $country');
      return {
        'lat': position.latitude,
        'lng': position.longitude,
        'city': city,
        'country': country,
        'placeName': placeName ?? city,
      };
    } catch (e) {
      debugPrint('🌍 Location failed: $e, using fallback');
      return _getSimulatorFallback();
    }
  }

  /// Fallback when GPS fails (e.g. simulator) — use Amsterdam so user sees a marker
  Map<String, dynamic> _getSimulatorFallback() {
    return {
      'lat': 52.3676,
      'lng': 4.9041,
      'city': 'Amsterdam',
      'country': 'Netherlands',
      'placeName': 'Amsterdam',
    };
  }

  void _handleSend() async {
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      // Get location data for the globe
      final locationData = await _getLocationData();

      // Save check-in to memory
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final checkIn = CheckIn(
          id: 'checkin_${MoodyClock.now().millisecondsSinceEpoch}',
          userId: userId,
          mood: _selectedMood,
          activities: _selectedActivity != null ? [_selectedActivity!] : [],
          reactions: _selectedReactions,
          text: _textController.text.trim().isNotEmpty
              ? _textController.text.trim()
              : null,
          timestamp: MoodyClock.now(),
        );

        final checkInService = CheckInService(Supabase.instance.client);
        await checkInService.saveCheckIn(
          checkIn,
          lat: locationData?['lat'],
          lng: locationData?['lng'],
          city: locationData?['city'],
          country: locationData?['country'],
          placeName: locationData?['placeName'],
        );

        await ref.read(currentUserProfileProvider.notifier).refresh();
        ref.invalidate(effectiveMoodStreakProvider);

        // Force refresh the globe data
        ref.invalidate(visitedPlacesProvider);
        
        if (kDebugMode) debugPrint('✅ Check-in saved: ${checkIn.id}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to save check-in: $e');
    }

    // Small delay for UX
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      // Show Moody's response
      _showMoodyResponse();
    }
  }

  void _showMoodyResponse() async {
    // Get pending activities for rating
    final pendingActivities = await _getPendingActivities();

    // Generate AI response
    final l10n = AppLocalizations.of(context)!;
    final response =
        await _getMoodyResponse(l10n, pendingActivities: pendingActivities);

    if (!mounted) return;

    // Show rating sheets for completed activities first
    if (pendingActivities.isNotEmpty) {
      await _showActivityRatings(pendingActivities);
      if (!mounted) return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFFF0F9FF),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Moody character with celebration effect
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glow effect
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF2A6049).withOpacity(0.3),
                          const Color(0xFF2A6049).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                  ScaleTransition(
                    scale: _moodyScaleAnimation,
                    child: MoodyCharacter(
                      size: 100,
                      mood: _selectedMood ?? 'default',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                response,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  color: const Color(0xFF1A202C),
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2A6049), Color(0xFF0E8F38)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2A6049).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close response
                    Navigator.of(context).pop(); // Close check-in screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    l10n.checkInThanksMoodyButton,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  Future<String> _getMoodyResponse(
    AppLocalizations l10n, {
    List<ActivityRating>? pendingActivities,
  }) async {
    try {
      final aiService = ref.read(moodyAIServiceProvider);

      return await aiService.generateCheckInResponse(
        userText: _textController.text.trim(),
        mood: _selectedMood ?? 'neutral',
        activities: _selectedActivity != null ? [_selectedActivity!] : [],
        reactions: _selectedReactions,
        pendingRatings: pendingActivities,
      );
    } catch (e) {
      print('⚠️ Failed to get AI response: $e');
      return l10n.checkInAiFallbackThankYou;
    }
  }

  /// Get activities that were scheduled for today and could be rated
  Future<List<ActivityRating>> _getPendingActivities() async {
    try {
      // Get today's activities from today activities provider
      final dayState = ref.read(todayActivitiesProvider);

      if (dayState is! AsyncData) return [];

      final activities = dayState.value ?? [];
      final today = MoodyClock.now();

      // Find activities that are scheduled for today and haven't been rated
      final ratingService = ref.read(activityRatingServiceProvider);
      final pendingRatings = <ActivityRating>[];

      for (final activity in activities) {
        // Check if activity is for today or in the past
        final activityTime = activity.startTime;
        if (activityTime.day == today.day &&
            activityTime.month == today.month &&
            activityTime.year == today.year) {
          final activityId = activity.rawData['id']?.toString() ??
              MoodyClock.now().toString();
          final activityName = activity.rawData['name'] as String? ??
              activity.rawData['title'] as String? ??
              'Activity';
          final location = activity.rawData['location'] as String?;

          // Check if already rated
          final existingRating =
              await ratingService.getRatingForActivity(activityId);

          if (existingRating == null) {
            // Create a placeholder rating for UI
            pendingRatings.add(ActivityRating(
              id: activityId,
              userId: Supabase.instance.client.auth.currentUser?.id ?? '',
              activityId: activityId,
              activityName: activityName,
              placeName: location,
              stars: 0,
              tags: [],
              wouldRecommend: false,
              completedAt: MoodyClock.now(),
              mood: _selectedMood ?? 'neutral',
              googlePlaceId: activity.rawData['placeId'] as String?,
            ));
          }
        }
      }

      return pendingRatings;
    } catch (e) {
      print('⚠️ Failed to get pending activities: $e');
      return [];
    }
  }

  /// Show rating sheets for completed activities
  Future<void> _showActivityRatings(List<ActivityRating> activities) async {
    for (final activity in activities) {
      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ActivityRatingSheet(
          activityId: activity.activityId,
          activityName: activity.activityName,
          placeName: activity.placeName,
          googlePlaceId: activity.googlePlaceId,
          currentMood: _selectedMood ?? 'neutral',
        ),
      );
    }
  }

  Future<void> _loadPreviousCheckIn() async {
    // Load previous check-in to personalize greeting
    final checkInService = CheckInService(Supabase.instance.client);
    final yesterdayCheckIn = await checkInService.getYesterdayCheckIn();

    final hour = MoodyClock.now().hour;
    final isMorning = hour < 12;

    if (mounted) {
      setState(() {
        if (isMorning && yesterdayCheckIn != null) {
          _morningGreetingLine = yesterdayCheckIn.mood == 'tired'
              ? _CheckInMorningLine.afterTired
              : _CheckInMorningLine.fresh;
        } else {
          _morningGreetingLine = _CheckInMorningLine.none;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dailyState = ref.watch(dailyMoodStateNotifierProvider);
    final currentMood = dailyState.currentMood ?? 'exploring';
    final gradientColors = _getTimeBasedGradient();
    final quickMoods = _quickMoods(l10n);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
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
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF1A202C)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l10n.checkInWithMoodyTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A202C),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Streak indicator
                    if (_streak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9A00), Color(0xFFFFD166)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF9A00).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(
                              '$_streak',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),

              // Main content - Scrollable
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 28),

                      // Floating Moody character - more subtle
                      AnimatedBuilder(
                        animation: _floatController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              math.sin(_floatController.value * 2 * math.pi) *
                                  6,
                            ),
                            child: child,
                          );
                        },
                        child: ScaleTransition(
                          scale: _moodyScaleAnimation,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF2A6049).withOpacity(0.25),
                                  const Color(0xFF2A6049).withOpacity(0.08),
                                  const Color(0xFF2A6049).withOpacity(0.0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF2A6049).withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: MoodyCharacter(
                                size: 90,
                                mood: currentMood,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Greeting with personality - more compact
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Text(
                              _headerGreeting(l10n),
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.checkInTellMeEverything,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Card-based mood selection - more compact
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.checkInHowAreYouFeeling,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.85,
                              children: quickMoods.map((mood) {
                                final isSelected =
                                    _selectedMood == mood['value'];
                                return _buildMoodCard(mood, isSelected);
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Activity tags (continued on next part due to length...)
                      _buildActivitiesSection(l10n),

                      const SizedBox(height: 28),

                      // Quick reactions
                      _buildReactionsSection(l10n),

                      const SizedBox(height: 28),

                      // Free text input
                      _buildTextInputSection(l10n),

                      const SizedBox(height: 28),

                      // Send button
                      _buildSendButton(l10n),

                      const SizedBox(height: 32),
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

  Widget _buildMoodCard(Map<String, dynamic> mood, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = isSelected ? null : mood['value'] as String;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: mood['gradient'] as List<Color>,
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.5)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? (mood['gradient'] as List<Color>)[0].withOpacity(0.35)
                  : Colors.black.withOpacity(0.08),
              blurRadius: isSelected ? 16 : 10,
              offset: Offset(0, isSelected ? 6 : 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                mood['emoji'] as String,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 6),
              Text(
                mood['label'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                mood['subtitle'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: isSelected
                      ? Colors.white.withOpacity(0.9)
                      : const Color(0xFF718096),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivitiesSection(AppLocalizations l10n) {
    final rows = _activityRows(l10n);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.checkInWhatDidYouDoToday,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: rows.map((row) {
                final tag = row['id'] as String;
                final label = row['label'] as String;
                final isSelected = _selectedActivity == tag;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedActivity = isSelected ? null : tag;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF2A6049), Color(0xFF6DE89A)],
                            )
                          : null,
                      color: isSelected ? null : const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2A6049).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF4A5568),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionsSection(AppLocalizations l10n) {
    final reactions = _quickReactions(l10n);
    final colors = <List<Color>>[
      [const Color(0xFFFF6B9D), const Color(0xFFFFA06B)],
      [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
      [const Color(0xFF6366F1), const Color(0xFF818CF8)],
      [const Color(0xFFEC4899), const Color(0xFFF472B6)],
      [const Color(0xFF2A6049), const Color(0xFF6DE89A)],
      [const Color(0xFF7B68EE), const Color(0xFF9F7AEA)],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.checkInQuickReactionsHeading,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List<Widget>.generate(reactions.length, (i) {
                final reaction = reactions[i];
                final rid = reaction['id'] as String;
                final isSelected = _selectedReactions.contains(rid);
                final gradient = colors[i % colors.length];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedReactions.remove(rid);
                      } else {
                        _selectedReactions.add(rid);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(colors: gradient)
                          : null,
                      color: isSelected ? null : const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: gradient[0].withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reaction['emoji'] as String,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          reaction['label'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF4A5568),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputSection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.checkInTellMeMoreHeading,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: l10n.checkInTextFieldHint,
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 15,
                    color: const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: const Color(0xFF1A202C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton(AppLocalizations l10n) {
    final canSend = _selectedMood != null ||
        _textController.text.isNotEmpty ||
        _selectedReactions.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: canSend
              ? const LinearGradient(
                  colors: [Color(0xFF2A6049), Color(0xFF0E8F38)],
                )
              : null,
          color: canSend ? null : Colors.grey[300],
          borderRadius: BorderRadius.circular(28),
          boxShadow: canSend
              ? [
                  BoxShadow(
                    color: const Color(0xFF2A6049).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: canSend ? _handleSend : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: _isSending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.checkInSendButton,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: canSend ? Colors.white : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.send_rounded,
                      size: 20,
                      color: canSend ? Colors.white : Colors.grey[500],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
