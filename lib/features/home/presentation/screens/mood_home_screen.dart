import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui'; // Add this import for ImageFilter
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/auth/providers/user_provider.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/features/weather/providers/weather_provider.dart';
import 'package:wandermood/features/plans/presentation/screens/plan_loading_screen.dart';
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
import 'package:wandermood/features/home/presentation/screens/main_screen.dart'; // Import mainTabProvider from here
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/mood/presentation/screens/moody_hub_screen.dart';
import 'package:wandermood/features/mood/presentation/widgets/mood_action_choice_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:wandermood/core/providers/communication_style_provider.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_chat_header_subtitle.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/core/localization/localized_mood_labels.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/services/connectivity_service.dart';
import 'package:wandermood/core/utils/offline_feedback.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';

// WanderMood v2 — Moody chat modal (Screen 9), aligned with moody_chat_sheet.dart
const Color _mcSkyTint = Color(0xFFEDF5F9);
const Color _mcCream = Color(0xFFF5F0E8);
const Color _mcSky = Color(0xFFA8C8DC);
const Color _mcForest = Color(0xFF2A6049);
const Color _mcForestTint = Color(0xFFEBF3EE);
const Color _mcParchment = Color(0xFFE8E2D8);
const Color _mcCharcoal = Color(0xFF1E1C18);

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Add personalization state
  String _personalizedGreeting = '';
  String _contextualSubtext = '';
  DateTime? _targetDateFromRoute;
  DateTime _selectedPlanningDate = DateTime.now();
  bool _forceShowMoodSelector = false;
  bool _hasResolvedRouteDate = false;

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    // Removed _updatePersonalizedGreeting() - no auto API calls on init
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasResolvedRouteDate) {
      _hasResolvedRouteDate = true;
      _targetDateFromRoute = _resolveTargetDateFromRoute();
      _selectedPlanningDate = _targetDateFromRoute ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _updateGreeting() {
    final hour = MoodyClock.now().hour;
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
  }

  /// Time-of-day phrase for the hero line (replaces "today?")
  String _getTimeOfDayPhrase(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = MoodyClock.now().hour;
    if (hour >= 5 && hour < 12) return l10n.moodHubThisMorning;
    if (hour >= 12 && hour < 17) return l10n.moodHubThisAfternoon;
    if (hour >= 17 && hour < 21) return l10n.moodHubThisEvening;
    return l10n.moodHubTonight;
  }

  /// Greeting text based on onboarding communication style (less formal options)
  String _getStyleBasedGreeting(
      BuildContext context, CommunicationStyle style, String? firstName) {
    final l10n = AppLocalizations.of(context)!;
    final name = (firstName != null && firstName.isNotEmpty) ? firstName : null;
    switch (style) {
      case CommunicationStyle.energetic:
        return name != null
            ? l10n.moodHubGreetingBestie(name)
            : l10n.moodHubGreetingBestie(l10n.moodyIntroNameFallback);
      case CommunicationStyle.friendly:
        return name != null
            ? l10n.moodHubGreetingFriendly(name)
            : l10n.moodHubGreetingHeyThere;
      case CommunicationStyle.professional:
        {
          final hour = MoodyClock.now().hour;
          final greeting = hour >= 5 && hour < 12
              ? l10n.goodMorning
              : hour >= 12 && hour < 17
                  ? l10n.goodAfternoon
                  : hour >= 17 && hour < 21
                      ? l10n.goodEvening
                      : l10n.heyNightOwl;
          return name != null
              ? l10n.moodHubGreetingProfessional(greeting, name)
              : greeting;
        }
      case CommunicationStyle.direct:
        return name != null
            ? l10n.moodHubGreetingDirect(name)
            : l10n.moodHubGreetingHi;
    }
  }

  /// Reads current GPS position + city from providers, with Rotterdam fallback.
  Future<({double lat, double lng, String city})> _getUserLocation() async {
    final position = await ref.read(userLocationProvider.future);
    final city = ref.read(locationNotifierProvider).value ?? 'Rotterdam';
    return (
      lat: position?.latitude ?? 51.9225,
      lng: position?.longitude ?? 4.4792,
      city: city,
    );
  }

  void _toggleMood(MoodOption mood) {
    setState(() {
      if (_selectedMoods.contains(mood.label)) {
        _selectedMoods.remove(mood.label);
      } else if (_selectedMoods.length < 3) {
        _selectedMoods.add(mood.label);
      } else {
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.moodHubSelectUpTo('3'),
          isError: true,
        );
      }
    });
  }

  Future<void> _generatePlan() async {
    if (_selectedMoods.isEmpty) return;

    final connected = await ref.read(connectivityServiceProvider).isConnected;
    if (!context.mounted) return;
    if (!connected) {
      showOfflineSnackBar(context);
      return;
    }

    print('🎯 Generating plan for moods: $_selectedMoods');

    // 🎯 Save mood selection state for hub
    ref.read(dailyMoodStateNotifierProvider.notifier).setMoodSelection(
          mood: _selectedMoods.first,
          selectedMoods: _selectedMoods.toList(),
          conversationId: _conversationId,
        );

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlanLoadingScreen(
            selectedMoods: _selectedMoods.toList(),
            targetDate: _selectedPlanningDate,
          ),
        ),
      );
    }
  }

  Future<void> _getAIRecommendations() async {
    final connected = await ref.read(connectivityServiceProvider).isConnected;
    if (!mounted) return;
    if (!connected) {
      showOfflineSnackBar(context);
      return;
    }

    setState(() {
      _isAILoading = true;
    });

    try {
      print(
          '🤖 Getting AI recommendations for moods: ${_selectedMoods.toList()}');

      // Extract conversation context from chat messages
      List<String> conversationContext = [];
      if (_chatMessages.isNotEmpty) {
        conversationContext = _chatMessages
            .map((msg) => '${msg.isUser ? "User" : "Moody"}: ${msg.message}')
            .toList();
        print(
            '📝 Including ${conversationContext.length} conversation messages');
      }

      final loc = await _getUserLocation();
      final response = await WanderMoodAIService.getRecommendations(
        moods: _selectedMoods.toList(),
        latitude: loc.lat,
        longitude: loc.lng,
        city: loc.city,
        preferences: {
          'timeSlot': _getTimeSlot(),
          'groupSize': 1,
        },
        conversationId: _conversationId,
        conversationContext: conversationContext,
      );

      print(
          '✅ Got ${response.recommendations.length} AI recommendations (${conversationContext.isNotEmpty ? "with conversation context" : "without context"})');

      // Navigate to PlanLoadingScreen first
      if (mounted) {
        print('🧭 Navigating to plan loading screen');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanLoadingScreen(
              selectedMoods: _selectedMoods.toList(),
              targetDate: _selectedPlanningDate,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error getting AI recommendations: $e');
      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Error: $e',
          isError: true,
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

  DateTime? _resolveTargetDateFromRoute() {
    try {
      final extra = GoRouterState.of(context).extra;
      if (extra is Map && extra['targetDate'] is String) {
        final parsed = DateTime.tryParse(extra['targetDate'] as String);
        if (parsed == null) return null;
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    } catch (_) {
      // Keep null when route state is unavailable.
    }
    return null;
  }

  // Helper to get current time slot
  String _getTimeSlot() {
    final hour = MoodyClock.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
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
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
        height: MediaQuery.of(context).size.height *
            0.25, // Reduced height to fix overflow
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
              AppLocalizations.of(context)!.homeSelectLocation,
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
                  color: const Color(0xFFEAF5EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Color(0xFF2A6049),
                ),
              ),
              title: Text(
                AppLocalizations.of(context)!.homeCurrentLocation,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.homeUsingGps,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () async {
                final l10n = AppLocalizations.of(context)!;
                // Close the dialog
                Navigator.pop(context);
                // Show loading message
                showWanderMoodToast(
                  context,
                  message: l10n.homeGettingLocation,
                  duration: const Duration(seconds: 1),
                );
                // Trigger location update
                final location = await ref
                    .read(locationNotifierProvider.notifier)
                    .getCurrentLocation();
                // Show result message
                showWanderMoodToast(
                  context,
                  message: l10n.homeLocationResult(location ?? l10n.homeLocationNotFound),
                  duration: const Duration(seconds: 3),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show dialog for talking to Moody
  void _showMoodActionChoiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MoodActionChoiceDialog(
        onUpdatePlan: () {
          // Reset mood selection to show mood selection screen
          // After mood selection, it will navigate to plan loading
          ref
              .read(dailyMoodStateNotifierProvider.notifier)
              .resetMoodSelection();
        },
        onJustChangeMood: () {
          // Just reset mood selection without navigating to plan loading
          // User can pick new moods but won't regenerate activities
          ref
              .read(dailyMoodStateNotifierProvider.notifier)
              .resetMoodSelection();
          // TODO: Add flag to skip plan generation after mood selection
        },
      ),
    );
  }

  void _showMoodyTalkDialog(BuildContext context) {
    // Create conversation ID only if it doesn't exist (persistent conversation)
    if (_conversationId == null) {
      _conversationId = 'conv_${MoodyClock.now().millisecondsSinceEpoch}';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      builder: (context) {
        final mq = MediaQuery.of(context);
        final topInset = mq.padding.top;
        final bottomObstruction = mq.viewInsets.bottom > 0
            ? mq.viewInsets.bottom
            : mq.padding.bottom;
        final sheetHeight = (mq.size.height - topInset - bottomObstruction)
            .clamp(280.0, mq.size.height);

        return Padding(
          padding: EdgeInsets.only(top: topInset),
          child: SizedBox(
            height: sheetHeight,
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Column(
                        children: const [
                          Expanded(
                              flex: 5, child: ColoredBox(color: _mcSkyTint)),
                          Expanded(flex: 5, child: ColoredBox(color: _mcCream)),
                        ],
                      ),
                      Column(
                        children: [
                          // Enhanced header with friendly aesthetics
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _mcSkyTint.withOpacity(0.85),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Row(
                                    children: [
                                      // Enhanced Moody avatar with modern styling
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _mcSky,
                                        ),
                                        child: const Center(
                                          child: MoodyCharacter(size: 32),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Title and personalized status
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppLocalizations.of(context)!.chatSheetMoodyName,
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
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: _mcForest,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    moodyChatTravelBestieSubtitle(
                                                      l10n: AppLocalizations.of(
                                                          context)!,
                                                      city: ref
                                                          .watch(
                                                              locationNotifierProvider)
                                                          .value,
                                                      style: ref
                                                          .watch(
                                                              communicationStyleProvider)
                                                          .style,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      color: const Color(
                                                          0xFF4A5568),
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
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
                                            color: _mcSky.withOpacity(0.35),
                                            border: Border.all(
                                              color: _mcSky.withOpacity(0.65),
                                              width: 2,
                                            ),
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 20),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.92),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color:
                                                  _mcParchment.withOpacity(0.9),
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
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          itemCount: _chatMessages.length,
                                          itemBuilder: (context, index) {
                                            final message =
                                                _chatMessages[index];
                                            return _buildMessageBubble(message);
                                          },
                                        ),
                                      ),

                                      // Enhanced typing indicator with personality
                                      if (_isAILoading)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 20),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: _mcSky,
                                                ),
                                                child: const Center(
                                                  child:
                                                      MoodyCharacter(size: 22),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 20,
                                                          vertical: 14),
                                                  decoration: BoxDecoration(
                                                    color: _mcSkyTint
                                                        .withOpacity(0.95),
                                                    border: Border.all(
                                                        color: _mcParchment
                                                            .withOpacity(0.6)),
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(20),
                                                      topRight:
                                                          Radius.circular(20),
                                                      bottomRight:
                                                          Radius.circular(20),
                                                      bottomLeft:
                                                          Radius.circular(4),
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: _mcForest
                                                            .withOpacity(0.06),
                                                        blurRadius: 12,
                                                        offset:
                                                            const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                  Color>(
                                                            _mcForest
                                                                .withOpacity(
                                                                    0.75),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          'Moody is crafting something special...',
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 15,
                                                            color: const Color(
                                                                0xFF2D3748),
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500,
                                                            fontStyle:
                                                                FontStyle
                                                                    .italic,
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
                                    ],
                                  ),
                          ),

                          // Enhanced input area with modern styling
                          Container(
                            padding: const EdgeInsets.only(
                              left: 24,
                              right: 24,
                              top: 24,
                              bottom: 24,
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
                                  child: TextField(
                                    controller: _chatController,
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(context)!.chatSheetInputHint,
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.grey[500],
                                        fontSize: 16,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 18,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(28),
                                        borderSide: BorderSide(
                                          color: _mcParchment,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(28),
                                        borderSide: const BorderSide(
                                          color: _mcForest,
                                          width: 2,
                                        ),
                                      ),
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.psychology_outlined,
                                          color: _mcForest.withOpacity(0.75),
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: _mcCharcoal,
                                    ),
                                    onSubmitted: (text) =>
                                        _sendChatMessageInModal(
                                            text, setModalState),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Enhanced send button with modern styling
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [_mcForest, _mcForest],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(26),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _mcForest.withOpacity(0.3),
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
                                          : () => _sendChatMessageInModal(
                                              _chatController.text,
                                              setModalState),
                                      child: Center(
                                        child: _isAILoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
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
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Build message bubble widget with modern iMessage-like style
  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            // Moody's Avatar with enhanced modern styling
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _mcSky,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: message.isUser
                        ? const LinearGradient(
                            colors: [_mcForest, Color(0xFF347558)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [_mcForestTint, _mcSkyTint],
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
                            ? _mcForest.withOpacity(0.2)
                            : _mcForest.withOpacity(0.06),
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
                      color: message.isUser ? Colors.white : _mcCharcoal,
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
                  colors: [_mcForest, Color(0xFF347558)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _mcForest.withOpacity(0.2),
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
    final now = MoodyClock.now();
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
  Future<void> _sendChatMessageInModal(
      String message, StateSetter setModalState) async {
    if (message.trim().isEmpty || _isAILoading) return;

    print('🚀 Starting chat message process: "${message.trim()}"');

    // Add user message to chat
    setModalState(() {
      _chatMessages.add(ChatMessage(
        message: message.trim(),
        isUser: true,
        timestamp: MoodyClock.now(),
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

      final loc = await _getUserLocation();
      final priorTurns = _chatMessages.length > 1
          ? _chatMessages
              .sublist(0, _chatMessages.length - 1)
              .map((m) => {
                    'role': m.isUser ? 'user' : 'assistant',
                    'content': m.message,
                  })
              .toList()
          : null;
      final response = await WanderMoodAIService.chat(
        message: message.trim(),
        conversationId: _conversationId,
        moods: _selectedMoods.toList(),
        latitude: loc.lat,
        longitude: loc.lng,
        city: loc.city,
        clientTurns: priorTurns,
        languageCode: Localizations.localeOf(context).languageCode,
      );

      debugPrint('✅ Moody AI response received successfully');

      // Validate response
      if (response.message.isEmpty) {
        throw Exception('Empty response message from AI service');
      }

      // Add AI response to chat
      setModalState(() {
        _chatMessages.add(ChatMessage(
          message: response.message,
          isUser: false,
          timestamp: MoodyClock.now(),
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
          message:
              'Oops! I\'m having trouble connecting right now. Can you try again? 🤔',
          isUser: false,
          timestamp: MoodyClock.now(),
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
        timestamp: MoodyClock.now(),
      ));
      _isAILoading = true;
    });

    // Clear the input immediately
    _chatController.clear();

    try {
      final loc = await _getUserLocation();
      final priorTurns = _chatMessages.length > 1
          ? _chatMessages
              .sublist(0, _chatMessages.length - 1)
              .map((m) => {
                    'role': m.isUser ? 'user' : 'assistant',
                    'content': m.message,
                  })
              .toList()
          : null;
      final response = await WanderMoodAIService.chat(
        message: message.trim(),
        conversationId: _conversationId,
        moods: _selectedMoods.toList(),
        latitude: loc.lat,
        longitude: loc.lng,
        city: loc.city,
        clientTurns: priorTurns,
        languageCode: Localizations.localeOf(context).languageCode,
      );

      print('✅ Moody AI response: ${response.message}');

      // Add AI response to chat
      if (mounted) {
        setState(() {
          _chatMessages.add(ChatMessage(
            message: response.message,
            isUser: false,
            timestamp: MoodyClock.now(),
          ));
        });
      }
    } catch (e) {
      print('❌ Chat error: $e');

      // Add error message to chat
      if (mounted) {
        setState(() {
          _chatMessages.add(ChatMessage(
            message: AppLocalizations.of(context)!.homeChatErrorRetry,
            isUser: false,
            timestamp: MoodyClock.now(),
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
    final hour = MoodyClock.now().hour;
    final isWeekend = MoodyClock.now().weekday >= 6;
    final dayOfWeek = MoodyClock.now().weekday;

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
    // Watch the live Supabase source so the "already planned" card disappears
    // immediately when the user deletes activities in My Day.
    ref.watch(scheduledActivitiesForTodayProvider);

    return _buildMoodSelectionScreen(
      context,
      ref,
      locationAsync,
      userData,
      weatherAsync,
      dailyMoodState,
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
          backgroundColor:
              _mcCream, // wmCream — match Explore / My Day (solid, no swirl)
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: location + weather (no pills, plain text + icons)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _showLocationDialog(context, ref),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF2A6049),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Consumer(
                                    builder: (context, ref, child) {
                                      final locationAsync =
                                          ref.watch(locationNotifierProvider);
                                      return locationAsync.when(
                                        data: (location) => Text(
                                          location ?? '...',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        loading: () => Text(
                                          '...',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        error: (_, __) => Text(
                                          'Location',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.black54,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _showWeatherDetails(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 4),
                          child: Consumer(
                            builder: (context, ref, child) {
                              final weatherAsync = ref.watch(weatherProvider);
                              return weatherAsync.when(
                                data: (weather) {
                                  if (weather == null)
                                    return _buildDefaultWeather();
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      WmNetworkImage(
                                        weather.iconUrl,
                                        width: 20,
                                        height: 20,
                                        errorBuilder: (_, __, ___) => Icon(
                                          _getWeatherIcon(weather.condition),
                                          color: const Color(0xFFFFB300),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${weather.temperature.round()}°',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
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
                // Greeting: based on onboarding communication style (e.g. "Hey bestie!" / "Hey, Name!" / "Good evening")
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final styleState = ref.watch(communicationStyleProvider);
                      final profileData = ref.watch(profileProvider);
                      final firstName =
                          profileData.valueOrNull?.fullName?.split(' ').first;
                      final text = _getStyleBasedGreeting(
                          context, styleState.style, firstName);
                      return Text(
                        text,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: const Color(0xFF1A202C),
                          height: 1.25,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                // Hero: "What's your mood" + time-based "this morning/afternoon/evening/tonight?" (green, italic)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .moodHubWhatIsYourMood,
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A202C),
                                height: 1.25,
                              ),
                            ),
                            Text(
                              _getTimeOfDayPhrase(context),
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                                color: const Color(
                                    0xFF2A6049), // wmForest — v2 design system
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: MoodyCharacter(
                          size: 96,
                          mood: _selectedMoods.isEmpty ? 'default' : 'happy',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Contextual banner - time-based localized message
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    final hour = MoodyClock.now().hour;
                    final message = hour >= 5 && hour < 12
                        ? l10n.moodHubBannerMorning
                        : hour >= 12 && hour < 17
                            ? l10n.moodHubBannerAfternoon
                            : hour >= 17 && hour < 21
                                ? l10n.moodHubBannerEvening
                                : l10n.moodHubBannerNight;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF26273A)
                            .withOpacity(0.9), // dark neutral, not green
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            '😊',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              message,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color:
                                    Colors.white, // white letters on dark card
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (!_hasPlanForSelectedDate(dailyMoodState))
                  _buildDateSelector(),
                if (!_hasPlanForSelectedDate(dailyMoodState))
                  const SizedBox(height: 10),
                if (_hasPlanForSelectedDate(dailyMoodState) &&
                    !_forceShowMoodSelector)
                  const SizedBox(height: 8),
                if (_hasPlanForSelectedDate(dailyMoodState) &&
                    !_forceShowMoodSelector)
                  _buildAlreadyPlannedState(
                    _selectedPlanningDate,
                    _activityCountForSelectedDate(dailyMoodState),
                  ),
                if (_hasPlanForSelectedDate(dailyMoodState) &&
                    !_forceShowMoodSelector)
                  const SizedBox(height: 12),

                // Put mood tiles and button in a single scrollable container
                if (!_hasPlanForSelectedDate(dailyMoodState) ||
                    _forceShowMoodSelector) ...[
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        // Selected moods indicator
                        if (_selectedMoods.isNotEmpty) ...[
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!
                                      .moodHubSelectedMoods,
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
                            final moodOptionsAsync =
                                ref.watch(moodOptionsProvider);

                            return moodOptionsAsync.when(
                              data: (moodOptions) {
                                // Use database mood options if available, otherwise use fallback
                                final finalMoodOptions = moodOptions.isNotEmpty
                                    ? moodOptions
                                    : _getFallbackMoodOptions();

                                if (finalMoodOptions.isEmpty) {
                                  return Container(
                                    height: 200,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.mood,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .moodHubNoMoodOptions,
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
                                  crossAxisCount:
                                      4, // Back to 4 columns for balanced proportions
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                  mainAxisSpacing:
                                      14, // Slightly increased from original 12
                                  crossAxisSpacing:
                                      14, // Slightly increased from original 16
                                  childAspectRatio:
                                      0.95, // Slightly taller cards (was 1.0)
                                  children: finalMoodOptions.map((mood) {
                                    final isSelected =
                                        _selectedMoods.contains(mood.label);
                                    return GestureDetector(
                                      onTap: () => _toggleMood(mood),
                                      child: _buildMoodTile(
                                          context, mood, isSelected),
                                    );
                                  }).toList(),
                                );
                              },
                              loading: () =>
                                  _buildFallbackMoodGrid(), // Show fallback while loading
                              error: (error, stack) =>
                                  _buildFallbackMoodGrid(), // Show fallback on error
                            );
                          },
                        ),

                        // CTA Button directly below grid in the same scroll view
                        Container(
                          width: double.infinity,
                          height: 56,
                          margin: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 12, top: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2A6049)
                                    .withOpacity(0.25), // wmForest glow
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _selectedMoods.isEmpty || _isAILoading
                                ? null
                                : () => _generatePlan(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedMoods.isEmpty ||
                                      _isAILoading
                                  ? const Color(
                                      0xFFD0D0D0) // Light gray for inactive/loading state
                                  : const Color(
                                      0xFF2A6049), // wmForest — v2 design system
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
                                        AppLocalizations.of(context)!
                                            .moodHubMoodyThinking,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    AppLocalizations.of(context)!
                                        .moodHubCreatePlan,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        // Back to Hub button - always show when on mood selection screen
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 30),
                          child: TextButton(
                            onPressed: () async {
                              // MoodHomeScreen always shows this full-screen mood picker; updating
                              // provider alone does not switch UI. Navigate to main Moody hub tab.
                              if (dailyMoodState.isInMoodChangeMode) {
                                await ref
                                    .read(
                                        dailyMoodStateNotifierProvider.notifier)
                                    .returnToHub();
                              }
                              if (!context.mounted) return;
                              context.go('/main?tab=2');
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
                                  AppLocalizations.of(context)!
                                      .moodHubBackToHub,
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
              ],
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

  Widget _buildDateSelector() {
    final l10n = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final days = List.generate(7, (i) => today.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l10n.moodyHubPlanForWhen,
            style: GoogleFonts.poppins(
              color: _mcParchment,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final day = days[index];
              final isSelected = _isSameDay(day, _selectedPlanningDate);
              final isToday = index == 0;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedPlanningDate = day;
                  _forceShowMoodSelector = false;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _mcForest : Colors.white,
                    border: Border.all(
                      color: isSelected ? _mcForest : _mcParchment,
                      width: isSelected ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isToday ? l10n.timeLabelToday : _localizedShortWeekday(day),
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : _mcCharcoal,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!isToday)
                        Text(
                          _localizedDayAndShortMonth(day),
                          style: GoogleFonts.poppins(
                            color: isSelected ? Colors.white.withValues(alpha: 0.85) : _mcParchment,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _localeTag() => Localizations.localeOf(context).toString();

  String _localizedShortWeekday(DateTime date) =>
      DateFormat.E(_localeTag()).format(date);

  String _localizedDayAndShortMonth(DateTime date) =>
      DateFormat('d MMM', _localeTag()).format(date);

  bool _hasPlanForSelectedDate(DailyMoodState state) {
    // Read the live Supabase activities so this reflects deletions immediately.
    final liveActivities = ref
        .read(scheduledActivitiesForTodayProvider)
        .maybeWhen(data: (list) => list, orElse: () => <Map<String, dynamic>>[]);
    if (liveActivities.isNotEmpty) return true;
    // Fallback to stale state while the provider is still loading.
    if (state.plannedActivities.isEmpty) return false;
    return state.plannedActivities.any((activity) =>
        _isSameDay(activity.startTime, _selectedPlanningDate));
  }

  int _activityCountForSelectedDate(DailyMoodState state) {
    final liveActivities = ref
        .read(scheduledActivitiesForTodayProvider)
        .maybeWhen(data: (list) => list, orElse: () => <Map<String, dynamic>>[]);
    if (liveActivities.isNotEmpty) return liveActivities.length;
    if (state.plannedActivities.isEmpty) return 0;
    return state.plannedActivities
        .where((activity) => _isSameDay(activity.startTime, _selectedPlanningDate))
        .length;
  }

  Widget _buildAlreadyPlannedState(DateTime date, int activityCount) {
    final l10n = AppLocalizations.of(context)!;
    final dayName = DateFormat.EEEE(_localeTag()).format(date);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _mcForestTint,
        border: Border.all(color: _mcForest.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: _mcForest, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.moodHomeAlreadyPlannedTitle(dayName),
                  style: GoogleFonts.poppins(
                    color: _mcForest,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.moodHomeActivitiesReadyCount(activityCount),
              style: GoogleFonts.poppins(
                color: _mcCharcoal.withValues(alpha: 0.78),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToMyDayForDate(date),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: _mcForest,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: Text(
                        l10n.moodHomeViewPlan,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _forceShowMoodSelector = true),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _mcForest),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: Text(
                        l10n.moodHomePlanAgain,
                        style: GoogleFonts.poppins(
                          color: _mcForest,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToMyDayForDate(DateTime date) {
    context.go('/main?tab=0', extra: {
      'targetDate': DateTime(date.year, date.month, date.day).toIso8601String(),
    });
  }

  /// Returns localized label for a mood (by English label key).
  String _localizedMoodLabel(BuildContext context, String label) {
    final l10n = AppLocalizations.of(context)!;
    return localizedMoodDisplayLabel(l10n, label);
  }

  /// Builds a single mood tile with pastel base, frosted-glass overlay, and soft floating shadow.
  Widget _buildMoodTile(
      BuildContext context, MoodOption mood, bool isSelected) {
    const double tileRadius = 20;
    // Use mood color as-is (pastel palette); glass overlay adds the sheen
    final Color pastelBase = mood.color;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tileRadius),
        color: pastelBase,
        border: Border.all(
          color: isSelected
              ? mood.color.withOpacity(0.7)
              : Colors.white.withOpacity(0.6),
          width: isSelected ? 2.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(3, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(1, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tileRadius),
        child: Stack(
          children: [
            // Frosted glass overlay with top-left sheen
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.35),
                      Colors.white.withOpacity(0.08),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(mood.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _localizedMoodLabel(context, mood.label),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
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
                      color: Color(0xFF2A6049),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Fallback mood options when database fails (pastel palette with glassy tiles)
  List<MoodOption> _getFallbackMoodOptions() {
    return [
      MoodOption(
        id: 'happy',
        label: 'Happy',
        emoji: '😊',
        colorHex: '#FCDF7E', // soft pale yellow
        displayOrder: 1,
        isActive: true,
        createdAt: MoodyClock.now(),
        updatedAt: MoodyClock.now(),
      ),
      MoodOption(
        id: 'adventurous',
        label: 'Adventurous',
        emoji: '🚀',
        colorHex: '#F79F9C', // muted light coral
        displayOrder: 2,
        isActive: true,
        createdAt: MoodyClock.now(),
        updatedAt: MoodyClock.now(),
      ),
      MoodOption(
        id: 'relaxed',
        label: 'Relaxed',
        emoji: '😌',
        colorHex: '#72DED5', // light teal aqua
        displayOrder: 3,
        isActive: true,
        createdAt: MoodyClock.now(),
        updatedAt: MoodyClock.now(),
      ),
      MoodOption(
        id: 'energetic',
        label: 'Energetic',
        emoji: '⚡',
        colorHex: '#84C8F0', // gentle sky blue
        displayOrder: 4,
        isActive: true,
        createdAt: MoodyClock.now(),
        updatedAt: MoodyClock.now(),
      ),
      MoodOption(
        id: 'romantic',
        label: 'Romantic',
        emoji: '💕',
        colorHex: '#F4A9D3', // soft light pink
        displayOrder: 5,
        isActive: true,
        createdAt: MoodyClock.now(),
        updatedAt: MoodyClock.now(),
      ),
      MoodOption(
        id: 'social',
        label: 'Social',
        emoji: '👥',
        colorHex: '#ECCBA3', // pale warm beige
        displayOrder: 6,
        isActive: true,
        createdAt: MoodyClock.now(),
        updatedAt: MoodyClock.now(),
      ),
      MoodOption(
        id: 'cultural',
        label: 'Cultural',
        emoji: '🎭',
        colorHex: '#BFA8E0', // light pastel purple / lavender
        displayOrder: 7,
        isActive: true,
        createdAt: MoodyClock.now(),
        updatedAt: MoodyClock.now(),
      ),
      MoodOption(
        id: 'curious',
        label: 'Curious',
        emoji: '🔍',
        colorHex: '#EFB887', // muted light peach
        displayOrder: 8,
        isActive: true,
        createdAt: MoodyClock.now(),
        updatedAt: MoodyClock.now(),
      ),
      MoodOption(
        id: 'cozy',
        label: 'Cozy',
        emoji: '☕',
        colorHex: '#D2A08B', // soft light brown / taupe
        displayOrder: 9,
        isActive: true,
        createdAt: MoodyClock.now(),
        updatedAt: MoodyClock.now(),
      ),
      MoodOption(
        id: 'excited',
        label: 'Excited',
        emoji: '🤩',
        colorHex: '#A3E0A3', // soft pastel green
        displayOrder: 10,
        isActive: true,
        createdAt: MoodyClock.now(),
        updatedAt: MoodyClock.now(),
      ),
      MoodOption(
        id: 'foody',
        label: 'Foody',
        emoji: '🍽️',
        colorHex: '#FFD3A3', // soft pastel orange / peach
        displayOrder: 11,
        isActive: true,
        createdAt: MoodyClock.now(),
        updatedAt: MoodyClock.now(),
      ),
      MoodOption(
        id: 'surprise',
        label: 'Surprise',
        emoji: '😲',
        colorHex: '#C0D3E0', // soft pastel blue / lavender
        displayOrder: 12,
        isActive: true,
        createdAt: MoodyClock.now(),
        updatedAt: MoodyClock.now(),
      ),
    ];
  }

  // Build fallback mood grid widget
  Widget _buildFallbackMoodGrid() {
    final fallbackMoodOptions = _getFallbackMoodOptions();

    return GridView.count(
      crossAxisCount: 4, // Back to 4 columns for balanced proportions
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      mainAxisSpacing: 14, // Slightly increased from original 12
      crossAxisSpacing: 14, // Slightly increased from original 16
      childAspectRatio: 0.95, // Slightly taller cards (was 1.0)
      children: fallbackMoodOptions.map((mood) {
        final isSelected = _selectedMoods.contains(mood.label);
        return GestureDetector(
          onTap: () => _toggleMood(mood),
          child: _buildMoodTile(context, mood, isSelected),
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
    } else if (lowercaseCondition.contains('rain') ||
        lowercaseCondition.contains('drizzle')) {
      return Icons.water_drop;
    } else if (lowercaseCondition.contains('snow')) {
      return Icons.ac_unit;
    } else if (lowercaseCondition.contains('storm') ||
        lowercaseCondition.contains('thunder')) {
      return Icons.thunderstorm;
    } else if (lowercaseCondition.contains('mist') ||
        lowercaseCondition.contains('fog')) {
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
