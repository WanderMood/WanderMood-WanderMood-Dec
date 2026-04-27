part of 'explore_screen.dart';

/// Mood pill row for advanced filters.
extension _ExploreAfMoodPills on _ExploreScreenState {
  List<Map<String, dynamic>> _exploreMoodDefinitions(AppLocalizations l10n) {
    return [
      {'id': 'adventure', 'label': l10n.exploreMoodAdventure, 'emoji': '🏔️', 'color': const Color(0xFFFFD700)},
      {'id': 'creative', 'label': l10n.exploreMoodCreative, 'emoji': '😊', 'color': const Color(0xFF87CEEB)},
      {'id': 'relaxed', 'label': l10n.exploreMoodRelaxed, 'emoji': '🍀', 'color': const Color(0xFF98FB98)},
      {'id': 'mindful', 'label': l10n.exploreMoodMindful, 'emoji': '🍀', 'color': const Color(0xFFDDA0DD)},
      {'id': 'romantic', 'label': l10n.exploreMoodRomantic, 'emoji': '❤️', 'color': const Color(0xFFFFB6C1)},
    ];
  }
  Widget _buildMoodButtons() {
    final l10n = AppLocalizations.of(context)!;
    final moods = _exploreMoodDefinitions(l10n);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: moods
            .map((mood) => Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: _buildMoodButton(mood),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMoodButton(Map<String, dynamic> mood) {
    final isSelected = _selectedMood == mood['id'];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // ignore: invalid_use_of_protected_member
          setState(() {
            _selectedMood = isSelected ? null : mood['id'] as String;
            _updateActiveFiltersCount();
          });
        },
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? mood['color'] : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? mood['color'] : Colors.grey[300]!,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: mood['color'].withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: mood['color'].withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mood['emoji'], style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                mood['label'] as String,
                style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodButtonsWithCallback(Function(VoidCallback) updateFilter) {
    final l10n = AppLocalizations.of(context)!;
    final moods = _exploreMoodDefinitions(l10n);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: moods
            .map((mood) => Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: _buildMoodButtonWithCallback(mood, updateFilter),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMoodButtonWithCallback(
      Map<String, dynamic> mood, Function(VoidCallback) updateFilter) {
    final isSelected = _selectedMood == mood['id'];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          updateFilter(() {
            _selectedMood = isSelected ? null : mood['id'] as String;
            _updateActiveFiltersCount();
          });
        },
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? mood['color'] : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? mood['color'] : Colors.grey[300]!,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: mood['color'].withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: mood['color'].withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mood['emoji'], style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                mood['label'] as String,
                style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
