import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import '../../providers/daily_mood_state_provider.dart';
import '../../providers/mood_options_provider.dart';
import '../../models/mood_option.dart';
import '../../../home/presentation/screens/dynamic_my_day_provider.dart';
import '../../../places/models/place.dart';
import '../../../../core/services/wandermood_ai_service.dart';
import '../../services/trending_activities_service.dart';
import '../../models/trending_activity.dart';
import 'trending_detail_screen.dart';
import 'check_in_screen.dart';
import '../../services/check_in_service.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/domain/providers/location_notifier_provider.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../places/providers/moody_explore_provider.dart';
import '../../services/moody_hub_content_service.dart';
import '../widgets/mood_based_carousel.dart';
import '../widgets/enhanced_mood_carousel.dart';
import '../widgets/simplified_mood_carousel.dart';
import '../widgets/period_activities_bottom_sheet.dart';
import '../widgets/moody_intro_overlay.dart';
import '../../../places/presentation/screens/saved_places_screen.dart';
import '../../../places/services/saved_places_service.dart';
import '../../../plans/data/services/scheduled_activity_service.dart';
import '../../../plans/domain/models/activity.dart';
import '../../../plans/domain/enums/time_slot.dart';
import '../../../plans/domain/enums/payment_type.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../home/presentation/screens/main_screen.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';
import '../../../../core/presentation/widgets/wm_toast.dart';
import '../../../profile/domain/providers/profile_provider.dart';
import 'dart:ui';

// Day hero state for Moody Hub hero card (My Day)
enum _DayHeroState {
  noPlan,
  planScheduledLater,
  upcomingSoon,
  activeNow,
  recentlyCompleted,
}

// Lightweight context object describing what the hero should focus on
class _HeroStateContext {
  final _DayHeroState state;
  final EnhancedActivityData? focusActivity;

  const _HeroStateContext(this.state, this.focusActivity);
}

class MoodyHubScreen extends ConsumerStatefulWidget {
  final VoidCallback? onChangeMood;
  final VoidCallback? onShowChat;

  const MoodyHubScreen({
    super.key,
    this.onChangeMood,
    this.onShowChat,
  });

  @override
  ConsumerState<MoodyHubScreen> createState() => _MoodyHubScreenState();
}

class _MoodyHubScreenState extends ConsumerState<MoodyHubScreen>
    with TickerProviderStateMixin {
  AnimationController? _fadeController;
  AnimationController? _slideController;
  AnimationController? _floatController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _floatAnimation;

  bool _isLoadingTrending = false;
  
  // Chat state
  final List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  bool _isAILoading = false;
  String? _conversationId;
  TrendingActivity? _contextualActivity; // For contextual chat from suggestion cards
  final ScrollController _chatScrollController = ScrollController();
  bool _isChatExpanded = false; // Track if chat is expanded to full screen
  bool _hasShownInitialGreeting = false; // Track if initial greeting was shown (no API call)
  bool _isSendingMessage = false; // Prevent duplicate sends
  bool _showIntroOverlay = false; // Track if intro overlay should be shown

  @override
  void initState() {
    super.initState();
    // Initialize controllers first
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    // Then setup animations
    _setupAnimations();
    
    // Load or create persistent conversation ID
    _loadConversationId();
    
    // Increment visit count for content rotation
    _incrementVisitCount();
    
    // Check if user has seen Moody intro
    _checkIntroOverlay();
  }
  
  /// Check if intro overlay should be shown
  Future<void> _checkIntroOverlay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenIntro = prefs.getBool('has_seen_moody_intro') ?? false;
      
      // Only show if user hasn't seen it and is a first-time user
      if (!hasSeenIntro) {
        final isFirstTime = await _isFirstTimeUser();
        if (mounted) {
          setState(() {
            _showIntroOverlay = isFirstTime;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error checking intro overlay: $e');
      }
    }
  }
  
  /// Dismiss intro overlay and mark as seen
  /// This reveals the full Moody Hub content (including nav bar from MainScreen)
  /// When user clicks "Skip for now", this unlocks the entire app
  Future<void> _dismissIntroOverlay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_moody_intro', true);
      
      // Invalidate the provider to force MainScreen to refresh and show bottom nav
      ref.invalidate(hasSeenIntroProvider);
      
      if (mounted) {
        setState(() {
          _showIntroOverlay = false;
        });
        
        // Force MainScreen to refresh and show bottom nav
        // The MainScreen watches hasSeenIntroProvider which will update immediately
        // This ensures the bottom nav appears immediately when user skips
        if (kDebugMode) {
          debugPrint('✅ Intro overlay dismissed - app unlocked');
          debugPrint('✅ Provider invalidated - bottom navigation should now be visible');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error dismissing intro overlay: $e');
      }
    }
  }
  
  /// Handle create day action from overlay
  Future<void> _handleCreateDayFromOverlay() async {
    // Dismiss overlay first
    await _dismissIntroOverlay();
    
    // Add 1 second delay before showing mood selection screen
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
    // Navigate to mood selection to start creating first plan
    widget.onChangeMood?.call();
    }
  }

  /// Load or create a persistent conversation ID
  Future<void> _loadConversationId() async {
    try {
      final convId = await WanderMoodAIService.getOrCreateConversationId();
      if (mounted) {
        setState(() {
          _conversationId = convId;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error loading conversation ID: $e');
      }
      // Fallback to generating a new one
      if (mounted) {
        setState(() {
          _conversationId = MoodyClock.now().millisecondsSinceEpoch.toString();
        });
      }
    }
  }
  
  Future<void> _incrementVisitCount() async {
    final contentService = ref.read(moodyHubContentServiceProvider);
    await contentService.incrementVisitCount();
  }

  // Show chat bottom sheet
  void _showChatBottomSheet(BuildContext context, {
    TrendingActivity? contextualActivity,
    String? contextualGreeting,
    bool autoRespond = false, // Auto-respond from Moody when opening
  }) {
    _contextualActivity = contextualActivity;
    
    // Only clear messages if this is a fresh chat session
    // If chat was already open, keep existing messages
    if (!_hasShownInitialGreeting) {
      _chatMessages.clear();
    }

    // Show initial greeting ONLY on first open (no API call)
    if (!_hasShownInitialGreeting) {
      if (contextualGreeting != null) {
        // User provided greeting - add as user message but DON'T auto-send
        _chatMessages.add({
          'role': 'user',
          'content': contextualGreeting,
          'timestamp': MoodyClock.now(),
        });
        // Don't auto-trigger API - wait for user to send
      } else if (contextualActivity != null) {
        // Show contextual greeting (static, no API call)
        _chatMessages.add({
          'role': 'assistant',
          'content': _getContextualGreeting(contextualActivity),
          'timestamp': MoodyClock.now(),
          'quickReplies': _getContextualQuickReplies(contextualActivity),
        });
      } else {
        // Show default greeting (static, no API call)
        _chatMessages.add({
          'role': 'assistant',
          'content': _getMoodyGreeting(),
          'timestamp': MoodyClock.now(),
          'quickReplies': _getDefaultQuickReplies(),
        });
      }
      _hasShownInitialGreeting = true;
    }

    // If autoRespond is true, add a greeting from Moody and trigger response
    if (autoRespond && _chatMessages.isEmpty) {
      _chatMessages.add({
        'role': 'assistant',
        'content': _getMoodyGreeting(),
        'timestamp': MoodyClock.now(),
        'quickReplies': _getDefaultQuickReplies(),
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => _buildChatBottomSheet(context),
    );
  }

  String _getMoodyGreeting() {
    final dailyState = ref.read(dailyMoodStateNotifierProvider);
    final currentMood = dailyState.currentMood ?? 'exploring';
    final moodEmoji = _getMoodEmoji(currentMood);

    return "Heyyy 👋\n\nYou're on a ${currentMood.capitalize()} wave today $moodEmoji\n\nWant to ride it or switch things up?";
  }

  String _getContextualGreeting(TrendingActivity activity) {
    final dailyState = ref.read(dailyMoodStateNotifierProvider);
    final currentMood = dailyState.currentMood ?? 'exploring';
    final moodEmoji = _getMoodEmoji(currentMood);

    return "This ${activity.title.toLowerCase()} fits your ${currentMood.capitalize()} + ${activity.moodTag.isNotEmpty ? activity.moodTag : 'Social'} mood perfectly $moodEmoji✨\n\nWanna add it to today, or just explore it?";
  }

  List<Map<String, String>> _getDefaultQuickReplies() {
    final dailyState = ref.read(dailyMoodStateNotifierProvider);
    final currentMood = dailyState.currentMood ?? 'exploring';

    return [
      {'emoji': _getMoodEmoji(currentMood), 'text': 'Keep ${currentMood.capitalize()}'},
      {'emoji': '⚡', 'text': 'Boost energy'},
      {'emoji': '🧘', 'text': 'Slow it down'},
      {'emoji': '💬', 'text': 'Tell you more'},
    ];
  }

  List<Map<String, String>> _getContextualQuickReplies(TrendingActivity activity) {
    return [
      {'emoji': '➕', 'text': 'Add to My Day'},
      {'emoji': '👀', 'text': 'View details'},
      {'emoji': '🔄', 'text': 'Show me something else'},
      {'emoji': '💬', 'text': 'Why this?'},
    ];
  }

  Widget _buildChatBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85, // Increased from 0.7 for better visibility
      minChildSize: 0.5,
      maxChildSize: 0.98, // Increased from 0.95 to handle keyboard better
      builder: (context, scrollController) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEDF5F9),
                Color(0xFFEDF5F9),
                Color(0xFFF5F0E8),
              ],
              stops: [0.0, 0.38, 0.38],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom, // Handle keyboard
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D0C4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Modern header with Moody character
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFA8C8DC).withOpacity(0.22),
                      const Color(0xFFA8C8DC).withOpacity(0.08),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Row(
                  children: [
                    // Animated Moody character
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFA8C8DC),
                            Color(0xFFA8C8DC),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFA8C8DC).withOpacity(0.45),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: MoodyCharacter(
                          size: 42,
                          mood: ref.watch(dailyMoodStateNotifierProvider).currentMood ?? 'exploring',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat with Moody',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A202C),
                            ),
                          ),
                          const SizedBox(height: 2),
                            Text(
                            _contextualActivity != null 
                                ? 'About ${_contextualActivity!.title}'
                                : 'Your travel companion 🌟',
                              style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF2A6049),
                              fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
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
                        icon: const Icon(Icons.close, color: Color(0xFF4A5568)),
                      onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
              if (_contextualActivity != null && _chatMessages.isNotEmpty)
                _buildContextualCard(_contextualActivity!),
              Expanded(
                child: ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _chatMessages.length + (_isAILoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _chatMessages.length && _isAILoading) {
                      return _buildLoadingMessage();
                    }
                    return _buildChatMessage(_chatMessages[index]);
                  },
                ),
              ),
              if (_chatMessages.isNotEmpty && _chatMessages.last['quickReplies'] != null)
                _buildQuickReplies(
                  List<Map<String, String>>.from(_chatMessages.last['quickReplies'] as List<dynamic>),
                  setModalState,
                ),
              // Modern input field
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFC),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                      child: TextField(
                        controller: _chatController,
                        decoration: InputDecoration(
                            hintText: 'Message Moody...',
                          hintStyle: GoogleFonts.poppins(
                              color: const Color(0xFF94A3B8),
                              fontSize: 15,
                            ),
                            prefixIcon: const Icon(
                              Icons.chat_bubble_outline,
                              color: Color(0xFF2A6049),
                              size: 22,
                            ),
                            filled: false,
                            border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: const Color(0xFF1A202C),
                          ),
                          maxLines: 4,
                          minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (text) => _sendMessage(text, setModalState),
                      ),
                    ),
                    ),
                    const SizedBox(width: 12),
                    // Gradient send button
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2A6049),
                            Color(0xFF2A6049),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2A6049).withOpacity(0.35),
                            blurRadius: 16,
                            spreadRadius: 0,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                        onPressed: () => _sendMessage(_chatController.text, setModalState),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextualCard(TrendingActivity activity) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          if (activity.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                activity.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: Center(
                    child: Text(activity.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(activity.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A202C),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Suggested by Moody',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5EE),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('💬', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A6049)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // Moody's avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFA8C8DC),
                    Color(0xFFA8C8DC),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA8C8DC).withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
              ),
                ],
              ),
              child: Center(
                child: MoodyCharacter(
                  size: 26,
                  mood: ref.watch(dailyMoodStateNotifierProvider).currentMood ?? 'exploring',
            ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: isUser 
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2A6049),
                          Color(0xFF2A6049),
                        ],
                      )
                    : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 20 : 8),
                  topRight: Radius.circular(isUser ? 8 : 20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser 
                        ? const Color(0xFF2A6049).withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                  if (!isUser)
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 8,
                      spreadRadius: -4,
                      offset: const Offset(0, -2),
                    ),
                ],
              ),
              child: Text(
                message['content'] as String? ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: isUser ? Colors.white : const Color(0xFF1A202C),
                  height: 1.5,
                  fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            // User avatar with profile picture
            Consumer(
              builder: (context, ref, child) {
                final profileAsync = ref.watch(profileProvider);
                return profileAsync.when(
                  data: (profile) {
                    final imageUrl = profile?.imageUrl;
                    if (imageUrl != null && imageUrl.isNotEmpty) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          imageUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildDefaultUserAvatar(),
                        ),
                      );
                    }
                    return _buildDefaultUserAvatar();
                  },
                  loading: () => _buildDefaultUserAvatar(),
                  error: (_, __) => _buildDefaultUserAvatar(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultUserAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade400,
            Colors.purple.shade400,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.person, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _buildQuickReplies(List<Map<String, String>> quickReplies, StateSetter setModalState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.8),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick replies ✨',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: quickReplies.asMap().entries.map((entry) {
              final index = entry.key;
              final reply = entry.value;
              final colorPair = [const Color(0xFF2A6049), const Color(0xFF2A6049)];
              
          return GestureDetector(
            onTap: () => _handleQuickReply(reply['text']!, setModalState),
            child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colorPair,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorPair[0].withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (reply['emoji'] != null) ...[
                    Text(reply['emoji']!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                  ],
                  Text(
                    reply['text'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
    );
  }

  Future<void> _sendMessage(String message, [StateSetter? setModalState]) async {
    // Prevent duplicate sends and empty messages
    if (message.trim().isEmpty || _isAILoading || _isSendingMessage) return;
    
    // Set sending flag to prevent duplicate calls
    _isSendingMessage = true;
    _isAILoading = true;
    
    setModalState?.call(() {});
    setState(() {
      _chatMessages.add({
        'role': 'user',
        'content': message.trim(),
        'timestamp': MoodyClock.now(),
      });
    });

    _chatController.clear();
    _scrollToBottom();

    try {
      final dailyState = ref.read(dailyMoodStateNotifierProvider);
      final currentMood = dailyState.currentMood ?? 'exploring';
      final locationAsync = ref.read(locationNotifierProvider);
      final city = locationAsync.value ?? 'Rotterdam';

      final position = await ref.read(userLocationProvider.future);
      final latitude = position?.latitude ?? 51.9225;
      final longitude = position?.longitude ?? 4.4792;

      // ONLY make API call when user explicitly sends a message
      final response = await WanderMoodAIService.chat(
        message: message.trim(),
        conversationId: _conversationId,
        moods: [currentMood],
        latitude: latitude,
        longitude: longitude,
        city: city,
      );

      if (response.conversationId != null) {
        _conversationId = response.conversationId;
      }

      if (mounted) {
        setState(() {
          _chatMessages.add({
            'role': 'assistant',
            'content': response.message,
            'timestamp': MoodyClock.now(),
          });
          _isAILoading = false;
          _isSendingMessage = false;
        });
        setModalState?.call(() {});
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'role': 'assistant',
            'content': "Oops! I'm having trouble connecting right now. Can you try again? 🤔",
            'timestamp': MoodyClock.now(),
          });
          _isAILoading = false;
          _isSendingMessage = false;
        });
        setModalState?.call(() {});
        _scrollToBottom();
      }
    }
  }

  void _handleQuickReply(String reply, StateSetter setModalState) {
    // Quick replies trigger explicit send - this is user action, so API call is OK
    setModalState(() {});
    if (_chatMessages.isNotEmpty) {
      _chatMessages.last.remove('quickReplies');
    }

    if (reply.contains('Add to My Day') && _contextualActivity != null) {
      _addActivityToDay(_contextualActivity!, setModalState);
      return;
    }

    if (reply.contains('View details') && _contextualActivity != null) {
      Navigator.of(context).pop();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrendingDetailScreen(
            trending: _contextualActivity!,
          ),
        ),
      );
      return;
    }

    if (reply.contains('Why this?') && _contextualActivity != null) {
      _explainRecommendation(_contextualActivity!, setModalState);
      return;
    }

    _sendMessage(reply, setModalState);
  }

  void _addActivityToDay(TrendingActivity activity, StateSetter setModalState) {
    setState(() {
      _chatMessages.add({
        'role': 'assistant',
        'content': "Added 💚\n\nI'll remind you later if the vibe still matches.",
        'timestamp': MoodyClock.now(),
      });
    });
    setModalState(() {});
    _scrollToBottom();
  }

  void _explainRecommendation(TrendingActivity activity, StateSetter setModalState) {
    final dailyState = ref.read(dailyMoodStateNotifierProvider);
    final currentMood = dailyState.currentMood ?? 'exploring';

    final explanation = "I picked this ${activity.title.toLowerCase()} because:\n\n"
        "${_getMoodEmoji(currentMood)} Your ${currentMood.capitalize()} mood loves ${activity.moodTag.isNotEmpty ? activity.moodTag : 'new experiences'}\n"
        "⭐ ${activity.popularityScore.toStringAsFixed(0)}% match with your vibe\n"
        "🔥 ${activity.trend == 'hot' ? 'Hot right now' : 'Trending in your area'}\n\n"
        "Your current energy is perfect for this!";

    setState(() {
      _chatMessages.add({
        'role': 'assistant',
        'content': explanation,
        'timestamp': MoodyClock.now(),
      });
    });
    setModalState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _setupAnimations() {
    // Controllers are already initialized in initState
    if (_fadeController != null) {
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
        parent: _fadeController!,
      curve: Curves.easeOut,
    ));
      _fadeController!.forward();
    }

    if (_slideController != null) {
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideController!,
      curve: Curves.easeOutBack,
    ));
      _slideController!.forward();
    }

    if (_floatController != null) {
      _floatAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _floatController!,
        curve: Curves.easeInOut,
      ));
    }
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    _slideController?.dispose();
    _floatController?.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final dailyState = ref.watch(dailyMoodStateNotifierProvider);
    final moodOptionsAsync = ref.watch(moodOptionsProvider);
    final trendingAsync = ref.watch(trendingActivitiesProvider);

    // Build the main content with SwirlBackground (same as Explore screen)
    final mainContent = SwirlBackground(
      child: SafeArea(
        child: _fadeAnimation != null && _slideAnimation != null
            ? FadeTransition(
                opacity: _fadeAnimation!,
                child: SlideTransition(
                  position: _slideAnimation!,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          const SizedBox(height: 20),
                          // Header with greeting
                          _buildHeader(),
                          const SizedBox(height: 24),
                          // Hero Moody card (contains primary CTA inside)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildStatusCard(dailyState),
                          ),
                          const SizedBox(height: 20),
                          // Two action cards
                          _buildActionCards(moodOptionsAsync),
                          const SizedBox(height: 24),
                          // Check-in streak badge
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildCheckInStreak(),
                          ),
                          const SizedBox(height: 24),
                          // Your Day's Flow section (always visible)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildYourDaysFlow(dailyState),
                          ),
                          const SizedBox(height: 24),
                          // You + this = perfect section with mood-based carousel
                          _buildMoodBasedSection(dailyState),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Header with greeting
                      _buildHeader(),
                      const SizedBox(height: 24),
                      // Hero Moody card (contains primary CTA inside)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildStatusCard(dailyState),
                      ),
                      const SizedBox(height: 20),
                      // Two action cards
                      _buildActionCards(moodOptionsAsync),
                      const SizedBox(height: 24),
                      // Check-in streak badge
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildCheckInStreak(),
                      ),
                      const SizedBox(height: 24),
                      // Your Day's Flow section (always visible)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildYourDaysFlow(dailyState),
                      ),
                      const SizedBox(height: 24),
                      // You + this = perfect section with mood-based carousel
                      _buildMoodBasedSection(dailyState),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
      ),
    );

    // Wrap in Stack to show overlay when needed
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to show SwirlBackground
      extendBody: false, // Don't extend behind nav bar
      body: Stack(
        children: [
          // Main content with blur effect when overlay is shown
          _showIntroOverlay
              ? ClipRect(
                  child: Stack(
                    children: [
                      // Blurred background - stronger blur to hide Moody Hub content
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                        child: mainContent,
                      ),
                      // Dark overlay on top of blurred content - stronger to hide green cards
                      Container(
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ],
                  ),
                )
              : mainContent,
          // Intro overlay
          if (_showIntroOverlay)
            MoodyIntroOverlay(
              onCreateDay: _handleCreateDayFromOverlay,
              onSkip: _dismissIntroOverlay,
            ),
        ],
      ),
    );
  }

  // Header with greeting (personalized based on check-ins)
  Widget _buildHeader() {
    final hour = MoodyClock.now().hour;
    String greeting = 'Hey there!';
    String emoji = '👋';
    String subtitle = 'Welcome back to your mood journey 🎭';
    
    if (hour < 12) {
      greeting = 'Good morning!';
      emoji = '☀️';
    } else if (hour < 17) {
      greeting = 'Good afternoon!';
      emoji = '🌤️';
    } else if (hour < 21) {
      greeting = 'Good evening!';
      emoji = '✨';
    } else {
      greeting = 'Hey night owl!';
      emoji = '🌙';
    }

    // Check if this is a first-time user
    return FutureBuilder<bool>(
      future: _isFirstTimeUser(),
      builder: (context, firstTimeSnapshot) {
        final isFirstTime = firstTimeSnapshot.data ?? false;
        
        if (isFirstTime) {
          // First-time user - they've already seen the intro overlay, so use a natural greeting
          // Keep the time-based greeting but with a friendly subtitle
          subtitle = 'Ready to create your first amazing day?';
        }

        // Load previous check-in to personalize greeting (for returning users)
        return FutureBuilder(
          future: isFirstTime ? Future.value(null) : _getPersonalizedGreeting(hour),
          builder: (context, snapshot) {
            if (snapshot.hasData && !isFirstTime) {
              final personalized = snapshot.data as Map<String, String>;
              greeting = personalized['greeting'] ?? greeting;
              subtitle = personalized['subtitle'] ?? subtitle;
            }
        
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          greeting,
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A202C),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ),
              // Saved places button
              FutureBuilder<int>(
                future: ref.read(savedPlacesServiceProvider).getSavedPlacesCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SavedPlacesScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.bookmark,
                              color: Color(0xFF2A6049),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              count > 9 ? '9+' : count.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
          },
        );
      },
    );
  }

  // Check if user is first-time (hasn't created a plan yet)
  Future<bool> _isFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedFirstPlan = prefs.getBool('has_completed_first_plan') ?? false;
      return !hasCompletedFirstPlan;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Error checking first-time user status: $e');
      return false; // Default to returning user if check fails
    }
  }

  Future<Map<String, String>> _getPersonalizedGreeting(int hour) async {
    try {
      final checkInService = CheckInService(SupabaseConfig.client);
      final yesterdayCheckIn = await checkInService.getYesterdayCheckIn();
      final lastCheckIn = await checkInService.getLastCheckIn();
      
      String greeting = 'Hey there!';
      String subtitle = 'Welcome back to your mood journey 🎭';
      
      if (hour < 12 && yesterdayCheckIn != null) {
        // Morning greeting referencing yesterday
        if (yesterdayCheckIn.mood == 'tired') {
          greeting = 'Good morning!';
          subtitle = 'Did you sleep well? Hope you feel refreshed! 🌅';
        } else if (yesterdayCheckIn.metadata?['bought_clothes'] == true) {
          greeting = 'Good morning!';
          subtitle = 'Ready to try on those new clothes today? 👗';
        } else {
          greeting = 'Good morning!';
          subtitle = 'Ready for a new day? Let\'s make it great! ☀️';
        }
      } else if (lastCheckIn != null) {
        // Reference most recent check-in
        final lastText = (lastCheckIn.text ?? '').toLowerCase();
        if (lastCheckIn.metadata?['bought_clothes'] == true && !lastText.contains('tried') && !lastText.contains('wore')) {
          subtitle = 'How are those new clothes working out? 👕';
        }
      }
      
      return {'greeting': greeting, 'subtitle': subtitle};
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Error loading personalized greeting: $e');
      return {'greeting': 'Hey there!', 'subtitle': 'Welcome back to your mood journey 🎭'};
    }
  }

  // Primary CTA button for inside the hero card - state-driven
  Widget _buildPrimaryCTAButton(_DayHeroState state) {
    late final String buttonText;
    late final VoidCallback? onTap;

    switch (state) {
      case _DayHeroState.noPlan:
        buttonText = 'Create my day ✨';
        onTap = widget.onChangeMood;
        break;
      case _DayHeroState.planScheduledLater:
        buttonText = 'View my plan';
        onTap = widget.onChangeMood;
        break;
      case _DayHeroState.upcomingSoon:
        buttonText = 'Add warm-up';
        onTap = widget.onChangeMood;
        break;
      case _DayHeroState.activeNow:
        buttonText = 'Check in now';
        onTap = () => _showCheckInScreen(context);
        break;
      case _DayHeroState.recentlyCompleted:
        buttonText = 'Rate & reflect';
        onTap = () => _showCheckInScreen(context);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A6049),
            Color(0xFF2A6049),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A6049).withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  buttonText,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Check if user has completed their first plan
  Future<bool> _hasCompletedFirstPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('has_completed_first_plan') ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error checking first plan completion: $e');
      }
      return false;
    }
  }

  // Old full-width primary CTA (kept for reference, can be removed if not used elsewhere)
  Widget _buildPrimaryCTA() {
    final scheduledActivitiesAsync = ref.watch(todayActivitiesProvider);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FutureBuilder<bool>(
        future: _hasCompletedFirstPlan(),
        builder: (context, firstPlanSnapshot) {
          final hasCompletedFirstPlan = firstPlanSnapshot.data ?? false;
          
          return scheduledActivitiesAsync.when(
            data: (activities) {
              // Only show "Update my day" if user has completed first plan AND has activities
              final hasPlan = hasCompletedFirstPlan && activities.isNotEmpty;
              final buttonText = hasPlan ? 'Update my day' : 'Create my day ✨';
          
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2A6049),
                  Color(0xFF2A6049),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2A6049).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onChangeMood?.call(),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        buttonText,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[200],
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A6049)),
              ),
            ),
          ),
        ),
        error: (_, __) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A6049),
                Color(0xFF2A6049),
              ],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => widget.onChangeMood?.call(),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create my day ✨',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      },
    ),
    );
  }

  // First-time welcome card
  Widget _buildFirstTimeWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A6049),
            Color(0xFF2A6049),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A6049).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const MoodyCharacter(
                  size: 40,
                  mood: 'excited',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to WanderMood!',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'I\'m Moody, your travel companion 🌟',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Let\'s create your first amazing day! I\'ll help you discover places based on your mood, weather, and preferences.',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to mood selection to start creating first plan
                widget.onChangeMood?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2A6049),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Create Your First Day Plan',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _HeroStateContext _deriveHeroContext(
    List<EnhancedActivityData> activities,
    DateTime now,
  ) {
    if (activities.isEmpty) {
      return _HeroStateContext(_DayHeroState.noPlan, null);
    }

    final active = activities
        .where((a) => a.status == ActivityStatus.activeNow)
        .firstOrNull;
    if (active != null) {
      return _HeroStateContext(_DayHeroState.activeNow, active);
    }

    final recentCompleted = activities
        .where(
          (a) =>
              a.status == ActivityStatus.completed &&
              now.difference(a.endTime).inMinutes <= 60,
        )
        .lastOrNull;

    final upcoming = activities
        .where((a) => a.status == ActivityStatus.upcoming)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (upcoming.isNotEmpty) {
      final next = upcoming.first;
      final diff = next.startTime.difference(now);
      if (!diff.isNegative && diff <= const Duration(hours: 2)) {
        return _HeroStateContext(_DayHeroState.upcomingSoon, next);
      }
      return _HeroStateContext(_DayHeroState.planScheduledLater, next);
    }

    if (recentCompleted != null) {
      return _HeroStateContext(_DayHeroState.recentlyCompleted, recentCompleted);
    }

    // Fallback: plan exists but nothing active/upcoming soon
    return _HeroStateContext(_DayHeroState.planScheduledLater, null);
  }

  String _currentCityLabel() {
    final asyncCity = ref.watch(locationNotifierProvider);
    final city = asyncCity.maybeWhen(
      data: (value) => value?.trim(),
      orElse: () => null,
    );
    // Never return null to keep copy safe
    if (city == null || city.isEmpty) {
      return 'your city';
    }
    return city;
  }

  // State-driven hero card based on today's plan
  Widget _buildStatusCard(DailyMoodState dailyState) {
    final currentMood = dailyState.currentMood ?? 'exploring';
    final todayActivitiesAsync = ref.watch(todayActivitiesProvider);

    return todayActivitiesAsync.when(
      data: (activities) {
        final now = MoodyClock.now();
        final heroContext = _deriveHeroContext(activities, now);
        final city = _currentCityLabel();

        String emoji = '✨';
        String line1 = '';
        String line2 = '';

        final focusTitle =
            heroContext.focusActivity?.rawData['title'] as String? ?? 'this activity';

        switch (heroContext.state) {
          case _DayHeroState.noPlan:
            emoji = '✨';
            line1 = 'Your day in $city is wide open.';
            line2 = 'Want me to put a plan together for you?';
            break;
          case _DayHeroState.planScheduledLater:
            emoji = '📅';
            line1 = 'You\'ve got a plan lined up later today in $city.';
            line2 = 'Want to take a quick look at what\'s coming?';
            break;
          case _DayHeroState.upcomingSoon:
            emoji = '⏰';
            line1 = 'Soon: $focusTitle in $city.';
            line2 = 'Want a small warm-up or tweak before it starts?';
            break;
          case _DayHeroState.activeNow:
            emoji = '⚡️';
            line1 = 'Right now you\'re at $focusTitle.';
            line2 = 'Want to check in while you\'re in the moment?';
            break;
          case _DayHeroState.recentlyCompleted:
            emoji = '✅';
            line1 = 'You just wrapped $focusTitle.';
            line2 = 'Want to jot it down before we plan the next thing?';
            break;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFC8E6C9).withOpacity(0.9), // Soft mint green
                const Color(0xFFE1F5E1).withOpacity(0.7), // Lighter mint
                const Color(0xFFF1F8F4).withOpacity(0.5), // Very light mint
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF81C784).withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.9),
                blurRadius: 15,
                spreadRadius: -5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left side: State-driven hero content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      line1,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: const Color(0xFF4A5568),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      line2,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A202C),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Primary CTA button - changes per state
                    _buildPrimaryCTAButton(heroContext.state),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right side: Floating Moody character (tappable)
              _buildFloatingMoodyCharacter(currentMood),
            ],
          ),
        );
      },
      loading: () => _buildLoadingMomentCard(currentMood),
      error: (_, __) => _buildLoadingMomentCard(currentMood),
    );
  }
  
  Widget _buildLoadingMomentCard(String currentMood) {
                  return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFC8E6C9).withOpacity(0.9),
            const Color(0xFFE1F5E1).withOpacity(0.7),
            const Color(0xFFF1F8F4).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF81C784).withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✨',
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let me think...',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A202C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildFloatingMoodyCharacter(currentMood),
        ],
      ),
    );
  }
  
  Widget _buildFloatingMoodyCharacter(String mood, {MomentCard? momentCard}) {
    return GestureDetector(
      onTap: () {
        // Open chat with contextual message based on moment
        if (momentCard != null) {
          _showChatBottomSheet(context, 
            contextualGreeting: _getContextualChatStarter(momentCard));
        } else {
          _showChatBottomSheet(context);
        }
      },
      child: _floatController != null
          ? AnimatedBuilder(
              animation: _floatController!,
              builder: (context, child) {
                final hour = MoodyClock.now().hour;
                final floatAmount = hour < 12 
                    ? 4.0 
                    : hour < 18 
                        ? 6.0 
                        : 5.0;
                
                return Transform.translate(
                  offset: Offset(
                    0,
                    math.sin(_floatController!.value * 2 * math.pi) * floatAmount,
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF81C784).withOpacity(0.3),
                          const Color(0xFFA5D6A7).withOpacity(0.2),
                          const Color(0xFFC8E6C9).withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        // Pulsing shadow to indicate tappability
                        BoxShadow(
                          color: const Color(0xFF2A6049).withOpacity(
                            0.3 + (math.sin(_floatController!.value * 2 * math.pi) * 0.2)
                          ),
                          blurRadius: 25 + (math.sin(_floatController!.value * 2 * math.pi) * 5),
                          spreadRadius: 3,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: const Color(0xFF81C784).withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: MoodyCharacter(
                        size: 80,
                        mood: mood,
                      ),
                    ),
                  ),
                );
              },
            )
          : Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF81C784).withOpacity(0.3),
                    const Color(0xFFA5D6A7).withOpacity(0.2),
                    const Color(0xFFC8E6C9).withOpacity(0.1),
                  ],
                ),
              ),
              child: Center(
                child: MoodyCharacter(
                  size: 80,
                  mood: mood,
                ),
              ),
      ),
    );
  }

  // Build action button for moment card based on type
  Widget _buildMomentActionButton(MomentCard momentCard, String mood) {
    String buttonText;
    VoidCallback onTap;
    
    switch (momentCard.pillar) {
      case ContentPillar.tripIdea:
        buttonText = 'Show me this';
        onTap = () {
          // TODO: Navigate to explore or place detail
          _showChatBottomSheet(context, 
            contextualGreeting: _getContextualChatStarter(momentCard));
        };
        break;
      case ContentPillar.eventFestival:
        buttonText = "Talk to me";
        onTap = () {
          _showChatBottomSheet(context, 
            contextualGreeting: null, // Don't pre-fill, just open chat
            autoRespond: true); // Auto-respond from Moody
        };
        break;
      case ContentPillar.softReflection:
        buttonText = "Let's talk about it";
        onTap = () {
          _showChatBottomSheet(context, 
            contextualGreeting: _getContextualChatStarter(momentCard));
        };
        break;
      case ContentPillar.packingPrep:
        buttonText = 'See checklist';
        onTap = () {
          _showChatBottomSheet(context, 
            contextualGreeting: _getContextualChatStarter(momentCard));
        };
        break;
      case ContentPillar.socialNudge:
        buttonText = 'Tell me more';
        onTap = () {
          _showChatBottomSheet(context, 
            contextualGreeting: _getContextualChatStarter(momentCard));
        };
        break;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2A6049),
              Color(0xFF0E8F38),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2A6049).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              buttonText,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward,
              size: 16,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
  
  // Get contextual chat starter based on moment type
  String _getContextualChatStarter(MomentCard momentCard) {
    switch (momentCard.pillar) {
      case ContentPillar.tripIdea:
        return "Tell me more about ${momentCard.title}";
      case ContentPillar.eventFestival:
        return "What's happening? ${momentCard.title}";
      case ContentPillar.softReflection:
        return momentCard.title;
      case ContentPillar.packingPrep:
        return "Help me prepare! ${momentCard.title}";
      case ContentPillar.socialNudge:
        return momentCard.title;
    }
  }

  // Helper to get mood label
  String _getMoodLabel(String mood) {
    final moodMap = {
      'foody': 'Foody',
      'adventurous': 'Adventurous',
      'relaxed': 'Relaxed',
      'cultural': 'Cultural',
      'romantic': 'Romantic',
      'social': 'Social',
      'contemplative': 'Contemplative',
      'energetic': 'Energetic',
      'creative': 'Creative',
      'exploring': 'Exploring',
    };
    return moodMap[mood.toLowerCase()] ?? mood.capitalize();
  }

  // Large animated Moody character hero section (keeping for reference)
  Widget _buildMoodyCharacterHero(DailyMoodState dailyState) {
    final currentMood = dailyState.currentMood ?? 'exploring';
    final moodEmoji = _getMoodEmoji(currentMood);
    final hour = MoodyClock.now().hour;
    
    String greeting = 'Hey there!';
    String personalityMessage = "Ready for today's adventure?";
    
    if (hour < 12) {
      greeting = 'Good morning!';
      personalityMessage = "What's the vibe today?";
    } else if (hour < 17) {
      greeting = 'Good afternoon!';
      personalityMessage = "How's your day going?";
    } else if (hour < 21) {
      greeting = 'Good evening!';
      personalityMessage = "How was your day?";
    } else {
      greeting = 'Hey night owl!';
      personalityMessage = "Still exploring?";
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Large animated character
          GestureDetector(
        onTap: () => _showChatBottomSheet(context),
        child: Container(
              width: 140,
              height: 140,
          decoration: BoxDecoration(
                shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                    const Color(0xFF2A6049).withOpacity(0.2),
                const Color(0xFF2A6049).withOpacity(0.1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                    color: const Color(0xFF2A6049).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
              ),
            ],
          ),
              child: Center(
                child: MoodyCharacter(
                  size: 120,
                mood: currentMood,
                onTap: () => _showChatBottomSheet(context),
              ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Greeting with personality
              Text(
            greeting,
                style: GoogleFonts.poppins(
              fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A202C),
                ),
          ),
          const SizedBox(height: 8),
          // Current vibe display with change button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      moodEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "You're feeling ${currentMood.capitalize()}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A202C),
                      ),
                    ),
                  ],
                      ),
                    ),
                    const SizedBox(width: 12),
              // Change mood button
              GestureDetector(
                onTap: () => _showMoodChangeSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5EE),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2A6049),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.swap_horiz,
                    color: Color(0xFF2A6049),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Personality message
          Text(
            personalityMessage,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF4A5568),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Today's Adventure card - one highlighted suggestion
  Widget _buildTodaysAdventureCard(
    AsyncValue<List<TrendingActivity>> trendingAsync,
    DailyMoodState dailyState,
  ) {
    final currentMood = dailyState.currentMood ?? 'exploring';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
                children: [
              const Text("✨", style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                "Today's Adventure",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A202C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          trendingAsync.when(
            data: (trending) {
              if (trending.isEmpty) {
                return _buildEmptyAdventureCard();
              }
              // Get the first/best suggestion
              final adventure = trending.first;
              return _buildAdventureCard(adventure, currentMood);
            },
            loading: () => Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2A6049),
                ),
              ),
            ),
            error: (_, __) => _buildEmptyAdventureCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdventureCard(TrendingActivity adventure, String currentMood) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrendingDetailScreen(trending: adventure),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background image
              if (adventure.imageUrl.isNotEmpty)
                Image.network(
                  adventure.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2A6049).withOpacity(0.3),
                          const Color(0xFF2A6049).withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        adventure.emoji,
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2A6049).withOpacity(0.3),
                        const Color(0xFF2A6049).withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      adventure.emoji,
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ),
              // Gradient overlay
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A6049),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Moody's Pick",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                    ),
                  ),
                ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        adventure.title,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (adventure.location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              adventure.location,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
              ),
            ],
          ),
                      ],
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

  Widget _buildEmptyAdventureCard() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🎯", style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              "Moody is finding something perfect for you...",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Card 2: Daily Check-in Card
  Widget _buildDailyCheckInCard(AsyncValue<List<MoodOption>> moodOptionsAsync) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFF2A6049).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "😌✨",
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 24),
            Text(
              "How are we feeling today?",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A202C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "30 seconds to better recommendations",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF4A5568),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Swipeable mood pills
            moodOptionsAsync.when(
              data: (moodOptions) => _buildCheckInMoodPills(moodOptions),
              loading: () => const CircularProgressIndicator(
                color: Color(0xFF2A6049),
              ),
              error: (_, __) => Text(
                "Couldn't load moods",
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Optional voice input hint
            Text(
              "💬 Tap to select • Swipe for more",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInMoodPills(List<MoodOption> moodOptions) {
    final quickMoods = moodOptions.take(6).toList();
    
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickMoods.length,
        itemBuilder: (context, index) {
          final mood = quickMoods[index];
    return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  ref.read(dailyMoodStateNotifierProvider.notifier).updateMood(mood.id);
                  showWanderMoodToast(
                    context,
                    message: "Feeling ${mood.label} today! ✨",
                  );
                },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2A6049).withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mood.emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mood.label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A202C),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Moody Suggestions Card
  Widget _buildMoodySuggestionsCard(
    AsyncValue<List<TrendingActivity>> trendingAsync,
    DailyMoodState dailyState,
  ) {
    final currentMood = dailyState.currentMood ?? 'exploring';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("☁️", style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              "Moody thinks you'd love...",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A202C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: trendingAsync.when(
            data: (trending) => _buildSuggestionCardsHorizontal(trending, currentMood),
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2A6049),
              ),
            ),
            error: (_, __) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("😅", style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    "Couldn't load suggestions",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Check-in streak badge
  Widget _buildCheckInStreak() {
    return FutureBuilder<int>(
      future: CheckInService(SupabaseConfig.client).getCheckInStreak(),
      builder: (context, snapshot) {
        final streak = snapshot.data ?? 0;
        if (streak == 0) return const SizedBox.shrink();
    
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFE0B2).withOpacity(0.8), // Soft pastel orange
                const Color(0xFFFFCCBC).withOpacity(0.6), // Lighter pastel orange
                const Color(0xFFFFF3E0).withOpacity(0.4), // Very light pastel
              ],
            ),
            borderRadius: BorderRadius.circular(24), // Soft rounded
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB74D).withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🔥", style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                "$streak ${streak == 1 ? 'day' : 'days'} checked in with Moody",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A202C),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Your Day's Flow - Colorful horizontal timeline with interpretive commentary
  Widget _buildYourDaysFlow(DailyMoodState dailyState) {
    final activities = dailyState.plannedActivities;
    final now = MoodyClock.now();
    final hour = now.hour;
    final currentMood = dailyState.currentMood ?? 'exploring';
    final contentService = ref.watch(moodyHubContentServiceProvider);
    
    // Define time periods with colors and emojis
    final timePeriods = [
      {
        'label': 'Morning',
        'emoji': '🌅',
        'start': 6,
        'end': 12,
        'color': const Color(0xFFFFE082), // Soft yellow
        'gradient': [const Color(0xFFFFF9C4), const Color(0xFFFFE082)],
      },
      {
        'label': 'Afternoon',
        'emoji': '☀️',
        'start': 12,
        'end': 17,
        'color': const Color(0xFF81C784), // Soft green
        'gradient': [const Color(0xFFC8E6C9), const Color(0xFF81C784)],
      },
      {
        'label': 'Evening',
        'emoji': '🌆',
        'start': 17,
        'end': 22,
        'color': const Color(0xFFBA68C8), // Soft purple
        'gradient': [const Color(0xFFE1BEE7), const Color(0xFFBA68C8)],
      },
      {
        'label': 'Night',
        'emoji': '🌙',
        'start': 22,
        'end': 24,
        'color': const Color(0xFF64B5F6), // Soft blue
        'gradient': [const Color(0xFFBBDEFB), const Color(0xFF64B5F6)],
      },
    ];
    
    // Determine which periods are active, completed, or upcoming
    List<Map<String, dynamic>> periodStates = timePeriods.map((period) {
      final periodStart = period['start'] as int;
      final periodEnd = period['end'] as int;
      bool isActive = hour >= periodStart && hour < periodEnd;
      bool isCompleted = hour >= periodEnd;
      bool isUpcoming = hour < periodStart;
      
      // Count activities in this period
      final periodActivities = activities.where((activity) {
        if (activity.startTime == null) return false;
        final activityHour = activity.startTime!.hour;
        return activityHour >= periodStart && activityHour < periodEnd;
      }).length;
      
      return {
        ...period,
        'isActive': isActive,
        'isCompleted': isCompleted,
        'isUpcoming': isUpcoming,
        'activityCount': periodActivities,
      };
    }).toList();
    
    // Generate interpretive commentary
    final morningCount = activities.where((a) => a.startTime != null && a.startTime!.hour >= 6 && a.startTime!.hour < 12).length;
    final afternoonCount = activities.where((a) => a.startTime != null && a.startTime!.hour >= 12 && a.startTime!.hour < 17).length;
    final eveningCount = activities.where((a) => a.startTime != null && a.startTime!.hour >= 17 && a.startTime!.hour < 24).length;
    
    final commentary = contentService.generateDayFlowCommentary(
      morningCount: morningCount,
      afternoonCount: afternoonCount,
      eveningCount: eveningCount,
      mood: currentMood,
      hour: hour,
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Your Day's Flow",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A202C),
              ),
            ),
            const Spacer(),
            Text(
              _getTimeOfDayEmoji(hour),
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Interpretive commentary
        Text(
          commentary,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF4A5568),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
          gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
            colors: [
              Colors.white,
                const Color(0xFFF5F5F5).withOpacity(0.5),
            ],
        ),
            borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
                color: const Color(0xFFB0BEC5).withOpacity(0.15),
              blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
          ),
        ],
      ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: periodStates.asMap().entries.map((entry) {
                final index = entry.key;
                final period = entry.value;
                final isLast = index == periodStates.length - 1;
                
                return Row(
                  children: [
                    _buildTimelinePeriod(period),
                    if (!isLast) _buildTimelineConnector(period, periodStates[index + 1]),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimelinePeriod(Map<String, dynamic> period) {
    final isActive = period['isActive'] as bool;
    final isCompleted = period['isCompleted'] as bool;
    final isUpcoming = period['isUpcoming'] as bool;
    final emoji = period['emoji'] as String;
    final label = period['label'] as String;
    final gradient = period['gradient'] as List<Color>;
    final activityCount = period['activityCount'] as int;
    
    return GestureDetector(
      onTap: () => _showPeriodActivities(context, period),
      child: Container(
        width: 100,
      child: Column(
        children: [
          // Period circle with gradient
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isCompleted 
                        ? [gradient[0].withOpacity(0.6), gradient[1].withOpacity(0.4)]
                        : isActive
                            ? gradient
                            : [gradient[0].withOpacity(0.3), gradient[1].withOpacity(0.2)],
                  ),
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: gradient[1].withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 3,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: TextStyle(
                      fontSize: isActive ? 32 : 28,
                    ),
                  ),
                ),
              ),
              if (isCompleted)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF81C784),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Label
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive 
                  ? const Color(0xFF1A202C)
                  : isCompleted
                      ? const Color(0xFF4A5568)
                      : const Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 4),
          // Activity count or status
          if (activityCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: gradient[1].withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$activityCount ${activityCount == 1 ? 'activity' : 'activities'}',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: gradient[1],
                ),
              ),
            )
          else if (isActive)
            Text(
              'In progress',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: gradient[1],
                fontStyle: FontStyle.italic,
              ),
            )
          else if (isUpcoming)
            Text(
              'Upcoming',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    ),
    );
  }
  
  // Show activities for a specific time period
  void _showPeriodActivities(BuildContext context, Map<String, dynamic> period) {
    final periodStart = period['start'] as int;
    final periodEnd = period['end'] as int;
    
    final dailyState = ref.read(dailyMoodStateNotifierProvider);
    final activities = dailyState.plannedActivities.where((activity) {
      final activityHour = activity.startTime.hour;
      return activityHour >= periodStart && activityHour < periodEnd;
    }).toList();
    
    final currentMood = dailyState.currentMood ?? 'exploring';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (context) => PeriodActivitiesBottomSheet(
        period: period,
        activities: activities,
        currentMood: currentMood,
        showChatCallback: _showChatBottomSheet,
      ),
    );
  }
  
  Widget _buildTimelineConnector(Map<String, dynamic> current, Map<String, dynamic> next) {
    final currentCompleted = current['isCompleted'] as bool;
    final nextActive = next['isActive'] as bool;
    final nextCompleted = next['isCompleted'] as bool;
    
    Color connectorColor;
    if (currentCompleted && (nextActive || nextCompleted)) {
      connectorColor = const Color(0xFF81C784); // Green for completed path
    } else if (currentCompleted) {
      connectorColor = const Color(0xFFE0E0E0); // Gray for upcoming
    } else {
      connectorColor = const Color(0xFFE0E0E0);
    }
    
    return Container(
      width: 40,
      margin: const EdgeInsets.only(top: 35),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: connectorColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: connectorColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: connectorColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getTimeOfDayEmoji(int hour) {
    if (hour < 6) return '🌙';
    if (hour < 12) return '🌅';
    if (hour < 17) return '☀️';
    if (hour < 22) return '🌆';
    return '🌙';
  }

  // You + this = perfect section with mood-based carousel
  Widget _buildMoodBasedSection(DailyMoodState dailyState) {
    final currentMood = dailyState.currentMood ?? 'exploring';
    final locationNotifier = ref.watch(locationNotifierProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'Recommended for you',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A202C),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Cached Explore rows only (no Edge/Google from Hub)
        locationNotifier.when(
          data: (location) {
            if (location == null) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Enable location to see personalized suggestions...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF718096),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }
            
            // Use ref.watch instead of FutureBuilder to prevent API calls on rebuild
            final placesAsync = ref.watch(moodyHubExploreCacheOnlyProvider);
            
            return placesAsync.when(
              data: (places) {
                if (places.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Open Explore to load spots for your mood — favorites from cache appear here.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF718096),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }
                
                return SimplifiedMoodCarousel(
                  places: places,
                  mood: currentMood,
                  onChatOpen: _showChatBottomSheet,
                  onAddToDay: _addPlaceToSchedule,
                  onRefresh: () =>
                      ref.invalidate(moodyHubExploreCacheOnlyProvider),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Could not load cached suggestions. Try Explore to refresh.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF718096),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Unable to load suggestions right now',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF718096),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Moody thinks you'd love section
  Widget _buildMoodyThinksYoudLove(
    AsyncValue<List<TrendingActivity>> trendingAsync,
    DailyMoodState dailyState,
  ) {
    final currentMood = dailyState.currentMood ?? 'exploring';
    
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
            const Text("☁️", style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              "Moody thinks you'd love...",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A202C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: trendingAsync.when(
            data: (trending) => _buildSuggestionCardsHorizontal(trending, currentMood),
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2A6049),
              ),
            ),
            error: (_, __) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("😅", style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    "Couldn't load suggestions",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Shift your vibe section
  Widget _buildShiftYourVibeSection(
    AsyncValue<List<MoodOption>> moodOptionsAsync,
    DailyMoodState dailyState,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Shift your vibe?",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 16),
          moodOptionsAsync.when(
            data: (moodOptions) => _buildMoodPills(moodOptions, dailyState),
            loading: () => const SizedBox(
              height: 60,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2A6049),
                ),
              ),
            ),
            error: (_, __) => Text(
              "Couldn't load moods",
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodPills(List<MoodOption> moodOptions, DailyMoodState dailyState) {
    final currentMood = dailyState.currentMood ?? 'exploring';
    // Get quick moods (first 6)
    final quickMoods = moodOptions.take(6).toList();
    
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickMoods.length + 1, // +1 for ellipsis
        itemBuilder: (context, index) {
          if (index == quickMoods.length) {
            // Ellipsis button
    return Container(
              width: 50,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '...',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            );
          }
          
          final mood = quickMoods[index];
          final isSelected = mood.id.toLowerCase() == currentMood.toLowerCase();
          
          return Container(
            margin: EdgeInsets.only(right: index == quickMoods.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: () {
                ref.read(dailyMoodStateNotifierProvider.notifier).updateMood(mood.id);
                showWanderMoodToast(
                  context,
                  message: "Switched to ${mood.label} mood! ✨",
                );
              },
      child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFFEAF5EE)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2A6049)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2A6049),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      mood.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mood.label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: const Color(0xFF1A202C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Your Journey - visual timeline section
  Widget _buildYourJourneySection(DailyMoodState dailyState) {
    final activities = dailyState.plannedActivities;
    final now = MoodyClock.now();
    final hour = now.hour;
    
    // Determine current phase
    String phaseTitle = "Your Journey";
    String phaseSubtitle = "Let's see what's happening today";
    
    if (hour < 12) {
      phaseTitle = "Morning Journey";
      phaseSubtitle = "Starting your day right";
    } else if (hour < 18) {
      phaseTitle = "Afternoon Journey";
      phaseSubtitle = "Your adventure continues";
    } else {
      phaseTitle = "Evening Journey";
      phaseSubtitle = "How was your day?";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("🗺️", style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              phaseTitle,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A202C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          phaseSubtitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 16),
        if (activities.isEmpty)
          _buildEmptyJourneyCard()
        else
          _buildJourneyTimeline(activities),
      ],
    );
  }

  Widget _buildJourneyTimeline(List<EnhancedActivityData> activities) {
    // Get today's activities sorted by time
    final todayActivities = activities
        .where((a) => a.startTime.day == MoodyClock.now().day)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (todayActivities.isEmpty) {
      return _buildEmptyJourneyCard();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: todayActivities.take(3).map((activity) {
          final isActive = activity.status == ActivityStatus.activeNow;
          final isCompleted = activity.status == ActivityStatus.completed;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                // Timeline dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? const Color(0xFF2A6049)
                        : isCompleted
                            ? Colors.grey[400]
                            : Colors.grey[300],
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                      Text(
                        activity.rawData['title'] ?? 'Activity',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A202C),
                        ),
                      ),
                      const SizedBox(height: 4),
          Row(
            children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(activity.startTime),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF5EE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Now',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2A6049),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyJourneyCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            const Text("🌟", style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              "Your journey starts here",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap 'Chat with Moody' to plan your day",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  // Quick mood shift section - always visible
  Widget _buildQuickMoodShift(
    AsyncValue<List<MoodOption>> moodOptionsAsync,
    DailyMoodState dailyState,
  ) {
    return moodOptionsAsync.when(
      data: (moodOptions) {
        if (moodOptions.isEmpty) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Change your vibe?",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A202C),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showMoodChangeSheet(context),
                    child: Text(
                      "See all",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF2A6049),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: moodOptions.length,
                  itemBuilder: (context, index) {
                    final mood = moodOptions[index];
                    final isSelected = mood.id.toLowerCase() == (dailyState.currentMood ?? '').toLowerCase();
                    
                    return Container(
                      margin: EdgeInsets.only(right: index == moodOptions.length - 1 ? 0 : 12),
                      child: GestureDetector(
                        onTap: () {
                          ref.read(dailyMoodStateNotifierProvider.notifier).updateMood(mood.id);
                          showWanderMoodToast(
                            context,
                            message: "Switched to ${mood.label} vibe! ✨",
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2A6049)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2A6049)
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                mood.emoji,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: isSelected ? Colors.white : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                mood.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : const Color(0xFF1A202C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const SizedBox(
          height: 60,
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2A6049),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // Show check-in screen (FaceTime-like)
  void _showCheckInScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CheckInScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  // Show confirmation dialog before changing mood
  void _showChangeMoodConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Text("🎭", style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                "Change your mood?",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A202C),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          "Do you want to continue to change mood? This will take you to the mood selection screen.",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Add a mini delay for better UX
              await Future.delayed(const Duration(milliseconds: 300));
              if (mounted) {
                Navigator.of(context).pop();
                // Enter mood change mode (preserves state and shows "Back to Hub" button)
                ref.read(dailyMoodStateNotifierProvider.notifier).enterMoodChangeMode();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A6049),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              "Continue",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show mood change bottom sheet
  void _showMoodChangeSheet(BuildContext context) {
    final moodOptionsAsync = ref.read(moodOptionsProvider);
    final dailyState = ref.read(dailyMoodStateNotifierProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Change your vibe",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A202C),
                    ),
                  ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
              ),
              Expanded(
                child: moodOptionsAsync.when(
                  data: (moodOptions) => GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: moodOptions.length,
                    itemBuilder: (context, index) {
                      final mood = moodOptions[index];
                      final isSelected = mood.id.toLowerCase() == (dailyState.currentMood ?? '').toLowerCase();
                      
                      return GestureDetector(
                        onTap: () {
                          ref.read(dailyMoodStateNotifierProvider.notifier).updateMood(mood.id);
                          Navigator.of(context).pop();
                          showWanderMoodToast(
                            context,
                            message: "Switched to ${mood.label} vibe! ✨",
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEAF5EE)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2A6049)
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
              Text(
                                mood.emoji,
                                style: const TextStyle(fontSize: 48),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                mood.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: const Color(0xFF1A202C),
                                ),
                              ),
                              if (isSelected) ...[
            const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A6049),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "Current",
              style: GoogleFonts.poppins(
                fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2A6049),
                  ),
                ),
                error: (_, __) => Center(
                    child: Text(
                      "Couldn't load moods",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
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

  // Action cards: Check in, Talk to Moody, Change mood (clear entry to pick moods / new plan)
  Widget _buildActionCards(AsyncValue<List<MoodOption>> moodOptionsAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              // Check in card
              Expanded(
                child: _buildModernActionCard(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF6B9D), // Warm pink
                      Color(0xFFFFA06B), // Warm orange
                    ],
                  ),
                  icon: Icons.videocam,
                  title: 'Check in',
                  subtitle: 'Tell Moody about your day',
                  emoji: '📹',
                  accentColor: const Color(0xFFFF6B9D),
                  onTap: () => _showCheckInScreen(context),
                ),
              ),
              const SizedBox(width: 16),
              // Talk to Moody card
              Expanded(
                child: _buildModernActionCard(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2A6049),
                      Color(0xFF2A6049),
                    ],
                  ),
                  icon: Icons.chat_bubble_rounded,
                  title: 'Talk to Moody',
                  subtitle: 'Ask me anything',
                  emoji: '💬',
                  accentColor: const Color(0xFF2A6049),
                  onTap: () => widget.onShowChat?.call(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Change mood card - full width so user can easily find "change mood"
          if (widget.onChangeMood != null)
            _buildModernActionCard(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF7C4DFF), // Soft purple
                  Color(0xFFB388FF), // Lighter purple
                ],
              ),
              icon: Icons.mood,
              title: 'Change mood',
              subtitle: 'Pick moods & create a new day plan',
              emoji: '✨',
              accentColor: const Color(0xFF7C4DFF),
              onTap: () => widget.onChangeMood!(),
            ),
        ],
      ),
    );
  }

  Widget _buildModernActionCard({
    required Gradient gradient,
    required IconData icon,
    required String title,
    required String subtitle,
    required String emoji,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: accentColor.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            // Inner highlight for depth
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              blurRadius: 5,
              spreadRadius: -2,
              offset: const Offset(0, -2),
            ),
          ],
        ),
                  child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
                    children: [
            // Icon with emoji overlay
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
                      const SizedBox(height: 16),
            // Title
                      Text(
              title,
                        style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            // Subtitle
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Today's Flow Card (keeping for reference, can be removed later)
  Widget _buildTodayFlowCard(DailyMoodState dailyState) {
    final now = MoodyClock.now();
    final hour = now.hour;
    
    // Determine status for each time period
    String morningStatus = 'Ready for you';
    String afternoonStatus = 'Ready for you';
    String eveningStatus = 'Ready for you';
    IconData morningIcon = Icons.circle_outlined;
    Color morningColor = Colors.grey;
    IconData afternoonIcon = Icons.circle_outlined;
    Color afternoonColor = Colors.grey;
    IconData eveningIcon = Icons.circle_outlined;
    Color eveningColor = Colors.grey;
    
    // Morning (6 AM - 12 PM)
    if (hour >= 6 && hour < 12) {
      // Check if there are morning activities
      final morningActivities = dailyState.plannedActivities
          .where((a) => a.startTime.hour >= 6 && a.startTime.hour < 12)
          .toList();
      
      if (morningActivities.any((a) => a.status == ActivityStatus.completed)) {
        morningStatus = 'Complete & satisfying';
        morningIcon = Icons.check;
        morningColor = const Color(0xFF1A202C);
      } else if (morningActivities.any((a) => a.status == ActivityStatus.activeNow)) {
        morningStatus = 'In progress';
        morningIcon = Icons.play_circle_filled;
        morningColor = Colors.blue;
      } else if (morningActivities.isNotEmpty) {
        morningStatus = 'Upcoming';
        morningIcon = Icons.schedule;
        morningColor = Colors.orange;
      }
    } else if (hour >= 12) {
      // Morning is past
      final morningActivities = dailyState.plannedActivities
          .where((a) => a.startTime.hour >= 6 && a.startTime.hour < 12)
          .toList();
      if (morningActivities.isNotEmpty) {
        morningStatus = 'Complete & satisfying';
        morningIcon = Icons.check;
        morningColor = const Color(0xFF1A202C);
      }
    }
    
    // Afternoon (12 PM - 6 PM)
    if (hour >= 12 && hour < 18) {
      final afternoonActivities = dailyState.plannedActivities
          .where((a) => a.startTime.hour >= 12 && a.startTime.hour < 18)
          .toList();
      
      if (afternoonActivities.any((a) => a.status == ActivityStatus.completed)) {
        afternoonStatus = 'Complete & satisfying';
        afternoonIcon = Icons.check_circle;
        afternoonColor = const Color(0xFF2A6049);
      } else if (afternoonActivities.any((a) => a.status == ActivityStatus.activeNow)) {
        afternoonStatus = 'In the zone now';
        afternoonIcon = Icons.arrow_forward;
        afternoonColor = const Color(0xFF1A202C);
      } else if (afternoonActivities.isNotEmpty) {
        afternoonStatus = 'Upcoming';
        afternoonIcon = Icons.schedule;
        afternoonColor = Colors.orange;
      }
    } else if (hour >= 18) {
      // Afternoon is past
      final afternoonActivities = dailyState.plannedActivities
          .where((a) => a.startTime.hour >= 12 && a.startTime.hour < 18)
          .toList();
      if (afternoonActivities.isNotEmpty) {
        afternoonStatus = 'Complete & satisfying';
        afternoonIcon = Icons.check_circle;
        afternoonColor = const Color(0xFF2A6049);
      }
    }
    
    // Evening (6 PM - 12 AM)
    if (hour >= 18) {
      final eveningActivities = dailyState.plannedActivities
          .where((a) => a.startTime.hour >= 18 || a.startTime.hour < 6)
          .toList();
      
      if (eveningActivities.any((a) => a.status == ActivityStatus.activeNow)) {
        eveningStatus = 'In the zone now';
        eveningIcon = Icons.play_arrow;
        eveningColor = Colors.blue;
      } else if (eveningActivities.isNotEmpty) {
        eveningStatus = 'Upcoming';
        eveningIcon = Icons.schedule;
        eveningColor = Colors.orange;
      } else {
        eveningStatus = 'Ready for you later';
        eveningIcon = Icons.circle;
        eveningColor = Colors.orange.shade600;
      }
    } else {
      // Evening is future
      final eveningActivities = dailyState.plannedActivities
          .where((a) => a.startTime.hour >= 18 || a.startTime.hour < 6)
          .toList();
      if (eveningActivities.isNotEmpty) {
        eveningStatus = 'Ready for you later';
        eveningIcon = Icons.circle;
        eveningColor = Colors.orange.shade600;
      }
    }
    
    // Determine next shift message
    String nextShiftMessage = 'Your day is looking great!';
    if (hour < 12) {
      nextShiftMessage = 'Afternoon adventures approaching';
    } else if (hour < 18) {
      nextShiftMessage = 'Social Hangout Spots approaching';
    } else {
      nextShiftMessage = 'Evening vibes ready';
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Day's Flow",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 24),
          // Morning
          _buildFlowItem(
            'Morning',
            morningStatus,
            morningIcon,
            morningColor,
          ),
                      const SizedBox(height: 16),
          // Afternoon
          _buildFlowItem(
            'Afternoon',
            afternoonStatus,
            afternoonIcon,
            afternoonColor,
          ),
          const SizedBox(height: 16),
          // Evening
          _buildFlowItem(
            'Evening',
            eveningStatus,
            eveningIcon,
            eveningColor,
          ),
          const SizedBox(height: 16),
          // Next shift hint
                      Text(
            'Next shift: $nextShiftMessage',
                        style: GoogleFonts.poppins(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF4A5568),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowItem(String period, String status, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(width: 12),
              Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$period: $status',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A202C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Get emoji for mood
  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'foody':
      case 'food':
        return '🍽️';
      case 'adventurous':
      case 'adventure':
        return '🏞️';
      case 'romantic':
        return '💕';
      case 'relaxed':
      case 'peaceful':
        return '😌';
      case 'excited':
        return '🎉';
      case 'energetic':
        return '⚡';
      case 'cultural':
        return '🎭';
      case 'social':
        return '👥';
      case 'cozy':
        return '☕';
      case 'creative':
        return '🎨';
      case 'contemplative':
        return '🧘';
      case 'happy':
        return '😊';
      case 'grateful':
        return '🙏';
      case 'inspired':
        return '💡';
      case 'wonder':
        return '🤩';
      default:
        return '✨';
    }
  }

  // Trending in Rotterdam section
  Widget _buildTrendingInRotterdamSection(AsyncValue<List<TrendingActivity>> trendingAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("🔥", style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              "Trending in Rotterdam",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A202C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        trendingAsync.when(
          data: (trending) {
            if (trending.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    const Text("😅", style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(
                      "No trending activities right now",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      textAlign: TextAlign.center,
                      ),
                    ],
                  ),
              );
            }
            return SizedBox(
              height: 220,
              child: _buildSuggestionCardsHorizontal(trending, 'exploring'),
            );
          },
          loading: () => Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2A6049),
                  ),
                ),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade200),
            ),
                  child: Column(
                    children: [
                const Text("😅", style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(
                  "Couldn't load trending activities",
                        style: GoogleFonts.poppins(
                    fontSize: 14,
                          color: Colors.grey[600],
                        ),
                  textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
              ),
      ],
    );
  }

  // Today's Insights section
  Widget _buildTodaysInsights(DailyMoodState dailyState) {
    final activities = dailyState.plannedActivities;
    final completed = activities.where((a) => a.status == ActivityStatus.completed).length;
    final upcoming = activities.where((a) => a.status == ActivityStatus.upcoming).length;
    final total = activities.length;
    
    // Calculate total time
    int totalHours = 0;
    for (final activity in activities) {
      final duration = activity.endTime.difference(activity.startTime);
      totalHours += duration.inHours;
    }
    
    // Get next activity info
    final nextActivity = activities
        .where((a) => a.status == ActivityStatus.upcoming)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    String nextActivityTitle = 'No upcoming activities';
    String nextActivityTime = '';
    String nextActivityWalk = '';
    
    if (nextActivity.isNotEmpty) {
      final next = nextActivity.first;
      nextActivityTitle = next.rawData['title'] ?? 'Next activity';
      final now = MoodyClock.now();
      final timeUntil = next.startTime.difference(now);
      if (timeUntil.inHours > 0) {
        nextActivityTime = 'In ${timeUntil.inHours} hours';
      } else if (timeUntil.inMinutes > 0) {
        nextActivityTime = 'In ${timeUntil.inMinutes} min';
      } else {
        nextActivityTime = 'Starting soon';
      }
      // Mock walk time - you can get this from activity data
      nextActivityWalk = '15 min walk';
    }
    
    // Determine focus time
    final now = MoodyClock.now();
    String focusTime = 'Evening focused';
    if (now.hour < 12) {
      focusTime = 'Morning focused';
    } else if (now.hour < 18) {
      focusTime = 'Afternoon focused';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Color(0xFF2A6049), size: 20),
              const SizedBox(width: 8),
              Text(
                "Today's Insights",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A202C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Activities planned
          Row(
            children: [
              const Icon(Icons.flag, size: 16, color: Color(0xFF4A5568)),
              const SizedBox(width: 8),
              Text(
                "$total activities planned",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF1A202C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Focus time and total hours
          Text(
            "$focusTime • $totalHours hours total",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          // Next activity
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Color(0xFF4A5568)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Next: $nextActivityTitle",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$nextActivityTime • $nextActivityWalk",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build horizontal scrollable suggestion cards
  Widget _buildSuggestionCardsHorizontal(List<TrendingActivity> trending, String currentMood) {
    if (trending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎯', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No suggestions yet',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon for personalized picks!',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: trending.length,
      itemBuilder: (context, index) {
        final activity = trending[index];
        return Container(
          width: 200,
          margin: EdgeInsets.only(
            right: index == trending.length - 1 ? 0 : 12,
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrendingDetailScreen(trending: activity),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image or emoji
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: activity.imageUrl.isNotEmpty
                        ? Image.network(
                            activity.imageUrl,
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: double.infinity,
                              height: 120,
                              color: const Color(0xFFEAF5EE),
                              child: Center(
                                child: Text(
                                  activity.emoji,
                                  style: const TextStyle(fontSize: 48),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFFEAF5EE),
                                  const Color(0xFFEAF5EE),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                activity.emoji,
                                style: const TextStyle(fontSize: 48),
                              ),
                            ),
                          ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A202C),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (activity.location.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  activity.location,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (activity.moodTag.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF5EE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              activity.moodTag,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF2A6049),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Add place to user's schedule
  void _addPlaceToSchedule(Place place, String timePeriod) async {
    try {
      if (kDebugMode) debugPrint('✅ Adding ${place.name} to $timePeriod');
      
      // Get scheduled activity service
      final scheduledActivityService = ref.read(scheduledActivityServiceProvider);
      
      // Convert time period to TimeSlot enum and calculate start time
      final now = MoodyClock.now();
      final today = DateTime(now.year, now.month, now.day);
      
      TimeSlot timeSlotEnum;
      DateTime startTime;
      int defaultHour;
      
      switch (timePeriod.toLowerCase()) {
        case 'morning':
          timeSlotEnum = TimeSlot.morning;
          defaultHour = 9; // 9 AM default
          startTime = today.add(Duration(hours: defaultHour));
          break;
        case 'afternoon':
          timeSlotEnum = TimeSlot.afternoon;
          defaultHour = 14; // 2 PM default
          startTime = today.add(Duration(hours: defaultHour));
          break;
        case 'evening':
          timeSlotEnum = TimeSlot.evening;
          defaultHour = 18; // 6 PM default
          startTime = today.add(Duration(hours: defaultHour));
          break;
        default:
          timeSlotEnum = TimeSlot.afternoon;
          defaultHour = 14;
          startTime = today.add(Duration(hours: defaultHour));
      }
      
      // Determine payment type based on place types
      PaymentType paymentType = PaymentType.free;
      if (place.types.contains('restaurant') || 
          place.types.contains('spa') || 
          place.types.contains('museum') ||
          place.types.contains('tourist_attraction')) {
        paymentType = PaymentType.reservation;
      }
      
      // Get image URL - use first photo if available, otherwise empty (will show emoji fallback in UI)
      final imageUrl = place.photos.isNotEmpty ? place.photos.first : '';
      
      // Create Activity from Place
      final activity = Activity(
        id: 'place_${place.id}_${MoodyClock.now().millisecondsSinceEpoch}',
        name: place.name,
        description: place.address ?? 'Visit ${place.name}',
        imageUrl: imageUrl,
        rating: place.rating > 0 ? place.rating : 4.5,
        startTime: startTime,
        duration: 120, // Default 2 hours
        timeSlot: timePeriod.toLowerCase(),
        timeSlotEnum: timeSlotEnum,
        tags: place.types.isNotEmpty ? place.types : ['explore'],
        location: LatLng(place.location.lat, place.location.lng),
        paymentType: paymentType,
        priceLevel: place.priceLevel != null ? '€${place.priceLevel}' : null,
      );
      
      // Save to database
      await scheduledActivityService.saveScheduledActivities([activity], isConfirmed: false);
      
      // Invalidate providers to refresh My Day screen
      ref.invalidate(scheduledActivityServiceProvider);
      ref.invalidate(scheduledActivitiesForTodayProvider);
      ref.invalidate(todayActivitiesProvider);
      
      if (kDebugMode) debugPrint('✅ Successfully added ${place.name} to $timePeriod schedule');
      
      // Show success message
      if (mounted) {
        showWanderMoodToast(
          context,
          message: '${place.name} added to your $timePeriod!',
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Error adding place to schedule: $e');
      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Failed to add ${place.name}. Please try again.',
          isError: true,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }
} 