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
import 'package:wandermood/core/services/wandermood_ai_service.dart';
import '../widgets/conversational_explore_header.dart';
import '../../application/intent_processor.dart';
import '../../providers/smart_context_provider.dart';
import '../../application/context_manager.dart';
import '../../providers/dynamic_grouping_provider.dart';
import '../widgets/dynamic_grouping_widget.dart';

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
  
  // Scroll detection for hiding/showing Moody button
  bool _isMoodyButtonVisible = true;
  bool _isScrolling = false;
  double _lastScrollOffset = 0.0;
  
  // Conversational interface state
  String _selectedIntent = '';
  String _currentExplanation = '';
  List<Place> _intentFilteredPlaces = [];

  // AI Chat variables
  final TextEditingController _chatController = TextEditingController();
  bool _isAILoading = false;
  final List<ChatMessage> _chatMessages = [];
  String? _conversationId;
  List<String> _aiRecommendedPlaceNames = []; // Track AI recommended places
  bool _hasAIRecommendations = false; // Track if we have AI recommendations

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
    _scrollController.addListener(_onScrollChanged);
    
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
    _chatController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _isSearching = _searchQuery.isNotEmpty;
    });
  }

  void _onScrollChanged() {
    final currentScrollOffset = _scrollController.offset;
    final scrollDelta = currentScrollOffset - _lastScrollOffset;
    
    // Hide button when scrolling down fast, show when scrolling up or stopped
    if (scrollDelta > 10 && !_isScrolling) {
      setState(() {
        _isMoodyButtonVisible = false;
        _isScrolling = true;
      });
    } else if (scrollDelta < -5 || scrollDelta.abs() < 1) {
      setState(() {
        _isMoodyButtonVisible = true;
        _isScrolling = false;
      });
    }
    
    _lastScrollOffset = currentScrollOffset;
  }

  void _onIntentSelected(String intent) {
    setState(() {
      _selectedIntent = intent;
    });
    
    // Get smart context for enhanced processing
    final smartContext = ref.read(smartContextProvider);
    
    // Process intent with current places and context
    final explorePlacesAsync = ref.read(explorePlacesProvider(city: ref.read(locationNotifierProvider).value ?? 'Rotterdam'));
    explorePlacesAsync.whenData((places) {
      final result = IntentProcessor.processIntent(intent, places, context: smartContext);
      final sortedPlaces = IntentProcessor.sortByPriority(
        result['filteredPlaces'], 
        result['priority']
      );
      
      setState(() {
        _intentFilteredPlaces = sortedPlaces;
        _currentExplanation = result['explanation'];
      });
    });
  }

  void _onConversationalSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });
    
    if (query.isNotEmpty) {
      // Get smart context for enhanced search
      final smartContext = ref.read(smartContextProvider);
      
      // Process natural language query with context
      final explorePlacesAsync = ref.read(explorePlacesProvider(city: ref.read(locationNotifierProvider).value ?? 'Rotterdam'));
      explorePlacesAsync.whenData((places) {
        final result = IntentProcessor.processNaturalLanguage(query, places, context: smartContext);
        final sortedPlaces = IntentProcessor.sortByPriority(
          result['filteredPlaces'], 
          result['priority']
        );
        
        setState(() {
          _intentFilteredPlaces = sortedPlaces;
          _currentExplanation = result['explanation'];
          _selectedIntent = ''; // Clear intent when searching
        });
      });
    } else {
      // Clear search
      setState(() {
        _intentFilteredPlaces = [];
        _currentExplanation = '';
        _selectedIntent = '';
      });
    }
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
    var filteredPlaces = places.where((place) {
      // Filter by search query
      bool matchesSearch = _searchQuery.isEmpty ||
          place.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (place.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          place.address.toLowerCase().contains(_searchQuery.toLowerCase());

      // Apply advanced filters (mood, dietary, accessibility, etc.)
      bool matchesAdvancedFilters = _checkAdvancedFilters(place);

      return matchesSearch && matchesAdvancedFilters;
    }).toList();

    // Sort places to prioritize AI recommendations
    if (_hasAIRecommendations && _aiRecommendedPlaceNames.isNotEmpty) {
      filteredPlaces.sort((a, b) {
        final aIsRecommended = _isPlaceRecommendedByAI(a);
        final bIsRecommended = _isPlaceRecommendedByAI(b);
        
        // AI recommended places come first
        if (aIsRecommended && !bIsRecommended) return -1;
        if (!aIsRecommended && bIsRecommended) return 1;
        
        // Within the same group (recommended or not), sort by rating
        return (b.rating ?? 0.0).compareTo(a.rating ?? 0.0);
      });
      
      print('🤖 Sorted ${filteredPlaces.length} places, AI recommendations prioritized');
    }

    return filteredPlaces;
  }

  // Check if a place matches AI recommendations
  bool _isPlaceRecommendedByAI(Place place) {
    if (!_hasAIRecommendations || _aiRecommendedPlaceNames.isEmpty) return false;
    
    // Check for exact or partial matches with AI recommended place names
    final placeName = place.name.toLowerCase();
    
    for (final recommendedName in _aiRecommendedPlaceNames) {
      final recommended = recommendedName.toLowerCase();
      
      // Check for exact match or if the place name contains the recommended name
      if (placeName.contains(recommended) || recommended.contains(placeName)) {
        return true;
      }
      
      // Check for keyword matches (e.g., "Markthal" should match "Markthal Rotterdam")
      final recommendedWords = recommended.split(' ');
      final placeWords = placeName.split(' ');
      
      for (final word in recommendedWords) {
        if (word.length > 3 && placeWords.any((placeWord) => placeWord.contains(word))) {
          return true;
        }
      }
    }
    
    return false;
  }

  bool _checkAdvancedFilters(Place place) {
    // Mood filter
    if (_selectedMood != null && !_placeMatchesMood(place, _selectedMood!)) return false;

    // Indoor/Outdoor filters
    if (_indoorOnly && !_placeIsIndoor(place)) return false;
    if (_outdoorOnly && _placeIsIndoor(place)) return false;

    // Weather safe filter
    if (_weatherSafe && !_placeIsWeatherSafe(place)) return false;

    // Availability filter
    if (_openNow && !_placeIsCurrentlyOpen(place)) return false;

    // Dietary preferences - using smart metadata matching
    if (_vegan && !_matchesFilter(place, 'vegan')) return false;
    if (_vegetarian && !_matchesFilter(place, 'vegetarian')) return false;
    if (_halal && !_matchesFilter(place, 'halal')) return false;
    if (_glutenFree && !_matchesFilter(place, 'gluten_free')) return false;
    if (_pescatarian && !_placeSupportsVeganVegetarian(place)) return false; // Pescatarian matches vegetarian

    // Accessibility & Inclusion - using smart metadata matching
    if (_wheelchairAccessible && !_matchesFilter(place, 'wheelchair_accessible')) return false;
    if (_lgbtqFriendly && !_matchesFilter(place, 'lgbtq_friendly')) return false;
    if (_seniorFriendly && !_matchesFilter(place, 'senior_friendly')) return false;
    if (_babyFriendly && !_matchesFilter(place, 'baby_friendly')) return false;
    if (_blackOwned && !_matchesFilter(place, 'black_owned')) return false;

    // Comfort & Convenience - using smart metadata matching
    if (_wifiAvailable && !_matchesFilter(place, 'wifi_available')) return false;
    if (_chargingPoints && !_matchesFilter(place, 'charging_points')) return false;
    if (_parkingAvailable && !_matchesFilter(place, 'parking_available')) return false;
    if (_creditCards && !_matchesFilter(place, 'credit_cards')) return false;

    // Photo Options - using smart metadata matching
    if (_instagrammable && !_matchesFilter(place, 'instagrammable')) return false;
    if (_aestheticSpaces && !_matchesFilter(place, 'aesthetic_spaces')) return false;
    if (_scenicViews && !_matchesFilter(place, 'scenic_views')) return false;
    if (_bestAtSunset && !_matchesFilter(place, 'best_at_sunset')) return false;

    return true;
  }

  // Smart metadata matching method
  bool _matchesFilter(Place place, String filterKey) {
    // Get filter metadata from places provider
    final exploreProvider = ref.read(explorePlacesProvider(city: 'Rotterdam').notifier);
    final filterMeta = exploreProvider.getFilterMetadata(filterKey);
    
    if (filterMeta == null) return false;

    // Check keywords in name and description
    final keywords = List<String>.from(filterMeta['keywords'] ?? []);
    final targetTypes = List<String>.from(filterMeta['types'] ?? []);
    final ratingThreshold = filterMeta['rating_threshold'] as double?;
    
    // Check name and description for keywords
    final searchText = '${place.name.toLowerCase()} ${place.description?.toLowerCase() ?? ''} ${place.address.toLowerCase()}';
    
    bool keywordMatch = keywords.any((keyword) => searchText.contains(keyword.toLowerCase()));
    
    // Check place types
    bool typeMatch = targetTypes.isEmpty || place.types.any((type) => targetTypes.contains(type));
    
    // Check rating threshold if specified
    bool ratingMatch = ratingThreshold == null || (place.rating ?? 0.0) >= ratingThreshold;
    
    // Combine all criteria
    return (keywordMatch || typeMatch) && ratingMatch;
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
    
    // Get user's GPS location for distance calculation (cached to prevent excessive rebuilds)
    final userLocationAsync = ref.read(userLocationProvider);
    
    // Use the location to fetch places - optimized to prevent excessive rebuilds
    final city = locationAsync.value ?? 'Rotterdam';
    final explorePlacesAsync = ref.watch(explorePlacesProvider(city: city));

    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const ProfileDrawer(),
        floatingActionButton: _buildFloatingMoodyButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
              
              // Conversational Explore Header
              ConversationalExploreHeader(
                onIntentSelected: _onIntentSelected,
                onSearchChanged: _onConversationalSearchChanged,
                selectedIntent: _selectedIntent,
                onFilterTap: _showAdvancedFilters,
                activeFiltersCount: _activeFiltersCount,
              ),
              
              // Smart Context Banner
              Consumer(
                builder: (context, ref, child) {
                  final hasContext = ref.watch(hasContextDataProvider);
                  final contextSummary = ref.watch(contextualRecommendationsProvider);
                  
                  // Hide banner when user has selected an intent/vibe to save screen space
                  if (!hasContext || _selectedIntent.isNotEmpty) return const SizedBox.shrink();
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF12B347).withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF12B347).withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF12B347),
                                const Color(0xFF0A8F3A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart Context Active ✨',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF12B347),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                contextSummary,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0);
                },
              ),
              
              // Places List
              Expanded(
                child: explorePlacesAsync.when(
                  data: (allPlaces) {
                    // Get city name for filtering
                    final currentCity = locationAsync.value ?? 'Rotterdam';
                    
                    List<Place> filteredPlaces;
                    
                    // Use conversational filtering if active, otherwise use traditional filtering
                    if (_intentFilteredPlaces.isNotEmpty || _selectedIntent.isNotEmpty || _searchQuery.isNotEmpty) {
                      filteredPlaces = _intentFilteredPlaces;
                    } else {
                      // Use the traditional filtering method from provider
                      final categoryFilteredPlaces = ref.read(explorePlacesProvider(city: currentCity).notifier)
                          .filterPlacesByCategory(_selectedCategory, city: currentCity);
                      
                      // Apply additional search and advanced filters locally
                      filteredPlaces = _filterPlaces(categoryFilteredPlaces);
                    }
                    
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
                    
                    return Column(
                      children: [
                        // Conversational Results Header
                        if (_currentExplanation.isNotEmpty)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF12B347).withOpacity(0.1),
                                  const Color(0xFF12B347).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF12B347).withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF12B347),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.psychology_outlined,
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
                                        _currentExplanation,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF12B347),
                                        ),
                                      ),
                                      Text(
                                        '${filteredPlaces.length} places found',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _currentExplanation = '';
                                      _selectedIntent = '';
                                      _intentFilteredPlaces = [];
                                      _searchQuery = '';
                                    });
                                  },
                                  icon: Icon(
                                    Icons.close,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
                        
                        // AI Recommendations Banner
                        if (_hasAIRecommendations && _aiRecommendedPlaceNames.isNotEmpty)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF12B347).withOpacity(0.1),
                                  const Color(0xFF12B347).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF12B347).withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF12B347),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const MoodyCharacter(size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AI Recommendations Active',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF12B347),
                                        ),
                                      ),
                                      Text(
                                        'Places matching your chat with Moody are highlighted',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _hasAIRecommendations = false;
                                      _aiRecommendedPlaceNames.clear();
                                    });
                                  },
                                  icon: Icon(
                                    Icons.close,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Places List
                        Expanded(
                          child: ListView.builder(
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
                          ),
                        ),
                      ],
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

  // Build floating Moody button with scroll hide/show animation and tap-hold
  Widget _buildFloatingMoodyButton() {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      offset: _isMoodyButtonVisible ? Offset.zero : const Offset(0, 2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isMoodyButtonVisible ? 1.0 : 0.0,
        child: GestureDetector(
          onTap: () {
            print('🎯 Moody button tapped in explore screen!');
            HapticFeedback.lightImpact();
            _showMoodyTalkDialog();
          },
          onLongPress: () {
            print('🎯 Moody button long pressed - showing quick mood prompts!');
            HapticFeedback.mediumImpact();
            _showQuickMoodPrompts();
          },
          child: Container(
            width: 64,
            height: 64,
            child: const MoodyCharacter(size: 48),
          ),
        ),
      ),
    );
  }

  // Show quick mood prompts on long press
  void _showQuickMoodPrompts() {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Moody character
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF12B347), Color(0xFF0A8F3A)],
                        ),
                      ),
                      child: const Center(
                        child: MoodyCharacter(size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Quick Mood Shortcuts',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Quick mood buttons
                _buildQuickMoodButton(
                  icon: '😴',
                  title: "I'm bored",
                  subtitle: 'Find something exciting nearby',
                  onTap: () {
                    Navigator.pop(context);
                    _selectIntentFromQuickMood('Adventure time');
                  },
                ),
                const SizedBox(height: 12),
                _buildQuickMoodButton(
                  icon: '✨',
                  title: 'Surprise me',
                  subtitle: 'Random discovery based on my mood',
                  onTap: () {
                    Navigator.pop(context);
                    _selectIntentFromQuickMood('Perfect for now');
                  },
                ),
                const SizedBox(height: 12),
                _buildQuickMoodButton(
                  icon: '😌',
                  title: 'Chill mode',
                  subtitle: 'Something peaceful and relaxing',
                  onTap: () {
                    Navigator.pop(context);
                    _selectIntentFromQuickMood('Chill vibes');
                  },
                ),
                const SizedBox(height: 16),
                
                // Full chat button
                Container(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showMoodyTalkDialog();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF12B347).withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Open Full Chat',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF12B347),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickMoodButton({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _selectIntentFromQuickMood(String intent) {
    HapticFeedback.selectionClick();
    _onIntentSelected(intent);
  }

  // Show dialog for talking to Moody
  void _showMoodyTalkDialog() {
    // Create conversation ID only if it doesn't exist (persistent conversation)
    if (_conversationId == null) {
      _conversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    // Get current location for dynamic text
    final currentLocation = ref.read(locationNotifierProvider).value ?? 'your area';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Enhanced header with friendly aesthetics
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF12B347).withOpacity(0.05),
                              Colors.white,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Handle bar
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Header content
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  // Enhanced Moody avatar with gradient and shadow
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF12B347), Color(0xFF0A8F3A)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF12B347).withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: MoodyCharacter(size: 28),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Title and online status
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Chat with Moody',
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF2D3748),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF10B149),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Your AI explore buddy is online',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Enhanced close button
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.grey,
                                        size: 18,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Chat messages area
                      Expanded(
                        child: _chatMessages.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  const Spacer(),
                                  
                                  // Large enhanced Moody character
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF12B347).withOpacity(0.1),
                                          const Color(0xFF12B347).withOpacity(0.05),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: const Color(0xFF12B347).withOpacity(0.2),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Center(
                                      child: MoodyCharacter(size: 60),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  Text(
                                    'Hey there! 👋',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2D3748),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  Text(
                                    'I\'m Moody, your AI explore buddy!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF4A5568),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  Text(
                                    'Ask me about $currentLocation\'s hidden gems,\nbest restaurants, or weekend adventures.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: Colors.grey[600],
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Quick suggestion chips
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF12B347).withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFF12B347).withOpacity(0.1),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Try asking me about:',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF2D3748),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          alignment: WrapAlignment.center,
                                          children: [
                                            _buildStaticSuggestionChip('🍕 Food spots'),
                                            _buildStaticSuggestionChip('🎨 Art & Culture'),
                                            _buildStaticSuggestionChip('🌆 Local hotspots'),
                                            _buildStaticSuggestionChip('🌟 Hidden gems'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const Spacer(),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _chatMessages.length + (_isAILoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index < _chatMessages.length) {
                                  return _buildMessageBubble(_chatMessages[index]);
                                } else {
                                  // Enhanced loading indicator
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF12B347), Color(0xFF0A8F3A)],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF12B347).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: MoodyCharacter(size: 20),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF5F7FA),
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),
                                              bottomRight: Radius.circular(20),
                                              bottomLeft: Radius.circular(4),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.08),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    Colors.grey[400]!,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Moody is thinking...',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                      ),

                      // Enhanced input area
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: const Color(0xFF12B347).withOpacity(0.1),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _chatController,
                                    decoration: InputDecoration(
                                      hintText: 'Ask me anything about $currentLocation...',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.chat_bubble_outline,
                                        color: Colors.grey[400],
                                        size: 20,
                                      ),
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFF2D3748),
                                    ),
                                    onSubmitted: (text) => _sendChatMessageInModal(text, setModalState),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Enhanced send button
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF12B347), Color(0xFF0A8F3A)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF12B347).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () => _sendChatMessageInModal(_chatController.text, setModalState),
                                    child: const Center(
                                      child: Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Send chat message in modal
  Future<void> _sendChatMessageInModal(String message, StateSetter setModalState) async {
    if (message.trim().isEmpty || _isAILoading) return;

    // Get current location for context
    final locationAsync = ref.read(locationNotifierProvider);
    final city = locationAsync.valueOrNull ?? 'Rotterdam';

    // Add user message
    setModalState(() {
      _chatMessages.add(ChatMessage(
        message: message.trim(),
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isAILoading = true;
    });

    // Clear input
    _chatController.clear();

    try {
      // Call AI service
      final response = await WanderMoodAIService.chat(
        message: message.trim(),
        conversationId: _conversationId,
        moods: [], // Empty moods for explore context
        latitude: 51.9244, // Default Rotterdam coordinates
        longitude: 4.4777,
        city: city,
      );

      // Extract place recommendations from AI response
      final placeNames = _extractPlaceNamesFromResponse(response.message);
      
      // Add AI response
      setModalState(() {
        _chatMessages.add(ChatMessage(
          message: response.message,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isAILoading = false;
      });

      // Update the main screen with AI recommendations
      setState(() {
        _aiRecommendedPlaceNames = placeNames;
        _hasAIRecommendations = placeNames.isNotEmpty;
      });

      print('🤖 AI recommended places: $placeNames');
      
    } catch (e) {
      print('🤖 Error getting AI response: $e');
      setModalState(() {
        _chatMessages.add(ChatMessage(
          message: 'Sorry, I had trouble connecting. Please try again!',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isAILoading = false;
      });
    }
  }

  // Extract place names from AI response text
  List<String> _extractPlaceNamesFromResponse(String response) {
    final List<String> placeNames = [];
    
    // Common place patterns to look for
    final RegExp placePattern = RegExp(
      r'(?:visit|try|check out|go to|recommend|suggest)\s+([A-Z][a-zA-Z\s&]+?)(?:\s|,|\.|\!|\?|$)',
      caseSensitive: false,
    );
    
    final matches = placePattern.allMatches(response);
    for (final match in matches) {
      final placeName = match.group(1)?.trim();
      if (placeName != null && placeName.length > 2) {
        placeNames.add(placeName);
      }
    }
    
    // Also look for specific Rotterdam landmarks mentioned
    final rotterdamLandmarks = [
      'Markthal', 'Euromast', 'Erasmus Bridge', 'Cube Houses', 'Fenix Food Factory',
      'Kunsthal', 'Boijmans', 'Het Park', 'Witte de Withstraat', 'Oude Haven'
    ];
    
    for (final landmark in rotterdamLandmarks) {
      if (response.toLowerCase().contains(landmark.toLowerCase())) {
        placeNames.add(landmark);
      }
    }
    
    return placeNames.toSet().toList(); // Remove duplicates
  }

  // Build message bubble widget with improved aesthetics
  Widget _buildMessageBubble(ChatMessage message) {
    final profileData = ref.watch(profileProvider);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: message.isUser 
          ? MainAxisAlignment.end 
          : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            // Moody's Avatar with animation
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF12B347), Color(0xFF0A8F3A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF12B347).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: MoodyCharacter(size: 20),
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          // Message bubble with improved styling
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser 
                ? CrossAxisAlignment.end 
                : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: message.isUser
                      ? const LinearGradient(
                          colors: [Color(0xFF12B347), Color(0xFF0A8F3A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                    color: message.isUser ? null : const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: message.isUser 
                        ? const Radius.circular(20) 
                        : const Radius.circular(4),
                      bottomRight: message.isUser 
                        ? const Radius.circular(4) 
                        : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: message.isUser 
                          ? const Color(0xFF12B347).withOpacity(0.2)
                          : Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: message.isUser 
                        ? Colors.white 
                        : const Color(0xFF2D3748),
                    ),
                  ),
                ),
                
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    _formatMessageTime(message.timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 12),
            // User's Profile Picture
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF12B347).withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: profileData.when(
                  data: (profile) {
                    if (profile?.imageUrl != null) {
                      return Image.network(
                        profile!.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultUserAvatar(profile);
                        },
                      );
                    } else {
                      return _buildDefaultUserAvatar(profile);
                    }
                  },
                  loading: () => _buildDefaultUserAvatar(null),
                  error: (_, __) => _buildDefaultUserAvatar(null),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to build default user avatar
  Widget _buildDefaultUserAvatar(dynamic profile) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          profile?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

     // Helper method to format message timestamp
   String _formatMessageTime(DateTime timestamp) {
     final now = DateTime.now();
     final difference = now.difference(timestamp);
     
     if (difference.inMinutes < 1) {
       return 'Just now';
     } else if (difference.inMinutes < 60) {
       return '${difference.inMinutes}m ago';
     } else if (difference.inHours < 24) {
       return '${difference.inHours}h ago';
     } else {
       return '${timestamp.day}/${timestamp.month}';
     }
   }

   // Helper method to build static suggestion chips
   Widget _buildStaticSuggestionChip(String text) {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(20),
         border: Border.all(
           color: const Color(0xFF12B347).withOpacity(0.2),
         ),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.05),
             blurRadius: 4,
             offset: const Offset(0, 2),
           ),
         ],
       ),
       child: Text(
         text,
         style: GoogleFonts.poppins(
           fontSize: 12,
           fontWeight: FontWeight.w500,
           color: const Color(0xFF4A5568),
         ),
       ),
     );
   }

   // Helper method to build quick suggestion buttons
   Widget _buildQuickSuggestion(String text) {
     return GestureDetector(
       onTap: () {
         // Find the modal state and send the suggestion as a message
         _chatController.text = text.replaceAll(RegExp(r'[🍕☕🎨]'), '').trim();
       },
       child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
         decoration: BoxDecoration(
           color: const Color(0xFF12B347).withOpacity(0.1),
           borderRadius: BorderRadius.circular(15),
           border: Border.all(
             color: const Color(0xFF12B347).withOpacity(0.2),
           ),
         ),
         child: Text(
           text,
           style: GoogleFonts.poppins(
             fontSize: 11,
             fontWeight: FontWeight.w500,
             color: const Color(0xFF12B347),
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
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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

class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.message,
    required this.isUser,
    required this.timestamp,
  });
}