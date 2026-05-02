import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mood Match brown (GroupPlanningUi.moodMatchDeepMuted); blended into the
/// legacy neutral stroke for a subtle warm edge when unselected.
const Color _kMoodMatchTileBorder = Color(0xFF4A3F36);
const Color _kTileBorderNeutral = Color(0xFFE7E6E3);
/// How much brown is mixed in (0 = gray only, 1 = full brown).
const double _kMoodMatchBorderBlend = 0.34;

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
    this.premiumFloatingShadow = false,
    this.denseLayout = false,
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
  /// Stronger layered shadow (e.g. mood-change bottom sheet).
  final bool premiumFloatingShadow;
  /// Tighter padding / gaps for small multi-column grids.
  final bool denseLayout;

  @override
  State<MoodHubStyleMoodTile> createState() => _MoodHubStyleMoodTileState();
}

class _MoodHubStyleMoodTileState extends State<MoodHubStyleMoodTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tap;

  Color _accentColor(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withSaturation((hsl.saturation + 0.22).clamp(0.0, 1.0))
        .withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0))
        .toColor();
  }

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
    final accent = _accentColor(widget.pastelBase);
    final tileBackground = widget.isSelected
        ? const Color(0xFFEFF7F2)
        : const Color(0xFFFFFFFF);
    final borderColor = widget.isSelected
        ? const Color(0xFF2A6049)
        : Color.lerp(
            _kTileBorderNeutral,
            _kMoodMatchTileBorder,
            _kMoodMatchBorderBlend,
          )!;
    final borderWidth = widget.isSelected ? 1.8 : 1.0;
    final titleWeight =
        widget.isSelected ? FontWeight.w600 : FontWeight.w500;

    final List<BoxShadow> tileShadows;
    if (widget.premiumFloatingShadow) {
      tileShadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: widget.isSelected ? 0.14 : 0.11),
          blurRadius: widget.isSelected ? 22 : 18,
          offset: const Offset(0, 10),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      tileShadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: widget.isSelected ? 0.08 : 0.04),
          blurRadius: widget.isSelected ? 12 : 8,
          offset: const Offset(0, 3),
        ),
      ];
    }

    return AnimatedBuilder(
      animation: _tap,
      builder: (context, child) {
        final bounce = _bounceScale();
        return Opacity(
          opacity: widget.dimmed ? 0.58 : 1.0,
          child: Transform.scale(
            scale: (widget.isSelected ? 1.02 : 1.0) * bounce,
            child: child,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: tileBackground,
          borderRadius: BorderRadius.circular(widget.tileRadius),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: tileShadows,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.tileRadius),
          clipBehavior: Clip.antiAlias,
            child: InkWell(
            onTap: widget.onTap != null ? _handleTap : null,
            child: Stack(
              children: [
                Padding(
                  padding: widget.denseLayout
                      ? const EdgeInsets.symmetric(horizontal: 3, vertical: 5)
                      : const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: widget.emojiSize *
                              (widget.denseLayout ? 1.55 : 1.75),
                          height: widget.emojiSize *
                              (widget.denseLayout ? 1.55 : 1.75),
                          decoration: BoxDecoration(
                            color: accent.withValues(
                                alpha: widget.isSelected ? 0.2 : 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              widget.emoji,
                              style: TextStyle(
                                fontSize: widget.emojiSize *
                                    (widget.denseLayout ? 0.76 : 0.82),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(height: widget.denseLayout ? 4 : 8),
                        Text(
                          widget.title,
                          style: GoogleFonts.poppins(
                            fontSize: widget.titleSize,
                            fontWeight: titleWeight,
                            color: const Color(0xFF1E1C18),
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: GoogleFonts.poppins(
                              fontSize: widget.subtitleSize,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B6A67),
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
                        color: const Color(0xFF2A6049),
                        shape: BoxShape.circle,
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
                          color: Colors.white,
                        ),
                      ),
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
