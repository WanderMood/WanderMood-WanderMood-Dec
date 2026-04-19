import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/realtime/domain/models/realtime_event.dart';

/// Scrollable notification list + empty state (keeps [NotificationCentreScreen] lean).
class NotificationCentreListBody extends StatelessWidget {
  const NotificationCentreListBody({
    super.key,
    required this.nl,
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
  });

  final bool nl;
  final String emptyText;
  final bool showLoading;
  final bool showEmpty;
  final List<RealtimeEvent> unread;
  final List<RealtimeEvent> read;
  final bool loadingMore;
  final bool hasMore;
  final VoidCallback onNearEnd;
  final Widget Function(RealtimeEvent e) itemBuilder;
  final Color cream;

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
            _section(nl ? 'Nieuw' : 'New'),
            ...unread.map(itemBuilder),
            const SizedBox(height: 16),
          ],
          if (read.isNotEmpty) ...[
            _section(nl ? 'Eerder' : 'Earlier'),
            ...read.map(itemBuilder),
          ],
        ],
      ),
    );
  }

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
