import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/features/group_planning/data/mood_match_invited_profile.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/features/group_planning/data/profile_invite_search_row.dart';
import 'package:wandermood/features/group_planning/domain/group_planning_deep_link.dart';
import 'package:wandermood/features/group_planning/domain/mood_match_in_app_invite_result.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Reusable username search panel for in-app invites.
class GroupPlanningInviteWandererPanel extends ConsumerStatefulWidget {
  const GroupPlanningInviteWandererPanel({
    super.key,
    required this.sessionId,
    required this.joinCode,
  });

  final String sessionId;
  final String joinCode;

  @override
  ConsumerState<GroupPlanningInviteWandererPanel> createState() =>
      _GroupPlanningInviteWandererPanelState();
}

class _GroupPlanningInviteWandererPanelState
    extends ConsumerState<GroupPlanningInviteWandererPanel> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<ProfileInviteSearchRow> _results = [];
  bool _searching = false;
  final Set<String> _invitingIds = {};
  final Set<String> _sentInviteIds = {};

  late final String _joinLink;

  @override
  void initState() {
    super.initState();
    final code = widget.joinCode.trim().toUpperCase();
    _joinLink = groupPlanningJoinShareLink(code).toString();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String raw) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final q = raw.trim();
      if (q.length < 2) {
        if (mounted) {
          setState(() {
            _results = [];
            _searching = false;
          });
        }
        return;
      }
      if (mounted) setState(() => _searching = true);
      final repo = ref.read(groupPlanningRepositoryProvider);
      final rows = await repo.searchProfilesByUsernameForInvite(q);
      if (!mounted) return;
      setState(() {
        _results = rows;
        _searching = false;
      });
    });
  }

  Future<void> _invite(ProfileInviteSearchRow row) async {
    if (_sentInviteIds.contains(row.id)) return;
    final l10n = AppLocalizations.of(context)!;
    final code = widget.joinCode.trim().toUpperCase();
    setState(() => _invitingIds.add(row.id));
    final repo = ref.read(groupPlanningRepositoryProvider);
    final result = await repo.sendMoodMatchInAppInvite(
      targetUserId: row.id,
      sessionId: widget.sessionId,
      joinCode: code,
      joinLinkHttps: _joinLink,
    );
    if (!mounted) return;
    setState(() => _invitingIds.remove(row.id));

    switch (result) {
      case MoodMatchInAppInviteResult.delivered:
        await MoodMatchSessionPrefs.upsertInvitedProfile(
          sessionId: widget.sessionId,
          profile: MoodMatchInvitedProfile(
            id: row.id,
            username: row.username,
            fullName: row.fullName,
            imageUrl: row.imageUrl,
          ),
        );
        setState(() => _sentInviteIds.add(row.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.moodMatchInviteSent)),
        );
      case MoodMatchInAppInviteResult.notDeliveredInApp:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.moodMatchInviteNotDeliveredInApp),
            action: SnackBarAction(
              label: l10n.moodMatchInviteCopyLinkAction,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _joinLink));
              },
            ),
          ),
        );
      case MoodMatchInAppInviteResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.moodMatchInviteFailed),
            action: SnackBarAction(
              label: l10n.moodMatchInviteCopyLinkAction,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _joinLink));
              },
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onQueryChanged,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: l10n.moodMatchInviteSearchHint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: GroupPlanningUi.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: GroupPlanningUi.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: GroupPlanningUi.forest),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_searching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_searchController.text.trim().length < 2 && _results.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.moodMatchInviteSearchEmpty,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: GroupPlanningUi.stone,
              ),
            ),
          )
        else if (_results.isEmpty && _searchController.text.trim().length >= 2)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.moodMatchInviteNoResults,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: GroupPlanningUi.stone,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final row = _results[i];
              final busy = _invitingIds.contains(row.id);
              final sent = _sentInviteIds.contains(row.id);
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: GroupPlanningUi.forestTint,
                    child: row.imageUrl != null && row.imageUrl!.trim().isNotEmpty
                        ? ClipOval(
                            child: WmNetworkImage(
                              row.imageUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            row.displayLabel.isNotEmpty
                                ? row.displayLabel[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: GroupPlanningUi.forest,
                            ),
                          ),
                  ),
                  title: Text(
                    row.displayLabel,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: GroupPlanningUi.charcoal,
                    ),
                  ),
                  subtitle: row.fullName != null &&
                          row.fullName!.trim().isNotEmpty &&
                          row.username != null
                      ? Text(
                          row.fullName!.trim(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: GroupPlanningUi.stone,
                          ),
                        )
                      : null,
                  trailing: busy
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : sent
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: GroupPlanningUi.forestTint,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: GroupPlanningUi.forest.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 14,
                                    color: GroupPlanningUi.forest,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.moodMatchInvitedWaitingTag,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: GroupPlanningUi.forest,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : TextButton(
                              onPressed: () => _invite(row),
                              child: Text(l10n.moodMatchInviteButton),
                            ),
                ),
              );
            },
          ),
      ],
    );
  }
}
