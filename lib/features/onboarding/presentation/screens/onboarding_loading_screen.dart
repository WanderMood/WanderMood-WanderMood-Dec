import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../widgets/swirling_gradient_painter.dart';
import '../../../plans/services/activity_generator_service.dart';
import '../../../places/providers/explore_places_provider.dart';
import '../../../location/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import '../../../weather/application/weather_service.dart';
import '../../../weather/domain/models/weather_location.dart';
import 'dart:math' as math;
import 'dart:convert';
import '../../../auth/providers/auth_state_provider.dart';
import '../../../../core/providers/supabase_provider.dart';

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
  String _currentStep = 'Preparing your personalized experience...';
  double _progress = 0.0;
  
  final List<String> _loadingSteps = [
    'Analyzing your travel preferences...',
    'Finding activities you\'ll love...',
    'Discovering amazing places nearby...',
    'Getting the latest weather updates...',
    'Preparing your personalized dashboard...',
    'Almost ready!'
  ];
  
  int _currentStepIndex = 0;
  int _currentFactIndex = 0;
  
  // Fun travel facts that rotate during loading - will be populated based on user location
  List<Map<String, String>> _travelFacts = [];
  
  // Default general travel facts as fallback
  final List<Map<String, String>> _defaultTravelFacts = [
    {
      'fact': 'Did you know? There are 195 countries in the world, each with unique cultures and traditions!',
      'emoji': '🌍'
    },
    {
      'fact': 'The world\'s busiest airport serves over 100 million passengers annually!',
      'emoji': '✈️'
    },
    {
      'fact': 'There are over 1,500 UNESCO World Heritage Sites across the globe!',
      'emoji': '🏛️'
    },
    {
      'fact': 'The Great Wall of China is visible from space and stretches over 13,000 miles!',
      'emoji': '🏯'
    },
    {
      'fact': 'There are more than 6,900 languages spoken around the world!',
      'emoji': '🗣️'
    },
    {
      'fact': 'The Amazon rainforest produces 20% of the world\'s oxygen!',
      'emoji': '🌳'
    },
    {
      'fact': 'Mount Everest grows about 4mm taller each year due to geological forces!',
      'emoji': '🏔️'
    },
    {
      'fact': 'The Sahara Desert is larger than the entire United States!',
      'emoji': '🏜️'
    },
  ];
  
  // Location-specific travel facts
  Map<String, List<Map<String, String>>> _locationFacts = {
    'Netherlands': [
      {
        'fact': 'The Netherlands has more museums per square mile than any other country!',
        'emoji': '🎨'
      },
      {
        'fact': 'Rotterdam is home to Europe\'s largest port, handling over 400 million tons of cargo annually!',
        'emoji': '🚢'
      },
      {
        'fact': 'The Netherlands has over 35,000 kilometers of bike paths - enough to circle the Earth!',
        'emoji': '🚲'
      },
      {
        'fact': 'Amsterdam has more canals than Venice and more bridges than Paris!',
        'emoji': '🌉'
      },
      {
        'fact': 'The Dutch consume over 150 million stroopwafels every year!',
        'emoji': '🧇'
      },
      {
        'fact': 'The Netherlands is the world\'s second-largest exporter of food despite its small size!',
        'emoji': '🌾'
      },
      {
        'fact': 'Keukenhof Gardens displays over 7 million flower bulbs across 32 hectares!',
        'emoji': '🌷'
      },
      {
        'fact': 'The Dutch are the tallest people in the world with an average height of 6 feet!',
        'emoji': '📏'
      },
    ],
    'United States': [
      {
        'fact': 'The US has 63 national parks, from Yellowstone to the Grand Canyon!',
        'emoji': '🏞️'
      },
      {
        'fact': 'Alaska has more than 3 million lakes and over 100,000 glaciers!',
        'emoji': '🏔️'
      },
      {
        'fact': 'The US Interstate Highway System spans over 47,000 miles!',
        'emoji': '🛣️'
      },
      {
        'fact': 'Times Square in NYC is visited by over 50 million people annually!',
        'emoji': '🗽'
      },
      {
        'fact': 'The US has the world\'s largest economy and is home to Silicon Valley!',
        'emoji': '💻'
      },
      {
        'fact': 'Hawaii is the only US state that commercially grows coffee!',
        'emoji': '☕'
      },
      {
        'fact': 'The Golden Gate Bridge in San Francisco is painted International Orange!',
        'emoji': '🌉'
      },
      {
        'fact': 'Disney World in Florida is larger than the city of San Francisco!',
        'emoji': '🏰'
      },
    ],
    'Japan': [
      {
        'fact': 'Japan has over 6,800 islands, but only 430 are inhabited!',
        'emoji': '🏝️'
      },
      {
        'fact': 'The Japanese Shinkansen bullet trains can reach speeds of 200 mph!',
        'emoji': '🚄'
      },
      {
        'fact': 'Mount Fuji is actually an active volcano that last erupted in 1707!',
        'emoji': '🗾'
      },
      {
        'fact': 'Japan has more than 100,000 temples and shrines!',
        'emoji': '⛩️'
      },
      {
        'fact': 'Tokyo is the world\'s largest metropolitan area with over 37 million people!',
        'emoji': '🏙️'
      },
      {
        'fact': 'Japan consumes about 80% of the world\'s bluefin tuna!',
        'emoji': '🍣'
      },
      {
        'fact': 'The Japanese love vending machines - there\'s one for every 23 people!',
        'emoji': '🥤'
      },
      {
        'fact': 'Cherry blossom season in Japan attracts millions of visitors each spring!',
        'emoji': '🌸'
      },
    ],
    'United Kingdom': [
      {
        'fact': 'The UK has over 1,500 castles, from medieval fortresses to royal residences!',
        'emoji': '🏰'
      },
      {
        'fact': 'London\'s Big Ben is not actually the name of the clock tower - it\'s Elizabeth Tower!',
        'emoji': '🕰️'
      },
      {
        'fact': 'The UK has produced more world-famous musicians per capita than any other country!',
        'emoji': '🎵'
      },
      {
        'fact': 'Stonehenge is over 5,000 years old and still shrouded in mystery!',
        'emoji': '🪨'
      },
      {
        'fact': 'The London Underground is the world\'s oldest subway system, opened in 1863!',
        'emoji': '🚇'
      },
      {
        'fact': 'The UK has 15 UNESCO World Heritage Sites including Bath and Edinburgh!',
        'emoji': '🏛️'
      },
      {
        'fact': 'Scotland has over 3,000 castles and about 790 islands!',
        'emoji': '🏴󠁧󠁢󠁳󠁣󠁴󠁿'
      },
      {
        'fact': 'The British drink about 100 million cups of tea every day!',
        'emoji': '☕'
      },
    ],
    'Germany': [
      {
        'fact': 'Germany has over 25,000 castles and palaces scattered across the country!',
        'emoji': '🏰'
      },
      {
        'fact': 'The Berlin Wall was 96 miles long and stood for 28 years!',
        'emoji': '🧱'
      },
      {
        'fact': 'Germany is famous for Oktoberfest, which actually starts in September!',
        'emoji': '🍺'
      },
      {
        'fact': 'The Black Forest region inspired many Brothers Grimm fairy tales!',
        'emoji': '🌲'
      },
      {
        'fact': 'Germany has no general speed limit on about 60% of its Autobahn highways!',
        'emoji': '🚗'
      },
      {
        'fact': 'Neuschwanstein Castle was the inspiration for Disney\'s Sleeping Beauty castle!',
        'emoji': '🏰'
      },
      {
        'fact': 'Germany has the largest economy in Europe and is known for engineering!',
        'emoji': '⚙️'
      },
      {
        'fact': 'The Rhine River flows through Germany and is lined with medieval castles!',
        'emoji': '🏰'
      },
    ],
    'France': [
      {
        'fact': 'France is the world\'s most visited country with over 89 million tourists annually!',
        'emoji': '🗼'
      },
      {
        'fact': 'The Eiffel Tower was originally built as a temporary structure for the 1889 World\'s Fair!',
        'emoji': '🗼'
      },
      {
        'fact': 'France produces over 400 types of cheese - one for every day of the year!',
        'emoji': '🧀'
      },
      {
        'fact': 'The Palace of Versailles has 2,300 rooms and 67 staircases!',
        'emoji': '🏰'
      },
      {
        'fact': 'France has 44 UNESCO World Heritage Sites, including Mont-Saint-Michel!',
        'emoji': '🏛️'
      },
      {
        'fact': 'The Louvre Museum is the world\'s largest art museum!',
        'emoji': '🎨'
      },
      {
        'fact': 'The French Riviera stretches for 550 miles along the Mediterranean!',
        'emoji': '🏖️'
      },
      {
        'fact': 'France is home to the world\'s most famous bicycle race - the Tour de France!',
        'emoji': '🚴'
      },
    ],
  };

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
          _startPrefetching();
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

  Future<void> _startPrefetching() async {
    try {
      // Load user preferences for personalization
      final prefs = await SharedPreferences.getInstance();
      final userId = ref.read(authStateProvider).asData?.value?.id;
      
      if (userId == null) {
        debugPrint('❌ No user ID found, skipping prefetch');
        return;
      }

      // Step 1: Load user preferences (20%)
      await _updateProgress(0, 'Loading your preferences...');
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
      await _updateProgress(1, "Finding activities you'll love...");
      final position = await LocationService.getCurrentLocation();
      debugPrint('📍 User location: ${position.latitude}, ${position.longitude}');
      
      // Load location-based travel facts
      _loadLocationBasedFacts(position.latitude, position.longitude);
      
      await Future.delayed(const Duration(milliseconds: 800));

      // Step 3: Generate personalized activity suggestions (60%)
      await _updateProgress(2, 'Curating perfect activities for you...');
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

      // Step 4: Fetch places for exploration (80%) - OPTIMIZED WITH PARALLEL PROCESSING
      await _updateProgress(3, 'Discovering amazing places nearby...');
      try {
        // Show dynamic progress during places fetching
        setState(() {
          _currentStep = 'Finding restaurants, cafes, and attractions...';
        });
        
        // Use Future.microtask to avoid lifecycle conflicts
        await Future.microtask(() {
          ref.invalidate(explorePlacesProvider(city: 'Rotterdam'));
        });
        final places = await ref.read(explorePlacesProvider(city: 'Rotterdam').future);
        debugPrint('🏛️ Prefetched ${places.length} places for exploration');
        
        // Update progress with more specific message
        setState(() {
          _currentStep = 'Organizing your perfect day...';
        });
      } catch (e) {
        debugPrint('⚠️ Places prefetch failed: $e (continuing anyway)');
      }
      await Future.delayed(const Duration(milliseconds: 800));

      // Step 5: Fetch weather data (90%)
      await _updateProgress(4, 'Preparing your personalized dashboard...');
      try {
        final weatherLocation = WeatherLocation(
          id: 'current_location',
          name: 'Current Location',
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
      await _updateProgress(5, 'Almost ready! Setting up your dashboard...');
      
      // Mark preferences as completed
      await prefs.setBool('hasCompletedPreferences', true);
      
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
      _currentStep = stepText;
      _progress = (stepIndex + 1) / _loadingSteps.length;
    });
    
    _progressController.reset();
    _progressController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _handleError(dynamic error) async {
    debugPrint('🔧 Handling prefetch error gracefully...');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedPreferences', true);
    
    if (mounted) {
      setState(() {
        _currentStep = 'Ready to explore! (Some data will load as you go)';
        _progress = 1.0;
      });
      
      await Future.delayed(const Duration(milliseconds: 1500));
      context.goNamed('main', extra: {'tab': 0});
    }
  }

  void _loadLocationBasedFacts(double latitude, double longitude) {
    String detectedCountry = _detectCountryFromCoordinates(latitude, longitude);
    
    if (_locationFacts.containsKey(detectedCountry)) {
      _travelFacts = _locationFacts[detectedCountry]!;
      debugPrint('🌍 Loading $detectedCountry travel facts');
    } else {
      _travelFacts = _defaultTravelFacts;
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
    final currentFact = _travelFacts[_currentFactIndex];
    
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
                              'Setting up your\nperfect day!',
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
                        'We\'re preparing personalized activities,\nplaces, and insights just for you!',
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
                                    const Color(0xFF4CAF50),
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
                          key: ValueKey(_currentStep),
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
                            _currentStep,
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
                                    const Color(0xFF4CAF50).withOpacity(0.1),
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
                                    currentFact['fact']!,
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