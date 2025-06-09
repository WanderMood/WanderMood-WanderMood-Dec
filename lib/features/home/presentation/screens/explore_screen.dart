import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/moody_character.dart';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/location/presentation/widgets/location_dropdown.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/providers/explore_places_provider.dart';
import 'package:wandermood/features/places/presentation/widgets/place_card.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/features/profile/presentation/widgets/profile_drawer.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'All';
  String _searchFilter = 'All';
  bool _isSearching = false;
  String _searchQuery = '';

  // Advanced filter settings - New Structure
  int _activeFiltersCount = 0;
  
  // Expandable sections state - ALL CLOSED BY DEFAULT
  bool _moodyExpanded = false;
  bool _dietaryExpanded = false;
  bool _accessibilityExpanded = false;
  bool _logisticsExpanded = false;
  bool _photoExpanded = false;

  // Moody tips array
  static const List<String> _moodyTips = [
    "🏠 Indoor • 🌱 Vegan • 🏳️‍🌈 LGBTQ+? I got you.",
    "📸 Instagrammable • ☕ Wi-Fi • ♿ Accessible — filtered!",
    "🌄 Scenic views • 🍽️ Halal • 🎶 Quiet spots?",
    "🧘‍♀️ Calm vibe • 🌿 Gluten-free • 🌙 Open now — done.",
    "🍜 Foodie-friendly • 🪑 Outdoor seating • 🤫 Less crowded?",
    "🎭 Romantic • 🚌 Transport included • 🕒 1–3 hr?"
  ];
  
  String _selectedMoodyTip = "🏠 Indoor • 🌱 Vegan • 🏳️‍🌈 LGBTQ+? I got you.";
  
  // Moody Suggests filters
  String? _selectedMood; // Keep for backward compatibility
  bool _indoorOnly = false;
  bool _outdoorOnly = false;
  bool _weatherSafe = false;
  bool _openNow = false;
  bool _crowdQuiet = false;
  bool _crowdLively = false;
  bool _romanticVibe = false;
  bool _surpriseMe = false;
  
  // Dietary Preferences
  bool _vegan = false;
  bool _vegetarian = false;
  bool _halal = false;
  bool _glutenFree = false;
  bool _pescatarian = false;
  bool _noAlcohol = false;
  
  // Accessibility & Inclusion
  bool _wheelchairAccessible = false;
  bool _lgbtqFriendly = false;
  bool _sensoryFriendly = false;
  bool _seniorFriendly = false;
  bool _babyFriendly = false;
  bool _blackOwned = false;
  
  // Comfort & Convenience
  // Price Range - Multi-select
  // Price Range slider (€0 to €100)
  RangeValues _priceRange = const RangeValues(0, 100);
  
  // Distance slider (0 to 50 km)
  double _maxDistance = 25.0;
  
  bool _parkingAvailable = false;
  bool _transportIncluded = false;
  bool _creditCards = false;
  bool _wifiAvailable = false;
  bool _chargingPoints = false;
  
  // Photo Options
  bool _instagrammable = false;
  bool _artisticDesign = false;
  bool _aestheticSpaces = false;
  bool _scenicViews = false;
  bool _bestAtNight = false;
  bool _bestAtSunset = false;

  final List<String> _categories = [
    'All',
    'Popular',
    'Accommodations',
    'Nature',
    'Culture',
    'Food',
    'Activities',
    'History',
  ];

  final Map<String, String> _filterIcons = {
    'All': '🌟',
    'Popular': '🔥',
    'Accommodations': '🏨',
    'Nature': '🌳',
    'Culture': '🎨',
    'Food': '🍽️',
    'Activities': '⚡',
    'History': '🏛️',
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // Initialize random Moody tip
    _selectedMoodyTip = _moodyTips[Random().nextInt(_moodyTips.length)];
    
    // Clear any cached data and get fresh location
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Clear ALL cached places data from SharedPreferences
      await _clearAllCachedData();
      // Clear any cached places data to ensure fresh content
      ref.invalidate(explorePlacesProvider);
      // Get current location
      ref.read(locationNotifierProvider.notifier).getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _isSearching = _searchQuery.isNotEmpty;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
      _searchFilter = 'All'; // Reset search filter when clearing
    });
  }

  void _updateActiveFiltersCount() {
    int count = 0;
    
    // Moody Suggests filters
    if (_selectedMood != null) count++;
    if (_indoorOnly) count++;
    if (_outdoorOnly) count++;
    if (_weatherSafe) count++;
    if (_openNow) count++;
    if (_crowdQuiet) count++;
    if (_crowdLively) count++;
    if (_romanticVibe) count++;
    if (_surpriseMe) count++;
    
    // Dietary Preferences
    if (_vegan) count++;
    if (_vegetarian) count++;
    if (_halal) count++;
    if (_glutenFree) count++;
    if (_pescatarian) count++;
    if (_noAlcohol) count++;
    
    // Accessibility & Inclusion
    if (_wheelchairAccessible) count++;
    if (_lgbtqFriendly) count++;
    if (_sensoryFriendly) count++;
    if (_seniorFriendly) count++;
    if (_babyFriendly) count++;
    if (_blackOwned) count++;
    
    // Comfort & Convenience
    // Count price range if not default (0-100)
    if (_priceRange.start != 0 || _priceRange.end != 100) count++;
    // Count distance if not default (25 km)
    if (_maxDistance != 25.0) count++;
    if (_parkingAvailable) count++;
    if (_transportIncluded) count++;
    if (_creditCards) count++;
    if (_wifiAvailable) count++;
    if (_chargingPoints) count++;
    
    // Photo Options
    if (_instagrammable) count++;
    if (_artisticDesign) count++;
    if (_aestheticSpaces) count++;
    if (_scenicViews) count++;
    if (_bestAtNight) count++;
    if (_bestAtSunset) count++;
    
    setState(() {
      _activeFiltersCount = count;
    });
  }

  void _clearAllFilters() {
    setState(() {
      // Moody Suggests filters
      _selectedMood = null;
      _indoorOnly = false;
      _outdoorOnly = false;
      _weatherSafe = false;
      _openNow = false;
      _crowdQuiet = false;
      _crowdLively = false;
      _romanticVibe = false;
      _surpriseMe = false;
      
      // Dietary Preferences
      _vegan = false;
      _vegetarian = false;
      _halal = false;
      _glutenFree = false;
      _pescatarian = false;
      _noAlcohol = false;
      
      // Accessibility & Inclusion
      _wheelchairAccessible = false;
      _lgbtqFriendly = false;
      _sensoryFriendly = false;
      _seniorFriendly = false;
      _babyFriendly = false;
      _blackOwned = false;
      
      // Comfort & Convenience
      _priceRange = const RangeValues(0, 100);
      _maxDistance = 25.0;
      _parkingAvailable = false;
      _transportIncluded = false;
      _creditCards = false;
      _wifiAvailable = false;
      _chargingPoints = false;
      
      // Photo Options
      _instagrammable = false;
      _artisticDesign = false;
      _aestheticSpaces = false;
      _scenicViews = false;
      _bestAtNight = false;
      _bestAtSunset = false;
      
      _activeFiltersCount = 0;
    });
  }

  void _showAdvancedFilters() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _buildAdvancedFilterModal(),
    );
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _searchFilter = category; // Sync search filter with category
    });
  }

  void _onSearchFilterSelected(String filter) {
    setState(() {
      _searchFilter = filter;
      _selectedCategory = filter; // Sync category with search filter
    });
  }

  void _showSearchFilterMenu() {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 200, // Position from right
        120, // Top position
        20, // Right margin
        0, // Bottom
      ),
      items: _categories.map((category) {
        return PopupMenuItem<String>(
          value: category,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _filterIcons[category] ?? '📍',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: category == _searchFilter ? FontWeight.w600 : FontWeight.w400,
                  color: category == _searchFilter ? const Color(0xFF12B347) : Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ).then((selectedFilter) {
      if (selectedFilter != null) {
        _onSearchFilterSelected(selectedFilter);
      }
    });
  }

  List<Place> _filterPlaces(List<Place> places) {
    return places.where((place) {
      // Filter by search query
      bool matchesSearch = _searchQuery.isEmpty ||
          place.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (place.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          place.address.toLowerCase().contains(_searchQuery.toLowerCase());

      // Enhanced category filtering (use search filter if searching, otherwise use selected category)
      final activeFilter = _isSearching ? _searchFilter : _selectedCategory;
      bool matchesCategory = activeFilter == 'All' || _checkCategoryMatch(place, activeFilter);

      // Apply advanced filters
      bool matchesAdvancedFilters = _checkAdvancedFilters(place);

      return matchesSearch && matchesCategory && matchesAdvancedFilters;
    }).toList();
  }

  bool _checkAdvancedFilters(Place place) {
    // Mood filter
    if (_selectedMood != null && !_placeMatchesMood(place, _selectedMood!)) return false;

    // Indoor only filter
    if (_indoorOnly && !_placeIsIndoor(place)) return false;

    // Weather safe filter (indoor activities or places with weather protection)
    if (_weatherSafe && !_placeIsWeatherSafe(place)) return false;

    // Availability filter
    if (_openNow && !_placeIsCurrentlyOpen(place)) return false;

    // Dietary preferences
    if (_halal && !_placeSupportsHalal(place)) return false;
    if (_vegan && !_placeSupportsVeganVegetarian(place)) return false;
    if (_vegetarian && !_placeSupportsVeganVegetarian(place)) return false;
    if (_glutenFree && !_placeSupportsGlutenFree(place)) return false;

    // Accessibility
    if (_wheelchairAccessible && !_placeIsAccessible(place)) return false;
    if (_lgbtqFriendly && !_placeIsLGBTQFriendly(place)) return false;

    return true;
  }

  // Helper method for mood matching
  bool _placeMatchesMood(Place place, String mood) {
    switch (mood.toLowerCase()) {
      case 'adventure':
        return place.types.contains('park') || place.types.contains('tourist_attraction') ||
               place.activities.any((activity) => activity.toLowerCase().contains('adventure'));
      case 'creative':
        return place.types.contains('art_gallery') || place.types.contains('museum') ||
               place.activities.any((activity) => ['art', 'creative', 'workshop'].contains(activity.toLowerCase()));
      case 'relaxed':
        return place.types.contains('spa') || place.types.contains('cafe') || place.types.contains('park') ||
               place.activities.any((activity) => ['relaxation', 'wellness', 'meditation'].contains(activity.toLowerCase()));
      case 'mindful':
        return place.types.contains('place_of_worship') || place.types.contains('park') ||
               place.activities.any((activity) => ['meditation', 'spiritual', 'mindfulness'].contains(activity.toLowerCase()));
      case 'romantic':
        return place.types.contains('restaurant') && place.rating > 4.0 ||
               place.activities.any((activity) => ['romantic', 'date', 'intimate'].contains(activity.toLowerCase()));
      default:
        return true;
    }
  }

  // Helper method for indoor places
  bool _placeIsIndoor(Place place) {
    return !place.types.contains('park') && !place.types.contains('zoo') && 
           !place.types.contains('campground') && !place.types.contains('amusement_park');
  }

  // Helper method for weather safe places
  bool _placeIsWeatherSafe(Place place) {
    // Weather safe places are typically indoor or have good weather protection
    return _placeIsIndoor(place) ||
           place.types.contains('shopping_mall') ||
           place.types.contains('subway_station') ||
           place.types.contains('train_station') ||
           place.types.contains('airport') ||
           place.types.contains('hospital') ||
           place.types.contains('university') ||
           place.types.contains('school');
  }

  // Helper method to check if place is currently open (mock implementation)
  bool _placeIsCurrentlyOpen(Place place) {
    // Mock implementation - assume most places are open during day hours
    final hour = DateTime.now().hour;
    if (place.types.contains('museum')) return hour >= 9 && hour <= 17;
    if (place.types.contains('restaurant')) return hour >= 11 && hour <= 22;
    if (place.types.contains('bar')) return hour >= 17 && hour <= 2;
    if (place.types.contains('park')) return hour >= 6 && hour <= 22;
    return hour >= 8 && hour <= 20; // Default business hours
  }

  // Helper methods for filter logic (in a real app, this data would come from your database)
  bool _placeSupportsHalal(Place place) => 
    place.types.contains('restaurant') && place.name.toLowerCase().contains('halal') ||
    place.description?.toLowerCase().contains('halal') == true;

  bool _placeSupportsVeganVegetarian(Place place) => 
    place.types.contains('restaurant') && (
      place.name.toLowerCase().contains('vegan') ||
      place.name.toLowerCase().contains('vegetarian') ||
      place.description?.toLowerCase().contains('vegan') == true ||
      place.description?.toLowerCase().contains('vegetarian') == true
    );

  bool _placeSupportsGlutenFree(Place place) =>
    place.types.contains('restaurant') && (
      place.name.toLowerCase().contains('gluten') ||
      place.description?.toLowerCase().contains('gluten') == true
    );

  bool _placeIsAccessible(Place place) => place.rating > 4.0; // Mock - assume higher rated places are more accessible
  bool _placeIsLGBTQFriendly(Place place) => place.rating > 4.2; // Mock - assume inclusive places have good ratings

  bool _checkCategoryMatch(Place place, String category) {
    switch (category.toLowerCase()) {
      case 'popular':
        return place.rating >= 4.0 || place.types.contains('tourist_attraction');
      case 'accommodations':
        return place.types.any((type) => ['lodging', 'hotel', 'apartment_rental'].contains(type.toLowerCase()));
      case 'nature':
        return place.types.any((type) => ['park', 'natural_feature', 'zoo', 'campground'].contains(type.toLowerCase())) ||
               place.activities.any((activity) => activity.toLowerCase().contains('nature'));
      case 'culture':
        return place.types.any((type) => ['museum', 'art_gallery', 'library', 'tourist_attraction'].contains(type.toLowerCase())) ||
               place.activities.any((activity) => ['culture', 'history', 'art'].contains(activity.toLowerCase()));
      case 'food':
        return place.types.any((type) => ['restaurant', 'cafe', 'bakery', 'food', 'meal_takeaway'].contains(type.toLowerCase())) ||
               place.activities.any((activity) => activity.toLowerCase().contains('dining'));
      case 'activities':
        return place.activities.isNotEmpty;
      case 'history':
        return place.types.any((type) => ['museum', 'cemetery', 'church', 'mosque', 'synagogue', 'hindu_temple', 'place_of_worship'].contains(type.toLowerCase())) ||
               place.activities.any((activity) => activity.toLowerCase().contains('history'));
      default:
        return place.types.any((type) => type.toLowerCase() == category.toLowerCase()) ||
               place.activities.any((activity) => activity.toLowerCase() == category.toLowerCase());
    }
  }

  Future<void> _clearAllCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // Remove all places cache keys
      for (final key in keys) {
        if (key.startsWith('places_cache_') || key.startsWith('places_timestamp_')) {
          await prefs.remove(key);
          print('🗑️ Cleared cached data: $key');
        }
      }
      print('✅ All places cache data cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current location from the location provider
    final locationAsync = ref.watch(locationNotifierProvider);
    
    // Get user's GPS location for distance calculation
    final userLocationAsync = ref.watch(userLocationProvider);
    
    // Use the location to fetch places
    final explorePlacesAsync = locationAsync.when(
      data: (city) => ref.watch(explorePlacesProvider(city: city ?? 'Rotterdam')),
      loading: () => ref.watch(explorePlacesProvider(city: 'Rotterdam')),
      error: (_, __) => ref.watch(explorePlacesProvider(city: 'Rotterdam')),
    );

    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const ProfileDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              // Header with title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  children: [
                    // Profile picture menu button
                    Builder(
                      builder: (context) {
                        final profileData = ref.watch(profileProvider);
                        return GestureDetector(
                          onTap: () => Scaffold.of(context).openDrawer(),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: profileData.when(
                              data: (profile) => CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white,
                                backgroundImage: profile?.imageUrl != null
                                    ? NetworkImage(profile!.imageUrl!)
                                    : null,
                                child: profile?.imageUrl == null
                                    ? Text(
                                        profile?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF12B347),
                                        ),
                                      )
                                    : null,
                              ),
                              loading: () => CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  color: const Color(0xFF12B347),
                                  size: 20,
                                ),
                              ),
                              error: (_, __) => CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  color: const Color(0xFF12B347),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Explore',
                      style: GoogleFonts.museoModerno(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF12B347),
                      ),
                    ),
                    const Spacer(),
                    const LocationDropdown(),
                  ],
                ),
              ),
              
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: Color(0xFF12B347),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: _searchFilter == 'All' 
                              ? 'Find hidden gems, vibes & bites... ✨'
                              : 'Search in ${_searchFilter.toLowerCase()}... ${_filterIcons[_searchFilter] ?? '✨'}',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      // Filter button
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12B347),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF12B347).withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: _showAdvancedFilters,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_activeFiltersCount > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$_activeFiltersCount',
                                      style: const TextStyle(
                                        color: Color(0xFF12B347),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Icon(
                                  Icons.tune,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_isSearching)
                        GestureDetector(
                          onTap: _clearSearch,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.close,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Categories
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = category == _selectedCategory;
                    
                    return GestureDetector(
                      onTap: () => _onCategorySelected(category),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? const Color(0xFF12B347)
                            : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                            ? null
                            : Border.all(color: Colors.grey.shade300),
                          boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF12B347).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Places List
              Expanded(
                child: explorePlacesAsync.when(
                  data: (places) {
                    final filteredPlaces = _filterPlaces(places);
                    
                    if (filteredPlaces.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No places found',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              Text(
                                'Try different search terms',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: filteredPlaces.length,
                      itemBuilder: (context, index) {
                        final place = filteredPlaces[index];
                        final userLocation = userLocationAsync.value;
                        
                        return PlaceCard(
                          place: place,
                          userLocation: userLocation,
                          onTap: () {
                            context.push('/place/${place.id}');
                          },
                        ).animate().fadeIn(
                          duration: 300.ms,
                          delay: Duration(milliseconds: index * 50),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
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
                          'Error loading places',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[700],
                          ),
                        ),
                        Text(
                          error.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(explorePlacesProvider);
                          },
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedFilterModal() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        // Create updateFilter function that updates both states
        void updateFilter(VoidCallback updateCallback) {
          updateCallback(); // Execute the state change once
          setState(() {}); // Trigger main widget rebuild
          setModalState(() {}); // Trigger modal rebuild
        }
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E8),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12B347),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.tune,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Advanced Filters',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (_activeFiltersCount > 0)
                              Text(
                                '$_activeFiltersCount filters active',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF12B347),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_activeFiltersCount > 0)
                        TextButton(
                          onPressed: () {
                            _clearAllFilters();
                            setModalState(() {});
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF12B347).withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Clear All',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF12B347),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Filter Content - New Expandable Structure
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Floating Moody when no filters selected
                        if (_activeFiltersCount == 0) ...[
                          Center(
                            child: Column(
                              children: [
                                MoodyCharacter(
                                  size: 80,
                                  mood: 'idle',
                                ),
                                const SizedBox(height: 16),
                                // Random Moody tip
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    _selectedMoodyTip,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                      height: 1.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                        
                        // Moody Suggests (AI-recommended toggles)
                        _buildExpandableSection(
                          '💃', 
                          'Moody Suggests', 
                          _moodyExpanded,
                          () {
                            print('🚨 TOGGLE FUNCTION CALLED for Moody Suggests');
                            updateFilter(() {
                              print('🔄 BEFORE: _moodyExpanded = $_moodyExpanded');
                              _moodyExpanded = !_moodyExpanded;
                              print('🔄 AFTER: _moodyExpanded = $_moodyExpanded');
                            });
                          },
                          _buildMoodyFilters(updateFilter),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Dietary Preferences
                        _buildExpandableSection(
                          '🍽️',
                          'Dietary Preferences',
                          _dietaryExpanded,
                          () => updateFilter(() {
                            print('🔄 Toggling Dietary Preferences: $_dietaryExpanded -> ${!_dietaryExpanded}');
                            _dietaryExpanded = !_dietaryExpanded;
                          }),
                          _buildDietaryFilters(updateFilter),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Accessibility & Inclusion
                        _buildExpandableSection(
                          '♿',
                          'Accessibility & Inclusion',
                          _accessibilityExpanded,
                          () => updateFilter(() {
                            _accessibilityExpanded = !_accessibilityExpanded;
                          }),
                          _buildAccessibilityFilters(updateFilter),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Comfort & Convenience
                        _buildExpandableSection(
                          '📍',
                          'Comfort & Convenience',
                          _logisticsExpanded,
                          () => updateFilter(() {
                            _logisticsExpanded = !_logisticsExpanded;
                          }),
                          _buildLogisticsFilters(updateFilter),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Photo Options
                        _buildExpandableSection(
                          '📸',
                          'Photo Options',
                          _photoExpanded,
                          () => updateFilter(() {
                            _photoExpanded = !_photoExpanded;
                          }),
                          _buildPhotoFilters(updateFilter),
                        ),
                         
                        const SizedBox(height: 100), // Extra space for apply button
                      ],
                    ),
                  ),
                ),
                
                          // Apply Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
                  child: Column(
                                  children: [
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        // Trigger rebuild to apply all the advanced filters
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF12B347),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                      shadowColor: const Color(0xFF12B347).withOpacity(0.3),
                    ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, size: 20),
                              const SizedBox(width: 8),
                                                      Text(
                          _activeFiltersCount > 0 
                            ? 'Save $_activeFiltersCount filters'
                            : 'Save filters',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSection(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF12B347).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF12B347).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12B347),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF12B347),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String emoji, String title) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodButtons() {
    final moods = [
      {'name': 'Adventure', 'emoji': '🏔️', 'color': const Color(0xFFFFD700)},
      {'name': 'Creative', 'emoji': '😊', 'color': const Color(0xFF87CEEB)},
      {'name': 'Relaxed', 'emoji': '🍀', 'color': const Color(0xFF98FB98)},
      {'name': 'Mindful', 'emoji': '🍀', 'color': const Color(0xFFDDA0DD)},
      {'name': 'Romantic', 'emoji': '❤️', 'color': const Color(0xFFFFB6C1)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: moods.map((mood) => 
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _buildMoodButton(mood),
          )
        ).toList(),
      ),
    );
  }

  Widget _buildMoodButton(Map<String, dynamic> mood) {
    final isSelected = _selectedMood == mood['name'];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedMood = isSelected ? null : mood['name'];
            _updateActiveFiltersCount();
          });
        },
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? mood['color'] : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? mood['color'] : Colors.grey[300]!,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: mood['color'].withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: mood['color'].withOpacity(0.2),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mood['emoji'], style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                mood['name'],
                style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodButtonsWithCallback(Function(VoidCallback) updateFilter) {
    final moods = [
      {'name': 'Adventure', 'emoji': '🏔️', 'color': const Color(0xFFFFD700)},
      {'name': 'Creative', 'emoji': '😊', 'color': const Color(0xFF87CEEB)},
      {'name': 'Relaxed', 'emoji': '🍀', 'color': const Color(0xFF98FB98)},
      {'name': 'Mindful', 'emoji': '🍀', 'color': const Color(0xFFDDA0DD)},
      {'name': 'Romantic', 'emoji': '❤️', 'color': const Color(0xFFFFB6C1)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: moods.map((mood) => 
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _buildMoodButtonWithCallback(mood, updateFilter),
          )
        ).toList(),
      ),
    );
  }

  Widget _buildMoodButtonWithCallback(Map<String, dynamic> mood, Function(VoidCallback) updateFilter) {
    final isSelected = _selectedMood == mood['name'];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          updateFilter(() {
            _selectedMood = isSelected ? null : mood['name'];
            _updateActiveFiltersCount();
          });
        },
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? mood['color'] : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? mood['color'] : Colors.grey[300]!,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: mood['color'].withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: mood['color'].withOpacity(0.2),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mood['emoji'], style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                mood['name'],
                style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String emoji, String label, bool value, Function(bool)? onChanged) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged != null ? () {
          HapticFeedback.lightImpact();
          onChanged(!value);
        } : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: value ? const Color(0xFF12B347) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: value ? const Color(0xFF12B347) : Colors.grey[300]!,
              width: value ? 2 : 1,
            ),
            boxShadow: value ? [
              BoxShadow(
                color: const Color(0xFF12B347).withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: const Color(0xFF12B347).withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 3,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                    color: value ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChipWithCallback(String emoji, String label, bool value, VoidCallback? onChanged) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: value ? const Color(0xFF12B347) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: value ? const Color(0xFF12B347) : Colors.grey[300]!,
              width: value ? 2 : 1,
            ),
            boxShadow: value ? [
              BoxShadow(
                color: const Color(0xFF12B347).withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: const Color(0xFF12B347).withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 3,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                    color: value ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton(String emoji, String label, bool value, Function(bool) onChanged) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onChanged(!value);
        },
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: value ? const Color(0xFF12B347) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: value ? const Color(0xFF12B347) : Colors.grey[300]!,
              width: value ? 2.5 : 1.5,
            ),
            boxShadow: value ? [
              BoxShadow(
                color: const Color(0xFF12B347).withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: const Color(0xFF12B347).withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 2,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                  color: value ? Colors.white : Colors.black87,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButtonWithCallback(String emoji, String label, bool value, VoidCallback? onChanged) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged,
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: value ? const Color(0xFF12B347) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: value ? const Color(0xFF12B347) : Colors.grey[300]!,
              width: value ? 2.5 : 1.5,
            ),
            boxShadow: value ? [
              BoxShadow(
                color: const Color(0xFF12B347).withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: const Color(0xFF12B347).withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 2,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                  color: value ? Colors.white : Colors.black87,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPriceLevelText(int level) {
    switch (level) {
      case 1: return 'Budget';
      case 2: return 'Moderate';
      case 3: return 'Expensive';
      case 4: return 'Luxury';
      default: return 'Budget';
    }
  }

  // Helper method to build expandable sections
  Widget _buildExpandableSection(
    String icon,
    String title,
    bool isExpanded,
    VoidCallback onToggle,
    Widget content,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                print('🚨 TAP DETECTED on section: $title');
                HapticFeedback.lightImpact();
                onToggle();
                print('🚨 AFTER onToggle called');
              },
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isExpanded ? const Color(0xFF12B347).withOpacity(0.05) : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Text(
                      icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: isExpanded ? const Color(0xFF12B347) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              duration: const Duration(milliseconds: 200),
              heightFactor: isExpanded ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: content,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Moody Suggests filters
  Widget _buildMoodyFilters(Function(VoidCallback) updateFilter) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMoodyFilterChip('🏠', 'Indoor Only', _indoorOnly, const Color(0xFFE3F2FD), (value) {
                updateFilter(() {
                  _indoorOnly = value;
                  if (value) _outdoorOnly = false; // Exclusive
                  _updateActiveFiltersCount();
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMoodyFilterChip('☀️', 'Outdoor Only', _outdoorOnly, const Color(0xFFFFF3E0), (value) {
                updateFilter(() {
                  _outdoorOnly = value;
                  if (value) _indoorOnly = false; // Exclusive
                  _updateActiveFiltersCount();
                });
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMoodyFilterChip('🌧️', 'Weather-Safe', _weatherSafe, const Color(0xFFE8F5E8), (value) {
                updateFilter(() {
                  _weatherSafe = value;
                  _updateActiveFiltersCount();
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMoodyFilterChip('🌙', 'Open Now', _openNow, const Color(0xFFFFF8E1), (value) {
                updateFilter(() {
                  _openNow = value;
                  _updateActiveFiltersCount();
                });
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMoodyFilterChip('🤫', 'Quiet', _crowdQuiet, const Color(0xFFFFF9C4), (value) {
                updateFilter(() {
                  _crowdQuiet = value;
                  if (value) _crowdLively = false; // Exclusive
                  _updateActiveFiltersCount();
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMoodyFilterChip('💃', 'Lively', _crowdLively, const Color(0xFFFFE0B2), (value) {
                updateFilter(() {
                  _crowdLively = value;
                  if (value) _crowdQuiet = false; // Exclusive
                  _updateActiveFiltersCount();
                });
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMoodyFilterChip('💕', 'Romantic Vibe', _romanticVibe, const Color(0xFFFCE4EC), (value) {
                updateFilter(() {
                  _romanticVibe = value;
                  _updateActiveFiltersCount();
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMoodyFilterChip('🔀', 'Surprise Me', _surpriseMe, const Color(0xFFE1F5FE), (value) {
                updateFilter(() {
                  _surpriseMe = value;
                  _updateActiveFiltersCount();
                });
              }),
            ),
          ],
        ),
      ],
    );
  }

  // Dietary Preferences filters
  Widget _buildDietaryFilters(Function(VoidCallback) updateFilter) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMoodyFilterChip('🌱', 'Vegan', _vegan, const Color(0xFFE8F5E8), (value) {
          updateFilter(() {
            _vegan = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildMoodyFilterChip('🥬', 'Vegetarian', _vegetarian, const Color(0xFFF1F8E9), (value) {
          updateFilter(() {
            _vegetarian = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildMoodyFilterChip('🥗', 'Halal', _halal, const Color(0xFFE0F2F1), (value) {
          updateFilter(() {
            _halal = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildMoodyFilterChip('🌾', 'Gluten-Free', _glutenFree, const Color(0xFFFFF8E1), (value) {
          updateFilter(() {
            _glutenFree = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildMoodyFilterChip('🐟', 'Pescatarian', _pescatarian, const Color(0xFFE1F5FE), (value) {
          updateFilter(() {
            _pescatarian = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildMoodyFilterChip('❌', 'No Alcohol', _noAlcohol, const Color(0xFFFFF3E0), (value) {
          updateFilter(() {
            _noAlcohol = value;
            _updateActiveFiltersCount();
          });
        }),
      ],
    );
  }

  // Accessibility & Inclusion filters
  Widget _buildAccessibilityFilters(Function(VoidCallback) updateFilter) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMoodyFilterChip('♿', 'Wheelchair Accessible', _wheelchairAccessible, const Color(0xFFE3F2FD), (value) {
          updateFilter(() {
            _wheelchairAccessible = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildMoodyFilterChip('🏳️‍🌈', 'LGBTQ+ Friendly', _lgbtqFriendly, const Color(0xFFF3E5F5), (value) {
          updateFilter(() {
            _lgbtqFriendly = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildMoodyFilterChip('🧓', 'Senior-Friendly', _seniorFriendly, const Color(0xFFFFF8E1), (value) {
          updateFilter(() {
            _seniorFriendly = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildMoodyFilterChip('🧑‍🍼', 'Baby-Friendly', _babyFriendly, const Color(0xFFFCE4EC), (value) {
          updateFilter(() {
            _babyFriendly = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildMoodyFilterChip('✊🏿', 'Black-owned', _blackOwned, const Color(0xFFEFEBE9), (value) {
          updateFilter(() {
            _blackOwned = value;
            _updateActiveFiltersCount();
          });
        }),
      ],
    );
  }

  // Comfort & Convenience filters
  Widget _buildLogisticsFilters(Function(VoidCallback) updateFilter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range (€)',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 100,
          divisions: 20,
          labels: RangeLabels(
            '€${_priceRange.start.round()}',
            '€${_priceRange.end.round()}',
          ),
          onChanged: (values) {
            updateFilter(() {
              _priceRange = values;
              _updateActiveFiltersCount();
            });
          },
          activeColor: const Color(0xFF12B347),
          inactiveColor: const Color(0xFF12B347).withOpacity(0.2),
        ),
        const SizedBox(height: 16),
        Text(
          'Maximum Distance (km)',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _maxDistance,
          min: 0,
          max: 50,
          divisions: 50,
          label: '${_maxDistance.round()} km',
          onChanged: (value) {
            updateFilter(() {
              _maxDistance = value;
              _updateActiveFiltersCount();
            });
          },
          activeColor: const Color(0xFF12B347),
          inactiveColor: const Color(0xFF12B347).withOpacity(0.2),
        ),
        const SizedBox(height: 16),
        Text(
          'Additional Options',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMoodyFilterChip('🚗', 'Parking', _parkingAvailable, const Color(0xFFE8EAF6), (value) {
              updateFilter(() {
                _parkingAvailable = value;
                _updateActiveFiltersCount();
              });
            }),
            _buildMoodyFilterChip('🚌', 'Transport', _transportIncluded, const Color(0xFFE0F2F1), (value) {
              updateFilter(() {
                _transportIncluded = value;
                _updateActiveFiltersCount();
              });
            }),
            _buildMoodyFilterChip('💳', 'Credit Cards', _creditCards, const Color(0xFFFFF3E0), (value) {
              updateFilter(() {
                _creditCards = value;
                _updateActiveFiltersCount();
              });
            }),
            _buildMoodyFilterChip('📶', 'Wi-Fi', _wifiAvailable, const Color(0xFFE1F5FE), (value) {
              updateFilter(() {
                _wifiAvailable = value;
                _updateActiveFiltersCount();
              });
            }),
            _buildMoodyFilterChip('🔌', 'Charging', _chargingPoints, const Color(0xFFFFF8E1), (value) {
              updateFilter(() {
                _chargingPoints = value;
                _updateActiveFiltersCount();
              });
            }),
          ],
        ),
      ],
    );
  }

  // Photo Options filters
  Widget _buildPhotoFilters(Function(VoidCallback) updateFilter) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMoodyFilterChip('📸', 'Instagrammable', _instagrammable, const Color(0xFFFCE4EC), (value) {
          updateFilter(() {
            _instagrammable = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildMoodyFilterChip('🎨', 'Artistic Design', _artisticDesign, const Color(0xFFF3E5F5), (value) {
          updateFilter(() {
            _artisticDesign = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildMoodyFilterChip('🧘‍♀️', 'Aesthetic Spaces', _aestheticSpaces, const Color(0xFFE8F5E8), (value) {
          updateFilter(() {
            _aestheticSpaces = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildMoodyFilterChip('🌆', 'Scenic Views', _scenicViews, const Color(0xFFE3F2FD), (value) {
          updateFilter(() {
            _scenicViews = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildMoodyFilterChip('🌙', 'Best at Night', _bestAtNight, const Color(0xFFE8EAF6), (value) {
          updateFilter(() {
            _bestAtNight = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildMoodyFilterChip('🌅', 'Best at Sunset', _bestAtSunset, const Color(0xFFFFE0B2), (value) {
          updateFilter(() {
            _bestAtSunset = value;
            _updateActiveFiltersCount();
          });
        }),
      ],
    );
  }

  // Helper to build Moody filter chips with custom colors
  Widget _buildMoodyFilterChip(String emoji, String label, bool isSelected, Color unselectedColor, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!isSelected);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF12B347) : unselectedColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF12B347) : unselectedColor.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF12B347).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: unselectedColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build filter chips (for other sections)
  Widget _buildFilterChip(String emoji, String label, bool isSelected, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!isSelected);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF12B347) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF12B347) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF12B347).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build selectable chips (for single-select options)
  Widget _buildSelectableChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF12B347) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF12B347) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}