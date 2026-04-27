part of 'explore_screen.dart';

/// Header, Moody hint card, and apply bar for the advanced filters modal.
extension _ExploreAfShellChrome on _ExploreScreenState {
  Widget _buildAdvancedFilterModalHeader(
    BuildContext context,
    AppLocalizations l10n,
    StateSetter setModalState,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 8, 14),
      decoration: const BoxDecoration(
        color: _afWmWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _afWmForest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, right: 4),
                  child: Text(
                    l10n.exploreAdvancedFiltersTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _afWmCharcoal,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          if (_activeFiltersCount > 0) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 46, right: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      l10n.exploreFiltersActiveCount(
                        _activeFiltersCount,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _afWmForest,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _clearAllFilters();
                      setModalState(() {});
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: _afWmStone,
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const RoundedRectangleBorder(
                        side: BorderSide.none,
                      ),
                    ),
                    child: Text(
                      l10n.exploreClearAll,
                      style: GoogleFonts.poppins(
                        color: _afWmStone,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedFiltersMoodyHintCard(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F7F4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD0E4DA), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _afWmForestTint,
                shape: BoxShape.circle,
                border: Border.all(color: _afWmParchment, width: 1),
              ),
              child: Center(
                child: MoodyCharacter(
                  size: 30,
                  mood: _activeFiltersCount > 0 ? 'happy' : 'default',
                  glowOpacityScale: 0.35,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activeFiltersCount > 0
                        ? l10n.exploreMoodyHintFiltersActive(_activeFiltersCount)
                        : l10n.exploreMoodyHintFiltersIntro,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF2A6049),
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFilterModalApplyBar(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      decoration: BoxDecoration(
        color: _afWmWhite,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(color: _afWmParchment.withValues(alpha: 0.85)),
        ),
      ),
      child: Column(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () async {
                final connected = await ref
                    .read(connectivityServiceProvider)
                    .isConnected;
                if (!context.mounted) return;
                if (!connected) {
                  showOfflineSnackBar(context);
                  return;
                }
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                final backendFilters = _buildMoodyBackendFilters();
                final namedFilters = _buildMoodyNamedFilters();
                ref
                    .read(moodyExploreBackendFiltersProvider.notifier)
                    .state = backendFilters;
                ref
                    .read(
                      moodyExploreBackendNamedFiltersProvider.notifier,
                    )
                    .state = namedFilters;
                ref.invalidate(moodyExploreAutoProvider);
                await _loadAllSections(resetBulkSeed: true);
                // ignore: invalid_use_of_protected_member — extension on State.
                setState(() {
                  _exploreVisiblePlaceCount = _kExplorePageSize;
                  _updateActiveFiltersCount();
                  debugPrint(
                      '💾 Saved filters - Active count: $_activeFiltersCount');
                  debugPrint(
                      '🔍 Filter state - Vegan: $_vegan, Vegetarian: $_vegetarian, Wheelchair: $_wheelchairAccessible');
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _afWmForest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _activeFiltersCount > 0
                        ? l10n.exploreSaveFiltersWithCount(_activeFiltersCount)
                        : l10n.exploreSaveFilters,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
