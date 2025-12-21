import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:wandermood/core/theme/app_theme.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/providers/explore_places_provider.dart';
import 'package:wandermood/features/places/services/saved_places_service.dart';
import 'package:wandermood/features/places/presentation/widgets/booking_bottom_sheet.dart';
import 'package:wandermood/core/services/moody_ai_service.dart';
import 'package:wandermood/features/places/services/places_service.dart';
import 'package:wandermood/features/places/services/reviews_cache_service.dart';
import 'package:wandermood/core/widgets/data_source_badge.dart';

class PlaceDetailScreen extends ConsumerStatefulWidget {
  final String placeId;

  const PlaceDetailScreen({
    required this.placeId,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _photoController = PageController();
  int _currentPhotoIndex = 0;
  Place? _currentPlace; // Track current place for booking button
  List<Map<String, dynamic>> _realReviews = []; // Real reviews from Google API
  bool _loadingReviews = false;
  bool _hasAttemptedReviewFetch = false;
  
  // Request deduplication: Track in-flight API requests
  final Set<String> _inFlightRequests = {};
  Place? _cachedPlace; // Cache the found place to avoid repeated lookups
  Future<List<String>>? _cachedMoodyTipsFuture; // Cache AI tips Future
  String? _cachedPlaceIdForTips; // Track which place the tips are for
  bool _isInitialized = false; // Track if widget has been initialized to prevent rebuild loops

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _isInitialized = true;
  }

  @override
  void dispose() {
    _isInitialized = false; // Mark as disposed to prevent rebuilds
    _inFlightRequests.clear(); // Clear any pending requests
    _tabController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('🔥 PLACE DETAIL SCREEN - BUILDING WITH PLACE ID: ${widget.placeId}');
    
    // Prevent rebuild loops: If we have a cached place and it matches, use it immediately
    // Don't do any provider reads/watches that could trigger rebuilds
    if (_cachedPlace != null && _cachedPlace!.id == widget.placeId && _isInitialized) {
      return _buildWithPlace(_cachedPlace!);
    }
    
    // List of all possible cities to check (including Delft, Beneden-Leeuwen and other cities)
    const allCities = [
      'Eindhoven', 
      'Rotterdam', 
      'Amsterdam', 
      'The Hague', 
      'Utrecht', 
      'Groningen',
      'Delft',
      'Beneden-Leeuwen',
    ];
    
    // Use ref.read instead of ref.watch to avoid rebuilds when providers update
    // Only read once and cache the result
    Place? foundPlace;
    String? foundCity;
    
    for (final city in allCities) {
      final placesAsync = ref.read(explorePlacesProvider(city: city));
      final place = placesAsync.maybeWhen(
        data: (places) {
          try {
            return places.firstWhere(
              (p) => p.id == widget.placeId,
            );
          } catch (e) {
            return null;
          }
        },
        orElse: () => null,
      );
      
      if (place != null) {
        foundPlace = place;
        foundCity = city;
        if (kDebugMode) debugPrint('✅ Place found in $city cache');
        break;
      }
    }
    
    // Cache the found place to avoid repeated lookups
    if (foundPlace != null) {
      _cachedPlace = foundPlace;
      return _buildWithPlace(foundPlace);
    }
    
    if (kDebugMode) debugPrint('⚠️ Place not found in any city cache, using Rotterdam as fallback...');
    
    // Fallback: Use Rotterdam provider (but only watch this one, not all 8)
    // Only watch if we haven't cached a place yet to prevent rebuild loops
    final rotterdamAsync = _cachedPlace == null 
        ? ref.watch(explorePlacesProvider(city: 'Rotterdam'))
        : ref.read(explorePlacesProvider(city: 'Rotterdam'));
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFDF5), // Warm cream yellow
            Color(0xFFFFF3E0), // Slightly darker warm yellow
            Color(0xFFFFF9E8), // Light peachy warmth
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: rotterdamAsync.when(
          data: (places) {
            try {
              final place = places.firstWhere(
                (p) => p.id == widget.placeId,
              );
              // Cache the place
              _cachedPlace = place;
              return _buildWithPlace(place);
            } catch (e) {
              // Place not found in any cache - try to fetch it directly if it's a Google Place ID
              if (widget.placeId.startsWith('google_')) {
                if (kDebugMode) debugPrint('🔄 Place not in cache, fetching directly from Google Places API...');
                return FutureBuilder<Place>(
                  future: _fetchPlaceDirectly(widget.placeId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
                        ),
                      );
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      final place = snapshot.data!;
                      // Cache the place
                      _cachedPlace = place;
                      return _buildWithPlace(place);
                    }
                    return _buildErrorState(Exception('Place not found and could not be fetched'));
                  },
                );
              }
              return _buildErrorState(Exception('Place not found'));
            }
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
            ),
          ),
          error: (error, stack) => _buildErrorState(error),
        ),
        bottomNavigationBar: _cachedPlace != null
            ? (_isPlaceBookable(_cachedPlace!)
                ? _buildBookingButton(_cachedPlace!)
                : const SizedBox.shrink())
            : const SizedBox.shrink(),
      ),
    );
  }
  
  /// Helper method to build with a place (avoids duplicate code)
  Widget _buildWithPlace(Place place) {
    // Update current place for booking button (only if changed)
    if (_currentPlace?.id != place.id) {
      _currentPlace = place;
      _cachedPlace = place; // Ensure cached place is set for booking button
      _hasAttemptedReviewFetch = false;
      _realReviews = [];
    }
    // Return the full Scaffold structure with booking button
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFDF5), // Warm cream yellow
            Color(0xFFFFF3E0), // Slightly darker warm yellow
            Color(0xFFFFF9E8), // Light peachy warmth
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _buildPlaceDetail(place),
        bottomNavigationBar: _isPlaceBookable(place)
            ? _buildBookingButton(place)
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildPlaceDetail(Place place) {
    if (kDebugMode) debugPrint('🏗️ BUILDING PLACE DETAIL for: ${place.name}');
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        _buildSliverAppBar(place, innerBoxIsScrolled),
      ],
      body: Container(
            decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF9E8), // Light peachy warmth
              Color(0xFFFFFDF5), // Warm cream yellow
            ],
          ),
              borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildTabBar(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildTabContent(place),
            ),
              ],
            ),
          ),
    );
  }

  Widget _buildSliverAppBar(Place place, bool innerBoxIsScrolled) {
    // Use solid background when scrolled to prevent content bleed-through
    final backgroundColor = innerBoxIsScrolled
        ? const Color(0xFFFFF9E8) // Match body background color
        : Colors.transparent;
    
    final iconColor = innerBoxIsScrolled ? Colors.black : Colors.white;
    final buttonBackground = innerBoxIsScrolled
        ? Colors.white.withOpacity(0.9)
        : Colors.black.withOpacity(0.3);
    
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: backgroundColor,
      elevation: innerBoxIsScrolled ? 2 : 0,
      systemOverlayStyle: innerBoxIsScrolled
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: buttonBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () {
            // Pop back to previous screen (Explore screen)
            // This maintains the navigation stack and preserves the selected city
            // The locationNotifierProvider maintains the selected city state across navigation
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              // Fallback: Navigate to Explore tab if no previous route exists
              // This preserves the selected city since locationNotifierProvider is stateful
              context.go('/main?tab=1');
            }
          },
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: buttonBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.share, color: iconColor),
            onPressed: () => _sharePlace(place),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: buttonBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Consumer(
            builder: (context, ref, child) {
              final savedPlacesAsync = ref.watch(savedPlacesProvider);
              
              return savedPlacesAsync.when(
                data: (savedPlaces) {
                  final isSaved = savedPlaces.any((sp) => sp.placeId == place.id);
                  
                  return IconButton(
                    icon: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved ? Colors.red : iconColor,
                    ),
                    onPressed: () async {
                      final savedPlacesService = ref.read(savedPlacesServiceProvider);
                      try {
                        if (isSaved) {
                          await savedPlacesService.unsavePlace(place.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${place.name} removed from saved places'),
                              backgroundColor: Colors.orange.shade400,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          await savedPlacesService.savePlace(place);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${place.name} saved to favorites!'),
                              backgroundColor: const Color(0xFF12B347),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                        ref.invalidate(savedPlacesProvider);
                        HapticFeedback.lightImpact();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to ${isSaved ? 'unsave' : 'save'} place'),
                            backgroundColor: Colors.red.shade400,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  );
                },
                loading: () => IconButton(
                  icon: Icon(Icons.favorite_border, color: iconColor),
                  onPressed: () {},
                ),
                error: (_, __) => IconButton(
                  icon: Icon(Icons.favorite_border, color: iconColor),
                  onPressed: () {},
                ),
              );
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRect(
          child: _buildPhotoCarousel(place),
        ),
      ),
    );
  }

  Widget _buildPhotoCarousel(Place place) {
    if (place.photos.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image, size: 64, color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _photoController,
          onPageChanged: (index) => setState(() => _currentPhotoIndex = index),
          itemCount: place.photos.length,
          itemBuilder: (context, index) {
            return place.isAsset
                ? Image.asset(
                    place.photos[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImageFallback(),
                  )
                : Image.network(
                    place.photos[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImageFallback(),
                  );
          },
        ),
        // Dark gradient overlay for better text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
        ),
        // Place name and details overlay (bottom right)
        Positioned(
          bottom: 24,
          right: 24,
          left: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Activity tags
              if (place.activities.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: place.activities.take(2).map((activity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
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
                const SizedBox(height: 12),
              ],
              // Place name (activity name only, no location)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getCleanActivityName(place.name),
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Rating badge
                  if (place.rating > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12B347),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            place.rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              // Removed address from image overlay as requested
            ],
          ),
        ),
        // Page indicators for multiple photos
        if (place.photos.length > 1) ...[
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(place.photos.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPhotoIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image, size: 64, color: Colors.grey),
      ),
    );
  }



  Widget _buildTabBar() {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFF12B347).withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF12B347).withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF12B347),
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF12B347),
              Color(0xFF0D8A35),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF12B347).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: '✨ Details'),
          Tab(text: '📸 Photos'),
          Tab(text: '⭐ Reviews'),
        ],
      ),
      ),
    );
  }

  Widget _buildTabContent(Place place) {
    if (kDebugMode) debugPrint('📋 BUILDING TAB CONTENT for: ${place.name}');
    return Padding(
        padding: const EdgeInsets.all(24),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDetailsTab(place),
            _buildPhotosTab(place),
          _buildReviewsTab(place),
          ],
      ),
    );
  }

  Widget _buildDetailsTab(Place place) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About section - clean without border, more emojis
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '🏛️✨',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
          Text(
                    'About this magical place 🌟',
            style: GoogleFonts.poppins(
              fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E2E2E),
            ),
          ),
                ],
              ),
              const SizedBox(height: 16),
          Text(
            place.description ?? 
                    '✨ A wonderful place to visit with great atmosphere and excellent vibes! 🎉 '
                    '🎯 Perfect for ${place.activities.isNotEmpty ? place.activities.join(', ').toLowerCase() + ' and creating amazing memories! 📸' : 'spending quality time and making unforgettable moments! 💫'}',
            style: GoogleFonts.poppins(
                  fontSize: 15,
              height: 1.6,
                  color: const Color(0xFF424242),
                  fontWeight: FontWeight.w400,
            ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (place.openingHours != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7CB342).withOpacity(0.1),
                    const Color(0xFF689F38).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF7CB342).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7CB342).withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7CB342).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '🕐',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
            Text(
                        'Opening Hours',
              style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF388E3C),
              ),
                      ),
                    ],
            ),
                  const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: place.openingHours!.isOpen
                            ? const Color(0xFF12B347).withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                        width: 1.5,
                      ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                              width: 12,
                              height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: place.openingHours!.isOpen
                              ? const Color(0xFF12B347)
                              : Colors.red,
                                boxShadow: [
                                  BoxShadow(
                                    color: place.openingHours!.isOpen
                                        ? const Color(0xFF12B347).withOpacity(0.3)
                                        : Colors.red.withOpacity(0.3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                        ),
                      ),
                            const SizedBox(width: 12),
                      Text(
                              place.openingHours!.isOpen ? '✅ Open now!' : '❌ Closed',
                        style: GoogleFonts.poppins(
                                fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: place.openingHours!.isOpen
                              ? const Color(0xFF12B347)
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (place.openingHours!.currentStatus != null) ...[
                          const SizedBox(height: 8),
                    Text(
                      place.openingHours!.currentStatus!,
                      style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF424242),
                              fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Features section - colorful pills without card container
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  children: [
                    const Text(
                      '✨',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
          Text(
                      'Amazing Features',
            style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E2E2E),
                      ),
                    ),
                  ],
            ),
          ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36, // Fixed height for carousel
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: (place.types.isNotEmpty ? 3 : 2),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildColorfulFeatureChip(
                          place.isIndoor ? '🏠' : '☀️',
                          place.isIndoor ? 'Indoor Vibes' : 'Outdoor Fun',
                          place.isIndoor ? const Color(0xFFE1BEE7) : const Color(0xFFFFE0B2), // Softer pastel colors
                        ),
                      );
                    } else if (index == 1) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildColorfulFeatureChip(
                          _getEnergyEmoji(place.energyLevel),
                          '${place.energyLevel} Energy',
                          _getSoftEnergyColor(place.energyLevel),
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildColorfulFeatureChip(
                          _getCategoryEmoji(place.types.first),
                          place.types.first.replaceAll('_', ' ').toUpperCase(),
                          _getSoftCategoryColor(place.types.first),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildEssentialInfo(place),
          const SizedBox(height: 24),
          _buildImageCarousel(place),
          const SizedBox(height: 24),
          _buildMoodyTips(place),
        ],
      ),
    );
  }

  // Helper method to clean activity name by removing location info
  String _getCleanActivityName(String name) {
    // Remove common location patterns like "Rotterdam, The Netherlands", "Rotterdam", etc.
    final patterns = [
      ', Rotterdam, The Netherlands',
      ', Rotterdam',
      ', The Netherlands',
      ' Rotterdam',
      ' The Netherlands',
    ];
    
    String cleanName = name;
    for (final pattern in patterns) {
      cleanName = cleanName.replaceAll(pattern, '');
    }
    
    return cleanName.trim();
  }

  Widget _buildEssentialInfo(Place place) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFB74D).withOpacity(0.1),
            const Color(0xFFFFA726).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFB74D).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB74D).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '📋',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
          Text(
                'Essential Travel Info',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF12B347).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // First row: Opening hours and Cost
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        '⏰',
                        'Opening Hours',
                        _getOpeningHoursText(place),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        '💰',
                        'Cost',
                        _getCostText(place),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Second row: Duration and Accessibility
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        '⏱️',
                        'Duration',
                        _getDurationText(place),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        '🚶',
                        'Accessibility',
                        _getAccessibilityText(place),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Full width: Best time to visit
                _buildFullWidthInfoItem(
                  '🌟',
                  'Best Time',
                  _getBestTimeText(place),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFullWidthInfoItem(String emoji, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.amber[800],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[900],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getOpeningHoursText(Place place) {
    if (place.openingHours?.isOpen == true) {
      return 'Open 24/7';
    } else if (place.openingHours?.currentStatus != null) {
      return place.openingHours!.currentStatus!;
    }
    return 'Check locally';
  }

  String _getCostText(Place place) {
    if (place.isFree) return 'Free to visit';
    if (place.priceRange != null) return place.priceRange!;
    if (place.priceLevel != null) {
      switch (place.priceLevel!) {
        case 0: return 'Free to visit';
        case 1: return '€5-15';
        case 2: return '€15-30';
        case 3: return '€30-50';
        case 4: return '€50+';
        default: return 'Varies';
      }
    }
    return _inferCostFromPlace(place);
  }

  String _inferCostFromPlace(Place place) {
    final placeName = place.name.toLowerCase();
    final description = place.description?.toLowerCase() ?? '';
    
    // Check specific place names/types
    if (placeName.contains('park') || placeName.contains('garden') || 
        placeName.contains('beach') || placeName.contains('square') ||
        placeName.contains('harbor') || placeName.contains('haven')) {
      return 'Free to visit';
    }
    
    if (placeName.contains('museum') || placeName.contains('gallery')) {
      return '€8-25';
    }
    
    if (placeName.contains('market') || placeName.contains('markt')) {
      return 'Free entry (pay for items)';
    }
    
    if (placeName.contains('restaurant') || placeName.contains('cafe')) {
      if (description.contains('fine dining') || description.contains('upscale')) {
        return '€40-80';
      }
      return '€15-35';
    }
    
    if (placeName.contains('mall') || placeName.contains('shopping')) {
      return 'Free entry (pay for items)';
    }
    
    if (placeName.contains('church') || placeName.contains('cathedral')) {
      return 'Free (donations welcome)';
    }
    
    if (placeName.contains('tower') || placeName.contains('observation')) {
      return '€10-20';
    }
    
    // Fallback to place types
    for (final type in place.types) {
      switch (type.toLowerCase()) {
        case 'park':
        case 'tourist_attraction':
          return 'Free to visit';
        case 'museum':
          return '€10-25';
        case 'restaurant':
          return '€15-40';
        case 'shopping_mall':
          return 'Free entry';
        default:
          continue;
      }
    }
    return 'Check locally';
  }

  String _getDurationText(Place place) {
    final placeName = place.name.toLowerCase();
    final activities = place.activities.join(' ').toLowerCase();
    
    // Specific place-based duration estimates
    if (placeName.contains('museum') || placeName.contains('gallery')) {
      return '1.5-3 hours';
    }
    
    if (placeName.contains('market') || placeName.contains('markt')) {
      return '45 mins - 1.5 hours';
    }
    
    if (placeName.contains('restaurant') || placeName.contains('cafe')) {
      if (placeName.contains('quick') || placeName.contains('fast')) {
        return '30-45 minutes';
      }
      return '1-2 hours';
    }
    
    if (placeName.contains('park') || placeName.contains('garden')) {
      if (activities.contains('walk') || activities.contains('stroll')) {
        return '1-3 hours';
      }
      return '2-4 hours';
    }
    
    if (placeName.contains('mall') || placeName.contains('shopping')) {
      return '1-3 hours';
    }
    
    if (placeName.contains('church') || placeName.contains('cathedral')) {
      return '30-60 minutes';
    }
    
    if (placeName.contains('tower') || placeName.contains('observation') || placeName.contains('viewpoint')) {
      return '45 mins - 1.5 hours';
    }
    
    if (placeName.contains('harbor') || placeName.contains('haven') || placeName.contains('waterfront')) {
      return '1-2 hours';
    }
    
    // Check activities for duration hints
    if (activities.contains('quick tour') || activities.contains('short visit')) {
      return '30-60 minutes';
    }
    
    if (activities.contains('dining') || activities.contains('meal')) {
      return '1-2 hours';
    }
    
    if (activities.contains('shopping')) {
      return '1-3 hours';
    }
    
    // Fallback to place types
    for (final type in place.types) {
      switch (type.toLowerCase()) {
        case 'restaurant':
        case 'cafe':
          return '1-2 hours';
        case 'museum':
        case 'tourist_attraction':
          return '1-2.5 hours';
        case 'park':
          return '1-4 hours';
        case 'shopping_mall':
          return '1-3 hours';
        default:
          continue;
      }
    }
    
    return 'Allow 1-2 hours';
  }

  String _getAccessibilityText(Place place) {
    // Check description or activities for accessibility mentions
    final description = place.description?.toLowerCase() ?? '';
    final activities = place.activities.join(' ').toLowerCase();
    
    if (description.contains('accessible') || 
        description.contains('wheelchair') ||
        activities.contains('accessible') ||
        activities.contains('easy walking')) {
      return 'Easy walking (accessible)';
    }
    
    // Check place types for accessibility assumptions
    for (final type in place.types) {
      switch (type.toLowerCase()) {
        case 'museum':
        case 'restaurant':
        case 'shopping_mall':
          return 'Easy walking (accessible)';
        case 'park':
          return 'Moderate walking';
        case 'tourist_attraction':
          return 'Check locally';
        default:
          continue;
      }
    }
    
    return 'Easy walking';
  }

  String _getBestTimeText(Place place) {
    final placeName = place.name.toLowerCase();
    final description = place.description?.toLowerCase() ?? '';
    final activities = place.activities.join(' ').toLowerCase();
    
    // First check for specific place characteristics
    if (placeName.contains('market') || placeName.contains('markt')) {
      return 'Morning hours (fresh produce)';
    }
    
    if (placeName.contains('museum') || placeName.contains('gallery')) {
      return 'Weekday mornings (less crowded)';
    }
    
    if (placeName.contains('restaurant') || placeName.contains('cafe') || placeName.contains('bar')) {
      if (placeName.contains('breakfast') || description.contains('breakfast')) {
        return 'Early morning (8-11 AM)';
      }
      if (placeName.contains('lunch') || description.contains('lunch')) {
        return 'Lunch hours (12-3 PM)';
      }
      return 'Evening for dinner (6-9 PM)';
    }
    
    if (placeName.contains('park') || placeName.contains('garden')) {
      if (activities.contains('photo') || description.contains('scenic')) {
        return 'Golden hour (6-8 PM) for photos';
      }
      return 'Sunny weather, any time of day';
    }
    
    if (placeName.contains('beach') || placeName.contains('waterfront') || placeName.contains('harbor') || placeName.contains('haven')) {
      return 'Golden hour (sunset) for photos';
    }
    
    if (placeName.contains('mall') || placeName.contains('shopping') || placeName.contains('store')) {
      return 'Weekday afternoons (less busy)';
    }
    
    if (placeName.contains('church') || placeName.contains('cathedral') || placeName.contains('temple')) {
      return 'Quiet morning hours';
    }
    
    if (placeName.contains('tower') || placeName.contains('viewpoint') || placeName.contains('observation')) {
      return 'Clear weather, sunset for views';
    }
    
    // Check activities for specific recommendations
    if (activities.contains('food') || activities.contains('dining')) {
      return 'Meal times (lunch or dinner)';
    }
    
    if (activities.contains('shopping')) {
      return 'Weekday afternoons (less crowded)';
    }
    
    if (activities.contains('photo') || activities.contains('sightseeing')) {
      // Only recommend sunset if it's actually outdoor/scenic
      if (place.isIndoor || placeName.contains('hall') || placeName.contains('mall')) {
        return 'Good lighting hours (10 AM - 4 PM)';
      }
      return 'Golden hour (6-8 PM) for photos';
    }
    
    // Final fallback based on place type with better logic
    for (final type in place.types) {
      switch (type.toLowerCase()) {
        case 'restaurant':
        case 'food':
          return 'Meal times (check opening hours)';
        case 'museum':
          return 'Weekday mornings (less crowded)';
        case 'shopping_mall':
        case 'store':
          return 'Weekday afternoons';
        case 'park':
          return 'Sunny weather preferred';
        default:
          continue;
      }
    }
    
    return 'Check opening hours for best times';
  }

  Widget _buildColorfulFeatureChip(String emoji, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2), // Slightly more visible background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.5), // More visible border
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: _getReadableTextColor(color), // High contrast text
              fontWeight: FontWeight.w600, // Bolder for readability
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // Get readable text color based on background
  Color _getReadableTextColor(Color backgroundColor) {
    // Use a darker, more saturated version of the color for text
    final hsl = HSLColor.fromColor(backgroundColor);
    return hsl.withLightness(0.3).withSaturation(0.8).toColor();
  }

  String _getEnergyEmoji(String energyLevel) {
    switch (energyLevel.toLowerCase()) {
      case 'low':
        return '😌';
      case 'medium':
        return '⚡';
      case 'high':
        return '🔥';
      default:
        return '⚡';
    }
  }

  Color _getEnergyColor(String energyLevel) {
    switch (energyLevel.toLowerCase()) {
      case 'low':
        return Colors.blue;
      case 'medium':
        return Colors.amber;
      case 'high':
        return Colors.red;
      default:
        return Colors.amber;
    }
  }

  // Softer pastel versions for the carousel
  Color _getSoftEnergyColor(String energyLevel) {
    switch (energyLevel.toLowerCase()) {
      case 'low':
        return const Color(0xFFB3E5FC); // Soft blue
      case 'medium':
        return const Color(0xFFFFF9C4); // Soft yellow
      case 'high':
        return const Color(0xFFFFCDD2); // Soft red/pink
      default:
        return const Color(0xFFFFF9C4); // Soft yellow
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'tourist_attraction':
        return '🏛️';
      case 'museum':
        return '🏛️';
      case 'park':
        return '🌳';
      case 'restaurant':
        return '🍽️';
      case 'shopping':
        return '🛍️';
      case 'entertainment':
        return '🎭';
      case 'nature':
        return '🌿';
      case 'culture':
        return '🎨';
      default:
        return '📍';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'tourist_attraction':
        return Colors.indigo;
      case 'museum':
        return Colors.brown;
      case 'park':
        return Colors.green;
      case 'restaurant':
        return Colors.deepOrange;
      case 'shopping':
        return Colors.pink;
      case 'entertainment':
        return Colors.purple;
      case 'nature':
        return Colors.teal;
      case 'culture':
        return Colors.deepPurple;
      default:
        return const Color(0xFF12B347);
    }
  }

  // Softer pastel versions for the carousel
  Color _getSoftCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'tourist_attraction':
        return const Color(0xFFC5CAE9); // Soft indigo
      case 'museum':
        return const Color(0xFFD7CCC8); // Soft brown
      case 'park':
        return const Color(0xFFC8E6C9); // Soft green
      case 'restaurant':
        return const Color(0xFFFFE0B2); // Soft orange
      case 'shopping':
        return const Color(0xFFF8BBD0); // Soft pink
      case 'entertainment':
        return const Color(0xFFE1BEE7); // Soft purple
      case 'nature':
        return const Color(0xFFB2DFDB); // Soft teal
      case 'culture':
        return const Color(0xFFD1C4E9); // Soft deep purple
      default:
        return const Color(0xFFC8E6C9); // Soft green
    }
  }

  Widget _buildImageCarousel(Place place) {
    return FutureBuilder<List<String>>(
      future: _getMorePlacePhotos(place),
      builder: (context, snapshot) {
        List<String> allImages = [];
        
        if (snapshot.hasData) {
          allImages.addAll(snapshot.data!);
        } else {
          // Add existing photos while loading more
          allImages.addAll(place.photos);
        }
        
        // Always ensure we have at least some images
        if (allImages.isEmpty) {
          allImages = [
      'assets/images/fallbacks/default.jpg',
      'assets/images/fallbacks/default_place.jpg',
    ];
        }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
      children: [
        Text(
          '📸 Gallery',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
                ),
                if (snapshot.connectionState == ConnectionState.waiting) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF12B347),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${allImages.length} photos',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
                itemCount: allImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.only(
                      right: index == allImages.length - 1 ? 0 : 12,
                ),
                child: GestureDetector(
                      onTap: () => _showFullScreenPhoto(allImages, index, place.isAsset),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                      ),
                          child: Stack(
                            children: [
                              place.isAsset
                          ? Image.asset(
                                      allImages[index],
                              fit: BoxFit.cover,
                                      width: 150,
                                      height: 120,
                              errorBuilder: (_, __, ___) => _buildImageFallback(),
                            )
                          : Image.network(
                                      allImages[index],
                              fit: BoxFit.cover,
                                      width: 150,
                                      height: 120,
                              errorBuilder: (_, __, ___) => _buildImageFallback(),
                                    ),
                              // Add a subtle gradient overlay for better visual appeal
                              Container(
                                width: 150,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.1),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
      },
    );
  }

  /// Fetch additional photos for a place using Google Places API
  Future<List<String>> _getMorePlacePhotos(Place place) async {
    try {
      final List<String> allPhotos = [...place.photos];
      
      // If we have a place ID, try to get more photos from Google Places API
      if (place.id.isNotEmpty && place.id.startsWith('google_')) {
        final placeId = place.id.replaceFirst('google_', '');
        
        // Try to get additional photos using the Legacy API
        final additionalPhotos = await _fetchAdditionalPhotos(placeId);
        allPhotos.addAll(additionalPhotos);
      }
      
      // Remove duplicates and limit to reasonable number
      final uniquePhotos = allPhotos.toSet().toList();
      return uniquePhotos.take(6).toList();
      
    } catch (e) {
      debugPrint('Error fetching additional photos: $e');
      return place.photos;
    }
  }

  /// Fetch additional photos from Google Places Legacy API
  Future<List<String>> _fetchAdditionalPhotos(String placeId) async {
    try {
      debugPrint('🔍 Fetching additional photos for place: $placeId');
      
      // This would ideally use the GooglePlacesService to get more photo references
      // For now, return empty list but structure is ready for implementation
      
      // In a real implementation, you would:
      // 1. Call Google Places Details API with photos field
      // 2. Get all photo references 
      // 3. Convert them to photo URLs using the Legacy API
      
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching additional photos: $e');
      return [];
    }
  }

  Widget _buildMoodyTips(Place place) {
    // Cache the Future to avoid creating new ones on every rebuild
    if (_cachedMoodyTipsFuture == null || _cachedPlaceIdForTips != place.id) {
      _cachedMoodyTipsFuture = _generateAIMoodyTips(place);
      _cachedPlaceIdForTips = place.id;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF12B347).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 28,
                height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF12B347),
                  borderRadius: BorderRadius.circular(14),
              ),
                child: const Center(
                  child: Text(
                    '😎',
                    style: TextStyle(fontSize: 16),
                  ),
              ),
            ),
              const SizedBox(width: 8),
            Text(
                'Moody says...',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                fontWeight: FontWeight.w600,
                  color: const Color(0xFF12B347),
              ),
            ),
          ],
        ),
          const SizedBox(height: 8),
          FutureBuilder<List<String>>(
            future: _cachedMoodyTipsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                      children: [
                        SizedBox(
                        width: 12,
                        height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF12B347),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        'Lemme check this place out... 🤔',
                            style: GoogleFonts.poppins(
                          fontSize: 13,
                              fontStyle: FontStyle.italic,
                          color: const Color(0xFF12B347),
                          ),
                        ),
                      ],
                    ),
                );
              }
              
              final moodyTips = snapshot.data ?? [
                'Check those opening hours first! 🕐',
                'Stay hydrated out there! 💧',
                'Download maps just in case! 📱',
              ];
              
              // Combine all tips into one conversational message
              final conversationalTip = _formatTipsAsConversation(moodyTips, place);
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                          child: Text(
                  conversationalTip,
                            style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.4,
                    color: const Color(0xFF2E2E2E),
                    fontWeight: FontWeight.w400,
                            ),
                          ),
              );
            },
                        ),
                      ],
                    ),
                  );
  }

  String _formatTipsAsConversation(List<String> tips, Place place) {
    if (tips.isEmpty) return 'Have an awesome time exploring! 🎉';
    
    // Take max 3 tips and make them conversational
    final selectedTips = tips.take(3).toList();
    final placeName = place.name.split(',').first; // Get just the place name without location
    
    String conversation = 'Yo! Quick heads up about $placeName - ';
    
    for (int i = 0; i < selectedTips.length; i++) {
      String tip = selectedTips[i];
      
      // Clean up the tip (remove ** formatting, make it more casual)
      tip = tip.replaceAll('**', '').replaceAll('*', '');
      
      // Make tips more conversational and shorter with casual emojis
      if (tip.toLowerCase().contains('food') || tip.toLowerCase().contains('eat')) {
        tip = 'the food here is fire! 🔥';
      } else if (tip.toLowerCase().contains('photo') || tip.toLowerCase().contains('picture')) {
        tip = 'it\'s totally Insta-worthy! 📸';
      } else if (tip.toLowerCase().contains('time') || tip.toLowerCase().contains('visit')) {
        tip = 'timing is everything here ⏰';
      } else if (tip.toLowerCase().contains('drink') || tip.toLowerCase().contains('bar')) {
        tip = 'def grab a drink! 🍻';
      } else if (tip.toLowerCase().contains('crowd') || tip.toLowerCase().contains('busy')) {
        tip = 'it gets pretty packed! 🙈';
      } else if (tip.toLowerCase().contains('walk') || tip.toLowerCase().contains('stroll')) {
        tip = 'perfect for a chill walk! 🚶‍♀️';
      } else {
        // Keep it short and casual
        if (tip.length > 45) {
          tip = tip.substring(0, 42) + '...';
        }
      }
      
      if (i == 0) {
        conversation += tip;
      } else if (i == selectedTips.length - 1 && selectedTips.length > 1) {
        conversation += ' Also, $tip';
      } else {
        conversation += ' Plus, $tip';
      }
    }
    
    // Add a fun ending
    conversation += ' Have fun! ✨';
    
    return conversation;
  }

  /// Generate AI-powered Moody Tips for the place with request deduplication
  Future<List<String>> _generateAIMoodyTips(Place place) async {
    // Request deduplication: Check if request is already in flight
    final requestKey = 'moody_tips_${place.id}';
    if (_inFlightRequests.contains(requestKey)) {
      if (kDebugMode) debugPrint('⏸️ Moody Tips request already in flight for: ${place.id}');
      // Return empty list or wait for existing request
      return [
        '🕐 Check opening hours before your visit to avoid disappointment',
        '📱 Consider downloading offline maps in case of poor signal', 
        '💧 Stay hydrated and bring water, especially during warmer weather',
      ];
    }
    
    // Mark request as in-flight
    _inFlightRequests.add(requestKey);
    
    try {
      final moodyService = ref.read(moodyAIServiceProvider);
      
      // Get current time context
      final hour = DateTime.now().hour;
      final timeOfDay = hour < 12 ? 'morning' : hour < 17 ? 'afternoon' : 'evening';
      
      // You could also get user's current mood from preferences/state if available
      String? userMood;
      // Example: userMood = ref.read(currentMoodProvider);
      
      final tips = await moodyService.generateMoodyTips(
        place: place,
        userMood: userMood,
        timeOfDay: timeOfDay,
        // You could add weather context here if available
        // weather: ref.read(weatherProvider).value?.description,
      );
      
      if (kDebugMode) debugPrint('✅ Generated ${tips.length} AI-powered Moody Tips');
      return tips;
    } catch (e) {
      debugPrint('❌ Error generating AI Moody Tips: $e');
      // Return basic fallback tips in case of complete failure
      return [
        '🕐 Check opening hours before your visit to avoid disappointment',
        '📱 Consider downloading offline maps in case of poor signal', 
        '💧 Stay hydrated and bring water, especially during warmer weather',
      ];
    } finally {
      // Always remove from in-flight requests
      _inFlightRequests.remove(requestKey);
    }
  }

  Widget _buildReviews(Place place) {
    if (!_loadingReviews && _realReviews.isEmpty && !_hasAttemptedReviewFetch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_loadingReviews && _realReviews.isEmpty && !_hasAttemptedReviewFetch) {
          _fetchRealReviews(place);
        }
      });
    }
    final reviews = _realReviews;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '⭐ Reviews',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.amber,
                ),
                const SizedBox(width: 4),
                Text(
                  '${place.rating.toStringAsFixed(1)} (${reviews.length} reviews)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: reviews.map((review) => _buildReviewCard(review)).toList(),
        ),
        // View all reviews feature - coming soon (hidden for now)
        // const SizedBox(height: 12),
        // Center(
        //   child: TextButton(
        //     onPressed: () {
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         SnackBar(
        //           content: Text(
        //             'View all reviews feature coming soon!',
        //             style: GoogleFonts.poppins(),
        //           ),
        //           backgroundColor: const Color(0xFF12B347),
        //           behavior: SnackBarBehavior.floating,
        //         ),
        //       );
        //     },
        //     child: Text(
        //       'View all reviews',
        //       style: GoogleFonts.poppins(
        //         fontSize: 14,
        //         fontWeight: FontWeight.w500,
        //         color: const Color(0xFF12B347),
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF12B347).withOpacity(0.1),
                child: Text(
                  (review['author_name'] as String? ?? 'A')[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF12B347),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['author_name'] ?? 'Anonymous',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review['rating'] ? Icons.star : Icons.star_border,
                              size: 14,
                              color: Colors.amber,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          review['relative_time_description'] ?? 'Recently',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review['text'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Smart review fetching: Check cache first, then API with request deduplication
  Future<void> _fetchRealReviews(Place place) async {
    // Extract Google Place ID from place.id (format: "google_ChIJ...")
    String googlePlaceId = place.id;
    if (googlePlaceId.startsWith('google_')) {
      googlePlaceId = googlePlaceId.substring('google_'.length);
    }
    
    // Request deduplication: Check if request is already in flight
    final requestKey = 'reviews_$googlePlaceId';
    if (_inFlightRequests.contains(requestKey)) {
      if (kDebugMode) debugPrint('⏸️ Reviews request already in flight for: $googlePlaceId');
      return; // Request already in progress, don't start another one
    }
    
    if (_loadingReviews) return;
    
    // If we already have reviews, don't fetch again
    if (_realReviews.isNotEmpty) {
      if (kDebugMode) debugPrint('✅ Already have reviews cached in memory for: $googlePlaceId');
      return;
    }
    
    setState(() {
      _loadingReviews = true;
    });
    
    // Mark request as in-flight
    _inFlightRequests.add(requestKey);

    try {
      _hasAttemptedReviewFetch = true;
      final reviewsCache = ref.read(reviewsCacheServiceProvider);
      
      // Step 1: Check cache first
      final cachedReviews = await reviewsCache.getCachedReviews(googlePlaceId);
      if (cachedReviews != null && cachedReviews.isNotEmpty) {
        if (mounted) {
          setState(() {
            _realReviews = cachedReviews;
            _loadingReviews = false;
          });
          if (kDebugMode) {
            debugPrint('✅ Using cached reviews for place: $googlePlaceId (${cachedReviews.length} reviews)');
          }
        }
        _inFlightRequests.remove(requestKey);
        return; // Use cached reviews, no API call needed
      }
      
      // Step 2: Cache miss - fetch from API
      if (kDebugMode) {
        debugPrint('🔄 Cache miss - fetching reviews from API for: $googlePlaceId');
      }
      
      // Check if widget is still mounted before making API call
      if (!mounted) {
        _inFlightRequests.remove(requestKey);
        return;
      }
      
      final placesService = ref.read(placesServiceProvider.notifier);
      final details = await placesService.getPlaceDetails(googlePlaceId);
      
      // Check again after async operation
      if (!mounted) {
        _inFlightRequests.remove(requestKey);
        return;
      }
      
      // Step 3: Safely extract reviews with null safety
      List<Map<String, dynamic>> reviews = [];
      if (details.containsKey('reviews') && details['reviews'] != null) {
        final reviewsData = details['reviews'];
        if (reviewsData is List) {
          reviews = reviewsData
              .where((r) => r is Map<String, dynamic>)
              .cast<Map<String, dynamic>>()
              .toList();
        }
      }
      
      // Step 4: Cache the fetched reviews
      if (reviews.isNotEmpty) {
        await reviewsCache.cacheReviews(googlePlaceId, reviews);
      }
      
      if (mounted) {
        setState(() {
          _realReviews = reviews;
          _loadingReviews = false;
        });
        if (kDebugMode) {
          debugPrint('✅ Loaded ${reviews.length} real reviews from Google Places API and cached them');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching reviews: $e');
      }
      if (mounted) {
        setState(() {
          _realReviews = [];
          _loadingReviews = false;
        });
      }
    } finally {
      // Always remove from in-flight requests
      _inFlightRequests.remove(requestKey);
    }
  }

  Widget _buildPhotosTab(Place place) {
    if (place.photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No photos available',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: place.photos.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showFullScreenPhoto(place.photos, index, place.isAsset),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: place.isAsset
                ? Image.asset(
                    place.photos[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImageFallback(),
                  )
                : Image.network(
                    place.photos[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImageFallback(),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab(Place place) {
    if (!_loadingReviews && _realReviews.isEmpty && !_hasAttemptedReviewFetch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_loadingReviews && _realReviews.isEmpty && !_hasAttemptedReviewFetch) {
          _fetchRealReviews(place);
        }
      });
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviews header with rating summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '⭐ Reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (_realReviews.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    const DataSourceBadge(
                      source: DataSource.real,
                      tooltip: 'Real reviews from Google Places API',
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF12B347).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF12B347).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${place.rating.toStringAsFixed(1)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF12B347),
                      ),
                    ),
                    if (place.reviewCount > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${place.reviewCount} reviews)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const DataSourceBadge(
                        source: DataSource.real,
                        tooltip: 'Rating and review count from Google Places API',
                        size: 10,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Reviews list - show loading or real reviews
          if (_loadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_realReviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.reviews_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No reviews available',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reviews will appear here when available',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _realReviews.map((review) => _buildDetailedReviewCard(review)).toList(),
            ),
          
          const SizedBox(height: 16),
          
          // Add review button - coming soon (hidden for now)
          // SizedBox(
          //   width: double.infinity,
          //   child: OutlinedButton.icon(
          //     onPressed: () {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         SnackBar(
          //           content: Text(
          //             'Add review feature coming soon!',
          //             style: GoogleFonts.poppins(),
          //           ),
          //           backgroundColor: const Color(0xFF12B347),
          //           behavior: SnackBarBehavior.floating,
          //         ),
          //       );
          //     },
          //     icon: const Icon(Icons.add_comment),
          //     label: Text(
          //       'Add Your Review',
          //       style: GoogleFonts.poppins(
          //         fontSize: 14,
          //         fontWeight: FontWeight.w600,
          //       ),
          //     ),
          //     style: OutlinedButton.styleFrom(
          //       foregroundColor: const Color(0xFF12B347),
          //       side: const BorderSide(color: Color(0xFF12B347)),
          //       padding: const EdgeInsets.symmetric(vertical: 16),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(25),
          //       ),
          //     ),
          //   ),
          // ),
                ],
              ),
    );
  }

  Widget _buildDetailedReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
        color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF12B347).withOpacity(0.1),
                child: Text(
                  (review['author_name'] as String? ?? 'A')[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                      color: const Color(0xFF12B347),
                  ),
                ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['author_name'] ?? 'Anonymous',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review['rating'] ? Icons.star : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                Text(
                          review['relative_time_description'] ?? 'Recently',
                  style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                  ),
                ),
              ],
            ),
                  ],
                ),
              ),
            ],
                ),
          const SizedBox(height: 12),
          Text(
            review['text'] ?? '',
              style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton(Place place) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => _showBookingSheet(place),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF12B347),
                  Color(0xFF0D8A35),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF12B347).withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '✨ Book Your Adventure!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Place not found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  void _sharePlace(Place place) {
    Share.share(
      'Check out ${place.name} at ${place.address}. Rated ${place.rating}/5.0!',
      subject: 'Great place to visit!',
    );
  }

  void _showFullScreenPhoto(List<String> photos, int initialIndex, bool isAsset) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenPhotoView(
          photos: photos,
          initialIndex: initialIndex,
          isAsset: isAsset,
        ),
      ),
    );
  }

  void _openInMaps(Place place) async {
    try {
      final availableMaps = await MapLauncher.installedMaps;
      if (availableMaps.isNotEmpty) {
        await availableMaps.first.showMarker(
          coords: Coords(place.location.lat, place.location.lng),
          title: place.name,
          description: place.address,
        );
      } else {
        final url = 'https://www.google.com/maps/search/?api=1&query='
            '${place.location.lat},${place.location.lng}';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open maps: $e')),
        );
      }
    }
  }

  // Determine if a place should show booking options
  bool _isPlaceBookable(Place place) {
    debugPrint('🔍 Checking if place is bookable: ${place.name}');
    debugPrint('   - Types: ${place.types}');
    debugPrint('   - priceLevel: ${place.priceLevel}');
    debugPrint('   - isFree: ${place.isFree}');
    
    // First, exclude all free or walk-in attractions
    if (_isFreeWalkInPlace(place)) {
      debugPrint('   ❌ Place is free/walk-in, no booking needed');
      return false;
    }
    
    // Show booking for places that typically need reservations/tickets
    final bookableTypes = [
      // Food & Drink
      'restaurant',
      'cafe',
      'bar',
      // Wellness & Services
      'spa',
      'beauty_salon',
      'hair_care',
      'gym',
      // Accommodation
      'lodging',
      'hotel',
      // Entertainment
      'movie_theater',
      'night_club',
      'bowling_alley',
      // Attractions that require tickets/reservations
      'museum',
      'tourist_attraction',
      'amusement_park',
      'zoo',
      'aquarium',
      'art_gallery',
      'stadium',
      'theater',
      'opera_house',
      'concert_hall',
      // Tours & Activities
      'tour_operator',
      'travel_agency',
    ];
    
    // Check if place type matches bookable types
    final hasBookableType = place.types.any((type) => 
      bookableTypes.any((bookable) => 
        type.toLowerCase().contains(bookable.toLowerCase())
      )
    );
    
    // Also check activities for paid tour/ticket hints
    final hasBookableActivity = place.activities.any((activity) {
      final lowerActivity = activity.toLowerCase();
      return lowerActivity.contains('guided tour') ||
             lowerActivity.contains('reservation') ||
             lowerActivity.contains('booking required') ||
             lowerActivity.contains('ticket required');
    });
    
    // Show booking if:
    // 1. Has bookable type (restaurant, spa, hotel, museum, tourist_attraction, etc.)
    // 2. OR has paid/ticketed activities
    // 3. AND is not explicitly free (price level 0 or flagged as free)
    final isKnownFree = place.isFree;
    final hasCost = !isKnownFree && (place.priceLevel == null || place.priceLevel! > 0);
    
    final shouldShow = (hasBookableType || hasBookableActivity) && hasCost;
    
    debugPrint('   - hasBookableType: $hasBookableType');
    debugPrint('   - hasBookableActivity: $hasBookableActivity');
    debugPrint('   - hasCost: $hasCost');
    debugPrint('   ${shouldShow ? "✅" : "❌"} Should show booking: $shouldShow');
    
    return shouldShow;
  }
  
  // Helper to determine if a place is free/walk-in (no booking needed)
  bool _isFreeWalkInPlace(Place place) {
    // Explicitly free based on flag or price level
    if (place.isFree || place.priceLevel == 0) {
      return true;
    }
    
    // First, check if place has bookable types - if so, it's NOT free/walk-in
    final bookableTypes = [
      'restaurant', 'cafe', 'bar', 'spa', 'beauty_salon', 'hair_care',
      'lodging', 'hotel', 'gym', 'movie_theater', 'night_club', 'bowling_alley',
      'museum', 'tourist_attraction', 'amusement_park', 'zoo', 'aquarium',
      'art_gallery', 'stadium', 'theater', 'opera_house', 'concert_hall',
      'tour_operator', 'travel_agency', 'meal_takeaway', 'food',
    ];
    
    final hasBookableType = place.types.any((type) => 
      bookableTypes.any((bookable) => 
        type.toLowerCase().contains(bookable.toLowerCase())
      )
    );
    
    // If it has bookable types, it's NOT free/walk-in
    if (hasBookableType) {
      debugPrint('   ⚠️ Has bookable types (${place.types.where((t) => bookableTypes.any((bt) => t.toLowerCase().contains(bt.toLowerCase()))).toList()}), NOT free/walk-in');
      return false;
    }
    
    // Free types - public spaces, monuments, parks (ONLY if no bookable types)
    final freeWalkInTypes = [
      'park',
      'arboretum',        // Botanical gardens/arboretums
      'garden',           // Public gardens
      'botanical_garden', // Botanical gardens
      'natural_feature',
      'cemetery',
      'church',
      'mosque',
      'synagogue',
      'hindu_temple',
      'library',
      'public_square',
      'plaza',
      'beach',
      'hiking_area',
      'walking_street',
      'street',
      'route',
      'neighborhood',
      'locality',
      'viewpoint',        // Scenic viewpoints
      'monument',         // Public monuments
      // Removed 'point_of_interest' - too generic, many paid places have this
    ];
    
    // Check if place is a free type (and has no bookable types)
    final isFreeType = place.types.any((type) => 
      freeWalkInTypes.any((freeType) => 
        type.toLowerCase().contains(freeType.toLowerCase())
      )
    );
    
    return isFreeType;
  }

  /// Fetch place directly from Google Places API if not found in cache
  Future<Place> _fetchPlaceDirectly(String placeId) async {
    try {
      final placesService = ref.read(placesServiceProvider.notifier);
      final place = await placesService.getPlaceById(placeId);
      if (kDebugMode) debugPrint('✅ Successfully fetched place directly: ${place.name}');
      return place;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error fetching place directly: $e');
      rethrow;
    }
  }

  void _showBookingSheet(Place place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingBottomSheet(place: place),
    );
  }
}

// Full screen photo view widget
class FullScreenPhotoView extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  final bool isAsset;

  const FullScreenPhotoView({
    Key? key,
    required this.photos,
    required this.initialIndex,
    required this.isAsset,
  }) : super(key: key);

  @override
  State<FullScreenPhotoView> createState() => _FullScreenPhotoViewState();
}

class _FullScreenPhotoViewState extends State<FullScreenPhotoView> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} of ${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: widget.isAsset
                  ? Image.asset(
                      widget.photos[index],
                      fit: BoxFit.contain,
                    )
                  : Image.network(
                      widget.photos[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.error,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
} 