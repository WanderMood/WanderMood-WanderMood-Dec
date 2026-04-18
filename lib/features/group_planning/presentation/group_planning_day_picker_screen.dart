import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Change 3 — Day picker screen.
/// OWNER picks the shared day; GUEST waits and then confirms.
class GroupPlanningDayPickerScreen extends ConsumerStatefulWidget {
  const GroupPlanningDayPickerScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<GroupPlanningDayPickerScreen> createState() =>
      _GroupPlanningDayPickerScreenState();
}

class _GroupPlanningDayPickerScreenState
    extends ConsumerState<GroupPlanningDayPickerScreen>
    with TickerProviderStateMixin {
  List<GroupMemberView> _members = [];
  GroupSessionRow? _session;
  bool _loading = true;
  bool _isOwner = false;
  int? _selectedDayIndex; // 0=today, 1=+1, 2=+2, 3=+3
  bool _confirming = false;
  String? _guestWaitingMsg;
  StreamSubscription<List<Map<String, dynamic>>>? _eventSub;

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pulse.dispose();
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      final results = await Future.wait([
        repo.fetchSession(widget.sessionId),
        repo.fetchMembersWithProfiles(widget.sessionId),
      ]);
      final session = results[0] as GroupSessionRow;
      final members = results[1] as List<GroupMemberView>;
      final uid = Supabase.instance.client.auth.currentUser?.id;
      final isOwner = session.createdBy == uid;

      if (!mounted) return;
      setState(() {
        _session = session;
        _members = members;
        _isOwner = isOwner;
        _loading = false;
      });

      if (!isOwner) {
        _subscribeToGuestEvents();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribeToGuestEvents() {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      final supabase = Supabase.instance.client;
      _eventSub = supabase
          .from('realtime_events')
          .stream(primaryKey: ['id'])
          .eq('recipient_id', uid)
          .listen((rows) {
            for (final row in rows) {
              final evType = row['event_type'] as String?;
              final data = row['event_data'];
              if (evType == 'planUpdate' && data is Map) {
                final event = data['event'] as String?;
                final date = data['proposed_date'] as String?;
                final byName = data['proposed_by_username'] as String?;
                if (event == 'day_proposed' && date != null && mounted) {
                  _showGuestDayConfirmDialog(date, byName ?? 'your match');
                  return;
                }
              }
            }
          });
    } catch (_) {}
  }

  String _firstName(String displayName) {
    final s = displayName.trim();
    if (s.isEmpty) return '?';
    final beforeAt = s.split('@').first.trim();
    final parts = beforeAt.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : '?';
  }

  GroupMemberView? _guestMember() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    for (final m in _members) {
      if (m.member.userId != uid) return m;
    }
    return null;
  }

  GroupMemberView? _myMember() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    for (final m in _members) {
      if (m.member.userId == uid) return m;
    }
    return null;
  }

  DateTime _dayFromIndex(int i) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: i));
  }

  String _dayLabel(AppLocalizations l10n, int i) {
    if (i == 0) return l10n.moodMatchDayPickerToday;
    final d = _dayFromIndex(i);
    return DateFormat('EEE d').format(d);
  }

  String _isoDate(int index) {
    final d = _dayFromIndex(index);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDay() async {
    if (_selectedDayIndex == null) return;
    setState(() => _confirming = true);
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      final iso = _isoDate(_selectedDayIndex!);
      await repo.writePlannedDate(widget.sessionId, iso);

      final guest = _guestMember();
      final me = _myMember();
      final myName = me != null ? _firstName(me.displayName) : 'Owner';
      if (guest != null) {
        final l10n = AppLocalizations.of(context)!;
        final dayLabel = _dayLabel(l10n, _selectedDayIndex!);
        await repo.sendPlanUpdateEvent(
          targetUserId: guest.member.userId,
          sessionId: widget.sessionId,
          payload: {
            'event': 'day_proposed',
            'proposed_date': iso,
            'proposed_day_label': dayLabel,
            'proposed_by_username': myName,
          },
        );
      }

      if (mounted) {
        context.go(
            '/group-planning/time-picker/${widget.sessionId}?date=$iso');
      }
    } catch (_) {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _showGuestDayConfirmDialog(
      String isoDate, String ownerName) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final dt = DateTime.tryParse(isoDate);
    final dayLabel = dt != null ? DateFormat('EEEE d MMMM').format(dt) : isoDate;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: BoxDecoration(
              color: GroupPlanningUi.cream,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.moodMatchGuestConfirmDay(dayLabel),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: GroupPlanningUi.charcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"$ownerName picked $dayLabel — works for you?"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: GroupPlanningUi.stone,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: GroupPlanningUi.primaryCta(
                    label: l10n.moodMatchGuestConfirmYes,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: GroupPlanningUi.secondaryCta(
                    label: l10n.moodMatchGuestConfirmNo,
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      context.go(
          '/group-planning/time-picker/${widget.sessionId}?date=$isoDate');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).top;

    if (_loading) {
      return Scaffold(
        backgroundColor: GroupPlanningUi.cream,
        body: const Center(
          child: CircularProgressIndicator(color: GroupPlanningUi.forest),
        ),
      );
    }

    return Scaffold(
      backgroundColor: GroupPlanningUi.cream,
      appBar: GroupPlanningUi.buildAppBar(
        context: context,
        title: _isOwner ? l10n.moodMatchDayPickerStep : '...',
      ),
      body: _isOwner ? _buildOwnerBody(l10n) : _buildGuestBody(l10n),
    );
  }

  Widget _buildOwnerBody(AppLocalizations l10n) {
    final guest = _guestMember();
    final guestName = guest != null ? _firstName(guest.displayName) : l10n.moodMatchFriendThey;
    final me = _myMember();
    final myName = me != null ? _firstName(me.displayName) : 'You';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.moodMatchDayPickerTitle,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: GroupPlanningUi.charcoal,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.moodMatchDayPickerSubtitle(guestName),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: GroupPlanningUi.stone,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: List.generate(4, (i) {
                final sel = _selectedDayIndex == i;
                final isToday = i == 0;
                final day = _dayFromIndex(i);
                final abbrev = isToday
                    ? l10n.moodMatchDayPickerToday
                    : DateFormat('EEE').format(day);
                final dateNum = DateFormat('d').format(day);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedDayIndex = i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: sel ? GroupPlanningUi.forest : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: sel
                                ? GroupPlanningUi.forest
                                : GroupPlanningUi.cardBorder,
                            width: sel ? 2 : 1,
                          ),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                    color: GroupPlanningUi.forest
                                        .withValues(alpha: 0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            if (isToday)
                              Text(
                                l10n.moodMatchDayPickerToday,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: sel
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : GroupPlanningUi.forest,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            Text(
                              abbrev,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : GroupPlanningUi.stone,
                              ),
                            ),
                            Text(
                              dateNum,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: sel
                                    ? Colors.white
                                    : GroupPlanningUi.charcoal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (_selectedDayIndex != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: GroupPlanningUi.softCardDecoration(
                  background: GroupPlanningUi.forestTint,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _InitialsAvatar(
                            name: myName,
                            bg: const Color(0xFFE8784A),
                            size: 28),
                        const SizedBox(width: 6),
                        _InitialsAvatar(
                            name: guestName,
                            bg: GroupPlanningUi.forest,
                            size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.moodMatchDayPickerNote(guestName),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: GroupPlanningUi.forest,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l10n.moodMatchDayPickerPreview(
                          myName,
                          _dayLabel(l10n, _selectedDayIndex!),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: GroupPlanningUi.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            GroupPlanningUi.primaryCta(
              label: l10n.moodMatchDayPickerCta,
              onPressed: _selectedDayIndex != null && !_confirming
                  ? _confirmDay
                  : null,
              busy: _confirming,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestBody(AppLocalizations l10n) {
    final owner = _members.firstWhere(
      (m) => _session != null && m.member.userId == _session!.createdBy,
      orElse: () => _members.isNotEmpty ? _members.first : _members.first,
    );
    final ownerName = _firstName(owner.displayName);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _InitialsAvatar(
                name: ownerName,
                bg: const Color(0xFFE8784A),
                size: 60),
            const SizedBox(height: 20),
            Text(
              l10n.moodMatchGuestWaitingDay(ownerName),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: GroupPlanningUi.charcoal,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            _BouncingDots(pulse: _pulse),
          ],
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar(
      {required this.name, required this.bg, required this.size});

  final String name;
  final Color bg;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bg,
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _BouncingDots extends StatelessWidget {
  const _BouncingDots({required this.pulse});

  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        double dotScale(int i) {
          final phase = (pulse.value + i * 0.18) % 1.0;
          return 0.6 + 0.4 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
        }

        Widget dot(int i) => Transform.scale(
              scale: dotScale(i),
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: GroupPlanningUi.forest,
                  shape: BoxShape.circle,
                ),
              ),
            );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(0),
            const SizedBox(width: 8),
            dot(1),
            const SizedBox(width: 8),
            dot(2),
          ],
        );
      },
    );
  }
}
