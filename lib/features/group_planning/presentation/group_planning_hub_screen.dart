import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/features/group_planning/domain/group_planning_deep_link.dart';
import 'package:wandermood/features/group_planning/domain/mood_match_copy.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/group_planning/presentation/share_sheet_origin.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Mood Match entry — forest header, cream body, staggered entry motion.
class GroupPlanningHubScreen extends ConsumerStatefulWidget {
  const GroupPlanningHubScreen({super.key});

  @override
  ConsumerState<GroupPlanningHubScreen> createState() =>
      _GroupPlanningHubScreenState();
}

class _GroupPlanningHubScreenState extends ConsumerState<GroupPlanningHubScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  AnimationController? _pulseWait;
  final GlobalKey _resumeShareKey = GlobalKey();

  bool _checkingActive = true;
  GroupSessionRow? _resumeSession;
  bool _resumeReadyHasPlan = false;
  DateTime? _lastActiveCheckAt;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entry.forward();
      _checkActiveSession();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When returning from Lobby/Result via tab switch or navigator, the widget may
    // stay mounted. Re-check so we show the pending/ready card instead of the
    // default start/join buttons.
    final now = DateTime.now();
    final last = _lastActiveCheckAt;
    if (last == null ||
        now.difference(last) > const Duration(milliseconds: 800)) {
      _lastActiveCheckAt = now;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _checkActiveSession());
    }
  }

  @override
  void dispose() {
    _pulseWait?.dispose();
    _entry.dispose();
    super.dispose();
  }

  void _ensurePulse() {
    if (_resumeSession != null &&
        !_resumeReadyHasPlan &&
        (_resumeSession!.status == 'waiting' ||
            _resumeSession!.status == 'generating')) {
      _pulseWait ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    } else {
      _pulseWait?.dispose();
      _pulseWait = null;
    }
  }

  Future<void> _checkActiveSession() async {
    if (!mounted) return;
    _pulseWait?.dispose();
    _pulseWait = null;
    _lastActiveCheckAt = DateTime.now();
    setState(() => _checkingActive = true);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) {
        setState(() {
          _checkingActive = false;
          _resumeSession = null;
          _resumeReadyHasPlan = false;
        });
        _ensurePulse();
      }
      return;
    }
    final prefs = await MoodMatchSessionPrefs.read();
    if (prefs.sessionId == null || prefs.sessionId!.isEmpty) {
      if (mounted) {
        setState(() {
          _checkingActive = false;
          _resumeSession = null;
          _resumeReadyHasPlan = false;
        });
        _ensurePulse();
      }
      return;
    }
    final repo = ref.read(groupPlanningRepositoryProvider);
    final detail = await repo.fetchSessionWithMembers(prefs.sessionId!);
    if (!mounted) return;
    if (detail == null) {
      await MoodMatchSessionPrefs.clear();
      setState(() {
        _checkingActive = false;
        _resumeSession = null;
        _resumeReadyHasPlan = false;
      });
      _ensurePulse();
      return;
    }
    final s = detail.session;
    final now = DateTime.now();
    if (!s.expiresAt.isAfter(now) ||
        s.status == 'expired' ||
        s.status == 'error') {
      await MoodMatchSessionPrefs.clear();
      setState(() {
        _checkingActive = false;
        _resumeSession = null;
        _resumeReadyHasPlan = false;
      });
      _ensurePulse();
      return;
    }
    if (s.status == 'ready') {
      final plan = await repo.fetchPlan(s.id);
      if (!mounted) return;
      await MoodMatchSessionPrefs.save(
        sessionId: s.id,
        joinCode: s.joinCode,
      );
      setState(() {
        _checkingActive = false;
        _resumeSession = s;
        _resumeReadyHasPlan = plan != null;
      });
      _ensurePulse();
      return;
    }
    if (s.status == 'waiting' || s.status == 'generating') {
      await MoodMatchSessionPrefs.save(
        sessionId: s.id,
        joinCode: s.joinCode,
      );
      setState(() {
        _checkingActive = false;
        _resumeSession = s;
        _resumeReadyHasPlan = false;
      });
      _ensurePulse();
      return;
    }
    await MoodMatchSessionPrefs.clear();
    if (mounted) {
      setState(() {
        _checkingActive = false;
        _resumeSession = null;
        _resumeReadyHasPlan = false;
      });
      _ensurePulse();
    }
  }

  Future<void> _onCancelResume(AppLocalizations l10n) async {
    final s = _resumeSession;
    if (s == null) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final repo = ref.read(groupPlanningRepositoryProvider);
    try {
      if (s.createdBy == uid) {
        await repo.deleteSession(s.id);
      } else {
        await repo.removeSelfFromSession(s.id);
      }
      await MoodMatchSessionPrefs.clear();
      if (!mounted) return;
      setState(() {
        _resumeSession = null;
        _resumeReadyHasPlan = false;
      });
      _ensurePulse();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.moodMatchHubCancelError('$e'))),
        );
      }
    }
  }

  void _continueLobby() {
    final s = _resumeSession;
    if (s == null) return;
    final code = s.joinCode;
    context.go(
      '/group-planning/lobby/${s.id}',
      extra: {'joinCode': code},
    );
  }

  void _openResult() {
    final s = _resumeSession;
    if (s == null) return;
    context.go('/group-planning/result/${s.id}');
  }

  Future<void> _shareResume({
    required AppLocalizations l10n,
    required String joinCode,
    required bool isReminder,
  }) async {
    final codeUpper = joinCode.trim().toUpperCase();
    final joinLink = groupPlanningJoinShareLink(codeUpper).toString();
    final text = isReminder
        ? '👀 ${l10n.moodMatchInviteShare(codeUpper)}\n$joinLink'
        : '${l10n.moodMatchInviteShare(codeUpper)}\n$joinLink';

    final origin = sharePositionOriginForContext(
      _resumeShareKey.currentContext ?? context,
    );
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: l10n.groupPlanShareSubject,
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      // no-op
    }
  }

  String _sessionDisplayTitle(AppLocalizations l10n) {
    final t = _resumeSession?.title?.trim();
    if (t != null && t.isNotEmpty) return t;
    return l10n.moodMatchHubUntitledSession;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final commStyle = ref.watch(preferencesProvider).communicationStyle;
    final hubMoodyIntro = moodMatchHubMoodyIntroLine(
      l10n,
      communicationStyle: commStyle,
      hasActivePendingSession: _resumeSession != null && !_resumeReadyHasPlan,
    );

    final charCurve = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.2, 0.5, curve: Curves.elasticOut),
    );
    final card1 = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.35, 0.72, curve: Curves.easeOutCubic),
    );
    final card2 = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.45, 0.82, curve: Curves.easeOutCubic),
    );

    return Scaffold(
      backgroundColor: GroupPlanningUi.cream,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 68, 16, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2A6049),
                      Color(0xFF163C2A), // Darker, richer forest green
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    ScaleTransition(
                      scale: Tween<double>(begin: 0, end: 1).animate(charCurve),
                      child: const MoodyCharacter(size: 56, mood: 'happy'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.moodMatchNewFeatureBadge.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.moodMatchTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.moodMatchTaglineHub,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 44,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/main');
                    }
                  },
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          GroupPlanningUi.forestTint,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: GroupPlanningUi.forest.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: GroupPlanningUi.forest.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const MoodyCharacter(size: 38, mood: 'happy'),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            hubMoodyIntro,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: GroupPlanningUi.charcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_checkingActive)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: GroupPlanningUi.forest,
                          ),
                        ),
                      ),
                    )
                  else if (_resumeSession != null && _resumeReadyHasPlan)
                    FadeTransition(
                      opacity: card1,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(card1),
                        child: _ReadyResumeCard(
                          l10n: l10n,
                          sessionTitle: _sessionDisplayTitle(l10n),
                          onSeePlan: _openResult,
                        ),
                      ),
                    )
                  else if (_resumeSession != null)
                    FadeTransition(
                      opacity: card1,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(card1),
                        child: _PendingResumeCard(
                          l10n: l10n,
                          sessionTitle: _sessionDisplayTitle(l10n),
                          joinCode: _resumeSession!.joinCode,
                          onContinue: _continueLobby,
                          onNudgeFriend: () => _shareResume(
                            l10n: l10n,
                            joinCode: _resumeSession!.joinCode,
                            isReminder: true,
                          ),
                          onCancel: () => _onCancelResume(l10n),
                        ),
                      ),
                    )
                  else ...[
                    FadeTransition(
                      opacity: card1,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(card1),
                        child: _ActionCard(
                          iconBg: const Color(0xFFEBF3EE),
                          emoji: '✨',
                          title: l10n.moodMatchStartBtn,
                          subtitle: l10n.moodMatchStartBtnSub,
                          onTap: () => context.push('/group-planning/create'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: card2,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(card2),
                        child: _ActionCard(
                          iconBg: const Color(0xFFFFF0E8),
                          emoji: '🔗',
                          title: l10n.moodMatchJoinBtn,
                          subtitle: l10n.moodMatchJoinBtnSub,
                          onTap: () => context.push('/group-planning/join'),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: GroupPlanningUi.cream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GroupPlanningUi.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 16, color: GroupPlanningUi.stone),
                            const SizedBox(width: 6),
                            Text(
                              l10n.groupPlanHowItWorksTitle.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: GroupPlanningUi.stone,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.moodMatchHowItWorksOneLiner,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            height: 1.45,
                            color: GroupPlanningUi.dusk,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingResumeCard extends StatelessWidget {
  const _PendingResumeCard({
    required this.l10n,
    required this.sessionTitle,
    required this.joinCode,
    required this.onContinue,
    required this.onNudgeFriend,
    required this.onCancel,
  });

  final AppLocalizations l10n;
  final String sessionTitle;
  final String joinCode;
  final VoidCallback onContinue;
  final VoidCallback onNudgeFriend;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GroupPlanningUi.cardBorder),
        boxShadow: [
          BoxShadow(
            color: GroupPlanningUi.forest.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle background decoration
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    GroupPlanningUi.forestTint.withValues(alpha: 0.8),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: GroupPlanningUi.forestTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l10n.moodMatchHubPendingTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: GroupPlanningUi.forest,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onCancel,
                      icon: Icon(Icons.close,
                          color: GroupPlanningUi.stone.withValues(alpha: 0.5),
                          size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: const ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  sessionTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: GroupPlanningUi.charcoal,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.moodMatchHubPendingStory,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.4,
                    color: GroupPlanningUi.stone,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF387A5F),
                              Color(0xFF2A6049),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: FilledButton(
                          onPressed: onContinue,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            l10n.moodMatchHubOpenPlan,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onNudgeFriend,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: GroupPlanningUi.forest,
                          side: BorderSide(color: GroupPlanningUi.cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          l10n.moodMatchHubNudgeFriend,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyResumeCard extends StatelessWidget {
  const _ReadyResumeCard({
    required this.l10n,
    required this.sessionTitle,
    required this.onSeePlan,
  });

  final AppLocalizations l10n;
  final String sessionTitle;
  final VoidCallback onSeePlan;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onSeePlan,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GroupPlanningUi.cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GroupPlanningUi.forest, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.moodMatchHubReadyTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: GroupPlanningUi.forest,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                sessionTitle,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: GroupPlanningUi.charcoal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.moodMatchHubReadySubtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.35,
                  color: GroupPlanningUi.stone,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    l10n.moodMatchHubSeePlanCta,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: GroupPlanningUi.forest,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: GroupPlanningUi.forest,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.iconBg,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color iconBg;
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -2),
      child: Material(
        color: Colors.white,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GroupPlanningUi.cardBorder),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFFAFAF8),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: GroupPlanningUi.charcoal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            height: 1.35,
                            color: GroupPlanningUi.stone,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: GroupPlanningUi.stone.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
