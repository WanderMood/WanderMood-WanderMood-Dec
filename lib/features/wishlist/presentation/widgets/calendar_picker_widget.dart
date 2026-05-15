import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

const _wmCream = Color(0xFFF5F0E8);
const _wmForest = Color(0xFF2A6049);
const _wmMint = Color(0xFF5DCAA5);
const _wmCharcoal = Color(0xFF1A1714);
const _wmMuted = Color(0x8C1A1714);

/// 14-day multi-select calendar (starts today).
class CalendarPickerWidget extends StatelessWidget {
  const CalendarPickerWidget({
    super.key,
    required this.selectedDates,
    required this.onToggle,
    this.daysAhead = 14,
  });

  final Set<DateTime> selectedDates;
  final ValueChanged<DateTime> onToggle;
  final int daysAhead;

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final today = _dayOnly(DateTime.now());
    final days = List.generate(daysAhead, (i) => today.add(Duration(days: i)));
    final weekdayLabels = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdayLabels
              .map(
                (l) => Text(
                  l,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _wmMuted,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: days.map((d) {
            final selected = selectedDates.any(
              (s) =>
                  s.year == d.year && s.month == d.month && s.day == d.day,
            );
            final isToday = d == today;
            return _DayChip(
              date: d,
              selected: selected,
              isToday: isToday,
              onTap: () => onToggle(d),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayNum = date.day;
    final month = DateFormat('MMM', 'nl').format(date);

    return Material(
      color: selected ? _wmForest : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? _wmForest
                  : isToday
                      ? _wmMint
                      : const Color(0xFFE8E2D8),
              width: isToday && !selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                month,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: selected ? _wmCream.withValues(alpha: 0.85) : _wmMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$dayNum',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: selected ? _wmCream : _wmCharcoal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
