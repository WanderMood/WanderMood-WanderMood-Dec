import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ConversationalExploreHeader extends StatefulWidget {
  final Function(String) onIntentSelected;
  final Function(String) onSearchChanged;
  final String selectedIntent;
  final VoidCallback? onFilterTap;
  final int activeFiltersCount;
  final int activitiesCount;
  final bool isGridView;
  final bool isMapView;
  final Function(bool, bool) onViewToggle;

  const ConversationalExploreHeader({
    Key? key,
    required this.onIntentSelected,
    required this.onSearchChanged,
    required this.selectedIntent,
    this.onFilterTap,
    this.activeFiltersCount = 0,
    this.activitiesCount = 0,
    this.isGridView = false,
    this.isMapView = false,
    required this.onViewToggle,
  }) : super(key: key);

  @override
  State<ConversationalExploreHeader> createState() => _ConversationalExploreHeaderState();
}

class _ConversationalExploreHeaderState extends State<ConversationalExploreHeader> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  
  // Category filters
  final List<Map<String, dynamic>> _categoryFilters = [
    {
      'id': 'all',
      'label': 'All',
      'emoji': '✨',
      'color': const Color(0xFF12B347), // Green
    },
    {
      'id': 'food',
      'label': 'Food',
      'emoji': '🍽️',
      'color': const Color(0xFFE55B4C), // Red
    },
    {
      'id': 'culture',
      'label': 'Culture',
      'emoji': '🎭',
      'color': const Color(0xFF6B5B95), // Purple
    },
    {
      'id': 'outdoor',
      'label': 'Outdoor',
      'emoji': '🌳',
      'color': const Color(0xFF52C41A), // Green
    },
    {
      'id': 'shopping',
      'label': 'Shopping',
      'emoji': '🛍️',
      'color': const Color(0xFF4A90E2), // Blue
    },
    {
      'id': 'nightlife',
      'label': 'Nightlife',
      'emoji': '🌙',
      'color': const Color(0xFF6C757D), // Dark gray
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar at the top
          _buildSearchBar(),
          const SizedBox(height: 16),
          
          // Category filter bubbles
          _buildCategoryFilters(),
          
          // Activities count and view toggle
          const SizedBox(height: 20),
          _buildActivitiesHeader(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
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
                hintText: "Search activities, restaurants, museums...",
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
                    color: const Color(0xFF12B347).withOpacity(0.5),
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
          // Filter icon with badge
          if (widget.onFilterTap != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: widget.onFilterTap,
                      icon: Icon(
                        Icons.tune,
                        color: Colors.grey[700],
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
                          color: const Color(0xFF12B347),
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

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _categoryFilters.length,
        itemBuilder: (context, index) {
          final category = _categoryFilters[index];
          final isSelected = _selectedCategory == category['id'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category['id'];
                });
                widget.onIntentSelected(category['id']);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? category['color'] 
                    : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected 
                      ? category['color'] 
                      : Colors.grey[200]!,
                    width: 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: category['color'].withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category['emoji'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category['label'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(
              duration: 400.ms,
              delay: Duration(milliseconds: 50 * index),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildActivitiesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
                  // Activities count label
          Text(
            widget.activitiesCount > 0 
              ? '${widget.activitiesCount} activities found'
              : 'Searching activities...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        // View toggle buttons
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // List view button
              InkWell(
                onTap: () {
                  widget.onViewToggle(false, false);
                },
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (!widget.isGridView && !widget.isMapView) ? const Color(0xFF12B347) : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                  ),
                  child: Icon(
                    Icons.view_list,
                    size: 20,
                    color: (!widget.isGridView && !widget.isMapView) ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
              // Grid view button
              InkWell(
                onTap: () {
                  widget.onViewToggle(true, false);
                },
                borderRadius: BorderRadius.zero,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.isGridView ? const Color(0xFF12B347) : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.grid_view,
                    size: 20,
                    color: widget.isGridView ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
              // Map view button
              InkWell(
                onTap: () {
                  widget.onViewToggle(false, true);
                },
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.isMapView ? const Color(0xFF12B347) : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                  ),
                  child: Icon(
                    Icons.map,
                    size: 20,
                    color: widget.isMapView ? Colors.white : Colors.grey[600],
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