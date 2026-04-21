import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/home/presentation/providers/moody_hub_state_provider.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_action.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_action_set_builder.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Horizontal state-driven action row that sits just above the composer.
///
/// Contract:
///   * Always visible while the Moody hub is on screen — never collapsed,
///     never hidden by chat scroll.
///   * Content is derived from [moodyHubStateProvider] only. It MUST NOT read
///     chat messages or AI responses. A state change cross-fades via
///     [AnimatedSwitcher] so the swap reads as "your state changed", not as
///     "the chat shuffled things around".
///   * Taps trigger navigation via the action's `onTap`. They never seed the
///     composer or inject chat messages.
class MoodyActionPillRow extends ConsumerWidget {
  const MoodyActionPillRow({
    super.key,
    this.onActionTap,
    this.horizontalPadding = 16,
  });

  final ValueChanged<MoodyAction>? onActionTap;
  final double horizontalPadding;

  // WanderMood v2 tokens — kept local so this widget has no cross-file
  // dependency on redesigned_moody_hub's privates.
  static const Color _wmForest = Color(0xFF2A6049);
  static const Color _wmSunset = Color(0xFFE8784A);
  static const Color _wmSunsetTint = Color(0xFFFCEEE4);
  static const Color _wmCharcoal = Color(0xFF1E1C18);
  static const Color _wmParchment = Color(0xFFE8E2D8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(moodyHubStateProvider);
    final state = async.maybeWhen(
      data: (s) => s,
      orElse: () => const MoodyHubState.empty(),
    );
    final actions = buildMoodyActions(
      context: context,
      ref: ref,
      state: state,
      l10n: l10n,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: SizedBox(
        key: ValueKey('${state.day}_${state.match.state}'),
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          physics: const BouncingScrollPhysics(),
          itemCount: actions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) => _MoodyPill(
            action: actions[index],
            onTap: onActionTap == null
                ? actions[index].onTap
                : () => onActionTap!(actions[index]),
          ),
        ),
      ),
    );
  }
}

class _MoodyPill extends StatelessWidget {
  const _MoodyPill({
    required this.action,
    required this.onTap,
  });

  final MoodyAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = _tonePalette(action.tone);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: border == null ? null : Border.all(color: border, width: 1),
            boxShadow: action.tone == MoodyActionTone.primary
                ? [
                    BoxShadow(
                      color: bg.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(action.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                action.label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color bg, Color fg, Color? border) _tonePalette(MoodyActionTone tone) {
    switch (tone) {
      case MoodyActionTone.primary:
        return (
          MoodyActionPillRow._wmForest,
          Colors.white,
          null,
        );
      case MoodyActionTone.accent:
        return (
          MoodyActionPillRow._wmSunsetTint,
          MoodyActionPillRow._wmSunset,
          MoodyActionPillRow._wmSunset.withValues(alpha: 0.3),
        );
      case MoodyActionTone.neutral:
        return (
          Colors.white.withValues(alpha: 0.9),
          MoodyActionPillRow._wmCharcoal,
          MoodyActionPillRow._wmParchment,
        );
    }
  }
}
