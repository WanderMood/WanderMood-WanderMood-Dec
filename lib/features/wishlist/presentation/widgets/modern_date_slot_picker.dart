import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// 2026-style horizontal snap date strip + time-of-day chips.
class ModernDateSlotPicker extends StatefulWidget {
  const ModernDateSlotPicker({
    super.key,
    required this.selectedDayIndex,
    required this.selectedSlot,
    required this.onDayIndexChanged,
    required this.onSlotChanged,
    this.horizonDays = 28,
  });

  final int selectedDayIndex;
  final String? selectedSlot;
  final ValueChanged<int> onDayIndexChanged;
  final ValueChanged<String?> onSlotChanged;
  final int horizonDays;

  static DateTime dayFromIndex(int index) {
    final t = DateTime.now();
    return DateTime(t.year, t.month, t.day + index);
  }

  @override
  State<ModernDateSlotPicker> createState() => _ModernDateSlotPickerState();
}

class _ModernDateSlotPickerState extends State<ModernDateSlotPicker> {
  late ScrollController _scroll;

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
    _scroll = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(ModernDateSlotPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDayIndex != widget.selectedDayIndex) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    if (!_scroll.hasClients) return;
    const itemWidth = 76.0;
    const gap = 10.0;
    final offset = (itemWidth + gap) * widget.selectedDayIndex - 24;
    _scroll.animateTo(
      offset.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Kies een dag',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: GroupPlanningUi.charcoal,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 108,
          child: ListView.separated(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: widget.horizonDays,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final day = ModernDateSlotPicker.dayFromIndex(i);
              final selected = i == widget.selectedDayIndex;
              final isToday = i == 0;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onDayIndexChanged(i);
                },
                child: AnimatedScale(
                  scale: selected ? 1.0 : 0.94,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 72,
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2A6049), Color(0xFF3D8A68)],
                            )
                          : null,
                      color: selected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : isToday
                                ? const Color(0xFF5DCAA5)
                                : GroupPlanningUi.cardBorder,
                        width: isToday && !selected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selected
                              ? GroupPlanningUi.forest.withValues(alpha: 0.35)
                              : GroupPlanningUi.moodMatchShadow(0.08),
                          blurRadius: selected ? 18 : 12,
                          offset: Offset(0, selected ? 8 : 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isToday
                              ? 'Vandaag'
                              : DateFormat('EEE', 'nl').format(day),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white.withValues(alpha: 0.85)
                                : GroupPlanningUi.stone,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('d', 'nl').format(day),
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            color: selected ? Colors.white : GroupPlanningUi.charcoal,
                          ),
                        ),
                        Text(
                          DateFormat('MMM', 'nl').format(day),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? Colors.white.withValues(alpha: 0.8)
                                : GroupPlanningUi.stone,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Deel van de dag',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: GroupPlanningUi.charcoal,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _timeChip(
              label: l10n.moodMatchDayPickerWholeDay,
              emoji: '🗓️',
              selected: widget.selectedSlot == null,
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onSlotChanged(null);
              },
            ),
            for (final slot in _slots)
              _timeChip(
                label: _slotLabel(l10n, slot),
                sub: _slotRanges[slot]!,
                emoji: _slotEmojis[slot]!,
                selected: widget.selectedSlot == slot,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onSlotChanged(slot);
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _timeChip({
    required String label,
    required String emoji,
    required bool selected,
    required VoidCallback onTap,
    String? sub,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? GroupPlanningUi.forest : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? GroupPlanningUi.forest : GroupPlanningUi.cardBorder,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: GroupPlanningUi.forest.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : GroupPlanningUi.charcoal,
                    ),
                  ),
                  if (sub != null)
                    Text(
                      sub,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: selected
                            ? Colors.white.withValues(alpha: 0.8)
                            : GroupPlanningUi.stone,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
