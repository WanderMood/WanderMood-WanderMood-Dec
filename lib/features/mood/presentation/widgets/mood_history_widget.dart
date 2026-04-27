import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/auth/domain/providers/auth_provider.dart';
import 'package:wandermood/features/mood/application/mood_service.dart';
import 'package:wandermood/features/mood/domain/models/mood_data.dart';
import 'package:wandermood/features/mood/domain/providers/effective_mood_streak_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/utils/moody_clock.dart';

/// WanderMood v2 mood history — no card shadows; parchment borders; calm empty state.
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);

class MoodHistoryWidget extends ConsumerWidget {
  const MoodHistoryWidget({
    super.key,
    this.daysToShow = 14,
  });

  final int daysToShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userAsyncValue = ref.watch(authStateProvider);

    return userAsyncValue.when(
      data: (user) {
        if (user == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.moodHistoryLoginRequired,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: _wmStone,
                ),
              ),
            ),
          );
        }

        final moodsAsyncValue = ref.watch(userMoodsProvider(user.id));
        return _buildMoodHistory(context, ref, l10n, moodsAsyncValue);
      },
      loading: () => const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _wmForest,
          ),
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.moodHistoryErrorUser,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: _wmStone,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodHistory(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    AsyncValue<List<MoodData>> moodsAsyncValue,
  ) {
    return moodsAsyncValue.when(
      data: (moods) {
        final sortedMoods = List<MoodData>.from(moods)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (sortedMoods.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildV2EmptyState(context, ref, l10n)),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntro(context, l10n),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.moodHistorySectionRecent,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _wmCharcoal,
                ),
              ),
            ),
            SizedBox(
              height: 168,
              child: _buildMoodCarousel(context, l10n, sortedMoods),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.moodHistorySectionTimeline,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _wmCharcoal,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _buildTimeline(context, l10n, sortedMoods),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _wmForest,
          ),
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.moodHistoryErrorMoods,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: _wmStone,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Text(
        l10n.moodHistoryIntro,
        style: GoogleFonts.poppins(
          fontSize: 14,
          height: 1.45,
          color: _wmStone,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildV2EmptyState(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final streakAsync = ref.watch(effectiveMoodStreakProvider);
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          decoration: BoxDecoration(
            color: _wmWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _wmParchment, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              streakAsync.when(
                data: (streak) => Text(
                  '🔥 ${l10n.myDayMoodStreakBadge(streak)}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _wmCharcoal,
                  ),
                ),
                loading: () => const SizedBox(
                  height: 22,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _wmForest,
                      ),
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.moodHistoryEmptyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _wmCharcoal,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.moodHistoryEmptyBody,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.4,
                  color: _wmStone,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              _buildEmptyTimelinePreview(l10n),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/moody'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _wmForest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.moodHistoryEmptyPrimaryCta,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.goNamed('main', extra: {'tab': 1}),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _wmForest,
                    side: const BorderSide(color: _wmForest, width: 1.25),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    l10n.navExplore,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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

  /// Decorative preview of the vertical timeline users will see once they log moods.
  Widget _buildEmptyTimelinePreview(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: List.generate(4, (i) {
            final isHead = i == 0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isHead ? 16 : 10,
                  height: isHead ? 16 : 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isHead ? _wmForestTint : _wmWhite,
                    border: Border.all(
                      color: _wmForest.withValues(alpha: isHead ? 1 : 0.4),
                      width: isHead ? 2 : 1.25,
                    ),
                  ),
                  child: isHead
                      ? const Center(
                          child: Text('✨', style: TextStyle(fontSize: 9, height: 1)),
                        )
                      : null,
                ),
                if (i < 3)
                  Container(
                    width: 2,
                    height: 16,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: _wmParchment,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            );
          }),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l10n.moodHistoryEmptyTimelineHint,
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.45,
                color: _wmStone,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodCarousel(
    BuildContext context,
    AppLocalizations l10n,
    List<MoodData> moods,
  ) {
    final recentMoods = moods.take(daysToShow).toList();

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: recentMoods.length,
      itemBuilder: (context, index) {
        return _buildMoodCarouselCard(context, l10n, recentMoods[index]);
      },
    );
  }

  Widget _buildMoodCarouselCard(
    BuildContext context,
    AppLocalizations l10n,
    MoodData mood,
  ) {
    final isToday = DateFormat('yyyy-MM-dd').format(mood.timestamp) ==
        DateFormat('yyyy-MM-dd').format(MoodyClock.now());

    return Container(
      width: 152,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: _wmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? _wmForest : _wmParchment,
          width: isToday ? 1.5 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getMoodEmoji(mood.moodType),
                  style: const TextStyle(fontSize: 28),
                ),
                const Spacer(),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _wmForestTint,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _wmParchment, width: 0.5),
                    ),
                    child: Text(
                      l10n.moodHistoryTodayBadge,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: _wmForest,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              mood.moodType,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _wmCharcoal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateShort(context, l10n, mood.timestamp),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _wmStone,
              ),
            ),
            if (mood.description != null && mood.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                mood.description!,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: _wmStone,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    AppLocalizations l10n,
    List<MoodData> moods,
  ) {
    final moodsByDay = <String, List<MoodData>>{};
    for (final mood in moods) {
      final dayKey = DateFormat('yyyy-MM-dd').format(mood.timestamp);
      moodsByDay.putIfAbsent(dayKey, () => []).add(mood);
    }

    final sortedDays = moodsByDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.only(left: 8, right: 20, bottom: 24),
      itemCount: sortedDays.length,
      itemBuilder: (context, dayIndex) {
        final dayKey = sortedDays[dayIndex];
        final dayMoods = moodsByDay[dayKey]!;
        final dayDate = DateTime.parse(dayKey);
        dayMoods.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return _buildDaySection(
          context,
          l10n,
          dayDate,
          dayMoods,
          dayIndex == sortedDays.length - 1,
        );
      },
    );
  }

  String _formatDateShort(
    BuildContext context,
    AppLocalizations l10n,
    DateTime date,
  ) {
    final now = MoodyClock.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return '${l10n.moodHistoryDayToday} ${DateFormat('HH:mm').format(date)}';
    }
    if (dateOnly == today.subtract(const Duration(days: 1))) {
      return '${l10n.moodHistoryDayYesterday} ${DateFormat('HH:mm').format(date)}';
    }

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('MMM d, HH:mm', localeTag).format(date);
  }

  Widget _buildDaySection(
    BuildContext context,
    AppLocalizations l10n,
    DateTime day,
    List<MoodData> moods,
    bool isLast,
  ) {
    final isToday = DateFormat('yyyy-MM-dd').format(day) ==
        DateFormat('yyyy-MM-dd').format(MoodyClock.now());
    final isYesterday = DateFormat('yyyy-MM-dd').format(day) ==
        DateFormat('yyyy-MM-dd')
            .format(MoodyClock.now().subtract(const Duration(days: 1)));

    final String dayLabel;
    if (isToday) {
      dayLabel = l10n.moodHistoryDayToday;
    } else if (isYesterday) {
      dayLabel = l10n.moodHistoryDayYesterday;
    } else {
      final localeTag = Localizations.localeOf(context).toLanguageTag();
      dayLabel = DateFormat('EEEE, MMM d', localeTag).format(day);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          child: Text(
            dayLabel,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _wmForest,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Column(
            children: moods.asMap().entries.map((entry) {
              final index = entry.key;
              final mood = entry.value;
              final isLastMood = index == moods.length - 1;
              return _buildMoodTimelineItem(
                context,
                l10n,
                mood,
                showConnectorBelow: !(isLastMood && isLast),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodTimelineItem(
    BuildContext context,
    AppLocalizations l10n,
    MoodData mood, {
    required bool showConnectorBelow,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _wmWhite,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _wmForest,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _getMoodEmoji(mood.moodType),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            if (showConnectorBelow)
              Container(
                width: 2,
                height: 20,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: _wmParchment,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _wmWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _wmParchment, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mood.moodType,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _wmCharcoal,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(mood.timestamp),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _wmStone,
                        ),
                      ),
                    ],
                  ),
                  if (mood.description != null && mood.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      mood.description!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.4,
                        color: _wmStone,
                      ),
                    ),
                  ],
                  if (mood.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: mood.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _wmForestTint,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _wmParchment,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _wmForest,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  String _getMoodEmoji(String moodType) {
    final lowerMood = moodType.toLowerCase();

    if (lowerMood.contains('happy') ||
        lowerMood.contains('joy') ||
        lowerMood == 'blij') {
      return '😊';
    }
    if (lowerMood.contains('energetic') || lowerMood == 'energiek') {
      return '⚡';
    }
    if (lowerMood.contains('relaxed') ||
        lowerMood.contains('calm') ||
        lowerMood == 'rustig') {
      return '😌';
    }
    if (lowerMood.contains('sad') ||
        lowerMood.contains('sorrow') ||
        lowerMood == 'verdrietig') {
      return '😢';
    }
    if (lowerMood.contains('angry') ||
        lowerMood.contains('mad') ||
        lowerMood == 'boos') {
      return '😠';
    }
    if (lowerMood.contains('adventurous')) {
      return '🏔️';
    }
    if (lowerMood.contains('romantic')) {
      return '💕';
    }
    if (lowerMood.contains('cultural')) {
      return '🎭';
    }
    if (lowerMood.contains('social')) {
      return '👥';
    }
    if (lowerMood.contains('contemplative')) {
      return '🧘';
    }
    if (lowerMood.contains('creative')) {
      return '🎨';
    }

    return '😐';
  }
}
