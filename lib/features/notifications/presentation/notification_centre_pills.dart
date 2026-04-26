import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Moody-style filter chip (matches Explore / conversational header patterns).
class NotificationCentrePill extends StatelessWidget {
  const NotificationCentrePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _sunset = Color(0xFFE8784A);
  static const _cream = Color(0xFFF5F0E8);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(999),
        splashColor: _sunset.withValues(alpha: 0.12),
        highlightColor: _sunset.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _sunset.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? _sunset.withValues(alpha: 0.55) : _cream.withValues(alpha: 0.08),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _sunset.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? _sunset : _cream.withValues(alpha: 0.58),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
