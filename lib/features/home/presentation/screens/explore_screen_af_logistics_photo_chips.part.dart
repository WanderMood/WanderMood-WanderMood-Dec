part of 'explore_screen.dart';

/// Price/distance + photo filters + v2 filter pills.
extension _ExploreAfLogisticsPhotoChips on _ExploreScreenState {
  String _getPriceLevelText(AppLocalizations l10n, int level) {
    switch (level) {
      case 1:
        return l10n.explorePriceLevelBudget;
      case 2:
        return l10n.explorePriceLevelModerate;
      case 3:
        return l10n.explorePriceLevelExpensive;
      case 4:
        return l10n.explorePriceLevelLuxury;
      default:
        return l10n.explorePriceLevelBudget;
    }
  }
  // Comfort & Convenience filters
  Widget _buildLogisticsFilters(Function(VoidCallback) updateFilter) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.exploreFilterPriceRange,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _afWmCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 100,
          divisions: 20,
          labels: RangeLabels(
            '€${_priceRange.start.round()}',
            '€${_priceRange.end.round()}',
          ),
          onChanged: (values) {
            updateFilter(() {
              _priceRange = values;
              _updateActiveFiltersCount();
            });
          },
          activeColor: _afWmForest,
          inactiveColor: _afWmForest.withOpacity(0.2),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.exploreFilterMaxDistance,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _afWmCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _maxDistance,
          min: 0,
          max: 50,
          divisions: 50,
          label: '${_maxDistance.round()} km',
          onChanged: (value) {
            updateFilter(() {
              _maxDistance = value;
              _updateActiveFiltersCount();
            });
          },
          activeColor: _afWmForest,
          inactiveColor: _afWmForest.withOpacity(0.2),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.exploreFilterAdditionalOptions,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _afWmCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip('🚗', l10n.exploreFilterParking, _parkingAvailable, (value) {
              updateFilter(() { _parkingAvailable = value; _updateActiveFiltersCount(); });
            }),
            _buildFilterChip('📶', l10n.exploreFilterWifi, _wifiAvailable, (value) {
              updateFilter(() { _wifiAvailable = value; _updateActiveFiltersCount(); });
            }),
          ],
        ),
      ],
    );
  }

  // Photo Options filters
  Widget _buildPhotoFilters(Function(VoidCallback) updateFilter) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip('📸', l10n.exploreFilterInstagrammable, _instagrammable, (value) {
          updateFilter(() { _instagrammable = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🎨', l10n.exploreFilterArtisticDesign, _artisticDesign, (value) {
          updateFilter(() { _artisticDesign = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🧘‍♀️', l10n.exploreFilterAestheticSpaces, _aestheticSpaces, (value) {
          updateFilter(() { _aestheticSpaces = value; _updateActiveFiltersCount(); });
        }),
        _buildFilterChip('🌆', l10n.exploreFilterScenicViews, _scenicViews, (value) {
          updateFilter(() { _scenicViews = value; _updateActiveFiltersCount(); });
        }),
      ],
    );
  }

  /// v2 filter pills (SCREEN 7): unselected cream + parchment + charcoal; selected forestTint + forest + forest text.
  Widget _buildFilterChip(
      String emoji, String label, bool isSelected, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!isSelected);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _afWmForestTint : _afWmCream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _afWmForest : _afWmParchment,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? _afWmForest : _afWmCharcoal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build selectable chips (for single-select options)
  Widget _buildSelectableChip(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEBF3EE) : const Color(0xFFF5F0E8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF2A6049) : const Color(0xFFE8E2D8),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color:
                isSelected ? const Color(0xFF2A6049) : const Color(0xFF8C8780),
          ),
        ),
      ),
    );
  }
}
