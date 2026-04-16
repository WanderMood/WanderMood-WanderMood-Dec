import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Join an existing session: scan QR (primary) or enter code.
class GroupPlanningJoinScreen extends ConsumerStatefulWidget {
  const GroupPlanningJoinScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  ConsumerState<GroupPlanningJoinScreen> createState() =>
      _GroupPlanningJoinScreenState();
}

class _GroupPlanningJoinScreenState
    extends ConsumerState<GroupPlanningJoinScreen> {
  late final TextEditingController _codeController;
  bool _busy = false;
  late bool _manualEntry;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCode?.trim();
    _codeController = TextEditingController(text: initial ?? '');
    _manualEntry = initial != null && initial.isNotEmpty;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinWithCode(String code) async {
    final l10n = AppLocalizations.of(context)!;
    final normalized = code.trim().toUpperCase();
    if (normalized.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.groupPlanJoinSnackEnterCode)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      final sessionId = await repo.joinSession(normalized);
      await MoodMatchSessionPrefs.save(
        sessionId: sessionId,
        joinCode: normalized,
      );
      if (!mounted) return;
      context.go(
        '/group-planning/lobby/$sessionId',
        extra: {'joinCode': normalized},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.groupPlanJoinError('$e'))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinFromField() async {
    await _joinWithCode(_codeController.text);
  }

  Future<void> _openScanner() async {
    final code = await context.push<String>('/group-planning/scan');
    if (!mounted) return;
    if (code == null || code.isEmpty) return;
    _codeController.text = code;
    await _joinWithCode(code);
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
                    padding: const EdgeInsets.fromLTRB(20, 44, 20, 28),
                    decoration: const BoxDecoration(
                      color: GroupPlanningUi.forest,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🔗',
                          style: TextStyle(fontSize: 44),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.groupPlanJoinTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.groupPlanJoinBody,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            height: 1.4,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_manualEntry) ...[
                      GroupPlanningUi.primaryCta(
                        label: l10n.groupPlanJoinScanQr,
                        busy: _busy,
                        onPressed: _busy ? null : _openScanner,
                        leading: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() => _manualEntry = true),
                          child: Text(
                            l10n.groupPlanJoinEnterInstead,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: GroupPlanningUi.forest,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        l10n.groupPlanJoinCodeLabel.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: GroupPlanningUi.stone,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: GroupPlanningUi.cardDecoration(),
                        child: TextField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          autocorrect: false,
                          style: GoogleFonts.robotoMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: GroupPlanningUi.charcoal,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.groupPlanJoinCodeHint,
                            hintStyle: GoogleFonts.robotoMono(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                              color: GroupPlanningUi.stone,
                            ),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      GroupPlanningUi.primaryCta(
                        label: l10n.groupPlanJoinButton,
                        busy: _busy,
                        onPressed: _busy ? null : _joinFromField,
                        leading: const Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() => _manualEntry = false),
                          child: Text(
                            l10n.groupPlanJoinScanInstead,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: GroupPlanningUi.forest,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      l10n.groupPlanHowItWorksBody,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        height: 1.45,
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
