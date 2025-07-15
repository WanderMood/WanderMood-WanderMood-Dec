import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ConversationalExploreHeader extends StatefulWidget {
  final Function(String) onIntentSelected;
  final Function(String) onSearchChanged;
  final String selectedIntent;
  final VoidCallback? onFilterTap;
  final int activeFiltersCount;

  const ConversationalExploreHeader({
    Key? key,
    required this.onIntentSelected,
    required this.onSearchChanged,
    required this.selectedIntent,
    this.onFilterTap,
    this.activeFiltersCount = 0,
  }) : super(key: key);

  @override
  State<ConversationalExploreHeader> createState() => _ConversationalExploreHeaderState();
}

class _ConversationalExploreHeaderState extends State<ConversationalExploreHeader> {
  final TextEditingController _searchController = TextEditingController();
  
  // Dynamic intent options that can change based on context
  final List<Map<String, dynamic>> _intentOptions = [
    {
      'id': 'chill',
      'label': 'Chill vibes',
      'emoji': '😌',
      'color': const Color(0xFF4A90E2), // Darker blue like Relaxed
    },
    {
      'id': 'adventure',
      'label': 'Adventure time',
      'emoji': '🗺️',
      'color': const Color(0xFFE17B47), // Orange like Adventure
    },
    {
      'id': 'foodie',
      'label': 'Foodie mode',
      'emoji': '🍽️',
      'color': const Color(0xFFE55B4C), // Red like Foody
    },
    {
      'id': 'culture',
      'label': 'Culture dive',
      'emoji': '🎨',
      'color': const Color(0xFF6B5B95), // Purple like Family fun
    },
    {
      'id': 'social',
      'label': 'Social hangout',
      'emoji': '👥',
      'color': const Color(0xFF5DADE2), // Blue like Freactives
    },
    {
      'id': 'nature',
      'label': 'Nature escape',
      'emoji': '🌳',
      'color': const Color(0xFF52C41A), // Green like Mindful
    },
    {
      'id': 'surprise',
      'label': 'Surprise me',
      'emoji': '🎲',
      'color': const Color(0xFFE67E22), // Orange like Surprise
    },
    {
      'id': 'now',
      'label': 'Perfect for now',
      'emoji': '⏰',
      'color': const Color(0xFFF39C12), // Yellow like Creative
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFFDF5),
            const Color(0xFFFFFDF5).withOpacity(0.9),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact conversational prompt (centered)
          Center(child: _buildCompactPrompt()),
          const SizedBox(height: 8),
          
          // Intent bubbles carousel
          _buildCompactIntentBubbles(),
          const SizedBox(height: 8),
          
          // Enhanced search bar (reduced height)
          _buildCompactSearchBar(),
        ],
      ),
    );
  }

  Widget _buildCompactPrompt() {
    return Text(
      "What's your vibe? ✨",
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF2C3E50),
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.3, end: 0);
  }

  Widget _buildCompactIntentBubbles() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _intentOptions.length,
        itemBuilder: (context, index) {
          final intent = _intentOptions[index];
          final isSelected = widget.selectedIntent == intent['id'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => widget.onIntentSelected(intent['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? intent['color'] 
                    : intent['color'].withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                      ? intent['color'] 
                      : intent['color'].withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: intent['color'].withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ] : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      intent['emoji'],
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      intent['label'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : intent['color'],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(
              duration: 400.ms,
              delay: Duration(milliseconds: 50 * index),
            ).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0)),
          );
        },
      ),
    );
  }

  Widget _buildCompactSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                fontSize: 14,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: "Search for a place or filter by name...",
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.psychology_outlined,
                  color: const Color(0xFF12B347),
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[400], size: 18),
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearchChanged('');
                      },
                    )
                  : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
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
                  IconButton(
                    onPressed: widget.onFilterTap,
                    icon: Icon(
                      Icons.tune,
                      color: const Color(0xFF12B347),
                      size: 22,
                    ),
                  ),
                  if (widget.activeFiltersCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12B347),
                          borderRadius: BorderRadius.circular(10),
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
    ).animate().fadeIn(duration: 600.ms, delay: 300.ms);
  }
} 