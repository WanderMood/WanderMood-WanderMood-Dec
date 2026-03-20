import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/mood/models/activity_rating.dart';
import 'package:wandermood/features/mood/services/activity_rating_service.dart';
import 'package:wandermood/features/home/presentation/widgets/activity_review_sheet.dart';

enum DayExecutionHeroState {
  active,
  upcoming,
  awaitingCompletion,
  completed,
}

class DayExecutionHeroCard extends ConsumerWidget {
  final EnhancedActivityData activity;
  final DayExecutionHeroState state;
  final VoidCallback onDirections;
  final VoidCallback? onGetReady;
  final VoidCallback? onMarkDone;
  final VoidCallback? onStillHere;

  const DayExecutionHeroCard({
    super.key,
    required this.activity,
    required this.state,
    required this.onDirections,
    this.onGetReady,
    this.onMarkDone,
    this.onStillHere,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state == DayExecutionHeroState.upcoming) {
      return _UpcomingExecutionHero(
        activity: activity,
        onDirections: onDirections,
        onGetReady: onGetReady ?? () {},
      );
    }

    if (state == DayExecutionHeroState.awaitingCompletion) {
      return _AwaitingCompletionHero(
        activity: activity,
        onMarkDone: onMarkDone ?? () {},
        onStillHere: onStillHere ?? () {},
      );
    }

    if (state == DayExecutionHeroState.active) {
      return _ActiveExecutionHero(
        activity: activity,
        onDirections: onDirections,
      );
    }

    final activityId =
        (activity.rawData['id'] as String?) ??
        (activity.rawData['title'] as String? ?? '');
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
            ),
    );
  }
}

class _ActiveExecutionHero extends StatelessWidget {
  final EnhancedActivityData activity;
  final VoidCallback onDirections;

  const _ActiveExecutionHero({
    required this.activity,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    final title = activity.rawData['title'] as String? ?? 'Activity';
    final timeStr = _formatTime(activity.startTime);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFA8C8DC),
        boxShadow: const [],
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
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Now - $timeStr',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1C18),
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
                  'In Progress',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: const Color(0xFF1E1C18),
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
          const SizedBox(height: 8),
          Text(
            'You are in the middle of this activity right now.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E1C18),
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
                  label: 'In Progress',
                  icon: Icons.play_arrow_rounded,
                  filled: true,
                  onTap: () {},
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
    final title = activity.rawData['title'] as String? ?? 'Activity';
    final hasReview = rating != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasReview
              ? const [Color(0xFF2A6049), Color(0xFF2A6049)]
              : const [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
        ),
        boxShadow: const [],
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
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasReview
                          ? 'Reviewed at ${_formatTime(rating!.completedAt)}'
                          : 'Completed today',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
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
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hasReview ? 'REVIEWED' : 'READY TO REVIEW',
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
              'Capture how it felt while the experience is still fresh.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.92),
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
                  label: hasReview ? 'Reviewed' : 'Review',
                  icon: Icons.check_rounded,
                  filled: true,
                  onTap: hasReview ? () {} : (onReview ?? () {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AwaitingCompletionHero extends StatelessWidget {
  final EnhancedActivityData activity;
  final VoidCallback onMarkDone;
  final VoidCallback onStillHere;

  const _AwaitingCompletionHero({
    required this.activity,
    required this.onMarkDone,
    required this.onStillHere,
  });

  @override
  Widget build(BuildContext context) {
    final title = activity.rawData['title'] as String? ?? 'Activity';
    final finishedAgo = activity.timeSinceStart;
    final finishedAgoText = finishedAgo != null
        ? _formatDuration(finishedAgo)
        : 'a little while';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFE8784A),
        boxShadow: const [],
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
                    const Icon(
                      Icons.access_time_filled_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Planned to end $finishedAgoText ago',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
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
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'CHECK IN',
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
          const SizedBox(height: 8),
          Text(
            'Still enjoying it? Keep it active a bit longer, or mark it done and review it later.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E1C18),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroButton(
                  label: 'Still Here',
                  icon: Icons.schedule_rounded,
                  filled: false,
                  onTap: onStillHere,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroButton(
                  label: 'Done',
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

class _UpcomingExecutionHero extends StatelessWidget {
  final EnhancedActivityData activity;
  final VoidCallback onDirections;
  final VoidCallback onGetReady;

  const _UpcomingExecutionHero({
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
        boxShadow: const [],
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
              color: const Color(0xFF1E1C18),
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

class _HeroButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _HeroButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? const Color(0xFF2A6049) : Colors.white,
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
              Icon(icon, size: 18, color: filled ? Colors.white : const Color(0xFF2A6049)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : const Color(0xFF2A6049),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
