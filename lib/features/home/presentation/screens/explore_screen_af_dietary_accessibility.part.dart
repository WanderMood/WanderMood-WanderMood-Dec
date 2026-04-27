part of 'explore_screen.dart';

/// Dietary + accessibility filter rows.
extension _ExploreAfDietaryAccessibility on _ExploreScreenState {
  Widget _buildDietaryFilters(Function(VoidCallback) updateFilter) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip('🌱', l10n.exploreFilterVegan, _vegan, (value) {
          updateFilter(() { _vegan = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🥬', l10n.exploreFilterVegetarian, _vegetarian, (value) {
          updateFilter(() { _vegetarian = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🥗', l10n.exploreFilterHalal, _halal, (value) {
          updateFilter(() { _halal = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🌾', l10n.exploreFilterGlutenFree, _glutenFree, (value) {
          updateFilter(() { _glutenFree = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🐟', l10n.exploreFilterPescatarian, _pescatarian, (value) {
          updateFilter(() { _pescatarian = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('❌', l10n.exploreFilterNoAlcohol, _noAlcohol, (value) {
          updateFilter(() { _noAlcohol = value; _updateActiveFiltersCount(); });
        }),
      ],
    );
  }

  // Accessibility & Inclusion filters
  Widget _buildAccessibilityFilters(Function(VoidCallback) updateFilter) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip('♿', l10n.exploreFilterWheelchairAccessible, _wheelchairAccessible, (value) {
          updateFilter(() { _wheelchairAccessible = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🏳️‍🌈', l10n.exploreFilterLgbtqFriendly, _lgbtqFriendly, (value) {
          updateFilter(() { _lgbtqFriendly = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🧠', l10n.exploreFilterSensoryFriendly, _sensoryFriendly, (value) {
          updateFilter(() { _sensoryFriendly = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('👨‍👩‍👧', l10n.exploreFilterFamilyFriendly, _familyFriendly, (value) {
          updateFilter(() { _familyFriendly = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🧓', l10n.exploreFilterSeniorFriendly, _seniorFriendly, (value) {
          updateFilter(() { _seniorFriendly = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🧑‍🍼', l10n.exploreFilterBabyFriendly, _babyFriendly, (value) {
          updateFilter(() { _babyFriendly = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('✊🏿', l10n.exploreFilterBlackOwned, _blackOwned, (value) {
          updateFilter(() { _blackOwned = value; _updateActiveFiltersCount(); });
        }),
      ],
    );
  }
}
