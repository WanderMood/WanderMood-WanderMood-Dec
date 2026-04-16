import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/l10n/app_localizations.dart';

// WanderMood v2 Explore tokens (SCREEN 6)
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);

class ConversationalExploreHeader extends StatefulWidget {
  final Function(String) onSearchChanged;
  final VoidCallback? onFilterTap;
  final int activeFiltersCount;
  final bool isGridView;
  final bool isMapView;
  final Function(bool, bool) onViewToggle;
  /// Quick category chips shown under the search bar (Explore feed filter).
  final List<String>? categoryKeys;
  final String? selectedCategory;
  final String Function(String key)? categoryLabel;
  final String Function(String key)? categoryEmoji;
  final ValueChanged<String>? onCategorySelected;

  const ConversationalExploreHeader({
    Key? key,
    required this.onSearchChanged,
    this.onFilterTap,
    this.activeFiltersCount = 0,
    this.isGridView = false,
    this.isMapView = false,
    required this.onViewToggle,
    this.categoryKeys,
    this.selectedCategory,
    this.categoryLabel,
    this.categoryEmoji,
    this.onCategorySelected,
  }) : super(key: key);

  @override
  State<ConversationalExploreHeader> createState() =>
      _ConversationalExploreHeaderState();
}

class _ConversationalExploreHeaderState extends State<ConversationalExploreHeader> {
  final TextEditingController _searchController = TextEditingController();

  bool get _hasCategoryRow =>
      widget.categoryKeys != null &&
      widget.categoryKeys!.isNotEmpty &&
      widget.selectedCategory != null &&
      widget.categoryLabel != null &&
      widget.onCategorySelected != null;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 10),
          if (_hasCategoryRow) ...[
            _buildCategoryChipsRow(),
            const SizedBox(height: 8),
          ],
          _buildActivitiesHeader(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: widget.onSearchChanged,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: l10n.exploreSearchHint,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.search,
                    color: Colors.grey[500],
                    size: 22,
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _searchController.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(
                    color: _wmForest.withValues(alpha: 0.45),
                    width: 1,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
          ),
          if (widget.onFilterTap != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: _wmForestTint,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: _wmParchment, width: 0.5),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: widget.onFilterTap,
                      icon: const Icon(
                        Icons.tune,
                        color: _wmForest,
                        size: 20,
                      ),
                    ),
                  ),
                  if (widget.activeFiltersCount > 0)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: _wmForest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.activeFiltersCount.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.0, 1.0),
        );
  }

  Widget _buildCategoryChipsRow() {
    final keys = widget.categoryKeys!;
    final selected = widget.selectedCategory!;
    final labelFn = widget.categoryLabel!;
    final emojiFn = widget.categoryEmoji ?? (_) => '📍';

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: keys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final key = keys[i];
          final isSelected = key == selected;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onCategorySelected!(key);
              },
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _wmForest : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? _wmForest : _wmParchment,
                    width: isSelected ? 1.25 : 1,
                  ),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emojiFn(key), style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      labelFn(key),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF4A4640),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivitiesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: _wmParchment,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFD8D2C8),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onViewToggle(false, false);
                },
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (!widget.isGridView && !widget.isMapView) ? _wmForest : _wmParchment,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                  ),
                  child: Icon(
                    Icons.view_list,
                    size: 20,
                    color: (!widget.isGridView && !widget.isMapView) ? Colors.white : const Color(0xFF8C8780),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onViewToggle(true, false);
                },
                borderRadius: BorderRadius.zero,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.isGridView ? _wmForest : _wmParchment,
                  ),
                  child: Icon(
                    Icons.grid_view,
                    size: 20,
                    color: widget.isGridView ? Colors.white : const Color(0xFF8C8780),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onViewToggle(false, true);
                },
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.isMapView ? _wmForest : _wmParchment,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                  ),
                  child: Icon(
                    Icons.map,
                    size: 20,
                    color: widget.isMapView ? Colors.white : const Color(0xFF8C8780),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
