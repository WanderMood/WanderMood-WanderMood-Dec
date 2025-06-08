import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/providers/explore_places_provider.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/plans/widgets/activity_detail_screen.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/plans/domain/enums/time_slot.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

// Mock data for friends and social features
final mockFriends = [
  {'name': 'Emma', 'avatar': '👩‍🦰', 'visitedCount': 12},
  {'name': 'Liam', 'avatar': '👨‍🦱', 'visitedCount': 8},
  {'name': 'Sofia', 'avatar': '👩‍🦳', 'visitedCount': 15},
  {'name': 'Noah', 'avatar': '👨‍🦲', 'visitedCount': 6},
];

final mockFunFacts = [
  "🏛️ Rotterdam has more museums per square kilometer than any other Dutch city!",
  "🌉 The Erasmus Bridge is nicknamed 'The Swan' by locals",
  "🏗️ Rotterdam was completely rebuilt after WWII, making it Europe's most modern city center",
  "🚢 Rotterdam's port is the largest in Europe",
  "🎨 Over 600 pieces of street art can be found throughout the city",
  "🏢 Rotterdam has more skyscrapers than any other city in the Netherlands",
];

class FreeTimeActivitiesScreen extends ConsumerStatefulWidget {
  const FreeTimeActivitiesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FreeTimeActivitiesScreen> createState() => _FreeTimeActivitiesScreenState();
}

class _FreeTimeActivitiesScreenState extends ConsumerState<FreeTimeActivitiesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentFactIndex = 0;
  bool _showFunFact = true;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Museums', 'Food', 'Nature', 'Culture', 'Entertainment'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cycleFunFacts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _cycleFunFacts() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentFactIndex = (_currentFactIndex + 1) % mockFunFacts.length;
        });
        _cycleFunFacts();
      }
    });
  }

  List<Place> _getFilteredPlaces(List<Place> places) {
    if (_selectedCategory == 'All') return places;
    
    return places.where((place) {
      switch (_selectedCategory) {
        case 'Museums':
          return place.types.contains('museum') || place.types.contains('art');
        case 'Food':
          return place.types.contains('restaurant') || place.types.contains('cafe');
        case 'Nature':
          return place.types.contains('park') || place.types.contains('nature');
        case 'Culture':
          return place.types.contains('cultural') || place.types.contains('tourist_attraction');
        case 'Entertainment':
          return place.types.contains('entertainment') || place.types.contains('amusement');
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // 🚨 OPTIMIZATION: Only watch provider once, cache result
    final placesAsync = ref.watch(explorePlacesProvider(city: 'Rotterdam'));
    
    return Scaffold(
              body: Stack(
          children: [
            // Brown-beige gradient covering ENTIRE top area
            Container(
              height: 280, // Fixed height to cover top area generously
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8B7355), Color(0xFFA0956B)], // Elegant brown-to-beige
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
            
            // 🎨 Add beautiful beige swirl background for content area only
            Positioned(
              top: 350, // Position much lower to avoid header interference
              left: 0,
              right: 0,
              bottom: 0,
              child: const SwirlBackground(
                child: SizedBox.expand(),
              ),
            ),
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Header content (over the gradient)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      children: [
                        // Header with back button
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                'Free Time Explorer',
                                style: GoogleFonts.museoModerno(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share, color: Colors.white),
                              onPressed: () {
                                // Share functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sharing your discoveries! 📱')),
                                );
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Stats cards
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('🎯', 'Discovered', '24', Colors.white.withOpacity(0.2))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('👥', 'Friends Here', '${mockFriends.length}', Colors.white.withOpacity(0.2))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('⭐', 'Avg Rating', '4.6', Colors.white.withOpacity(0.2))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Content area with white background
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                // Fun Fact Banner
            if (_showFunFact)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE4B5), Color(0xFFFFD700)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Did you know?',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[800],
                            ),
                          ),
                          Text(
                            mockFunFacts[_currentFactIndex],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.orange[800], size: 20),
                      onPressed: () => setState(() => _showFunFact = false),
                    ),
                  ],
                ),
              ).animate()
                .slideX(begin: 0.3, duration: 600.ms)
                .fadeIn(duration: 600.ms),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF8B7355),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFF8B7355),
                indicatorWeight: 3,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(icon: Icon(Icons.explore), text: 'Discover'),
                  Tab(icon: Icon(Icons.people), text: 'Social'),
                  Tab(icon: Icon(Icons.map), text: 'Map View'),
                ],
              ),
            ),

            const SizedBox(height: 16),

                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDiscoverTab(placesAsync),
                        _buildSocialTab(),
                        _buildMapTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.museoModerno(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab(AsyncValue<List<Place>> placesAsync) {
    return placesAsync.when(
      data: (places) {
        final filteredPlaces = _getFilteredPlaces(places);
        
        return Column(
          children: [
            // Category Filter
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedCategory = category);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF8B7355).withOpacity(0.2),
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: isSelected ? const Color(0xFF8B7355) : Colors.grey[700],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Places Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredPlaces.length,
                itemBuilder: (context, index) {
                  final place = filteredPlaces[index];
                  return _buildPlaceCard(place, index);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Error loading places', style: GoogleFonts.poppins()),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(Place place, int index) {
    final randomFriend = mockFriends[Random().nextInt(mockFriends.length)];
    final hasVisitedFriend = Random().nextBool();
    
    return GestureDetector(
      onTap: () => _openPlaceDetail(place),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    child: Image.network(
                      place.photos.isNotEmpty 
                          ? place.photos.first 
                          : _getFallbackImage(place),
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.7),
                                Colors.purple.withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.7),
                                Colors.purple.withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              place.emoji ?? '🏛️',
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // Distance badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_walk, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${Random().nextInt(20) + 1} min',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Friend visited indicator
                if (hasVisitedFriend)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        randomFriend['avatar'] as String,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          place.rating.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B7355).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            place.tag ?? 'Place',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFF8B7355),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    if (hasVisitedFriend)
                      Text(
                        '${randomFriend['name'] as String} visited here',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 100).ms)
      .slideY(begin: 0.3, duration: 400.ms)
      .fadeIn(duration: 400.ms);
  }

  Widget _buildSocialTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Friends Section
        _buildSectionHeader('👥 Friends Activity', 'See what your friends discovered'),
        const SizedBox(height: 16),
        
        ...mockFriends.map((friend) => _buildFriendActivityCard(friend)).toList(),
        
        const SizedBox(height: 24),
        
        // Leaderboard
        _buildSectionHeader('🏆 Discovery Leaderboard', 'Top explorers this month'),
        const SizedBox(height: 16),
        
        _buildLeaderboard(),
        
        const SizedBox(height: 24),
        
        // Recent Check-ins
        _buildSectionHeader('📍 Recent Check-ins', 'Latest discoveries in Rotterdam'),
        const SizedBox(height: 16),
        
        ...List.generate(3, (index) => _buildRecentCheckIn(index)),
      ],
    );
  }

  Widget _buildFriendActivityCard(Map<String, dynamic> friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B7355), Color(0xFFA0956B)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                friend['avatar'] as String,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend['name'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Visited ${friend['visitedCount']} places',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Last seen at Kunsthal Rotterdam',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Following ${friend['name'] as String}\'s activities! 👥')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B7355),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              'Follow',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    final sortedFriends = [...mockFriends]..sort((a, b) => (b['visitedCount'] as int).compareTo(a['visitedCount'] as int));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: sortedFriends.asMap().entries.map((entry) {
          final index = entry.key;
          final friend = entry.value;
          final medals = ['🥇', '🥈', '🥉', '🏅'];
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(medals[index], style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  friend['avatar'] as String,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    friend['name'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown[800],
                    ),
                  ),
                ),
                Text(
                  '${friend['visitedCount']} visits',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.brown[700],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentCheckIn(int index) {
    final places = ['Kunsthal Rotterdam', 'Markthal', 'Euromast'];
    final times = ['2 hours ago', '5 hours ago', '1 day ago'];
    final friends = mockFriends[index % mockFriends.length];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Text(friends['avatar'] as String, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                    text: friends['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' checked in at '),
                  TextSpan(
                    text: places[index],
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF8B7355)),
                  ),
                ],
              ),
            ),
          ),
          Text(
            times[index],
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    return Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      size: 64,
                      color: Color(0xFF8B7355),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Interactive Map Coming Soon!',
                      style: GoogleFonts.museoModerno(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore Rotterdam with our upcoming interactive map feature. See all places, your friends\' locations, and discover hidden gems!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Map feature coming soon! 🗺️')),
                        );
                      },
                      icon: const Icon(Icons.notification_add),
                      label: Text(
                        'Notify Me',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B7355),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.museoModerno(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getFallbackImage(Place place) {
    // Return appropriate fallback image based on place type
    if (place.types.contains('museum') || place.types.contains('art')) {
      return 'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800&h=600&fit=crop&auto=format'; // Museum
    } else if (place.types.contains('restaurant') || place.types.contains('cafe')) {
      return 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=800&h=600&fit=crop&auto=format'; // Restaurant
    } else if (place.types.contains('park') || place.types.contains('nature')) {
      return 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&h=600&fit=crop&auto=format'; // Nature/Park
    } else if (place.types.contains('tourist_attraction')) {
      return 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800&h=600&fit=crop&auto=format'; // Attraction
    } else {
      return 'https://images.unsplash.com/photo-1544967882-bc559c7eb3ce?w=800&h=600&fit=crop&auto=format'; // Default Rotterdam
    }
  }

  void _openPlaceDetail(Place place) {
    // Convert Place to Activity for ActivityDetailScreen
    final activity = Activity(
      id: place.id,
      name: place.name,
      description: place.description ?? 'Discover this amazing place in Rotterdam!',
      imageUrl: place.photos.isNotEmpty ? place.photos.first : _getFallbackImage(place),
      rating: place.rating,
      startTime: DateTime.now().add(const Duration(hours: 1)),
      duration: 120,
      timeSlot: 'afternoon',
      timeSlotEnum: TimeSlot.afternoon,
      tags: place.types.take(2).toList(),
      isPaid: false,
      paymentType: PaymentType.free,
      location: LatLng(place.location.lat, place.location.lng),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(activity: activity),
      ),
    );
  }
} 