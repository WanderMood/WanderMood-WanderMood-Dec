import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Glass-style mood tile — shared by [MoodHomeScreen] and Mood Match lobby.
/// Includes a short tap scale bump (same interaction pattern as hub selection).
class MoodHubStyleMoodTile extends StatefulWidget {
  const MoodHubStyleMoodTile({
    super.key,
    required this.emoji,
    required this.pastelBase,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.dimmed = false,
    this.emojiSize = 32,
    this.titleSize = 11,
    this.subtitleSize = 8,
    this.tileRadius = 20,
    this.showCheckBadge = true,
  });

  final String emoji;
  final Color pastelBase;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool dimmed;
  final double emojiSize;
  final double titleSize;
  final double subtitleSize;
  final double tileRadius;
  final bool showCheckBadge;

  @override
  State<MoodHubStyleMoodTile> createState() => _MoodHubStyleMoodTileState();
}

class _MoodHubStyleMoodTileState extends State<MoodHubStyleMoodTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tap;

  @override
  void initState() {
    super.initState();
    _tap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap?.call();
    if (widget.onTap != null) {
      _tap.forward(from: 0);
    }
  }

  double _bounceScale() {
    final t = _tap.value;
    if (t <= 0) return 1;
    // One hump: 1 → ~1.12 → settles toward 1.04 while selected is applied outside
    return 1 + 0.12 * math.sin(t * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? widget.pastelBase.withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.6);
    final borderWidth = widget.isSelected ? 2.8 : 1.2;
    final titleWeight =
        widget.isSelected ? FontWeight.w600 : FontWeight.w500;
    final elevation = widget.isSelected ? 10.0 : 6.0;

    return AnimatedBuilder(
      animation: _tap,
      builder: (context, child) {
        final bounce = _bounceScale();
        return Opacity(
          opacity: widget.dimmed ? 0.6 : 1.0,
          child: Transform.scale(
            scale: (widget.isSelected ? 1.04 : 1.0) * bounce,
            child: child,
          ),
        );
      },
      child: Material(
        color: widget.pastelBase,
        elevation: elevation,
        shadowColor: Colors.black.withValues(alpha: 0.22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.tileRadius),
          side: BorderSide(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap != null ? _handleTap : null,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.isSelected)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.85),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(widget.tileRadius),
                    ),
                  ),
                ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.emoji,
                        style: TextStyle(fontSize: widget.emojiSize),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          fontSize: widget.titleSize,
                          fontWeight: titleWeight,
                          color: Colors.black87,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.subtitle != null &&
                          widget.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: GoogleFonts.poppins(
                            fontSize: widget.subtitleSize,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (widget.isSelected && widget.showCheckBadge)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.pastelBase.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Color(0xFF2A6049),
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
}
