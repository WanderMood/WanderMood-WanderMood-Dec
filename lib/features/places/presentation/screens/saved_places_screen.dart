import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:go_router/go_router.dart';

class SavedPlacesScreen extends ConsumerStatefulWidget {
  const SavedPlacesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends ConsumerState<SavedPlacesScreen> {
  // Placeholder data for saved places
  final List<Place> _savedPlaces = [
    Place(
      id: 'golden_gate',
      name: 'Golden Gate Bridge',
      address: 'Golden Gate Bridge, San Francisco, CA 94129',
      rating: 4.8,
      photos: ['assets/images/fallbacks/default.jpg'],
      types: ['point_of_interest', 'tourist_attraction'],
      location: const PlaceLocation(lat: 37.8199, lng: -122.4783),
      description: 'Iconic suspension bridge spanning the Golden Gate Strait',
      emoji: '🌉',
      tag: 'Landmark',
      isAsset: true,
      activities: ['Sightseeing', 'Photography', 'Walking'],
      dateAdded: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Place(
      id: 'fishermans_wharf',
      name: 'Fisherman\'s Wharf',
      address: 'Beach Street & The Embarcadero, San Francisco, CA',
      rating: 4.5,
      photos: ['assets/images/fallbacks/default.jpg'],
      types: ['tourist_attraction', 'restaurant'],
      location: const PlaceLocation(lat: 37.8080, lng: -122.4177),
      description: 'Popular waterfront area with shopping, dining, and sea lions',
      emoji: '🦭',
      tag: 'Entertainment',
      isAsset: true,
      activities: ['Shopping', 'Dining', 'Sea Lion Watching'],
      dateAdded: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Place(
      id: 'painted_ladies',
      name: 'Painted Ladies',
      address: 'Alamo Square, Hayes Valley, San Francisco, CA',
      rating: 4.6,
      photos: ['assets/images/fallbacks/default.jpg'],
      types: ['tourist_attraction', 'landmark'],
      location: const PlaceLocation(lat: 37.7764, lng: -122.4330),
      description: 'Row of Victorian houses with a scenic backdrop of the city',
      emoji: '🏠',
      tag: 'Scenic',
      isAsset: true,
      activities: ['Photography', 'Sightseeing'],
      dateAdded: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Place(
      id: 'lombard_street',
      name: 'Lombard Street',
      address: 'Lombard St, San Francisco, CA 94133',
      rating: 4.4,
      photos: ['assets/images/fallbacks/default.jpg'],
      types: ['tourist_attraction', 'landmark'],
      location: const PlaceLocation(lat: 37.8021, lng: -122.4186),
      description: 'Famous winding street known as the "crookedest street in the world"',
      emoji: '🛣️',
      tag: 'Landmark',
      isAsset: true,
      activities: ['Photography', 'Walking'],
      dateAdded: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Place(
      id: 'coit_tower',
      name: 'Coit Tower',
      address: '1 Telegraph Hill Blvd, San Francisco, CA 94133',
      rating: 4.3,
      photos: ['assets/images/fallbacks/default.jpg'],
      types: ['tourist_attraction', 'landmark'],
      location: const PlaceLocation(lat: 37.8025, lng: -122.4058),
      description: 'Historic tower with panoramic views of the city and bay',
      emoji: '🗼',
      tag: 'Landmark',
      isAsset: true,
      activities: ['Sightseeing', 'Photography'],
      dateAdded: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  // Filter state
  String _currentFilter = 'All';
  final List<String> _filterOptions = ['All', 'Landmarks', 'Food', 'Nature', 'Entertainment'];

  @override
  Widget build(BuildContext context) {
    // Filter places if not 'All'
    final filteredPlaces = _currentFilter == 'All'
        ? _savedPlaces
        : _savedPlaces.where((place) {
            if (_currentFilter == 'Landmarks' && 
                (place.types.contains('landmark') || place.tag == 'Landmark')) {
              return true;
            } else if (_currentFilter == 'Food' && 
                (place.types.contains('restaurant') || place.types.contains('cafe'))) {
              return true;
            } else if (_currentFilter == 'Nature' && 
                (place.types.contains('park') || place.tag == 'Nature')) {
              return true;
            } else if (_currentFilter == 'Entertainment' && 
                (place.types.contains('entertainment') || place.tag == 'Entertainment')) {
              return true;
            }
            return false;
          }).toList();

    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Saved Places',
            style: GoogleFonts.museoModerno(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF12B347),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {
                // Search functionality
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _filterOptions.map((filter) {
                    final isSelected = _currentFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(
                          filter,
                          style: GoogleFonts.poppins(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF12B347),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (selected) {
                          setState(() {
                            _currentFilter = filter;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            // Place count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Text(
                    '${filteredPlaces.length} ${filteredPlaces.length == 1 ? 'place' : 'places'}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: 'Date: Newest',
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                    underline: const SizedBox(),
                    items: ['Date: Newest', 'Date: Oldest', 'Name: A-Z', 'Rating: High to Low']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      // Sort places
                    },
                  ),
                ],
              ),
            ),
            
            // List of saved places
            Expanded(
              child: filteredPlaces.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredPlaces.length,
                      itemBuilder: (context, index) {
                        return _buildPlaceCard(filteredPlaces[index]);
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF12B347),
          child: const Icon(Icons.add),
          onPressed: () {
            // Navigate to explore to find more places
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Find more places to save'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.place_outlined,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No saved places found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or add new places',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // Place card widget
  Widget _buildPlaceCard(Place place) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to place details
          context.push('/place/${place.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: place.isAsset
                      ? Image.asset(
                          place.photos.first,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, color: Colors.white, size: 40),
                          ),
                        )
                      : Image.network(
                          place.photos.first,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, color: Colors.white, size: 40),
                          ),
                        ),
                ),
                
                // Category tag
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          place.emoji ?? '📍',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          place.tag ?? 'Place',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Saved date
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Saved ${_formatSavedDate(place.dateAdded ?? DateTime.now())}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (place.rating > 0) ...[
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          place.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.address,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.description ?? 'No description available',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  
                  // Activities
                  if (place.activities.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: place.activities.map((activity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF12B347).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            activity,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF12B347),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            
            // Actions row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.directions_outlined),
                    onPressed: () {
                      // Open directions
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      // Share place
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark, color: Color(0xFF12B347)),
                    onPressed: () {
                      // Unsave place
                      setState(() {
                        _savedPlaces.removeWhere((p) => p.id == place.id);
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Format saved date relative to today
  String _formatSavedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }
} 