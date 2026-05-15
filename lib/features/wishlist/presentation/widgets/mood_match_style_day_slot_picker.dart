import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Scrollable day wheel + morning / afternoon / evening chips (Mood Match UI).
class MoodMatchStyleDaySlotPicker extends StatefulWidget {
  const MoodMatchStyleDaySlotPicker({
    super.key,
    required this.selectedDayIndex,
    required this.selectedSlot,
    required this.onDayIndexChanged,
    required this.onSlotChanged,
    this.horizonDays = 21,
  });

  final int selectedDayIndex;
  final String? selectedSlot;
  final ValueChanged<int> onDayIndexChanged;
  final ValueChanged<String?> onSlotChanged;
  final int horizonDays;

  static DateTime dayFromIndex(int index) {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day + index);
  }

  @override
  State<MoodMatchStyleDaySlotPicker> createState() =>
      _MoodMatchStyleDaySlotPickerState();
}

class _MoodMatchStyleDaySlotPickerState extends State<MoodMatchStyleDaySlotPicker> {
  late FixedExtentScrollController _dayController;

  static const _slots = ['morning', 'afternoon', 'evening'];
  static const _slotEmojis = {
    'morning': '🌅',
    'afternoon': '☀️',
    'evening': '🌆',
  };
  static const _slotRanges = {
    'morning': '9–12',
    'afternoon': '12–17',
    'evening': '17–22',
  };

  @override
  void initState() {
    super.initState();
    _dayController = FixedExtentScrollController(
      initialItem: widget.selectedDayIndex,
    );
  }

  @override
  void didUpdateWidget(MoodMatchStyleDaySlotPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDayIndex != widget.selectedDayIndex &&
        _dayController.hasClients) {
      _dayController.jumpToItem(widget.selectedDayIndex);
    }
  }

  @override
  void dispose() {
    _dayController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final slotLabel = widget.selectedSlot == null
        ? l10n.moodMatchDayPickerWholeDay
        : _slotLabel(l10n, widget.selectedSlot!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Kies een dag',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: GroupPlanningUi.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: GroupPlanningUi.cardBorder),
            boxShadow: [
              BoxShadow(
                color: GroupPlanningUi.moodMatchShadow(0.10),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: GroupPlanningUi.forestTint.withValues(alpha: 0.55),
                    border: Border.all(
                      color: GroupPlanningUi.forest.withValues(alpha: 0.28),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: _dayController,
                itemExtent: 48,
                physics: const FixedExtentScrollPhysics(),
                diameterRatio: 2.0,
                perspective: 0.0025,
                squeeze: 1.05,
                onSelectedItemChanged: (idx) {
                  HapticFeedback.selectionClick();
                  widget.onDayIndexChanged(idx);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.horizonDays,
                  builder: (context, i) {
                    final day = MoodMatchStyleDaySlotPicker.dayFromIndex(i);
                    final isToday = i == 0;
                    final isSel = i == widget.selectedDayIndex;
                    final label = isToday
                        ? '${l10n.moodMatchDayPickerToday} · ${DateFormat('EEE d MMM', 'nl').format(day)}'
                        : DateFormat('EEE d MMM', 'nl').format(day);
                    return Center(
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: isSel ? 17 : 15,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel
                              ? GroupPlanningUi.charcoal
                              : GroupPlanningUi.stone.withValues(alpha: 0.85),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          l10n.moodMatchTimePickerTitle,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: GroupPlanningUi.charcoal,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.selectedSlot != null
              ? '$slotLabel · ${_slotRanges[widget.selectedSlot!]}'
              : slotLabel,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: GroupPlanningUi.stone,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: GroupPlanningUi.cardBorder),
            boxShadow: [
              BoxShadow(
                color: GroupPlanningUi.moodMatchShadow(0.07),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _slotChip(
                label: l10n.moodMatchDayPickerWholeDay,
                emoji: '🗓️',
                selected: widget.selectedSlot == null,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onSlotChanged(null);
                },
              ),
              for (final slot in _slots)
                _slotChip(
                  label: '${_slotLabel(l10n, slot)} ${_slotRanges[slot]}',
                  emoji: _slotEmojis[slot] ?? '🕐',
                  selected: widget.selectedSlot == slot,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onSlotChanged(slot);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _slotChip({
    required String label,
    required String emoji,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? GroupPlanningUi.forest : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? GroupPlanningUi.forest : GroupPlanningUi.cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : GroupPlanningUi.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
