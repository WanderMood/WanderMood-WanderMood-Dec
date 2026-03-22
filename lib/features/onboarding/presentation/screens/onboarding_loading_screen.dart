import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import '../../../location/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import '../../../weather/application/weather_service.dart';
import '../../../weather/domain/models/weather_location.dart';
import 'dart:convert';
import '../../../auth/providers/auth_state_provider.dart';
import '../../../../core/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Post–magic-link loading (wmForest)
const Color _wmForest = Color(0xFF2A6049);
const Color _wmWhite = Color(0xFFFFFFFF);

class OnboardingLoadingScreen extends ConsumerStatefulWidget {
  const OnboardingLoadingScreen({super.key});

  @override
  ConsumerState<OnboardingLoadingScreen> createState() => _OnboardingLoadingScreenState();
}

class _OnboardingLoadingScreenState extends ConsumerState<OnboardingLoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final Animation<double> _breathScale;
  late final AnimationController _fadeOutController;
  late final Animation<double> _fadeOpacity;

  /// Shown loading line; empty until first [_updateProgress] (then [loadingStep0] in UI).
  String _currentStepDisplay = '';
  double _progress = 0.0;
  
  static const int _loadingStepsCount = 6;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _breathScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
        if (mounted) {
          _startPrefetching(context);
        }
      });
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  Future<void> _exitWithFade(VoidCallback navigate) async {
    await _fadeOutController.forward();
    if (!mounted) return;
    navigate();
  }

  Future<void> _startPrefetching(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Load user preferences for personalization
      final prefs = await SharedPreferences.getInstance();
      final userId = ref.read(authStateProvider).asData?.value?.id;
      
      if (userId == null) {
        debugPrint('❌ No user ID found, skipping prefetch');
        if (mounted) {
          final prefsEarly = await SharedPreferences.getInstance();
          final hasCompletedFirstPlanEarly =
              prefsEarly.getBool('has_completed_first_plan') ?? false;
          final tabEarly = hasCompletedFirstPlanEarly ? 0 : 2;
          await _exitWithFade(
            () => context.goNamed('main', extra: {'tab': tabEarly}),
          );
        }
        return;
      }

      // Step 1: Load user preferences (20%)
      await _updateProgress(0, l10n.loadingStep1);
      Map<String, dynamic>? userPreferences;
      try {
        final response = await ref.read(supabaseClientProvider)
            .from('user_preferences')
            .select('*')
            .eq('user_id', userId)
            .single();
        userPreferences = response;
        debugPrint('✅ Loaded user preferences: ${userPreferences.keys}');
      } catch (e) {
        debugPrint('⚠️ Could not load user preferences: $e');
      }

      // Step 2: Get user location (40%)
      await _updateProgress(1, l10n.loadingStep2);
      final position = await LocationService.getCurrentLocation();
      debugPrint('📍 User location: ${position.latitude}, ${position.longitude}');

      await Future.delayed(const Duration(milliseconds: 800));

      // Step 3: Generate personalized activity suggestions (60%)
      await _updateProgress(2, l10n.loadingStep3);
      try {
        final activitySuggestions = await _generatePersonalizedActivities(
          userPreferences: userPreferences,
          position: position,
          userId: userId,
        );
        debugPrint('🎯 Generated ${activitySuggestions.length} personalized activities');
        
        // Prefetch activity images
        await _prefetchActivityImages(activitySuggestions);
        debugPrint('🖼️ Prefetched activity images');
      } catch (e) {
        debugPrint('⚠️ Activity suggestions failed: $e (continuing anyway)');
      }
      await Future.delayed(const Duration(milliseconds: 1000));

      // Step 4: Skip places prefetch here - moved to MainScreen for better timing
      // Places will be prefetched in background after MainScreen loads (user is authenticated, session established)
      await _updateProgress(3, l10n.loadingStep4);
      await Future.delayed(const Duration(milliseconds: 600));

      // Step 5: Fetch weather data (90%)
      await _updateProgress(4, l10n.loadingStep5);
      try {
        final weatherLocation = WeatherLocation(
          id: 'current_location',
          name: l10n.weatherCurrentLocation,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        await ref.read(weatherServiceProvider.notifier).getCurrentWeather(weatherLocation);
        debugPrint('🌤️ Fetched weather data');
      } catch (e) {
        debugPrint('⚠️ Weather fetch failed: $e (continuing anyway)');
      }
      await Future.delayed(const Duration(milliseconds: 600));

      // Step 6: Finalize and prepare dashboard (100%)
      await _updateProgress(5, l10n.loadingStep6);
      
      // Mark preferences as completed in local storage
      await prefs.setBool('hasCompletedPreferences', true);
      
      // CRITICAL: Also update database so login checks work correctly
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Supabase.instance.client
              .from('user_preferences')
              .update({'has_completed_preferences': true})
              .eq('user_id', user.id);
          debugPrint('✅ Updated has_completed_preferences=true in database');
        }
      } catch (e) {
        debugPrint('⚠️ Could not update preferences completion flag in database: $e');
        // Non-critical - local flag is set, user can proceed
      }
      
      // Check if this is first-time user (hasn't created a plan yet)
      final hasCompletedFirstPlan = prefs.getBool('has_completed_first_plan') ?? false;
      
      // Cache timestamp for activity suggestions
      await prefs.setString('lastActivitySuggestionUpdate', DateTime.now().toIso8601String());
      
      debugPrint('✅ Prefetch completed successfully!');
      await Future.delayed(const Duration(milliseconds: 1000));

      // Navigate to main app
      if (mounted) {
        debugPrint('🚀 Navigating to main app...');
        // First-time users go to Moody Hub (tab 2), returning users go to My Day (tab 0)
        final tabIndex = hasCompletedFirstPlan ? 0 : 2;
        debugPrint('📍 First-time user: ${!hasCompletedFirstPlan}, routing to tab: $tabIndex');
        await _exitWithFade(
          () => context.goNamed('main', extra: {'tab': tabIndex}),
        );
      }
    } catch (e) {
      debugPrint('❌ Prefetch failed: $e');
      // Continue to app even if prefetch fails
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final hasCompletedFirstPlan = prefs.getBool('has_completed_first_plan') ?? false;
        final tabIndex = hasCompletedFirstPlan ? 0 : 2;
        await _exitWithFade(
          () => context.goNamed('main', extra: {'tab': tabIndex}),
        );
      }
    }
  }

  Future<void> _updateProgress(int stepIndex, String stepText) async {
    if (!mounted) return;

    setState(() {
      _currentStepDisplay = stepText;
      _progress = (stepIndex + 1) / _loadingStepsCount;
    });

    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String stepLabel =
        _currentStepDisplay.isEmpty ? l10n.loadingStep0 : _currentStepDisplay;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _wmForest,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _wmForest,
        body: FadeTransition(
          opacity: _fadeOpacity,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Center(
                    child: ScaleTransition(
                      alignment: Alignment.center,
                      scale: _breathScale,
                      child: const MoodyCharacter(
                        size: 120,
                        mood: 'excited',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.loadingTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _wmWhite,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: Text(
                      stepLabel,
                      key: ValueKey<String>(stepLabel),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        height: 1.45,
                        color: _wmWhite.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _progress.clamp(0.0, 1.0),
                          backgroundColor: _wmWhite.withValues(alpha: 0.2),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(_wmWhite),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Generate personalized activity suggestions based on user preferences
  Future<List<Map<String, dynamic>>> _generatePersonalizedActivities({
    Map<String, dynamic>? userPreferences,
    required Position position,
    required String userId,
  }) async {
    final List<Map<String, dynamic>> activities = [];
    
    // Get current time for time-based suggestions
    final now = DateTime.now();
    final hour = now.hour;
    final isWeekend = now.weekday >= 6;
    
    // Extract user mood preferences with safe type casting
    List<dynamic> parseListField(dynamic value) {
      if (value == null) return [];
      if (value is List) return value;
      if (value is String) {
        if (value.contains(',')) {
          return value.split(',').map((s) => s.trim()).toList();
        }
        return value.isEmpty ? [] : [value];
      }
      return [];
    }

    final moodPreferences = parseListField(userPreferences?['mood_preferences']);
    final interests = parseListField(userPreferences?['interests']);
    final socialVibe = userPreferences?['social_vibe'] as String? ?? 'mixed';
    
    debugPrint('🎯 Generating activities for moods: $moodPreferences, interests: $interests');
    
    // Generate time-appropriate activities
    if (hour >= 6 && hour < 12) {
      // Morning activities
      activities.addAll(await _getMorningActivities(moodPreferences, interests, position));
    } else if (hour >= 12 && hour < 17) {
      // Afternoon activities
      activities.addAll(await _getAfternoonActivities(moodPreferences, interests, position));
    } else {
      // Evening activities
      activities.addAll(await _getEveningActivities(moodPreferences, interests, position));
    }
    
    // Add weekend-specific activities
    if (isWeekend) {
      activities.addAll(await _getWeekendActivities(moodPreferences, interests, position));
    }
    
    // Add social vibe appropriate activities
    activities.addAll(await _getSocialVibeActivities(socialVibe, moodPreferences, position));
    
    // Store in cache for My Day screen
    final prefs = await SharedPreferences.getInstance();
    final activitiesJson = activities.map((a) => jsonEncode(a)).toList();
    await prefs.setStringList('cached_activity_suggestions', activitiesJson);
    
    return activities.take(8).toList(); // Limit to 8 activities
  }

  /// Get morning-appropriate activities
  Future<List<Map<String, dynamic>>> _getMorningActivities(
    List<dynamic> moodPreferences,
    List<dynamic> interests,
    Position position,
  ) async {
    final activities = <Map<String, dynamic>>[];
    
    // Coffee & breakfast spots
    activities.add({
      'id': 'morning_coffee_${DateTime.now().millisecondsSinceEpoch}',
      'title': 'Start with Great Coffee',
      'description': 'Find a cozy café nearby for your morning boost',
      'category': 'food',
      'timeOfDay': 'morning',
      'duration': 45,
      'mood': 'energetic',
      'imageUrl': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&q=80',
      'isRecommended': moodPreferences.contains('energetic'),
    });
    
    // Morning walk/exercise
    if (moodPreferences.contains('energetic') || interests.contains('fitness')) {
      activities.add({
        'id': 'morning_walk_${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Morning Walk in Nature',
        'description': 'Get energized with a refreshing walk in nearby parks',
        'category': 'exercise',
        'timeOfDay': 'morning',
        'duration': 60,
        'mood': 'energetic',
        'imageUrl': 'https://images.unsplash.com/photo-1544920403-4c9d4c3e8e2e?w=400&q=80',
        'isRecommended': true,
      });
    }
    
    return activities;
  }

  /// Get afternoon-appropriate activities
  Future<List<Map<String, dynamic>>> _getAfternoonActivities(
    List<dynamic> moodPreferences,
    List<dynamic> interests,
    Position position,
  ) async {
    final activities = <Map<String, dynamic>>[];
    
    // Museums & culture
    if (interests.contains('culture') || moodPreferences.contains('curious')) {
      activities.add({
        'id': 'afternoon_museum_${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Explore Local Museums',
        'description': 'Discover fascinating art and history nearby',
        'category': 'culture',
        'timeOfDay': 'afternoon',
        'duration': 120,
        'mood': 'curious',
        'imageUrl': 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=400&q=80',
        'isRecommended': true,
      });
    }
    
    // Lunch spots
    activities.add({
      'id': 'afternoon_lunch_${DateTime.now().millisecondsSinceEpoch}',
      'title': 'Delicious Local Lunch',
      'description': 'Try authentic local cuisine at nearby restaurants',
      'category': 'food',
      'timeOfDay': 'afternoon',
      'duration': 90,
      'mood': 'relaxed',
      'imageUrl': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&q=80',
      'isRecommended': moodPreferences.contains('relaxed'),
    });
    
    return activities;
  }

  /// Get evening-appropriate activities
  Future<List<Map<String, dynamic>>> _getEveningActivities(
    List<dynamic> moodPreferences,
    List<dynamic> interests,
    Position position,
  ) async {
    final activities = <Map<String, dynamic>>[];
    
    // Evening dining
    activities.add({
      'id': 'evening_dinner_${DateTime.now().millisecondsSinceEpoch}',
      'title': 'Perfect Dinner Spot',
      'description': 'End your day with a memorable dining experience',
      'category': 'food',
      'timeOfDay': 'evening',
      'duration': 120,
      'mood': 'relaxed',
      'imageUrl': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&q=80',
      'isRecommended': true,
    });
    
    // Evening entertainment
    if (moodPreferences.contains('social') || interests.contains('nightlife')) {
      activities.add({
        'id': 'evening_entertainment_${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Evening Entertainment',
        'description': 'Enjoy live music, bars, or cultural events',
        'category': 'entertainment',
        'timeOfDay': 'evening',
        'duration': 180,
        'mood': 'social',
        'imageUrl': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&q=80',
        'isRecommended': true,
      });
    }
    
    return activities;
  }

  /// Get weekend-specific activities
  Future<List<Map<String, dynamic>>> _getWeekendActivities(
    List<dynamic> moodPreferences,
    List<dynamic> interests,
    Position position,
  ) async {
    final activities = <Map<String, dynamic>>[];
    
    // Weekend markets
    activities.add({
      'id': 'weekend_market_${DateTime.now().millisecondsSinceEpoch}',
      'title': 'Weekend Market Visit',
      'description': 'Browse local markets for unique finds and treats',
      'category': 'shopping',
      'timeOfDay': 'morning',
      'duration': 90,
      'mood': 'curious',
      'imageUrl': 'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=400&q=80',
      'isRecommended': moodPreferences.contains('curious'),
    });
    
    return activities;
  }

  /// Get social vibe appropriate activities
  Future<List<Map<String, dynamic>>> _getSocialVibeActivities(
    String socialVibe,
    List<dynamic> moodPreferences,
    Position position,
  ) async {
    final activities = <Map<String, dynamic>>[];
    
    if (socialVibe == 'social' || socialVibe == 'mixed') {
      activities.add({
        'id': 'social_activity_${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Social Hangout Spots',
        'description': 'Perfect places to meet people and socialize',
        'category': 'social',
        'timeOfDay': 'any',
        'duration': 120,
        'mood': 'social',
        'imageUrl': 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=400&q=80',
        'isRecommended': true,
      });
    }
    
    return activities;
  }

  /// Prefetch activity images for instant loading
  Future<void> _prefetchActivityImages(List<Map<String, dynamic>> activities) async {
    final List<String> imageUrls = activities
        .map((activity) => activity['imageUrl'] as String?)
        .where((url) => url != null)
        .cast<String>()
        .toList();
    
    debugPrint('🖼️ Prefetching ${imageUrls.length} activity images');
    
    // Store image URLs in cache for pre-loading
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cached_activity_images', imageUrls);
    
    // In a real app, you'd use a proper image caching library like cached_network_image
    // For now, we'll just store the URLs for the UI to use
  }
} 