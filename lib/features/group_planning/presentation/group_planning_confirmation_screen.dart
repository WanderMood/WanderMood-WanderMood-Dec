import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Change 7 — Confirmation screen after time slot is saved.
class GroupPlanningConfirmationScreen extends ConsumerStatefulWidget {
  const GroupPlanningConfirmationScreen({
    super.key,
    required this.sessionId,
    required this.scheduledDate,
    required this.timeSlot,
  });

  final String sessionId;
  final String scheduledDate; // YYYY-MM-DD
  final String timeSlot; // morning | afternoon | evening

  @override
  ConsumerState<GroupPlanningConfirmationScreen> createState() =>
      _GroupPlanningConfirmationScreenState();
}

class _GroupPlanningConfirmationScreenState
    extends ConsumerState<GroupPlanningConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;
  List<GroupMemberView> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      final members = await repo.fetchMembersWithProfiles(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
      });
      _pop.forward(from: 0);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _firstName(String displayName) {
    final s = displayName.trim();
    if (s.isEmpty) return '?';
    final beforeAt = s.split('@').first.trim();
    final parts = beforeAt.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : '?';
  }

  GroupMemberView? _otherMember() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    for (final m in _members) {
      if (m.member.userId != uid) return m;
    }
    return null;
  }

  String _dayLabel() {
    final dt = DateTime.tryParse(widget.scheduledDate);
    if (dt == null) return widget.scheduledDate;
    return DateFormat('EEEE d MMMM').format(dt);
  }

  String _slotLabel(AppLocalizations l10n) {
    switch (widget.timeSlot) {
      case 'morning':
        return l10n.moodMatchTimePickerMorning;
      case 'afternoon':
        return l10n.moodMatchTimePickerAfternoon;
      case 'evening':
        return l10n.moodMatchTimePickerEvening;
      default:
        return widget.timeSlot;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final other = _otherMember();
    final otherName =
        other != null ? _firstName(other.displayName) : l10n.moodMatchFriendThey;

    return Scaffold(
      backgroundColor: GroupPlanningUi.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(
                          '/group-planning/result/${widget.sessionId}');
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                  label: Text(l10n.moodMatchConfirmBackToPlan),
                  style: TextButton.styleFrom(
                    foregroundColor: GroupPlanningUi.stone,
                    textStyle: GoogleFonts.poppins(fontSize: 12),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── ✓ pop-in animation ──────────────────────────────
                    AnimatedBuilder(
                      animation: _pop,
                      builder: (context, _) {
                        final c = Curves.elasticOut.transform(_pop.value);
                        return Transform.scale(
                          scale: c.clamp(0.0, 1.2),
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: GroupPlanningUi.forest,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: GroupPlanningUi.forest
                                      .withValues(alpha: 0.3),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 52,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    // ── Title ───────────────────────────────────────────
                    Text(
                      l10n.moodMatchConfirmTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: GroupPlanningUi.charcoal,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ── Subtitle: day + slot ────────────────────────────
                    Text(
                      l10n.moodMatchConfirmSubtitle(
                          _dayLabel(), _slotLabel(l10n)),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: GroupPlanningUi.stone,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // ── Other user status card ──────────────────────────
                    if (!_loading) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: GroupPlanningUi.softCardDecoration(
                          background: GroupPlanningUi.forestTint,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: GroupPlanningUi.forest
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                otherName.isNotEmpty
                                    ? otherName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: GroupPlanningUi.forest,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    otherName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: GroupPlanningUi.charcoal,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.moodMatchConfirmOtherNote(otherName),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: GroupPlanningUi.stone,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const _TypingDots(),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // ── View My Day CTA ─────────────────────────────────────
              GroupPlanningUi.primaryCta(
                label: l10n.moodMatchConfirmViewMyDay,
                onPressed: () => context.go('/main?tab=3'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final opacity = (Curves.easeInOut.transform(
                  t < 0.5 ? t * 2 : (1 - t) * 2,
                ) *
                0.9)
                .clamp(0.15, 0.9);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: GroupPlanningUi.forest.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
