import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../places/models/place.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import '../../../places/services/saved_places_service.dart';
import '../../../../core/extensions/string_extensions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/core/services/taste_profile_service.dart';

class SimplifiedMoodCarousel extends ConsumerStatefulWidget {
  final List<Place> places;
  final String mood;
  final Function(BuildContext, {String? contextualGreeting})? onChatOpen;
  final Function(Place, String)? onAddToDay;
  final VoidCallback? onRefresh;

  const SimplifiedMoodCarousel({
    super.key,
    required this.places,
    required this.mood,
    this.onChatOpen,
    this.onAddToDay,
    this.onRefresh,
  });

  @override
  ConsumerState<SimplifiedMoodCarousel> createState() => _SimplifiedMoodCarouselState();
}

class _SimplifiedMoodCarouselState extends ConsumerState<SimplifiedMoodCarousel> {
  final Set<String> _savedPlaces = {};
  final Set<String> _dismissedPlaces = {};

  @override
  void initState() {
    super.initState();
    _loadSavedPlaces();
  }

  @override
  void dispose() {
    // Widget is being disposed - any pending async operations will check mounted
    super.dispose();
  }

  Future<void> _loadSavedPlaces() async {
    final savedPlacesService = ref.read(savedPlacesServiceProvider);
    final savedPlaces = await savedPlacesService.getSavedPlaces();
    
    // Check if widget is still mounted before calling setState
    if (!mounted) return;
    
    setState(() {
      _savedPlaces.addAll(savedPlaces.map((sp) => sp.placeId));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter out dismissed places
    final visiblePlaces = widget.places
        .where((place) => !_dismissedPlaces.contains(place.id))
        .toList();

    if (visiblePlaces.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with count and refresh
        _buildHeader(visiblePlaces.length),
        
        // Swipe hint (shows once)
        _buildSwipeHint(),
        
        const SizedBox(height: 16),
        
        // Scrollable cards
        SizedBox(
          height: 380,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: visiblePlaces.length,
            itemBuilder: (context, index) {
              final place = visiblePlaces[index];
              return _buildCleanCard(context, place, index);
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
          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.pink.shade400],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.shade200.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  '$count recommendations',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Refresh button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onRefresh,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 22,
                  color: Color(0xFF2A6049),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        '💡 Swipe right to save, left to dismiss',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildCleanCard(BuildContext context, Place place, int index) {
    final gradientColors = _getGradientForIndex(index);
    final matchScore = _calculateMatchScore(place, index);
    final isSaved = _savedPlaces.contains(place.id);
    final needsBooking = _needsReservation(place);

    return Dismissible(
      key: Key('${place.id}_$index'), // Unique key with index to avoid conflicts
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        // Handle dismissal BEFORE removing from tree
        if (direction == DismissDirection.startToEnd) {
          _savePlaceForLater(place);
        } else {
          if (!mounted) return false;
          TasteProfileService.recordFromPlace(
            place,
            interactionType: 'skipped',
            moodContext: widget.mood,
            timeSlot:
                TasteProfileService.inferTimeSlotFromHour(MoodyClock.now().hour),
          );
          setState(() {
            _dismissedPlaces.add(place.id);
          });
          if (mounted) {
            _showDismissMessage(place);
          }
        }
        return false; // Don't actually dismiss, just update state
      },
      background: _buildSwipeBackground(true),
      secondaryBackground: _buildSwipeBackground(false),
      child: Container(
        width: 340,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section - LARGER, more prominent
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPlaceImage(place, gradientColors),
                    _buildImageOverlay(),
                    _buildTopBadge(matchScore, isSaved),
                    _buildPlaceInfo(place),
                  ],
                ),
              ),
              
              // Actions section - SIMPLIFIED
              _buildSimpleActions(context, place, needsBooking),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceImage(Place place, List<Color> gradientColors) {
    // Use actual place photos if available, otherwise gradient placeholder
    final imageUrl = place.photos.isNotEmpty ? place.photos.first : null;
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return WmPlacePhotoNetworkImage(
        imageUrl,
        fit: BoxFit.cover,
        progressIndicatorBuilder: (context, url, progress) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.progress,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ),
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) debugPrint('⚠️ Image load error for $imageUrl: $error');
          return _buildGradientPlaceholder(place, gradientColors);
        },
      );
    }
    
    return _buildGradientPlaceholder(place, gradientColors);
  }

  Widget _buildGradientPlaceholder(Place place, List<Color> gradientColors) {
    // Elegant placeholder with place-relevant emoji
    final emoji = _getPlaceEmoji(place.types);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 72),
            ),
            const SizedBox(height: 8),
            Text(
              place.types.isNotEmpty ? place.types.first.capitalize() : 'Place',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOverlay() {
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

  Widget _buildTopBadge(int matchScore, bool isSaved) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Match hearts (emotional, not analytical)
          _buildMatchHearts(matchScore),
          
          const Spacer(),
          
          // Saved indicator
          if (isSaved)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.bookmark,
                size: 18,
                color: Color(0xFF2A6049),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchHearts(int matchScore) {
    int heartCount;
    Color heartColor;
    
    if (matchScore >= 90) {
      heartCount = 3;
      heartColor = Colors.red.shade400;
    } else if (matchScore >= 80) {
      heartCount = 2;
      heartColor = Colors.pink.shade400;
    } else {
      heartCount = 1;
      heartColor = Colors.pink.shade300;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          heartCount,
          (index) => Icon(
            Icons.favorite,
            size: 14,
            color: heartColor,
          ),
        ),
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
          // Place name - BIGGER, more prominent
          Text(
            place.name,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Compact info row
          Row(
            children: [
              if (place.rating > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (place.types.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    place.types.first.capitalize(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A202C),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleActions(BuildContext context, Place place, bool needsBooking) {
    final timeOfDay = MoodyClock.now().hour;
    String timePeriod;
    IconData timeIcon;
    
    if (timeOfDay >= 6 && timeOfDay < 12) {
      timePeriod = 'morning';
      timeIcon = Icons.wb_sunny;
    } else if (timeOfDay >= 12 && timeOfDay < 17) {
      timePeriod = 'afternoon';
      timeIcon = Icons.wb_cloudy;
    } else if (timeOfDay >= 17 && timeOfDay < 22) {
      timePeriod = 'evening';
      timeIcon = Icons.nightlight;
    } else {
      timePeriod = 'tomorrow';
      timeIcon = Icons.wb_twilight;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // PRIMARY action button - BIG and clear
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handlePrimaryAction(context, place, timePeriod, needsBooking),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A6049),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(needsBooking ? Icons.calendar_today : timeIcon, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    needsBooking ? 'Check availability' : 'Add to $timePeriod',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Secondary actions - MINIMAL
          Row(
            children: [
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Ask Moody',
                  onTap: () => _askMoodyAboutPlace(context, place),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryButton(
                  icon: _savedPlaces.contains(place.id) 
                      ? Icons.bookmark 
                      : Icons.bookmark_outline,
                  label: 'Save',
                  onTap: () => _toggleSave(place),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
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
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF1A202C)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A202C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(bool isRight) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isRight ? Colors.green.shade400 : Colors.red.shade400,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: isRight ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isRight ? Icons.bookmark_add_rounded : Icons.cancel_rounded,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            isRight ? 'Saved!' : 'Dismissed',
            style: GoogleFonts.poppins(
              fontSize: 18,
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
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
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
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap refresh to discover more places',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  List<Color> _getGradientForIndex(int index) {
    final gradients = [
      [const Color(0xFFFFE5B4), const Color(0xFFFFD6A5)], // Warm peach
      [const Color(0xFFB4E5FF), const Color(0xFFA5D8FF)], // Sky blue
      [const Color(0xFFFFB4E5), const Color(0xFFFFA5D8)], // Soft pink
      [const Color(0xFFB4FFD5), const Color(0xFFA5FFBB)], // Mint green
      [const Color(0xFFD4B4FF), const Color(0xFFC8A5FF)], // Lavender
      [const Color(0xFFFFE5D4), const Color(0xFFFFD4B4)], // Coral
      [const Color(0xFFD4FFE5), const Color(0xFFB4FFD4)], // Aqua
      [const Color(0xFFFFD4E5), const Color(0xFFFFC4D4)], // Rose
    ];
    return gradients[index % gradients.length];
  }

  int _calculateMatchScore(Place place, int index) {
    int score = 75; // Base score
    
    if (place.rating >= 4.5) score += 15;
    else if (place.rating >= 4.0) score += 10;
    else if (place.rating >= 3.5) score += 5;
    
    if (index == 0) score += 10;
    else if (index == 1) score += 5;
    
    return score.clamp(70, 99);
  }

  bool _needsReservation(Place place) {
    final bookingTypes = [
      'restaurant',
      'spa',
      'museum',
      'theater',
      'concert_hall',
      'art_gallery',
      'tourist_attraction',
    ];
    
    return place.types.any((type) => bookingTypes.contains(type));
  }

  String _getPlaceEmoji(List<String> types) {
    if (types.isEmpty) return '📍';
    
    final emojiMap = {
      'restaurant': '🍽️',
      'cafe': '☕',
      'bar': '🍸',
      'museum': '🏛️',
      'park': '🌳',
      'beach': '🏖️',
      'shopping_mall': '🛍️',
      'gym': '💪',
      'spa': '💆',
      'market': '🏪',
      'viewpoint': '🌄',
      'tourist_attraction': '🗺️',
      'landmark': '🏰',
    };
    
    for (final type in types) {
      if (emojiMap.containsKey(type)) {
        return emojiMap[type]!;
      }
    }
    
    return '✨';
  }

  // Action handlers
  Future<void> _handlePrimaryAction(
    BuildContext context,
    Place place,
    String timePeriod,
    bool needsBooking,
  ) async {
    if (needsBooking) {
      _showReservationSheet(context, place);
    } else {
      _showTimePickerSheet(context, place, timePeriod);
    }
  }

  void _showTimePickerSheet(BuildContext context, Place place, String suggestedPeriod) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'When do you want to go?',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Time period options
            _buildTimePeriodOption(
              context,
              place,
              'Morning',
              '6:00 - 12:00',
              Icons.wb_sunny,
              Colors.orange,
              suggestedPeriod == 'morning',
            ),
            _buildTimePeriodOption(
              context,
              place,
              'Afternoon',
              '12:00 - 17:00',
              Icons.wb_cloudy,
              Colors.blue,
              suggestedPeriod == 'afternoon',
            ),
            _buildTimePeriodOption(
              context,
              place,
              'Evening',
              '17:00 - 22:00',
              Icons.nightlight,
              Colors.purple,
              suggestedPeriod == 'evening',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePeriodOption(
    BuildContext context,
    Place place,
    String label,
    String time,
    IconData icon,
    Color color,
    bool issuggested,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            // Call parent handler which will save to database and show success message
            widget.onAddToDay?.call(place, label.toLowerCase());
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: issuggested ? color.withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: issuggested ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A202C),
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (issuggested)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Suggested',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReservationSheet(BuildContext context, Place place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎫',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Reservation Required',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${place.name} typically requires a reservation.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Book button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openGoogleMaps(place);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A6049),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'View on Google Maps',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Reminder button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  showWanderMoodToast(
                    context,
                    message: 'Reminder set for ${place.name}',
                    backgroundColor: const Color(0xFF2A6049),
                  );
                },
                child: Text(
                  'Set reminder to book',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, Place place, String period) {
    showWanderMoodToast(
      context,
      message: '${place.name} added to your $period!',
      duration: const Duration(seconds: 3),
      backgroundColor: const Color(0xFF2A6049),
      leading: const Icon(Icons.check_circle, color: Colors.white),
      actionLabel: 'View',
      onAction: () {
        // TODO: Navigate to My Day
      },
    );
  }

  void _askMoodyAboutPlace(BuildContext context, Place place) {
    final message = 'Tell me more about ${place.name}. Why would I love it based on my ${widget.mood} mood?';
    widget.onChatOpen?.call(context, contextualGreeting: message);
  }

  void _toggleSave(Place place) async {
    final savedPlacesService = ref.read(savedPlacesServiceProvider);
    
    if (_savedPlaces.contains(place.id)) {
      // Unsave
      if (!mounted) return;
      setState(() {
        _savedPlaces.remove(place.id);
      });
      
      try {
        await savedPlacesService.unsavePlace(place.id);
        if (!mounted) return;
        showWanderMoodToast(
          context,
          message: '${place.name} removed from saved',
          backgroundColor: Colors.grey.shade700,
          duration: const Duration(seconds: 2),
          leading: const Icon(Icons.bookmark_border, color: Colors.white, size: 20),
        );
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Error unsaving place: $e');
        // Re-add if unsave failed
        if (!mounted) return;
        setState(() {
          _savedPlaces.add(place.id);
        });
      }
    } else {
      // Save
      if (!mounted) return;
      setState(() {
        _savedPlaces.add(place.id);
      });
      
      try {
        await savedPlacesService.savePlace(place);
        if (!mounted) return;
        _showSavedMessage(place);
        if (kDebugMode) debugPrint('✅ Successfully saved ${place.name} to database');
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Error saving place: $e');
        // Remove from local state if save failed
        if (!mounted) return;
        setState(() {
          _savedPlaces.remove(place.id);
        });
        if (!mounted) return;
        showWanderMoodToast(
          context,
          message: 'Failed to save ${place.name}. Please try again.',
          isError: true,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _savePlaceForLater(Place place) async {
    final savedPlacesService = ref.read(savedPlacesServiceProvider);
    
    if (!mounted) return;
    setState(() {
      _savedPlaces.add(place.id);
    });
    
    // Save to database
    try {
      await savedPlacesService.savePlace(place);
      if (!mounted) return;
      _showSavedMessage(place);
      if (kDebugMode) debugPrint('✅ Successfully saved ${place.name} to database');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error saving place: $e');
      // Remove from local state if save failed
      if (!mounted) return;
      setState(() {
        _savedPlaces.remove(place.id);
      });
      // Show error message
      if (!mounted) return;
      showWanderMoodToast(
        context,
        message: 'Failed to save ${place.name}. Please try again.',
        isError: true,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _showSavedMessage(Place place) {
    showWanderMoodToast(
      context,
      message: '${place.name} saved for later!',
      duration: const Duration(seconds: 3),
      backgroundColor: const Color(0xFF2A6049),
      leading: const Icon(Icons.bookmark, color: Colors.white, size: 20),
    );
  }

  void _showDismissMessage(Place place) {
    showWanderMoodToast(
      context,
      message: '${place.name} hidden',
      duration: const Duration(seconds: 4),
      backgroundColor: Colors.grey.shade700,
      leading: const Icon(Icons.cancel_outlined, color: Colors.white, size: 20),
      actionLabel: 'Undo',
      onAction: () {
        if (!mounted) return;
        setState(() {
          _dismissedPlaces.remove(place.id);
        });
      },
    );
  }

  void _openGoogleMaps(Place place) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(place.name)}&query_place_id=${place.id}',
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

