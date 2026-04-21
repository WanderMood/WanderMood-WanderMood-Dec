import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/home/presentation/utils/my_day_slot_period.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Bottom sheet for selecting a time slot when adding a place to My Day (Explore + Mood Match).
class AddPlaceToMyDaySheet extends ConsumerStatefulWidget {
  const AddPlaceToMyDaySheet({
    super.key,
    required this.place,
    required this.planningDate,
    required this.onTimeSelected,
  });

  final Place place;
  final DateTime planningDate;
  final FutureOr<void> Function(DateTime) onTimeSelected;

  @override
  ConsumerState<AddPlaceToMyDaySheet> createState() =>
      _AddPlaceToMyDaySheetState();
}

class _AddPlaceToMyDaySheetState extends ConsumerState<AddPlaceToMyDaySheet> {
  static const _slotKeys = ['morning', 'afternoon', 'evening'];

  late int _selectedSlotIndex;
  late DateTime _selectedDate;
  Set<String> _occupiedSlots = {};
  bool _loadingSlots = true;

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDateShort(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  String _formatDateLong(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  DateTime get _selectedStartTime {
    final d = _selectedDate;
    final hour =
        _selectedSlotIndex == 0 ? 9 : (_selectedSlotIndex == 1 ? 14 : 19);
    return DateTime(d.year, d.month, d.day, hour, 0);
  }

  int _firstFreeSlotIndex() {
    final now = DateTime.now();
    for (var i = 0; i < 3; i++) {
      if (!myDayQuickAddSlotOfferedForDay(
          slotIndex: i, selectedDay: _selectedDate, now: now)) {
        continue;
      }
      if (!_occupiedSlots.contains(_slotKeys[i])) return i;
    }
    return myDayQuickAddFirstOfferedSlotIndex(
            selectedDay: _selectedDate, now: now) ??
        2;
  }

  bool _hasBookableSlot() {
    final now = DateTime.now();
    for (var i = 0; i < 3; i++) {
      if (!myDayQuickAddSlotOfferedForDay(
          slotIndex: i, selectedDay: _selectedDate, now: now)) {
        continue;
      }
      if (!_occupiedSlots.contains(_slotKeys[i])) return true;
    }
    return false;
  }

  bool _selectedSlotIsBookable() {
    final now = DateTime.now();
    if (!myDayQuickAddSlotOfferedForDay(
        slotIndex: _selectedSlotIndex,
        selectedDay: _selectedDate,
        now: now)) {
      return false;
    }
    return !_occupiedSlots.contains(_slotKeys[_selectedSlotIndex]);
  }

  Future<void> _refreshOccupiedSlots() async {
    setState(() => _loadingSlots = true);
    final svc = ref.read(scheduledActivityServiceProvider);
    final o = await svc.getOccupiedTimeSlotKeysForPlaceOnDate(
      placeId: widget.place.id,
      date: _selectedDate,
    );
    if (!mounted) return;
    setState(() {
      _occupiedSlots = o;
      _loadingSlots = false;
      _selectedSlotIndex = _firstFreeSlotIndex();
    });
  }

  Future<void> _pickCustomDate() async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(_dateOnly(now))
          ? _dateOnly(now)
          : _selectedDate,
      firstDate: _dateOnly(now),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: l10n.exploreDatePickerHelp,
      cancelText: l10n.cancel,
      confirmText: l10n.exploreDatePickerConfirm,
    );
    if (picked == null) return;
    setState(() => _selectedDate = _dateOnly(picked));
    await _refreshOccupiedSlots();
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(widget.planningDate);
    final now = DateTime.now();
    _selectedSlotIndex =
        myDayQuickAddFirstOfferedSlotIndex(selectedDay: _selectedDate, now: now) ??
            2;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshOccupiedSlots());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = _dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));
    final isTodaySelected = _isSameDay(_selectedDate, today);
    final isTomorrowSelected = _isSameDay(_selectedDate, tomorrow);
    final isCustomSelected = !isTodaySelected && !isTomorrowSelected;
    final allTaken = !_loadingSlots && !_hasBookableSlot();

    Widget dayChip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFEBF3EE) : const Color(0xFFF5F0E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? const Color(0xFF2A6049) : const Color(0xFFE8E2D8),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? const Color(0xFF2A6049) : const Color(0xFF8C8780),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget timeChip({
      required String label,
      required int slotIndex,
    }) {
      final key = _slotKeys[slotIndex];
      final taken = _occupiedSlots.contains(key);
      final selected = _selectedSlotIndex == slotIndex && !taken;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: taken || _loadingSlots
              ? null
              : () => setState(() => _selectedSlotIndex = slotIndex),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: taken
                  ? const Color(0xFFF0EEEB)
                  : (selected
                      ? const Color(0xFFEBF3EE)
                      : const Color(0xFFF5F0E8)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: taken
                    ? const Color(0xFFE0DDD8)
                    : (selected
                        ? const Color(0xFF2A6049)
                        : const Color(0xFFE8E2D8)),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: taken
                            ? const Color(0xFFB0ABA5)
                            : (selected
                                ? const Color(0xFF2A6049)
                                : const Color(0xFF8C8780)),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (taken) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check_rounded,
                        size: 16, color: Color(0xFF2A6049)),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E2D8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.myDayQuickAddActivity,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1C18),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.place.name,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8C8780),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.exploreAddToMyDayDayLabel,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8C8780),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              dayChip(
                label: l10n.timeLabelToday,
                selected: isTodaySelected,
                onTap: () async {
                  setState(() => _selectedDate = today);
                  await _refreshOccupiedSlots();
                },
              ),
              const SizedBox(width: 8),
              dayChip(
                label: l10n.timeLabelTomorrow,
                selected: isTomorrowSelected,
                onTap: () async {
                  setState(() => _selectedDate = tomorrow);
                  await _refreshOccupiedSlots();
                },
              ),
              const SizedBox(width: 8),
              dayChip(
                label: isCustomSelected
                    ? _formatDateShort(_selectedDate)
                    : l10n.exploreAddToMyDayPickDate,
                selected: isCustomSelected,
                onTap: _pickCustomDate,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.exploreAddToMyDaySelectedDate(_formatDateLong(_selectedDate)),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF8C8780),
            ),
          ),
          const SizedBox(height: 14),
          if (_loadingSlots)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF2A6049),
                  ),
                ),
              ),
            )
          else if (allTaken)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  l10n.exploreAlreadyInDayPlan,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1C18),
                  ),
                ),
              ),
            )
          else ...[
            Text(
              l10n.exploreAddToMyDayTimeLabel,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8C8780),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: () {
                final chips = <Widget>[];
                for (var j = 0; j < 3; j++) {
                  if (!myDayQuickAddSlotOfferedForDay(
                    slotIndex: j,
                    selectedDay: _selectedDate,
                    now: now,
                  )) {
                    continue;
                  }
                  if (chips.isNotEmpty) {
                    chips.add(const SizedBox(width: 8));
                  }
                  final label = j == 0
                      ? l10n.timeLabelMorning
                      : (j == 1
                          ? l10n.timeLabelAfternoon
                          : l10n.timeLabelEvening);
                  chips.add(
                    Expanded(
                      child: timeChip(label: label, slotIndex: j),
                    ),
                  );
                }
                return chips;
              }(),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_loadingSlots ||
                      allTaken ||
                      !_selectedSlotIsBookable())
                  ? null
                  : () async {
                      final out = widget.onTimeSelected(_selectedStartTime);
                      if (out is Future) await out;
                      if (context.mounted) Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A6049),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.myDayQuickAddActivity,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
