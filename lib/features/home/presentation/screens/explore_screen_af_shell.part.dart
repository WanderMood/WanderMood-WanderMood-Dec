part of 'explore_screen.dart';

/// Advanced filters modal shell.
extension _ExploreAfShell on _ExploreScreenState {
  Widget _buildAdvancedFilterModal() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        final l10n = AppLocalizations.of(context)!;
        // Create updateFilter function that updates both states
        void updateFilter(VoidCallback updateCallback) {
          updateCallback(); // Execute the state change once
          // ignore: invalid_use_of_protected_member — extension on State; see file header.
          setState(() {}); // Trigger main widget rebuild
          setModalState(() {}); // Trigger modal rebuild
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: _afWmWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _afWmParchment, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildAdvancedFilterModalHeader(context, l10n, setModalState),

                const Divider(height: 1, thickness: 1, color: _afWmParchment),

                // Filter Content - New Expandable Structure
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAdvancedFiltersMoodyHintCard(l10n),

                        // Dietary Preferences
                        _buildExpandableSection(
                          '🍽️',
                          l10n.exploreSectionDietaryPreferences,
                          _dietaryExpanded,
                          () => updateFilter(() {
                            _dietaryExpanded = !_dietaryExpanded;
                          }),
                          _buildDietaryFilters(updateFilter),
                          activeCount: _dietaryActiveCount,
                        ),

                        // Accessibility & Inclusion
                        _buildExpandableSection(
                          '♿',
                          l10n.exploreSectionAccessibilityInclusion,
                          _accessibilityExpanded,
                          () => updateFilter(() {
                            _accessibilityExpanded = !_accessibilityExpanded;
                          }),
                          _buildAccessibilityFilters(updateFilter),
                          activeCount: _accessibilityActiveCount,
                        ),

                        // Photo & Aesthetic
                        _buildExpandableSection(
                          '📸',
                          l10n.exploreSectionPhotoAesthetic,
                          _photoExpanded,
                          () => updateFilter(() {
                            _photoExpanded = !_photoExpanded;
                          }),
                          _buildPhotoFilters(updateFilter),
                          activeCount: _photoActiveCount,
                        ),

                        // Quick Suggestions
                        _buildExpandableSection(
                          '⚡',
                          l10n.exploreSectionQuickSuggestions,
                          _advancedSuggestionsExpanded,
                          () => updateFilter(() {
                            _advancedSuggestionsExpanded = !_advancedSuggestionsExpanded;
                          }),
                          _buildAdvancedSuggestionFilters(updateFilter),
                          activeCount: _quickSuggestionsActiveCount,
                        ),

                        // Comfort & Convenience
                        _buildExpandableSection(
                          '🛋️',
                          l10n.exploreSectionComfortConvenience,
                          _logisticsExpanded,
                          () => updateFilter(() {
                            _logisticsExpanded = !_logisticsExpanded;
                          }),
                          _buildLogisticsFilters(updateFilter),
                          activeCount: _comfortActiveCount,
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),

                _buildAdvancedFilterModalApplyBar(context, l10n),
              ],
            ),
          ),
        );
      },
    );
  }
}
