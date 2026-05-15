import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/group_planning/presentation/share_sheet_origin.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/profile/domain/providers/current_user_profile_provider.dart';
import 'package:wandermood/features/wishlist/data/plan_met_vriend_service.dart';
import 'package:wandermood/features/wishlist/domain/plan_met_vriend_flow.dart';
import 'package:wandermood/features/wishlist/domain/plan_met_vriend_invite_link.dart';
import 'package:wandermood/features/wishlist/presentation/screens/plan_met_vriend_plans_screen.dart';
import 'package:wandermood/features/wishlist/presentation/utils/plan_met_vriend_navigation.dart';
import 'package:wandermood/features/wishlist/presentation/widgets/plan_met_vriend_edit_invite_sheet.dart';
import 'package:wandermood/features/wishlist/presentation/widgets/plan_invite_note_strip.dart';
import 'package:wandermood/l10n/app_localizations.dart';

const _moodyCard = Color(0xFFF0EBE2);
/// Espresso panel (matches partner stories / mood-match deep brown).
const _espressoCard = Color(0xFF251A15);
const _onEspresso = Color(0xFFF5F0E8);
const _onEspressoMuted = Color(0xFFC8BDB4);

String _planMetVriendAvatarInitial(String? label) {
  final trimmed = label?.trim();
  if (trimmed == null || trimmed.isEmpty) return '?';
  final word = trimmed.split(RegExp(r'\s+')).first;
  if (word.isEmpty) return '?';
  return word[0].toUpperCase();
}

/// Resolves [PlanMetVriendPlanListItem] when GoRouter `extra` was dropped.
class PlanMetVriendPendingDetailLoader extends ConsumerWidget {
  const PlanMetVriendPendingDetailLoader({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(planMetVriendPlansProvider);
    return async.when(
      loading: () => const Scaffold(
        backgroundColor: GroupPlanningUi.cream,
        body: Center(
          child: CircularProgressIndicator(color: GroupPlanningUi.forest),
        ),
      ),
      error: (_, __) => const PlanMetVriendPlansScreen(),
      data: (plans) {
        for (final plan in plans) {
          if (plan.sessionId == sessionId) {
            return PlanMetVriendPendingDetailScreen(plan: plan);
          }
        }
        return const PlanMetVriendPlansScreen();
      },
    );
  }
}

class PlanMetVriendPendingDetailScreen extends ConsumerStatefulWidget {
  const PlanMetVriendPendingDetailScreen({
    super.key,
    required this.plan,
  });

  final PlanMetVriendPlanListItem plan;

  @override
  ConsumerState<PlanMetVriendPendingDetailScreen> createState() =>
      _PlanMetVriendPendingDetailScreenState();
}

class _PlanMetVriendPendingDetailScreenState
    extends ConsumerState<PlanMetVriendPendingDetailScreen> {
  late PlanMetVriendPlanListItem _plan;
  RealtimeChannel? _channel;
  bool _reminding = false;
  bool _cancelling = false;
  final _shareKey = GlobalKey();
  String? _invitePeerName;
  String? _invitePeerAvatar;
  String? _inviterMessage;
  String? _inviteeReply;
  String? _inviterDisplayName;
  String? _inviterAvatarUrl;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
    _subscribe();
    _loadInvitePeer();
  }

  PlanMetVriendPlanListItem _copyPlan({
    String? inviteId,
    String? friendLabel,
    String? friendAvatarUrl,
    DateTime? plannedDate,
    String? timeSlot,
  }) {
    return PlanMetVriendPlanListItem(
      sessionId: _plan.sessionId,
      placeName: _plan.placeName,
      status: _plan.status,
      isHost: _plan.isHost,
      cardKind: _plan.cardKind,
      isCompleted: _plan.isCompleted,
      plannedDate: plannedDate ?? _plan.plannedDate,
      friendLabel: friendLabel ?? _plan.friendLabel,
      friendAvatarUrl: friendAvatarUrl ?? _plan.friendAvatarUrl,
      photoUrl: _plan.photoUrl,
      placeId: _plan.placeId,
      timeSlot: timeSlot ?? _plan.timeSlot,
      proposedByUserId: _plan.proposedByUserId,
      inviteId: inviteId ?? _plan.inviteId,
      friendUserId: _plan.friendUserId,
      locationLabel: _plan.locationLabel,
      updatedAt: _plan.updatedAt,
    );
  }

  Future<void> _loadInvitePeer() async {
    final service = ref.read(planMetVriendServiceProvider);
    final invite = await service.fetchInviteBySession(_plan.sessionId);
    if (!mounted) return;

    String? peerName;
    String? peerAvatar;
    String? inviteId = _plan.inviteId;

    String? inviterName;
    String? inviterAvatar;
    String? inviterNote;
    String? inviteeNote;

    if (invite != null) {
      inviteId ??= invite['id']?.toString();
      inviterNote = PlanMetVriendService.inviteNoteText(invite);
      inviteeNote = PlanMetVriendService.inviteNoteText(invite, reply: true);
      if (_plan.isHost) {
        peerName = (invite['invitee_display_name'] as String?)?.trim();
        peerAvatar = (invite['invitee_avatar_url'] as String?)?.trim();
        final username = (invite['invitee_username'] as String?)?.trim();
        peerName ??= username;
        final profile = ref.read(currentUserProfileProvider).valueOrNull;
        inviterName = profile?.fullName?.trim().isNotEmpty == true
            ? profile!.fullName!.trim()
            : profile?.username?.trim();
        inviterAvatar = profile?.avatarUrl?.trim();
      } else {
        final inviterId = invite['inviter_user_id']?.toString();
        if (inviterId != null && inviterId.isNotEmpty) {
          final profile = await service.fetchProfile(inviterId);
          peerName = profile['displayName']?.toString().trim() ??
              profile['username']?.toString().trim();
          peerAvatar = profile['avatarUrl']?.toString().trim();
          inviterName = peerName;
          inviterAvatar = peerAvatar;
        }
      }
    }

    setState(() {
      _invitePeerName = peerName;
      _invitePeerAvatar = peerAvatar;
      _inviterMessage = inviterNote;
      _inviteeReply = inviteeNote;
      _inviterDisplayName = inviterName;
      _inviterAvatarUrl = inviterAvatar;
      if (inviteId != null && inviteId.isNotEmpty) {
        _plan = _copyPlan(
          inviteId: inviteId,
          friendLabel: peerName ?? _plan.friendLabel,
          friendAvatarUrl: peerAvatar ?? _plan.friendAvatarUrl,
        );
      } else if (peerName != null || peerAvatar != null) {
        _plan = _copyPlan(
          friendLabel: peerName ?? _plan.friendLabel,
          friendAvatarUrl: peerAvatar ?? _plan.friendAvatarUrl,
        );
      }
    });
  }

  bool _isStatusLikeLabel(String? value, AppLocalizations l10n) {
    final t = value?.trim();
    if (t == null || t.isEmpty) return true;
    final lower = t.toLowerCase();
    if (lower == l10n.planMetVriendPlansChipWaitingGeneric.toLowerCase()) {
      return true;
    }
    if (lower.startsWith('waiting for')) return true;
    return false;
  }

  String _resolveFriendName(AppLocalizations l10n) {
    for (final candidate in [_plan.friendLabel, _invitePeerName]) {
      if (_isStatusLikeLabel(candidate, l10n)) continue;
      final first = _firstName(candidate);
      if (first.isNotEmpty) return first;
    }
    return l10n.moodMatchFriendThey;
  }

  String? _resolveFriendAvatar() {
    for (final candidate in [_plan.friendAvatarUrl, _invitePeerAvatar]) {
      final url = candidate?.trim();
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  void _subscribe() {
    final client = Supabase.instance.client;
    _channel = client
        .channel('pmv-pending-${_plan.sessionId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'group_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _plan.sessionId,
          ),
          callback: (payload) {
            final status = payload.newRecord['status']?.toString() ?? '';
            _onSessionStatus(status);
          },
        )
        .subscribe();
  }

  void _onSessionStatus(String status) {
    if (!mounted) return;
    if (status == 'match_found' || status == 'day_confirmed') {
      openPlanMetVriendDayPicker(context, _plan.sessionId);
    } else if (status == 'day_proposed') {
      ref.invalidate(planMetVriendPlansProvider);
      openPlanMetVriendDayPicker(context, _plan.sessionId);
    }
  }

  String _firstName(String? name) {
    final n = name?.trim();
    if (n == null || n.isEmpty) return '';
    return n.split(RegExp(r'\s+')).first;
  }

  String? _slotLabel(AppLocalizations l10n) {
    switch (_plan.timeSlot) {
      case 'morning':
        return l10n.planMetVriendPlansSlotMorning;
      case 'afternoon':
        return l10n.planMetVriendPlansSlotAfternoon;
      case 'evening':
        return l10n.planMetVriendPlansSlotEvening;
      default:
        return null;
    }
  }

  String? _dateLabel(AppLocalizations l10n, String locale) {
    final date = _plan.plannedDate;
    if (date == null) return null;
    final d = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (d == today) return l10n.planMetVriendPlansTonight;
    return DateFormat('EEE d MMM', locale).format(d);
  }

  String? _subtitleDate(AppLocalizations l10n, String locale) {
    final date = _plan.plannedDate;
    if (date == null) return null;
    return DateFormat.MMMd(locale).format(
      DateTime(date.year, date.month, date.day),
    );
  }

  IconData _slotIcon() {
    switch (_plan.timeSlot) {
      case 'morning':
        return Icons.wb_twilight_rounded;
      case 'evening':
        return Icons.nights_stay_rounded;
      default:
        return Icons.wb_sunny_rounded;
    }
  }

  Future<void> _remind() async {
    if (_reminding) return;
    final l10n = AppLocalizations.of(context)!;
    final friendId = _plan.friendUserId;
    final inviteId = _plan.inviteId;
    if (friendId == null || inviteId == null) {
      showWanderMoodToast(context, message: l10n.planMetVriendPendingReminderSent);
      return;
    }

    setState(() => _reminding = true);
    try {
      final profile = ref.watch(currentUserProfileProvider).valueOrNull;
      final inviterName = profile?.fullName?.trim().isNotEmpty == true
          ? profile!.fullName!.trim()
          : (profile?.username ?? 'Someone');
      await ref.read(planMetVriendServiceProvider).resendInviteReminder(
            friendUserId: friendId,
            inviterName: inviterName,
            placeName: _plan.placeName,
            sessionId: _plan.sessionId,
            inviteId: inviteId,
          );
      if (mounted) {
        showWanderMoodToast(context, message: l10n.planMetVriendPendingReminderSent);
      }
    } catch (_) {
      if (mounted) {
        showWanderMoodToast(context, message: l10n.planMetVriendPendingReminderSent);
      }
    } finally {
      if (mounted) setState(() => _reminding = false);
    }
  }

  Future<void> _editInvite() async {
    final l10n = AppLocalizations.of(context)!;
    final friendId = _plan.friendUserId;
    final inviteId = _plan.inviteId;
    if (friendId == null || inviteId == null) return;

    final updated = await showPlanMetVriendEditInviteSheet(
      context,
      params: PlanMetVriendEditInviteParams(
        sessionId: _plan.sessionId,
        inviteId: inviteId,
        friendUserId: friendId,
        placeName: _plan.placeName,
        initialDate: _plan.plannedDate,
        initialSlot: _plan.timeSlot,
      ),
    );
    if (updated == true && mounted) {
      ref.invalidate(planMetVriendPlansProvider);
      showWanderMoodToast(context, message: l10n.planMetVriendPendingEditSaved);
      final session = await ref
          .read(planMetVriendServiceProvider)
          .fetchSession(_plan.sessionId);
      final planned = session?['planned_date']?.toString();
      final slot = session?['proposed_slot']?.toString();
      if (planned != null && mounted) {
        final d = DateTime.tryParse(planned);
        setState(() {
          _plan = _copyPlan(
            plannedDate: d ?? _plan.plannedDate,
            timeSlot: slot ?? _plan.timeSlot,
          );
        });
      }
    }
  }

  Future<void> _shareLink() async {
    final l10n = AppLocalizations.of(context)!;
    final placeId = _plan.placeId ?? '';
    final link = planMetVriendDownloadInviteUri(
      placeId: placeId.isNotEmpty ? placeId : _plan.sessionId,
      placeName: _plan.placeName,
    );
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final inviterName = profile?.fullName?.trim().isNotEmpty == true
        ? profile!.fullName!.trim()
        : (profile?.username ?? 'Someone');
    final text = planMetVriendShareMessage(
      placeName: _plan.placeName,
      inviterName: inviterName,
      link: link,
    );
    final origin = sharePositionOriginForContext(
      _shareKey.currentContext ?? context,
    );
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: _plan.placeName,
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: link.toString()));
      if (mounted) {
        showWanderMoodToast(context, message: l10n.planMetVriendLinkCopied);
      }
    }
  }

  Future<void> _cancelPlan() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.planMetVriendPendingCancelTitle),
        content: Text(l10n.planMetVriendPendingCancelBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.planMetVriendPendingCancelPlan,
              style: const TextStyle(color: Color(0xFFE05C5C)),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(planMetVriendServiceProvider).cancelFriendPlan(
            sessionId: _plan.sessionId,
            isHost: _plan.isHost,
            groupRepo: ref.read(groupPlanningRepositoryProvider),
          );
      ref.invalidate(planMetVriendPlansProvider);
      if (mounted) {
        showWanderMoodToast(
          context,
          message: l10n.planMetVriendDeleteInviteSuccess,
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: l10n.planMetVriendDeleteInviteError,
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  String _waitingChipLabel(AppLocalizations l10n, String friendName) {
    if (friendName == l10n.moodMatchFriendThey) {
      return l10n.planMetVriendPlansChipWaitingGeneric;
    }
    return l10n.planMetVriendPlansChipWaitingFor(friendName);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final friendName = _resolveFriendName(l10n);
    final friendAvatar = _resolveFriendAvatar();
    final slot = _slotLabel(l10n) ?? '—';
    final subtitleDate = _subtitleDate(l10n, locale) ?? '—';
    final dateRow = _dateLabel(l10n, locale);
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final meAvatar = profile?.avatarUrl?.trim();
    final meLabel = profile?.fullName?.trim().isNotEmpty == true
        ? profile!.fullName!.trim()
        : (profile?.username?.trim() ?? '');

    return Scaffold(
      backgroundColor: GroupPlanningUi.cream,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: l10n.planMetVriendPendingTitle(friendName),
              subtitle: l10n.planMetVriendPendingSubtitle(slot, subtitleDate),
              onBack: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _TeamProfilesRow(
                      meAvatarUrl: meAvatar,
                      meFallback: _planMetVriendAvatarInitial(meLabel),
                      friendAvatarUrl: friendAvatar,
                      friendFallback: _planMetVriendAvatarInitial(friendName),
                    ),
                    const SizedBox(height: 20),
                    _MainPlanCard(
                      placeName: _plan.placeName,
                      photoUrl: _plan.photoUrl,
                      friendName: friendName,
                      friendAvatarUrl: friendAvatar,
                      statusLabel: _waitingChipLabel(l10n, friendName),
                      dateRow: dateRow != null && slot.isNotEmpty
                          ? '$dateRow · $slot'
                          : (dateRow ?? slot),
                      location: _plan.locationLabel,
                      slotIcon: _slotIcon(),
                    ),
                    if ((_inviterMessage?.isNotEmpty ?? false) ||
                        (_inviteeReply?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 16),
                      PlanInviteNoteStrip(
                        inviterName: _inviterDisplayName ?? meLabel,
                        inviterAvatarUrl: _inviterAvatarUrl ?? meAvatar,
                        inviterMessage: _inviterMessage,
                        inviteeName: friendName,
                        inviteeReply: _inviteeReply,
                      ),
                    ],
                    const SizedBox(height: 24),
                    GroupPlanningUi.primaryCta(
                      label: l10n.planMetVriendPendingSendReminder,
                      leading: const Icon(
                        Icons.notifications_active_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      busy: _reminding,
                      onPressed: _reminding ? null : _remind,
                    ),
                    const SizedBox(height: 12),
                    _OutlineActionButton(
                      label: l10n.planMetVriendPendingEditInvite,
                      icon: Icons.edit_outlined,
                      onPressed: _editInvite,
                    ),
                    const SizedBox(height: 8),
                    _ShareLinkRow(
                      key: _shareKey,
                      label: l10n.planMetVriendPendingShareLink,
                      onTap: _shareLink,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _cancelling ? null : _cancelPlan,
                      child: Text(
                        l10n.planMetVriendPendingCancelPlan,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: GroupPlanningUi.forest,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _BottomNote(
                      text: l10n.planMetVriendPendingBottomNote(friendName),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: GroupPlanningUi.charcoal,
            ),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: GroupPlanningUi.moodMatchTabActiveOrange,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: GroupPlanningUi.stone,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _TeamProfilesRow extends StatelessWidget {
  const _TeamProfilesRow({
    required this.meAvatarUrl,
    required this.meFallback,
    required this.friendAvatarUrl,
    required this.friendFallback,
  });

  final String? meAvatarUrl;
  final String meFallback;
  final String? friendAvatarUrl;
  final String friendFallback;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ProfileAvatar(url: meAvatarUrl, fallback: meFallback),
        const SizedBox(width: 10),
        const SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: MoodyCharacter(size: 30, mood: 'happy', glowOpacityScale: 0.42),
          ),
        ),
        const SizedBox(width: 10),
        _ProfileAvatar(url: friendAvatarUrl, fallback: friendFallback),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.url, required this.fallback});

  final String? url;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final resolved = url?.trim();
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: GroupPlanningUi.moodMatchShadow(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: resolved != null && resolved.isNotEmpty
            ? WmNetworkImage(
                resolved,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Initial(fallback),
              )
            : _Initial(fallback),
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.url, required this.fallback});

  final String? url;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final resolved = url?.trim();
    return ClipOval(
      child: SizedBox(
        width: 28,
        height: 28,
        child: resolved != null && resolved.isNotEmpty
            ? WmNetworkImage(
                resolved,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Initial(fallback),
              )
            : _Initial(fallback),
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final initial = _planMetVriendAvatarInitial(label);
    return ColoredBox(
      color: GroupPlanningUi.forestTint,
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: GroupPlanningUi.forest,
          ),
        ),
      ),
    );
  }
}

class _MainPlanCard extends StatelessWidget {
  const _MainPlanCard({
    required this.placeName,
    required this.photoUrl,
    required this.friendName,
    required this.friendAvatarUrl,
    required this.statusLabel,
    required this.dateRow,
    this.location,
    required this.slotIcon,
  });

  final String placeName;
  final String? photoUrl;
  final String friendName;
  final String? friendAvatarUrl;
  final String statusLabel;
  final String dateRow;
  final String? location;
  final IconData slotIcon;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _espressoCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF4D382E),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: GroupPlanningUi.moodMatchShadow(0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 108,
              height: 128,
              child: url != null && url.isNotEmpty
                  ? WmPlacePhotoNetworkImage(
                      url,
                      width: 108,
                      height: 128,
                      fit: BoxFit.cover,
                    )
                  : ColoredBox(
                      color: GroupPlanningUi.forestTint,
                      child: Icon(
                        Icons.place_rounded,
                        size: 40,
                        color: GroupPlanningUi.forest.withValues(alpha: 0.5),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  placeName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _onEspresso,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SmallAvatar(
                      url: friendAvatarUrl,
                      fallback: _planMetVriendAvatarInitial(friendName),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        friendName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _onEspresso,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: GroupPlanningUi.moodMatchTabActiveOrange
                        .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: GroupPlanningUi.moodMatchTabActiveOrange,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: GroupPlanningUi.moodMatchTabActiveOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: _onEspresso.withValues(alpha: 0.18),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: _onEspressoMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        dateRow,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _onEspresso,
                        ),
                      ),
                    ),
                    Icon(slotIcon, size: 15, color: _onEspressoMuted),
                  ],
                ),
                if (location != null && location!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: _onEspressoMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _onEspressoMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: GroupPlanningUi.forest, width: 1.5),
          ),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: GroupPlanningUi.forest),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: GroupPlanningUi.forest,
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

class _ShareLinkRow extends StatelessWidget {
  const _ShareLinkRow({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: GroupPlanningUi.forest,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.link_rounded, size: 17),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: GroupPlanningUi.forest,
          ),
        ),
      ),
    );
  }
}

class _BottomNote extends StatelessWidget {
  const _BottomNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _moodyCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GroupPlanningUi.cardBorder),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 12,
          height: 1.4,
          color: GroupPlanningUi.charcoal.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
