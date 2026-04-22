import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/home/presentation/providers/main_navigation_provider.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/features/auth/application/auth_provider.dart';
import 'package:wandermood/features/home/presentation/providers/moody_hub_state_provider.dart';
import 'package:wandermood/features/home/presentation/utils/moody_hub_hero_copy.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_action.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_action_set_builder.dart'
    show buildMoodyActions, routeMoodMatch;
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/l10n/app_localizations.dart';

void _deferMoodyHubActionTap(VoidCallback onTap) {
  unawaited(Future<void>(() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    onTap();
  }));
}

/// Assistant-style chat bubble corners (slight “tail” top-left) + layered float shadow.
const BorderRadius _hubBubbleRadius = BorderRadius.only(
  topLeft: Radius.circular(8),
  topRight: Radius.circular(22),
  bottomLeft: Radius.circular(22),
  bottomRight: Radius.circular(22),
);

/// First hub bubble = strongest float + widest; follow-ups read as replies.
enum HubBubbleEmphasis { primary, secondary }

double _hubBubbleWidthFactor(HubBubbleEmphasis e) =>
    e == HubBubbleEmphasis.primary ? 0.92 : 0.86;

List<BoxShadow> _hubBubbleShadowsFor(HubBubbleEmphasis emphasis) {
  final lift = emphasis == HubBubbleEmphasis.primary ? 1.0 : 0.66;
  final a1 = emphasis == HubBubbleEmphasis.primary ? 0.07 : 0.048;
  final a2 = emphasis == HubBubbleEmphasis.primary ? 0.04 : 0.028;
  return [
    BoxShadow(
      color: const Color(0xFF1E1C18).withValues(alpha: a1),
      blurRadius: 22,
      spreadRadius: -3,
      offset: Offset(0, 9 * lift),
    ),
    BoxShadow(
      color: const Color(0xFF1E1C18).withValues(alpha: a2),
      blurRadius: 8,
      offset: Offset(0, 2 * lift),
    ),
  ];
}

double _hubBorderOpacity(HubBubbleEmphasis e) =>
    e == HubBubbleEmphasis.primary ? 0.05 : 0.036;

EdgeInsets _hubCardPadding(HubBubbleEmphasis e) =>
    e == HubBubbleEmphasis.primary
        ? const EdgeInsets.fromLTRB(12, 12, 12, 10)
        : const EdgeInsets.fromLTRB(11, 10, 11, 9);

List<BoxShadow> _neutralPairShadows() => [
      BoxShadow(
        color: const Color(0xFF1E1C18).withValues(alpha: 0.034),
        blurRadius: 7,
        offset: const Offset(0, 2),
      ),
    ];

/// Small bottom-left nib (incoming-message style). Pure [CustomPainter] — no packages.
class _HubChatBubbleTailPainter extends CustomPainter {
  _HubChatBubbleTailPainter({required this.fillColor});

  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0.5)
      ..lineTo(5, 0.5)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..isAntiAlias = true
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _HubChatBubbleTailPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor;
}

/// Shadow + rounded shell; optional tail only on the **primary** column bubbles.
class _HubFeatureBubbleShell extends StatelessWidget {
  const _HubFeatureBubbleShell({
    required this.emphasis,
    required this.backgroundColor,
    required this.showTail,
    required this.child,
  });

  final HubBubbleEmphasis emphasis;
  final Color backgroundColor;
  final bool showTail;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bubble = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _hubBubbleRadius,
        boxShadow: _hubBubbleShadowsFor(emphasis),
        border: Border.all(
          color: const Color(0xFF1E1C18).withValues(alpha: _hubBorderOpacity(emphasis)),
        ),
      ),
      child: Material(
        color: backgroundColor,
        borderRadius: _hubBubbleRadius,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );

    if (!showTail) return bubble;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        bubble,
        Positioned(
          left: 17,
          bottom: -4.5,
          child: CustomPaint(
            size: const Size(12, 8),
            painter: _HubChatBubbleTailPainter(fillColor: backgroundColor),
          ),
        ),
      ],
    );
  }
}

/// Left-aligned, width-capped “message” strip (chat thread).
class _HubBubbleFrame extends StatelessWidget {
  const _HubBubbleFrame({
    required this.emphasis,
    required this.child,
  });

  final HubBubbleEmphasis emphasis;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: _hubBubbleWidthFactor(emphasis),
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }
}

/// Single top hub surface for the Moody tab: blends with the chat background
/// (no floating white card). [expanded] controls full hero vs collapsed handle.
class MoodyActionSheet extends ConsumerWidget {
  const MoodyActionSheet({
    super.key,
    required this.expanded,
    this.onToggle,
    this.onChat,
  });

  final bool expanded;

  /// Collapse/expand handle (only when user has a thread).
  final VoidCallback? onToggle;

  /// Callback to send a message to the AI when a chip is tapped.
  final void Function(String)? onChat;

  /// Collapsed “chat state” strip: compact ^ Moody Hub + subtitle (matches content height).
  static const double collapsedHeightTappable = 54;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const SizedBox.shrink();
    }
    final state = ref.watch(moodyHubStateProvider).maybeWhen(
          data: (s) => s,
          orElse: () => const MoodyHubState.empty(),
        );
    final actions = buildMoodyActions(
      context: context,
      ref: ref,
      state: state,
      l10n: l10n,
      onChat: onChat,
    );

    if (!expanded) {
      return Material(
        color: Colors.transparent,
        child: _CollapsedHandle(
          onTap: onToggle,
          title: l10n.moodyHubCollapsedActionsTitle,
          subtitle: l10n.moodyHubCollapsedActionsSubtitle,
        ),
      );
    }

    return _MoodyHubExpandedBody(
      state: state,
      actions: actions,
      l10n: l10n,
    );
  }
}

class _CollapsedHandle extends StatelessWidget {
  const _CollapsedHandle({
    this.onTap,
    required this.title,
    required this.subtitle,
  });

  final VoidCallback? onTap;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final accent = enabled
        ? const Color(0xFF2A6049)
        : const Color(0xFF8C8780);

    final pill = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: enabled ? 0.92 : 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2A6049).withValues(alpha: enabled ? 0.32 : 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 18,
                  color: accent,
                ),
                const SizedBox(width: 2),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                height: 1.2,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5C574E),
              ),
            ),
          ],
        ),
      ),
    );

    final semanticsLabel = '$title. $subtitle';

    if (!enabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Semantics(label: semanticsLabel, child: pill),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Align(
            alignment: Alignment.center,
            child: Semantics(
              button: true,
              label: semanticsLabel,
              child: pill,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _moodyHubPrimaryPlanBubble({
  required MoodyAction primary,
  required AppLocalizations l10n,
  required HubBubbleEmphasis emphasis,
}) {
  if (primary.id == MoodyActionId.planWholeDay) {
    return _HubBubbleFrame(
      emphasis: emphasis,
      child: _MoodyHubPrimaryPlanCard(
        emphasis: emphasis,
        emoji: primary.emoji,
        title: l10n.moodyHubPlanYourDayCardTitle,
        body: l10n.moodyHubPlanYourDayCardBody,
        ctaLabel: primary.label,
        onCta: primary.onTap,
      ),
    );
  }
  if (primary.id == MoodyActionId.changeMood &&
      primary.tone == MoodyActionTone.primary) {
    return _HubBubbleFrame(
      emphasis: emphasis,
      child: _MoodyHubPrimaryPlanCard(
        emphasis: emphasis,
        emoji: primary.emoji,
        title: l10n.moodyHubChangeMoodCardTitle,
        body: l10n.moodyHubChangeMoodCardBody,
        ctaLabel: primary.label,
        onCta: primary.onTap,
      ),
    );
  }
  return _HubBubbleFrame(
    emphasis: emphasis,
    child: _PrimaryHubButton(
      action: primary,
      emphasis: emphasis,
    ),
  );
}

class _MoodyHubExpandedBody extends ConsumerStatefulWidget {
  const _MoodyHubExpandedBody({
    required this.state,
    required this.actions,
    required this.l10n,
  });

  final MoodyHubState state;
  final List<MoodyAction> actions;
  final AppLocalizations l10n;

  @override
  ConsumerState<_MoodyHubExpandedBody> createState() =>
      _MoodyHubExpandedBodyState();
}

class _MoodyHubExpandedBodyState extends ConsumerState<_MoodyHubExpandedBody> {
  static const int _moodyTabIndex = 2;

  /// Bumps when returning to the Moody tab so hub content replays entrance motion.
  int _entranceVersion = 0;
  ProviderSubscription<int>? _tabSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabSub ??= ref.listenManual<int>(mainTabProvider, (previous, next) {
      if (next == _moodyTabIndex &&
          previous != null &&
          previous != _moodyTabIndex) {
        setState(() => _entranceVersion++);
      }
    });
  }

  @override
  void dispose() {
    _tabSub?.close();
    super.dispose();
  }

  /// Staggered fade + slide for hub blocks (after hero mascot).
  Widget _hubStagger(int step, Widget child) {
    final delayMs = 70 * step;
    return child
        .animate(delay: delayMs.ms)
        .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.07,
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        );
  }

  @override
  Widget build(BuildContext context) {
    final actions = widget.actions;
    final l10n = widget.l10n;
    final state = widget.state;

    MoodyAction? primary;
    for (final a in actions) {
      if (a.tone == MoodyActionTone.primary) {
        primary = a;
        break;
      }
    }
    MoodyAction? matchAction;
    final rest = <MoodyAction>[];
    for (final a in actions) {
      if (a.id == MoodyActionId.moodMatch) {
        matchAction = a;
      } else {
        rest.add(a);
      }
    }
    // `rest` still includes primary — strip primary for secondary rows
    final secondary = rest.where((a) => a.tone != MoodyActionTone.primary).toList();

    final commStyle = ref.watch(preferencesProvider).communicationStyle;
    final firstName = _firstNameFromDisplay(
      ref.watch(userDisplayNameProvider),
    );
    final heroBody = moodyHubHeroBodyLine(l10n, state, commStyle);
    // Breathing room above the chat composer seam so the last card isn’t clipped.
    // (Hub sits above the composer; extra scroll extent beats a hard edge.)
    const bottomInset = 72.0;

    var hubLeadBubbleCount = 0;
    HubBubbleEmphasis nextLeadEmphasis() {
      hubLeadBubbleCount++;
      return hubLeadBubbleCount == 1
          ? HubBubbleEmphasis.primary
          : HubBubbleEmphasis.secondary;
    }

    var staggerStep = 1;

    // Use ListView (not SingleChildScrollView) so the viewport gets a bounded
    // height from the parent AnimatedContainer — avoids _RenderSingleChildViewport
    // "not laid out" + semantics.parentDataDirty cascades during tab/keyboard churn.
    return ListView(
      key: ValueKey<int>(_entranceVersion),
      clipBehavior: Clip.none,
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 6),
      physics: const BouncingScrollPhysics(),
      children: [
        Center(
          child: const _MoodyHubHeroMascot(),
        )
            .animate()
            .scale(
              duration: 560.ms,
              begin: const Offset(0.38, 0.38),
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 360.ms, curve: Curves.easeOutCubic),
        const SizedBox(height: 12),
        _hubStagger(
          staggerStep++,
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.92,
              alignment: Alignment.centerLeft,
              child: _MoodyHubHeroMessageCard(
                title: _greeting(l10n, firstName: firstName),
                body: heroBody,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Killer feature: Mood Match card leads (above day CTA).
        if (state.match.state == MoodyMatchState.sharedReady) ...[
          _hubStagger(
            staggerStep++,
            Builder(
              builder: (context) {
                final e = nextLeadEmphasis();
                return _HubBubbleFrame(
                  emphasis: e,
                  child: _SharedPlanCard(
                    state: state,
                    l10n: l10n,
                    emphasis: e,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (state.match.state == MoodyMatchState.invite) ...[
          _hubStagger(
            staggerStep++,
            Builder(
              builder: (context) {
                final e = nextLeadEmphasis();
                return _HubBubbleFrame(
                  emphasis: e,
                  child: _MoodMatchPromoCard(
                    l10n: l10n,
                    emphasis: e,
                    ctaLabel: l10n.moodyHubMoodMatchInviteCta,
                    onCta: () => routeMoodMatch(context, state.match),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (state.day == MoodyDayState.active &&
            primary != null &&
            matchAction != null &&
            state.match.state != MoodyMatchState.sharedReady &&
            state.match.state != MoodyMatchState.invite) ...[
          _hubStagger(
            staggerStep++,
            Builder(
              builder: (context) {
                final e = nextLeadEmphasis();
                final m = matchAction!;
                return _HubBubbleFrame(
                  emphasis: e,
                  child: _MoodMatchPromoCard(
                    l10n: l10n,
                    emphasis: e,
                    ctaLabel: m.label,
                    onCta: () => _deferMoodyHubActionTap(m.onTap),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _hubStagger(
            staggerStep++,
            Builder(
              builder: (context) {
                final e = nextLeadEmphasis();
                return _moodyHubPrimaryPlanBubble(
                  primary: primary!,
                  l10n: l10n,
                  emphasis: e,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ] else ...[
          // Empty day: full Mood Match card (body + CTA) leads, then Plan / Change mood —
          // same stack as the shipped hub reference, not the thin accent row.
          if (state.match.state != MoodyMatchState.sharedReady &&
              state.match.state != MoodyMatchState.invite &&
              matchAction != null) ...[
            _hubStagger(
              staggerStep++,
              Builder(
                builder: (context) {
                  final e = nextLeadEmphasis();
                  final m = matchAction!;
                  return _HubBubbleFrame(
                    emphasis: e,
                    child: _MoodMatchPromoCard(
                      l10n: l10n,
                      emphasis: e,
                      ctaLabel: m.label,
                      onCta: () => _deferMoodyHubActionTap(m.onTap),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (primary != null) ...[
            _hubStagger(
              staggerStep++,
              Builder(
                builder: (context) {
                  final e = nextLeadEmphasis();
                  return _moodyHubPrimaryPlanBubble(
                    primary: primary!,
                    l10n: l10n,
                    emphasis: e,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
        ..._secondaryPairs(secondary).map(
          (row) => _hubStagger(staggerStep++, row),
        ),
      ],
    );
  }
}

String _greeting(AppLocalizations l10n, {String? firstName}) {
  final hour = DateTime.now().hour;
  final base = hour < 12
      ? l10n.goodMorning
      : hour < 17
          ? l10n.goodAfternoon
          : l10n.goodEvening;
  if (firstName == null || firstName.isEmpty) return base;
  return '$base, $firstName';
}

/// Extracts the first word from a display name (or the @handle as-is).
/// Returns null for generic fallbacks like "User" / "Loading…" so the greeting
/// stays plain ("Good morning") rather than "Good morning, User".
String? _firstNameFromDisplay(String? displayName) {
  final t = displayName?.trim();
  if (t == null || t.isEmpty) return null;
  if (t == 'User' || t == 'Loading...' || t == 'New User') return null;
  if (t.startsWith('@')) return t;
  return t.split(RegExp(r'\s+')).first;
}

/// Moody only — no extra blue disc behind the character (glow comes from the asset).
class _MoodyHubHeroMascot extends StatelessWidget {
  const _MoodyHubHeroMascot();

  static const double _charSize = 68;

  @override
  Widget build(BuildContext context) {
    return MoodyCharacter(
      size: _charSize,
      mood: 'happy',
    );
  }
}

/// Greeting + hero copy directly on the hub background (no card chrome).
class _MoodyHubHeroMessageCard extends StatelessWidget {
  const _MoodyHubHeroMessageCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.start,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.22,
            color: const Color(0xFF1E1C18),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.start,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.42,
            color: const Color(0xFF4A4640),
          ),
        ),
      ],
    );
  }
}

/// Same visual pattern as [ _MoodMatchInviteCard ] — headline, body, pill CTA — for
/// “Plan your day” / “Continue day” so the primary feature matches Mood Match.
class _MoodyHubPrimaryPlanCard extends StatelessWidget {
  const _MoodyHubPrimaryPlanCard({
    required this.emphasis,
    required this.emoji,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
  });

  final HubBubbleEmphasis emphasis;
  final String emoji;
  final String title;
  final String body;
  final String ctaLabel;
  final VoidCallback onCta;

  static const Color _bg = Color(0xFFEEF6F1);
  static const Color _titleColor = Color(0xFF245A46);
  static const Color _buttonColor = Color(0xFF2A6049);

  @override
  Widget build(BuildContext context) {
    final titleFs = emphasis == HubBubbleEmphasis.primary ? 17.0 : 16.0;
    final showTail = emphasis == HubBubbleEmphasis.primary;
    return _HubFeatureBubbleShell(
      emphasis: emphasis,
      backgroundColor: _bg,
      showTail: showTail,
      child: InkWell(
        onTap: onCta,
        borderRadius: _hubBubbleRadius,
        child: Padding(
          padding: _hubCardPadding(emphasis),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 23)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: titleFs,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: -0.22,
                        color: _titleColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: emphasis == HubBubbleEmphasis.primary ? 5 : 4),
              Text(
                body,
                style: GoogleFonts.poppins(
                  fontSize: emphasis == HubBubbleEmphasis.primary ? 13.0 : 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E1C18).withValues(alpha: 0.86),
                  height: 1.36,
                ),
              ),
              SizedBox(height: emphasis == HubBubbleEmphasis.primary ? 10 : 9),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _buttonColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: emphasis == HubBubbleEmphasis.primary ? 11 : 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: onCta,
                  child: Text(
                    ctaLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

class _PrimaryHubButton extends StatelessWidget {
  const _PrimaryHubButton({
    required this.action,
    required this.emphasis,
  });

  final MoodyAction action;
  final HubBubbleEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    const r = BorderRadius.all(Radius.circular(999));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: _hubBubbleShadowsFor(emphasis),
      ),
      child: Material(
        color: const Color(0xFF2A6049),
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _deferMoodyHubActionTap(action.onTap),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: emphasis == HubBubbleEmphasis.primary ? 16 : 14,
              vertical: emphasis == HubBubbleEmphasis.primary ? 13 : 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(action.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    action.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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
}

class _SharedPlanCard extends ConsumerWidget {
  const _SharedPlanCard({
    required this.state,
    required this.l10n,
    required this.emphasis,
  });

  final MoodyHubState state;
  final AppLocalizations l10n;
  final HubBubbleEmphasis emphasis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = state.match.partnerFirstName ?? '…';
    final subtitle = l10n.moodMatchHubSubReadyWith(name);
    const bg = Color(0xFFF7F4EE);
    final titleFs = emphasis == HubBubbleEmphasis.primary ? 17.0 : 16.0;
    final bodyFs = emphasis == HubBubbleEmphasis.primary ? 13.0 : 12.5;
    final showTail = emphasis == HubBubbleEmphasis.primary;

    return _HubFeatureBubbleShell(
      emphasis: emphasis,
      backgroundColor: bg,
      showTail: showTail,
      child: InkWell(
        onTap: () => routeMoodMatch(context, state.match),
        borderRadius: _hubBubbleRadius,
        child: Padding(
          padding: _hubCardPadding(emphasis),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🫶',
                    style: TextStyle(
                      fontSize: emphasis == HubBubbleEmphasis.primary ? 23.0 : 22.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.moodMatchTitle,
                      style: GoogleFonts.poppins(
                        fontSize: titleFs,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: -0.22,
                        color: const Color(0xFFC45C2A),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: emphasis == HubBubbleEmphasis.primary ? 5 : 4),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: bodyFs,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E1C18).withValues(alpha: 0.86),
                  height: 1.36,
                ),
              ),
              SizedBox(height: emphasis == HubBubbleEmphasis.primary ? 10 : 9),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE8784A),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: emphasis == HubBubbleEmphasis.primary ? 11 : 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () => routeMoodMatch(context, state.match),
                  child: Text(
                    l10n.moodMatchHubCtaOpenShared,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

/// Full-width Mood Match bubble: [moodyHubInviteCardBody] + orange CTA (Start / View matches / …).
class _MoodMatchPromoCard extends StatelessWidget {
  const _MoodMatchPromoCard({
    required this.l10n,
    required this.emphasis,
    required this.ctaLabel,
    required this.onCta,
  });

  final AppLocalizations l10n;
  final HubBubbleEmphasis emphasis;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF7F4EE);
    final titleFs = emphasis == HubBubbleEmphasis.primary ? 17.0 : 16.0;
    final bodyFs = emphasis == HubBubbleEmphasis.primary ? 13.0 : 12.5;
    final showTail = emphasis == HubBubbleEmphasis.primary;
    return _HubFeatureBubbleShell(
      emphasis: emphasis,
      backgroundColor: bg,
      showTail: showTail,
      child: InkWell(
        onTap: onCta,
        borderRadius: _hubBubbleRadius,
        child: Padding(
          padding: _hubCardPadding(emphasis),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🫶',
                    style: TextStyle(
                      fontSize: emphasis == HubBubbleEmphasis.primary ? 23.0 : 22.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.moodMatchTitle,
                      style: GoogleFonts.poppins(
                        fontSize: titleFs,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: -0.22,
                        color: const Color(0xFFC45C2A),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: emphasis == HubBubbleEmphasis.primary ? 5 : 4),
              Text(
                l10n.moodyHubInviteCardBody,
                style: GoogleFonts.poppins(
                  fontSize: bodyFs,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E1C18).withValues(alpha: 0.86),
                  height: 1.36,
                ),
              ),
              SizedBox(height: emphasis == HubBubbleEmphasis.primary ? 10 : 9),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE8784A),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: emphasis == HubBubbleEmphasis.primary ? 11 : 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: onCta,
                  child: Text(
                    ctaLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

List<Widget> _secondaryPairs(List<MoodyAction> secondary) {
  if (secondary.isEmpty) return const [];
  final out = <Widget>[];
  for (var i = 0; i < secondary.length; i += 2) {
    final a = secondary[i];
    final b = i + 1 < secondary.length ? secondary[i + 1] : null;
    final isLastPair = i + 2 >= secondary.length;
    out.add(
      Padding(
        padding: EdgeInsets.only(bottom: isLastPair ? 0 : 10),
        child: Row(
          children: [
            Expanded(child: _NeutralHalfButton(action: a)),
            if (b != null) ...[
              const SizedBox(width: 10),
              Expanded(child: _NeutralHalfButton(action: b)),
            ],
          ],
        ),
      ),
    );
  }
  return out;
}

class _NeutralHalfButton extends StatelessWidget {
  const _NeutralHalfButton({required this.action});

  final MoodyAction action;

  @override
  Widget build(BuildContext context) {
    const r = BorderRadius.all(Radius.circular(999));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: _neutralPairShadows(),
      ),
      child: Material(
        color: const Color(0xFFF8F6F1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: Color(0xFFE0D8CE)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _deferMoodyHubActionTap(action.onTap),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Text(action.emoji, style: const TextStyle(fontSize: 17)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    action.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1C18),
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
