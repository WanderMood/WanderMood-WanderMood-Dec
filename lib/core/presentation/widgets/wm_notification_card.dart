import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/wm_notification_leading.dart';
import 'package:wandermood/features/realtime/domain/models/realtime_event.dart';

/// Single notification row for the in-app centre (Moody styling).
class WmNotificationCard extends StatelessWidget {
  const WmNotificationCard({
    super.key,
    required this.event,
    required this.body,
    required this.meta,
    required this.categoryLabel,
    required this.unread,
    required this.iconBg,
    this.onTap,
    this.senderAvatarUrl,
    this.showSenderAvatar = false,
  });

  final RealtimeEvent event;
  final String body;
  final String meta;
  final String categoryLabel;
  final bool unread;
  final Color iconBg;
  final VoidCallback? onTap;
  final String? senderAvatarUrl;
  final bool showSenderAvatar;

  static const Color _cream = Color(0xFFF5F0E8);
  static const Color _sunset = Color(0xFFE8784A);

  @override
  Widget build(BuildContext context) {
    final bg = unread ? const Color(0xFF2A2722) : const Color(0xFF23211D);
    final border = unread
        ? _sunset.withValues(alpha: 0.45)
        : _cream.withValues(alpha: 0.14);
    final titleStyle = GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: _cream.withValues(alpha: 0.92));
    final metaStyle = GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _cream.withValues(alpha: 0.48));
    final chipStyle = GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: _sunset.withValues(alpha: unread ? 0.95 : 0.72));
    return Card(
      color: bg,
      elevation: unread ? 6 : 3,
      shadowColor: Colors.black.withValues(alpha: 0.55),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(width: unread ? 1.25 : 1, color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          horizontalTitleGap: 10,
          minLeadingWidth: 36,
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _cream.withValues(alpha: 0.1)),
            ),
            child: WmNotificationLeading(
              event: event,
              senderAvatarUrl: senderAvatarUrl,
              showSenderAvatar: showSenderAvatar,
            ),
          ),
          title: Text(body, style: titleStyle),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                if (unread)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                        color: _sunset, shape: BoxShape.circle),
                  ),
                Expanded(child: Text(meta, style: metaStyle)),
                Text(categoryLabel.toUpperCase(), style: chipStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
