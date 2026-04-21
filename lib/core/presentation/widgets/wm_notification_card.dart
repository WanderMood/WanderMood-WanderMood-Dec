import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/wm_notification_leading.dart';
import 'package:wandermood/features/realtime/domain/models/realtime_event.dart';

/// Optional tier styling for Mood Match (and similar) — keeps default card when null.
class WmNotificationPresentation {
  const WmNotificationPresentation({
    required this.background,
    required this.borderColor,
    required this.borderWidth,
    required this.titleSize,
    required this.titleWeight,
    required this.listTileVerticalPadding,
    required this.showLeftAccent,
    required this.elevation,
    required this.metaOpacity,
    required this.chipOpacity,
    this.showChevron = false,
  });

  /// Softer, compact status row.
  factory WmNotificationPresentation.moodMatchStatus(bool unread) {
    const cream = Color(0xFFF5F0E8);
    return WmNotificationPresentation(
      background: unread ? const Color(0xFF252320) : const Color(0xFF201F1C),
      borderColor: cream.withValues(alpha: unread ? 0.11 : 0.07),
      borderWidth: 0.75,
      titleSize: 12.75,
      titleWeight: FontWeight.w500,
      listTileVerticalPadding: 6,
      showLeftAccent: false,
      elevation: unread ? 2 : 1,
      metaOpacity: 0.44,
      chipOpacity: unread ? 0.52 : 0.38,
      showChevron: false,
    );
  }

  /// Action-needed row: slightly stronger border, left accent, optional chevron.
  factory WmNotificationPresentation.moodMatchAction(bool unread) {
    const sunset = Color(0xFFE8784A);
    return WmNotificationPresentation(
      background: unread ? const Color(0xFF2A2724) : const Color(0xFF23211E),
      borderColor: sunset.withValues(alpha: unread ? 0.30 : 0.14),
      borderWidth: unread ? 1.05 : 0.75,
      titleSize: 13.0,
      titleWeight: FontWeight.w600,
      listTileVerticalPadding: 10,
      showLeftAccent: true,
      elevation: unread ? 4 : 2,
      metaOpacity: 0.48,
      chipOpacity: unread ? 0.85 : 0.62,
      showChevron: true,
    );
  }

  /// Highlight milestone — restrained, not loud.
  factory WmNotificationPresentation.moodMatchHighlight(bool unread) {
    const sunset = Color(0xFFE8784A);
    return WmNotificationPresentation(
      background: unread ? const Color(0xFF2F2822) : const Color(0xFF28241F),
      borderColor: sunset.withValues(alpha: unread ? 0.34 : 0.18),
      borderWidth: unread ? 1.0 : 0.8,
      titleSize: 13.5,
      titleWeight: FontWeight.w600,
      listTileVerticalPadding: 11,
      showLeftAccent: true,
      elevation: unread ? 5 : 3,
      metaOpacity: 0.5,
      chipOpacity: unread ? 0.88 : 0.72,
      showChevron: true,
    );
  }

  final Color background;
  final Color borderColor;
  final double borderWidth;
  final double titleSize;
  final FontWeight titleWeight;
  final double listTileVerticalPadding;
  final bool showLeftAccent;
  final double elevation;
  final double metaOpacity;
  final double chipOpacity;
  final bool showChevron;
}

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
    this.onDelete,
    this.deleteTooltip,
    this.senderAvatarUrl,
    this.showSenderAvatar = false,
    this.presentation,
  });

  final RealtimeEvent event;
  final String body;
  final String meta;
  final String categoryLabel;
  final bool unread;
  final Color iconBg;
  final VoidCallback? onTap;
  /// Remove from the in-app list (does not replace swipe-to-dismiss).
  final VoidCallback? onDelete;
  final String? deleteTooltip;
  final String? senderAvatarUrl;
  final bool showSenderAvatar;
  final WmNotificationPresentation? presentation;

  static const Color _cream = Color(0xFFF5F0E8);
  static const Color _sunset = Color(0xFFE8784A);

  @override
  Widget build(BuildContext context) {
    final p = presentation;
    final bg = p?.background ?? (unread ? const Color(0xFF2A2722) : const Color(0xFF23211D));
    final border = p?.borderColor ??
        (unread
            ? _sunset.withValues(alpha: 0.45)
            : _cream.withValues(alpha: 0.14));
    final borderW = p?.borderWidth ?? (unread ? 1.25 : 1.0);
    final titleStyle = GoogleFonts.poppins(
      fontSize: p?.titleSize ?? 13,
      fontWeight: p?.titleWeight ?? FontWeight.w500,
      height: 1.4,
      color: _cream.withValues(alpha: 0.92),
    );
    final metaStyle = GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: _cream.withValues(alpha: p?.metaOpacity ?? 0.48),
    );
    final chipStyle = GoogleFonts.poppins(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: _sunset.withValues(alpha: p?.chipOpacity ?? (unread ? 0.95 : 0.72)),
    );
    final vPad = p?.listTileVerticalPadding ?? 8.0;
    final elevation = p?.elevation ?? (unread ? 6.0 : 3.0);

    Widget? trailingWidget;
    if (p?.showChevron == true || onDelete != null) {
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (p?.showChevron == true)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: _cream.withValues(alpha: 0.28),
              ),
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: _cream.withValues(alpha: 0.5),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              tooltip: deleteTooltip ?? 'Remove',
              onPressed: onDelete,
            ),
        ],
      );
    }

    final tile = ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: vPad),
      horizontalTitleGap: 10,
      minLeadingWidth: 36,
      trailing: trailingWidget,
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
                decoration:
                    const BoxDecoration(color: _sunset, shape: BoxShape.circle),
              ),
            Expanded(child: Text(meta, style: metaStyle)),
            Text(categoryLabel.toUpperCase(), style: chipStyle),
          ],
        ),
      ),
    );

    // Rounded `BoxDecoration` borders must use a single border color; a
    // multi-color `Border` throws ("borderRadius can only be given on borders
    // with uniform colors"). Avoid `Stack` + vertical `Positioned` in scrollables
    // (unbounded height). Accent: `IntrinsicHeight` + stretched strip + uniform
    // outline (only for tiers that use `showLeftAccent`).
    final radius = BorderRadius.circular(14);
    final showAccent = p?.showLeftAccent == true;
    final accentLine = _sunset.withValues(alpha: unread ? 0.75 : 0.45);
    final surfaceDecoration = BoxDecoration(
      color: bg,
      borderRadius: radius,
      border: Border.all(width: borderW, color: border),
    );

    final surfaceChild = showAccent
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: accentLine),
                Expanded(child: tile),
              ],
            ),
          )
        : tile;

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: elevation * 0.85,
            offset: Offset(0, elevation * 0.22),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: DecoratedBox(
              decoration: surfaceDecoration,
              child: surfaceChild,
            ),
          ),
        ),
      ),
    );
  }
}
