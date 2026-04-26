import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/profile/domain/providers/current_user_profile_provider.dart';
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
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.groupPlanSessionNamePlaceholder)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      final r = await repo.createSession(
        title: title,
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
      GroupPlanningUi.showErrorSnack(
        context,
        l10n,
        e,
        fallback: l10n.groupPlanCreateError(''),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topInset = MediaQuery.paddingOf(context).top;
    final meAvatarUrl =
        ref.watch(currentUserProfileProvider).valueOrNull?.avatarUrl;
    return Scaffold(
      backgroundColor: GroupPlanningUi.moodMatchDeep,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, topInset + 26, 16, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      GroupPlanningUi.moodMatchDeepSurface,
                      GroupPlanningUi.moodMatchDeep,
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 70,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _AvatarCircle(
                            label: l10n.groupPlanYouShort,
                            bg: GroupPlanningUi.forestTint,
                            fg: GroupPlanningUi.forest,
                            avatarUrl: meAvatarUrl,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 58,
                            height: 58,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFBFD8FF).withValues(alpha: 0.5),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: const MoodyCharacter(size: 42, mood: 'happy'),
                          ),
                          const SizedBox(width: 8),
                          _AvatarCircle(
                            label: '?',
                            bg: const Color(0xFFFFE4D6),
                            fg: GroupPlanningUi.charcoal,
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
                top: topInset + 4,
                left: 8,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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
          Expanded(
            child: Material(
              color: GroupPlanningUi.cream,
              elevation: 8,
              shadowColor: GroupPlanningUi.moodMatchShadow(0.35),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: GroupPlanningUi.stone.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.groupPlanSessionNameLabel
                          .replaceAll('(optional)', '')
                          .replaceAll('(OPTIONAL)', '')
                          .trim()
                          .toUpperCase(),
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
                      leading: const Icon(
                        Icons.ios_share_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.label,
    required this.bg,
    required this.fg,
    this.avatarUrl,
  });

  final String label;
  final Color bg;
  final Color fg;
  final String? avatarUrl;

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
      clipBehavior: Clip.antiAlias,
      child: (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
          ? WmNetworkImage(
              avatarUrl!.trim(),
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _labelText(),
            )
          : _labelText(),
    );
  }

  Widget _labelText() {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: label.length <= 4 ? 11 : 18,
        color: fg,
      ),
    );
  }
}
