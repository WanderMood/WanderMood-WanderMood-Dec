import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> activity;
  final Function(String) onAddToPlanner;

  const ActivityDetailsScreen({
    super.key,
    required this.activity,
    required this.onAddToPlanner,
  });

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarExpanded = false;
  final PageController _imagePreviewController = PageController();
  
  // Sample gallery images - in production, these would come from the activity data
  final List<String> galleryImages = [
    'https://images.unsplash.com/photo-1577720580479-7d839d829c73',
    'https://images.unsplash.com/photo-1578301978693-85fa9c0320b9',
    'https://images.unsplash.com/photo-1577720580018-92a6e816d112',
    'https://images.unsplash.com/photo-1577720580157-bc85140d6e3f',
    'https://images.unsplash.com/photo-1577720580793-7fbc78a15b9f',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _imagePreviewController.dispose();
    super.dispose();
  }

  String _heroImageSrc(Map<String, dynamic> activity) {
    final raw = activity['image']?.toString() ?? '';
    if (raw.isEmpty) return '';
    if (isGooglePlacePhotoHttpUrl(raw)) return raw;
    return raw.contains('?') ? raw : '$raw?auto=format&fit=crop&w=1000&q=80';
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      if (_scrollController.offset > 200 && !_isAppBarExpanded) {
        setState(() => _isAppBarExpanded = true);
      } else if (_scrollController.offset <= 200 && _isAppBarExpanded) {
        setState(() => _isAppBarExpanded = false);
      }
    }
  }

  void _showImagePreview(int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black.withOpacity(0.9),
        child: Stack(
          children: [
            // Image carousel
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: galleryImages.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: Hero(
                      tag: 'gallery_image_$index',
                      child: WmNetworkImage(
                        '${galleryImages[index]}?auto=format&fit=crop&w=2000&q=90',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gallery',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: galleryImages.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImagePreview(index),
                child: Container(
                  width: 140,
                  margin: EdgeInsets.only(
                    right: 12,
                    left: index == 0 ? 0 : 0,
                  ),
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
                  child: Hero(
                    tag: 'gallery_image_$index',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: WmNetworkImage(
                        '${galleryImages[index]}?auto=format&fit=crop&w=300&h=200&q=80',
                        fit: BoxFit.cover,
                        progressIndicatorBuilder: (context, url, progress) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.progress,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.grey[400]!,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(
                duration: 400.ms,
                delay: (100 * index).ms,
              ).slideX(
                begin: 0.2,
                end: 0,
                duration: 400.ms,
                delay: (100 * index).ms,
                curve: Curves.easeOut,
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final isAddedToPlan = false; // This should come from your state management

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7BE495), // Vibrant mint green
              Color(0xFF329D9C), // Teal
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background swirl effect
            Positioned.fill(
              child: CustomPaint(
                painter: SwirlingGradientPainter(),
              ),
            ),
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Expandable app bar with hero image
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Hero image (Google Place vs Unsplash — do not append Unsplash params to Google URLs)
                        WmPlaceOrHttpsNetworkImage(
                          _heroImageSrc(activity),
                          fit: BoxFit.cover,
                        ),
                        // Gradient overlay
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
                        // Activity name and rating
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity['name'],
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 16,
                                          color: Color(0xFFFFC107),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${activity['rating']}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.schedule,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${activity['duration']} min',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    // Share button
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.share, color: Colors.white),
                      ),
                      onPressed: () {
                        // Implement share functionality
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                // Activity details
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A6049).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Color(0xFF2A6049),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start Time',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _formatTime(DateTime.parse(activity['startTime'])),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2A6049),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 24),
                              const Icon(
                                Icons.timelapse,
                                color: Color(0xFF2A6049),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Duration',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${activity['duration']} min',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2A6049),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // About section
                        Text(
                          'About',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activity['description'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Features section
                        Text(
                          'Features',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Activity tags
                            ...(activity['tags'] as List).map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A6049).withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF2A6049),
                                    width: 0.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2A6049).withOpacity(0.2),
                                      spreadRadius: 0,
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  tag,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF2A6049),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }),
                            
                            // Dietary tags
                            if (activity['dietaryOptions'] != null) ...[
                              ...(activity['dietaryOptions'] as List).map((option) {
                                IconData getIcon() {
                                  switch (option) {
                                    case 'halal':
                                      return Icons.restaurant;
                                    case 'kosher':
                                      return Icons.restaurant_menu;
                                    case 'vegetarian':
                                      return Icons.eco;
                                    case 'vegan':
                                      return Icons.grass;
                                    case 'glutenFree':
                                      return Icons.no_food;
                                    default:
                                      return Icons.restaurant;
                                  }
                                }

                                String getLabel() {
                                  switch (option) {
                                    case 'halal':
                                      return 'Halal';
                                    case 'kosher':
                                      return 'Kosher';
                                    case 'vegetarian':
                                      return 'Vegetarian';
                                    case 'vegan':
                                      return 'Vegan';
                                    case 'glutenFree':
                                      return 'Gluten-Free';
                                    default:
                                      return option;
                                  }
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9).withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF2E7D32),
                                      width: 0.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2E7D32).withOpacity(0.2),
                                        spreadRadius: 0,
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        getIcon(),
                                        size: 16,
                                        color: const Color(0xFF2E7D32),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        getLabel(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: const Color(0xFF2E7D32),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],

                            // Inclusivity tags
                            if (activity['inclusivityTags'] != null) ...[
                              ...(activity['inclusivityTags'] as List).map((tag) {
                                IconData getIcon() {
                                  switch (tag) {
                                    case 'lgbtqFriendly':
                                      return Icons.favorite;
                                    case 'wheelchairAccessible':
                                      return Icons.accessible;
                                    case 'familyFriendly':
                                      return Icons.family_restroom;
                                    case 'petFriendly':
                                      return Icons.pets;
                                    default:
                                      return Icons.info_outline;
                                  }
                                }

                                String getLabel() {
                                  switch (tag) {
                                    case 'lgbtqFriendly':
                                      return 'LGBTQ+ Friendly';
                                    case 'wheelchairAccessible':
                                      return 'Wheelchair Accessible';
                                    case 'familyFriendly':
                                      return 'Family Friendly';
                                    case 'petFriendly':
                                      return 'Pet Friendly';
                                    default:
                                      return tag;
                                  }
                                }

                                Color getColor() {
                                  switch (tag) {
                                    case 'lgbtqFriendly':
                                      return const Color(0xFF9C27B0);  // Purple
                                    case 'wheelchairAccessible':
                                      return const Color(0xFF1976D2);  // Blue
                                    case 'familyFriendly':
                                      return const Color(0xFF00897B);  // Teal
                                    case 'petFriendly':
                                      return const Color(0xFF5D4037);  // Brown
                                    default:
                                      return Colors.grey;
                                  }
                                }

                                final color = getColor();
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: color,
                                      width: 0.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.2),
                                        spreadRadius: 0,
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        getIcon(),
                                        size: 16,
                                        color: color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        getLabel(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),

                        const SizedBox(height: 24),
                        
                        // Booking Information Section
                        Text(
                          'Booking Information',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (activity['isPaid'] == true || (activity['price'] != null && activity['price'].toString() != '0')) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCE8C3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Ticket Required',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFEB9C00),
                                  ),
                                ),
                              ),
                            ] else if (_isRestaurantActivity(activity)) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Reservation Required',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF2196F3),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Free Activity',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF66BB6A),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 12),
                            if (activity['price'] != null && activity['price'].toString() != '0') ...[
                              Text(
                                '€${activity['price']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2A6049),
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        const SizedBox(height: 24),

                        // Location section
                        Text(
                          'Location',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Map will be displayed here',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Reviews section
                        if (activity['reviews'] != null) ...[
                          Text(
                            'Reviews',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...(activity['reviews'] as List).map((review) =>
                            _buildReviewCard(
                              name: review['name'],
                              rating: review['rating'].toDouble(),
                              comment: review['comment'],
                              date: review['date'],
                            ),
                          ).toList(),
                          const SizedBox(height: 24),
                        ],

                        // Gallery section
                        _buildGallerySection(),

                        // Add space for bottom button
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      // Bottom action button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => widget.onAddToPlanner(activity['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAddedToPlan ? Colors.grey[300] : const Color(0xFF2A6049),
                  foregroundColor: isAddedToPlan ? Colors.grey[700] : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAddedToPlan ? Icons.check : Icons.add,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAddedToPlan ? 'Added to Plan' : 'Add to Plan',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard({
    required String name,
    required double rating,
    required String comment,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    size: 16,
                    color: Color(0xFFFFC107),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to check if an activity is restaurant-related
  bool _isRestaurantActivity(Map<String, dynamic> activity) {
    final String name = (activity['name'] ?? '').toString().toLowerCase();
    final String type = (activity['type'] ?? '').toString().toLowerCase();
    final String category = (activity['category'] ?? '').toString().toLowerCase();
    final List<dynamic> tags = activity['tags'] ?? [];
    
    return type.contains('restaurant') ||
           type.contains('dining') ||
           category.contains('restaurant') ||
           category.contains('dining') ||
           name.contains('restaurant') ||
           name.contains('dining') ||
           tags.any((tag) => 
             tag.toString().toLowerCase().contains('restaurant') ||
             tag.toString().toLowerCase().contains('dining') ||
             tag.toString().toLowerCase().contains('food')
           );
  }

  String _formatTime(dynamic time) {
    if (time is DateTime) {
      final String period = time.hour >= 12 ? 'PM' : 'AM';
      final int hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
      final String minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute $period';
    } else if (time is String) {
      // If it's already a formatted string, just return it
      return time;
    }
    return 'Time not available';
  }
} 