import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:wandermood/l10n/app_localizations.dart';

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

  /// Hub + match cards: primary pill CTAs (warm brown, NL “Verder” reference).
  static const Color moodMatchCtaBrown = Color(0xFF6B4A3A);

  /// Hub Active tab selected fill (segmented control).
  static const Color moodMatchTabActiveOrange = Color(0xFFE07A3F);

  /// Shadow / scrim tint from the mood-match palette (avoids pure black).
  static Color moodMatchShadow(double alpha) =>
      moodMatchDeep.withValues(alpha: alpha);

  static Color get cardBorder => const Color.fromRGBO(30, 28, 24, 0.07);

  /// White card on cream: single diffuse shadow (reads “floating”, no sharp corners).
  static BoxDecoration moodMatchFloatingCard({double radius = 28}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: moodMatchShadow(0.09),
          blurRadius: 32,
          offset: const Offset(0, 12),
          spreadRadius: 0,
        ),
      ],
    );
  }

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

  /// Classify a thrown error into a localized, user-safe message.
  ///
  /// Prefers specific messages (network, service) and falls back to a generic
  /// copy. The raw error is never shown to the user — it's only logged for
  /// developers via [debugPrint]. Pass a custom [fallback] to override the
  /// generic message (e.g. "Could not join session.").
  static String classifyError(
    AppLocalizations l10n,
    Object? error, {
    String? fallback,
  }) {
    // Some legacy copy uses "Could not join: {error}" style. When we pass an
    // empty {error}, we end up with trailing ": " — strip it so the sentence
    // still reads cleanly.
    String cleanFallback(String? v) {
      if (v == null) return l10n.planLoadingErrorGeneric;
      var s = v.trim();
      while (s.endsWith(':') || s.endsWith(',') || s.endsWith('-')) {
        s = s.substring(0, s.length - 1).trimRight();
      }
      if (s.isEmpty) return l10n.planLoadingErrorGeneric;
      return s.endsWith('.') || s.endsWith('!') || s.endsWith('?')
          ? s
          : '$s.';
    }

    if (error == null) return cleanFallback(fallback);
    final s = error.toString().toLowerCase();
    if (s.contains('socketexception') ||
        s.contains('timeoutexception') ||
        s.contains('network') ||
        s.contains('connection') ||
        s.contains('timeout') ||
        s.contains('failed host lookup') ||
        s.contains('no internet')) {
      return l10n.planLoadingErrorNetwork;
    }
    if (s.contains('rate limit') ||
        s.contains('quota') ||
        s.contains('503') ||
        s.contains('502') ||
        s.contains('504')) {
      return l10n.planLoadingErrorService;
    }
    return cleanFallback(fallback);
  }

  /// Show a clean error SnackBar with a localized message + optional Retry.
  ///
  /// The raw [error] is logged via [debugPrint] only — never shown to the user.
  /// If [onRetry] is provided, a single-tap Retry action is added.
  static void showErrorSnack(
    BuildContext context,
    AppLocalizations l10n,
    Object? error, {
    String? fallback,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (error != null) {
      debugPrint('[GroupPlanningUi] error: $error');
    }
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(classifyError(l10n, error, fallback: fallback)),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: l10n.planLoadingTryAgain,
                onPressed: onRetry,
              )
            : null,
      ),
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
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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

/// Pill switcher: Active vs Completed (Mood Match hub, Plans with friends).
class GroupPlanningActiveCompletedToggle extends StatelessWidget {
  const GroupPlanningActiveCompletedToggle({
    super.key,
    required this.activeLabel,
    required this.completedLabel,
    required this.selectedIndex,
    required this.onSelected,
  });

  final String activeLabel;
  final String completedLabel;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GroupPlanningUi.stone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _segment(
                emoji: '⚡️',
                label: activeLabel,
                selected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
            ),
            Expanded(
              child: _segment(
                emoji: '✔️',
                label: completedLabel,
                selected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment({
    required String emoji,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final textStyle = GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.15,
      color: selected ? GroupPlanningUi.charcoal : GroupPlanningUi.stone,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: GroupPlanningUi.moodMatchShadow(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
