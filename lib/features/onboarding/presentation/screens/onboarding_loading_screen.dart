import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../widgets/swirling_gradient_painter.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import '../../../plans/services/activity_generator_service.dart';
import '../../../places/providers/moody_explore_provider.dart';
import '../../../location/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/domain/providers/location_notifier_provider.dart';
import '../../../../core/providers/user_location_provider.dart';
import '../../../weather/application/weather_service.dart';
import '../../../weather/domain/models/weather_location.dart';
import 'dart:math' as math;
import 'dart:convert';
import '../../../auth/providers/auth_state_provider.dart';
import '../../../../core/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingLoadingScreen extends ConsumerStatefulWidget {
  const OnboardingLoadingScreen({super.key});

  @override
  ConsumerState<OnboardingLoadingScreen> createState() => _OnboardingLoadingScreenState();
}

class _OnboardingLoadingScreenState extends ConsumerState<OnboardingLoadingScreen> 
    with TickerProviderStateMixin {
  late AnimationController _moodyController;
  late AnimationController _progressController;
  late AnimationController _factController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _factAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isLoading = true;
  /// Shown loading line; empty until first [_updateProgress] (then [loadingStep0] in UI).
  String _currentStepDisplay = '';
  double _progress = 0.0;
  
  static const int _loadingStepsCount = 6;
  
  int _currentStepIndex = 0;
  int _currentFactIndex = 0;
  
  // Fun travel facts that rotate during loading - will be populated based on user location
  List<Map<String, dynamic>> _travelFacts = [];
  
  // Default general travel facts as fallback (factIndex used for l10n lookup)
  static const List<Map<String, dynamic>> _defaultTravelFacts = [
    {'emoji': '🌍', 'factIndex': 0},
    {'emoji': '✈️', 'factIndex': 1},
    {'emoji': '🏛️', 'factIndex': 2},
    {'emoji': '🏯', 'factIndex': 3},
    {'emoji': '🗣️', 'factIndex': 4},
    {'emoji': '🌳', 'factIndex': 5},
    {'emoji': '🏔️', 'factIndex': 6},
    {'emoji': '🏜️', 'factIndex': 7},
  ];
  
  /// Per-country fact rows: emoji + stable id for [AppLocalizations] (loadingFactNl0…).
  static const List<Map<String, dynamic>> _nlFacts = [
    {'emoji': '🎨', 'country': 'nl', 'i': 0},
    {'emoji': '🚢', 'country': 'nl', 'i': 1},
    {'emoji': '🚲', 'country': 'nl', 'i': 2},
    {'emoji': '🌉', 'country': 'nl', 'i': 3},
    {'emoji': '🧇', 'country': 'nl', 'i': 4},
    {'emoji': '🌾', 'country': 'nl', 'i': 5},
    {'emoji': '🌷', 'country': 'nl', 'i': 6},
    {'emoji': '📏', 'country': 'nl', 'i': 7},
  ];
  static const List<Map<String, dynamic>> _usFacts = [
    {'emoji': '🏞️', 'country': 'us', 'i': 0},
    {'emoji': '🏔️', 'country': 'us', 'i': 1},
    {'emoji': '🛣️', 'country': 'us', 'i': 2},
    {'emoji': '🗽', 'country': 'us', 'i': 3},
    {'emoji': '💻', 'country': 'us', 'i': 4},
    {'emoji': '☕', 'country': 'us', 'i': 5},
    {'emoji': '🌉', 'country': 'us', 'i': 6},
    {'emoji': '🏰', 'country': 'us', 'i': 7},
  ];
  static const List<Map<String, dynamic>> _jpFacts = [
    {'emoji': '🏝️', 'country': 'jp', 'i': 0},
    {'emoji': '🚄', 'country': 'jp', 'i': 1},
    {'emoji': '🗾', 'country': 'jp', 'i': 2},
    {'emoji': '⛩️', 'country': 'jp', 'i': 3},
    {'emoji': '🏙️', 'country': 'jp', 'i': 4},
    {'emoji': '🍣', 'country': 'jp', 'i': 5},
    {'emoji': '🥤', 'country': 'jp', 'i': 6},
    {'emoji': '🌸', 'country': 'jp', 'i': 7},
  ];
  static const List<Map<String, dynamic>> _ukFacts = [
    {'emoji': '🏰', 'country': 'uk', 'i': 0},
    {'emoji': '🕰️', 'country': 'uk', 'i': 1},
    {'emoji': '🎵', 'country': 'uk', 'i': 2},
    {'emoji': '🪨', 'country': 'uk', 'i': 3},
    {'emoji': '🚇', 'country': 'uk', 'i': 4},
    {'emoji': '🏛️', 'country': 'uk', 'i': 5},
    {'emoji': '🏴󠁧󠁢󠁳󠁣󠁴󠁿', 'country': 'uk', 'i': 6},
    {'emoji': '☕', 'country': 'uk', 'i': 7},
  ];
  static const List<Map<String, dynamic>> _deFacts = [
    {'emoji': '🏰', 'country': 'de', 'i': 0},
    {'emoji': '🧱', 'country': 'de', 'i': 1},
    {'emoji': '🍺', 'country': 'de', 'i': 2},
    {'emoji': '🌲', 'country': 'de', 'i': 3},
    {'emoji': '🚗', 'country': 'de', 'i': 4},
    {'emoji': '🏰', 'country': 'de', 'i': 5},
    {'emoji': '⚙️', 'country': 'de', 'i': 6},
    {'emoji': '🏰', 'country': 'de', 'i': 7},
  ];
  static const List<Map<String, dynamic>> _frFacts = [
    {'emoji': '🗼', 'country': 'fr', 'i': 0},
    {'emoji': '🗼', 'country': 'fr', 'i': 1},
    {'emoji': '🧀', 'country': 'fr', 'i': 2},
    {'emoji': '🏰', 'country': 'fr', 'i': 3},
    {'emoji': '🏛️', 'country': 'fr', 'i': 4},
    {'emoji': '🎨', 'country': 'fr', 'i': 5},
    {'emoji': '🏖️', 'country': 'fr', 'i': 6},
    {'emoji': '🚴', 'country': 'fr', 'i': 7},
  ];

  // Floating elements for visual appeal
  final List<String> _floatingEmojis = ['✈️', '🗺️', '📸', '🎒', '🧭', '🌍', '🎯', '💫'];

  @override
  void initState() {
    super.initState();
    
    // Initialize with default travel facts
    _travelFacts = _defaultTravelFacts;
    
    _moodyController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _factController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.elasticOut,
    ));
    
    _factAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _factController,
      curve: Curves.easeOutBack,
    ));
    
    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_floatingController);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start prefetching after the widget is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
        if (mounted) {
          _startPrefetching(context);
        }
      });
    });
    _startFactRotation();
  }

  @override
  void dispose() {
    _moodyController.dispose();
    _progressController.dispose();
    _factController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startFactRotation() {
    // Rotate facts every 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) {
        setState(() {
          _currentFactIndex = (_currentFactIndex + 1) % _travelFacts.length;
        });
        _factController.reset();
        _factController.forward();
        _startFactRotation();
      }
    });
  }

  Future<void> _startPrefetching(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Load user preferences for personalization
      final prefs = await SharedPreferences.getInstance();
      final userId = ref.read(authStateProvider).asData?.value?.id;
      
      if (userId == null) {
        debugPrint('❌ No user ID found, skipping prefetch');
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
      
      // Load location-based travel facts
      _loadLocationBasedFacts(position.latitude, position.longitude);
      
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
        context.goNamed('main', extra: {'tab': tabIndex});
      }
    } catch (e) {
      debugPrint('❌ Prefetch failed: $e');
      // Continue to app even if prefetch fails
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final hasCompletedFirstPlan = prefs.getBool('has_completed_first_plan') ?? false;
        final tabIndex = hasCompletedFirstPlan ? 0 : 2;
        context.goNamed('main', extra: {'tab': tabIndex});
      }
    }
  }

  Future<void> _updateProgress(int stepIndex, String stepText) async {
    if (!mounted) return;
    
    setState(() {
      _currentStepIndex = stepIndex;
      _currentStepDisplay = stepText;
      _progress = (stepIndex + 1) / _loadingStepsCount;
    });
    
    _progressController.reset();
    _progressController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _handleError(dynamic error) async {
    debugPrint('🔧 Handling prefetch error gracefully...');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedPreferences', true);
    
    // CRITICAL: Also update database so login checks work correctly
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('user_preferences')
            .update({'has_completed_preferences': true})
            .eq('user_id', user.id);
        debugPrint('✅ Updated has_completed_preferences=true in database (error handler)');
      }
    } catch (e) {
      debugPrint('⚠️ Could not update preferences completion flag in database: $e');
      // Non-critical - local flag is set, user can proceed
    }
    
    if (mounted) {
      setState(() {
        _currentStepDisplay = AppLocalizations.of(context)!.loadingStep6;
        _progress = 1.0;
      });
      
      await Future.delayed(const Duration(milliseconds: 1500));
      context.goNamed('main', extra: {'tab': 0});
    }
  }

  static String _getFactText(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    switch (index) {
      case 0: return l10n.loadingFact0;
      case 1: return l10n.loadingFact1;
      case 2: return l10n.loadingFact2;
      case 3: return l10n.loadingFact3;
      case 4: return l10n.loadingFact4;
      case 5: return l10n.loadingFact5;
      case 6: return l10n.loadingFact6;
      case 7: return l10n.loadingFact7;
      default: return '';
    }
  }

  static String _localizedLocationFact(AppLocalizations l10n, String country, int i) {
    switch (country) {
      case 'nl':
        switch (i) {
          case 0: return l10n.loadingFactNl0;
          case 1: return l10n.loadingFactNl1;
          case 2: return l10n.loadingFactNl2;
          case 3: return l10n.loadingFactNl3;
          case 4: return l10n.loadingFactNl4;
          case 5: return l10n.loadingFactNl5;
          case 6: return l10n.loadingFactNl6;
          case 7: return l10n.loadingFactNl7;
          default: return '';
        }
      case 'us':
        switch (i) {
          case 0: return l10n.loadingFactUs0;
          case 1: return l10n.loadingFactUs1;
          case 2: return l10n.loadingFactUs2;
          case 3: return l10n.loadingFactUs3;
          case 4: return l10n.loadingFactUs4;
          case 5: return l10n.loadingFactUs5;
          case 6: return l10n.loadingFactUs6;
          case 7: return l10n.loadingFactUs7;
          default: return '';
        }
      case 'jp':
        switch (i) {
          case 0: return l10n.loadingFactJp0;
          case 1: return l10n.loadingFactJp1;
          case 2: return l10n.loadingFactJp2;
          case 3: return l10n.loadingFactJp3;
          case 4: return l10n.loadingFactJp4;
          case 5: return l10n.loadingFactJp5;
          case 6: return l10n.loadingFactJp6;
          case 7: return l10n.loadingFactJp7;
          default: return '';
        }
      case 'uk':
        switch (i) {
          case 0: return l10n.loadingFactUk0;
          case 1: return l10n.loadingFactUk1;
          case 2: return l10n.loadingFactUk2;
          case 3: return l10n.loadingFactUk3;
          case 4: return l10n.loadingFactUk4;
          case 5: return l10n.loadingFactUk5;
          case 6: return l10n.loadingFactUk6;
          case 7: return l10n.loadingFactUk7;
          default: return '';
        }
      case 'de':
        switch (i) {
          case 0: return l10n.loadingFactDe0;
          case 1: return l10n.loadingFactDe1;
          case 2: return l10n.loadingFactDe2;
          case 3: return l10n.loadingFactDe3;
          case 4: return l10n.loadingFactDe4;
          case 5: return l10n.loadingFactDe5;
          case 6: return l10n.loadingFactDe6;
          case 7: return l10n.loadingFactDe7;
          default: return '';
        }
      case 'fr':
        switch (i) {
          case 0: return l10n.loadingFactFr0;
          case 1: return l10n.loadingFactFr1;
          case 2: return l10n.loadingFactFr2;
          case 3: return l10n.loadingFactFr3;
          case 4: return l10n.loadingFactFr4;
          case 5: return l10n.loadingFactFr5;
          case 6: return l10n.loadingFactFr6;
          case 7: return l10n.loadingFactFr7;
          default: return '';
        }
      default:
        return '';
    }
  }

  void _loadLocationBasedFacts(double latitude, double longitude) {
    final detectedCountry = _detectCountryFromCoordinates(latitude, longitude);
    switch (detectedCountry) {
      case 'Netherlands':
        _travelFacts = List<Map<String, dynamic>>.from(_nlFacts);
        debugPrint('🌍 Loading Netherlands travel facts');
        break;
      case 'United States':
        _travelFacts = List<Map<String, dynamic>>.from(_usFacts);
        debugPrint('🌍 Loading United States travel facts');
        break;
      case 'Japan':
        _travelFacts = List<Map<String, dynamic>>.from(_jpFacts);
        debugPrint('🌍 Loading Japan travel facts');
        break;
      case 'United Kingdom':
        _travelFacts = List<Map<String, dynamic>>.from(_ukFacts);
        debugPrint('🌍 Loading United Kingdom travel facts');
        break;
      case 'Germany':
        _travelFacts = List<Map<String, dynamic>>.from(_deFacts);
        debugPrint('🌍 Loading Germany travel facts');
        break;
      case 'France':
        _travelFacts = List<Map<String, dynamic>>.from(_frFacts);
        debugPrint('🌍 Loading France travel facts');
        break;
      default:
        _travelFacts = List<Map<String, dynamic>>.from(_defaultTravelFacts);
        debugPrint('🌍 Loading default travel facts');
    }
  }
  
  String _detectCountryFromCoordinates(double latitude, double longitude) {
    // Simple coordinate-based country detection
    // Netherlands bounds: 50.75-53.7 N, 3.2-7.22 E
    if (latitude >= 50.75 && latitude <= 53.7 && longitude >= 3.2 && longitude <= 7.22) {
      return 'Netherlands';
    }
    
    // United States bounds: 24.7-49.4 N, -125 to -66.9 W
    if (latitude >= 24.7 && latitude <= 49.4 && longitude >= -125 && longitude <= -66.9) {
      return 'United States';
    }
    
    // Japan bounds: 24-46 N, 123-146 E
    if (latitude >= 24 && latitude <= 46 && longitude >= 123 && longitude <= 146) {
      return 'Japan';
    }
    
    // United Kingdom bounds: 49.9-61 N, -8.5 to 1.8 E
    if (latitude >= 49.9 && latitude <= 61 && longitude >= -8.5 && longitude <= 1.8) {
      return 'United Kingdom';
    }
    
    // Germany bounds: 47.3-55.1 N, 5.9-15.0 E
    if (latitude >= 47.3 && latitude <= 55.1 && longitude >= 5.9 && longitude <= 15.0) {
      return 'Germany';
    }
    
    // France bounds: 41.3-51.1 N, -5.1 to 9.6 E
    if (latitude >= 41.3 && latitude <= 51.1 && longitude >= -5.1 && longitude <= 9.6) {
      return 'France';
    }
    
    return 'Unknown';
  }

  Widget _buildFloatingEmoji(String emoji, double delay) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        final offsetY = math.sin((_floatingAnimation.value * 2 * math.pi) + delay) * 20;
        final offsetX = math.cos((_floatingAnimation.value * 2 * math.pi) + delay) * 10;
        
        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentFact = _travelFacts[_currentFactIndex];
    final String factBody = currentFact.containsKey('country')
        ? _localizedLocationFact(
            l10n,
            currentFact['country'] as String,
            currentFact['i'] as int,
          )
        : _getFactText(context, currentFact['factIndex'] as int);
    final String stepLabel =
        _currentStepDisplay.isEmpty ? l10n.loadingStep0 : _currentStepDisplay;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFDF5),
              Color(0xFFFFF3E0),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Swirl effect
              Positioned.fill(
                child: CustomPaint(
                  painter: SwirlingGradientPainter(),
                ),
              ),
              
              // Floating emojis
              ...List.generate(_floatingEmojis.length, (index) {
                final emoji = _floatingEmojis[index];
                final random = math.Random(index);
                final left = random.nextDouble() * (MediaQuery.of(context).size.width - 50);
                final top = 100.0 + random.nextDouble() * 200;
                
                return Positioned(
                  left: left,
                  top: top,
                  child: _buildFloatingEmoji(emoji, index * 0.5),
                ).animate(delay: Duration(milliseconds: index * 200))
                 .fadeIn(duration: 800.ms)
                 .scale(begin: const Offset(0, 0), duration: 600.ms);
              }),
              
              // Main content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                      // Moody character with enhanced animation
                      AnimatedBuilder(
                        animation: _moodyController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (0.15 * math.sin(_moodyController.value * 2 * math.pi)),
                            child: Transform.rotate(
                              angle: math.sin(_moodyController.value * 2 * math.pi) * 0.1,
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF5BB32A).withOpacity(0.3),
                                          blurRadius: 20 * _pulseAnimation.value,
                                          spreadRadius: 5 * _pulseAnimation.value,
                                        ),
                                      ],
                                    ),
                                    child: const MoodyCharacter(
                                      size: 120,
                                      mood: 'excited',
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ).animate()
                       .fadeIn(duration: 800.ms)
                       .scale(duration: 600.ms, curve: Curves.elasticOut),
                
                const SizedBox(height: 40),
                
                      // Animated title with sparkles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                          Text(
                            '✨',
                            style: const TextStyle(fontSize: 24),
                          ).animate(onPlay: (controller) => controller.repeat())
                           .shimmer(duration: 2000.ms, color: Colors.amber),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              AppLocalizations.of(context)!.loadingTitle,
                              style: GoogleFonts.museoModerno(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5BB32A),
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '✨',
                            style: const TextStyle(fontSize: 24),
                          ).animate(onPlay: (controller) => controller.repeat())
                           .shimmer(duration: 2000.ms, color: Colors.amber, delay: 1000.ms),
                        ],
                      ).animate()
                       .fadeIn(duration: 800.ms, delay: 200.ms)
                       .slideY(begin: 0.3, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      // Subtitle with typewriter effect
                      Text(
                        AppLocalizations.of(context)!.loadingSubtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ).animate()
                       .fadeIn(duration: 800.ms, delay: 400.ms)
                       .slideY(begin: 0.3, end: 0),
                      
                      const SizedBox(height: 48),
                      
                      // Enhanced progress indicator with glow
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF5BB32A),
                                    const Color(0xFF2A6049),
                                    const Color(0xFF66BB6A),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF5BB32A).withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: LinearProgressIndicator(
                                value: _progress * _progressAnimation.value,
                                backgroundColor: Colors.transparent,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.transparent),
                                minHeight: 12,
                              ),
                            );
                          },
                        ),
                      ).animate()
                       .fadeIn(duration: 800.ms, delay: 600.ms)
                       .slideX(begin: -1, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Progress percentage with bounce effect
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (0.2 * _progressAnimation.value),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5BB32A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF5BB32A).withOpacity(0.3),
                                  width: 2,
                          ),
                        ),
                        child: Text(
                                '${(_progress * 100).round()}%',
                          style: GoogleFonts.poppins(
                                  fontSize: 18,
                            fontWeight: FontWeight.w600,
                                  color: const Color(0xFF5BB32A),
                                ),
                              ),
                            ),
                          );
                        },
                      ).animate()
                       .fadeIn(duration: 800.ms, delay: 700.ms),
                      
                      const SizedBox(height: 24),
                      
                      // Current step with slide animation
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          key: ValueKey(stepLabel),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            stepLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Fun fact section with rotation animation
                      AnimatedBuilder(
                        animation: _factAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _factAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF5BB32A).withOpacity(0.1),
                                    const Color(0xFF2A6049).withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF5BB32A).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    currentFact['emoji']!,
                                    style: const TextStyle(fontSize: 32),
                                  ).animate(onPlay: (controller) => controller.repeat())
                                   .rotate(duration: 3000.ms),
                                  const SizedBox(height: 12),
                                  Text(
                                    factBody,
                          style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.black87,
                            fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Animated loading dots with stagger effect
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF5BB32A),
                                  const Color(0xFF66BB6A),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF5BB32A).withOpacity(0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ).animate(
                            onPlay: (controller) => controller.repeat(),
                          ).scale(
                            duration: Duration(milliseconds: 800 + index * 200),
                            curve: Curves.easeInOut,
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.2, 1.2),
                          ).then()
                           .scale(
                             duration: Duration(milliseconds: 800 + index * 200),
                             curve: Curves.easeInOut,
                             begin: const Offset(1.2, 1.2),
                             end: const Offset(0.8, 0.8),
                           );
                        }),
                      ),
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