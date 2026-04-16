import 'package:flutter/material.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/mood/models/activity_rating.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/home/presentation/widgets/activity_review_sheet.dart';
import 'package:wandermood/features/mood/services/activity_rating_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';

import '../screens/dynamic_my_day_provider.dart';
import '../utils/my_day_activity_id.dart';
import '../utils/my_day_display_title.dart';
import '../utils/my_day_slot_period.dart';
import 'travel_time_connector.dart';

// Screen 3 — section headers wmForest, metadata wmStone; status chips v2 palette
const Color _kWmForest = Color(0xFF2A6049);
/// Warm ivory surfaces (quick actions, chips) — aligns with Blij / cream system.
const Color _kWmIvory = Color(0xFFFFFBF7);
const Color _kWmStone = Color(0xFF8C8780);
const Color _kWmParchment = Color(0xFFE8E2D8);
const Color _kWmSunset = Color(0xFFE8784A);
/// Planned / upcoming status chip — warm bronze (readable white label).
const Color _kWmWarmBronze = Color(0xFF8F7355);
const Color _kWmCharcoal = Color(0xFF1E1C18);

class MyDayTimelineSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<EnhancedActivityData> activities;
  final bool isFirstSection;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final void Function(EnhancedActivityData activity) onActivityTap;
  final void Function(EnhancedActivityData activity) onDirectionsTap;
  final void Function(EnhancedActivityData activity) onMoreTap;
  final void Function(EnhancedActivityData activity) onCheckIn;
  final void Function(EnhancedActivityData activity) onMarkDone;
  final void Function(EnhancedActivityData activity) onGetReady;
  final String Function(DateTime time) formatTime;

  const MyDayTimelineSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.activities,
    required this.isFirstSection,
    required this.isCollapsed,
    required this.onActivityTap,
    required this.onDirectionsTap,
    required this.onMoreTap,
    required this.onCheckIn,
    required this.onMarkDone,
    required this.onGetReady,
    required this.formatTime,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allCompleted = activities.every(
      (activity) => activity.status == ActivityStatus.completed,
    );

    return SliverToBoxAdapter(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isFirstSection ? 18 : 24),
            Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _kWmForest,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),
                  // Activity count — always on the right
                  Text(
                    l10n.myDayTimelineActivityCount(activities.length),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _kWmStone,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  // "All Done" collapse pill — only when complete
                  if (allCompleted) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onToggleCollapse,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _kWmIvory,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kWmParchment),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: _kWmForest, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              l10n.myDayTimelineAllDone,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _kWmForest,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              isCollapsed ? Icons.expand_more : Icons.expand_less,
                              color: _kWmForest,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
            ),
            const SizedBox(height: 4),
            Text(
              allCompleted ? l10n.myDayTimelineSectionComplete : subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: allCompleted ? _kWmForest : _kWmStone,
                fontWeight: allCompleted ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 16),
            if (!allCompleted || !isCollapsed)
              ...() {
                final widgets = <Widget>[];
                for (int i = 0; i < activities.length; i++) {
                  final activity = activities[i];
                  widgets.add(
                    MyDayTimelineActivityCard(
                      activity: activity,
                      l10n: l10n,
                      onTap: () => onActivityTap(activity),
                      onDirectionsTap: () => onDirectionsTap(activity),
                      onMoreTap: () => onMoreTap(activity),
                      onCheckIn: () => onCheckIn(activity),
                      onMarkDone: () => onMarkDone(activity),
                      onGetReady: () => onGetReady(activity),
                      formatTime: formatTime,
                    ).animate(delay: (i * 100).ms)
                        .slideX(begin: 0.3, duration: 600.ms)
                        .fadeIn(duration: 600.ms)
                        .scale(begin: const Offset(0.9, 0.9), duration: 400.ms),
                  );
                  if (i < activities.length - 1) {
                    final fromLoc = parseTravelLocation(activity.rawData);
                    final toLoc = parseTravelLocation(activities[i + 1].rawData);
                    if (fromLoc != null && toLoc != null) {
                      widgets.add(TravelTimeConnector(
                        fromLat: fromLoc.lat,
                        fromLng: fromLoc.lng,
                        toLat: toLoc.lat,
                        toLng: toLoc.lng,
                      ));
                    }
                    widgets.add(const SizedBox(height: 12));
                  } else {
                    widgets.add(const SizedBox(height: 16));
                  }
                }
                return widgets;
              }(),
            ],
          ),
        ),
    );
  }
}

class MyDayTimelineActivityCard extends ConsumerWidget {
  final EnhancedActivityData activity;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onDirectionsTap;
  final VoidCallback onMoreTap;
  final VoidCallback onCheckIn;
  final VoidCallback onMarkDone;
  final VoidCallback onGetReady;
  final String Function(DateTime time) formatTime;

  const MyDayTimelineActivityCard({
    super.key,
    required this.activity,
    required this.l10n,
    required this.onTap,
    required this.onDirectionsTap,
    required this.onMoreTap,
    required this.onCheckIn,
    required this.onMarkDone,
    required this.onGetReady,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardStatus = _buildCardStatus(activity, l10n);
    final activityId = myDayStableActivityId(activity.rawData);
    final ratingAsync = activity.status == ActivityStatus.completed
        ? ref.watch(activityRatingForActivityProvider(activityId))
        : null;
    final hasReview = ratingAsync?.maybeWhen(
          data: (rating) => rating != null,
          orElse: () => false,
        ) ??
        false;

    // Primary CTA depends on user-initiated status
    final String primaryLabel;
    final VoidCallback primaryAction;
    if (activity.status == ActivityStatus.completed) {
      primaryLabel = hasReview ? l10n.myDayTimelinePrimaryReviewed : l10n.myDayTimelinePrimaryReview;
      primaryAction = hasReview ? () {} : () => showActivityReviewSheet(context, activity);
    } else if (activity.status == ActivityStatus.activeNow) {
      primaryLabel = l10n.myDayTimelinePrimaryDone;
      primaryAction = () { HapticFeedback.mediumImpact(); onMarkDone(); };
    } else {
      primaryLabel = l10n.myDayTimelinePrimaryImHere;
      primaryAction = () { HapticFeedback.mediumImpact(); onCheckIn(); };
    }

    final subtitleText = l10n.myDayTimelineTapForDetails;
    final displayTitle = myDayShortActivityTitle(
      activity.rawData['title'] as String?,
    );
    final titleForCard = displayTitle.isNotEmpty
        ? displayTitle
        : l10n.myDayActivityFallbackLabel;

    // Time-of-day badge (replaces "1:15 PM • 120m" which implied a booking)
    final slotEmoji = _slotEmoji(activity.startTime.hour);
    final slotLabel = myDayActivitySlotPeriodLabel(
      l10n,
      activity.startTime,
      MoodyClock.now(),
    );

    return Semantics(
      label: '$titleForCard. $subtitleText',
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTapDown: (_) => HapticFeedback.lightImpact(),
          onTap: onTap,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kWmParchment, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: WmPlaceOrHttpsNetworkImage(
                        activity.rawData['imageUrl']?.toString() ?? '',
                        fit: BoxFit.cover,
                        progressIndicatorBuilder: (context, url, progress) => Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: progress.progress,
                            ),
                          ),
                        ),
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cardStatus.color.withValues(alpha: 0.85),
                                cardStatus.color.withValues(alpha: 0.55),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.image, color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$slotEmoji $slotLabel',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: cardStatus.color,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.55),
                                      width: 0.75,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        cardStatus.icon,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        cardStatus.label,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              titleForCard,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.8),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (activity.status == ActivityStatus.completed)
                            _myDayTimelineRatingRow(
                              l10n,
                              ratingAsync,
                              activity.rawData,
                            ),
                          Text(
                            _activityLabel(activity.rawData, l10n),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _kWmCharcoal,
                            ),
                          ),
                          Text(
                            subtitleText,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: _kWmStone,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // For upcoming activities show "Get Ready" outline before "I'm Here"
                        if (activity.status == ActivityStatus.upcoming) ...[
                          Semantics(
                            label: l10n.myDayGetReadyButton,
                            button: true,
                            child: _OutlineActionButton(
                              label: l10n.myDayGetReadyButton,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                onGetReady();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Primary filled button (I'm Here / Done / Review)
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: activity.status == ActivityStatus.activeNow
                                ? _kWmSunset
                                : _kWmForest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.55),
                              width: 0.75,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTapDown: (_) => HapticFeedback.lightImpact(),
                              onTap: primaryAction,
                              child: Center(
                                child: Text(
                                  primaryLabel,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          label: l10n.myDayActivityOptionsTitle,
                          button: true,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTapDown: (_) => HapticFeedback.lightImpact(),
                              onTap: onMoreTap,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _kWmParchment, width: 1),
                                ),
                                child: Icon(
                                  Icons.more_vert,
                                  size: 16,
                                  color: _kWmStone,
                                  semanticLabel: '',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
      ),
    );
  }
}

/// WanderMood review first; otherwise a compact Google-style rating from plan data.
Widget _myDayTimelineRatingRow(
  AppLocalizations l10n,
  AsyncValue<ActivityRating?>? ratingAsync,
  Map<String, dynamic> raw,
) {
  final wm = ratingAsync?.maybeWhen(
    data: (r) => r,
    orElse: () => null,
  );
  if (wm != null) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          ...List.generate(
            5,
            (i) => Icon(
              i < wm.stars ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 14,
              color: i < wm.stars ? _kWmSunset : _kWmParchment,
            ),
          ),
          if (wm.tags.isNotEmpty) ...[
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                wm.tags.first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kWmForest,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  final g = (raw['rating'] as num?)?.toDouble();
  if (g != null && g > 0) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        l10n.myDayFreeTimeInsightRating(g.toStringAsFixed(1)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: _kWmStone,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  return const SizedBox.shrink();
}

_ActivityCardStatus _buildCardStatus(EnhancedActivityData activity, AppLocalizations l10n) {
  switch (activity.status) {
    case ActivityStatus.activeNow:
      return _ActivityCardStatus(
        color: _kWmSunset,
        label: l10n.myDayTimelineStatusImHere,
        icon: Icons.place_rounded,
      );
    case ActivityStatus.upcoming:
      return _ActivityCardStatus(
        color: _kWmWarmBronze,
        label: l10n.myDayTimelineStatusPlanned,
        icon: Icons.bookmark_rounded,
      );
    case ActivityStatus.completed:
      return _ActivityCardStatus(
        color: _kWmForest,
        label: l10n.myDayTimelineStatusDone,
        icon: Icons.check_circle,
      );
    default:
      return _ActivityCardStatus(
        color: _kWmStone,
        label: l10n.myDayTimelineStatusPlanned,
        icon: Icons.bookmark_rounded,
      );
  }
}

/// Small outline button used alongside the primary action on activity cards.
class _OutlineActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlineActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kWmForest, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTapDown: (_) => HapticFeedback.lightImpact(),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kWmForest,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Returns a meaningful activity label: category first, then type, then a mood-tag fallback.
String _activityLabel(Map<String, dynamic> data, AppLocalizations l10n) {
  final category = data['category'] as String?;
  if (category != null &&
      category.trim().isNotEmpty &&
      category.toLowerCase() != 'activity') {
    return _localizedActivityKindLabel(category.trim(), l10n);
  }
  final type = data['type'] as String?;
  if (type != null && type.trim().isNotEmpty) {
    return _localizedActivityKindLabel(type.trim(), l10n);
  }
  final mood = data['mood'] as String?;
  if (mood != null && mood.trim().isNotEmpty) {
    return _localizedActivityKindLabel(mood.trim(), l10n);
  }
  return l10n.myDayActivityFallbackLabel;
}

/// Maps English plan tags (food, culture, …) to [AppLocalizations] like Explore chips.
String _localizedActivityKindLabel(String raw, AppLocalizations l10n) {
  switch (raw.toLowerCase()) {
    case 'food':
    case 'foodie':
      return l10n.exploreCategoryFood;
    case 'culture':
      return l10n.exploreCategoryCulture;
    case 'nature':
    case 'outdoors':
      return l10n.exploreCategoryNature;
    case 'shopping':
      return l10n.exploreCategoryChipShopping;
    case 'entertainment':
      return l10n.myDayFreeTimeCategoryEntertainment;
    case 'exercise':
    case 'active':
    case 'adventure':
      return l10n.myDayFreeTimeCategoryExercise;
    case 'social':
      return l10n.myDayFreeTimeCategorySocial;
    case 'relaxation':
    case 'relaxed':
      return l10n.exploreMoodRelaxed;
    case 'nightlife':
      return l10n.exploreCategoryChipNightlife;
    case 'wellness':
      return l10n.profileVibeWellnessName;
    default:
      return _capitalize(raw);
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

String _slotEmoji(int hour) {
  if (hour >= 6 && hour < 12) return '🌅';
  if (hour >= 12 && hour < 18) return '☀️';
  return '🌙';
}

class _ActivityCardStatus {
  final Color color;
  final String label;
  final IconData icon;

  const _ActivityCardStatus({
    required this.color,
    required this.label,
    required this.icon,
  });
}
