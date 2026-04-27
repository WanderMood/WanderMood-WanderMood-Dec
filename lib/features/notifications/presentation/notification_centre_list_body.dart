import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/realtime/domain/models/realtime_event.dart';
import 'package:wandermood/l10n/app_localizations.dart';

import 'notification_centre_mood_match.dart';

typedef NotificationCentreItemBuilder = Widget Function(
  RealtimeEvent e,
  NotificationCentreRowContext ctx,
);

/// Scrollable notification list + empty state (keeps [NotificationCentreScreen] lean).
class NotificationCentreListBody extends StatelessWidget {
  const NotificationCentreListBody({
    super.key,
    required this.l10n,
    required this.emptyText,
    required this.showLoading,
    required this.showEmpty,
    required this.unread,
    required this.read,
    required this.loadingMore,
    required this.hasMore,
    required this.onNearEnd,
    required this.itemBuilder,
    this.cream = const Color(0xFFF5F0E8),
    this.moodMatchMergedTimeline = false,
    this.moodMatchOrderedItems,
    this.moodMatchHeader,
    this.enableMoodMatchSpacingHints = false,
  });

  final AppLocalizations l10n;
  final String emptyText;
  final bool showLoading;
  final bool showEmpty;
  final List<RealtimeEvent> unread;
  final List<RealtimeEvent> read;
  final bool loadingMore;
  final bool hasMore;
  final VoidCallback onNearEnd;
  final NotificationCentreItemBuilder itemBuilder;
  final Color cream;

  /// Single chronological column (oldest → newest) with optional [moodMatchHeader].
  final bool moodMatchMergedTimeline;
  final List<RealtimeEvent>? moodMatchOrderedItems;
  final Widget? moodMatchHeader;

  /// Tighten spacing between related day-flow rows (same session).
  final bool enableMoodMatchSpacingHints;

  @override
  Widget build(BuildContext context) {
    if (showLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE8784A)));
    }
    if (showEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyText,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: cream.withValues(alpha: 0.55),
              height: 1.45,
            ),
          ),
        ),
      );
    }

    if (moodMatchMergedTimeline && moodMatchOrderedItems != null) {
      final items = moodMatchOrderedItems!;
      return NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > n.metrics.maxScrollExtent - 120 && !loadingMore && hasMore) {
            onNearEnd();
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (moodMatchHeader != null) moodMatchHeader!,
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0 &&
                  enableMoodMatchSpacingHints &&
                  items[i].isRead != items[i - 1].isRead &&
                  !items[i - 1].isRead &&
                  items[i].isRead)
                _readTransitionMarker(l10n, cream),
              itemBuilder(
                items[i],
                NotificationCentreRowContext(
                  previous: i > 0 ? items[i - 1] : null,
                  index: i,
                  tightenTop: enableMoodMatchSpacingHints &&
                      moodMatchTightenTopSpacing(items[i], i > 0 ? items[i - 1] : null),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 120 && !loadingMore && hasMore) {
          onNearEnd();
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (unread.isNotEmpty) ...[
            _section(l10n.notificationCentreSectionNew),
            for (var i = 0; i < unread.length; i++)
              itemBuilder(
                unread[i],
                NotificationCentreRowContext(
                  previous: i > 0 ? unread[i - 1] : null,
                  index: i,
                  tightenTop: enableMoodMatchSpacingHints &&
                      moodMatchTightenTopSpacing(unread[i], i > 0 ? unread[i - 1] : null),
                ),
              ),
            const SizedBox(height: 16),
          ],
          if (read.isNotEmpty) ...[
            _section(l10n.notificationCentreSectionEarlier),
            for (var i = 0; i < read.length; i++)
              itemBuilder(
                read[i],
                NotificationCentreRowContext(
                  previous: i > 0 ? read[i - 1] : null,
                  index: i,
                  tightenTop: enableMoodMatchSpacingHints &&
                      moodMatchTightenTopSpacing(read[i], i > 0 ? read[i - 1] : null),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _readTransitionMarker(AppLocalizations l10n, Color cream) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 10),
        child: Row(
          children: [
            Expanded(child: Divider(color: cream.withValues(alpha: 0.12), height: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                l10n.notificationCentreReadDividerLabel,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                  color: cream.withValues(alpha: 0.32),
                ),
              ),
            ),
            Expanded(child: Divider(color: cream.withValues(alpha: 0.12), height: 1)),
          ],
        ),
      );

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            letterSpacing: 0.6,
            color: cream.withValues(alpha: 0.35),
          ),
        ),
      );
}
