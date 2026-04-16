import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Start a 2-person group mood session; share link then lobby.
class GroupPlanningCreateScreen extends ConsumerStatefulWidget {
  const GroupPlanningCreateScreen({super.key});

  @override
  ConsumerState<GroupPlanningCreateScreen> createState() =>
      _GroupPlanningCreateScreenState();
}

class _GroupPlanningCreateScreenState
    extends ConsumerState<GroupPlanningCreateScreen> {
  final _titleController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      final existing = await repo.findMyActiveWaitingSession();
      if (existing != null) {
        await MoodMatchSessionPrefs.save(
          sessionId: existing.id,
          joinCode: existing.joinCode,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.moodMatchCreateAlreadyWaiting)),
        );
        context.go('/group-planning');
        return;
      }
      final r = await repo.createSession(
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
      );
      // Do not persist until the host taps "Continue to lobby" on the share
      // screen — otherwise backing out of invite/share still shows "Sessie
      // bezig" on the Mood Match hub (prefs drive hub resume).
      if (!mounted) return;
      context.go(
        '/group-planning/lobby/${r.sessionId}',
        extra: {'joinCode': r.joinCode, 'autoShowInvite': true},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.groupPlanCreateError('$e'))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: GroupPlanningUi.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 68, 16, 32),
                    decoration: const BoxDecoration(
                      color: GroupPlanningUi.forest,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 56,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.translate(
                                offset: const Offset(14, 0),
                                child: _AvatarCircle(
                                  label: l10n.groupPlanYouShort,
                                  bg: GroupPlanningUi.forestTint,
                                  fg: GroupPlanningUi.forest,
                                ),
                              ),
                              _AvatarCircle(
                                label: '?',
                                bg: const Color(0xFFFFE4D6),
                                fg: GroupPlanningUi.charcoal,
                              ),
                              Transform.translate(
                                offset: const Offset(-14, 0),
                                child: _DashedPlusCircle(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.groupPlanCreateHeaderSubtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.groupPlanCreateHeaderCaption,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.65),
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
                          context.go('/group-planning');
                        }
                      },
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.groupPlanSessionNameLabel.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: GroupPlanningUi.stone,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: GroupPlanningUi.cardDecoration(),
                      child: TextField(
                        controller: _titleController,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: GroupPlanningUi.charcoal,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.groupPlanSessionNamePlaceholder,
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 15,
                            color: GroupPlanningUi.stone,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    GroupPlanningUi.primaryCta(
                      label: l10n.groupPlanCreateCta,
                      busy: _busy,
                      onPressed: _busy ? null : _create,
                      leading: const Icon(Icons.ios_share_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.groupPlanCreateShareHint,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        height: 1.4,
                        color: GroupPlanningUi.stone,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: label.length <= 4 ? 11 : 18,
          color: fg,
        ),
      ),
    );
  }
}

class _DashedPlusCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.88),
          width: 1.6,
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        '+',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}
