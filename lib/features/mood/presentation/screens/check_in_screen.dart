import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../home/providers/dynamic_my_day_provider.dart';
import '../../providers/daily_mood_state_provider.dart';
import '../../models/check_in.dart';
import '../../models/activity_rating.dart';
import '../../services/check_in_service.dart';
import '../../services/moody_ai_service.dart';
import '../../services/activity_rating_service.dart';
import '../widgets/activity_rating_sheet.dart';
import 'dart:math' as math;

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
  String _greeting = "Hey! How's your day going?";
  int _streak = 0;
  
  late AnimationController _moodyAnimationController;
  late Animation<double> _moodyScaleAnimation;
  late AnimationController _floatController;
  
  // Quick mood options with more personality
  final List<Map<String, dynamic>> _quickMoods = [
    {
      'emoji': '😊',
      'label': 'Great',
      'value': 'great',
      'subtitle': 'Living my best life!',
      'gradient': [const Color(0xFFFFD166), const Color(0xFFFF9A00)],
    },
    {
      'emoji': '😴',
      'label': 'Tired',
      'value': 'tired',
      'subtitle': 'Need some rest',
      'gradient': [const Color(0xFF7B68EE), const Color(0xFF9F7AEA)],
    },
    {
      'emoji': '🎉',
      'label': 'Amazing',
      'value': 'amazing',
      'subtitle': 'Best day ever!',
      'gradient': [const Color(0xFFFF6B9D), const Color(0xFFFFA06B)],
    },
    {
      'emoji': '😐',
      'label': 'Okay',
      'value': 'okay',
      'subtitle': 'Just coasting',
      'gradient': [const Color(0xFF94A3B8), const Color(0xFFCBD5E0)],
    },
    {
      'emoji': '🤔',
      'label': 'Thoughtful',
      'value': 'thoughtful',
      'subtitle': 'In my feels',
      'gradient': [const Color(0xFF6366F1), const Color(0xFF818CF8)],
    },
    {
      'emoji': '😌',
      'label': 'Chill',
      'value': 'chill',
      'subtitle': 'Taking it easy',
      'gradient': [const Color(0xFF12B347), const Color(0xFF6DE89A)],
    },
  ];
  
  // Quick activity tags
  final List<String> _activityTags = [
    'Explored places',
    'Had great food',
    'Met friends',
    'Relaxed',
    'Worked out',
    'Creative time',
    'Adventure',
    'Self-care',
  ];
  
  // Quick reactions (like FaceTime reactions)
  final List<Map<String, dynamic>> _quickReactions = [
    {'emoji': '❤️', 'label': 'Loved it'},
    {'emoji': '🔥', 'label': 'On fire'},
    {'emoji': '✨', 'label': 'Magical'},
    {'emoji': '😅', 'label': 'Exhausted'},
    {'emoji': '🤩', 'label': 'Amazing'},
    {'emoji': '😌', 'label': 'Peaceful'},
  ];

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
    final hour = DateTime.now().hour;
    
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
    final streak = await checkInService.getCheckInStreak();
    if (mounted) {
      setState(() {
        _streak = streak;
      });
    }
  }

  void _handleSend() async {
    if (_isSending) return;
    
    setState(() => _isSending = true);
    
    try {
      // Save check-in to memory
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final checkIn = CheckIn(
          id: 'checkin_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          mood: _selectedMood,
          activities: _selectedActivity != null ? [_selectedActivity!] : [],
          reactions: _selectedReactions,
          text: _textController.text.trim().isNotEmpty ? _textController.text.trim() : null,
          timestamp: DateTime.now(),
        );
        
        final checkInService = CheckInService(Supabase.instance.client);
        await checkInService.saveCheckIn(checkIn);
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
    final response = await _getMoodyResponse(pendingActivities: pendingActivities);
    
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
                          const Color(0xFF12B347).withOpacity(0.3),
                          const Color(0xFF12B347).withOpacity(0.0),
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
                    colors: [Color(0xFF12B347), Color(0xFF0E8F38)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF12B347).withOpacity(0.4),
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
                    'Thanks Moody! 💚',
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

  Future<String> _getMoodyResponse({List<ActivityRating>? pendingActivities}) async {
    try {
      // Use AI service for intelligent, contextual responses
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
      // Fallback to simple response
      return 'Thanks for checking in! I love hearing about your day 💛';
    }
  }
  
  /// Get activities that were scheduled for today and could be rated
  Future<List<ActivityRating>> _getPendingActivities() async {
    try {
      // Get today's activities from today activities provider
      final dayState = ref.read(todayActivitiesProvider);
      
      if (dayState is! AsyncData) return [];
      
      final activities = dayState.value ?? [];
      final today = DateTime.now();
      
      // Find activities that are scheduled for today and haven't been rated
      final ratingService = ref.read(activityRatingServiceProvider);
      final pendingRatings = <ActivityRating>[];
      
      for (final activity in activities) {
        // Check if activity is for today or in the past
        final activityTime = activity.startTime;
        if (activityTime.day == today.day &&
            activityTime.month == today.month &&
            activityTime.year == today.year) {
          
          final activityId = activity.rawData['id']?.toString() ?? DateTime.now().toString();
          final activityName = activity.rawData['name'] as String? ?? 
                              activity.rawData['title'] as String? ?? 
                              'Activity';
          final location = activity.rawData['location'] as String?;
          
          // Check if already rated
          final existingRating = await ratingService.getRatingForActivity(activityId);
          
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
              completedAt: DateTime.now(),
              mood: _selectedMood ?? 'neutral',
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
          currentMood: _selectedMood ?? 'neutral',
        ),
      );
    }
  }

  Future<void> _loadPreviousCheckIn() async {
    // Load previous check-in to personalize greeting
    final checkInService = CheckInService(Supabase.instance.client);
    final lastCheckIn = await checkInService.getLastCheckIn();
    final yesterdayCheckIn = await checkInService.getYesterdayCheckIn();
    
    final hour = DateTime.now().hour;
    final isMorning = hour < 12;
    
    if (mounted) {
      setState(() {
        if (isMorning && yesterdayCheckIn != null) {
          // Morning greeting referencing yesterday
          if (yesterdayCheckIn.mood == 'tired') {
            _greeting = "Good morning! Did you sleep well? 🌅";
          } else {
            _greeting = "Good morning! How are you feeling today? ☀️";
          }
        } else if (lastCheckIn != null) {
          _greeting = "Hey! How's your day going?";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyState = ref.watch(dailyMoodStateNotifierProvider);
    final currentMood = dailyState.currentMood ?? 'exploring';
    final gradientColors = _getTimeBasedGradient();
    
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                        'Check in with Moody',
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              math.sin(_floatController.value * 2 * math.pi) * 6,
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
                                  const Color(0xFF12B347).withOpacity(0.25),
                                  const Color(0xFF12B347).withOpacity(0.08),
                                  const Color(0xFF12B347).withOpacity(0.0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF12B347).withOpacity(0.3),
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
                              _greeting,
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
                              "Tell me everything! 💚",
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
                              "How are you feeling?",
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
                              children: _quickMoods.map((mood) {
                                final isSelected = _selectedMood == mood['value'];
                                return _buildMoodCard(mood, isSelected);
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 28),
                      
                      // Activity tags (continued on next part due to length...)
                      _buildActivitiesSection(),
                      
                      const SizedBox(height: 28),
                      
                      // Quick reactions
                      _buildReactionsSection(),
                      
                      const SizedBox(height: 28),
                      
                      // Free text input
                      _buildTextInputSection(),
                      
                      const SizedBox(height: 28),
                      
                      // Send button
                      _buildSendButton(),
                      
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

  Widget _buildActivitiesSection() {
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
              "What did you do today?",
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
              children: _activityTags.map((tag) {
                final isSelected = _selectedActivity == tag;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedActivity = isSelected ? null : tag;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF12B347), Color(0xFF6DE89A)],
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
                                color: const Color(0xFF12B347).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF4A5568),
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

  Widget _buildReactionsSection() {
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
              "Quick reactions",
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
              children: _quickReactions.map((reaction) {
                final isSelected = _selectedReactions.contains(reaction['label']);
                final colors = [
                  [const Color(0xFFFF6B9D), const Color(0xFFFFA06B)],
                  [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
                  [const Color(0xFF6366F1), const Color(0xFF818CF8)],
                  [const Color(0xFFEC4899), const Color(0xFFF472B6)],
                  [const Color(0xFF12B347), const Color(0xFF6DE89A)],
                  [const Color(0xFF7B68EE), const Color(0xFF9F7AEA)],
                ];
                final colorIndex = _quickReactions.indexOf(reaction);
                final gradient = colors[colorIndex % colors.length];
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedReactions.remove(reaction['label']);
                      } else {
                        _selectedReactions.add(reaction['label'] as String);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(colors: gradient)
                          : null,
                      color: isSelected ? null : const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
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
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF4A5568),
                          ),
                        ),
                      ],
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

  Widget _buildTextInputSection() {
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
              "Tell me more... (optional)",
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
                  hintText: "What's on your mind? Share anything! 💭",
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

  Widget _buildSendButton() {
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
                  colors: [Color(0xFF12B347), Color(0xFF0E8F38)],
                )
              : null,
          color: canSend ? null : Colors.grey[300],
          borderRadius: BorderRadius.circular(28),
          boxShadow: canSend
              ? [
                  BoxShadow(
                    color: const Color(0xFF12B347).withOpacity(0.4),
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
                      'Send to Moody',
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
