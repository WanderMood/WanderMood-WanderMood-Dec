import 'package:flutter/material.dart';
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
import 'package:wandermood/features/places/providers/saved_places_provider.dart';
import 'package:wandermood/features/places/presentation/widgets/booking_bottom_sheet.dart';
import 'package:wandermood/core/services/moody_ai_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(explorePlacesProvider());
    
    return Container(
      decoration: AppTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: placesAsync.when(
          data: (places) {
            final place = places.firstWhere(
              (p) => p.id == widget.placeId,
              orElse: () => throw Exception('Place not found'),
            );
            
            return _buildPlaceDetail(place);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
            ),
          ),
          error: (error, stack) => _buildErrorState(error),
        ),
        bottomNavigationBar: placesAsync.maybeWhen(
          data: (places) {
            try {
              final place = places.firstWhere((p) => p.id == widget.placeId);
              return _buildBookingButton(place);
            } catch (e) {
              return const SizedBox.shrink();
            }
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildPlaceDetail(Place place) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(place),
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildTabBar(),
                _buildTabContent(place),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(Place place) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _sharePlace(place),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Consumer(
            builder: (context, ref, child) {
              final savedPlacesAsync = ref.watch(savedPlacesProvider);
              
              return savedPlacesAsync.when(
                data: (savedPlaces) {
                  final isSaved = savedPlaces.contains(place);
                  
                  return IconButton(
                    icon: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved ? Colors.red : Colors.white,
                    ),
                    onPressed: () {
                      ref.read(savedPlacesProvider.notifier).toggleSave(place);
                      HapticFeedback.lightImpact();
                    },
                  );
                },
                loading: () => IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: () {},
                ),
                error: (_, __) => IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: () {},
                ),
              );
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildPhotoCarousel(place),
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
              // Place name
              Row(
                children: [
                  Expanded(
                    child: Text(
                      place.name,
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
              const SizedBox(height: 8),
              // Address
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      place.address,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25), // More pill-like shape
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        indicator: BoxDecoration(
          color: const Color(0xFF12B347),
          borderRadius: BorderRadius.circular(25), // Pill-shaped indicator
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Details'),
          Tab(text: 'Photos'),
          Tab(text: 'Location'),
        ],
      ),
    );
  }

  Widget _buildTabContent(Place place) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6, // Dynamic height based on screen
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDetailsTab(place),
            _buildPhotosTab(place),
            _buildLocationTab(place),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab(Place place) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📍 About this place',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            place.description ?? 
            'A wonderful place to visit with great atmosphere and excellent service. '
            'Perfect for ${place.activities.isNotEmpty ? place.activities.join(', ').toLowerCase() : 'spending time'}.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 24),
          if (place.openingHours != null) ...[
            Text(
              '🕐 Opening Hours',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: place.openingHours!.isOpen
                              ? const Color(0xFF12B347)
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        place.openingHours!.isOpen ? 'Open now' : 'Closed',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: place.openingHours!.isOpen
                              ? const Color(0xFF12B347)
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (place.openingHours!.currentStatus != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      place.openingHours!.currentStatus!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            '✨ Features',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildColorfulFeatureChip(
                place.isIndoor ? '🏠' : '☀️',
                place.isIndoor ? 'Indoor' : 'Outdoor',
                place.isIndoor ? Colors.purple : Colors.orange,
              ),
              _buildColorfulFeatureChip(
                _getEnergyEmoji(place.energyLevel),
                '${place.energyLevel} Energy',
                _getEnergyColor(place.energyLevel),
              ),
              if (place.types.isNotEmpty)
                _buildColorfulFeatureChip(
                  _getCategoryEmoji(place.types.first),
                  place.types.first.replaceAll('_', ' ').toUpperCase(),
                  _getCategoryColor(place.types.first),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _buildImageCarousel(place),
          const SizedBox(height: 24),
          _buildMoodyTips(place),
          const SizedBox(height: 24),
          _buildReviews(place),
        ],
      ),
    );
  }

  Widget _buildColorfulFeatureChip(String emoji, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
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

  Widget _buildImageCarousel(Place place) {
    // Sample additional images for the carousel
    final carouselImages = [
      ...place.photos,
      'assets/images/fallbacks/default.jpg',
      'assets/images/fallbacks/default_place.jpg',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📸 Gallery',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: carouselImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.only(
                  right: index == carouselImages.length - 1 ? 0 : 12,
                ),
                child: GestureDetector(
                  onTap: () => _showFullScreenPhoto(carouselImages, index, place.isAsset),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                      ),
                      child: place.isAsset
                          ? Image.asset(
                              carouselImages[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildImageFallback(),
                            )
                          : Image.network(
                              carouselImages[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildImageFallback(),
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
  }

  Widget _buildMoodyTips(Place place) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF12B347),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.lightbulb,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '💡 Moody Tips',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF12B347).withOpacity(0.05),
                const Color(0xFF12B347).withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF12B347).withOpacity(0.2),
            ),
          ),
          child: FutureBuilder<List<String>>(
            future: _generateAIMoodyTips(place),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF12B347),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '🤖 Moody is thinking of personalized tips for you...',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              
              final moodyTips = snapshot.data ?? [
                '🕐 Check opening hours before your visit to avoid disappointment',
                '📱 Consider downloading offline maps in case of poor signal',
                '💧 Stay hydrated and bring water, especially during warmer weather',
              ];
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: moodyTips.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tip = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == moodyTips.length - 1 ? 0 : 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF12B347),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tip,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Generate AI-powered Moody Tips for the place
  Future<List<String>> _generateAIMoodyTips(Place place) async {
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
      
      return tips;
    } catch (e) {
      debugPrint('❌ Error generating AI Moody Tips: $e');
      // Return basic fallback tips in case of complete failure
      return [
        '🕐 Check opening hours before your visit to avoid disappointment',
        '📱 Consider downloading offline maps in case of poor signal', 
        '💧 Stay hydrated and bring water, especially during warmer weather',
      ];
    }
  }

  Widget _buildReviews(Place place) {
    final reviews = _generateSampleReviews(place);
    
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
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'View all reviews feature coming soon!',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: const Color(0xFF12B347),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'View all reviews',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF12B347),
              ),
            ),
          ),
        ),
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
                  review['name'][0].toUpperCase(),
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
                      review['name'],
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
                          review['date'],
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
            review['comment'],
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

  List<Map<String, dynamic>> _generateSampleReviews(Place place) {
    final baseReviews = [
      {
        'name': 'Emma Johnson',
        'rating': 5,
        'date': '2 days ago',
        'comment': '🤩 Absolutely amazing experience! The atmosphere was perfect and the staff was incredibly friendly. 📸 Highly recommend visiting during the golden hour for the best photos!',
      },
      {
        'name': 'Michael Chen',
        'rating': 4,
        'date': '1 week ago',
        'comment': '👍 Great place to spend an afternoon. Well-maintained and lots to see. ⚠️ The only downside was it got quite crowded around lunchtime, so plan accordingly.',
      },
      {
        'name': 'Sarah Williams',
        'rating': 5,
        'date': '2 weeks ago',
        'comment': '✨ This place exceeded all my expectations! Perfect for ${place.activities.isNotEmpty ? place.activities.first.toLowerCase() : 'a day out'}. 👯‍♀️ Will definitely be coming back with friends!',
      },
    ];
    
    return baseReviews;
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

  Widget _buildLocationTab(Place place) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📍 Location',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Interactive Map Container
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Interactive map placeholder (will open external maps on tap)
                  GestureDetector(
                    onTap: () => _openInMaps(place),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF12B347).withOpacity(0.2),
                            const Color(0xFF12B347).withOpacity(0.4),
                          ],
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF12B347),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Tap to open in Maps',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Address Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: const Color(0xFF12B347),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Address',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  place.address,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Directions Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openInMaps(place),
              icon: const Icon(Icons.directions),
              label: Text(
                'Get Directions',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF12B347),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25), // Pill-shaped button
                ),
                elevation: 2,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Coordinates (for development/debug)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              '🧭 Coordinates: ${place.location.lat.toStringAsFixed(6)}, ${place.location.lng.toStringAsFixed(6)}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton(Place place) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showBookingSheet(place),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF12B347),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25), // Pill-shaped button
            ),
            elevation: 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 20),
              const SizedBox(width: 8),
              Text(
                'Book Now',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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