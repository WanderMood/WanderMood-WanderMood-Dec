import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/features/places/providers/trending_destinations_provider.dart';
import 'package:wandermood/core/theme/app_theme.dart';
import 'dart:math' as math;
import 'package:wandermood/features/location/providers/location_provider.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

class AllTrendingDestinationsScreen extends ConsumerStatefulWidget {
  final List<PlacesSearchResult> destinations;

  const AllTrendingDestinationsScreen({
    Key? key,
    required this.destinations,
  }) : super(key: key);

  @override
  ConsumerState<AllTrendingDestinationsScreen> createState() => _AllTrendingDestinationsScreenState();
}

class _AllTrendingDestinationsScreenState extends ConsumerState<AllTrendingDestinationsScreen> with SingleTickerProviderStateMixin {
  bool _isMapView = false;
  String _selectedFilter = 'All';
  String _sortOption = 'Most Booked Today 🔥'; // Default sort option
  bool _isListening = false;
  late AnimationController _micAnimationController;
  
  // Sort options
  final List<String> _sortOptions = [
    'Most Booked Today 🔥',
    'Top Rated ⭐',
    'Hidden Gems 💎',
    'New ✨',
  ];
  
  @override
  void initState() {
    super.initState();
    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }
  
  @override
  void dispose() {
    _micAnimationController.dispose();
    super.dispose();
  }
  
  void _startListening() {
    // In a real app, here you would start speech recognition
    setState(() {
      _isListening = true;
    });
    _micAnimationController.repeat();
    
    // Simulate voice recognition with a delay
    Future.delayed(const Duration(seconds: 2), () {
      // Randomly select a sort option to simulate voice recognition
      final random = math.Random();
      final selectedOption = _sortOptions[random.nextInt(_sortOptions.length)];
      
      setState(() {
        _sortOption = selectedOption;
        _isListening = false;
      });
      _micAnimationController.reset();
      
      showWanderMoodToast(
        context,
        message: 'Sorted by "$selectedOption"',
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF2A6049),
      );
    });
  }
  
  void _stopListening() {
    setState(() {
      _isListening = false;
    });
    _micAnimationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    // Define the card builder within build so it has access to context
    Widget buildDestinationCard(PlacesSearchResult destination, WidgetRef ref, int index) {
      // Generate a booking count based on the destination hash to make it deterministic
      final bookingCount = 5 + (destination.hashCode % 38);
      // Generate a deterministic rating between 3.5 and 5.0
      final rating = 3.5 + ((destination.hashCode % 30) / 20);
      
      // Get current location, defaulting to Rotterdam if not available
      final locationState = ref.watch(locationProvider);
      final currentCity = locationState.asData?.value ?? 'Rotterdam';
      
      // Determine if this card has the highest booking count (to add special animation)
      bool isTopTrending = _sortOption == 'Most Booked Today 🔥' && index == 0;
      
      return Hero(
        tag: 'trending_destination_${destination.placeId}',
        child: Card(
          elevation: 10,
          shadowColor: Colors.black.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (destination.photos?.isNotEmpty ?? false)
                Image.network(
                  ref.read(trendingDestinationsProvider(city: currentCity).notifier)
                      .getPhotoUrl(destination.photos!.first.photoReference),
                  fit: BoxFit.cover,
                  height: double.infinity,
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              
              // Booking count badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A6049),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isTopTrending)
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 16,
                        ).animate(
                          onPlay: (controller) => controller.repeat(reverse: true),
                        ).scale(
                          duration: 800.ms,
                          curve: Curves.easeInOut,
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.4, 1.4),
                        ).then()
                        .tint(
                          color: Colors.orange,
                          duration: 500.ms,
                        ).then()
                        .tint(
                          color: Colors.white,
                          duration: 500.ms,
                        )
                      else
                        const Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: 16,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        '$bookingCount booked today',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Destination info
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    
                    // Rating stars
                    Row(
                      children: [
                        ...List.generate(5, (starIndex) {
                          final double threshold = starIndex + 1.0;
                          IconData icon;
                          Color color;
                          
                          if (rating >= threshold) {
                            icon = Icons.star;
                            color = Colors.amber;
                          } else if (rating > starIndex.toDouble()) {
                            icon = Icons.star_half;
                            color = Colors.amber;
                          } else {
                            icon = Icons.star_outline;
                            color = Colors.amber.withOpacity(0.7);
                          }
                          
                          return Icon(
                            icon,
                            color: color,
                            size: 14,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    if (destination.types?.isNotEmpty ?? false)
                      Text(
                        destination.types!.first.replaceAll('_', ' ').toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    // Emoji based on type
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getEmojiForType(destination.types?.firstOrNull ?? ''),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Make the card tappable
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showWanderMoodToast(
                      context,
                      message: 'Would navigate to ${destination.name}',
                      duration: const Duration(seconds: 1),
                    );
                  },
                  splashColor: Colors.white.withOpacity(0.1),
                  highlightColor: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ).animate(
        delay: Duration(milliseconds: 100 * index),
      ).fadeIn(duration: const Duration(milliseconds: 300))
      .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 300));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '🔥 Trending Destinations',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        ).shimmer(
          duration: const Duration(seconds: 3),
          color: const Color(0xFF2A6049).withOpacity(0.3),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.black,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Map/List view toggle
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // List view button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMapView = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isMapView 
                          ? const Color(0xFF2A6049).withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(20),
                      ),
                    ),
                    child: Icon(
                      Icons.view_list,
                      color: !_isMapView ? const Color(0xFF2A6049) : Colors.black54,
                      size: 20,
                    ),
                  ),
                ),
                // Map view button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMapView = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isMapView 
                          ? const Color(0xFF2A6049).withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(20),
                      ),
                    ),
                    child: Icon(
                      Icons.map,
                      color: _isMapView ? const Color(0xFF2A6049) : Colors.black54,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16, top: 8),
                      child: Text(
                        'Discover what\'s popular right now',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 1),
                              blurRadius: 3.0,
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Filter row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', _selectedFilter == 'All'),
                          _buildFilterChip('Attractions', _selectedFilter == 'Attractions'),
                          _buildFilterChip('Museums', _selectedFilter == 'Museums'),
                          _buildFilterChip('Parks', _selectedFilter == 'Parks'),
                          _buildFilterChip('Restaurants', _selectedFilter == 'Restaurants'),
                        ],
                      ),
                    ),
                    
                    // Sort options
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        children: [
                          Text(
                            'Sort by:',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _showSortOptionsModal(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF2A6049).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _sortOption,
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF2A6049),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: Color(0xFF2A6049),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Show different views based on toggle state
                    Expanded(
                      child: _isMapView
                          ? _buildMapView()
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: widget.destinations.length,
                              itemBuilder: (context, index) {
                                // Apply sorting to determine the actual index to use
                                final sortedIndex = _getSortedIndex(index);
                                return buildDestinationCard(widget.destinations[sortedIndex], ref, index);
                              },
                            ),
                    ),
                  ],
                ),
              ),
              
              // Voice command floating action button
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: _isListening ? _stopListening : _startListening,
                  backgroundColor: _isListening 
                      ? Colors.red 
                      : const Color(0xFF2A6049),
                  child: AnimatedBuilder(
                    animation: _micAnimationController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isListening)
                            ...List.generate(3, (i) {
                              return Container(
                                width: 55.0 + (i * 5.0),
                                height: 55.0 + (i * 5.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF2A6049).withOpacity(
                                    0.5 - (i * 0.15) * _micAnimationController.value,
                                  ),
                                ),
                              ).animate(
                                controller: _micAnimationController,
                              ).scale(
                                duration: Duration(milliseconds: 500 + (i * 200)),
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.2, 1.2),
                                curve: Curves.easeOut,
                              );
                            }),
                          Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                            size: 28,
                          ),
                        ],
                      );
                    },
                  ),
                ).animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOutQuad),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Map View Coming Soon',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'In the full version, you\'ll see all trending destinations on an interactive map!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isMapView = false;
              });
            },
            icon: const Icon(Icons.view_list),
            label: const Text('Switch to List View'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A6049),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              _selectedFilter = label;
            });
          }
        },
        backgroundColor: Colors.white.withOpacity(0.8),
        selectedColor: const Color(0xFF2A6049).withOpacity(0.3),
        checkmarkColor: const Color(0xFF2A6049),
        labelStyle: GoogleFonts.poppins(
          color: isSelected ? const Color(0xFF2A6049) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected 
                ? const Color(0xFF2A6049) 
                : Colors.transparent,
            width: isSelected ? 1.5 : 0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: isSelected ? 2 : 0,
        shadowColor: isSelected ? const Color(0xFF2A6049).withOpacity(0.3) : Colors.transparent,
      ),
    );
  }
  
  String _getEmojiForType(String type) {
    switch (type.toLowerCase()) {
      case 'tourist_attraction':
        return '🏛️ Attraction';
      case 'museum':
        return '🖼️ Museum';
      case 'park':
        return '🌳 Park';
      case 'restaurant':
        return '🍽️ Restaurant';
      case 'bar':
        return '🍸 Bar';
      case 'shopping_mall':
        return '🛍️ Shopping';
      case 'lodging':
        return '🏨 Hotel';
      case 'cafe':
        return '☕ Café';
      default:
        return '�� Place';
    }
  }

  // Show sort options in a modal bottom sheet
  void _showSortOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Text(
                      'Sort Destinations',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              ...List.generate(
                _sortOptions.length,
                (index) => _buildSortOption(_sortOptions[index], context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Build individual sort option item
  Widget _buildSortOption(String option, BuildContext context) {
    final bool isSelected = option == _sortOption;
    
    return InkWell(
      onTap: () {
        setState(() {
          _sortOption = option;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A6049).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              option,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF2A6049) : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2A6049),
              ),
          ],
        ),
      ),
    );
  }
  
  // Get the actual index based on current sort option
  int _getSortedIndex(int index) {
    switch (_sortOption) {
      case 'Most Booked Today 🔥':
        // Sort by booking count (descending)
        final sortedIndices = List.generate(widget.destinations.length, (i) => i)
          ..sort((a, b) {
            final bookingCountA = 5 + (widget.destinations[a].hashCode % 38);
            final bookingCountB = 5 + (widget.destinations[b].hashCode % 38);
            return bookingCountB.compareTo(bookingCountA); // Descending
          });
        return sortedIndices[index];
        
      case 'Top Rated ⭐':
        // Sort by rating (descending)
        final sortedIndices = List.generate(widget.destinations.length, (i) => i)
          ..sort((a, b) {
            final ratingA = 3.5 + ((widget.destinations[a].hashCode % 30) / 20);
            final ratingB = 3.5 + ((widget.destinations[b].hashCode % 30) / 20);
            return ratingB.compareTo(ratingA); // Descending
          });
        return sortedIndices[index];
        
      case 'Hidden Gems 💎':
        // Sort by a combination of high rating + low booking count
        final sortedIndices = List.generate(widget.destinations.length, (i) => i)
          ..sort((a, b) {
            final ratingA = 3.5 + ((widget.destinations[a].hashCode % 30) / 20);
            final bookingCountA = 5 + (widget.destinations[a].hashCode % 38);
            final ratingB = 3.5 + ((widget.destinations[b].hashCode % 30) / 20);
            final bookingCountB = 5 + (widget.destinations[b].hashCode % 38);
            
            // Hidden gems formula: high rating + low popularity = hidden gem
            final gemScoreA = ratingA - (bookingCountA / 50);
            final gemScoreB = ratingB - (bookingCountB / 50);
            return gemScoreB.compareTo(gemScoreA);
          });
        return sortedIndices[index];
        
      case 'New ✨':
        // Sort by "newness" - using a hash-based value for demo purposes
        final sortedIndices = List.generate(widget.destinations.length, (i) => i)
          ..sort((a, b) {
            // Use the last character of placeId to simulate "newness"
            final newScoreA = widget.destinations[a].placeId?.codeUnitAt(widget.destinations[a].placeId!.length - 1) ?? 0;
            final newScoreB = widget.destinations[b].placeId?.codeUnitAt(widget.destinations[b].placeId!.length - 1) ?? 0;
            return newScoreB.compareTo(newScoreA);
          });
        return sortedIndices[index];
        
      default:
        return index;
    }
  }
} 