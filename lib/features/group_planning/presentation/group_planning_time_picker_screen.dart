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

/// Change 4 — Personal start time picker. Both users complete this independently.
class GroupPlanningTimePickerScreen extends ConsumerStatefulWidget {
  const GroupPlanningTimePickerScreen({
    super.key,
    required this.sessionId,
    required this.plannedDate,
  });

  final String sessionId;
  final String plannedDate; // YYYY-MM-DD

  @override
  ConsumerState<GroupPlanningTimePickerScreen> createState() =>
      _GroupPlanningTimePickerScreenState();
}

class _GroupPlanningTimePickerScreenState
    extends ConsumerState<GroupPlanningTimePickerScreen> {
  List<GroupMemberView> _members = [];
  bool _loading = true;
  String? _selectedSlot; // 'morning' | 'afternoon' | 'evening'
  bool _saving = false;

  static const _slots = ['morning', 'afternoon', 'evening'];
  static const _slotEmojis = {'morning': '🌅', 'afternoon': '☀️', 'evening': '🌆'};
  static const _slotRanges = {
    'morning': '9–12',
    'afternoon': '12–17',
    'evening': '17–22',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      final members = await repo.fetchMembersWithProfiles(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _firstName(String displayName) {
    final s = displayName.trim();
    if (s.isEmpty) return '?';
    // `GroupMemberView.displayName` returns `@username` when the profile only
    // has a handle. `split('@').first` on that returns an empty string, so
    // strip the leading `@` first to avoid empty-subject copy downstream.
    if (s.startsWith('@')) {
      final u = s.substring(1).trim();
      if (u.isNotEmpty) {
        final parts = u.split(RegExp(r'\s+'));
        if (parts.isNotEmpty && parts.first.isNotEmpty) return parts.first;
      }
    }
    final beforeAt = s.split('@').first.trim();
    final parts = beforeAt.split(RegExp(r'\s+'));
    return parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : '?';
  }

  GroupMemberView? _otherMember() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    for (final m in _members) {
      if (m.member.userId != uid) return m;
    }
    return null;
  }

  String _dayDisplayLabel() {
    final dt = DateTime.tryParse(widget.plannedDate);
    if (dt == null) return widget.plannedDate;
    return DateFormat('EEEE d MMMM').format(dt);
  }

  String _slotNote(AppLocalizations l10n, String slot) {
    switch (slot) {
      case 'morning':
        return l10n.moodMatchTimePickerMorningNote;
      case 'afternoon':
        return l10n.moodMatchTimePickerAfternoonNote;
      case 'evening':
        return l10n.moodMatchTimePickerEveningNote;
      default:
        return '';
    }
  }

  String _slotLabel(AppLocalizations l10n, String slot) {
    switch (slot) {
      case 'morning':
        return l10n.moodMatchTimePickerMorning;
      case 'afternoon':
        return l10n.moodMatchTimePickerAfternoon;
      case 'evening':
        return l10n.moodMatchTimePickerEvening;
      default:
        return slot;
    }
  }

  List<Map<String, dynamic>> _activitiesFromPlan(
      Map<String, dynamic>? planData) {
    if (planData == null) return [];
    final recs = planData['recommendations'] as List<dynamic>?;
    if (recs == null) return [];
    return recs.take(3).map((r) {
      final m = Map<String, dynamic>.from(r as Map);
      return {
        'name': m['name'] ?? m['title'] ?? 'Activity',
        'place_id': m['place_id']?.toString() ?? m['id']?.toString() ?? '',
        'duration_minutes': (m['duration_minutes'] as num?)?.toInt() ?? 60,
      };
    }).toList();
  }

  DateTime _activityStartTime(int indexInList) {
    final slot = _selectedSlot ?? 'morning';
    final baseHour = switch (slot) {
      'morning' => 9,
      'afternoon' => 12,
      'evening' => 17,
      _ => 12,
    };
    final baseMin = baseHour * 60 + indexInList * 90;
    return DateTime(2000, 1, 1, baseMin ~/ 60, baseMin % 60);
  }

  Future<void> _save() async {
    if (_selectedSlot == null) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      final plan = await repo.fetchPlan(widget.sessionId);
      final activities = _activitiesFromPlan(plan?.planData);

      await repo.saveGroupScheduledActivities(
        sessionId: widget.sessionId,
        scheduledDate: widget.plannedDate,
        timeSlot: _selectedSlot!,
        activities: activities,
      );

      if (mounted) {
        context.go(
            '/group-planning/confirmation/${widget.sessionId}?date=${widget.plannedDate}&slot=${_selectedSlot!}');
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final other = _otherMember();
    final otherName = other != null
        ? _firstName(other.displayName)
        : l10n.moodMatchFriendThey;
    final dayLabel = _dayDisplayLabel();

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
        title: l10n.moodMatchTimePickerStep,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.moodMatchTimePickerTitle,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: GroupPlanningUi.charcoal,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.moodMatchTimePickerSubtitle(dayLabel, otherName),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: GroupPlanningUi.stone,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              // Locked day badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: GroupPlanningUi.forestTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GroupPlanningUi.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 16, color: GroupPlanningUi.forest),
                    const SizedBox(width: 8),
                    Text(
                      dayLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: GroupPlanningUi.forest,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: GroupPlanningUi.forest,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Locked ✓',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Slot buttons
              ...List.generate(_slots.length, (i) {
                final slot = _slots[i];
                final sel = _selectedSlot == slot;
                return Padding(
                  padding: EdgeInsets.only(bottom: i < _slots.length - 1 ? 12 : 0),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedSlot = slot);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(16),
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
                                      .withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Text(
                            _slotEmojis[slot] ?? '🕐',
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_slotLabel(l10n, slot)}  ${_slotRanges[slot]}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: sel
                                        ? Colors.white
                                        : GroupPlanningUi.charcoal,
                                  ),
                                ),
                                if (sel) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _slotNote(l10n, slot),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      fontStyle: FontStyle.italic,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (sel)
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (_selectedSlot != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: GroupPlanningUi.softCardDecoration(
                    background: const Color(0xFFFFF0F5),
                  ),
                  child: Row(
                    children: [
                      const Text('💕', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        l10n.moodMatchTimePickerWithBadge(otherName),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB5375E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Text(
                l10n.moodMatchTimePickerOtherNote(otherName),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: GroupPlanningUi.stone,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              GroupPlanningUi.primaryCta(
                label: l10n.moodMatchTimePickerCta,
                onPressed:
                    _selectedSlot != null && !_saving ? _save : null,
                busy: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
