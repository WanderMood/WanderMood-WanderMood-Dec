import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../places/models/place.dart';
import '../../../../core/extensions/string_extensions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

class EnhancedMoodCarousel extends ConsumerStatefulWidget {
  final List<Place> places;
  final String mood;
  final Function(BuildContext, {String? contextualGreeting})? onChatOpen;
  final VoidCallback? onPlaceSelected;

  const EnhancedMoodCarousel({
    super.key,
    required this.places,
    required this.mood,
    this.onChatOpen,
    this.onPlaceSelected,
  });

  @override
  ConsumerState<EnhancedMoodCarousel> createState() => _EnhancedMoodCarouselState();
}

class _EnhancedMoodCarouselState extends ConsumerState<EnhancedMoodCarousel>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final Set<String> _savedPlaces = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.places.isEmpty) {
      return _buildEmptyState();
    }

    // Take top 8 places instead of 5 for more variety
    final displayPlaces = widget.places.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced header with stats
        _buildHeader(displayPlaces.length),
        const SizedBox(height: 16),
        
        // Scrollable cards
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: displayPlaces.length,
            itemBuilder: (context, index) {
              final place = displayPlaces[index];
              final matchScore = _calculateMatchScore(place, index);
              final isTopPick = index == 0;
              return _buildEnhancedCard(context, place, index, matchScore, isTopPick);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.pink.shade400],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.shade200.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  '$count perfect matches',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Shuffle button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // TODO: Shuffle/refresh recommendations
                showWanderMoodToast(
                  context,
                  message: 'Refreshing recommendations...',
                  duration: const Duration(seconds: 1),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.refresh, size: 20, color: Color(0xFF2A6049)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCard(
    BuildContext context,
    Place place,
    int index,
    int matchScore,
    bool isTopPick,
  ) {
    final gradientColors = _getGradientForIndex(index);
    final isSaved = _savedPlaces.contains(place.id);

    return Dismissible(
      key: Key(place.id),
      direction: DismissDirection.horizontal,
      background: _buildSwipeBackground(true),
      secondaryBackground: _buildSwipeBackground(false),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          // Swiped right - Save
          _savePlaceForLater(place);
        } else {
          // Swiped left - Not interested
          _dismissPlace(place);
        }
      },
      child: Container(
        width: 320,
        margin: const EdgeInsets.only(right: 16),
        child: Stack(
          children: [
            // Main card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    blurRadius: 10,
                    spreadRadius: -5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image section with badges
                    Expanded(
                      flex: 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildImage(place, gradientColors),
                          _buildGradientOverlay(),
                          _buildTopBadges(place, matchScore, isTopPick, isSaved),
                          _buildPlaceInfo(place),
                        ],
                      ),
                    ),
                    
                    // Actions section
                    _buildActionsSection(context, place),
                  ],
                ),
              ),
            ),
            
            // "Top Pick" ribbon
            if (isTopPick) _buildTopPickRibbon(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(Place place, List<Color> gradientColors) {
    return place.photos.isNotEmpty
        ? Image.network(
            place.photos.first,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholder(gradientColors),
          )
        : _buildPlaceholder(gradientColors);
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildTopBadges(Place place, int matchScore, bool isTopPick, bool isSaved) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Match score badge with pulsing animation
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.1);
              return Transform.scale(
                scale: matchScore >= 90 ? scale : 1.0,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: matchScore >= 90
                      ? [Colors.green.shade400, Colors.teal.shade400]
                      : [Colors.blue.shade400, Colors.cyan.shade400],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (matchScore >= 90 ? Colors.green : Colors.blue)
                        .withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    matchScore >= 90 ? Icons.star : Icons.favorite,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$matchScore% match',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // Saved indicator
          if (isSaved)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.bookmark,
                size: 16,
                color: Color(0xFF2A6049),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceInfo(Place place) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Place name
          Text(
            place.name,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          
          // Tags row
          Wrap(
            spacing: 8,
            children: [
              if (place.rating != null)
                _buildSmallBadge(
                  '⭐ ${place.rating!.toStringAsFixed(1)}',
                  Colors.amber.shade700,
                ),
              if (place.types.isNotEmpty)
                _buildSmallBadge(
                  place.types.first.capitalize(),
                  Colors.white.withOpacity(0.9),
                  textColor: const Color(0xFF1A202C),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color color, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor ?? Colors.white,
        ),
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, Place place) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Primary action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Tell me more',
                  icon: Icons.chat_bubble_outline,
                  color: Colors.purple.shade400,
                  onTap: () => _askMoodyAboutPlace(context, place),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Add to day',
                  icon: Icons.add_circle_outline,
                  color: const Color(0xFF2A6049),
                  onTap: () => _addToSchedule(context, place),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Secondary actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildIconButton(
                icon: Icons.directions,
                label: 'Directions',
                onTap: () => _openDirections(place),
              ),
              _buildIconButton(
                icon: Icons.share,
                label: 'Share',
                onTap: () => _sharePlace(place),
              ),
              _buildIconButton(
                icon: Icons.info_outline,
                label: 'Details',
                onTap: () => _showPlaceDetails(context, place),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF1A202C)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPickRibbon() {
    return Positioned(
      top: -5,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.red.shade400],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'TOP PICK',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(bool isRight) {
    return Container(
      color: isRight ? Colors.green.shade400 : Colors.red.shade400,
      alignment: isRight ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isRight ? Icons.bookmark_add : Icons.cancel,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            isRight ? 'Save for later' : 'Not interested',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '✨',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              'No recommendations yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check back soon for personalized suggestions!',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          size: 80,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  // Helper methods
  List<Color> _getGradientForIndex(int index) {
    final gradients = [
      [const Color(0xFFFFE5B4), const Color(0xFFFFD6A5)], // Warm peach
      [const Color(0xFFB4E5FF), const Color(0xFFA5D8FF)], // Sky blue
      [const Color(0xFFFFB4D5), const Color(0xFFFFA5C8)], // Soft pink
      [const Color(0xFFB4FFD5), const Color(0xFFA5FFBB)], // Mint green
      [const Color(0xFFD4B4FF), const Color(0xFFC8A5FF)], // Lavender
      [const Color(0xFFFFE5D4), const Color(0xFFFFD4B4)], // Coral
      [const Color(0xFFD4FFE5), const Color(0xFFB4FFD4)], // Aqua
      [const Color(0xFFFFD4E5), const Color(0xFFFFC4D4)], // Rose
    ];
    return gradients[index % gradients.length];
  }

  int _calculateMatchScore(Place place, int index) {
    // Smart scoring algorithm
    int score = 70; // Base score
    
    // Boost for highly rated places
    if (place.rating != null) {
      score += ((place.rating! - 3.0) * 10).round().clamp(0, 20);
    }
    
    // Top picks get highest scores
    if (index == 0) score = math.min(score + 15, 98);
    if (index == 1) score = math.min(score + 10, 95);
    if (index == 2) score = math.min(score + 5, 92);
    
    // Random variation
    score += math.Random().nextInt(5) - 2;
    
    return score.clamp(70, 99);
  }

  void _askMoodyAboutPlace(BuildContext context, Place place) {
    final message = 'Tell me more about ${place.name}. Why would I love it based on my ${widget.mood} mood?';
    widget.onChatOpen?.call(context, contextualGreeting: message);
  }

  void _addToSchedule(BuildContext context, Place place) {
    // TODO: Implement actual schedule addition
    showWanderMoodToast(
      context,
      message: '${place.name} added to your day! 🎉',
      backgroundColor: const Color(0xFF2A6049),
    );
  }

  void _savePlaceForLater(Place place) {
    setState(() {
      _savedPlaces.add(place.id);
    });
    showWanderMoodToast(
      context,
      message: '${place.name} saved for later! 📌',
      backgroundColor: const Color(0xFF2A6049),
    );
  }

  void _dismissPlace(Place place) {
    showWanderMoodToast(
      context,
      message: 'Okay, hiding ${place.name}',
      backgroundColor: Colors.grey.shade700,
    );
  }

  void _openDirections(Place place) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${place.location.lat},${place.location.lng}',
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _sharePlace(Place place) async {
    try {
      final message = 'Check out ${place.name} on WanderMood! 🧳✨\n\n${place.address ?? ''}';
      await Share.share(message);
    } catch (e) {
      showWanderMoodToast(
        context,
        message: 'Failed to share: $e',
        isError: true,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _showPlaceDetails(BuildContext context, Place place) {
    // Navigate to place details screen
    context.push('/place/${place.id}');
  }
}

