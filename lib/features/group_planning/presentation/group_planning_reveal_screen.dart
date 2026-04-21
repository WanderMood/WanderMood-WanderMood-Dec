import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/features/group_planning/domain/group_plan_compatibility.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart'
    show GroupMemberView, GroupPlanRow, GroupSessionRow;
import 'package:wandermood/features/group_planning/presentation/group_planning_mood_labels.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_mood_visuals.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/domain/mood_match_copy.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Change 5 — Match result reveal. Emotional payoff between lobby and shared plan.
class GroupPlanningRevealScreen extends ConsumerStatefulWidget {
  const GroupPlanningRevealScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<GroupPlanningRevealScreen> createState() =>
      _GroupPlanningRevealScreenState();
}

class _GroupPlanningRevealScreenState
    extends ConsumerState<GroupPlanningRevealScreen>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  Map<String, dynamic>? _planData;
  List<GroupMemberView> _members = [];
  bool _loading = true;
  String? _error;

  static const _sunset = Color(0xFFE8784A);

  static const double _totalMs = 3000;

  static double _phase(double tMs, double startMs, double durationMs) {
    if (durationMs <= 0) return 1;
    if (tMs <= startMs) return 0;
    if (tMs >= startMs + durationMs) return 1;
    return (tMs - startMs) / durationMs;
  }

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          HapticFeedback.mediumImpact();
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      final results = await Future.wait([
        repo.fetchPlan(widget.sessionId),
        repo.fetchMembersWithProfiles(widget.sessionId),
        repo.fetchSession(widget.sessionId),
      ]);
      var plan = results[0] as GroupPlanRow?;
      final members = results[1] as List<GroupMemberView>;
      final session = results[2] as GroupSessionRow;
      if (!mounted) return;
      // Owner may have confirmed a day that the DB couldn't persist (missing
      // column on older schema). Fall back to the locally-saved date.
      final withMood =
          members.where((m) => m.member.hasSubmittedMood).toList();
      final allMoodsIn = withMood.length >= 2;

      Map<String, dynamic> planDataForReveal;
      if (plan != null) {
        planDataForReveal = Map<String, dynamic>.from(plan.planData);
      } else if (allMoodsIn) {
        // Reveal before `group_plans` exists: score from mood tags; Moody line
        // falls back to tier copy until the user continues to match-loading.
        final tags = withMood
            .map((m) => m.member.moodTag ?? '')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();
        if (tags.length < 2) {
          setState(() {
            _loading = false;
            _error = l10n.groupPlanResultNoPlan;
          });
          return;
        }
        final score = compatibilityScoreForMoodTags(tags);
        planDataForReveal = {
          'compatibilityScore': score,
          'moods': tags,
        };
      } else {
        setState(() {
          _loading = false;
          _error = l10n.groupPlanResultNoPlan;
        });
        return;
      }

      setState(() {
        _planData = planDataForReveal;
        _members = members;
        _loading = false;
      });
      _master.forward(from: 0);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  String _firstName(GroupMemberView m) {
    final s = m.displayName.trim();
    if (s.isEmpty) return '?';
    final beforeAt = s.split('@').first.trim();
    final parts = beforeAt.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : '?';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return Scaffold(
        backgroundColor: GroupPlanningUi.moodMatchDeep,
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: GroupPlanningUi.moodMatchDeep,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => context.go('/group-planning'),
                ),
                const Spacer(),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style:
                      GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    final score = (_planData?['compatibilityScore'] as num?)?.toInt() ?? 78;
    final commStyle = ref.watch(preferencesProvider).communicationStyle;
    final moodyText = moodMatchMoodyParagraph(
      l10n,
      score,
      _planData?['moodyMessage'] as String?,
      commStyle,
    );
    final withMood = _members.where((m) => m.member.hasSubmittedMood).toList();
    GroupMemberView? a;
    GroupMemberView? b;
    if (withMood.length >= 2) {
      a = withMood[0];
      b = withMood[1];
    }
    final tagA = a?.member.moodTag;
    final tagB = b?.member.moodTag;

    return Scaffold(
      backgroundColor: GroupPlanningUi.moodMatchDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.55),
                  radius: 1.15,
                  colors: [
                    const Color(0xFF1F3D32).withValues(alpha: 0.95),
                    GroupPlanningUi.moodMatchDeep,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 120,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _master,
                builder: (context, _) {
                  final halo =
                      0.12 + 0.08 * math.sin(_master.value * math.pi * 2);
                  return Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                GroupPlanningUi.forest.withValues(alpha: halo),
                            blurRadius: 64,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _master,
              builder: (context, _) {
                final tMs = _master.value * _totalMs;
                // Phase 1: 0–500ms  — mood bubbles slide in
                // Phase 2: 500–1100ms — tag + title + subtitle fade up
                // Phase 3: 1100–1900ms — compat ring
                // Phase 4: 2100–3000ms — CTA slides up
                final p1 = _phase(tMs, 0, 500);
                final p2 = _phase(tMs, 500, 600);
                final p3 = _phase(tMs, 1100, 800);
                final p4 = _phase(tMs, 2100, 900);

                final ease = Curves.easeOutCubic;
                final c1 = ease.transform(p1);
                final c2 = ease.transform(p2);
                final c3 = ease.transform(p3);
                final c4 = ease.transform(p4);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip:
                              MaterialLocalizations.of(context).closeButtonTooltip,
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white54),
                          onPressed: () => context.go('/group-planning'),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          // Allow vertical scrolling on short devices / large
                          // text-scale settings — previously the reveal content
                          // could overflow the hero area with no escape hatch.
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 8),
                              // ── MATCH RESULT tag ──────────────────────────────
                              Opacity(
                                opacity: c2,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - c2) * 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _sunset.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color:
                                              _sunset.withValues(alpha: 0.35)),
                                    ),
                                    child: Text(
                                      l10n.moodMatchResultTag,
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.4,
                                        color: _sunset,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // ── Moody + title (single copy of moodyMessage) ────
                              Opacity(
                                opacity: c2,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - c2) * 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      MoodyCharacter(
                                        size: 44,
                                        mood: 'happy',
                                        glowOpacityScale: 1.15,
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        moodyText,
                                        textAlign: TextAlign.center,
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              // ── Two mood bubbles (avatars + mood emoji badge) ──
                              if (a != null &&
                                  b != null &&
                                  tagA != null &&
                                  tagB != null)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Transform.translate(
                                        offset: Offset((1 - c1) * -80, 0),
                                        child: Opacity(
                                          opacity: c1,
                                          child: _MoodBubble(
                                            emoji: groupPlanMoodEmoji(tagA),
                                            mood: groupPlanLocalizedMoodTag(
                                                l10n, tagA),
                                            name: _firstName(a),
                                            avatarUrl: a.avatarUrl,
                                            color: groupPlanMoodChipTint(tagA),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: Opacity(
                                        opacity: (p1 * 1.4).clamp(0.0, 1.0),
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white
                                                .withValues(alpha: 0.1),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.28),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Text(
                                            '+',
                                            style: GoogleFonts.poppins(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white.withValues(
                                                  alpha: 0.85),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Transform.translate(
                                        offset: Offset((1 - c1) * 80, 0),
                                        child: Opacity(
                                          opacity: c1,
                                          child: _MoodBubble(
                                            emoji: groupPlanMoodEmoji(tagB),
                                            mood: groupPlanLocalizedMoodTag(
                                                l10n, tagB),
                                            name: _firstName(b),
                                            avatarUrl: b.avatarUrl,
                                            color: groupPlanMoodChipTint(tagB),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 28),
                              // ── Compatibility radial gauge ─────────────────────
                              Opacity(
                                opacity: c3,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - c3) * 20),
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 280),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _CompatRing(
                                            progress: c3,
                                            score: score,
                                            label: l10n
                                                .moodMatchResultCompatibility,
                                            bucketLabel:
                                                moodMatchScoreBucketLabel(
                                                    l10n, score),
                                          ),
                                          if (tagA != null && tagB != null) ...[
                                            const SizedBox(height: 18),
                                            Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        '${groupPlanMoodEmoji(tagA)} ${groupPlanLocalizedMoodTag(l10n, tagA)}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                      color: const Color(
                                                          0xFF5DCAA5),
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: ' · ',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                      color: const Color(
                                                          0xFF5DCAA5),
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        '${groupPlanMoodEmoji(tagB)} ${groupPlanLocalizedMoodTag(l10n, tagB)}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                      color: const Color(
                                                          0xFF5DCAA5),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                          const SizedBox(height: 22),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              _MaeColumn(
                                                icon: '🌅',
                                                caption: l10n
                                                    .moodMatchRevealMaeMorning,
                                              ),
                                              _MaeColumn(
                                                icon: '☀️',
                                                caption: l10n
                                                    .moodMatchRevealMaeAfternoon,
                                              ),
                                              _MaeColumn(
                                                icon: '🌆',
                                                caption: l10n
                                                    .moodMatchRevealMaeEvening,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                            ],
                          ),
                        ),
                      ),
                      // ── CTA ───────────────────────────────────────────────────
                      Transform.translate(
                        offset: Offset(0, (1 - c4) * 40),
                        child: Opacity(
                          opacity: c4,
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: Material(
                                  color: GroupPlanningUi.forest,
                                  borderRadius: BorderRadius.circular(999),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () async {
                                      HapticFeedback.mediumImpact();
                                      await MoodMatchSessionPrefs.markRevealCompleted(
                                        widget.sessionId,
                                      );
                                      if (!context.mounted) return;
                                      // After the reveal, the owner picks the
                                      // day (and optionally a slot). Plan
                                      // generation runs from match-loading
                                      // once both sides agree on the day.
                                      context.go(
                                          '/group-planning/day-picker/${widget.sessionId}');
                                    },
                                    child: Center(
                                      child: Text(
                                        l10n.moodMatchRevealCta,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MaeColumn extends StatelessWidget {
  const _MaeColumn({
    required this.icon,
    required this.caption,
  });

  final String icon;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _MoodBubble extends StatelessWidget {
  const _MoodBubble({
    required this.emoji,
    required this.mood,
    required this.name,
    required this.color,
    this.avatarUrl,
  });

  final String emoji;
  final String mood;
  final String name;
  final Color color;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final url = avatarUrl?.trim();
    return Column(
      children: [
        SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Soft colored glow behind the avatar so the mood tint still reads.
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.70),
                        color.withValues(alpha: 0.0),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
              // Avatar disk — thin ring, dark matte under photo (no thick white).
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.38),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: GroupPlanningUi.moodMatchShadow(0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: (url != null && url.isNotEmpty)
                          ? ColoredBox(
                              color: GroupPlanningUi.moodMatchDeepSurface,
                              child: SizedBox.expand(
                                child: WmNetworkImage(
                                  url,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  errorBuilder: (_, __, ___) => ColoredBox(
                                    color: color,
                                    child: Center(
                                      child: Text(
                                        initial,
                                        style: GoogleFonts.poppins(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : ColoredBox(
                              color: color,
                              child: Center(
                                child: Text(
                                  initial,
                                  style: GoogleFonts.poppins(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              // Mood chip: inset slightly so it sits on the photo, not on the ring.
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GroupPlanningUi.moodMatchDeepSurface,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GroupPlanningUi.moodMatchShadow(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          mood,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Premium circular gauge — layered glow, specular edge, subtle 3D-style cap.
class _CompatRing extends StatefulWidget {
  const _CompatRing({
    required this.progress,
    required this.score,
    required this.label,
    required this.bucketLabel,
  });

  final double progress;
  final int score;
  final String label;
  final String bucketLabel;

  @override
  State<_CompatRing> createState() => _CompatRingState();
}

class _CompatRingState extends State<_CompatRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _alive;

  @override
  void initState() {
    super.initState();
    _alive = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _alive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown =
        (widget.score * widget.progress).round().clamp(0, widget.score);

    return AnimatedBuilder(
      animation: _alive,
      builder: (context, _) {
        final t = _alive.value;
        final breathe = 1.0 + 0.028 * math.sin(t * math.pi * 2);
        return Center(
          child: Transform.scale(
            scale: breathe,
            child: SizedBox(
              width: 196,
              height: 196,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CustomPaint(
                      painter: _CompatRingPainter(
                        progress: widget.progress,
                        score: widget.score,
                        lively: t,
                      ),
                    ),
                  ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [Color(0xFF8CE3C1), Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(rect),
                    child: Text(
                      '$shown%',
                      style: GoogleFonts.poppins(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.0,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color: GroupPlanningUi.moodMatchShadow(0.45),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          Shadow(
                            color: const Color(0xFF5DCAA5).withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: Offset.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.bucketLabel,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CompatRingPainter extends CustomPainter {
  _CompatRingPainter({
    required this.progress,
    required this.score,
    required this.lively,
  });

  final double progress;
  final int score;
  /// 0–1 looping — drives ambient glow and cap shimmer.
  final double lively;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) / 2) - 10;
    const stroke = 11.0;
    final pulse = 0.55 + 0.45 * math.sin(lively * math.pi * 2);

    // Soft mint bloom behind the ring (depth / “lift”).
    final bloom = Paint()
      ..color = const Color(0xFF5DCAA5).withValues(alpha: 0.08 + 0.06 * pulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 + 6 * pulse);
    canvas.drawCircle(center, radius + stroke, bloom);

    // Track — outer rim + subtle inner shadow ring for inset feel.
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    final innerRim = Paint()
      ..color = GroupPlanningUi.moodMatchShadow(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius - stroke * 0.35, innerRim);

    final sweep =
        (score / 100).clamp(0.0, 1.0) * math.pi * 2 * progress;
    if (sweep <= 0.001) return;

    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final start = -math.pi / 2;

    // Drop-shadow pass (offset arc for “raised” stroke).
    canvas.save();
    canvas.translate(0, 2.2);
    final shadowPaint = Paint()
      ..color = GroupPlanningUi.moodMatchShadow(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawArc(arcRect, start, sweep, false, shadowPaint);
    canvas.restore();

    // Outer glow along progress.
    final glowPaint = Paint()
      ..color = const Color(0xFF8CE3C1).withValues(alpha: 0.22 + 0.12 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 7
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(arcRect, start, sweep, false, glowPaint);

    const gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: [
        Color(0xFF3FA885),
        Color(0xFF5DCAA5),
        Color(0xFF8CE3C1),
        Color(0xFFE8FFF6),
      ],
      stops: [0.0, 0.35, 0.7, 1.0],
    );
    final progressPaint = Paint()
      ..shader = gradient.createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, start, sweep, false, progressPaint);

    // Specular highlight strip on inner side of arc (3D bevel).
    final hiRect = Rect.fromCircle(center: center, radius: radius - stroke * 0.42);
    final hiPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35 + 0.2 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(hiRect, start, sweep * 0.92, false, hiPaint);

    // End cap — “bead” with radial fill + halo.
    final endAngle = start + sweep;
    final dot = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );
    final outerHalo = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.45),
          const Color(0xFF8CE3C1).withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: dot, radius: stroke * 2.2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(dot, stroke * 1.8, outerHalo);

    final bead = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFFB8F5DD),
          const Color(0xFF5DCAA5),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: dot, radius: stroke * 0.95));
    canvas.drawCircle(dot, stroke * 0.72, bead);
    final glint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(
      Offset(dot.dx - 1.8, dot.dy - 1.8),
      stroke * 0.18,
      glint,
    );
  }

  @override
  bool shouldRepaint(covariant _CompatRingPainter old) {
    return old.progress != progress ||
        old.score != score ||
        old.lively != lively;
  }
}
