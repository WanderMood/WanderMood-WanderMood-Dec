import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared visual tokens for group planning (matches WanderMood design system).
abstract final class GroupPlanningUi {
  static const Color forest = Color(0xFF2A6049);
  static const Color cream = Color(0xFFF5F0E8);
  static const Color charcoal = Color(0xFF1E1C18);
  static const Color stone = Color(0xFF8C8780);
  static const Color forestTint = Color(0xFFEBF3EE);
  static const Color dusk = Color(0xFF4A4640);

  /// Warm deep brown for Mood Match hero, reveal, and result (not flat black).
  static const Color moodMatchDeep = Color(0xFF2A211C);
  static const Color moodMatchDeepSurface = Color(0xFF362B23);
  static const Color moodMatchDeepMuted = Color(0xFF4A3F36);

  /// Shadow / scrim tint from the mood-match palette (avoids pure black).
  static Color moodMatchShadow(double alpha) =>
      moodMatchDeep.withValues(alpha: alpha);

  static Color get cardBorder => const Color.fromRGBO(30, 28, 24, 0.07);

  static BoxDecoration cardDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: moodMatchShadow(0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration softCardDecoration({required Color background}) {
    return BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: cardBorder),
    );
  }

  /// Custom primary CTA (replaces FilledButton look).
  static Widget primaryCta({
    required String label,
    required VoidCallback? onPressed,
    Widget? leading,
    bool busy = false,
    String? busyLabel,
  }) {
    final enabled = onPressed != null && !busy;
    return Material(
      color: enabled ? forest : stone.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: Center(
            child: busy
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      if (busyLabel != null && busyLabel.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            busyLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (leading != null) ...[
                        leading,
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

  static Widget secondaryCta({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: forestTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: forest.withValues(alpha: 0.15), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: forest,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Blurred scrim + fade for premium modals (Mood Match lock-in, day confirm).
  static Future<T?> showBlurredDialog<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: ColoredBox(
                    color: moodMatchShadow(0.42),
                  ),
                ),
              ),
            ),
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: Center(child: child),
            ),
          ],
        );
      },
    );
  }

  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    VoidCallback? onBack,
  }) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: cream,
      foregroundColor: charcoal,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: onBack ??
            () {
              if (context.canPop()) {
                context.pop();
              }
            },
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: charcoal,
        ),
      ),
      actions: actions,
    );
  }
}
