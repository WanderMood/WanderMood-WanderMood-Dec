import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/saved_places_service.dart';
import '../../models/place.dart';
import 'package:url_launcher/url_launcher.dart';

class SavedPlacesScreen extends ConsumerStatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  ConsumerState<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends ConsumerState<SavedPlacesScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh saved places when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(savedPlacesProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final savedPlacesAsync = ref.watch(savedPlacesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Saved Places',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A202C),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A202C)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A202C)),
            onPressed: () {
              ref.invalidate(savedPlacesProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: savedPlacesAsync.when(
        data: (savedPlaces) {
          if (savedPlaces.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildSavedPlacesList(context, ref, savedPlaces);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString()),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_border,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No saved places yet',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Swipe right on places you love\nto save them for later',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF12B347),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Discover places',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPlacesList(
    BuildContext context,
    WidgetRef ref,
    List<SavedPlace> savedPlaces,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with count
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
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
                    const Icon(Icons.bookmark, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${savedPlaces.length} saved',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // List of saved places
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: savedPlaces.length,
            itemBuilder: (context, index) {
              final savedPlace = savedPlaces[index];
              return _buildSavedPlaceCard(context, ref, savedPlace);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSavedPlaceCard(
    BuildContext context,
    WidgetRef ref,
    SavedPlace savedPlace,
  ) {
    final place = savedPlace.place;
    final gradientColors = _getGradientForIndex(savedPlace.hashCode % 8);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (place.photos.isNotEmpty && place.photos.first.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: place.photos.first,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        return Center(
                          child: Text(
                            _getPlaceEmoji(place.types),
                            style: const TextStyle(fontSize: 64),
                          ),
                        );
                      },
                    )
                  else
                    Center(
                      child: Text(
                        _getPlaceEmoji(place.types),
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                        if (place.rating > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
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
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Saved date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved ${_formatSavedDate(savedPlace.savedAt)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (place.types.isNotEmpty)
                          Text(
                            place.types.first.replaceAll('_', ' ').toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Directions button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openDirections(place),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12B347).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.directions,
                          color: Color(0xFF12B347),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Remove button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _removeSavedPlace(context, ref, savedPlace),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.bookmark_remove,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientForIndex(int index) {
    final gradients = [
      [const Color(0xFFFFE5B4), const Color(0xFFFFD6A5)],
      [const Color(0xFFB4E5FF), const Color(0xFFA5D8FF)],
      [const Color(0xFFFFB4E5), const Color(0xFFFFA5D8)],
      [const Color(0xFFB4FFD5), const Color(0xFFA5FFBB)],
      [const Color(0xFFD4B4FF), const Color(0xFFC8A5FF)],
      [const Color(0xFFFFE5D4), const Color(0xFFFFD4B4)],
      [const Color(0xFFD4FFE5), const Color(0xFFB4FFD4)],
      [const Color(0xFFFFD4E5), const Color(0xFFFFC4D4)],
    ];
    return gradients[index % gradients.length];
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

  String _formatSavedDate(DateTime savedAt) {
    final now = DateTime.now();
    final difference = now.difference(savedAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'just now';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${savedAt.day}/${savedAt.month}/${savedAt.year}';
    }
  }

  void _removeSavedPlace(
    BuildContext context,
    WidgetRef ref,
    SavedPlace savedPlace,
  ) {
    final savedPlacesService = ref.read(savedPlacesServiceProvider);
    
    savedPlacesService.unsavePlace(savedPlace.placeId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.bookmark_remove, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${savedPlace.placeName} removed',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openDirections(Place place) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(place.name)}&query_place_id=${place.id}',
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
