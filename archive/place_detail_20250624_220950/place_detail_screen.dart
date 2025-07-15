import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' as ui;
import 'package:wandermood/core/theme/app_theme.dart';
import '../../models/place.dart';
import '../../providers/place_detail_provider.dart';
import '../widgets/booking_section.dart';
import '../widgets/expanded_image_view.dart';
import '../widgets/place_image.dart';

class PlaceDetailScreen extends ConsumerStatefulWidget {
  final String placeId;

  const PlaceDetailScreen({required this.placeId, Key? key}) : super(key: key);

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, animationDuration: const Duration(milliseconds: 300));
    _tabController.addListener(_handleTabChange);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      HapticFeedback.selectionClick();
    }
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showAppBarTitle) {
      setState(() {
        _showAppBarTitle = true;
      });
    } else if (_scrollController.offset <= 200 && _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = false;
      });
    }
  }

  void _toggleFavorite() {
    HapticFeedback.lightImpact();
    setState(() {
      _isFavorite = !_isFavorite;
    });
    // TODO: Save favorite status to user preferences
  }

  void _sharePlace(Place place) {
    Share.share(
      'Check out ${place.name} in ${place.address}!',
      subject: 'Discover ${place.name}',
    );
  }

  Future<void> _openMaps(Place place) async {
    try {
      final availableMaps = await MapLauncher.installedMaps;
      if (availableMaps.isNotEmpty) {
        await availableMaps.first.showMarker(
          coords: Coords(place.location.lat, place.location.lng),
          title: place.name,
        );
      }
    } catch (e) {
      debugPrint('Error opening maps: $e');
      // Fallback to Google Maps URL
      final url = 'https://www.google.com/maps/search/?api=1&query=${place.location.lat},${place.location.lng}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeAsync = ref.watch(placeDetailProvider(widget.placeId));

    return Container(
      decoration: AppTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: placeAsync.when(
          data: (place) {
            return NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 320,
                    floating: false,
                    pinned: true,
                    backgroundColor: _showAppBarTitle 
                      ? Colors.transparent // Make transparent to show gradient below
                      : Colors.transparent,
                    elevation: _showAppBarTitle ? 1 : 0,
                    title: null,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                      onPressed: () => context.pop(),
                    ),
                    actions: [
                      Material(
                        color: Colors.transparent,
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? Colors.redAccent : Colors.grey.shade700,
                              size: 22,
                            ),
                            onPressed: _toggleFavorite,
                            splashRadius: 24,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: Container(
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.share_rounded,
                              color: Colors.grey.shade700,
                              size: 22,
                            ),
                            onPressed: () => _sharePlace(place),
                            splashRadius: 24,
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: Stack(
                      children: [
                        // Add gradient background that matches app background when collapsed
                        AnimatedOpacity(
                          opacity: _showAppBarTitle ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFFFAFF4),  // Top color - matches app theme
                                  Color(0xFFFFDBD4),  // Middle color for smooth transition
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Existing FlexibleSpaceBar
                        FlexibleSpaceBar(
                          title: _showAppBarTitle 
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Text(
                                      place.name,
                                      style: GoogleFonts.poppins(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                          titlePadding: const EdgeInsets.only(left: 54, bottom: 16, right: 100),
                          background: Stack(
                            fit: StackFit.expand,
                            children: [
                              PlaceImage(
                                imageUrl: place.photos.isNotEmpty 
                                  ? place.photos.first 
                                  : 'assets/images/qr_placeholder.png',
                                height: 320,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.zero,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.4),
                                    ],
                                  ),
                                ),
                              ),
                              // Place name and rating at the bottom
                              Positioned(
                                bottom: 20,
                                left: 16,
                                right: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.6),
                                            offset: const Offset(0, 1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ).animate().fade(duration: const Duration(milliseconds: 500)).slideY(begin: 0.2, end: 0),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Color(0xFFFFD700),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          place.rating.toString(),
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (place.tag != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              place.tag!,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ).animate().fade(duration: const Duration(milliseconds: 500), delay: const Duration(milliseconds: 100)).slideY(begin: 0.2, end: 0),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          color: Colors.white.withOpacity(0.9),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          place.address,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ).animate().fade(duration: const Duration(milliseconds: 500), delay: const Duration(milliseconds: 150)).slideY(begin: 0.2, end: 0),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: 16), // Add extra space
                  ),
                  SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: const Color(0xFF12B347),
                        labelColor: const Color(0xFF12B347),
                        unselectedLabelColor: Colors.grey,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        unselectedLabelStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        splashBorderRadius: BorderRadius.circular(24),
                        overlayColor: MaterialStateProperty.all(
                          const Color(0xFF12B347).withOpacity(0.1),
                        ),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                        indicator: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: const Color(0xFF12B347),
                              width: 3.0,
                            ),
                          ),
                        ),
                        tabs: [
                          AnimatedBuilder(
                            animation: _tabController,
                            builder: (context, child) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                transform: Matrix4.identity()..scale(_tabController.index == 0 ? 1.05 : 1.0),
                                child: Tab(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('📋', style: TextStyle(fontSize: 18)),
                                      const SizedBox(width: 6),
                                      Text('Details'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          AnimatedBuilder(
                            animation: _tabController,
                            builder: (context, child) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                transform: Matrix4.identity()..scale(_tabController.index == 1 ? 1.05 : 1.0),
                                child: Tab(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('📸', style: TextStyle(fontSize: 18)),
                                      const SizedBox(width: 6),
                                      Text('Photos'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          AnimatedBuilder(
                            animation: _tabController,
                            builder: (context, child) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                transform: Matrix4.identity()..scale(_tabController.index == 2 ? 1.05 : 1.0),
                                child: Tab(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('🗺️', style: TextStyle(fontSize: 18)),
                                      const SizedBox(width: 6),
                                      Text('Map'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    pinned: true,
                    floating: true,
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  // Details Tab
                  _buildDetailsTab(place).animate().fadeIn(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  ),
                  
                  // Photos Tab
                  _buildPhotosTab(place).animate().fadeIn(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  ),
                  
                  // Map Tab
                  _buildMapTab(place).animate().fadeIn(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  ),
                ],
              ),
            ).animate().fade();
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF12B347),
            ),
          ),
          error: (error, stackTrace) => Center(
            child: Text(
              'Error loading place: $error',
              style: GoogleFonts.poppins(
                color: AppTheme.error,
              ),
            ),
          ),
        ),
        bottomNavigationBar: placeAsync.maybeWhen(
          data: (place) => BookingSection(place: place),
          orElse: () => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildDetailsTab(Place place) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (place.description != null) ...[
            Text(
              'About',
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              place.description!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Address
          Text(
            'Location',
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _openMaps(place),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF12B347)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      place.address,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const Icon(Icons.navigate_next, color: Color(0xFF12B347)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Activities
          if (place.activities.isNotEmpty) ...[
            Text(
              'Activities',
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: place.activities.map((activity) {
                  // Add emoji based on activity type
                  String emoji = _getEmojiForActivity(activity);
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Text(
                        emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                      label: Text(
                        activity,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: const Color(0xFF12B347).withOpacity(0.3)),
                        backgroundColor: const Color(0xFF12B347).withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Opening Hours (dummy data)
          Text(
            'Opening Hours',
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              _buildOpeningHours('Monday - Friday', '9:00 AM - 9:00 PM'),
              _buildOpeningHours('Saturday', '10:00 AM - 10:00 PM'),
              _buildOpeningHours('Sunday', '11:00 AM - 8:00 PM'),
            ],
          ),
          const SizedBox(height: 24),

          // Reviews (dummy data)
          Text(
            'Reviews',
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
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
              children: [
                _buildReviewItem(
                  'Alex Johnson',
                  4.5,
                  'Great place! We had an amazing time exploring the area and trying the local food.',
                  '2 days ago',
                ),
                const Divider(),
                _buildReviewItem(
                  'Maria Garcia',
                  5.0,
                  'One of the best attractions in Rotterdam. Highly recommended for families!',
                  '1 week ago',
                ),
                const Divider(),
                _buildReviewItem(
                  'Thomas Weber',
                  3.5,
                  'Interesting place but a bit crowded. Try to visit early in the morning.',
                  '3 weeks ago',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Similar Places
          Text(
            'Similar Places',
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildSimilarPlaceCard(
                  'Rotterdam Zoo',
                  'assets/images/shifaaz-shamoon-qtbV_8P_Ksk-unsplash.jpg',
                  'zoo',
                ),
                _buildSimilarPlaceCard(
                  'Kunsthal',
                  'assets/images/pietro-de-grandi-T7K4aEPoGGk-unsplash.jpg',
                  'kunsthal',
                ),
                _buildSimilarPlaceCard(
                  'Erasmusbrug',
                  'assets/images/tom-podmore-3mEK924ZuTs-unsplash.jpg',
                  'erasmusbrug',
                ),
              ],
            ),
          ),
          const SizedBox(height: 50), // Extra space for bottom bar
        ],
      ),
    );
  }

  Widget _buildOpeningHours(String days, String hours) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            days,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            hours,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: const Color(0xFF12B347),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(
      String name, double rating, String comment, String timeAgo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Color(0xFFFFD700),
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating.toString(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeAgo,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarPlaceCard(String name, String image, String id) {
    return GestureDetector(
      onTap: () {
        // Navigate to the selected place
        if (id != widget.placeId) {
          context.push('/place/$id');
        }
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Image with enhanced brightness like in Explore screen
              ColorFiltered(
                colorFilter: ColorFilter.matrix([
                  1.2, 0, 0, 0, 0.1, // Red channel
                  0, 1.2, 0, 0, 0.1, // Green channel
                  0, 0, 1.2, 0, 0.1, // Blue channel
                  0, 0, 0, 1, 0, // Alpha channel
                ]),
                child: Image.asset(
                  image,
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              // Gradient overlay
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
              // Place name at the bottom
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Rotterdam',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildPhotosTab(Place place) {
    // If there are no additional photos, use a list with the main photo
    final photos = place.photos.isNotEmpty
        ? place.photos
        : ['assets/images/placeholder.jpg'];

    // Add some dummy photos
    final allPhotos = [
      ...photos,
      'assets/images/pietro-de-grandi-T7K4aEPoGGk-unsplash.jpg',
      'assets/images/tom-podmore-3mEK924ZuTs-unsplash.jpg',
      'assets/images/shifaaz-shamoon-qtbV_8P_Ksk-unsplash.jpg',
      'assets/images/diego-jimenez-A-NVHPka9Rk-unsplash.jpg',
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: allPhotos.length,
        itemBuilder: (context, index) {
          final imageAsset = allPhotos[index];

          return GestureDetector(
            onTap: () {
              // Show full-screen image
              _showExpandedImage(context, imageAsset, index, allPhotos);
            },
            child: Hero(
              tag: 'photo_$index',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix([
                    1.1, 0, 0, 0, 0.1, // Red channel
                    0, 1.1, 0, 0, 0.1, // Green channel
                    0, 0, 1.1, 0, 0.1, // Blue channel
                    0, 0, 0, 1, 0, // Alpha channel
                  ]),
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showExpandedImage(BuildContext context, String imageAsset, int index, List<String> allPhotos) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) {
          return ExpandedImageView(
            imageAsset: imageAsset,
            tag: 'photo_$index',
            allPhotos: allPhotos,
            initialIndex: index,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildMapTab(Place place) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.map,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Map will be displayed here',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'In the full version, you would see an interactive map showing ${place.name}',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _openMaps(place),
            icon: const Icon(Icons.directions),
            label: Text(
              'Get Directions',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF12B347),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  String _getEmojiForActivity(String activity) {
    // Map activities to appropriate emojis
    switch (activity.toLowerCase()) {
      case 'food tour':
        return '🍽️';
      case 'shopping':
        return '🛍️';
      case 'architecture':
        return '🏛️';
      case 'hiking':
        return '🥾';
      case 'beach':
        return '🏖️';
      case 'city':
        return '🏙️';
      case 'nature':
        return '🌿';
      case 'food':
        return '🍴';
      case 'art':
        return '🎨';
      case 'history':
        return '🏛️';
      case 'adventure':
        return '🤩';
      case 'relaxation':
        return '🧘';
      case 'cultural':
        return '🎭';
      case 'sports':
        return '⚽';
      case 'family':
        return '👨‍👩‍👧‍👦';
      case 'romantic':
        return '💑';
      case 'solo':
        return '🧳';
      case 'local':
        return '🏠';
      case 'international':
        return '✈️';
      case 'nightlife':
        return '🌃';
      case 'museum':
        return '🖼️';
      case 'park':
        return '🌳';
      case 'market':
        return '🛒';
      case 'street food':
        return '🥘';
      case 'tour':
        return '🧭';
      case 'landmark':
        return '🗿';
      default:
        // If no specific emoji is found, return a generic one
        return '✨';
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 20;

  @override
  double get maxExtent => tabBar.preferredSize.height + 20;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Calculate opacity based on shrink offset for blur effect
    final opacity = shrinkOffset / maxExtent;
    final blurValue = (opacity * 15).clamp(5.0, 15.0);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: blurValue,
            sigmaY: blurValue,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.6),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: TabBar(
              controller: tabBar.controller,
              indicatorColor: const Color(0xFF12B347),
              labelColor: const Color(0xFF12B347),
              unselectedLabelColor: Colors.grey.shade600,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              splashBorderRadius: BorderRadius.circular(24),
              overlayColor: MaterialStateProperty.all(
                const Color(0xFF12B347).withOpacity(0.1),
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              indicator: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF12B347),
                    width: 3.0,
                  ),
                ),
              ),
              tabs: [
                AnimatedBuilder(
                  animation: tabBar.controller!,
                  builder: (context, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()..scale(tabBar.controller!.index == 0 ? 1.05 : 1.0),
                      child: Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('📋', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text('Details'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: tabBar.controller!,
                  builder: (context, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()..scale(tabBar.controller!.index == 1 ? 1.05 : 1.0),
                      child: Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('📸', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text('Photos'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: tabBar.controller!,
                  builder: (context, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()..scale(tabBar.controller!.index == 2 ? 1.05 : 1.0),
                      child: Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🗺️', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text('Map'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return true;
  }
} 