import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/plans/domain/enums/time_slot.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/features/plans/widgets/activity_detail_screen.dart';
import 'package:wandermood/features/plans/services/activity_generator_service.dart';
import 'package:wandermood/core/services/wandermood_ai_service.dart' as ai_service;
import 'package:wandermood/core/models/ai_recommendation.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/core/extensions/string_extensions.dart';
import 'package:wandermood/features/places/presentation/screens/place_detail_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/home/presentation/screens/main_screen.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/home/domain/enums/moody_feature.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/plans/presentation/widgets/day_plan_activity_card.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/core/services/distance_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class DayPlanScreen extends ConsumerStatefulWidget {
  final List<Activity> activities;
  final List<String> selectedMoods;
  final String moodyMessage;
  final String moodyReasoning;

  const DayPlanScreen({
    super.key,
    required this.activities,
    this.selectedMoods = const [],
    this.moodyMessage = '',
    this.moodyReasoning = '',
  });

  @override
  ConsumerState<DayPlanScreen> createState() => _DayPlanScreenState();
}

class _DayPlanScreenState extends ConsumerState<DayPlanScreen> {
  /// Mutable list of exactly 3 activities (morning, afternoon, evening) for swap support.
  late List<Activity> _activities;
  /// IDs of activities already individually added via each card's button.
  final Set<String> _addedActivityIds = {};
  int get _addedCount => _addedActivityIds.length;

  @override
  void initState() {
    super.initState();
    _activities = List.from(widget.activities);
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, MMMM d, y');
    return formatter.format(now);
  }

  void _refreshMyDayProviders(WidgetRef ref) {
    ref.invalidate(scheduledActivityServiceProvider);
    ref.invalidate(scheduledActivitiesForTodayProvider);
    ref.invalidate(todayActivitiesProvider);
  }

  /// Opens My Day without inserting new rows (per-card adds stay the only new items).
  Future<void> _navigateToMyDayOnly(WidgetRef ref) async {
    _refreshMyDayProviders(ref);
    if (!mounted) return;
    ref.read(mainTabProvider.notifier).state = 0;
    context.goNamed('main', extra: {'tab': 0});
  }

  /// Adds only the activities the user has NOT already added individually.
  /// Does NOT clear existing scheduled activities — preserves what was already added.
  Future<void> _addPlanToMyDay(WidgetRef ref) async {
    if (_activities.isEmpty) return;
    try {
      final remaining = _activities
          .where((a) => !_addedActivityIds.contains(a.id))
          .toList();
      final didSave = remaining.isNotEmpty;
      if (didSave) {
        final service = ref.read(scheduledActivityServiceProvider);
        await service.saveScheduledActivities(remaining, isConfirmed: false);
      }
      _refreshMyDayProviders(ref);
      if (!mounted) return;
      ref.read(mainTabProvider.notifier).state = 0;
      context.goNamed('main', extra: {'tab': 0});
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      if (didSave) {
        showWanderMoodToast(context, message: l10n.dayPlanPlanAddedToMyDay);
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      showWanderMoodToast(
        context,
        message: l10n.dayPlanAddPlanFailed,
        isError: true,
      );
    }
  }

  void _refreshActivity(Activity activity) async {
    // Check if user has reached the limit
    if (activity.refreshCount >= 3) {
      final l10n = AppLocalizations.of(context)!;
      showWanderMoodToast(
        context,
        message: l10n.dayPlanAllAlternativesUsed,
      );
      return;
    }

    try {
      // Show loading feedback
      final l10nLoading = AppLocalizations.of(context)!;
      showWanderMoodToast(
        context,
        message: l10nLoading.dayPlanFindingOptions(activity.name),
        duration: const Duration(seconds: 3),
      );

      // 🤖 USE MOODY AI FOR ALTERNATIVE GENERATION
      debugPrint('🤖 Asking Moody AI for alternative activity for ${activity.name}...');
      
      // Extract mood from activity tags or use default
      final moods = activity.tags.where((tag) => 
        ['Foody', 'Adventurous', 'Relaxed', 'Cultural', 'Social', 'Active', 'Creative', 'Romantic'].contains(tag)
      ).toList();
      final selectedMoods = moods.isNotEmpty ? moods : ['Foody'];
      
      // 🤖 GET AI RECOMMENDATION FOR ALTERNATIVE
      final aiResponse = await ai_service.WanderMoodAIService.getRecommendations(
        moods: selectedMoods,
        latitude: activity.location.latitude,
        longitude: activity.location.longitude,
        city: 'Rotterdam',
        preferences: {
          'timeSlot': activity.timeSlot,
          'groupSize': 1,
          'budget': 100,
        },
      );

      Activity? replacementActivity;
      if (aiResponse.recommendations.isNotEmpty) {
        // Find a recommendation different from the current activity
        final alternatives = aiResponse.recommendations.where((rec) => 
          rec.name != activity.name
        ).toList();
        
        if (alternatives.isNotEmpty) {
          final selectedRec = alternatives.first;
          final recPlaceId = _extractPlaceIdFromRecommendation(selectedRec);
          replacementActivity = Activity(
            id: 'ai_alt_${DateTime.now().millisecondsSinceEpoch}_${selectedRec.name?.hashCode ?? 0}',
            name: selectedRec.name ?? 'AI Alternative',
            description: selectedRec.description ?? 'Alternative recommended by Moody AI',
            timeSlot: activity.timeSlot, // Keep same time slot
            timeSlotEnum: activity.timeSlotEnum,
            duration: activity.duration, // Keep same duration
            location: _extractLocationFromRecommendation(selectedRec, activity.location.latitude, activity.location.longitude),
            paymentType: _parsePaymentType(selectedRec.cost ?? '€€'),
            imageUrl: selectedRec.imageUrl ?? _getFallbackImageForType(selectedRec.type ?? ''),
            rating: selectedRec.rating ?? 4.5,
                         tags: [
              ...selectedMoods.map((mood) => mood),
              selectedRec.type ?? 'Restaurant',
              'Premium Choice ⭐',
            ],
            startTime: activity.startTime, // Keep same start time
            priceLevel: _parsePriceLevel(selectedRec.cost ?? '€€'),
            placeId: recPlaceId,
            refreshCount: 0, // Reset for new activity
          );
        }
      }
      
      if (replacementActivity != null && replacementActivity.placeId != null && replacementActivity.placeId!.isNotEmpty) {
        debugPrint('✅ Generated AI alternative activity: ${replacementActivity.name}');
        debugPrint('   Rating: ${replacementActivity.rating}');
        
        // Ensure UI updates properly
        if (mounted) {
          setState(() {
            // Create updated activity with preserved timing and incremented refresh count
            final updatedActivity = replacementActivity!.copyWith(
              startTime: activity.startTime,
              duration: activity.duration,
              refreshCount: activity.refreshCount + 1,
              timeSlotEnum: activity.timeSlotEnum, // Crucial: preserve the specific time slot enum!
              timeSlot: activity.timeSlot, // Crucial: preserve the string representation too
            );
            
            // Replace the activity in the slot
            final index = _activities.indexOf(activity);
            if (index >= 0 && index < _activities.length) {
              _activities = List.from(_activities)..[index] = updatedActivity;
            }
          });
        }
        
        // Show success feedback
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.dayPlanFoundNewOption(
            replacementActivity.name,
            '${3 - (activity.refreshCount + 1)}',
          ),
        );
      } else {
        // No linked-place alternative found
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.dayPlanNoLinkedPlaceAlternative,
        );
      }
    } catch (e) {
      debugPrint('❌ Error refreshing activity: $e');
      
      // Show error feedback
      showWanderMoodToast(
        context,
        message: AppLocalizations.of(context)!.dayPlanFindOptionsFailed,
        isError: true,
      );
    }
  }

  String _firstSentence(String text) {
    final normalized = text.replaceAll('\n', ' ').trim();
    if (normalized.isEmpty) return '';

    final match = RegExp(r'^.*?[.!?](?:\s|$)').firstMatch(normalized);
    if (match != null) {
      return match.group(0)!.trim();
    }

    return normalized;
  }

  Widget _buildMoodyMessageCard(BuildContext context) {
    final primaryMessage = _firstSentence(
      widget.moodyMessage.isNotEmpty ? widget.moodyMessage : widget.moodyReasoning,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE8E2D8),
          width: 0.5,
        ),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const MoodyCharacter(
                size: 36,
                mood: 'happy',
                currentFeature: MoodyFeature.none,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.dayPlanMoodyCardTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2A6049),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            primaryMessage,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, curve: Curves.easeOutQuad).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildRefreshButton(Activity activity) {
    final remainingRefreshes = 3 - activity.refreshCount;
    final isDisabled = remainingRefreshes <= 0;
    
    if (isDisabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 14,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context)!.dayPlanAllOptionsUsed,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return TextButton.icon(
      onPressed: () => _refreshActivity(activity),
      icon: const Icon(
        Icons.refresh_rounded,
        size: 16,
        color: Color(0xFF2A6049),
      ),
      label: Text(
        remainingRefreshes == 3 
          ? AppLocalizations.of(context)!.dayPlanNotFeelingThis 
          : AppLocalizations.of(context)!.dayPlanTryAgainLeft(remainingRefreshes.toString()),
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF2A6049),
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // Helper methods for AI recommendation conversion
  PaymentType _parsePaymentType(String costString) {
    if (costString.toLowerCase().contains('free') || costString == '€') {
      return PaymentType.free;
    } else if (costString.contains('€€€') || costString.toLowerCase().contains('expensive')) {
      return PaymentType.reservation;
    } else {
      return PaymentType.reservation;
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

  LatLng _extractLocationFromRecommendation(AIRecommendation rec, double fallbackLat, double fallbackLng) {
    // If the recommendation has location data, use it
    if (rec.location != null) {
      final lat = rec.location!['latitude'] as double?;
      final lng = rec.location!['longitude'] as double?;
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    
    // Fall back to provided coordinates
    return LatLng(fallbackLat, fallbackLng);
  }

  String? _extractPlaceIdFromRecommendation(AIRecommendation rec) {
    final loc = rec.location;
    if (loc == null) return null;
    final dynamic raw = loc['placeId'] ?? loc['place_id'] ?? loc['id'];
    if (raw == null) return null;
    final id = raw.toString().trim();
    return id.isEmpty ? null : id;
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

  static const List<String> _slotOrder = ['morning', 'afternoon', 'evening'];
  static const List<String> _slotEmojis = ['☀️', '🌤️', '🌆'];

  /// Mood-based theme line for section header (localized).
  String _getThemeForSlot(BuildContext context, int slotIndex) {
    final l10n = AppLocalizations.of(context)!;
    final moods = widget.selectedMoods;
    if (moods.isEmpty) {
      final fallbacks = [l10n.dayPlanThemeExploreDiscover, l10n.dayPlanThemeTrueLocalFind, l10n.dayPlanThemeWindDownCulture];
      return fallbacks[slotIndex.clamp(0, 2)];
    }
    String themeForMood(String m) {
      final lower = m.toLowerCase();
      if (lower.contains('cultural') || lower.contains('culture') || lower.contains('curious')) return l10n.dayPlanThemeCulturalDeepDive;
      if (lower.contains('food') || lower.contains('foodie')) return l10n.dayPlanThemeFoodieFind;
      if (lower.contains('social')) return l10n.dayPlanThemeSunsetVibes;
      if (lower.contains('relax') || lower.contains('relaxed')) return l10n.dayPlanThemeWindDownRelax;
      if (lower.contains('adventure') || lower.contains('adventurous')) return l10n.dayPlanThemeAdventureAwaits;
      if (lower.contains('outdoor') || lower.contains('nature')) return l10n.dayPlanThemeOutdoorNature;
      if (lower.contains('creative') || lower.contains('art')) return l10n.dayPlanThemeCreativeVibes;
      if (lower.contains('romantic')) return l10n.dayPlanThemeRomanticMoments;
      return l10n.dayPlanThemeYourVibe;
    }
    final moodIndex = slotIndex.clamp(0, moods.length - 1);
    return themeForMood(moods[moodIndex]);
  }

  void _goBackToMoodyHub() {
    // Reset so Moody tab shows mood selection screen (pick moods again), then go there
    ref.read(dailyMoodStateNotifierProvider.notifier).resetMoodSelection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.goNamed('main', extra: {'tab': 2});
    });
  }

  @override
  Widget build(BuildContext context) {
    const wmCream = Color(0xFFF5F0E8);
    const wmForest = Color(0xFF2A6049);
    const wmForestTint = Color(0xFFEBF3EE);
    const wmParchment = Color(0xFFE8E2D8);
    const wmCharcoal = Color(0xFF1E1C18);

    return Scaffold(
      backgroundColor: wmCream,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header: back arrow, TODAY'S ITINERARY, Your Day Plan based on:, mood pills, Edit Moods
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: wmForestTint,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: wmParchment, width: 0.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome, size: 14, color: wmForest),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(context)!.dayPlanTodayItinerary,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: wmForest,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.dayPlanBasedOn,
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: wmCharcoal,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Mood pills: bright, solid look with a soft shadow
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          ...widget.selectedMoods.take(3).toList().asMap().entries.map((e) {
                            final mood = e.value;
                            final isOrange = e.key % 2 == 0;
                            final bgColor = isOrange ? const Color(0xFFFF8A00) : const Color(0xFF0EA5A4);
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: bgColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_moodEmoji(mood), style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _moodDisplayName(context, mood),
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Edit Moods: subtle link back to mood selection
                      GestureDetector(
                        onTap: _goBackToMoodyHub,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.dayPlanEditMoods,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        // Content: dynamic list of filtered activities (Morning, Afternoon, Evening if applicable)
        Expanded(
          child: Consumer(
            builder: (context, ref, _) {
              final userLocationAsync = ref.watch(userLocationProvider);
              final position = userLocationAsync.valueOrNull;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                children: [
                  if (widget.moodyMessage.isNotEmpty) ...[
                    _buildMoodyMessageCard(context),
                    const SizedBox(height: 16),
                  ],
                  for (int i = 0; i < _activities.length; i++) ...[
                    _buildSectionHeader(context, _activities[i], i),
                    _buildActivityCard(
                      _activities[i],
                      distanceKm: position != null
                          ? DistanceService.formatDistance(
                              DistanceService.calculateDistance(
                                position.latitude,
                                position.longitude,
                                _activities[i].location.latitude,
                                _activities[i].location.longitude,
                              ),
                            )
                          : null,
                      locationLabel: _activities[i].description.isEmpty
                          ? null
                          : (_activities[i].description.length > 80
                              ? '${_activities[i].description.substring(0, 80)}...'
                              : _activities[i].description),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 110),
                ],
              );
            },
          ),
        ),
              ],
            ),
          ),
          // Bottom CTAs: default is View My Day (no bulk save). Explicit second action adds all suggestions.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: wmParchment.withValues(alpha: 0.8), width: 0.5)),
                boxShadow: const [],
              ),
              child: SafeArea(
                top: false,
                child: Builder(builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  final remaining = _activities.length - _addedCount;
                  if (_addedCount == 0) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _activities.isEmpty
                                ? null
                                : () => _navigateToMyDayOnly(ref),
                            icon: const Text('🗓️', style: TextStyle(fontSize: 22)),
                            label: Text(
                              l10n.dayPlanViewMyDay,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: wmForest,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _activities.isEmpty
                              ? null
                              : () => _addPlanToMyDay(ref),
                          child: Text(
                            l10n.dayPlanAddAllSuggestions(
                              _activities.length.toString(),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: wmForest,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _activities.isEmpty ? null : () => _addPlanToMyDay(ref),
                      icon: const Text('🗓️', style: TextStyle(fontSize: 22)),
                      label: Text(
                        remaining > 0
                            ? l10n.dayPlanAddMoreToMyDay(remaining.toString())
                            : l10n.dayPlanViewMyDay,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: wmForest,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Translates an English mood key to the user's locale display name.
  String _moodDisplayName(BuildContext context, String mood) {
    final l10n = AppLocalizations.of(context)!;
    final lower = mood.toLowerCase();
    if (lower.contains('cultural') || lower.contains('culture')) return l10n.moodCultural;
    if (lower.contains('cozy') || lower.contains('cosy')) return l10n.moodCozy;
    if (lower.contains('food') || lower.contains('foody')) return l10n.moodFoody;
    if (lower.contains('relax')) return l10n.moodRelaxed;
    if (lower.contains('adventure') || lower.contains('adventurous')) return l10n.moodAdventurous;
    if (lower.contains('social')) return l10n.moodSocial;
    if (lower.contains('creative')) return l10n.moodCreative;
    if (lower.contains('romantic')) return l10n.moodRomantic;
    if (lower.contains('energetic')) return l10n.moodEnergetic;
    if (lower.contains('curious')) return l10n.moodCurious;
    return mood;
  }

  /// Actual Unicode emoji for mood pills (e.g. 🍜 Foody, 😀 Curious, 👥 Social).
  String _moodEmoji(String mood) {
    final m = mood.toLowerCase();
    if (m.contains('food') || m.contains('foody')) return '🍜';
    if (m.contains('cultural') || m.contains('culture')) return '🏛️';
    if (m.contains('curious')) return '😀';
    if (m.contains('relax')) return '🧘';
    if (m.contains('adventure')) return '🏔️';
    if (m.contains('social')) return '👥';
    if (m.contains('creative')) return '🎨';
    if (m.contains('romantic')) return '💕';
    if (m.contains('energetic')) return '⚡';
    if (m.contains('contemplative')) return '🌿';
    return '✨';
  }

  /// Section header: circular period badge + MORNING/AFTERNOON/EVENING + mood-based theme (reference style).
  Widget _buildSectionHeader(BuildContext context, Activity activity, int index) {
    final l10n = AppLocalizations.of(context)!;
    
    String label;
    String emoji;
    int themeIndex;
    
    switch (activity.timeSlotEnum) {
      case TimeSlot.morning:
        label = l10n.dayPlanMorning;
        emoji = '☀️';
        themeIndex = 0;
        break;
      case TimeSlot.afternoon:
        label = l10n.dayPlanAfternoon;
        emoji = '🌤️';
        themeIndex = 1;
        break;
      case TimeSlot.evening:
      case TimeSlot.night:
      default:
        label = l10n.dayPlanEvening;
        emoji = '🌆';
        themeIndex = 2;
        break;
    }

    final theme = _getThemeForSlot(context, themeIndex);
    return Padding(
      padding: EdgeInsets.only(top: index == 0 ? 4 : 20, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '· $theme',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Day Plan card: reference design with gradient bar, mood match, category, Not feeling this? + See activity.
  Widget _buildActivityCard(Activity activity, {String? distanceKm, String? locationLabel}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 380),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: DayPlanActivityCard(
            activity: activity,
            onTap: (a, {String? distanceKm}) => _openActivityDetail(a, distanceKm: distanceKm),
            onNotFeelingThis: () => _refreshActivity(activity),
            distanceKm: distanceKm,
            locationLabel: locationLabel,
            onAdded: () {
              if (mounted) {
                setState(() {
                  _addedActivityIds.add(activity.id);
                });
              }
            },
          ),
        ),
        ],
      ),
    );
  }

  void _openActivityDetail(Activity activity, {String? distanceKm}) {
    final rawId = activity.placeId?.trim();
    if (rawId != null && rawId.isNotEmpty) {
      // Ensure the ID has the google_ prefix that getPlaceById() requires
      // for live API lookups. AI-generated activities carry raw Google Place IDs.
      final placeId = rawId.startsWith('google_') ? rawId : 'google_$rawId';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaceDetailScreen(placeId: placeId),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(activity: activity, distanceKm: distanceKm),
      ),
    );
  }

  // Dedicated colorful tag builder
  List<Widget> _buildColorfulTags(List<String> tags) {
    // Rich collection of tag styles with semantic meaning
    final Map<String, ({Color color, Color textColor, String icon})> tagStyles = {
      // Wellness & Health related
      'Wellness': (
        color: const Color(0xFFE1F5FE), 
        textColor: const Color(0xFF0288D1), 
        icon: '🧘‍♀️'
      ),
      'Yoga': (
        color: const Color(0xFFE8EAF6),
        textColor: const Color(0xFF3F51B5),
        icon: '🧘'
      ),
      'Spa': (
        color: const Color(0xFFE0F7FA),
        textColor: const Color(0xFF00ACC1),
        icon: '💆'
      ),
      'Meditation': (
        color: const Color(0xFFE0F2F1),
        textColor: const Color(0xFF009688),
        icon: '🧠'
      ),
      'Fitness': (
        color: const Color(0xFFEDE7F6),
        textColor: const Color(0xFF673AB7),
        icon: '🏋️'
      ),
      'Health': (
        color: const Color(0xFFE8F5E9),
        textColor: const Color(0xFF43A047),
        icon: '❤️‍🩹'
      ),

      // Outdoor related 
      'Outdoor': (
        color: const Color(0xFFE8F5E9), 
        textColor: const Color(0xFF388E3C), 
        icon: '🌿'
      ),
      'Nature': (
        color: const Color(0xFFDCEDC8),
        textColor: const Color(0xFF33691E),
        icon: '🌳'
      ),
      'Park': (
        color: const Color(0xFFF1F8E9),
        textColor: const Color(0xFF558B2F),
        icon: '🏞️'
      ),
      'Hiking': (
        color: const Color(0xFFF9FBE7),
        textColor: const Color(0xFF827717),
        icon: '🥾'
      ),
      'Beach': (
        color: const Color(0xFFE0F7FA),
        textColor: const Color(0xFF00838F),
        icon: '🏖️'
      ),

      // Active & Sports
      'Active': (
        color: const Color(0xFFFCE4EC), 
        textColor: const Color(0xFFD81B60), 
        icon: '💪'
      ),
      'Sports': (
        color: const Color(0xFFE8EAF6),
        textColor: const Color(0xFF1A237E),
        icon: '⚽'
      ),
      'Adventure': (
        color: const Color(0xFFEDE7F6),
        textColor: const Color(0xFF512DA8),
        icon: '🧗‍♂️'
      ),
      'Running': (
        color: const Color(0xFFFFEBEE),
        textColor: const Color(0xFFC62828),
        icon: '🏃'
      ),
      'Swimming': (
        color: const Color(0xFFE3F2FD),
        textColor: const Color(0xFF1565C0),
        icon: '🏊'
      ),

      // Food & Drinks
      'Food': (
        color: const Color(0xFFFFF3E0), 
        textColor: const Color(0xFFE65100), 
        icon: '🍽️'
      ),
      'Restaurant': (
        color: const Color(0xFFFFECB3),
        textColor: const Color(0xFFFF8F00),
        icon: '🍴'
      ),
      'Cooking': (
        color: const Color(0xFFFFCCBC),
        textColor: const Color(0xFFD84315),
        icon: '👨‍🍳'
      ),
      'Cafe': (
        color: const Color(0xFFEFEBE9),
        textColor: const Color(0xFF5D4037),
        icon: '☕'
      ),
      'Drinks': (
        color: const Color(0xFFE0F2F1),
        textColor: const Color(0xFF00796B),
        icon: '🍹'
      ),
      'Dinner': (
        color: const Color(0xFFFFEBEE),
        textColor: const Color(0xFFB71C1C),
        icon: '🍷'
      ),
      'Breakfast': (
        color: const Color(0xFFFFF8E1),
        textColor: const Color(0xFFF57F17),
        icon: '🍳'
      ),
      'Lunch': (
        color: const Color(0xFFF9FBE7),
        textColor: const Color(0xFF827717),
        icon: '🥪'
      ),

      // Relationship & Social
      'Romantic': (
        color: const Color(0xFFFFEBEE), 
        textColor: const Color(0xFFE53935), 
        icon: '❤️'
      ),
      'Dating': (
        color: const Color(0xFFFCE4EC),
        textColor: const Color(0xFFC2185B),
        icon: '💕'
      ),
      'Couple': (
        color: const Color(0xFFF8BBD0),
        textColor: const Color(0xFFAD1457),
        icon: '👫'
      ),
      'Social': (
        color: const Color(0xFFE3F2FD),
        textColor: const Color(0xFF1976D2),
        icon: '👥'
      ),
      'Friends': (
        color: const Color(0xFFE8EAF6),
        textColor: const Color(0xFF303F9F),
        icon: '🤝'
      ),

      // Relaxation & Comfort
      'Cozy': (
        color: const Color(0xFFEFEBE9), 
        textColor: const Color(0xFF795548), 
        icon: '☕'
      ),
      'Relaxing': (
        color: const Color(0xFFE0F7FA),
        textColor: const Color(0xFF00ACC1),
        icon: '🧖‍♀️'
      ),
      'Peaceful': (
        color: const Color(0xFFE0F2F1),
        textColor: const Color(0xFF004D40),
        icon: '🍃'
      ),
      'Calm': (
        color: const Color(0xFFE1F5FE),
        textColor: const Color(0xFF0277BD),
        icon: '🕊️'
      ),

      // Educational & Cultural
      'Learning': (
        color: const Color(0xFFE8EAF6), 
        textColor: const Color(0xFF3949AB), 
        icon: '📚'
      ),
      'Educational': (
        color: const Color(0xFFB3E5FC),
        textColor: const Color(0xFF0277BD),
        icon: '🔍'
      ),
      'Class': (
        color: const Color(0xFFD1C4E9),
        textColor: const Color(0xFF512DA8),
        icon: '📝'
      ),
      'Workshop': (
        color: const Color(0xFFE1BEE7),
        textColor: const Color(0xFF7B1FA2),
        icon: '🛠️'
      ),
      'Cultural': (
        color: const Color(0xFFF3E5F5),
        textColor: const Color(0xFF7B1FA2),
        icon: '🎭'
      ),
      'Museum': (
        color: const Color(0xFFD7CCC8),
        textColor: const Color(0xFF4E342E),
        icon: '🏛️'
      ),
      'Art': (
        color: const Color(0xFFE1F5FE),
        textColor: const Color(0xFF01579B),
        icon: '🎨'
      ),
      'History': (
        color: const Color(0xFFD7CCC8),
        textColor: const Color(0xFF5D4037),
        icon: '📜'
      ),

      // Indoor activities
      'Indoor': (
        color: const Color(0xFFE0F2F1), 
        textColor: const Color(0xFF00796B), 
        icon: '🏠'
      ),
      'Cinema': (
        color: const Color(0xFF263238),
        textColor: const Color(0xFFECEFF1),
        icon: '🎬'
      ),
      'Movie': (
        color: const Color(0xFF37474F),
        textColor: const Color(0xFFCFD8DC),
        icon: '🍿'
      ),
      'Theater': (
        color: const Color(0xFFBF360C),
        textColor: const Color(0xFFFFCCBC),
        icon: '🎭'
      ),
      'Music': (
        color: const Color(0xFFE1BEE7),
        textColor: const Color(0xFF6A1B9A),
        icon: '🎵'
      ),
      'Concert': (
        color: const Color(0xFF4A148C),
        textColor: const Color(0xFFEA80FC),
        icon: '🎸'
      ),
      'Shopping': (
        color: const Color(0xFFF9FBE7),
        textColor: const Color(0xFF827717),
        icon: '🛍️'
      ),

      // Time of day
      'Morning': (
        color: const Color(0xFFFFF8E1),
        textColor: const Color(0xFFF57F17),
        icon: '🌅'
      ),
      'Afternoon': (
        color: const Color(0xFFFFE0B2),
        textColor: const Color(0xFFE65100),
        icon: '☀️'
      ),
      'Evening': (
        color: const Color(0xFF3F51B5),
        textColor: const Color(0xFFE8EAF6),
        icon: '🌙'
      ),
      'Night': (
        color: const Color(0xFF1A237E),
        textColor: const Color(0xFFC5CAE9),
        icon: '✨'
      ),
    };

    // Dynamic color generation for tags not in our map
    Color generateColorFromString(String input) {
      // Generate a repeatable hash from the string
      int hash = 0;
      for (int i = 0; i < input.length; i++) {
        hash = input.codeUnitAt(i) + ((hash << 5) - hash);
      }
      
      // Convert to vibrant HSL color
      final hue = (hash % 360).abs(); // 0-359 degrees on color wheel
      
      // Use vibrant saturation and appropriate lightness
      return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.8, 0.85).toColor();
    }

    // Generate visually pleasing text color (dark for light backgrounds, light for dark backgrounds)
    Color getTextColor(Color backgroundColor) {
      // Calculate perceived brightness using standard formula
      final brightness = (backgroundColor.red * 299 + 
                         backgroundColor.green * 587 + 
                         backgroundColor.blue * 114) / 1000;
      
      // Use white text on dark backgrounds, dark text on light backgrounds
      return brightness > 165 
          ? const Color(0xFF212121) // Dark text for light background
          : const Color(0xFFFAFAFA); // Light text for dark background
    }

    return tags.map((tag) {
      // Try case-insensitive lookup in our tag map
      var style = tagStyles.entries
        .where((e) => e.key.toLowerCase() == tag.toLowerCase())
        .map((e) => e.value)
        .firstOrNull;
      
      // If not found, generate a color based on the tag's name
      if (style == null) {
        final color = generateColorFromString(tag);
        final textColor = getTextColor(color);
        
        // Pick an icon based on the tag if possible, or use default
        String icon = '✨';
        if (tag.toLowerCase().contains('food') || tag.toLowerCase().contains('eat')) {
          icon = '🍽️';
        } else if (tag.toLowerCase().contains('art') || tag.toLowerCase().contains('creative')) {
          icon = '🎨';
        } else if (tag.toLowerCase().contains('water') || tag.toLowerCase().contains('sea')) {
          icon = '🌊';
        } else if (tag.toLowerCase().contains('music') || tag.toLowerCase().contains('concert')) {
          icon = '🎵';
        } else if (tag.toLowerCase().contains('nature') || tag.toLowerCase().contains('tree')) {
          icon = '🌳';
        }
        
        style = (color: color, textColor: textColor, icon: icon);
      }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: style.color,
          borderRadius: BorderRadius.circular(16),
      ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${style.icon} ',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              tag,
        style: GoogleFonts.poppins(
          fontSize: 12,
                color: style.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _getIntelligentFallbackImage(Activity activity) {
    final nameLower = activity.name.toLowerCase();
    final tags = activity.tags.map((t) => t.toLowerCase()).toList();
    
    // Spa/Wellness - luxury spa interiors
    if (nameLower.contains('spa') || nameLower.contains('wellness') || 
        nameLower.contains('massage') || nameLower.contains('relax') ||
        tags.any((tag) => ['spa', 'wellness', 'massage', 'relaxation'].contains(tag))) {
      return 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=500&h=400&fit=crop&auto=format'; // Luxury spa interior
    }
    
    // Yoga/Fitness - serene yoga scenes
    if (nameLower.contains('yoga') || nameLower.contains('pilates') || 
        nameLower.contains('fitness') || nameLower.contains('zen') ||
        tags.any((tag) => ['yoga', 'fitness', 'meditation', 'wellness'].contains(tag))) {
      return 'https://images.unsplash.com/photo-1588286840104-8957b019727f?w=500&h=400&fit=crop&auto=format'; // Beautiful yoga studio
    }
    
    // Bar/Nightlife - stylish cocktail bars
    if (nameLower.contains('bar') || nameLower.contains('lounge') || 
        nameLower.contains('cocktail') || nameLower.contains('drink') ||
        tags.any((tag) => ['bar', 'nightlife', 'drinks'].contains(tag))) {
      return 'https://images.unsplash.com/photo-1574391884720-bbc2f1831d92?w=500&h=400&fit=crop&auto=format'; // Stylish bar interior
    }
    
    // Cafe - cozy coffee shops
    if (nameLower.contains('cafe') || nameLower.contains('coffee') || 
        nameLower.contains('espresso') ||
        tags.any((tag) => ['cafe', 'coffee'].contains(tag))) {
      return 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=500&h=400&fit=crop&auto=format'; // Cozy cafe interior
    }
    
    // Fine dining - elegant restaurant interiors
    if (nameLower.contains('fine') || nameLower.contains('luxury') || 
        nameLower.contains('upscale') || nameLower.contains('romantic dining') ||
        tags.any((tag) => ['fine dining', 'luxury', 'romantic'].contains(tag))) {
      return 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=500&h=400&fit=crop&auto=format'; // Fine dining restaurant
    }
    
    // Restaurant/Food - warm restaurant ambiance
    if (nameLower.contains('restaurant') || nameLower.contains('bistro') || 
        nameLower.contains('dining') || nameLower.contains('food') ||
        tags.any((tag) => ['restaurant', 'food', 'dining'].contains(tag))) {
      return 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=500&h=400&fit=crop&auto=format'; // Restaurant interior
    }
    
    // Museums - grand museum halls
    if (nameLower.contains('museum') || 
        tags.any((tag) => ['museum', 'history'].contains(tag))) {
      return 'https://images.unsplash.com/photo-1567213907515-1ea943549e0b?w=500&h=400&fit=crop&auto=format'; // Museum interior
    }
    
    // Art galleries - contemporary art spaces
    if (nameLower.contains('gallery') || nameLower.contains('art') ||
        tags.any((tag) => ['art', 'gallery'].contains(tag))) {
      return 'https://images.unsplash.com/photo-1578926078959-f25b3c9c7daa?w=500&h=400&fit=crop&auto=format'; // Art gallery
    }
    
    // Parks/Gardens - beautiful nature scenes
    if (nameLower.contains('park') || nameLower.contains('garden') || 
        nameLower.contains('nature') ||
        tags.any((tag) => ['park', 'nature', 'outdoor'].contains(tag))) {
      return 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=500&h=400&fit=crop&auto=format'; // Beautiful park
    }
    
    // Entertainment venues - modern entertainment spaces
    if (nameLower.contains('theater') || nameLower.contains('cinema') || 
        nameLower.contains('entertainment') ||
        tags.any((tag) => ['entertainment', 'theater', 'cinema'].contains(tag))) {
      return 'https://images.unsplash.com/photo-1489599735188-0fcfb87b50d4?w=500&h=400&fit=crop&auto=format'; // Entertainment venue
    }
    
    // Shopping - beautiful shopping areas
    if (nameLower.contains('shop') || nameLower.contains('mall') || 
        nameLower.contains('market') ||
        tags.any((tag) => ['shopping', 'market'].contains(tag))) {
      return 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=500&h=400&fit=crop&auto=format'; // Shopping area
    }
    
    // Churches/Religious sites - beautiful architecture
    if (nameLower.contains('church') || nameLower.contains('cathedral') || 
        nameLower.contains('temple') || nameLower.contains('mosque') ||
        tags.any((tag) => ['religious', 'spiritual', 'church'].contains(tag))) {
      return 'https://images.unsplash.com/photo-1520637836862-4d197d17c38a?w=500&h=400&fit=crop&auto=format'; // Beautiful church
    }
    
    // Adventure activities - exciting outdoor scenes
    if (nameLower.contains('adventure') || nameLower.contains('outdoor') || 
        nameLower.contains('active') ||
        tags.any((tag) => ['adventure', 'active', 'outdoor'].contains(tag))) {
      return 'https://images.unsplash.com/photo-1594736797933-d0401ba2fe65?w=500&h=400&fit=crop&auto=format'; // Adventure activity
    }
    
    // Generic tourist attraction - iconic travel imagery
    return 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=500&h=400&fit=crop&auto=format'; // Iconic landmark
  }

  // Alternative activities - only used in debug mode
  // In production, this should fetch real alternative activities from Places API
  List<Map<String, dynamic>> get _alternativeActivities {
    // No mock data - return empty list
    // Alternative activities should come from real API data
    return [];
  }

  Widget _buildPhotoPlaceholder(String text) {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.photo_camera_outlined,
            size: 40,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 