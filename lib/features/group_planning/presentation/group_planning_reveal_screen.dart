import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/features/group_planning/domain/group_planning_deep_link.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart'
    show GroupMemberView, GroupPlanRow, GroupSessionRow;
import 'package:wandermood/features/group_planning/presentation/group_planning_mood_labels.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_mood_visuals.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/domain/mood_match_copy.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/group_planning/presentation/share_sheet_origin.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Emotional payoff between lobby and shared plan.
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
  String? _joinCode;
  bool _loading = true;
  String? _error;
  final GlobalKey _shareKey = GlobalKey();

  static const _bg = Color(0xFF0F0E0C);
  static const _mint = Color(0xFF5DCAA5);

  /// Total timeline: phase4 ends at 2000 + 350 ms.
  static const double _totalMs = 2350;

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
      duration: const Duration(milliseconds: 2350),
    );
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
      final plan = results[0] as GroupPlanRow?;
      final members = results[1] as List<GroupMemberView>;
      final session = results[2] as GroupSessionRow;
      if (!mounted) return;
      if (plan == null) {
        setState(() {
          _loading = false;
          _error = l10n.groupPlanResultNoPlan;
        });
        return;
      }
      setState(() {
        _planData = plan.planData;
        _members = members;
        _joinCode = session.joinCode;
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
        backgroundColor: _bg,
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _mint.withValues(alpha: 0.9),
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: _bg,
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
    final scoreLabel = moodMatchScoreBucketLabel(l10n, score);

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
      backgroundColor: _bg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _master,
          builder: (context, _) {
            final tMs = _master.value * _totalMs;
            // Phase 1: 0–500 ms · Phase 2: 600–1500 · Phase 3: 1500–1900 · Phase 4: 2000–2350
            final p1 = _phase(tMs, 0, 500);
            final p2 = _phase(tMs, 600, 900);
            final p3 = _phase(tMs, 1500, 400);
            final p4 = _phase(tMs, 2000, 350);

            final curve1 = Curves.easeOutCubic.transform(p1);
            final ease = Curves.easeOutCubic;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white54),
                      onPressed: () => context.go('/group-planning'),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (a != null &&
                            b != null &&
                            tagA != null &&
                            tagB != null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Transform.translate(
                                  offset: Offset(
                                    ease.transform(1 - curve1) * -80,
                                    0,
                                  ),
                                  child: Opacity(
                                    opacity: curve1,
                                    child: _MoodBubble(
                                      emoji: groupPlanMoodEmoji(tagA),
                                      mood:
                                          groupPlanLocalizedMoodTag(l10n, tagA),
                                      name: _firstName(a),
                                      color: groupPlanMoodChipTint(tagA),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Opacity(
                                  opacity: (p1 * 1.2).clamp(0.0, 1.0),
                                  child: Text(
                                    '+',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Transform.translate(
                                  offset: Offset(
                                    ease.transform(1 - curve1) * 80,
                                    0,
                                  ),
                                  child: Opacity(
                                    opacity: curve1,
                                    child: _MoodBubble(
                                      emoji: groupPlanMoodEmoji(tagB),
                                      mood:
                                          groupPlanLocalizedMoodTag(l10n, tagB),
                                      name: _firstName(b),
                                      color: groupPlanMoodChipTint(tagB),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                        ],
                        _ScoreRing(
                          progress: ease.transform(p2),
                          score: score,
                          countT: ease.transform(p2),
                          mint: _mint,
                          label: scoreLabel,
                          labelOpacity: ease.transform(p2),
                        ),
                        SizedBox(
                          height: 20 + 24 * ease.transform(p3),
                        ),
                        Opacity(
                          opacity: ease.transform(p3),
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              (1 - ease.transform(p3)) * 28,
                            ),
                            child: Transform.scale(
                              scale: 0.85 + 0.15 * ease.transform(p3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const MoodyCharacter(size: 40, mood: 'happy'),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        moodyText,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                          height: 1.4,
                                          color: Colors.white
                                              .withValues(alpha: 0.75),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, (1 - ease.transform(p4)) * 40),
                    child: Opacity(
                      opacity: ease.transform(p4),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: Material(
                              color: GroupPlanningUi.forest,
                              borderRadius: BorderRadius.circular(14),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  context.go(
                                      '/group-planning/result/${widget.sessionId}');
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
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              KeyedSubtree(
                                key: _shareKey,
                                child: IconButton.filled(
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.08),
                                  ),
                                  icon: const Icon(Icons.ios_share_rounded,
                                      color: Colors.white70),
                                  tooltip: l10n.moodMatchSeePlanShareA11y,
                                  onPressed: () async {
                                    final code = _joinCode;
                                    final text = code != null && code.isNotEmpty
                                        ? '${l10n.moodMatchInviteShare(code)}\n${groupPlanningJoinShareLink(code).toString()}'
                                        : l10n.moodMatchTagline;
                                    final origin =
                                        sharePositionOriginForContext(
                                      _shareKey.currentContext ?? context,
                                    );
                                    await SharePlus.instance.share(
                                      ShareParams(
                                        text: text,
                                        sharePositionOrigin: origin,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
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
    );
  }
}

class _MoodBubble extends StatelessWidget {
  const _MoodBubble({
    required this.emoji,
    required this.mood,
    required this.name,
    required this.color,
  });

  final String emoji;
  final String mood;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 32)),
        ),
        const SizedBox(height: 8),
        Text(
          mood,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        Text(
          name,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.progress,
    required this.score,
    required this.countT,
    required this.mint,
    required this.label,
    required this.labelOpacity,
  });

  final double progress;
  final int score;
  final double countT;
  final Color mint;
  final String label;
  final double labelOpacity;

  @override
  Widget build(BuildContext context) {
    final shown = (score * countT).round().clamp(0, score);
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(160, 160),
            painter: _RingPainter(
              progress: progress,
              color: mint,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$shown',
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Opacity(
                opacity: labelOpacity,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white60,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 8.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, bg);
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final sweep = 1.75 * 3.141592653589793 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592653589793 / 2,
      sweep,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
