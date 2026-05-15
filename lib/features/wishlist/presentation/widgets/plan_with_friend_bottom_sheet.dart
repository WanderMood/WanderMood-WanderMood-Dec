import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/features/group_planning/data/profile_invite_search_row.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/group_planning/presentation/share_sheet_origin.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/wishlist/data/plan_met_vriend_service.dart';
import 'package:wandermood/features/wishlist/data/plan_with_friend_recent_friends_store.dart';
import 'package:wandermood/features/wishlist/domain/plan_met_vriend_flow.dart';
import 'package:wandermood/features/wishlist/domain/plan_met_vriend_invite_link.dart';
import 'package:wandermood/features/wishlist/presentation/providers/plan_with_friend_suggested_friends_provider.dart';
import 'package:wandermood/features/wishlist/presentation/utils/plan_with_friend_launcher.dart';
import 'package:wandermood/l10n/app_localizations.dart';

enum _PlanWithFriendStep { quickInvite, chooseTime, confirmation }

enum PlanWithFriendQuickDateOption { today, tomorrow, custom }

Future<void> showPlanWithFriendBottomSheet(
  BuildContext context, {
  required PlanWithFriendArgs args,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    isDismissible: true,
    enableDrag: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(ctx).bottom,
      ),
      child: PlanWithFriendBottomSheet(args: args),
    ),
  );
}

class PlanWithFriendBottomSheet extends ConsumerStatefulWidget {
  const PlanWithFriendBottomSheet({super.key, required this.args});

  final PlanWithFriendArgs args;

  @override
  ConsumerState<PlanWithFriendBottomSheet> createState() =>
      _PlanWithFriendBottomSheetState();
}

class _PlanWithFriendBottomSheetState
    extends ConsumerState<PlanWithFriendBottomSheet> {
  _PlanWithFriendStep _step = _PlanWithFriendStep.quickInvite;
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  final _shareKey = GlobalKey();

  Timer? _searchDebounce;
  List<ProfileInviteSearchRow> _searchResults = [];
  List<PlanMetVriendFriend> _recentFriends = [];
  bool _searching = false;

  PlanMetVriendFriend? _selectedFriend;
  PlanWithFriendQuickDateOption? _dateOption;
  DateTime? _customDate;
  String? _timeSlot = 'evening';
  bool _sending = false;

  Place? get _place => widget.args.place;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadRecentFriends();
  }

  Future<void> _loadRecentFriends() async {
    final recent = await PlanWithFriendRecentFriendsStore.load();
    if (mounted) setState(() => _recentFriends = recent);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  PlanMetVriendPlace get _pmvPlace {
    final placeData = widget.args.placeData ??
        {
          'place_id': widget.args.placeId,
          'name': widget.args.placeName,
        };
    return PlanMetVriendPlace(
      placeId: widget.args.placeId,
      placeName: widget.args.placeName,
      placeData: placeData,
      place: _place,
      sourceUrl: widget.args.sourceUrl,
    );
  }

  String? get _photoUrl => _pmvPlace.photoUrl;

  void _onSearchChanged(String raw) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final q = raw.trim();
      if (q.length < 2) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _searching = false;
          });
        }
        return;
      }
      if (mounted) setState(() => _searching = true);
      final rows = await ref
          .read(groupPlanningRepositoryProvider)
          .searchProfilesByUsernameForInvite(q);
      if (!mounted) return;
      setState(() {
        _searchResults = rows;
        _searching = false;
      });
    });
  }

  void _selectFriend(PlanMetVriendFriend friend) {
    HapticFeedback.selectionClick();
    unawaited(PlanWithFriendRecentFriendsStore.remember(friend));
    setState(() {
      _selectedFriend = friend;
      _step = _PlanWithFriendStep.chooseTime;
      _dateOption ??= PlanWithFriendQuickDateOption.today;
    });
  }

  PlanMetVriendFriend _friendFromRow(ProfileInviteSearchRow row) {
    return PlanMetVriendFriend(
      userId: row.id,
      displayName: row.fullName?.trim().isNotEmpty == true
          ? row.fullName!.trim()
          : row.displayLabel,
      username: row.username,
      avatarUrl: row.imageUrl,
    );
  }

  String _firstName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : name;
  }

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime _tomorrow() => _today().add(const Duration(days: 1));

  DateTime? get _resolvedDate {
    switch (_dateOption) {
      case PlanWithFriendQuickDateOption.today:
        return _today();
      case PlanWithFriendQuickDateOption.tomorrow:
        return _tomorrow();
      case PlanWithFriendQuickDateOption.custom:
        return _customDate;
      case null:
        return null;
    }
  }

  String _longDate(DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('EEEE d MMMM', locale).format(date);
  }

  bool get _canSend =>
      _selectedFriend != null &&
      _resolvedDate != null &&
      (_timeSlot?.isNotEmpty ?? false) &&
      !_sending;

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get _city {
    final data = _pmvPlace.placeData;
    final city = data['city'] as String? ?? data['locality'] as String?;
    if (city != null && city.trim().isNotEmpty) return city.trim();
    final p = _place;
    if (p != null && p.address.isNotEmpty) {
      final parts = p.address.split(',');
      if (parts.isNotEmpty) return parts.last.trim();
    }
    return 'Amsterdam';
  }

  String _dateLabel(AppLocalizations l10n, DateTime date) {
    final today = _today();
    if (date == today) return l10n.moodMatchDayPickerToday;
    if (date == _tomorrow()) return l10n.planMetVriendDateTomorrow;
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('EEE d MMM', locale).format(date);
  }

  String _timeLabel(AppLocalizations l10n) {
    switch (_timeSlot) {
      case 'morning':
        return '${l10n.planMetVriendTimeMorning} 🌅';
      case 'afternoon':
        return '${l10n.planMetVriendTimeAfternoon} ☀️';
      case 'evening':
        return '${l10n.planMetVriendTimeEvening} 🌆';
      default:
        return '${l10n.moodMatchDayPickerWholeDay} ✨';
    }
  }

  String _timePillLabel(AppLocalizations l10n, String slot) {
    switch (slot) {
      case 'morning':
        return '${l10n.planMetVriendTimeMorning} 🌅';
      case 'afternoon':
        return '${l10n.planMetVriendTimeAfternoon} ☀️';
      case 'evening':
        return '${l10n.planMetVriendTimeEvening} 🌆';
      default:
        return '${l10n.moodMatchDayPickerWholeDay} ✨';
    }
  }

  String _dayLabelForInvite(AppLocalizations l10n, DateTime date) {
    if (date == _today()) return l10n.moodMatchDayPickerToday;
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('EEE d MMM', locale).format(date);
  }

  Future<void> _pickCustomDate() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var temp = _customDate ?? _today().add(const Duration(days: 3));
        final l10n = AppLocalizations.of(ctx)!;
        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: GroupPlanningUi.cream,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  l10n.planMetVriendPickDateTitle,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(
                height: 280,
                child: CalendarDatePicker(
                  initialDate: temp,
                  firstDate: _today(),
                  lastDate: _today().add(const Duration(days: 365)),
                  onDateChanged: (d) => temp = d,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GroupPlanningUi.primaryCta(
                  label: l10n.planMetVriendPickDateDone,
                  onPressed: () => Navigator.pop(ctx, temp),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _customDate = DateTime(picked.year, picked.month, picked.day);
        _dateOption = PlanWithFriendQuickDateOption.custom;
      });
    }
  }

  Future<String> _inviterName() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return 'Iemand';
    final row = await Supabase.instance.client
        .from('profiles')
        .select('full_name, username')
        .eq('id', uid)
        .maybeSingle();
    if (row == null) return 'Iemand';
    final full = row['full_name'] as String?;
    if (full != null && full.trim().isNotEmpty) return full.trim();
    return (row['username'] as String?) ?? 'Iemand';
  }

  Uri get _downloadLink => planMetVriendDownloadInviteUri(
        placeId: widget.args.placeId,
        placeName: widget.args.placeName,
      );

  Future<void> _shareDownloadLink() async {
    final name = await _inviterName();
    final text = planMetVriendShareMessage(
      placeName: widget.args.placeName,
      inviterName: name,
      link: _downloadLink,
    );
    final origin = sharePositionOriginForContext(
      _shareKey.currentContext ?? context,
    );
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: widget.args.placeName,
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      await _copyDownloadLink();
    }
  }

  Future<void> _copyDownloadLink() async {
    await Clipboard.setData(ClipboardData(text: _downloadLink.toString()));
    if (!mounted) return;
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!.planMetVriendLinkCopied,
    );
  }

  Future<void> _sendInvite() async {
    if (!_canSend) return;
    final l10n = AppLocalizations.of(context)!;
    final friend = _selectedFriend!;
    final date = _resolvedDate!;
    final slot = _timeSlot ?? 'whole_day';

    setState(() => _sending = true);

    try {
      final service = ref.read(planMetVriendServiceProvider);
      final repo = ref.read(groupPlanningRepositoryProvider);
      final inviterName = await _inviterName();
      final iso = _isoDate(date);

      final result = await service.sendInvite(
        friend: friend,
        place: _pmvPlace,
        selectedDates: [date],
        city: _city,
        message: _messageController.text,
        inviterDisplayName: inviterName,
        proposedSlot: slot,
      );

      final uid = Supabase.instance.client.auth.currentUser!.id;
      await MoodMatchSessionPrefs.savePlannedDate(result.sessionId, iso);
      await MoodMatchSessionPrefs.savePendingTimeSlot(result.sessionId, slot);

      await service.proposeInitialDay(
        repo: repo,
        sessionId: result.sessionId,
        inviteId: result.inviteId,
        friendUserId: friend.userId,
        inviterUserId: uid,
        inviterDisplayName: inviterName,
        proposedDateIso: iso,
        proposedSlot: slot,
        dayLabel: _dayLabelForInvite(l10n, date),
        placeName: widget.args.placeName,
      );

      if (!mounted) return;
      unawaited(PlanWithFriendRecentFriendsStore.remember(friend));
      setState(() {
        _step = _PlanWithFriendStep.confirmation;
        _sending = false;
      });
    } catch (e, st) {
      if (kDebugMode) debugPrint('pmv sheet send: $e\n$st');
      if (mounted) {
        setState(() => _sending = false);
        showWanderMoodToast(context, message: l10n.planMetVriendSendError);
      }
    }
  }

  void _closeSheet() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height *
        (_step == _PlanWithFriendStep.chooseTime ? 0.58 : 0.52);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    final stepBody = switch (_step) {
      _PlanWithFriendStep.quickInvite => _buildQuickInvite(l10n),
      _PlanWithFriendStep.chooseTime => _buildChooseTime(l10n),
      _PlanWithFriendStep.confirmation => _buildConfirmation(l10n),
    };

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: const BoxDecoration(
              color: GroupPlanningUi.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x331A1714),
                  blurRadius: 28,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: GroupPlanningUi.stone.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  stepBody,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInvite(AppLocalizations l10n) {
    final query = _searchController.text.trim();
    final useSearch = query.length >= 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        InvitePlacePreview(
          placeName: widget.args.placeName,
          subtitle: _placeSubtitle(),
          photoUrl: _photoUrl,
        ),
        const SizedBox(height: 14),
        FriendSearchInput(
          controller: _searchController,
          hint: l10n.planMetVriendSearchFriend,
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: 12),
        if (_searching)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (useSearch)
          _buildSearchResults(l10n)
        else
          _buildSuggestedFriends(l10n),
        if (!useSearch && _recentFriends.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildRecentFriends(l10n),
        ],
        const SizedBox(height: 12),
        InviteMessageField(
          controller: _messageController,
          label: l10n.planMetVriendMessageOptional,
          hint: l10n.planMetVriendMessageHint,
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: _shareKey,
          child: TextButton.icon(
            onPressed: _shareDownloadLink,
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: Text(
              l10n.planMetVriendInviteViaLink,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: GroupPlanningUi.forest,
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildSuggestedFriends(AppLocalizations l10n) {
    final async = ref.watch(planWithFriendSuggestedFriendsProvider);
    return async.when(
      loading: () => const SizedBox(
        height: 88,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (friends) {
        if (friends.isEmpty) {
          return Text(
            l10n.planMetVriendNoFriendsFound,
            style: GoogleFonts.poppins(fontSize: 12, color: GroupPlanningUi.stone),
          );
        }
        return FriendSuggestionsRow(
          friends: friends,
          selectedId: _selectedFriend?.userId,
          onSelect: _selectFriend,
        );
      },
    );
  }

  Widget _buildRecentFriends(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.planMetVriendRecentFriends,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: GroupPlanningUi.stone,
          ),
        ),
        const SizedBox(height: 8),
        FriendSuggestionsRow(
          friends: _recentFriends,
          selectedId: _selectedFriend?.userId,
          onSelect: _selectFriend,
        ),
      ],
    );
  }

  Widget _buildSearchResults(AppLocalizations l10n) {
    if (_searchResults.isEmpty) {
      return Text(
        l10n.planMetVriendNoFriendsFound,
        style: GoogleFonts.poppins(fontSize: 12, color: GroupPlanningUi.stone),
      );
    }
    final friends =
        _searchResults.map(_friendFromRow).toList(growable: false);
    return FriendSuggestionsRow(
      friends: friends,
      selectedId: _selectedFriend?.userId,
      onSelect: _selectFriend,
    );
  }

  Widget _buildChooseTime(AppLocalizations l10n) {
    final friend = _selectedFriend;
    final date = _resolvedDate;
    if (friend == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        _SelectedFriendRow(friend: friend),
        const SizedBox(height: 14),
        QuickDatePills(
          todayTitle: l10n.moodMatchDayPickerToday,
          todaySubtitle: _longDate(_today()),
          tomorrowTitle: l10n.planMetVriendDateTomorrow,
          tomorrowSubtitle: _longDate(_tomorrow()),
          pickTitle: l10n.planMetVriendDatePick,
          pickSubtitle: _customDate != null &&
                  _dateOption == PlanWithFriendQuickDateOption.custom
              ? _longDate(_customDate!)
              : null,
          selected: _dateOption,
          onSelect: (opt) {
            if (opt == PlanWithFriendQuickDateOption.custom) {
              _pickCustomDate();
            } else {
              setState(() => _dateOption = opt);
            }
          },
        ),
        const SizedBox(height: 12),
        TimeOfDayPills(
          morningLabel: _timePillLabel(l10n, 'morning'),
          afternoonLabel: _timePillLabel(l10n, 'afternoon'),
          eveningLabel: _timePillLabel(l10n, 'evening'),
          wholeDayLabel: _timePillLabel(l10n, 'whole_day'),
          selectedSlot: _timeSlot,
          onSelect: (slot) => setState(() => _timeSlot = slot),
        ),
        const SizedBox(height: 12),
        InviteMessageField(
          controller: _messageController,
          label: l10n.planMetVriendMessageOptional,
          hint: l10n.planMetVriendMessageHint,
        ),
        const SizedBox(height: 14),
        GroupPlanningUi.primaryCta(
          label: l10n.planMetVriendSendInvite,
          busy: _sending,
          busyLabel: l10n.planMetVriendSending,
          onPressed: _canSend ? _sendInvite : null,
        ),
        if (date != null) ...[
          const SizedBox(height: 6),
          Text(
            '${_longDate(date)} · ${_timeLabel(l10n)}',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: GroupPlanningUi.stone,
            ),
          ),
        ],
        ],
      ),
    );
  }

  Widget _buildConfirmation(AppLocalizations l10n) {
    final friend = _selectedFriend;
    final date = _resolvedDate;
    if (friend == null || date == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        InviteConfirmationState(
          title: l10n.planMetVriendInviteSentTitle,
          subtitle: l10n.planMetVriendInviteSentBody(
            _firstName(friend.displayName),
          ),
        ),
        const SizedBox(height: 16),
        _InviteSummaryCard(
          placeName: widget.args.placeName,
          photoUrl: _photoUrl,
          dateLabel: _dateLabel(l10n, date),
          timeLabel: _timeLabel(l10n),
          friendLabel: l10n.planMetVriendWithFriend(
            _firstName(friend.displayName),
          ),
        ),
        const SizedBox(height: 16),
        GroupPlanningUi.primaryCta(
          label: l10n.planMetVriendDone,
          onPressed: _closeSheet,
        ),
        ],
      ),
    );
  }

  String _placeSubtitle() {
    final p = _place;
    if (p != null) {
      if (p.types.isNotEmpty) {
        return p.types.first.replaceAll('_', ' ');
      }
      if (p.address.isNotEmpty) {
        return p.address.split(',').first.trim();
      }
    }
    final data = widget.args.placeData;
    final cat = data?['category'] as String?;
    if (cat != null && cat.trim().isNotEmpty) return cat.trim();
    return '';
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class InvitePlacePreview extends StatelessWidget {
  const InvitePlacePreview({
    super.key,
    required this.placeName,
    required this.subtitle,
    this.photoUrl,
  });

  final String placeName;
  final String subtitle;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 52,
            height: 52,
            child: photoUrl != null
                ? WmPlacePhotoNetworkImage(photoUrl!, fit: BoxFit.cover)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [GroupPlanningUi.forest, Color(0xFF5DCAA5)],
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                placeName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: GroupPlanningUi.charcoal,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: GroupPlanningUi.stone,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class FriendSearchInput extends StatelessWidget {
  const FriendSearchInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      autocorrect: false,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, color: GroupPlanningUi.forest),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: GroupPlanningUi.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: GroupPlanningUi.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: GroupPlanningUi.forest, width: 1.5),
        ),
      ),
    );
  }
}

class FriendSuggestionsRow extends StatelessWidget {
  const FriendSuggestionsRow({
    super.key,
    required this.friends,
    required this.onSelect,
    this.selectedId,
  });

  final List<PlanMetVriendFriend> friends;
  final String? selectedId;
  final ValueChanged<PlanMetVriendFriend> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: friends.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final f = friends[i];
          return FriendAvatarChip(
            friend: f,
            selected: f.userId == selectedId,
            onTap: () => onSelect(f),
          );
        },
      ),
    );
  }
}

class FriendAvatarChip extends StatelessWidget {
  const FriendAvatarChip({
    super.key,
    required this.friend,
    required this.onTap,
    this.selected = false,
  });

  final PlanMetVriendFriend friend;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final name = friend.displayName;
    final first = name.trim().split(RegExp(r'\s+')).first;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: selected
                      ? GroupPlanningUi.forest
                      : GroupPlanningUi.forestTint,
                  child: friend.avatarUrl != null &&
                          friend.avatarUrl!.trim().isNotEmpty
                      ? ClipOval(
                          child: WmNetworkImage(
                            friend.avatarUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          first.isNotEmpty ? first[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : GroupPlanningUi.forest,
                          ),
                        ),
                ),
                if (selected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: GroupPlanningUi.forest,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: GroupPlanningUi.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InviteMessageField extends StatelessWidget {
  const InviteMessageField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: GroupPlanningUi.stone,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLength: 80,
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          ),
        ),
      ],
    );
  }
}

class _SelectedFriendRow extends StatelessWidget {
  const _SelectedFriendRow({required this.friend});

  final PlanMetVriendFriend friend;

  @override
  Widget build(BuildContext context) {
    final first = friend.displayName.trim().split(RegExp(r'\s+')).first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: GroupPlanningUi.cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: GroupPlanningUi.forestTint,
            child: friend.avatarUrl != null &&
                    friend.avatarUrl!.trim().isNotEmpty
                ? ClipOval(
                    child: WmNetworkImage(
                      friend.avatarUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    first.isNotEmpty ? first[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: GroupPlanningUi.forest,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              first,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const Icon(Icons.check_circle, color: GroupPlanningUi.forest),
        ],
      ),
    );
  }
}

class QuickDatePills extends StatelessWidget {
  const QuickDatePills({
    super.key,
    required this.todayTitle,
    required this.todaySubtitle,
    required this.tomorrowTitle,
    required this.tomorrowSubtitle,
    required this.pickTitle,
    required this.selected,
    required this.onSelect,
    this.pickSubtitle,
  });

  final String todayTitle;
  final String todaySubtitle;
  final String tomorrowTitle;
  final String tomorrowSubtitle;
  final String pickTitle;
  final String? pickSubtitle;
  final PlanWithFriendQuickDateOption? selected;
  final ValueChanged<PlanWithFriendQuickDateOption> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DatePill(
            title: todayTitle,
            subtitle: todaySubtitle,
            selected: selected == PlanWithFriendQuickDateOption.today,
            onTap: () => onSelect(PlanWithFriendQuickDateOption.today),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DatePill(
            title: tomorrowTitle,
            subtitle: tomorrowSubtitle,
            selected: selected == PlanWithFriendQuickDateOption.tomorrow,
            onTap: () => onSelect(PlanWithFriendQuickDateOption.tomorrow),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DatePill(
            title: pickTitle,
            subtitle: pickSubtitle,
            showCalendarIcon: pickSubtitle == null,
            selected: selected == PlanWithFriendQuickDateOption.custom,
            onTap: () => onSelect(PlanWithFriendQuickDateOption.custom),
          ),
        ),
      ],
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.showCalendarIcon = false,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final bool showCalendarIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : GroupPlanningUi.charcoal;
    final subFg = selected
        ? Colors.white.withValues(alpha: 0.88)
        : GroupPlanningUi.stone;

    return Material(
      color: selected ? GroupPlanningUi.forest : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? GroupPlanningUi.forest : GroupPlanningUi.cardBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                    color: subFg,
                  ),
                ),
              ] else if (showCalendarIcon) ...[
                const SizedBox(height: 4),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: subFg,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TimeOfDayPills extends StatelessWidget {
  const TimeOfDayPills({
    super.key,
    required this.morningLabel,
    required this.afternoonLabel,
    required this.eveningLabel,
    required this.wholeDayLabel,
    required this.selectedSlot,
    required this.onSelect,
  });

  final String morningLabel;
  final String afternoonLabel;
  final String eveningLabel;
  final String wholeDayLabel;
  final String? selectedSlot;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final pills = [
      (morningLabel, 'morning'),
      (afternoonLabel, 'afternoon'),
      (eveningLabel, 'evening'),
      (wholeDayLabel, 'whole_day'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in pills)
          _Pill(
            label: p.$1,
            selected: selectedSlot == p.$2,
            onTap: () => onSelect(p.$2),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? GroupPlanningUi.forest : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? GroupPlanningUi.forest : GroupPlanningUi.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : GroupPlanningUi.charcoal,
            ),
          ),
        ),
      ),
    );
  }
}

class InviteConfirmationState extends StatelessWidget {
  const InviteConfirmationState({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const MoodyCharacter(size: 64, mood: 'happy'),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: GroupPlanningUi.charcoal,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: GroupPlanningUi.stone,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _InviteSummaryCard extends StatelessWidget {
  const _InviteSummaryCard({
    required this.placeName,
    required this.dateLabel,
    required this.timeLabel,
    required this.friendLabel,
    this.photoUrl,
  });

  final String placeName;
  final String? photoUrl;
  final String dateLabel;
  final String timeLabel;
  final String friendLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: GroupPlanningUi.cardDecoration(),
      child: Row(
        children: [
          if (photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48,
                height: 48,
                child: WmPlacePhotoNetworkImage(photoUrl!, fit: BoxFit.cover),
              ),
            ),
          if (photoUrl != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  placeName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: GoogleFonts.poppins(fontSize: 12, color: GroupPlanningUi.stone),
                ),
                Text(
                  timeLabel,
                  style: GoogleFonts.poppins(fontSize: 12, color: GroupPlanningUi.stone),
                ),
                Text(
                  friendLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GroupPlanningUi.forest,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
