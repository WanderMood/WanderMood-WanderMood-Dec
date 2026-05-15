import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/wishlist/data/plan_met_vriend_service.dart';
import 'package:wandermood/features/wishlist/presentation/widgets/plan_with_friend_bottom_sheet.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class PlanMetVriendEditInviteParams {
  const PlanMetVriendEditInviteParams({
    required this.sessionId,
    required this.inviteId,
    required this.friendUserId,
    required this.placeName,
    this.initialDate,
    this.initialSlot,
  });

  final String sessionId;
  final String inviteId;
  final String friendUserId;
  final String placeName;
  final DateTime? initialDate;
  final String? initialSlot;
}

Future<bool?> showPlanMetVriendEditInviteSheet(
  BuildContext context, {
  required PlanMetVriendEditInviteParams params,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: PlanMetVriendEditInviteSheet(params: params),
    ),
  );
}

class PlanMetVriendEditInviteSheet extends ConsumerStatefulWidget {
  const PlanMetVriendEditInviteSheet({super.key, required this.params});

  final PlanMetVriendEditInviteParams params;

  @override
  ConsumerState<PlanMetVriendEditInviteSheet> createState() =>
      _PlanMetVriendEditInviteSheetState();
}

class _PlanMetVriendEditInviteSheetState
    extends ConsumerState<PlanMetVriendEditInviteSheet> {
  PlanWithFriendQuickDateOption? _dateOption;
  DateTime? _customDate;
  String? _timeSlot;
  bool _saving = false;

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime _tomorrow() => _today().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    final initial = widget.params.initialDate;
    final slot = widget.params.initialSlot;
    _timeSlot = slot != null && slot.isNotEmpty ? slot : 'afternoon';
    if (initial == null) {
      _dateOption = PlanWithFriendQuickDateOption.tomorrow;
      return;
    }
    final d = DateTime(initial.year, initial.month, initial.day);
    if (d == _today()) {
      _dateOption = PlanWithFriendQuickDateOption.today;
    } else if (d == _tomorrow()) {
      _dateOption = PlanWithFriendQuickDateOption.tomorrow;
    } else {
      _dateOption = PlanWithFriendQuickDateOption.custom;
      _customDate = d;
    }
  }

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

  bool get _canSave =>
      _resolvedDate != null && (_timeSlot?.isNotEmpty ?? false) && !_saving;

  String _longDate(DateTime d, String locale) =>
      DateFormat.yMMMd(locale).format(d);

  Future<void> _pickCustomDate() async {
    final l10n = AppLocalizations.of(context)!;
    var temp = _customDate ?? _tomorrow();
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GroupPlanningUi.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
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
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _customDate = DateTime(picked.year, picked.month, picked.day);
        _dateOption = PlanWithFriendQuickDateOption.custom;
      });
    }
  }

  String _timePillLabel(AppLocalizations l10n, String slot) {
    switch (slot) {
      case 'morning':
        return l10n.planMetVriendPlansSlotMorning;
      case 'afternoon':
        return l10n.planMetVriendPlansSlotAfternoon;
      case 'evening':
        return l10n.planMetVriendPlansSlotEvening;
      default:
        return l10n.planMetVriendTimeAfternoon;
    }
  }

  Future<String> _inviterName() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return 'Someone';
    final profile =
        await ref.read(planMetVriendServiceProvider).fetchProfile(uid);
    return profile['displayName'] ?? profile['username'] ?? 'Someone';
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final date = _resolvedDate!;
    final slot = _timeSlot!;
    final iso =
        DateTime(date.year, date.month, date.day).toIso8601String().split('T').first;

    setState(() => _saving = true);
    try {
      final service = ref.read(planMetVriendServiceProvider);
      final repo = ref.read(groupPlanningRepositoryProvider);
      final inviterName = await _inviterName();
      final uid = Supabase.instance.client.auth.currentUser!.id;

      await MoodMatchSessionPrefs.savePlannedDate(widget.params.sessionId, iso);
      await MoodMatchSessionPrefs.savePendingTimeSlot(
        widget.params.sessionId,
        slot,
      );

      await service.proposeInitialDay(
        repo: repo,
        sessionId: widget.params.sessionId,
        inviteId: widget.params.inviteId,
        friendUserId: widget.params.friendUserId,
        inviterUserId: uid,
        inviterDisplayName: inviterName,
        proposedDateIso: iso,
        proposedSlot: slot,
        dayLabel: _longDate(date, locale),
        placeName: widget.params.placeName,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showWanderMoodToast(context, message: l10n.planMetVriendSendError);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Material(
        color: GroupPlanningUi.cream,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: GroupPlanningUi.stone.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.planMetVriendPendingEditSheetTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: GroupPlanningUi.charcoal,
                  ),
                ),
                const SizedBox(height: 18),
                QuickDatePills(
                  todayTitle: l10n.moodMatchDayPickerToday,
                  todaySubtitle: _longDate(_today(), locale),
                  tomorrowTitle: l10n.planMetVriendDateTomorrow,
                  tomorrowSubtitle: _longDate(_tomorrow(), locale),
                  pickTitle: l10n.planMetVriendDatePick,
                  pickSubtitle: _customDate != null &&
                          _dateOption == PlanWithFriendQuickDateOption.custom
                      ? _longDate(_customDate!, locale)
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
                const SizedBox(height: 18),
                GroupPlanningUi.primaryCta(
                  label: l10n.planMetVriendPendingSaveChanges,
                  busy: _saving,
                  busyLabel: l10n.planMetVriendSending,
                  onPressed: _canSave ? _save : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
