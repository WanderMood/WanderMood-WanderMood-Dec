import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/location/presentation/widgets/location_dropdown.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/providers/explore_places_provider.dart';
// OLD - Replaced by moody_explore_provider. Keep for 24-48h rollback safety.
import 'package:wandermood/features/places/providers/moody_explore_provider.dart';
import 'package:wandermood/features/places/presentation/widgets/place_card.dart';
import 'package:wandermood/features/places/presentation/widgets/place_grid_card.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wandermood/core/constants/api_keys.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wandermood/core/services/distance_service.dart';
import 'package:wandermood/core/services/user_preferences_service.dart';

import '../widgets/conversational_explore_header.dart';
import '../../application/intent_processor.dart';
import '../../providers/smart_context_provider.dart';


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
  
  // Scroll detection for content
  bool _isScrolling = false;
  double _lastScrollOffset = 0.0;
  
  // View mode toggle - grid, list or map
  bool _isGridView = false;
  bool _isMapView = false;
  GoogleMapController? _mapController;
  
  // Conversational interface state
  String _selectedIntent = '';
  String _currentExplanation = '';
  List<Place> _intentFilteredPlaces = [];



  // Advanced filter settings - New Structure
  int _activeFiltersCount = 0;
  
  // Expandable sections state - ALL CLOSED BY DEFAULT
  bool _advancedSuggestionsExpanded = false;
  bool _dietaryExpanded = false;
  bool _accessibilityExpanded = false;
  bool _logisticsExpanded = false;
  bool _photoExpanded = false;


  
  
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

  // Quick filter state (used primarily in map view, but applied globally)
  bool _quickFilterDistance1km = false;
  bool _quickFilterRating45 = false;
  
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
    _mapController?.dispose();
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
    
    // Track scrolling state for any future use
    if (scrollDelta > 10 && !_isScrolling) {
      setState(() {
        _isScrolling = true;
      });
    } else if (scrollDelta < -5 || scrollDelta.abs() < 1) {
      setState(() {
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
    // NEW: Use Moody Edge Function
    final explorePlacesAsync = ref.read(moodyExploreAutoProvider);
    // OLD: ref.read(explorePlacesProvider(city: ref.read(locationNotifierProvider).value ?? 'Rotterdam'))
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
      // NEW: Use Moody Edge Function
    final explorePlacesAsync = ref.read(moodyExploreAutoProvider);
    // OLD: ref.read(explorePlacesProvider(city: ref.read(locationNotifierProvider).value ?? 'Rotterdam'))
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
    final initialCount = places.length;
    final preferencesService = ref.read(userPreferencesServiceProvider);
    
    var filteredPlaces = places.where((place) {
      // Filter by search query
      bool matchesSearch = _searchQuery.isEmpty ||
          place.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (place.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          place.address.toLowerCase().contains(_searchQuery.toLowerCase());

      // Apply advanced filters (mood, dietary, accessibility, etc.)
      bool matchesAdvancedFilters = _checkAdvancedFilters(place);

      // Apply user preferences from onboarding (soft filter - boost matching places)
      // Only apply if no explicit filters are set (to avoid double-filtering)
      bool matchesPreferences = true;
      if (_activeFiltersCount == 0 && _searchQuery.isEmpty) {
        // Soft preference matching: prefer places that match interests/styles
        matchesPreferences = preferencesService.placeMatchesInterests(place) ||
                            preferencesService.placeMatchesTravelStyles(place);
      }

      return matchesSearch && matchesAdvancedFilters && matchesPreferences;
    }).toList();

    // Sort places: preference matches first, then by rating
    filteredPlaces.sort((a, b) {
      final aMatchesPrefs = preferencesService.placeMatchesInterests(a) || 
                           preferencesService.placeMatchesTravelStyles(a);
      final bMatchesPrefs = preferencesService.placeMatchesInterests(b) || 
                           preferencesService.placeMatchesTravelStyles(b);
      
      if (aMatchesPrefs && !bMatchesPrefs) return -1;
      if (!aMatchesPrefs && bMatchesPrefs) return 1;
      
      return (b.rating ?? 0.0).compareTo(a.rating ?? 0.0);
    });

    // Debug logging
    if (_activeFiltersCount > 0 || _searchQuery.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('🔍 Filtering: ${initialCount} → ${filteredPlaces.length} places');
        debugPrint('   Active filters: $_activeFiltersCount');
        debugPrint('   Search query: "$_searchQuery"');
      }
    }

    return filteredPlaces;
  }

  /// Apply quick filters (distance, rating) on top of existing filters
  List<Place> _applyQuickFilters(
    List<Place> places, {
    required Position? userLocation,
    required String currentCity,
  }) {
    var result = List<Place>.from(places);

    // Rating quick filter: 4.5+
    if (_quickFilterRating45) {
      result = result.where((place) => place.rating >= 4.5).toList();
    }

    // Distance quick filter: within 1km
    if (_quickFilterDistance1km) {
      // If we don't have user location, fall back to city center coordinates
      double originLat;
      double originLng;

      if (userLocation != null) {
        originLat = userLocation.latitude;
        originLng = userLocation.longitude;
      } else {
        // Simple fallback using same coordinates map as explore_places_provider
        final cityCoords = {
          'Rotterdam': {'lat': 51.9244, 'lng': 4.4777},
          'Amsterdam': {'lat': 52.3676, 'lng': 4.9041},
          'The Hague': {'lat': 52.0705, 'lng': 4.3007},
          'Utrecht': {'lat': 52.0907, 'lng': 5.1214},
          'Eindhoven': {'lat': 51.4416, 'lng': 5.4697},
          'Groningen': {'lat': 53.2194, 'lng': 6.5665},
          'Delft': {'lat': 52.0067, 'lng': 4.3556},
          'Beneden-Leeuwen': {'lat': 51.8892, 'lng': 5.5142},
        };
        final fallback = cityCoords[currentCity] ?? cityCoords['Rotterdam']!;
        originLat = fallback['lat']!;
        originLng = fallback['lng']!;
      }

      result = result.where((place) {
        final distanceKm = DistanceService.calculateDistance(
          originLat,
          originLng,
          place.location.lat,
          place.location.lng,
        );
        return distanceKm <= 1.0;
      }).toList();
    }

    return result;
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

  // Smart metadata matching method - improved with fallback logic
  bool _matchesFilter(Place place, String filterKey) {
    // NEW: Edge Function handles mood-based filtering
    // Local filters use keyword matching (no need for metadata from old provider)
    // Create search text for keyword matching
    final searchText = '${place.name.toLowerCase()} ${place.description?.toLowerCase() ?? ''} ${place.address.toLowerCase()}';
    
    // Use keyword-based matching (Edge Function already filtered by mood)
    return _matchesFilterByKeywords(place, filterKey, searchText);
  }
  
  // Fallback keyword matching when metadata is not available
  bool _matchesFilterByKeywords(Place place, String filterKey, String searchText) {
    final keywordMap = {
      'vegan': ['vegan', 'plant-based', 'plant based', 'vegetarian'],
      'vegetarian': ['vegetarian', 'veggie', 'meat-free', 'meat free'],
      'halal': ['halal', 'muslim', 'islamic'],
      'gluten_free': ['gluten-free', 'gluten free', 'celiac', 'gf'],
      'wheelchair_accessible': ['accessible', 'wheelchair', 'ramp', 'elevator', 'disabled'],
      'lgbtq_friendly': ['lgbtq', 'lgbt', 'gay', 'pride', 'inclusive'],
      'senior_friendly': ['senior', 'elderly', 'accessible', 'easy access'],
      'baby_friendly': ['baby', 'child', 'family', 'kids', 'stroller', 'changing'],
      'black_owned': ['black owned', 'black-owned', 'african'],
      'wifi_available': ['wifi', 'wi-fi', 'wireless', 'internet', 'free wifi'],
      'charging_points': ['charging', 'power outlet', 'usb', 'electric'],
      'parking_available': ['parking', 'car park', 'garage'],
      'credit_cards': ['card', 'credit', 'debit', 'payment', 'cashless'],
      'instagrammable': ['instagram', 'photo', 'picturesque', 'scenic', 'beautiful'],
      'aesthetic_spaces': ['aesthetic', 'design', 'decor', 'interior', 'stylish'],
      'scenic_views': ['view', 'scenic', 'panoramic', 'vista', 'overlook'],
      'best_at_sunset': ['sunset', 'evening', 'golden hour', 'dusk'],
    };
    
    final keywords = keywordMap[filterKey] ?? [];
    if (keywords.isEmpty) return true; // If no keywords defined, don't filter out
    
    // Check if any keyword matches
    return keywords.any((keyword) => searchText.contains(keyword.toLowerCase()));
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

  // Helper method to check if place is currently open
  // Uses real opening hours data when available, otherwise estimates based on type
  bool _placeIsCurrentlyOpen(Place place) {
    // Use real opening hours if available
    if (place.openingHours != null && place.openingHours!.isOpen != null) {
      return place.openingHours!.isOpen!;
    }
    
    // Fallback: estimate based on place type and current time
    // This is a reasonable fallback when real data isn't available
    final hour = DateTime.now().hour;
    if (place.types.contains('museum')) return hour >= 9 && hour <= 17;
    if (place.types.contains('restaurant')) return hour >= 11 && hour <= 22;
    if (place.types.contains('bar')) return hour >= 17 || hour <= 2; // Bars open late
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

  // Helper methods for accessibility and inclusivity
  // These use rating as a proxy when real data isn't available
  // In production, this data should come from place details API or user reviews
  bool _placeIsAccessible(Place place) {
    // Check description for accessibility keywords
    final desc = place.description?.toLowerCase() ?? '';
    if (desc.contains('accessible') || desc.contains('wheelchair') || desc.contains('ramp')) {
      return true;
    }
    // Fallback: higher-rated places are more likely to be accessible
    return place.rating > 4.0;
  }
  
  bool _placeIsLGBTQFriendly(Place place) {
    // Check description for inclusivity keywords
    final desc = place.description?.toLowerCase() ?? '';
    if (desc.contains('lgbtq') || desc.contains('inclusive') || desc.contains('diverse') || desc.contains('pride')) {
      return true;
    }
    // Fallback: higher-rated places are more likely to be inclusive
    return place.rating > 4.2;
  }

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
    // NEW: Use Moody Edge Function for 60-80 places
    final explorePlacesAsync = ref.watch(moodyExploreAutoProvider);
    // OLD: ref.watch(explorePlacesProvider(city: city)) - Replaced by Edge Function

    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Removed drawer and floating action button for Moody chat
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                floating: true,
                pinned: true,
                snap: false,
                expandedHeight: 300, // Increased to accommodate the activities count and view toggle
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                // Removed hamburger menu
                leading: null,
                // Removed compact title, search and location buttons
                title: null,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: SafeArea(
          child: Column(
            children: [
              // Header with title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  children: [
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
                          activitiesCount: explorePlacesAsync.when(
                            data: (places) => _filterPlaces(places).length,
                            loading: () => 0,
                            error: (_, __) => 0,
                          ),
                          isGridView: _isGridView,
                          isMapView: _isMapView,
                          onViewToggle: (isGrid, isMap) {
                            setState(() {
                              _isGridView = isGrid;
                              _isMapView = isMap;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(0), // Changed from 60 to 0
                  child: Container(), // Empty container since we moved the UI elements
                ),
              ),
            ];
          },
          body: explorePlacesAsync.when(
                  data: (allPlaces) {
                    // Get city name for filtering
                    final currentCity = locationAsync.value ?? 'Rotterdam';
                    
                    List<Place> filteredPlaces;
                    final userLocation = userLocationAsync.value;
                    
                    // Use conversational filtering if active, otherwise use traditional filtering
                    if (_intentFilteredPlaces.isNotEmpty || _selectedIntent.isNotEmpty || _searchQuery.isNotEmpty) {
                      filteredPlaces = _intentFilteredPlaces;
                    } else {
                      // NEW: Edge Function already returns filtered/ranked places based on mood
                      // Just apply local UI filters (search, category, etc.)
                      filteredPlaces = allPlaces; // Start with all places from Edge Function
                      
                      // Apply local UI filters (category, search, etc.)
                      if (_selectedCategory != 'All') {
                        filteredPlaces = filteredPlaces.where((place) {
                          return place.types.any((type) => 
                            type.toLowerCase().contains(_selectedCategory.toLowerCase())
                          );
                        }).toList();
                      }
                      
                      // Apply additional search and advanced filters locally
                      filteredPlaces = _filterPlaces(filteredPlaces);
                    }

                    // For map view: show ALL places (filters are visual indicators only)
                    // For list/grid view: apply quick filters to actually filter results
                    final placesForMap = filteredPlaces; // Keep all places for map
                    
                    if (!_isMapView) {
                      // Apply quick filters only for list/grid views
                      filteredPlaces = _applyQuickFilters(
                        filteredPlaces,
                        userLocation: userLocation,
                        currentCity: currentCity,
                      );
                    }
                    
                    // REMOVED: Auto-invalidate was causing infinite loop
                    // If filters reduce results too much, user can manually refresh or adjust filters
                    if (filteredPlaces.length < 5 && allPlaces.length >= 50) {
                      debugPrint('⚠️ Filters reduced results to ${filteredPlaces.length} places (${allPlaces.length} unfiltered).');
                      // User can adjust filters or pull to refresh manually
                    }
                    
                    if (filteredPlaces.isEmpty && !_isMapView) {
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
                                        if (false) // Removed AI recommendations
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
                            child: const Icon(Icons.recommend, size: 16, color: Colors.white),
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
                                  'Places matching your search are highlighted',
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
                                      // Removed AI recommendations functionality
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
                        
                  // Places List/Grid/Map
                        Expanded(
                    child: _isMapView
                      ? _buildMapView(placesForMap, userLocationAsync.value)
                      : _isGridView 
                        ? GridView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: filteredPlaces.length,
                            itemBuilder: (context, index) {
                              final place = filteredPlaces[index];
                              final userLocation = userLocationAsync.value;
                              
                              return PlaceGridCard(
                                place: place,
                                userLocation: userLocation,
                                cityName: locationAsync.value ?? 'Rotterdam',
                                onTap: () {
                                  context.push('/place/${place.id}');
                                },
                              ).animate().fadeIn(
                                duration: 300.ms,
                                delay: Duration(milliseconds: index * 30),
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: filteredPlaces.length,
                            itemBuilder: (context, index) {
                              final place = filteredPlaces[index];
                              final userLocation = userLocationAsync.value;
                              final currentCity = locationAsync.value ?? 'Rotterdam';
                              
                              return PlaceCard(
                                place: place,
                                userLocation: userLocation,
                                cityName: currentCity,
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
                  error: (error, stack) {
                    // Check if error is location-related
                    final errorMessage = error.toString();
                    final isLocationError = errorMessage.contains('Location is required') || 
                                          errorMessage.contains('GPS coordinates') ||
                                          errorMessage.contains('location services');
                    
                    return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            isLocationError ? Icons.location_off : Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                            isLocationError ? 'Location Required' : 'Error loading places',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[700],
                          ),
                        ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              isLocationError 
                                ? 'Please enable location services or set your location in settings to discover places near you.'
                                : errorMessage,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                            ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                              // Invalidate the correct provider
                              ref.invalidate(moodyExploreAutoProvider);
                              // Also try to refresh location
                              if (isLocationError) {
                                ref.read(locationNotifierProvider.notifier).retryLocationAccess();
                                ref.read(userLocationProvider.notifier).refreshLocation();
                              }
                          },
                            child: Text(isLocationError ? 'Enable Location' : 'Try Again'),
                        ),
                      ],
                    ),
                    );
                  },
          ),
        ),
      ),
    );
  }





  // Show dialog for talking to Moody
  void _showMoodyTalkDialog() {
    // Removed - Moody chat now only available on Moody screen
  }

  // Send chat message in modal
  Future<void> _sendChatMessageInModal(String message, StateSetter setModalState) async {
    // Removed - Moody chat now only available on Moody screen
  }

  // Build message bubble
  Widget _buildMessageBubble(ChatMessage message) {
    // Removed - Moody chat now only available on Moody screen
    return Container();
   }

   // Helper method to build quick suggestion buttons
   Widget _buildQuickSuggestion(String text) {
    // Removed - Moody chat now only available on Moody screen
    return Container();
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
                        // Empty state when no filters selected
                        if (_activeFiltersCount == 0) ...[
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                // Filter tip
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    "🎯 Use filters to find exactly what you're looking for!",
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
                        
                        // Advanced Suggestions 
                        _buildExpandableSection(
                          '⚡', 
                          'Quick Suggestions', 
                          _advancedSuggestionsExpanded,
                          () {
                            updateFilter(() {
                              _advancedSuggestionsExpanded = !_advancedSuggestionsExpanded;
                            });
                          },
                          _buildAdvancedSuggestionFilters(updateFilter),
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
                      // Force a rebuild to apply filters
                      setState(() {
                        // Update active filters count
                        _updateActiveFiltersCount();
                        debugPrint('💾 Saved filters - Active count: $_activeFiltersCount');
                        debugPrint('🔍 Filter state - Vegan: $_vegan, Vegetarian: $_vegetarian, Wheelchair: $_wheelchairAccessible');
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

  // Advanced Suggestion filters
  Widget _buildAdvancedSuggestionFilters(Function(VoidCallback) updateFilter) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFilterChip('🏠', 'Indoor Only', _indoorOnly, const Color(0xFFE3F2FD), (value) {
                updateFilter(() {
                  _indoorOnly = value;
                  if (value) _outdoorOnly = false; // Exclusive
                  _updateActiveFiltersCount();
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFilterChip('☀️', 'Outdoor Only', _outdoorOnly, const Color(0xFFFFF3E0), (value) {
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
              child: _buildFilterChip('🌧️', 'Weather-Safe', _weatherSafe, const Color(0xFFE8F5E8), (value) {
                updateFilter(() {
                  _weatherSafe = value;
                  _updateActiveFiltersCount();
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFilterChip('🌙', 'Open Now', _openNow, const Color(0xFFFFF8E1), (value) {
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
              child: _buildFilterChip('🤫', 'Quiet', _crowdQuiet, const Color(0xFFFFF9C4), (value) {
                updateFilter(() {
                  _crowdQuiet = value;
                  if (value) _crowdLively = false; // Exclusive
                  _updateActiveFiltersCount();
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFilterChip('💃', 'Lively', _crowdLively, const Color(0xFFFFE0B2), (value) {
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
              child: _buildFilterChip('💕', 'Romantic Vibe', _romanticVibe, const Color(0xFFFCE4EC), (value) {
                updateFilter(() {
                  _romanticVibe = value;
                  _updateActiveFiltersCount();
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFilterChip('🔀', 'Surprise Me', _surpriseMe, const Color(0xFFE1F5FE), (value) {
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
        _buildFilterChip('🌱', 'Vegan', _vegan, const Color(0xFFE8F5E8), (value) {
          updateFilter(() {
            _vegan = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildFilterChip('🥬', 'Vegetarian', _vegetarian, const Color(0xFFF1F8E9), (value) {
          updateFilter(() {
            _vegetarian = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildFilterChip('🥗', 'Halal', _halal, const Color(0xFFE0F2F1), (value) {
          updateFilter(() {
            _halal = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildFilterChip('🌾', 'Gluten-Free', _glutenFree, const Color(0xFFFFF8E1), (value) {
          updateFilter(() {
            _glutenFree = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildFilterChip('🐟', 'Pescatarian', _pescatarian, const Color(0xFFE1F5FE), (value) {
          updateFilter(() {
            _pescatarian = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildFilterChip('❌', 'No Alcohol', _noAlcohol, const Color(0xFFFFF3E0), (value) {
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
        _buildFilterChip('♿', 'Wheelchair Accessible', _wheelchairAccessible, const Color(0xFFE3F2FD), (value) {
          updateFilter(() {
            _wheelchairAccessible = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildFilterChip('🏳️‍🌈', 'LGBTQ+ Friendly', _lgbtqFriendly, const Color(0xFFF3E5F5), (value) {
          updateFilter(() {
            _lgbtqFriendly = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildFilterChip('🧓', 'Senior-Friendly', _seniorFriendly, const Color(0xFFFFF8E1), (value) {
          updateFilter(() {
            _seniorFriendly = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildFilterChip('🧑‍🍼', 'Baby-Friendly', _babyFriendly, const Color(0xFFFCE4EC), (value) {
          updateFilter(() {
            _babyFriendly = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildFilterChip('✊🏿', 'Black-owned', _blackOwned, const Color(0xFFEFEBE9), (value) {
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
            _buildFilterChip('🚗', 'Parking', _parkingAvailable, const Color(0xFFE8EAF6), (value) {
              updateFilter(() {
                _parkingAvailable = value;
                _updateActiveFiltersCount();
              });
            }),
            _buildFilterChip('🚌', 'Transport', _transportIncluded, const Color(0xFFE0F2F1), (value) {
              updateFilter(() {
                _transportIncluded = value;
                _updateActiveFiltersCount();
              });
            }),
            _buildFilterChip('💳', 'Credit Cards', _creditCards, const Color(0xFFFFF3E0), (value) {
              updateFilter(() {
                _creditCards = value;
                _updateActiveFiltersCount();
              });
            }),
            _buildFilterChip('📶', 'Wi-Fi', _wifiAvailable, const Color(0xFFE1F5FE), (value) {
              updateFilter(() {
                _wifiAvailable = value;
                _updateActiveFiltersCount();
              });
            }),
            _buildFilterChip('🔌', 'Charging', _chargingPoints, const Color(0xFFFFF8E1), (value) {
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
        _buildFilterChip('📸', 'Instagrammable', _instagrammable, const Color(0xFFFCE4EC), (value) {
          updateFilter(() {
            _instagrammable = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildFilterChip('🎨', 'Artistic Design', _artisticDesign, const Color(0xFFF3E5F5), (value) {
          updateFilter(() {
            _artisticDesign = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildFilterChip('🧘‍♀️', 'Aesthetic Spaces', _aestheticSpaces, const Color(0xFFE8F5E8), (value) {
          updateFilter(() {
            _aestheticSpaces = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildFilterChip('🌆', 'Scenic Views', _scenicViews, const Color(0xFFE3F2FD), (value) {
          updateFilter(() {
            _scenicViews = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildFilterChip('🌙', 'Best at Night', _bestAtNight, const Color(0xFFE8EAF6), (value) {
          updateFilter(() {
            _bestAtNight = value;
            _updateActiveFiltersCount();
          });
        }),
        _buildFilterChip('🌅', 'Best at Sunset', _bestAtSunset, const Color(0xFFFFE0B2), (value) {
          updateFilter(() {
            _bestAtSunset = value;
            _updateActiveFiltersCount();
          });
        }),
      ],
    );
  }

  // Helper to build filter chips with custom colors
  Widget _buildFilterChip(String emoji, String label, bool isSelected, Color unselectedColor, Function(bool) onChanged) {
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

  // Build map view with markers for places
  Widget _buildMapView(List<Place> places, Position? userLocation) {
    // Safety check: if no places, show empty state
    if (places.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No places to display on map',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    // Determine initial camera position
    LatLng initialPosition;
    if (userLocation != null) {
      // Check if it's simulator coordinates
      final isSanFrancisco = (userLocation.latitude - 37.785834).abs() < 0.1 && 
                            (userLocation.longitude + 122.406417).abs() < 0.1;
      if (!isSanFrancisco) {
        initialPosition = LatLng(userLocation.latitude, userLocation.longitude);
      } else {
        // Use city center as fallback
        final currentCity = ref.read(locationNotifierProvider).value ?? 'Rotterdam';
        final cityCoords = _getCityCoordinates(currentCity);
        initialPosition = LatLng(cityCoords['lat']!, cityCoords['lng']!);
      }
    } else {
      // Use city center
      final currentCity = ref.read(locationNotifierProvider).value ?? 'Rotterdam';
      final cityCoords = _getCityCoordinates(currentCity);
      initialPosition = LatLng(cityCoords['lat']!, cityCoords['lng']!);
    }
    
    // Create markers for all places (not filtered - show everything on map)
    final Set<Marker> markers = {};
    final currentCity = ref.read(locationNotifierProvider).value ?? 'Rotterdam';
    
    for (int i = 0; i < places.length; i++) {
      final place = places[i];
      final markerId = MarkerId(place.id);
      
      // Determine marker color based on quick filters (visual indicator only)
      BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;
      if (_quickFilterRating45 && place.rating >= 4.5) {
        markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      } else if (_quickFilterDistance1km) {
        // Check if within 1km (for visual highlighting)
        final distance = _calculatePlaceDistance(place, userLocation, currentCity);
        if (distance != null && distance <= 1.0) {
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        }
      }
      
      // Store place ID for navigation
      final placeId = place.id;
      markers.add(
        Marker(
          markerId: markerId,
          position: LatLng(place.location.lat, place.location.lng),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.rating > 0 ? '⭐ ${place.rating.toStringAsFixed(1)}' : null,
          ),
          icon: markerIcon,
          onTap: () async {
            // Navigate to place detail when marker is tapped
            // Use a small delay to ensure context is stable
            await Future.delayed(const Duration(milliseconds: 100));
            if (mounted) {
              context.push('/place/$placeId');
            }
          },
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 300, // Proper height constraint
          child: Stack(
            children: [
              // Google Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialPosition,
                  zoom: 13,
                ),
                markers: markers,
                mapType: MapType.normal, // Ensure map type is set
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  if (kDebugMode) {
                    debugPrint('✅ Google Map created successfully');
                    debugPrint('📍 Initial position: ${initialPosition.latitude}, ${initialPosition.longitude}');
                    debugPrint('📍 Markers count: ${markers.length}');
                  }
                },
                onCameraMoveStarted: () {
                  if (kDebugMode) {
                    debugPrint('🗺️ Camera move started');
                  }
                },
                onTap: (LatLng position) {
                  if (kDebugMode) {
                    debugPrint('🗺️ Map tapped at: ${position.latitude}, ${position.longitude}');
                  }
                },
                // Error handling for map loading
                onCameraIdle: () {
                  if (kDebugMode) {
                    debugPrint('🗺️ Camera idle - map should be fully loaded');
                  }
                },
                myLocationEnabled: userLocation != null && 
                  (userLocation.latitude - 37.785834).abs() > 0.1, // Don't show if SF simulator
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false, // Hide default toolbar
                compassEnabled: true,
                // Additional map settings to ensure proper rendering
                trafficEnabled: false,
                buildingsEnabled: true,
                indoorViewEnabled: false,
              ),
              
              // Quick filter chips at the top
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Filters',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      // Distance filter (highlights places within 1km)
                      _buildQuickFilterChip(
                        '1km',
                        isActive: _quickFilterDistance1km,
                        onTap: () {
                          setState(() {
                            _quickFilterDistance1km = !_quickFilterDistance1km;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      // Rating filter (highlights places 4.5+)
                      _buildQuickFilterChip(
                        '4.5+',
                        isActive: _quickFilterRating45,
                        onTap: () {
                          setState(() {
                            _quickFilterRating45 = !_quickFilterRating45;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Get city coordinates for map initialization
  Map<String, double> _getCityCoordinates(String cityName) {
    final cityCoords = {
      'Rotterdam': {'lat': 51.9244, 'lng': 4.4777},
      'Amsterdam': {'lat': 52.3676, 'lng': 4.9041},
      'The Hague': {'lat': 52.0705, 'lng': 4.3007},
      'Utrecht': {'lat': 52.0907, 'lng': 5.1214},
      'Eindhoven': {'lat': 51.4416, 'lng': 5.4697},
      'Groningen': {'lat': 53.2194, 'lng': 6.5665},
      'Delft': {'lat': 52.0067, 'lng': 4.3556},
      'Beneden-Leeuwen': {'lat': 51.8892, 'lng': 5.5142},
    };
    return cityCoords[cityName] ?? cityCoords['Rotterdam']!;
  }
  
  /// Calculate distance for a place (helper for map markers)
  double? _calculatePlaceDistance(Place place, Position? userLocation, String cityName) {
    Position? referencePoint;
    
    if (userLocation != null) {
      final isSanFrancisco = (userLocation.latitude - 37.785834).abs() < 0.1 && 
                            (userLocation.longitude + 122.406417).abs() < 0.1;
      if (!isSanFrancisco) {
        referencePoint = userLocation;
      }
    }
    
    if (referencePoint == null) {
      final cityCoords = _getCityCoordinates(cityName);
      referencePoint = Position(
        latitude: cityCoords['lat']!,
        longitude: cityCoords['lng']!,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
    
    return DistanceService.calculateDistance(
      referencePoint.latitude,
      referencePoint.longitude,
      place.location.lat,
      place.location.lng,
    );
  }

  // Build quick filter chip for map view
  Widget _buildQuickFilterChip(
    String label, {
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF12B347).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF12B347) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFF12B347) : Colors.grey[800],
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