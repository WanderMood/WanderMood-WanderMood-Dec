part of 'explore_screen.dart';

/// Quick suggestion filter column.
extension _ExploreAfQuickSuggestions on _ExploreScreenState {
  Widget _buildAdvancedSuggestionFilters(Function(VoidCallback) updateFilter) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFilterChip('🏠', l10n.exploreFilterIndoorOnly, _indoorOnly, (value) {
                updateFilter(() {
                  _indoorOnly = value;
                  if (value) _outdoorOnly = false;
                  _updateActiveFiltersCount();
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFilterChip('☀️', l10n.exploreFilterOutdoorOnly, _outdoorOnly, (value) {
                updateFilter(() {
                  _outdoorOnly = value;
                  if (value) _indoorOnly = false;
                  _updateActiveFiltersCount();
                });
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildFilterChip('🌙', l10n.exploreFilterOpenNow, _openNow, (value) {
          updateFilter(() {
            _openNow = value;
            _updateActiveFiltersCount();
          });
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFilterChip('🤫', l10n.exploreFilterQuiet, _crowdQuiet, (value) {
                updateFilter(() {
                  _crowdQuiet = value;
                  if (value) _crowdLively = false;
                  _updateActiveFiltersCount();
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFilterChip('💃', l10n.exploreFilterLively, _crowdLively, (value) {
                updateFilter(() {
                  _crowdLively = value;
                  if (value) _crowdQuiet = false;
                  _updateActiveFiltersCount();
                });
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFilterChip('💕', l10n.exploreFilterRomanticVibe, _romanticVibe, (value) {
                updateFilter(() {
                  _romanticVibe = value;
                  _updateActiveFiltersCount();
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFilterChip('🔀', l10n.exploreFilterSurpriseMe, _surpriseMe, (value) {
                updateFilter(() {
                  _surpriseMe = value;
                  _updateActiveFiltersCount();
                });
              }),
            ),
          ],
        ),
      ],
    );
  }
}
