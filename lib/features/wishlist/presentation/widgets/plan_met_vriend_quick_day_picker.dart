import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';

/// Mood Match–styled multi-day picker for the Plan met vriend quick view.
class PlanMetVriendQuickDayPicker extends StatelessWidget {
  const PlanMetVriendQuickDayPicker({
    super.key,
    required this.selectedDayIndices,
    required this.onToggleDayIndex,
    this.horizonDays = 21,
  });

  /// Day offsets from today (0 = today).
  final Set<int> selectedDayIndices;
  final ValueChanged<int> onToggleDayIndex;
  final int horizonDays;

  static DateTime dayFromIndex(int index) {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day + index);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 188,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: horizonDays,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final day = dayFromIndex(i);
          final selected = selectedDayIndices.contains(i);
          final isToday = i == 0;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onToggleDayIndex(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 92,
              decoration: BoxDecoration(
                color: selected ? GroupPlanningUi.forest : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? GroupPlanningUi.forest
                      : isToday
                          ? const Color(0xFF5DCAA5)
                          : GroupPlanningUi.cardBorder,
                  width: isToday && !selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: GroupPlanningUi.forest.withValues(alpha: 0.22),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: GroupPlanningUi.moodMatchShadow(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
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
                          ? Colors.white.withValues(alpha: 0.9)
                          : GroupPlanningUi.stone,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMM', 'nl').format(day),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : GroupPlanningUi.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
