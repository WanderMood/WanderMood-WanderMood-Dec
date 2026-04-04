import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/constants/inclusion_preference_options.dart';

const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmCharcoal = Color(0xFF1E1C18);

/// Multi-select chips for [user_preferences.dietary_restrictions] inclusion keys.
class InclusionDietaryPreferenceField extends StatelessWidget {
  const InclusionDietaryPreferenceField({
    super.key,
    required this.selected,
    required this.onToggleKey,
  });

  final Set<String> selected;
  final void Function(String key) onToggleKey;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in kInclusionPreferenceEntries)
          FilterChip(
            label: Text(
              e.label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected.contains(e.key) ? _wmForest : _wmCharcoal,
              ),
            ),
            selected: selected.contains(e.key),
            selectedColor: _wmForestTint,
            checkmarkColor: _wmForest,
            side: const BorderSide(color: _wmParchment),
            onSelected: (_) => onToggleKey(e.key),
          ),
      ],
    );
  }
}
