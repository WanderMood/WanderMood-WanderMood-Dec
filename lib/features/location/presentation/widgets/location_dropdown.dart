import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/features/location/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

class LocationDropdown extends ConsumerStatefulWidget {
  const LocationDropdown({super.key});

  @override
  ConsumerState<LocationDropdown> createState() => _LocationDropdownState();
}

class _LocationDropdownState extends ConsumerState<LocationDropdown> {
  String? _countryCode;
  List<String> _popularCities = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCountryFromCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeCountryFromCurrentLocation() {
    // Determine country based on the current location from the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationAsync = ref.read(locationNotifierProvider);
      locationAsync.when(
        data: (location) => _setCountryFromLocationName(location),
        loading: () => _setDefaultCountry(),
        error: (_, __) => _setDefaultCountry(),
      );
    });
  }

  void _setCountryFromLocationName(String? locationName) {
    String countryCode = 'nl'; // Default to Netherlands
    
    if (locationName != null) {
      final location = locationName.toLowerCase();
      
      // Check if it's a known Dutch city
      if (['amsterdam', 'rotterdam', 'the hague', 'utrecht', 'eindhoven', 'groningen', 'tilburg', 'almere', 'breda', 'nijmegen'].contains(location)) {
        countryCode = 'nl';
      }
      // Check if it's a known US city
      else if (['new york', 'los angeles', 'chicago', 'houston', 'phoenix', 'philadelphia', 'san antonio', 'san diego', 'dallas', 'san jose', 'san francisco'].contains(location)) {
        countryCode = 'us';
      }
      // Check if it's a known UK city
      else if (['london', 'birmingham', 'manchester', 'glasgow', 'liverpool', 'leeds', 'sheffield', 'edinburgh', 'bristol', 'cardiff'].contains(location)) {
        countryCode = 'gb';
      }
      // Check if it's a known German city
      else if (['berlin', 'hamburg', 'munich', 'cologne', 'frankfurt', 'stuttgart', 'düsseldorf', 'leipzig', 'dortmund', 'essen'].contains(location)) {
        countryCode = 'de';
      }
      // Check if it's a known French city
      else if (['paris', 'marseille', 'lyon', 'toulouse', 'nice', 'nantes', 'strasbourg', 'montpellier', 'bordeaux', 'lille'].contains(location)) {
        countryCode = 'fr';
      }
      // Check if it's a known Spanish city
      else if (['madrid', 'barcelona', 'valencia', 'seville', 'zaragoza', 'málaga', 'murcia', 'palma', 'las palmas', 'bilbao'].contains(location)) {
        countryCode = 'es';
      }
      // Check if it's a known Italian city
      else if (['rome', 'milan', 'naples', 'turin', 'palermo', 'genoa', 'bologna', 'florence', 'bari', 'catania'].contains(location)) {
        countryCode = 'it';
      }
      // For Rotterdam or any Dutch-related location, default to Netherlands
      else if (location.contains('rotterdam') || location.contains('netherlands') || location.contains('holland')) {
        countryCode = 'nl';
      }
    }
    
    setState(() {
      _countryCode = countryCode;
      _popularCities = _getPopularCitiesForCountry(countryCode);
    });
  }

  void _setDefaultCountry() {
    setState(() {
      _countryCode = 'nl';
      _popularCities = _getPopularCitiesForCountry('nl');
    });
  }



  List<String> _getPopularCitiesForCountry(String? countryCode) {
    switch (countryCode?.toLowerCase()) {
      case 'nl': // Netherlands
        return ['Amsterdam', 'Rotterdam', 'The Hague', 'Utrecht', 'Eindhoven', 'Groningen', 'Tilburg', 'Almere', 'Breda', 'Nijmegen'];
      case 'us': // United States
        return ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose'];
      case 'gb': // United Kingdom
        return ['London', 'Birmingham', 'Manchester', 'Glasgow', 'Liverpool', 'Leeds', 'Sheffield', 'Edinburgh', 'Bristol', 'Cardiff'];
      case 'de': // Germany
        return ['Berlin', 'Hamburg', 'Munich', 'Cologne', 'Frankfurt', 'Stuttgart', 'Düsseldorf', 'Leipzig', 'Dortmund', 'Essen'];
      case 'fr': // France
        return ['Paris', 'Marseille', 'Lyon', 'Toulouse', 'Nice', 'Nantes', 'Strasbourg', 'Montpellier', 'Bordeaux', 'Lille'];
      case 'es': // Spain
        return ['Madrid', 'Barcelona', 'Valencia', 'Seville', 'Zaragoza', 'Málaga', 'Murcia', 'Palma', 'Las Palmas', 'Bilbao'];
      case 'it': // Italy
        return ['Rome', 'Milan', 'Naples', 'Turin', 'Palermo', 'Genoa', 'Bologna', 'Florence', 'Bari', 'Catania'];
      default:
        return ['Amsterdam', 'Rotterdam', 'The Hague', 'Utrecht']; // Default to Netherlands
    }
  }

  String _getCountryFlag(String? countryCode) {
    switch (countryCode?.toLowerCase()) {
      case 'nl': return '🇳🇱';
      case 'us': return '🇺🇸';
      case 'gb': return '🇬🇧';
      case 'de': return '🇩🇪';
      case 'fr': return '🇫🇷';
      case 'es': return '🇪🇸';
      case 'it': return '🇮🇹';
      default: return '🌍';
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Show loading state
      showWanderMoodToast(
        context,
        message: 'Getting your location...',
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF2A6049),
        leading: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );

      // Use the exact same logic as the Moody screen
      final location = await ref.read(locationNotifierProvider.notifier).getCurrentLocation();
      
      // Show result message
      showWanderMoodToast(
        context,
        message: 'Location: ${location ?? "Could not get location"}',
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF2A6049),
      );
      
      // The country and cities will automatically update via the listener
    } catch (e) {
      showWanderMoodToast(
        context,
        message:
            'Could not get your location. Please enable location services.',
        isError: true,
        actionLabel: 'Settings',
        onAction: () => LocationService.openAppSettings(),
      );
    }
  }

  Future<List<String>> _searchCities(String query) async {
    if (query.isEmpty) return [];
    
    try {
      // Filter popular cities first
      final filteredPopular = _popularCities
          .where((city) => city.toLowerCase().contains(query.toLowerCase()))
          .toList();
      
      // If we have good matches in popular cities, return those
      if (filteredPopular.isNotEmpty) {
        return filteredPopular.take(5).toList();
      }
      
      // Otherwise, try geocoding search
      final locations = await locationFromAddress('$query, ${_getCountryName()}');
      if (locations.isNotEmpty) {
        // Convert coordinates back to city names
        final cityNames = <String>[];
        for (final location in locations.take(3)) {
          try {
            final placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
            if (placemarks.isNotEmpty) {
              final city = placemarks.first.locality ?? placemarks.first.subAdministrativeArea;
              if (city != null && !cityNames.contains(city)) {
                cityNames.add(city);
              }
            }
          } catch (e) {
            // Skip this location if reverse geocoding fails
          }
        }
        return cityNames;
      }
    } catch (e) {
      // If search fails, return filtered popular cities
      return _popularCities
          .where((city) => city.toLowerCase().contains(query.toLowerCase()))
          .take(3)
          .toList();
    }
    
    return [];
  }

  String _getCountryName() {
    switch (_countryCode?.toLowerCase()) {
      case 'nl': return 'Netherlands';
      case 'us': return 'United States';
      case 'gb': return 'United Kingdom';
      case 'de': return 'Germany';
      case 'fr': return 'France';
      case 'es': return 'Spain';
      case 'it': return 'Italy';
      default: return 'Netherlands';
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationNotifierProvider);
    
    // Update country when location changes
    ref.listen<AsyncValue<String?>>(locationNotifierProvider, (previous, next) {
      next.when(
        data: (location) => _setCountryFromLocationName(location),
        loading: () => {},
        error: (_, __) => {},
      );
    });

    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      onSelected: (String value) {
        if (value == 'current_location') {
          _getCurrentLocation();
        } else if (value == 'search_cities') {
          _showCitySearchDialog();
        } else {
          // Set selected city
          ref.read(locationNotifierProvider.notifier).setLocation(value);
        }
      },
      itemBuilder: (BuildContext context) => [
        // Current Location Option
        PopupMenuItem<String>(
          value: 'current_location',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A6049).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.my_location,
                  size: 18,
                  color: Color(0xFF2A6049),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use Current Location',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Detect your exact location',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Search Cities Option
        PopupMenuItem<String>(
          value: 'search_cities',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.search,
                  size: 18,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Cities',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Find cities in ${_getCountryName()}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const PopupMenuDivider(),
        
        // Popular Cities Header
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              Text(
                _getCountryFlag(_countryCode),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'Popular Cities',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // Popular Cities List
        ..._popularCities.take(6).map((city) => PopupMenuItem<String>(
          value: city,
          child: Row(
            children: [
              const Icon(Icons.location_city, size: 18, color: Colors.grey),
              const SizedBox(width: 12),
              Text(city, style: GoogleFonts.poppins()),
            ],
          ),
        )),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            locationAsync.when(
              data: (location) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    location ?? 'Select Location',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white),
                ],
              ),
              loading: () => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Rotterdam (edit)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white),
                ],
              ),
              error: (error, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Your city',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCitySearchDialog() {
    List<String> searchResults = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Text(
                    _getCountryFlag(_countryCode),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Search Cities',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Field
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search cities in ${_getCountryName()}...',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF2A6049)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2A6049)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) async {
                        setState(() => isSearching = true);
                        final results = await _searchCities(value);
                        setState(() {
                          searchResults = results;
                          isSearching = false;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Results
                    Expanded(
                      child: isSearching
                          ? const Center(
                              child: CircularProgressIndicator(color: Color(0xFF2A6049)),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (searchResults.isNotEmpty) ...[
                                    Text(
                                      'Search Results',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...searchResults.map((city) => ListTile(
                                      leading: const Icon(Icons.location_city, color: Color(0xFF2A6049)),
                                      title: Text(city, style: GoogleFonts.poppins()),
                                      contentPadding: EdgeInsets.zero,
                                      onTap: () {
                                        ref.read(locationNotifierProvider.notifier).setLocation(city);
                                        Navigator.pop(context);
                                        _searchController.clear();
                                      },
                                    )),
                                  ] else if (_searchController.text.isEmpty) ...[
                                    Text(
                                      'Popular Cities',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ..._popularCities.map((city) => ListTile(
                                      leading: const Icon(Icons.location_city, color: Colors.grey),
                                      title: Text(city, style: GoogleFonts.poppins()),
                                      contentPadding: EdgeInsets.zero,
                                      onTap: () {
                                        ref.read(locationNotifierProvider.notifier).setLocation(city);
                                        Navigator.pop(context);
                                        _searchController.clear();
                                      },
                                    )),
                                  ] else ...[
                                    Center(
                                      child: Column(
                                        children: [
                                          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                                          const SizedBox(height: 8),
                                          Text(
                                            'No cities found',
                                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _searchController.clear();
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
} 