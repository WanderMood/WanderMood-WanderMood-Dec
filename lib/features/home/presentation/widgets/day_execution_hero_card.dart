import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/home/presentation/utils/my_day_activity_id.dart';
import 'package:wandermood/features/home/presentation/utils/my_day_display_title.dart';
import 'package:wandermood/features/home/presentation/utils/my_day_slot_period.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/features/mood/models/activity_rating.dart';
import 'package:wandermood/features/mood/services/activity_rating_service.dart';
import 'package:wandermood/features/home/presentation/widgets/activity_review_sheet.dart';
// WanderMood v2 tokens (Screen 3 — My Day execution hero)
const Color _wmSky = Color(0xFFA8C8DC);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);

/// Lifted hero cards — tinted glow + neutral depth (read against cream screen bg).
List<BoxShadow> _forestHeroShadows() => [
      BoxShadow(
        color: _wmForest.withValues(alpha: 0.34),
        blurRadius: 28,
        offset: const Offset(0, 14),
      ),
      BoxShadow(
        color: _wmCharcoal.withValues(alpha: 0.14),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];

List<BoxShadow> _skyHeroShadows() => [
      BoxShadow(
        color: const Color(0xFF6B90A8).withValues(alpha: 0.38),
        blurRadius: 26,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: _wmCharcoal.withValues(alpha: 0.12),
        blurRadius: 22,
        offset: const Offset(0, 7),
      ),
    ];

enum DayExecutionHeroState {
  active,
  upcoming,
  completed,
}

class DayExecutionHeroCard extends ConsumerWidget {
  final EnhancedActivityData activity;
  final DayExecutionHeroState state;
  final VoidCallback onDirections;
  final VoidCallback? onCheckIn;
  final VoidCallback? onMarkDone;

  const DayExecutionHeroCard({
    super.key,
    required this.activity,
    required this.state,
    required this.onDirections,
    this.onCheckIn,
    this.onMarkDone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state == DayExecutionHeroState.upcoming) {
      return _UpcomingExecutionHero(
        activity: activity,
        onDirections: onDirections,
        onCheckIn: onCheckIn ?? () {},
      );
    }

    if (state == DayExecutionHeroState.active) {
      return _ActiveExecutionHero(
        activity: activity,
        onDirections: onDirections,
        onMarkDone: onMarkDone ?? () {},
      );
    }

    final activityId = myDayStableActivityId(activity.rawData);
    final ratingAsync = ref.watch(activityRatingForActivityProvider(activityId));

    return ratingAsync.when(
      data: (rating) => state == DayExecutionHeroState.completed
          ? _CompletedExecutionHero(
              activity: activity,
              onDirections: onDirections,
              onReview: rating != null
                  ? null
                  : () => showActivityReviewSheet(context, activity),
              rating: rating,
            )
          : _ActiveExecutionHero(
              activity: activity,
              onDirections: onDirections,
              onMarkDone: onMarkDone ?? () {},
            ),
      loading: () => state == DayExecutionHeroState.completed
          ? _CompletedExecutionHero(
              activity: activity,
              onDirections: onDirections,
              onReview: () => showActivityReviewSheet(context, activity),
              rating: null,
            )
          : _ActiveExecutionHero(
              activity: activity,
              onDirections: onDirections,
              onMarkDone: onMarkDone ?? () {},
            ),
      error: (_, __) => state == DayExecutionHeroState.completed
          ? _CompletedExecutionHero(
              activity: activity,
              onDirections: onDirections,
              onReview: () => showActivityReviewSheet(context, activity),
              rating: null,
            )
          : _ActiveExecutionHero(
              activity: activity,
              onDirections: onDirections,
              onMarkDone: onMarkDone ?? () {},
            ),
    );
  }
}

class _ActiveExecutionHero extends StatelessWidget {
  final EnhancedActivityData activity;
  final VoidCallback onDirections;
  final VoidCallback onMarkDone;

  const _ActiveExecutionHero({
    required this.activity,
    required this.onDirections,
    required this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _heroActivityTitle(context, activity.rawData);
    final slot = _slotEmoji(activity.startTime.hour);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: _wmSky,
        border: Border.all(color: _wmParchment, width: 0.5),
        boxShadow: _skyHeroShadows(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(slot, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.myDayExecutionHeroYoureHereBadge,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _wmCharcoal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.myDayExecutionHeroInProgressBadge,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: _wmCharcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _wmCharcoal,
              height: 1.16,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.myDayExecutionHeroActiveHint,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: _wmStone,
              height: 1.32,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroButton(
                  label: l10n.activityDetailDirections,
                  icon: Icons.navigation_rounded,
                  filled: false,
                  onTap: onDirections,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroButton(
                  label: l10n.myDayTimelinePrimaryDone,
                  icon: Icons.check_rounded,
                  filled: true,
                  onTap: onMarkDone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletedExecutionHero extends StatelessWidget {
  final EnhancedActivityData activity;
  final VoidCallback onDirections;
  final VoidCallback? onReview;
  final ActivityRating? rating;

  const _CompletedExecutionHero({
    required this.activity,
    required this.onDirections,
    required this.onReview,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _heroActivityTitle(context, activity.rawData);
    final hasReview = rating != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: _wmForest,
        border: Border.all(color: _wmParchment, width: 0.5),
        boxShadow: _forestHeroShadows(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          hasReview
                              ? l10n.myDayExecutionHeroReviewedAt(
                                  _formatTime(context, rating!.completedAt),
                                )
                              : l10n.myDayExecutionHeroCompletedToday,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasReview
                        ? l10n.myDayExecutionHeroBadgeReviewedCaps
                        : l10n.myDayExecutionHeroBadgeReadyToReviewCaps,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.16,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (hasReview) ...[
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
                      '"${rating!.notes!}"',
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
          ] else
            Text(
              l10n.myDayExecutionHeroReviewCaptureHint,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.82),
                height: 1.32,
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroButton(
                  label: l10n.activityDetailDirections,
                  icon: Icons.navigation_rounded,
                  filled: false,
                  onColoredCard: true,
                  onTap: onDirections,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: hasReview
                    ? _DimmedButton(
                        label: l10n.myDayTimelinePrimaryReviewed,
                        icon: Icons.check_rounded,
                      )
                    : _HeroButton(
                        label: l10n.myDayTimelinePrimaryReview,
                        icon: Icons.star_outline_rounded,
                        filled: true,
                        primaryOnForestCard: true,
                        onTap: onReview ?? () {},
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingExecutionHero extends StatelessWidget {
  final EnhancedActivityData activity;
  final VoidCallback onDirections;
  final VoidCallback onCheckIn;

  const _UpcomingExecutionHero({
    required this.activity,
    required this.onDirections,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _heroActivityTitle(context, activity.rawData);
    final slotEmoji = _slotEmoji(activity.startTime.hour);
    final slotName = myDayActivitySlotPeriodLabel(
      AppLocalizations.of(context)!,
      activity.startTime,
      MoodyClock.now(),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: _wmForest,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 0.5,
        ),
        boxShadow: _forestHeroShadows(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(slotEmoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          slotName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    l10n.myDayExecutionHeroUpNextBadge,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.16,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.myDayExecutionHeroTapImHereWhenArrive,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.32,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroButton(
                  label: l10n.activityDetailDirections,
                  icon: Icons.navigation_rounded,
                  filled: false,
                  onColoredCard: true,
                  onTap: onDirections,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroButton(
                  label: l10n.myDayTimelinePrimaryImHere,
                  icon: Icons.place_rounded,
                  filled: true,
                  primaryOnForestCard: true,
                  onTap: onCheckIn,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  /// Secondary style on wmForest / wmSunset cards: light outline + white label.
  final bool onColoredCard;
  /// Primary CTA on solid wmForest hero (white fill + forest label).
  final bool primaryOnForestCard;

  const _HeroButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
    this.onColoredCard = false,
    this.primaryOnForestCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryBorder = onColoredCard
        ? BorderSide(color: Colors.white.withValues(alpha: 0.55), width: 1)
        : BorderSide(color: _wmForest.withValues(alpha: 0.45), width: 1);
    final secondaryFg = onColoredCard ? Colors.white : _wmForest;
    final secondaryBg =
        onColoredCard ? Colors.white.withValues(alpha: 0.12) : Colors.white;

    final filledBg = primaryOnForestCard ? Colors.white : _wmForest;
    final filledFg = primaryOnForestCard ? _wmForest : Colors.white;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: filled ? filledBg : secondaryBg,
        // Use `shape` only — Material forbids both `shape` and `borderRadius`.
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: filled && primaryOnForestCard
              ? BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 0.75)
              : filled
                  ? BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 0.75)
                  : secondaryBorder,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTapDown: (_) => HapticFeedback.lightImpact(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: Icon(icon, size: 18, color: filled ? filledFg : secondaryFg),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: filled ? filledFg : secondaryFg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A non-interactive, visually muted button for completed/locked states.
class _DimmedButton extends StatelessWidget {
  final String label;
  final IconData icon;

  const _DimmedButton({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.55)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

String _slotEmoji(int hour) {
  if (hour >= 6 && hour < 12) return '🌅';
  if (hour >= 12 && hour < 18) return '☀️';
  return '🌙';
}

String _heroActivityTitle(BuildContext context, Map<String, dynamic> rawData) {
  final l10n = AppLocalizations.of(context)!;
  final t = rawData['title'] as String?;
  if (t != null && t.trim().isNotEmpty) {
    return myDayShortActivityTitle(t);
  }
  return l10n.myDayActivityFallbackLabel;
}

String _formatTime(BuildContext context, DateTime time) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.jm(locale).format(time);
}
