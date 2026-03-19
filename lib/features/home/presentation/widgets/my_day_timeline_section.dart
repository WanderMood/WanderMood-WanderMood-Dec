import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/home/presentation/widgets/activity_review_sheet.dart';
import 'package:wandermood/features/mood/services/activity_rating_service.dart';

import '../screens/dynamic_my_day_provider.dart';

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
    required this.formatTime,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final allCompleted = activities.every(
      (activity) => activity.status == ActivityStatus.completed,
    );

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: isFirstSection ? 0 : 24),
            GestureDetector(
              onTap: allCompleted ? onToggleCollapse : null,
              child: Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.museoModerno(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF12B347),
                    ),
                  ),
                  if (allCompleted) ...[
                    const SizedBox(width: 8),
                    Icon(
                      isCollapsed ? Icons.expand_more : Icons.expand_less,
                      color: const Color(0xFF12B347),
                      size: 18,
                    ),
                  ],
                  const Spacer(),
                  if (allCompleted) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12B347).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF12B347).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF12B347),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'All Done',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF12B347),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '${activities.length} ${activities.length == 1 ? 'activity' : 'activities'}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: allCompleted ? const Color(0xFF12B347) : Colors.grey[600],
                      fontWeight: allCompleted ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              allCompleted ? 'Great job completing this section!' : subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: allCompleted ? const Color(0xFF12B347) : Colors.grey[600],
                fontWeight: allCompleted ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 16),
            if (!allCompleted || !isCollapsed)
              ...activities.asMap().entries.map((entry) {
                final index = entry.key;
                final activity = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: MyDayTimelineActivityCard(
                    activity: activity,
                    onTap: () => onActivityTap(activity),
                    onDirectionsTap: () => onDirectionsTap(activity),
                    onMoreTap: () => onMoreTap(activity),
                    formatTime: formatTime,
                  ).animate(delay: (index * 100).ms)
                      .slideX(begin: 0.3, duration: 600.ms)
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.9, 0.9), duration: 400.ms),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class MyDayTimelineActivityCard extends ConsumerWidget {
  final EnhancedActivityData activity;
  final VoidCallback onTap;
  final VoidCallback onDirectionsTap;
  final VoidCallback onMoreTap;
  final String Function(DateTime time) formatTime;

  const MyDayTimelineActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    required this.onDirectionsTap,
    required this.onMoreTap,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardStatus = _buildCardStatus(activity);
    final activityId =
        (activity.rawData['id'] as String?) ??
        (activity.rawData['title'] as String? ?? '');
    final ratingAsync = activity.status == ActivityStatus.completed
        ? ref.watch(activityRatingForActivityProvider(activityId))
        : null;
    final hasReview = ratingAsync?.maybeWhen(
          data: (rating) => rating != null,
          orElse: () => false,
        ) ??
        false;
    final isAwaitingCompletion =
        activity.status == ActivityStatus.awaitingCompletion;
    final primaryLabel = activity.status == ActivityStatus.completed
        ? (hasReview ? 'Reviewed' : 'Review')
        : isAwaitingCompletion
            ? 'Done'
            : 'Directions';
    final primaryColor = activity.status == ActivityStatus.completed
        ? (hasReview ? const Color(0xFF16A34A) : const Color(0xFF8B5CF6))
        : isAwaitingCompletion
            ? const Color(0xFF16A34A)
            : const Color(0xFF12B347);
    final subtitleText = isAwaitingCompletion
        ? 'Mark done or tap more for still here'
        : 'Tap for details';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 15),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: cardStatus.color.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -5,
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
                      child: CachedNetworkImage(
                        imageUrl: activity.rawData['imageUrl'] ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cardStatus.color.withOpacity(0.8),
                                cardStatus.color.withOpacity(0.6),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.schedule,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${formatTime(activity.startTime)} • ${activity.rawData['duration']}m',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: cardStatus.color,
                                    borderRadius: BorderRadius.circular(20),
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
                              activity.rawData['title'],
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
                          Text(
                            activity.rawData['category'] ?? 'Activity',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            subtitleText,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                if (activity.status == ActivityStatus.completed) {
                                  if (!hasReview) {
                                    showActivityReviewSheet(context, activity);
                                  }
                                  return;
                                }
                                onDirectionsTap();
                              },
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
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onMoreTap();
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.more_vert,
                              size: 16,
                              color: Colors.grey,
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
    );
  }
}

_ActivityCardStatus _buildCardStatus(EnhancedActivityData activity) {
  switch (activity.status) {
    case ActivityStatus.activeNow:
      return const _ActivityCardStatus(
        color: Colors.red,
        label: 'RIGHT NOW',
        icon: Icons.play_circle_filled,
      );
    case ActivityStatus.awaitingCompletion:
      return const _ActivityCardStatus(
        color: Color(0xFFF59E0B),
        label: 'CHECK IN',
        icon: Icons.hourglass_bottom_rounded,
      );
    case ActivityStatus.upcoming:
      return const _ActivityCardStatus(
        color: Colors.orange,
        label: 'UPCOMING',
        icon: Icons.schedule,
      );
    case ActivityStatus.completed:
      return const _ActivityCardStatus(
        color: Colors.green,
        label: 'COMPLETED',
        icon: Icons.check_circle,
      );
    default:
      return const _ActivityCardStatus(
        color: Color(0xFF12B347),
        label: 'SCHEDULED',
        icon: Icons.event,
      );
  }
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
