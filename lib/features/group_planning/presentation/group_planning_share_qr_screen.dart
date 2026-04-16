import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wandermood/features/group_planning/domain/group_planning_deep_link.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_invite_wanderer_panel.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/group_planning/presentation/share_sheet_origin.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Bottom sheet for inviting: prefer in-app invite; link/QR/code live in a collapsed section.
Future<void> showGroupPlanningShareSheet(
  BuildContext context, {
  required String sessionId,
  required String joinCode,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GroupPlanningShareSheet(
      sessionId: sessionId,
      joinCode: joinCode,
    ),
  );
}

class GroupPlanningShareSheet extends StatefulWidget {
  const GroupPlanningShareSheet({
    super.key,
    required this.sessionId,
    required this.joinCode,
  });

  final String sessionId;
  final String joinCode;

  @override
  State<GroupPlanningShareSheet> createState() =>
      _GroupPlanningShareSheetState();
}

class _GroupPlanningShareSheetState extends State<GroupPlanningShareSheet> {
  final GlobalKey _shareKey = GlobalKey();
  bool _showInAppInvite = false;

  Uri _joinShareUri() =>
      groupPlanningJoinShareLink(widget.joinCode.trim().toUpperCase());

  Future<void> _shareLink() async {
    final l10n = AppLocalizations.of(context)!;
    final deepLink = _joinShareUri().toString();
    final text =
        '${l10n.groupPlanInviteShare(widget.joinCode)}\n${l10n.groupPlanInviteOpenLink(deepLink)}';
    final origin = sharePositionOriginForContext(
      _shareKey.currentContext ?? context,
    );
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: l10n.groupPlanShareSubject,
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      debugPrint('Share sheet: $e');
    }
  }

  Future<void> _copyLink() async {
    final l10n = AppLocalizations.of(context)!;
    final deepLink = _joinShareUri().toString();
    await Clipboard.setData(ClipboardData(text: deepLink));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.moodMatchShareCopiedToast)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final codeUpper = widget.joinCode.trim().toUpperCase();
    final qrUri = groupPlanningQrDeepLink(codeUpper);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = _showInAppInvite ? screenHeight * 0.72 : screenHeight * 0.70;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: GroupPlanningUi.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: GroupPlanningUi.stone.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: _showInAppInvite
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    setState(() => _showInAppInvite = false),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 18,
                                  color: GroupPlanningUi.charcoal,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  l10n.moodMatchInviteTitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: GroupPlanningUi.charcoal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: GroupPlanningUi.softCardDecoration(
                              background: GroupPlanningUi.forestTint,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const MoodyCharacter(size: 30, mood: 'happy'),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.moodMatchInviteSubtitle,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                      color: GroupPlanningUi.forest,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          GroupPlanningInviteWandererPanel(
                            sessionId: widget.sessionId,
                            joinCode: widget.joinCode,
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.groupPlanShareScreenTitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: GroupPlanningUi.charcoal,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B1A16),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const MoodyCharacter(size: 34, mood: 'happy'),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.moodMatchShareMoodyPrompt,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.92),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          GroupPlanningUi.primaryCta(
                            label: l10n.moodMatchInviteWanderMoodCta,
                            onPressed: () {
                              setState(() => _showInAppInvite = true);
                            },
                            leading: const Icon(
                              Icons.person_search_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 10),
                          KeyedSubtree(
                            key: _shareKey,
                            child: GroupPlanningUi.secondaryCta(
                              label: l10n.moodMatchShareShareLink,
                              onPressed: _shareLink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: TextButton(
                              onPressed: _copyLink,
                              child: Text(
                                l10n.moodMatchShareCopyLink,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: GroupPlanningUi.forest,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                              splashColor:
                                  GroupPlanningUi.forest.withValues(alpha: 0.08),
                            ),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: const EdgeInsets.only(bottom: 4),
                              title: Text(
                                l10n.moodMatchShareLinkQrFoldTitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: GroupPlanningUi.forest,
                                ),
                              ),
                              subtitle: Text(
                                l10n.moodMatchShareLinkQrFoldSubtitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  height: 1.3,
                                  color: GroupPlanningUi.stone,
                                ),
                              ),
                              children: [
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: GroupPlanningUi.cream,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: GroupPlanningUi.cardBorder,
                                      ),
                                    ),
                                    child: QrImageView(
                                      data: qrUri.toString(),
                                      version: QrVersions.auto,
                                      size: 160,
                                      backgroundColor: GroupPlanningUi.cream,
                                      eyeStyle: const QrEyeStyle(
                                        eyeShape: QrEyeShape.square,
                                        color: GroupPlanningUi.forest,
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape: QrDataModuleShape.square,
                                        color: GroupPlanningUi.forest,
                                      ),
                                      gapless: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: GroupPlanningUi.cardBorder,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        l10n.moodMatchShareFriendCodeIntro,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          height: 1.35,
                                          color: GroupPlanningUi.stone,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      SelectableText(
                                        codeUpper,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.robotoMono(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: GroupPlanningUi.charcoal,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.moodMatchShareBottomHint,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    height: 1.35,
                                    color: GroupPlanningUi.stone
                                        .withValues(alpha: 0.88),
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
      ),
    );
  }
}
