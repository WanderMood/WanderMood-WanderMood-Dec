import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/wishlist/data/plan_met_vriend_service.dart';
import 'package:wandermood/features/wishlist/domain/plan_met_vriend_flow.dart';
import 'package:wandermood/features/wishlist/presentation/widgets/modern_date_slot_picker.dart';
import 'package:wandermood/l10n/app_localizations.dart';

const _wmCharcoal = Color(0xFF1A1714);
const _wmMuted = Color(0x8C1A1714);

/// Full-screen: scrollable day + time-of-day, then invite + date ping-pong.
class AvailabilityPickerScreen extends ConsumerStatefulWidget {
  const AvailabilityPickerScreen({
    super.key,
    required this.friend,
    required this.place,
  });

  final PlanMetVriendFriend friend;
  final PlanMetVriendPlace place;

  @override
  ConsumerState<AvailabilityPickerScreen> createState() =>
      _AvailabilityPickerScreenState();
}

class _AvailabilityPickerScreenState
    extends ConsumerState<AvailabilityPickerScreen> {
  final _messageController = TextEditingController();
  int _selectedDayIndex = 0;
  String? _selectedSlot = 'evening';
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String get _city {
    final data = widget.place.placeData;
    final city = data['city'] as String? ?? data['locality'] as String?;
    if (city != null && city.trim().isNotEmpty) return city.trim();
    final p = widget.place.place;
    if (p != null && p.address.isNotEmpty) {
      final parts = p.address.split(',');
      if (parts.isNotEmpty) return parts.last.trim();
    }
    return 'Amsterdam';
  }

  DateTime get _selectedDate =>
      ModernDateSlotPicker.dayFromIndex(_selectedDayIndex);

  String get _friendLabel {
    final u = widget.friend.username?.trim();
    if (u != null && u.isNotEmpty) return u;
    return widget.friend.displayName;
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dayLabel(AppLocalizations l10n, int index) {
    if (index == 0) return l10n.moodMatchDayPickerToday;
    return DateFormat('EEE d MMM', 'nl')
        .format(ModernDateSlotPicker.dayFromIndex(index));
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _sending = true);
    try {
      final service = ref.read(planMetVriendServiceProvider);
      final repo = ref.read(groupPlanningRepositoryProvider);
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name, username')
          .eq('id', Supabase.instance.client.auth.currentUser!.id)
          .maybeSingle();
      final inviterName = (profile?['full_name'] as String?)?.trim().isNotEmpty ==
              true
          ? profile!['full_name'] as String
          : (profile?['username'] as String?) ?? 'Iemand';

      final iso = _isoDate(_selectedDate);
      final slotPayload = _selectedSlot ?? 'whole_day';

      final result = await service.sendInvite(
        friend: widget.friend,
        place: widget.place,
        selectedDates: [_selectedDate],
        city: _city,
        message: _messageController.text,
        inviterDisplayName: inviterName,
        proposedSlot: slotPayload,
      );

      final uid = Supabase.instance.client.auth.currentUser!.id;
      await MoodMatchSessionPrefs.savePlannedDate(result.sessionId, iso);
      await MoodMatchSessionPrefs.savePendingTimeSlot(
        result.sessionId,
        slotPayload,
      );

      await service.proposeInitialDay(
        repo: repo,
        sessionId: result.sessionId,
        inviteId: result.inviteId,
        friendUserId: widget.friend.userId,
        inviterUserId: uid,
        inviterDisplayName: inviterName,
        proposedDateIso: iso,
        proposedSlot: slotPayload,
        dayLabel: _dayLabel(l10n, _selectedDayIndex),
        placeName: widget.place.placeName,
      );

      if (!mounted) return;
      context.pushReplacement('/wishlist/day-picker/${result.sessionId}');
    } catch (e, st) {
      if (kDebugMode) debugPrint('pmv send invite: $e\n$st');
      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Uitnodiging versturen mislukt. Probeer het opnieuw.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.place.photoUrl;

    return Scaffold(
      backgroundColor: GroupPlanningUi.moodMatchDeep,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              8,
              MediaQuery.paddingOf(context).top + 4,
              8,
              12,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.white70,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Wanneer kun jij?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: Material(
              color: GroupPlanningUi.cream,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const SizedBox(height: 8),
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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              if (photo != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: WmPlacePhotoNetworkImage(
                                      photo,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.place.placeName,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17,
                                        color: _wmCharcoal,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'met $_friendLabel',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: _wmMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Stel je voorkeursdag en moment voor. '
                                    '$_friendLabel kan bevestigen of een ander '
                                    'voorstel doen.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.92),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ModernDateSlotPicker(
                            selectedDayIndex: _selectedDayIndex,
                            selectedSlot: _selectedSlot,
                            onDayIndexChanged: (i) =>
                                setState(() => _selectedDayIndex = i),
                            onSlotChanged: (s) =>
                                setState(() => _selectedSlot = s),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Persoonlijk bericht',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _wmCharcoal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _messageController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Voor $_friendLabel (optioneel)',
                              hintStyle: GoogleFonts.poppins(
                                color: _wmMuted,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: GroupPlanningUi.cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: GroupPlanningUi.cardBorder),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(14)),
                                borderSide:
                                    BorderSide(color: GroupPlanningUi.forest),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: GroupPlanningUi.primaryCta(
                      label: 'Uitnodiging versturen',
                      onPressed: _sending ? null : _confirm,
                      busy: _sending,
                    ),
                  ),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
