import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'dart:math' as math;

import 'package:wandermood/features/home/domain/enums/moody_feature.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_chat_sheet.dart';
import 'package:wandermood/features/home/presentation/screens/main_screen.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/features/plans/presentation/screens/plan_loading_screen.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/features/weather/providers/weather_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wandermood/features/mood/services/activity_rating_service.dart';
import 'package:wandermood/features/mood/models/activity_rating.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RedesignedMoodyHub extends ConsumerStatefulWidget {
  const RedesignedMoodyHub({super.key});

  @override
  ConsumerState<RedesignedMoodyHub> createState() => _RedesignedMoodyHubState();
}

class _RedesignedMoodyHubState extends ConsumerState<RedesignedMoodyHub> {
  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  String _getTimeEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
  }

  String _getCityName() {
    final city = ref.read(locationNotifierProvider).value;
    return city ?? 'Rotterdam';
  }

  @override
  Widget build(BuildContext context) {
    final todayActivities = ref.watch(todayActivitiesProvider);
    final dailyMoodState = ref.watch(dailyMoodStateNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      body: todayActivities.when(
        data: (activities) {
          final nonCancelled = activities
              .where((a) => a.status != ActivityStatus.cancelled)
              .toList();

          if (nonCancelled.isNotEmpty) {
            return _MoodyHubWithPlan(
              activities: nonCancelled,
              moodState: dailyMoodState,
              greeting: _getTimeGreeting(),
              emoji: _getTimeEmoji(),
              city: _getCityName(),
            );
          }
          return _MoodyHubNoPlan(
            greeting: _getTimeGreeting(),
            emoji: _getTimeEmoji(),
            city: _getCityName(),
          );
        },
        loading: () => _MoodyHubNoPlan(
          greeting: _getTimeGreeting(),
          emoji: _getTimeEmoji(),
          city: _getCityName(),
        ),
        error: (_, __) => _MoodyHubNoPlan(
          greeting: _getTimeGreeting(),
          emoji: _getTimeEmoji(),
          city: _getCityName(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STATE A: User HAS an active day plan
// ---------------------------------------------------------------------------
class _MoodyHubWithPlan extends ConsumerWidget {
  final List<EnhancedActivityData> activities;
  final DailyMoodState moodState;
  final String greeting;
  final String emoji;
  final String city;

  const _MoodyHubWithPlan({
    required this.activities,
    required this.moodState,
    required this.greeting,
    required this.emoji,
    required this.city,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = activities
        .where((a) => a.status == ActivityStatus.activeNow)
        .toList();
    final upcoming = activities
        .where((a) => a.status == ActivityStatus.upcoming)
        .toList();
    final completed = activities
        .where((a) => a.status == ActivityStatus.completed)
        .toList();

    final currentActivity = current.isNotEmpty ? current.first : null;
    final nextActivity = upcoming.isNotEmpty ? upcoming.first : null;

    final moods = moodState.selectedMoods;

    final morningActivities = activities.where((a) => a.startTime.hour < 12).toList();
    final afternoonActivities = activities.where((a) => a.startTime.hour >= 12 && a.startTime.hour < 18).toList();
    final eveningActivities = activities.where((a) => a.startTime.hour >= 18).toList();

    final now = DateTime.now();
    final currentPeriod = now.hour < 12 ? 'morning' : (now.hour < 18 ? 'afternoon' : 'evening');

    bool periodDone(List<EnhancedActivityData> acts) =>
        acts.isNotEmpty && acts.every((a) => a.status == ActivityStatus.completed);
    bool periodNow(String period) => period == currentPeriod;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // --- Header ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting $emoji',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (moods.isNotEmpty)
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          children: [
                            const TextSpan(text: "You're on a "),
                            for (int i = 0; i < moods.length; i++) ...[
                              if (i > 0 && i == moods.length - 1)
                                const TextSpan(text: ' & '),
                              if (i > 0 && i < moods.length - 1)
                                const TextSpan(text: ', '),
                              TextSpan(
                                text: moods[i],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _moodColor(moods[i]),
                                ),
                              ),
                            ],
                            const TextSpan(text: ' journey'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF16A34A), size: 24),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- Current Activity Hero ---
          if (currentActivity != null)
            Builder(
              builder: (context) {
                final activityId =
                    (currentActivity.rawData['id'] as String?) ??
                    (currentActivity.rawData['title'] as String? ?? '');
                final ratingAsync =
                    ref.watch(activityRatingForActivityProvider(activityId));

                return ratingAsync.when(
                  data: (rating) {
                    final isReviewed = rating != null;
                    return _CurrentActivityHero(
                      activity: currentActivity,
                      onDirections: () => _openDirections(context, currentActivity),
                      onReview: isReviewed
                          ? () {}
                          : () => _showActivityReviewSheet(context, currentActivity),
                      isReviewed: isReviewed,
                      rating: rating,
                    );
                  },
                  loading: () => _CurrentActivityHero(
                    activity: currentActivity,
                    onDirections: () => _openDirections(context, currentActivity),
                    onReview: () => _showActivityReviewSheet(context, currentActivity),
                    isReviewed: false,
                    rating: null,
                  ),
                  error: (_, __) => _CurrentActivityHero(
                    activity: currentActivity,
                    onDirections: () => _openDirections(context, currentActivity),
                    onReview: () => _showActivityReviewSheet(context, currentActivity),
                    isReviewed: false,
                    rating: null,
                  ),
                );
              },
            )
          else if (nextActivity != null)
            _UpcomingActivityHero(
              activity: nextActivity,
              onDirections: () => _openDirections(context, nextActivity),
              onGetReady: () => _showGetReadySheet(context, ref, nextActivity),
            ),

          const SizedBox(height: 24),

          // --- Day Progress Timeline ---
          Text(
            "Today's Journey",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${completed.length}/${activities.length} completed',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF9FAFB), Colors.white],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF3F4F6), width: 2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _TimelineBubble(
                      label: 'Morning',
                      icon: Icons.wb_sunny_rounded,
                      isDone: periodDone(morningActivities),
                      isNow: periodNow('morning'),
                      isFuture: !periodNow('morning') && !periodDone(morningActivities),
                      count: morningActivities.length,
                    ),
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: periodDone(morningActivities)
                              ? const LinearGradient(colors: [Color(0xFF4ADE80), Color(0xFFFB923C)])
                              : LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade200]),
                        ),
                      ),
                    ),
                    _TimelineBubble(
                      label: 'Afternoon',
                      icon: Icons.cloud_rounded,
                      isDone: periodDone(afternoonActivities),
                      isNow: periodNow('afternoon'),
                      isFuture: !periodNow('afternoon') && !periodDone(afternoonActivities),
                      count: afternoonActivities.length,
                    ),
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: periodDone(afternoonActivities)
                              ? const LinearGradient(colors: [Color(0xFFFB923C), Color(0xFFA78BFA)])
                              : LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade200]),
                        ),
                      ),
                    ),
                    _TimelineBubble(
                      label: 'Evening',
                      icon: Icons.nightlight_round,
                      isDone: periodDone(eveningActivities),
                      isNow: periodNow('evening'),
                      isFuture: !periodNow('evening') && !periodDone(eveningActivities),
                      count: eveningActivities.length,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Next Up Preview
                if (nextActivity != null)
                  _NextUpPreview(
                    activity: nextActivity,
                    onTap: () {
                      // Jump user to My Day tab where the activity lives
                      ref.read(mainTabProvider.notifier).state = 0;
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- Quick Actions ---
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: const Color(0xFF9333EA),
                  bgGradient: const [Color(0xFFFAF5FF), Color(0xFFFCE7F3)],
                  borderColor: const Color(0xFFE9D5FF),
                  title: 'Ask Moody',
                  subtitle: 'Get suggestions',
                  onTap: () => _openMoodyChat(context, ref),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.add_rounded,
                  iconColor: const Color(0xFF2563EB),
                  bgGradient: const [Color(0xFFEFF6FF), Color(0xFFECFDF5)],
                  borderColor: const Color(0xFFBFDBFE),
                  title: 'Add Activity',
                  subtitle: 'Extend your day',
                  onTap: () {
                    ref.read(mainTabProvider.notifier).state = 1;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- Moody Chat Prompt ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0FDF4), Color(0xFFECFDF5)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBBF7D0), width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF67E8F9), Color(0xFF93C5FD)],
                    ),
                  ),
                  child: const Center(child: Text('😊', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: "How's it going? ",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          TextSpan(
                            text: 'Tap to tell me about your experience!',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _openMoodyChat(context, ref),
                        child: Row(
                          children: [
                            Text(
                              'Share feedback',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF16A34A)),
                          ],
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
    );
  }

  void _openMoodyChat(BuildContext context, WidgetRef ref) {
    showMoodyChatSheet(context, ref);
  }

  Future<void> _showActivityReviewSheet(
    BuildContext context,
    EnhancedActivityData activity,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: _ActivityReviewSheet(activity: activity),
        );
      },
    );
  }

  Future<void> _showGetReadySheet(
    BuildContext context,
    WidgetRef ref,
    EnhancedActivityData activity,
  ) async {
    // Parse destination coordinates from rawData['location'] which is \"lat,lng\"
    double? destLat;
    double? destLng;
    final loc = activity.rawData['location'] as String?;
    if (loc != null && loc.contains(',')) {
      final parts = loc.split(',');
      if (parts.length == 2) {
        destLat = double.tryParse(parts[0]);
        destLng = double.tryParse(parts[1]);
      }
    }

    // Get current location (may fall back to Rotterdam)
    final userPosition = await ref.read(userLocationProvider.future);

    // Estimate distance & travel time
    double? distanceKm;
    int tripMinutes;
    String transportMode;

    if (userPosition != null && destLat != null && destLng != null) {
      distanceKm = _distanceKm(
        userPosition.latitude,
        userPosition.longitude,
        destLat,
        destLng,
      );

      if (distanceKm <= 1.2) {
        // Short walk
        transportMode = 'Walking';
        tripMinutes = (distanceKm / 4.5 * 60).round().clamp(5, 40);
      } else if (distanceKm <= 5) {
        // In-city transit / bike
        transportMode = 'Public transport';
        tripMinutes = (distanceKm / 12 * 60).round() + 5;
      } else {
        // Longer trip
        transportMode = 'Public transport';
        tripMinutes = (distanceKm / 18 * 60).round() + 10;
      }
      // Cap so "Leave by" is never far in the past (e.g. bad/mock location → huge distance)
      tripMinutes = tripMinutes.clamp(5, 120);
    } else {
      // Fallback when we cannot compute distance (e.g. no GPS → Rotterdam fallback)
      distanceKm = null;
      transportMode = 'Walking';
      tripMinutes = 15;
    }

    final leaveByTime =
        activity.startTime.subtract(Duration(minutes: tripMinutes));

    // Get current weather (or mock)
    final weather = await ref.read(weatherProvider.future);
    if (!context.mounted) return;

    final temp = weather?.temperature;
    final condition = weather?.condition ?? weather?.details['description'] as String? ?? '—';
    final l10n = AppLocalizations.of(context)!;
    String tip = l10n.getReadyWeatherTipDefault;
    if (temp != null && temp < 16) {
      tip = l10n.getReadyWeatherTipCool;
    } else if (condition.toLowerCase().contains('rain')) {
      tip = l10n.getReadyWeatherTipRain;
    }
    final checklist = _generateChecklist(activity.rawData, l10n);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: _ExcitingGetReadySheetContent(
            activity: activity,
            leaveByTime: leaveByTime,
            tripMinutes: tripMinutes,
            transportMode: transportMode,
            weatherTemp: temp,
            weatherCondition: condition,
            weatherTip: tip,
            checklist: checklist,
            formatTime: _formatTime,
            onOpenDirections: () => _openDirections(sheetContext, activity),
          ),
        );
      },
    );
  }

  void _openDirections(BuildContext context, EnhancedActivityData activity) async {
    final loc = activity.rawData['location'] as String?;
    if (loc == null || !loc.contains(',')) return;
    final parts = loc.split(',');
    if (parts.length != 2) return;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return;

    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // Haversine distance in kilometers
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;

  List<String> _generateChecklist(Map<String, dynamic> raw, AppLocalizations l10n) {
    final title = (raw['title'] as String? ?? '').toLowerCase();
    final category = (raw['category'] as String? ?? '').toLowerCase();

    final isFood = category.contains('food') || title.contains('restaurant') || title.contains('dinner');
    final isOutdoor = category.contains('outdoor') || title.contains('park') || title.contains('walk');

    final items = <String>[
      l10n.getReadyItemWallet,
      l10n.getReadyItemPhoneCharged,
    ];

    if (isFood) {
      items.add(l10n.getReadyItemReusableBag);
    }
    if (isOutdoor) {
      items.add(l10n.getReadyItemShoes);
      items.add(l10n.getReadyItemWater);
    }

    items.add(l10n.getReadyItemId);
    return items;
  }

  Color _moodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'foodie':
      case 'foody':
        return const Color(0xFFEA580C);
      case 'cultural':
        return const Color(0xFF9333EA);
      case 'adventurous':
        return const Color(0xFFDC2626);
      case 'relaxed':
        return const Color(0xFF16A34A);
      case 'romantic':
        return const Color(0xFFEC4899);
      case 'energetic':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

// ---------------------------------------------------------------------------
// Current Activity Hero Card
// ---------------------------------------------------------------------------
class _CurrentActivityHero extends StatelessWidget {
  final EnhancedActivityData activity;
  final VoidCallback onDirections;
  final VoidCallback onReview;
  final ActivityRating? rating;
  final bool isReviewed;

  const _CurrentActivityHero({
    required this.activity,
    required this.onDirections,
    required this.onReview,
    required this.rating,
    required this.isReviewed,
  });

  @override
  Widget build(BuildContext context) {
    final title = activity.rawData['title'] as String? ?? 'Activity';
    final timeStr = _formatTime(activity.startTime);
    final afterState = isReviewed && rating != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: afterState
              ? const [Color(0xFF16A34A), Color(0xFF22C55E)]
              : const [Color(0xFFFB923C), Color(0xFFEC4899), Color(0xFFA855F7)],
        ),
        boxShadow: [
          BoxShadow(
            color: (afterState ? const Color(0xFF16A34A) : const Color(0xFFEC4899))
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!afterState)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Now – $timeStr',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Reviewed at ${_formatTime(rating!.completedAt)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  afterState ? 'DONE' : 'IN PROGRESS',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          if (afterState) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Row(
                  children: List.generate(
                    rating!.stars,
                    (index) => const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: Color(0xFFFACC15),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (rating!.notes != null && rating!.notes!.isNotEmpty)
                  Expanded(
                    child: Text(
                      '🤩 "${rating!.notes!}"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroButton(
                  label: 'Directions',
                  icon: Icons.navigation_rounded,
                  filled: false,
                  onTap: onDirections,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroButton(
                  label: afterState ? 'Reviewed' : 'Review',
                  icon: Icons.check_rounded,
                  filled: true,
                  onTap: afterState ? () {} : onReview,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upcoming Activity Hero Card (when nothing is active right now)
// ---------------------------------------------------------------------------
class _UpcomingActivityHero extends StatelessWidget {
  final EnhancedActivityData activity;
  final VoidCallback onDirections;
  final VoidCallback onGetReady;
  const _UpcomingActivityHero({
    required this.activity,
    required this.onDirections,
    required this.onGetReady,
  });

  @override
  Widget build(BuildContext context) {
    final title = activity.rawData['title'] as String? ?? 'Activity';
    final timeStr = _formatTime(activity.startTime);
    final remaining = activity.timeRemaining;
    final remainStr = remaining != null ? _formatDuration(remaining) : '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Starts at $timeStr',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  remainStr.isNotEmpty ? 'IN $remainStr' : 'UPCOMING',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroButton(
                  label: 'Directions',
                  icon: Icons.navigation_rounded,
                  filled: false,
                  onTap: onDirections,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroButton(
                  label: 'Get Ready',
                  icon: Icons.rocket_launch_rounded,
                  filled: true,
                  onTap: onGetReady,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero button (Directions / Check In)
// ---------------------------------------------------------------------------
class _HeroButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _HeroButton({required this.label, required this.icon, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? const Color(0xFF22C55E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: filled ? Colors.white : const Color(0xFF1A1A2E)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline Bubble (Morning / Afternoon / Evening)
// ---------------------------------------------------------------------------
class _TimelineBubble extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isDone;
  final bool isNow;
  final bool isFuture;
  final int count;

  const _TimelineBubble({
    required this.label,
    required this.icon,
    required this.isDone,
    required this.isNow,
    required this.isFuture,
    required this.count,
  });

  @override
  State<_TimelineBubble> createState() => _TimelineBubbleState();
}

class _TimelineBubbleState extends State<_TimelineBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isNow) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _TimelineBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isNow && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isNow && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> gradient;
    final Color iconColor;
    final String statusText;

    if (widget.isDone) {
      gradient = const [Color(0xFF4ADE80), Color(0xFF10B981)];
      iconColor = Colors.white;
      statusText = 'Done';
    } else if (widget.isNow) {
      gradient = const [Color(0xFFFB923C), Color(0xFFEC4899)];
      iconColor = Colors.white;
      statusText = 'Now';
    } else {
      gradient = [Colors.grey.shade100, Colors.grey.shade100];
      iconColor = Colors.grey.shade400;
      statusText = 'Later';
    }

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: gradient),
                  boxShadow: widget.isNow
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFB923C).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : widget.isDone
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                ),
                child: Icon(widget.icon, size: 28, color: iconColor),
              ),
            ),
            if (widget.isDone)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF10B981), width: 2),
                  ),
                  child: const Icon(Icons.check_rounded, size: 14, color: Color(0xFF10B981)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          widget.label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: widget.isFuture ? Colors.grey.shade500 : const Color(0xFF1A1A2E),
          ),
        ),
        widget.isNow
            ? FadeTransition(
                opacity: _pulseOpacity,
                child: Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEA580C),
                  ),
                ),
              )
            : Text(
                statusText,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: widget.isDone ? FontWeight.w500 : FontWeight.w400,
                  color: widget.isDone
                      ? const Color(0xFF16A34A)
                      : Colors.grey.shade400,
                ),
              ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Next Up Preview (inside timeline card)
// ---------------------------------------------------------------------------
class _NextUpPreview extends StatelessWidget {
  final EnhancedActivityData activity;
  final VoidCallback onTap;
  const _NextUpPreview({required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = activity.rawData['title'] as String? ?? 'Activity';
    final imageUrl = activity.rawData['imageUrl'] as String?;
    final timeStr = _formatTime(activity.startTime);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6), width: 2),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Up Next',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    timeStr,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 22, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.image_rounded, color: Colors.grey.shade400),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Action Card
// ---------------------------------------------------------------------------
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final List<Color> bgGradient;
  final Color borderColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.bgGradient,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: bgGradient,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 24, color: iconColor),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Small pill chip used in Get Ready quick actions
class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _QuickChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4B5563)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF374151)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STATE B: User has NO active plan
// ---------------------------------------------------------------------------
class _MoodyHubNoPlan extends ConsumerWidget {
  final String greeting;
  final String emoji;
  final String city;

  const _MoodyHubNoPlan({
    required this.greeting,
    required this.emoji,
    required this.city,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // --- Header ---
          Text(
            'Hey there! $emoji',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ready to discover $city today?',
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 24),

          // --- Hero CTA: Create Plan ---
          _CreatePlanHero(city: city),

          const SizedBox(height: 28),

          // --- OR divider ---
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade200)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or explore on your own',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade400),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade200)),
            ],
          ),

          const SizedBox(height: 28),

          // --- Secondary Actions Grid ---
          Row(
            children: [
              Expanded(
                child: _SecondaryActionCard(
                  icon: Icons.place_rounded,
                  iconGradient: const [Color(0xFFFB923C), Color(0xFFEC4899)],
                  bgGradient: const [Color(0xFFFFF7ED), Color(0xFFFCE7F3)],
                  borderColor: const Color(0xFFFED7AA),
                  title: 'Browse',
                  subtitle: 'Explore activities',
                  onTap: () {
                    ref.read(mainTabProvider.notifier).state = 1;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SecondaryActionCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconGradient: const [Color(0xFF4ADE80), Color(0xFF10B981)],
                  bgGradient: const [Color(0xFFF0FDF4), Color(0xFFECFDF5)],
                  borderColor: const Color(0xFFBBF7D0),
                  title: 'Ask Moody',
                  subtitle: 'Chat for ideas',
                  onTap: () {
                    showMoodyChatSheet(context, ref);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // --- Quick Mood Shortcuts ---
          Text(
            "I'm feeling...",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _moodShortcuts.map((mood) {
              return _MoodPill(
                emoji: mood.emoji,
                label: mood.label,
                gradient: mood.gradient,
                onTap: () {
                  ref.read(dailyMoodStateNotifierProvider.notifier).setMoodSelection(
                    mood: mood.label,
                    selectedMoods: [mood.label],
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlanLoadingScreen(
                        selectedMoods: [mood.label],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // --- Trending Suggestion ---
          _TrendingCard(city: city),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create Plan Hero (big green CTA)
// ---------------------------------------------------------------------------
class _CreatePlanHero extends ConsumerWidget {
  final String city;
  const _CreatePlanHero({required this.city});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4ADE80), Color(0xFF10B981), Color(0xFF16A34A)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, size: 32, color: Color(0xFFFDE68A)),
              const SizedBox(height: 12),
              Text(
                'Your day in $city\nis wide open.',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Want me to put a plan together for you?',
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFBBF7D0)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 6,
                  shadowColor: Colors.black.withOpacity(0.15),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // Go to the standalone Moody experience with full mood selection tiles
                      // so the user can choose how they feel before generating a plan.
                      context.pushNamed('moody-standalone');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Create my day',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.auto_awesome, size: 20, color: Color(0xFF16A34A)),
                          const Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF16A34A)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Moody character – float higher so it overlaps the hero nicely
        Positioned(
          bottom: 140,
          right: 28,
          child: SizedBox(
            width: 72,
            height: 72,
            child: MoodyCharacter(
              size: 72,
              mood: 'happy',
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Secondary Action Card (Browse / Ask Moody)
// ---------------------------------------------------------------------------
class _SecondaryActionCard extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGradient;
  final List<Color> bgGradient;
  final Color borderColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SecondaryActionCard({
    required this.icon,
    required this.iconGradient,
    required this.bgGradient,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: bgGradient,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: iconGradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconGradient.first.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, size: 24, color: Colors.white),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mood Pill
// ---------------------------------------------------------------------------
class _MoodPill extends StatelessWidget {
  final String emoji;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _MoodPill({
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trending Card
// ---------------------------------------------------------------------------
class _TrendingCard extends StatelessWidget {
  final String city;
  const _TrendingCard({required this.city});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.10),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFAF5FF), Color(0xFFFCE7F3)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE9D5FF), width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA855F7).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.trending_up_rounded, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trending in $city',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                      children: const [
                        TextSpan(text: 'Most people are exploring '),
                        TextSpan(
                          text: 'Foodie',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ' spots this afternoon'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "See what's popular →",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9333EA),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mood shortcut data
// ---------------------------------------------------------------------------
class _MoodShortcut {
  final String emoji;
  final String label;
  final List<Color> gradient;
  const _MoodShortcut(this.emoji, this.label, this.gradient);
}

const _moodShortcuts = [
  _MoodShortcut('🍜', 'Foodie', [Color(0xFFFBBF24), Color(0xFFF97316)]),
  _MoodShortcut('☕', 'Relaxed', [Color(0xFF4ADE80), Color(0xFF10B981)]),
  _MoodShortcut('🏔️', 'Adventurous', [Color(0xFFFB923C), Color(0xFFEF4444)]),
  _MoodShortcut('💕', 'Romantic', [Color(0xFFF472B6), Color(0xFFF43F5E)]),
  _MoodShortcut('🎨', 'Cultural', [Color(0xFFA78BFA), Color(0xFF6366F1)]),
  _MoodShortcut('⚡', 'Energetic', [Color(0xFF60A5FA), Color(0xFF06B6D4)]),
];

// ---------------------------------------------------------------------------
// Activity Review Sheet (Quick Review for current activity)
// ---------------------------------------------------------------------------
class _ActivityReviewSheet extends ConsumerStatefulWidget {
  final EnhancedActivityData activity;

  const _ActivityReviewSheet({required this.activity});

  @override
  ConsumerState<_ActivityReviewSheet> createState() => _ActivityReviewSheetState();
}

class _ActivityReviewSheetState extends ConsumerState<_ActivityReviewSheet> {
  int _rating = 0;
  String? _selectedEmoji;
  final TextEditingController _noteController = TextEditingController();

  final List<_EmojiOption> _emojiOptions = const [
    _EmojiOption('🤩', 'Amazing'),
    _EmojiOption('😊', 'Good'),
    _EmojiOption('😐', 'Okay'),
    _EmojiOption('😞', 'Meh'),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.activity.rawData['title'] as String? ?? 'Activity';
    final timeStr =
        '${_formatTime(widget.activity.startTime)} – ${_formatTime(widget.activity.endTime)}';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Review',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF7ED), Color(0xFFFFE4E6)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF97316)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFB923C), Color(0xFFEC4899)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text('🛍️', style: TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeStr,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Star rating
                  Text(
                    'How was it?',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      final isActive = star <= _rating;
                      return IconButton(
                        onPressed: () {
                          setState(() => _rating = star);
                        },
                        iconSize: 36,
                        splashRadius: 24,
                        icon: Icon(
                          Icons.star_rounded,
                          color: isActive ? const Color(0xFFFACC15) : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                  if (_rating > 0) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        _rating == 5
                            ? '🌟 Amazing!'
                            : _rating == 4
                                ? '😊 Really good!'
                                : _rating == 3
                                    ? '👍 Pretty good!'
                                    : _rating == 2
                                        ? '😐 It was okay'
                                        : '😞 Not great',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Emoji vibe
                  Text(
                    'Your vibe',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _emojiOptions.length,
                    itemBuilder: (context, index) {
                      final option = _emojiOptions[index];
                      final selected = option.emoji == _selectedEmoji;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedEmoji =
                                selected ? null : option.emoji;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  selected ? Colors.transparent : Colors.grey.shade300,
                              width: 2,
                            ),
                            gradient: selected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFFEC4899),
                                    ],
                                  )
                                : null,
                            color: selected ? null : Colors.white,
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1)
                                          .withOpacity(0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                option.emoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                option.label,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Optional note
                  Text(
                    'Any thoughts? (optional)',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'What stood out? Any tips for others?',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: Color(0xFF8B5CF6),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '💡 This helps others discover great spots!',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _rating == 0
                        ? null
                        : () async {
                            final client = Supabase.instance.client;
                            final userId = client.auth.currentUser?.id;
                            if (userId == null) {
                              Navigator.of(context).pop();
                              return;
                            }

                            final raw = widget.activity.rawData;
                            final activityId =
                                (raw['id'] as String?) ?? (raw['title'] as String? ?? '');
                            final activityName = raw['title'] as String? ?? 'Activity';
                            final placeName = raw['placeName'] as String?;
                            final moodRaw = raw['mood'] as String?;
                            final mood = _selectedEmoji != null
                                ? _mapEmojiToMood(_selectedEmoji!)
                                : (moodRaw ?? 'unknown');

                            final rating = ActivityRating(
                              id: const Uuid().v4(),
                              userId: userId,
                              activityId: activityId,
                              activityName: activityName,
                              placeName: placeName,
                              stars: _rating,
                              tags: _selectedEmoji != null ? [_mapEmojiToLabel(_selectedEmoji!)] : [],
                              wouldRecommend: _rating >= 4,
                              notes: _noteController.text.isNotEmpty ? _noteController.text : null,
                              completedAt: DateTime.now(),
                              mood: mood,
                            );

                            await ref
                                .read(activityRatingServiceProvider)
                                .saveRating(rating);

                            // Mark activity as completed in the shared activity status layer
                            ref
                                .read(activityManagerProvider.notifier)
                                .updateActivityStatus(
                                  activityId,
                                  ActivityStatus.completed,
                                );

                            // Refresh providers so My Day and Moody Hub stay in sync
                            ref.invalidate(todayActivitiesProvider);
                            ref.invalidate(timelineCategorizedActivitiesProvider);
                            ref.invalidate(
                              activityRatingForActivityProvider(activityId),
                            );

                            if (!mounted) return;
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Thanks for your review! 🚀',
                                  style: GoogleFonts.poppins(),
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey.shade500,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded),
                        const SizedBox(width: 8),
                        Text(
                          'Save Review',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _rating == 0
                      ? 'Please add a star rating to continue'
                      : 'Your feedback helps Moody learn!',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiOption {
  final String emoji;
  final String label;
  const _EmojiOption(this.emoji, this.label);
}

String _mapEmojiToMood(String emoji) {
  switch (emoji) {
    case '🤩':
      return 'amazing';
    case '😊':
      return 'good';
    case '😐':
      return 'okay';
    case '😞':
      return 'meh';
    default:
      return 'unknown';
  }
}

String _mapEmojiToLabel(String emoji) {
  switch (emoji) {
    case '🤩':
      return 'Amazing';
    case '😊':
      return 'Good';
    case '😐':
      return 'Okay';
    case '😞':
      return 'Meh';
    default:
      return 'Unknown';
  }
}

// ---------------------------------------------------------------------------
// Exciting Get Ready Sheet (React-style hero, countdown, energy, playlist, shimmer)
// ---------------------------------------------------------------------------
class _ExcitingGetReadySheetContent extends StatefulWidget {
  final EnhancedActivityData activity;
  final DateTime leaveByTime;
  final int tripMinutes;
  final String transportMode;
  final double? weatherTemp;
  final String weatherCondition;
  final String weatherTip;
  final List<String> checklist;
  final String Function(DateTime) formatTime;
  final VoidCallback onOpenDirections;

  const _ExcitingGetReadySheetContent({
    required this.activity,
    required this.leaveByTime,
    required this.tripMinutes,
    required this.transportMode,
    required this.weatherTemp,
    required this.weatherCondition,
    required this.weatherTip,
    required this.checklist,
    required this.formatTime,
    required this.onOpenDirections,
  });

  @override
  State<_ExcitingGetReadySheetContent> createState() => _ExcitingGetReadySheetContentState();
}

class _ExcitingGetReadySheetContentState extends State<_ExcitingGetReadySheetContent>
    with SingleTickerProviderStateMixin {
  final Set<int> _checkedIndices = {};
  bool _reminderOn = false;
  Duration? _countdown;
  Timer? _countdownTimer;
  late AnimationController _shimmerController;
  late final String _activityId;

  static const List<String> _checklistEmojis = ['💳', '📱', '🛍️', '👟', '💧', '🪪'];

  @override
  void initState() {
    super.initState();
    _activityId = (widget.activity.rawData['id'] as String?) ??
        (widget.activity.rawData['title'] as String? ?? '');
    _loadPersistedState();
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) => _updateCountdown());
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  void _updateCountdown() {
    if (!mounted) return;
    final d = widget.activity.startTime.difference(DateTime.now());
    setState(() => _countdown = d.isNegative ? Duration.zero : d);
  }

  Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('get_ready_state_$_activityId');
      if (raw == null) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final List<dynamic>? indices = decoded['checkedIndices'] as List<dynamic>?;
      final bool reminder = decoded['reminderOn'] as bool? ?? false;
      setState(() {
        _checkedIndices
          ..clear()
          ..addAll(indices?.map((e) => e as int) ?? const <int>[]);
        _reminderOn = reminder;
      });
    } catch (_) {
      // Swallow errors – fallback to default state
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{
        'checkedIndices': _checkedIndices.toList(),
        'reminderOn': _reminderOn,
      };
      await prefs.setString('get_ready_state_$_activityId', jsonEncode(data));
    } catch (_) {
      // Ignore persistence failures for now
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = widget.checklist.length;
    final checked = _checkedIndices.length;
    final energyPercent = total > 0 ? (checked / total).clamp(0.0, 1.0) : 0.0;

    final hours = _countdown != null ? _countdown!.inHours : 0;
    final mins = _countdown != null ? (_countdown!.inMinutes % 60) : 0;

    final rawMood = widget.activity.rawData['mood'] as String?;
    final moodTag = (rawMood != null && rawMood.trim().isNotEmpty) ? rawMood : 'adventure';
    final themeLabel = _playlistThemeFromActivity(widget.activity.rawData);

    final reminderTime = widget.leaveByTime.subtract(const Duration(minutes: 10));

    return WillPopScope(
      onWillPop: () async {
        await _saveState();
        return true;
      },
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Hero
                  _buildHero(l10n, hours, mins, reminderTime),
                  const SizedBox(height: 20),
                  // Energy meter
                  _buildEnergyMeter(l10n, energyPercent),
                  const SizedBox(height: 16),
                  // Weather
                  _buildWeatherCard(l10n),
                  const SizedBox(height: 16),
                  // Checklist
                  _buildChecklist(l10n),
                  const SizedBox(height: 16),
                  // Vibe Playlist
                  _buildVibePlaylist(l10n, moodTag, themeLabel),
                  const SizedBox(height: 16),
                  // Reminder
                  _buildReminder(l10n, reminderTime),
                  const SizedBox(height: 16),
                  // Quick actions
                  _buildQuickActions(l10n),
                  const SizedBox(height: 24),
                  // CTA with shimmer
                  _buildShimmerCta(l10n),
                ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(AppLocalizations l10n, int hours, int mins, DateTime reminderTime) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEA580C), Color(0xFFEC4899), Color(0xFF9333EA)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    l10n.getReadyLetsGo,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.getReadyAdventureStartsIn,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _countdownBox('${hours.clamp(0, 99)}', l10n.getReadyHours),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(':', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  _countdownBox('${mins.clamp(0, 59)}', l10n.getReadyMins),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.getReadyLeaveBy(widget.formatTime(widget.leaveByTime)),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.getReadyTripSummary(widget.transportMode, widget.tripMinutes),
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: widget.onOpenDirections,
                    icon: const Icon(Icons.route_rounded, size: 18, color: Colors.white),
                    label: Text(
                      '${l10n.getReadyRoute} →',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            right: -4,
            child: SizedBox(
              width: 64,
              height: 64,
              child: MoodyCharacter(
                size: 64,
                mood: 'excited',
                currentFeature: MoodyFeature.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countdownBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyMeter(AppLocalizations l10n, double percent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.getReadyYourAdventureEnergy,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.getReadyBoostEnergyHint,
            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFB45309)),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: Colors.white70,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEA580C)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(AppLocalizations l10n) {
    final tempStr = widget.weatherTemp != null
        ? '${widget.weatherTemp!.toStringAsFixed(0)}°C, ${widget.weatherCondition}'
        : '—';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFEFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌤️', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.getReadyWeatherAt(widget.formatTime(widget.activity.startTime)),
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  tempStr,
                  style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.weatherTip,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                l10n.getReadyPackEssentials,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(widget.checklist.length, (i) {
            final checked = _checkedIndices.contains(i);
            final emoji = i < _checklistEmojis.length ? _checklistEmojis[i] : '✓';
            return InkWell(
              onTap: () {
                setState(() {
                  if (checked) {
                    _checkedIndices.remove(i);
                  } else {
                    _checkedIndices.add(i);
                  }
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.checklist[i],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: checked ? Colors.grey : const Color(0xFF111827),
                              decoration: checked ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (checked)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Ready to go!',
                                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF16A34A), fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      checked ? Icons.check_circle_rounded : Icons.circle_outlined,
                      size: 24,
                      color: checked ? const Color(0xFF16A34A) : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _playlistThemeFromActivity(Map<String, dynamic> raw) {
    final title = (raw['title'] as String? ?? '').toLowerCase();
    final cat = (raw['category'] as String? ?? '').toLowerCase();
    if (cat.contains('food') || title.contains('restaurant') || title.contains('dinner')) return 'Foodie';
    if (cat.contains('culture') || title.contains('museum')) return 'Cultural';
    if (cat.contains('shop') || title.contains('shopping')) return 'Shopping';
    if (cat.contains('outdoor') || title.contains('park')) return 'Outdoor';
    return 'Adventure';
  }

  Widget _buildVibePlaylist(AppLocalizations l10n, String mood, String themeLabel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple.shade100, Colors.pink.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.music_note_rounded, color: Color(0xFF9333EA), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.getReadyVibePlaylist,
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B21A8)),
                ),
                Text(
                  l10n.getReadyGetInMood(mood),
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF7C3AED)),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.getReadyPlaylistLabel(themeLabel),
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF4C1D95)),
                ),
              ],
            ),
          ),
          Material(
            color: const Color(0xFF9333EA),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _onPlaylistTap(themeLabel),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  l10n.getReadyPlay,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminder(AppLocalizations l10n, DateTime reminderTime) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(
          l10n.getReadyNudgeMe,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
        ),
        subtitle: _reminderOn
            ? Text(
                l10n.getReadyReminderAt(widget.formatTime(reminderTime)),
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF16A34A)),
              )
            : null,
        value: _reminderOn,
        onChanged: (value) {
          setState(() => _reminderOn = value);
          if (value) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.getReadyReminderAt(widget.formatTime(reminderTime)),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildQuickActions(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.getReadyQuickActions,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _GradientActionChip(
                label: l10n.getReadyQuickShare,
                icon: Icons.ios_share_rounded,
                gradient: const [Color(0xFFEA580C), Color(0xFFF59E0B)],
                onTap: _onShareTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GradientActionChip(
                label: l10n.getReadyQuickCalendar,
                icon: Icons.event_rounded,
                gradient: const [Color(0xFFEC4899), Color(0xFFDB2777)],
                onTap: _onCalendarTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GradientActionChip(
                label: l10n.getReadyQuickParking,
                icon: Icons.local_parking_rounded,
                gradient: const [Color(0xFF9333EA), Color(0xFF7C3AED)],
                onTap: _onParkingTap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onShareTap() {
    final title = widget.activity.rawData['title'] as String? ?? 'this place';
    final time = widget.formatTime(widget.activity.startTime);
    final message = 'Join me at $title around $time – planned with WanderMood.';
    Share.share(message);
  }

  Future<void> _onCalendarTap() async {
    final title = widget.activity.rawData['title'] as String? ?? 'WanderMood activity';
    final start = widget.activity.startTime.toUtc();
    final end = widget.activity.endTime.toUtc();
    final startStr = _formatIso8601Utc(start);
    final endStr = _formatIso8601Utc(end);
    final details = widget.activity.rawData['description'] as String? ?? 'Planned with WanderMood';
    final location = widget.activity.rawData['address'] as String? ??
        widget.activity.rawData['location'] as String? ??
        '';

    final uri = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=${Uri.encodeComponent(title)}'
      '&dates=$startStr/$endStr'
      '&details=${Uri.encodeComponent(details)}'
      '&location=${Uri.encodeComponent(location.toString())}',
    );
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showCalendarSnackBar();
      }
    } catch (_) {
      if (mounted) _showCalendarSnackBar();
    }
  }

  String _formatIso8601Utc(DateTime utc) {
    final y = utc.year;
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final h = utc.hour.toString().padLeft(2, '0');
    final min = utc.minute.toString().padLeft(2, '0');
    final s = utc.second.toString().padLeft(2, '0');
    return '$y$m${d}T$h$min${s}Z';
  }

  void _showCalendarSnackBar() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.getReadyQuickCalendar} – open in browser or app')),
    );
  }

  void _onParkingTap() async {
    final loc = widget.activity.rawData['location'] as String?;
    Uri url;
    if (loc != null && loc.contains(',')) {
      final parts = loc.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          url = Uri.parse('https://www.google.com/maps/search/?api=1&query=parking%20near%20$lat,$lng');
        } else {
          url = Uri.parse('https://www.google.com/maps/search/?api=1&query=parking');
        }
      } else {
        url = Uri.parse('https://www.google.com/maps/search/?api=1&query=parking');
      }
    } else {
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=parking');
    }
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _onPlaylistTap(String themeLabel) async {
    // Open Spotify search for theme-based mood music (app or web)
    final query = 'Happy $themeLabel Beats';
    final uri = Uri.parse(
      'https://open.spotify.com/search/${Uri.encodeComponent(query)}',
    );
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showPlaylistSnackBar();
      }
    } catch (_) {
      if (mounted) _showPlaylistSnackBar();
    }
  }

  void _showPlaylistSnackBar() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.getReadyVibePlaylist)),
    );
  }

  Widget _buildShimmerCta(AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child!,
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment(-1.0 + _shimmerController.value * 2, 0),
                      end: Alignment(_shimmerController.value * 2, 0),
                      colors: [
                        Colors.transparent,
                        Colors.white24,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ).createShader(bounds);
                  },
                  child: Container(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            await _saveState();
            if (!mounted) return;
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.getReadyPrimaryCta,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                l10n.getReadyCantWait,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const _GradientActionChip({
    required this.label,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
String _formatTime(DateTime time) {
  final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

String _formatDuration(Duration duration) {
  if (duration.inHours > 0) {
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }
  return '${duration.inMinutes}m';
}
