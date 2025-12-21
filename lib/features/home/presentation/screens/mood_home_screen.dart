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
import 'package:wandermood/core/services/wandermood_ai_service.dart';
import 'package:wandermood/core/models/ai_recommendation.dart';
import 'package:flutter/rendering.dart';
import 'package:wandermood/features/mood/providers/mood_options_provider.dart';
import 'package:wandermood/features/mood/models/mood_option.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';
import 'package:wandermood/features/profile/presentation/widgets/profile_drawer.dart';
import 'package:wandermood/features/home/presentation/screens/main_screen.dart';  // Import mainTabProvider from here
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/features/mood/presentation/screens/moody_hub_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

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
  final TextEditingController _chatController = TextEditingController();
  bool _isAILoading = false;
  final List<ChatMessage> _chatMessages = [];
  String? _conversationId;
  String _moodQuestion = "How are you feeling today?";
  String _characterEmoji = "😊";
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Add personalization state
  String _personalizedGreeting = '';
  String _contextualSubtext = '';
  
  @override
  void initState() {
    super.initState();
    _updateGreeting();
    // Removed _updatePersonalizedGreeting() - no auto API calls on init
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
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
    
    // Also update AI-powered elements
    _updateAIGreeting();
  }

  // AI-powered personalized greeting
  void _updateAIGreeting() {
    final hour = DateTime.now().hour;
    final isWeekend = DateTime.now().weekday >= 6;
    
    setState(() {
      // Smart character expressions based on context
      if (hour >= 5 && hour < 12) {
        _characterEmoji = "😊"; // Happy morning
        _moodQuestion = "Ready to start your day?";
      } else if (hour >= 12 && hour < 17) {
        _characterEmoji = "☀️"; // Sunny afternoon  
        _moodQuestion = "What's the afternoon vibe?";
      } else if (hour >= 17 && hour < 21) {
        _characterEmoji = "✨"; // Evening sparkle
        _moodQuestion = isWeekend ? "Weekend plans calling?" : "How do you want to unwind?";
      } else {
        _characterEmoji = "🌙"; // Night owl
        _moodQuestion = "Late night adventures?";
      }
    });
  }

  // Get AI-powered greeting based on weather and context
  Future<void> _getAIPersonalizedGreeting() async {
    try {
      // This could call Moody AI to get a personalized greeting question for the user based on current time and weather
      final response = await WanderMoodAIService.chat(
        message: "Generate a short personalized greeting question for the user based on current time and weather",
        conversationId: null, // No conversation yet
        moods: [],
        latitude: 51.9244,
        longitude: 4.4777, 
        city: 'Rotterdam',
      );

      if (mounted && response.message.isNotEmpty && response.message.length < 50) {
        setState(() {
          _moodQuestion = response.message;
        });
      }
    } catch (e) {
      print('🤖 Could not get AI greeting: $e');
      // Keep default greeting
    }
  }



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
      print('🎯 Generating plan for moods: $_selectedMoods');
      
      // 🎯 Save mood selection state for hub
      ref.read(dailyMoodStateNotifierProvider.notifier).setMoodSelection(
        mood: _selectedMoods.first,
        selectedMoods: _selectedMoods.toList(),
        conversationId: _conversationId,
      );
      
      // Navigate to PlanLoadingScreen first
      if (context.mounted) {
        print('🧭 Navigating to plan loading screen');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanLoadingScreen(
              selectedMoods: _selectedMoods.toList(),
              onLoadingComplete: () {
                print('✅ Plan loading complete, navigating to result screen');
                Navigator.pushReplacement(
                  context,
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
  }

  // Get AI recommendations for selected moods
  Future<void> _getAIRecommendations() async {
    setState(() {
      _isAILoading = true;
    });

    try {
      print('🤖 Getting AI recommendations for moods: ${_selectedMoods.toList()}');
      
      // Extract conversation context from chat messages
      List<String> conversationContext = [];
      if (_chatMessages.isNotEmpty) {
        conversationContext = _chatMessages
            .map((msg) => '${msg.isUser ? "User" : "Moody"}: ${msg.message}')
            .toList();
        print('📝 Including ${conversationContext.length} conversation messages');
      }
      
      final response = await WanderMoodAIService.getRecommendations(
        moods: _selectedMoods.toList(),
        latitude: 51.9244, // Rotterdam coordinates (you can get this from location provider)
        longitude: 4.4777,
        city: 'Rotterdam',
        preferences: {
          'timeSlot': _getTimeSlot(),
          'groupSize': 1,
        },
        conversationId: _conversationId,
        conversationContext: conversationContext,
      );

      print('✅ Got ${response.recommendations.length} AI recommendations (${conversationContext.isNotEmpty ? "with conversation context" : "without context"})');

      // Navigate to PlanLoadingScreen first
      if (mounted) {
        print('🧭 Navigating to plan loading screen');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanLoadingScreen(
              selectedMoods: _selectedMoods.toList(),
              onLoadingComplete: () {
                print('✅ Plan loading complete, navigating to result screen');
                Navigator.pushReplacement(
                  context,
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
    } catch (e) {
      print('❌ Error getting AI recommendations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAILoading = false;
        });
      }
    }
  }

  // Helper to get current time slot
  String _getTimeSlot() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  // Suggest moods based on chat conversation
  void _suggestMoodsFromChat() {
    final chatText = _chatMessages
        .where((msg) => msg.isUser)
        .map((msg) => msg.message.toLowerCase())
        .join(' ');

    // Enhanced keyword-based mood detection
    final suggestedMoods = <String>[];
    
    if (chatText.contains(RegExp(r'\b(food|eat|hungry|restaurant|dinner|lunch|asian|cuisine|tasty|sushi)\b'))) {
      suggestedMoods.add('Foody');
    }
    if (chatText.contains(RegExp(r'\b(romantic|date|love|couple|intimate)\b'))) {
      suggestedMoods.add('Romantic');
    }
    if (chatText.contains(RegExp(r'\b(adventure|explore|active|exciting|outdoor)\b'))) {
      suggestedMoods.add('Adventure');
    }
    if (chatText.contains(RegExp(r'\b(chill|relax|calm|peaceful|tired|nothing much)\b'))) {
      suggestedMoods.add('Relaxed');
    }
    if (chatText.contains(RegExp(r'\b(energy|energetic|party|parties|dance|active|lively|bar|club|going out)\b'))) {
      suggestedMoods.add('Energetic');
    }
    if (chatText.contains(RegExp(r'\b(surprise|different|new|unique|creative)\b'))) {
      suggestedMoods.add('Surprise');
    }

    print('🎯 Chat analysis: "$chatText"');
    print('🎭 Suggested moods: $suggestedMoods');

    // Auto-select suggested moods
    setState(() {
      _selectedMoods.clear();
      _selectedMoods.addAll(suggestedMoods.take(3)); // Max 3 moods
    });
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
      backgroundColor: const Color(0xFFFAFCFA),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.25, // Reduced height to fix overflow
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
              onTap: () async {
                // Close the dialog
                Navigator.pop(context);
                // Show loading message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Getting your location...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                // Trigger location update
                final location = await ref.read(locationNotifierProvider.notifier).getCurrentLocation();
                // Show result message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Location: ${location ?? "Could not get location"}'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  // Show dialog for talking to Moody
  void _showMoodyTalkDialog(BuildContext context) {
    // Create conversation ID only if it doesn't exist (persistent conversation)
    if (_conversationId == null) {
      _conversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFAFCFA), // Very light mint white
                        Color(0xFFF8FAF9), // Soft green-tinted white
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Enhanced header with friendly aesthetics
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF12B347).withOpacity(0.03),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Handle bar
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Header content - Modernized
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  // Enhanced Moody avatar with modern styling
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF12B347), Color(0xFF0EA33F)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF12B347).withOpacity(0.25),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: MoodyCharacter(size: 32),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Title and personalized status
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Moody',
                                          style: GoogleFonts.poppins(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1A202C),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF10B149),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                'Your Rotterdam travel companion',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: const Color(0xFF4A5568),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Enhanced close button
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Chat messages area
                      Expanded(
                        child: _chatMessages.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  const Spacer(),
                                  
                                  // Large enhanced Moody character with modern styling
                                  Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF12B347).withOpacity(0.08),
                                          const Color(0xFF12B347).withOpacity(0.03),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: const Color(0xFF12B347).withOpacity(0.15),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF12B347).withOpacity(0.1),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: MoodyCharacter(size: 70),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Personalized greeting
                                  Text(
                                    _personalizedGreeting,
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A202C),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Contextual subtext
                                  Text(
                                    _contextualSubtext,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF4A5568),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Modern description
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFF12B347).withOpacity(0.1),
                                      ),
                                    ),
                                    child: Text(
                                      'I know Rotterdam like the back of my hand! Tell me your mood, and I\'ll craft the perfect day just for you. Whether you\'re feeling adventurous, romantic, or need some chill vibes - I\'ve got you covered! 🎯',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: const Color(0xFF2D3748),
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  
                                  const Spacer(),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    controller: scrollController,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    itemCount: _chatMessages.length,
                                    itemBuilder: (context, index) {
                                      final message = _chatMessages[index];
                                      return _buildMessageBubble(message);
                                    },
                                  ),
                                ),
                                
                                // Enhanced typing indicator with personality
                                if (_isAILoading) 
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF12B347), Color(0xFF0EA33F)],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF12B347).withOpacity(0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: MoodyCharacter(size: 22),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0F9F0),
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),
                                              bottomRight: Radius.circular(20),
                                              bottomLeft: Radius.circular(4),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF12B347).withOpacity(0.08),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    const Color(0xFF12B347).withOpacity(0.7),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Moody is crafting something special...',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  color: const Color(0xFF2D3748),
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                      ),
                      
                      // Quick action button if conversation has started - Enhanced
                      if (_chatMessages.isNotEmpty) 
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF12B347).withOpacity(0.05),
                                  const Color(0xFF12B347).withOpacity(0.02),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF12B347).withOpacity(0.2),
                              ),
                            ),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context); // Close chat
                                _suggestMoodsFromChat(); // Auto-suggest moods from conversation
                                
                                // Small delay to let mood selection UI update, then generate plan
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  _generatePlan(); // Automatically start plan generation
                                });
                              },
                              icon: const Icon(Icons.auto_awesome, size: 20),
                              label: Text(
                                '✨ Create My Perfect Plan',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF12B347),
                                backgroundColor: Colors.transparent,
                                side: BorderSide.none,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Enhanced input area with modern styling
                      Container(
                        padding: EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 24,
                          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey[100]!),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 20,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: const Color(0xFF12B347).withOpacity(0.15),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF12B347).withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _chatController,
                                    decoration: InputDecoration(
                                      hintText: 'What\'s your mood today?',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.grey[500],
                                        fontSize: 16,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 18,
                                      ),
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.psychology_outlined,
                                          color: const Color(0xFF12B347).withOpacity(0.6),
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: const Color(0xFF1A202C),
                                    ),
                                    onSubmitted: (text) => _sendChatMessageInModal(text, setModalState),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Enhanced send button with modern styling
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF12B347), Color(0xFF0EA33F)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF12B347).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(26),
                                    onTap: _isAILoading 
                                      ? null 
                                      : () => _sendChatMessageInModal(_chatController.text, setModalState),
                                    child: Center(
                                      child: _isAILoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.send_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Build message bubble widget with modern iMessage-like style
  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Row(
        mainAxisAlignment: message.isUser 
          ? MainAxisAlignment.end 
          : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            // Moody's Avatar with enhanced modern styling
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF12B347), Color(0xFF0EA33F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF12B347).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: MoodyCharacter(size: 20),
              ),
            ),
            const SizedBox(width: 10),
          ],
          
          // Message bubble with modern styling
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser 
                ? CrossAxisAlignment.end 
                : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                    minWidth: 80,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: message.isUser
                      ? const LinearGradient(
                          colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFE8F5E8), Color(0xFFF5FBF5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: message.isUser 
                        ? const Radius.circular(20) 
                        : const Radius.circular(4),
                      bottomRight: message.isUser 
                        ? const Radius.circular(4) 
                        : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: message.isUser 
                          ? Colors.blue.withOpacity(0.12)
                          : const Color(0xFF12B347).withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: message.isUser 
                        ? Colors.white 
                        : const Color(0xFF1A202C),
                    ),
                  ),
                ),
                
                // Timestamp with modern styling
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 6, right: 6),
                  child: Text(
                    _formatMessageTime(message.timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 10),
            // User's Profile Picture with modern styling
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'U',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to format message timestamp (iMessage style)
  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  // Send chat message to Moody AI (for modal)
  Future<void> _sendChatMessageInModal(String message, StateSetter setModalState) async {
    if (message.trim().isEmpty || _isAILoading) return;

    print('🚀 Starting chat message process: "${message.trim()}"');

    // Add user message to chat
    setModalState(() {
      _chatMessages.add(ChatMessage(
        message: message.trim(),
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isAILoading = true;
    });

    print('✅ User message added to chat, loading state set to true');

    // Clear the input immediately
    _chatController.clear();

    try {
      print('💬 Sending message to Moody AI: $message');
      print('🔧 Conversation ID: $_conversationId');
      print('🎭 Selected moods: ${_selectedMoods.toList()}');
      
      final response = await WanderMoodAIService.chat(
        message: message.trim(),
        conversationId: _conversationId,
        moods: _selectedMoods.toList(),
        latitude: 51.9244,
        longitude: 4.4777,
        city: 'Rotterdam',
      );

      print('✅ Moody AI response received successfully');
      print('📝 Response message: "${response.message}"');
      print('🆔 Response conversation ID: ${response.conversationId}');

      // Validate response
      if (response.message.isEmpty) {
        throw Exception('Empty response message from AI service');
      }

      // Add AI response to chat
      setModalState(() {
        _chatMessages.add(ChatMessage(
          message: response.message,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isAILoading = false;
      });

      print('✅ AI response added to chat successfully');
      print('📊 Total messages in chat: ${_chatMessages.length}');

    } catch (e, stackTrace) {
      print('❌ Chat error occurred: $e');
      print('📋 Stack trace: $stackTrace');
      
      // Add error message to chat
      setModalState(() {
        _chatMessages.add(ChatMessage(
          message: 'Oops! I\'m having trouble connecting right now. Can you try again? 🤔',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isAILoading = false;
      });

      print('⚠️ Error message added to chat');
    }

    print('🏁 Chat message process completed');
  }

  // Send chat message to Moody AI
  Future<void> _sendChatMessage(String message) async {
    if (message.trim().isEmpty || _isAILoading) return;

    // Add user message to chat
    setState(() {
      _chatMessages.add(ChatMessage(
        message: message.trim(),
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isAILoading = true;
    });

    // Clear the input immediately
    _chatController.clear();

    try {
      print('💬 Sending message to Moody AI: $message');
      
      final response = await WanderMoodAIService.chat(
        message: message.trim(),
        conversationId: _conversationId,
        moods: _selectedMoods.toList(),
        latitude: 51.9244,
        longitude: 4.4777,
        city: 'Rotterdam',
      );

      print('✅ Moody AI response: ${response.message}');

      // Add AI response to chat
      if (mounted) {
        setState(() {
          _chatMessages.add(ChatMessage(
            message: response.message,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      print('❌ Chat error: $e');
      
      // Add error message to chat
      if (mounted) {
        setState(() {
          _chatMessages.add(ChatMessage(
            message: 'Sorry, I couldn\'t respond right now. Try again! 😅',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAILoading = false;
        });
      }
    }
  }
  
  // Add method to hide the conversation
  void _hideMoodyConversation() {
    setState(() {
      _showMoodyConversation = false;
    });
  }

  // Add personalized greeting method
  void _updatePersonalizedGreeting() {
    final hour = DateTime.now().hour;
    final isWeekend = DateTime.now().weekday >= 6;
    final dayOfWeek = DateTime.now().weekday;
    
    setState(() {
      // Contextual greetings based on time and day
      if (hour >= 5 && hour < 10) {
        _personalizedGreeting = "Rise and shine! ☀️";
        _contextualSubtext = isWeekend 
          ? "Perfect weekend morning for adventures"
          : "Ready to make today amazing?";
      } else if (hour >= 10 && hour < 14) {
        _personalizedGreeting = "Hey there! 👋";
        _contextualSubtext = "I've been thinking about your perfect day";
      } else if (hour >= 14 && hour < 18) {
        _personalizedGreeting = "Afternoon vibes! ✨";
        _contextualSubtext = "What's on your mind for today?";
      } else if (hour >= 18 && hour < 22) {
        _personalizedGreeting = "Evening explorer! 🌆";
        _contextualSubtext = isWeekend 
          ? "Weekend nights are the best for discoveries"
          : "How did your day treat you?";
      } else {
        _personalizedGreeting = "Night owl! 🌙";
        _contextualSubtext = "Late night adventures calling?";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationNotifierProvider);
    final userData = ref.watch(userDataProvider);
    final weatherAsync = ref.watch(weatherProvider);
    final dailyMoodState = ref.watch(dailyMoodStateNotifierProvider);
    
    // 🎯 Hub Logic: 
    // 1. First check if user has seen intro overlay - if not, show hub with intro
    // 2. Then check if user has selected mood today - if yes, show hub
    // 3. Otherwise show mood selection screen
    return FutureBuilder<bool>(
      future: _hasSeenIntroOverlay(),
      builder: (context, introSnapshot) {
        final hasSeenIntro = introSnapshot.data ?? false;
        
        // If user hasn't seen intro overlay, always show hub (which will show intro)
        if (!hasSeenIntro) {
          return MoodyHubScreen(
            onChangeMood: () {
              // Reset mood selection and show full mood selection screen
              ref.read(dailyMoodStateNotifierProvider.notifier).resetMoodSelection();
            },
            onShowChat: () {
              // Show existing chat dialog with current context
              _showMoodyTalkDialog(context);
            },
          );
        }
        
        // If user has seen intro, check if they've selected mood today
        if (dailyMoodState.hasSelectedMoodToday) {
          return MoodyHubScreen(
            onChangeMood: () {
              // Reset mood selection and show full mood selection screen
              ref.read(dailyMoodStateNotifierProvider.notifier).resetMoodSelection();
            },
            onShowChat: () {
              // Show existing chat dialog with current context
              _showMoodyTalkDialog(context);
            },
          );
        }
        
        // User has seen intro but hasn't selected mood - show mood selection with "Back to Hub" button
        return _buildMoodSelectionScreen(context, ref, locationAsync, userData, weatherAsync, dailyMoodState);
      },
    );
  }
  
  /// Check if user has seen the Moody intro overlay
  Future<bool> _hasSeenIntroOverlay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('has_seen_moody_intro') ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error checking intro overlay status: $e');
      }
      return false; // Default to showing intro if check fails
    }
  }
  
  /// Build the mood selection screen (moved from build method)
  Widget _buildMoodSelectionScreen(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<String?> locationAsync,
    AsyncValue<Map<String, dynamic>?> userData,
    AsyncValue<WeatherData?> weatherAsync,
    DailyMoodState dailyMoodState,
  ) {
    
    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          drawer: const ProfileDrawer(),
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
                    // Profile button with drawer
                    GestureDetector(
                      onTap: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF12B347),
                          width: 2,
                        ),
                      ),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final profileData = ref.watch(profileProvider);
                            return profileData.when(
                              data: (profile) => CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.transparent,
                                backgroundImage: profile?.imageUrl != null
                                    ? NetworkImage(profile!.imageUrl!)
                                    : null,
                                child: profile?.imageUrl == null
                                    ? Text(
                                        profile?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          color: const Color(0xFF12B347),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : null,
                              ),
                              loading: () => const CircularProgressIndicator(
                                color: Color(0xFF12B347),
                                strokeWidth: 2,
                              ),
                              error: (_, __) => Text(
                          'U',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            color: const Color(0xFF12B347),
                            fontWeight: FontWeight.w600,
                          ),
                              ),
                            );
                          },
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
                              Consumer(
                                builder: (context, ref, child) {
                                  final locationAsync = ref.watch(locationNotifierProvider);
                                  return locationAsync.when(
                                    data: (location) => Text(
                                      location ?? 'Getting location...',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    loading: () => Text(
                                      'Getting location...',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    error: (_, __) => Text(
                                      'Location unavailable',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
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
              
              // Greeting Header - Made smaller
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    userData.when(
                                data: (data) {
                                  String firstName = '';
                                  if (data != null && data.containsKey('name') && data['name'] != null) {
                          firstName = data['name'].toString().split(' ')[0];
                                  } else {
                                    firstName = 'explorer';
                                  }
                        return Text(
                                      "$_timeGreeting $firstName $_timeEmoji",
                                      style: GoogleFonts.poppins(
                            fontSize: 24, // Reduced from ~28
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                    ),
                                  );
                                },
                      loading: () => Text(
                                    "$_timeGreeting explorer $_timeEmoji",
                                    style: GoogleFonts.poppins(
                          fontSize: 24, // Reduced from ~28
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                      error: (_, __) => Text(
                                    "$_timeGreeting explorer $_timeEmoji",
                                    style: GoogleFonts.poppins(
                          fontSize: 24, // Reduced from ~28
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                  ],
                              ),
              ),

                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                  _moodQuestion, // AI-powered dynamic greeting instead of hardcoded text
                        style: GoogleFonts.poppins(
                    fontSize: 18, // Reduced from 22
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              // Original Moody Character - Not emoji
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

                      // Grid of mood tiles - Dynamic from database with fallback
                      Consumer(
                        builder: (context, ref, _) {
                          final moodOptionsAsync = ref.watch(moodOptionsProvider);
                          
                          return moodOptionsAsync.when(
                            data: (moodOptions) {
                              // Use database mood options if available, otherwise use fallback
                              final finalMoodOptions = moodOptions.isNotEmpty ? moodOptions : _getFallbackMoodOptions();
                              
                              if (finalMoodOptions.isEmpty) {
                                return Container(
                                  height: 200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.mood,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No mood options available',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              
                              return GridView.count(
                                crossAxisCount: 4,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.0,
                                children: finalMoodOptions.map((mood) {
                                  final isSelected = _selectedMoods.contains(mood.label);
                                  return GestureDetector(
                                    onTap: () => _toggleMood(mood),
                                    child: Container(
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
                                                  width: 70,
                                                  child: Text(
                                                    mood.label,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w400,
                                                      color: Colors.black87,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
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
                              );
                            },
                            loading: () => _buildFallbackMoodGrid(), // Show fallback while loading
                            error: (error, stack) => _buildFallbackMoodGrid(), // Show fallback on error
                          );
                        },
                      ),
                      
                      // CTA Button directly below grid in the same scroll view
                      Container(
                        width: double.infinity,
                        height: 56,
                        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 8),
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
                          onPressed: _selectedMoods.isEmpty || _isAILoading ? null : _generatePlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedMoods.isEmpty || _isAILoading
                                ? const Color(0xFFD0D0D0) // Light gray for inactive/loading state
                                : const Color(0xFF12B347), // Green for active state
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 0,
                          ),
                          child: _isAILoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "🤖 Moody is thinking...",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                            "Let's create your perfect plan! 🎯",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      
                      // Back to Hub button - always show when on mood selection screen
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 30),
                        child: TextButton(
                          onPressed: () {
                            // Always show hub when "Back to Hub" is clicked
                            // If in mood change mode, use returnToHub (preserves activities)
                            if (dailyMoodState.isInMoodChangeMode) {
                              ref.read(dailyMoodStateNotifierProvider.notifier).returnToHub();
                            } else {
                              // If not in mood change mode (first-time user), just show hub
                              // Enter mood change mode temporarily, then return to hub
                              // This ensures the hub is shown even without a mood selection
                              ref.read(dailyMoodStateNotifierProvider.notifier).enterMoodChangeMode();
                              Future.delayed(const Duration(milliseconds: 50), () {
                                if (mounted) {
                                  ref.read(dailyMoodStateNotifierProvider.notifier).returnToHub();
                                }
                              });
                            }
                          },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black54,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              minimumSize: const Size(double.infinity, 44),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.home_rounded,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Back to Hub',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
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

  // Fallback mood options when database fails
  List<MoodOption> _getFallbackMoodOptions() {
    return [
      MoodOption(
        id: 'happy',
        label: 'Happy',
        emoji: '😊',
        colorHex: '#FFD700',
        displayOrder: 1,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MoodOption(
        id: 'adventurous',
        label: 'Adventurous',
        emoji: '🚀',
        colorHex: '#FF6B6B',
        displayOrder: 2,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MoodOption(
        id: 'relaxed',
        label: 'Relaxed',
        emoji: '😌',
        colorHex: '#4ECDC4',
        displayOrder: 3,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MoodOption(
        id: 'energetic',
        label: 'Energetic',
        emoji: '⚡',
        colorHex: '#45B7D1',
        displayOrder: 4,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MoodOption(
        id: 'romantic',
        label: 'Romantic',
        emoji: '💕',
        colorHex: '#FD79A8',
        displayOrder: 5,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MoodOption(
        id: 'social',
        label: 'Social',
        emoji: '👥',
        colorHex: '#FFEAA7',
        displayOrder: 6,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MoodOption(
        id: 'cultural',
        label: 'Cultural',
        emoji: '🎭',
        colorHex: '#A29BFE',
        displayOrder: 7,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MoodOption(
        id: 'curious',
        label: 'Curious',
        emoji: '🔍',
        colorHex: '#FF7675',
        displayOrder: 8,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MoodOption(
        id: 'cozy',
        label: 'Cozy',
        emoji: '☕',
        colorHex: '#D63031',
        displayOrder: 9,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MoodOption(
        id: 'excited',
        label: 'Excited',
        emoji: '🤩',
        colorHex: '#00B894',
        displayOrder: 10,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MoodOption(
        id: 'foody',
        label: 'Foody',
        emoji: '🍽️',
        colorHex: '#E17055',
        displayOrder: 11,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MoodOption(
        id: 'surprise',
        label: 'Surprise',
        emoji: '😲',
        colorHex: '#FDCB6E',
        displayOrder: 12,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  // Build fallback mood grid widget
  Widget _buildFallbackMoodGrid() {
    final fallbackMoodOptions = _getFallbackMoodOptions();
    
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: fallbackMoodOptions.map((mood) {
        final isSelected = _selectedMoods.contains(mood.label);
        return GestureDetector(
          onTap: () => _toggleMood(mood),
          child: Container(
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
                        width: 70,
                        child: Text(
                          mood.label,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
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



class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.message,
    required this.isUser,
    required this.timestamp,
  });
} 