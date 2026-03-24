import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/core/services/distance_service.dart';
import 'package:wandermood/features/places/services/saved_places_service.dart';
import 'package:wandermood/features/places/services/sharing_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/plans/domain/enums/time_slot.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/l10n/app_localizations.dart';

// WM v2 tokens (aligned with My Day cards)
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmSunset = Color(0xFFE8784A);
const Color _wmSunsetTint = Color(0xFFFFE8DF);
const Color _wmDusk = Color(0xFF4A4640);
const Color _wmError = Color(0xFFE05C5C);

class PlaceCard extends ConsumerWidget {
  final Place place;
  final VoidCallback onTap;
  final Position? userLocation;
  final String? cityName; // City name for fallback distance calculation
  /// When false, hides the "Add to My Day" button.
  final bool showAddToMyDayButton;
  /// Optional override for the "Add to My Day" tap — e.g. to show a time-picker sheet.
  final VoidCallback? onAddToMyDayTap;
  /// When true, shows a "See activity" label (e.g. on Day Plan where we don't book yet).
  final bool showSeeActivityLabel;
  /// Outer margin around the card.
  final EdgeInsetsGeometry cardMargin;

  const PlaceCard({
    Key? key,
    required this.place,
    required this.onTap,
    this.userLocation,
    this.cityName,
    this.showAddToMyDayButton = true,
    this.onAddToMyDayTap,
    this.showSeeActivityLabel = false,
    this.cardMargin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  }) : super(key: key);

  // Cache distance calculation to prevent spam
  static final Map<String, String> _distanceCache = {};
  static final Map<String, DateTime> _distanceCacheTime = {};
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  
  // Clean up expired cache entries
  static void _cleanupCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    for (final entry in _distanceCacheTime.entries) {
      if (now.difference(entry.value) > _cacheValidDuration) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _distanceCache.remove(key);
      _distanceCacheTime.remove(key);
    }
  }

  String _getPriceLevel(int? priceLevel) {
    if (priceLevel == null) return '';
    switch (priceLevel) {
      case 1:
        return '\$';
      case 2:
        return '\$\$';
      case 3:
        return '\$\$\$';
      case 4:
        return '\$\$\$\$';
      default:
        return '';
    }
  }

  // Removed duplicate _getPriceLevelText method



  /// Get city center coordinates as fallback
  Position? _getCityCenterCoordinates(String? cityName) {
    if (cityName == null) return null;
    
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
    
    final coords = cityCoords[cityName];
    if (coords != null) {
      return Position(
        latitude: coords['lat']!,
        longitude: coords['lng']!,
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
    
    // Try to extract city from place address if not provided
    final extractedCity = _extractCityName();
    if (extractedCity.isNotEmpty) {
      final extractedCoords = cityCoords[extractedCity];
      if (extractedCoords != null) {
        return Position(
          latitude: extractedCoords['lat']!,
          longitude: extractedCoords['lng']!,
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
    }
    
    return null;
  }

  /// Calculate distance from user location to place with caching
  String? _calculateDistance() {
    // Determine reference point: user location > city center > null
    Position? referencePoint;
    late String cacheKey;
    
    if (userLocation != null) {
      final userLat = userLocation!.latitude;
      final userLng = userLocation!.longitude;
      
      // Check if this is unrealistic coordinates (SF simulator)
      final isSanFrancisco = (userLat - 37.785834).abs() < 0.1 && (userLng + 122.406417).abs() < 0.1;
      
      if (!isSanFrancisco) {
        // Use valid user location
        referencePoint = userLocation;
        cacheKey = '${place.id}_user_${userLat.toStringAsFixed(4)}_${userLng.toStringAsFixed(4)}';
      }
    }
    
    // Fallback to city center if user location unavailable or invalid
    if (referencePoint == null) {
      final cityCenter = _getCityCenterCoordinates(cityName);
      if (cityCenter != null) {
        referencePoint = cityCenter;
        cacheKey = '${place.id}_city_${cityCenter.latitude.toStringAsFixed(4)}_${cityCenter.longitude.toStringAsFixed(4)}';
      } else {
        // No reference point available
        return null;
      }
    }
    
    // Clean up expired cache entries periodically
    if (_distanceCache.length > 100) {
      _cleanupCache();
    }
    
    // Check cache first
    if (_distanceCache.containsKey(cacheKey) && _distanceCacheTime.containsKey(cacheKey)) {
      final cacheTime = _distanceCacheTime[cacheKey]!;
      if (DateTime.now().difference(cacheTime) < _cacheValidDuration) {
        return _distanceCache[cacheKey];
      }
    }
    
    // Calculate distance using reference point
    final distance = DistanceService.calculateDistance(
      referencePoint.latitude,
      referencePoint.longitude,
      place.location.lat,
      place.location.lng,
    );
    
    final formattedDistance = DistanceService.formatDistance(distance);
    
    // Only log once per cache refresh
    if (!_distanceCache.containsKey(cacheKey)) {
      debugPrint('📏 Distance to ${place.name}: $formattedDistance (${distance.toStringAsFixed(2)}km) from ${referencePoint == userLocation ? "user location" : "city center"}');
    }
    
    // Cache the result
    _distanceCache[cacheKey] = formattedDistance;
    _distanceCacheTime[cacheKey] = DateTime.now();
    
    return formattedDistance;
  }

  /// Extract city name from address
  String _extractCityName() {
    if (place.address.isEmpty) return '';
    
    // Extract city from address patterns like "Street 123, 1234 AB City" or "Street 123, City"
    final addressParts = place.address.split(',');
    if (addressParts.length >= 2) {
      String cityPart = addressParts.isNotEmpty 
          ? addressParts.last.trim() 
          : '';
      
      // Remove postal code pattern (e.g., "1234 AB Amsterdam" -> "Amsterdam")
      final postcodePattern = RegExp(r'^\d{4}\s*[A-Z]{2}\s*');
      cityPart = cityPart.replaceFirst(postcodePattern, '').trim();
      
      // Handle special cases and clean up
      cityPart = cityPart.replaceAll('Rotterdam', 'Rotterdam');
      cityPart = cityPart.replaceAll('Amsterdam', 'Amsterdam');
      cityPart = cityPart.replaceAll('The Hague', 'The Hague');
      cityPart = cityPart.replaceAll('Utrecht', 'Utrecht');
      
      return cityPart;
    }
    
    // Fallback: check if address contains common Dutch cities
    final addressLower = place.address.toLowerCase();
    if (addressLower.contains('rotterdam')) return 'Rotterdam';
    if (addressLower.contains('amsterdam')) return 'Amsterdam';
    if (addressLower.contains('the hague') || addressLower.contains('den haag')) return 'The Hague';
    if (addressLower.contains('utrecht')) return 'Utrecht';
    if (addressLower.contains('eindhoven')) return 'Eindhoven';
    if (addressLower.contains('groningen')) return 'Groningen';
    
    return '';
  }

  /// Get country flag emoji based on city or location
  String _getCountryFlag() {
    final city = _extractCityName().toLowerCase();
    
    // Netherlands cities
    if (['rotterdam', 'amsterdam', 'the hague', 'den haag', 'utrecht', 'eindhoven', 
         'groningen', 'tilburg', 'almere', 'breda', 'nijmegen', 'haarlem', 'arnhem',
         'zaanstad', 'haarlemmermeer', 'apeldoorn', 'enschede', 'leeuwarden'].contains(city)) {
      return '🇳🇱';
    }
    
    // US cities  
    if (['new york', 'los angeles', 'chicago', 'houston', 'phoenix', 'philadelphia',
         'san antonio', 'san diego', 'dallas', 'san jose', 'boston',
         'seattle', 'denver', 'washington', 'nashville', 'oklahoma city', 'el paso',
         'las vegas', 'detroit', 'memphis', 'louisville', 'baltimore', 'milwaukee'].contains(city)) {
      return '🇺🇸';
    }
    
    // UK cities
    if (['london', 'birmingham', 'manchester', 'glasgow', 'liverpool', 'leeds',
         'sheffield', 'edinburgh', 'bristol', 'cardiff', 'belfast', 'nottingham',
         'leicester', 'bradford', 'coventry', 'kingston upon hull', 'stoke-on-trent'].contains(city)) {
      return '🇬🇧';
    }
    
    // German cities
    if (['berlin', 'hamburg', 'munich', 'cologne', 'frankfurt', 'stuttgart',
         'düsseldorf', 'leipzig', 'dortmund', 'essen', 'bremen', 'dresden',
         'hanover', 'nuremberg', 'duisburg', 'bochum', 'wuppertal'].contains(city)) {
      return '🇩🇪';
    }
    
    // French cities
    if (['paris', 'marseille', 'lyon', 'toulouse', 'nice', 'nantes',
         'strasbourg', 'montpellier', 'bordeaux', 'lille', 'rennes', 'reims',
         'le havre', 'saint-étienne', 'toulon', 'grenoble', 'dijon'].contains(city)) {
      return '🇫🇷';
    }
    
    // Spanish cities
    if (['madrid', 'barcelona', 'valencia', 'seville', 'zaragoza', 'málaga',
         'murcia', 'palma', 'las palmas', 'bilbao', 'alicante', 'córdoba',
         'valladolid', 'vigo', 'gijón', 'hospitalet de llobregat'].contains(city)) {
      return '🇪🇸';
    }
    
    // Italian cities
    if (['rome', 'milan', 'naples', 'turin', 'palermo', 'genoa',
         'bologna', 'florence', 'bari', 'catania', 'venice', 'verona',
         'messina', 'padua', 'trieste', 'taranto', 'brescia'].contains(city)) {
      return '🇮🇹';
    }
    
    // Swiss cities (like in your reference image)
    if (['zurich', 'geneva', 'basel', 'lausanne', 'bern', 'winterthur',
         'lucerne', 'st. gallen', 'lugano', 'biel', 'thun', 'köniz'].contains(city)) {
      return '🇨🇭';
    }
    
    // Default to Netherlands flag (most places in app are in Netherlands)
    return '🇳🇱';
  }

  /// Get emoji for activity tags based on activity type
  String _getActivityEmoji(String activity) {
    final activityLower = activity.toLowerCase();
    
    // Food related
    if (activityLower.contains('food') || activityLower.contains('dining') || 
        activityLower.contains('restaurant') || activityLower.contains('cafe') ||
        activityLower.contains('cooking') || activityLower.contains('culinary')) {
      return '🍽️';
    }
    
    // Shopping related
    if (activityLower.contains('shop') || activityLower.contains('market') || 
        activityLower.contains('mall') || activityLower.contains('store')) {
      return '🛍️';
    }
    
    // Culture/Art related
    if (activityLower.contains('art') || activityLower.contains('culture') || 
        activityLower.contains('museum') || activityLower.contains('gallery') ||
        activityLower.contains('history') || activityLower.contains('heritage')) {
      return '🎨';
    }
    
    // Architecture related
    if (activityLower.contains('architect') || activityLower.contains('building') || 
        activityLower.contains('design') || activityLower.contains('landmark')) {
      return '🏛️';
    }
    
    // Nature/Outdoor related
    if (activityLower.contains('park') || activityLower.contains('nature') || 
        activityLower.contains('outdoor') || activityLower.contains('garden') ||
        activityLower.contains('walking') || activityLower.contains('cycling')) {
      return '🌳';
    }
    
    // Entertainment/Fun related
    if (activityLower.contains('entertainment') || activityLower.contains('fun') || 
        activityLower.contains('game') || activityLower.contains('amusement') ||
        activityLower.contains('music') || activityLower.contains('show')) {
      return '🎪';
    }
    
    // Sightseeing/Tours/Photography related
    if (activityLower.contains('sightseeing') || activityLower.contains('tour') || 
        activityLower.contains('view') || activityLower.contains('observation') ||
        activityLower.contains('photo')) {
      return '📸';
    }
    
    // Sports related
    if (activityLower.contains('sport') || activityLower.contains('fitness') || 
        activityLower.contains('gym') || activityLower.contains('climbing')) {
      return '⚽';
    }
    
    // Spa/Wellness related
    if (activityLower.contains('spa') || activityLower.contains('wellness') || 
        activityLower.contains('massage') || activityLower.contains('relax')) {
      return '💆';
    }
    
    // Jazz/Music related
    if (activityLower.contains('jazz') || activityLower.contains('concert') || 
        activityLower.contains('musical')) {
      return '🎵';
    }
    
    // Travel/Transportation related
    if (activityLower.contains('bike') || activityLower.contains('harbor') || 
        activityLower.contains('boat') || activityLower.contains('transport')) {
      return '🚲';
    }
    
    // Default emoji for other activities
    return '📍';
  }

  /// Get energy level icon
  String _getEnergyIcon(String energyLevel) {
    switch (energyLevel.toLowerCase()) {
      case 'low':
        return '🧘'; // Calm/meditative
      case 'medium':
        return '⚡'; // Medium energy bolt
      case 'high':
        return '🔥'; // High energy fire
      default:
        return '⚡';
    }
  }

  /// Get energy level label (standard terms instead of "low/medium/high energy")
  String _getEnergyLabel(String energyLevel) {
    switch (energyLevel.toLowerCase()) {
      case 'low':
        return 'Relaxing';
      case 'medium':
        return 'Moderate pace';
      case 'high':
        return 'Active';
      default:
        return 'Moderate pace';
    }
  }

  /// Get energy level color — all variants use forest to stay on-palette.
  Color _getEnergyColor(String energyLevel) {
    switch (energyLevel.toLowerCase()) {
      case 'low':
        return _wmForest;
      case 'medium':
        return _wmForest;
      case 'high':
        return const Color(0xFF8F7355); // warm bronze for "active"
      default:
        return _wmForest;
    }
  }

  /// Get color for activity tags based on activity type
  Color _getTagColor(String activity) {
    final activityLower = activity.toLowerCase();
    
    // Food related
    if (activityLower.contains('food') || activityLower.contains('dining') || 
        activityLower.contains('restaurant') || activityLower.contains('cafe') ||
        activityLower.contains('cooking') || activityLower.contains('culinary')) {
      return _wmSunset;
    }
    
    // Shopping related
    if (activityLower.contains('shop') || activityLower.contains('market') || 
        activityLower.contains('mall') || activityLower.contains('store')) {
      return _wmForest;
    }
    
    // Culture/Art related
    if (activityLower.contains('art') || activityLower.contains('culture') || 
        activityLower.contains('museum') || activityLower.contains('gallery') ||
        activityLower.contains('history') || activityLower.contains('heritage')) {
      return _wmForest;
    }
    
    // Architecture related
    if (activityLower.contains('architect') || activityLower.contains('building') || 
        activityLower.contains('design') || activityLower.contains('landmark')) {
      return _wmForest;
    }
    
    // Nature/Outdoor related
    if (activityLower.contains('park') || activityLower.contains('nature') || 
        activityLower.contains('outdoor') || activityLower.contains('garden') ||
        activityLower.contains('walking') || activityLower.contains('cycling')) {
      return _wmForest;
    }
    
    // Entertainment/Fun related
    if (activityLower.contains('entertainment') || activityLower.contains('fun') || 
        activityLower.contains('game') || activityLower.contains('amusement') ||
        activityLower.contains('music') || activityLower.contains('show')) {
      return _wmSunset;
    }
    
    // Sightseeing/Tours related
    if (activityLower.contains('sightseeing') || activityLower.contains('tour') || 
        activityLower.contains('view') || activityLower.contains('observation') ||
        activityLower.contains('photo')) {
      return _wmSunset;
    }
    
    // Default color for other activities
    return _wmForest;
  }

  Widget _buildPlaceImage() {
    Widget mainImage;
    
    // Determine the main image
    if (place.photos.isEmpty) {
      mainImage = Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 40, color: Colors.grey[500]),
              const SizedBox(height: 8),
              Text(
                place.name.substring(0, place.name.length > 15 ? 15 : place.name.length),
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else if (place.isAsset) {
      try {
        if (place.photos.isEmpty) {
          mainImage = _buildFallbackImage();
        } else {
          mainImage = Image.asset(
            place.photos.first,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading asset image: $error');
              return _buildFallbackImage();
            },
          );
        }
      } catch (e) {
        debugPrint('Exception loading asset image: $e');
        mainImage = _buildFallbackImage();
      }
    } else {
      if (place.photos.isEmpty) {
        mainImage = _buildFallbackImage();
      } else {
        mainImage = Image.network(
          place.photos.first,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading network image: $error');
            return _buildFallbackImage();
          },
          loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: const Color(0xFF2A6049),
              ),
            ),
          );
        },
        );
      }
    }
    
    // Return stack with image and badges
    return Stack(
      children: [
        // Main image
        mainImage,
        
        // Removed incorrectly positioned price badge - will add to content section instead
          
        // Duration badge if available
        if (place.tag != null && place.tag!.contains('hr'))
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    place.tag!,
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
      ],
    );
  }

  Widget _buildFallbackImage() {
    // Use a category-specific placeholder based on place types - using real images
    String imagePath = 'assets/images/philipp-kammerer-6Mxb_mZ_Q8E-unsplash.jpg';

    if (place.types.contains('restaurant') || 
        place.types.contains('cafe') || 
        place.types.contains('food')) {
      imagePath = 'assets/images/tom-podmore-3mEK924ZuTs-unsplash.jpg';
    } else if (place.types.contains('museum') || 
              place.types.contains('art_gallery')) {
      imagePath = 'assets/images/pietro-de-grandi-T7K4aEPoGGk-unsplash.jpg';
    } else if (place.types.contains('park') || 
              place.types.contains('natural_feature')) {
      imagePath = 'assets/images/dino-reichmuth-A5rCN8626Ck-unsplash.jpg';
    } else if (place.types.contains('bar') || 
              place.types.contains('night_club')) {
      imagePath = 'assets/images/pedro-lastra-Nyvq2juw4_o-unsplash.jpg';
    } else if (place.types.contains('lodging') || 
              place.types.contains('hotel')) {
      imagePath = 'assets/images/mesut-kaya-eOcyhe5-9sQ-unsplash.jpg';
    }

    try {
      return Image.asset(
        imagePath,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading fallback image: $error');
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[300],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 40, color: Colors.grey[500]),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      place.name,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Exception loading fallback image: $e');
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey[500]),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Check if place is saved using the new Supabase service
    final savedPlacesAsync = ref.watch(savedPlacesProvider);
    final isFavorite = savedPlacesAsync.value?.any((sp) => sp.place.id == place.id) ?? false;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: cardMargin,
        decoration: BoxDecoration(
          color: _wmWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _wmParchment, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 7),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
              spreadRadius: -1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              width: double.infinity,
              color: _wmForest,
            ),
            // Image section
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  // Main image
                  _buildPlaceImage(),
                      
                  // Opening hours pill
                  if (place.openingHours?.todayHours != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: place.openingHours!.isOpen
                              ? _wmForest
                              : _wmError.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              place.openingHours!.isOpen ? Icons.check_circle : Icons.cancel,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              place.openingHours!.isOpen
                                  ? l10n.dayPlanCardOpenNow
                                  : l10n.dayPlanCardClosed,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                      
                  // Action icon column — unified frosted-glass circles
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CardIconButton(
                          icon: Icons.near_me_rounded,
                          onTap: () => _openDirections(context),
                        ),
                        const SizedBox(height: 8),
                        _CardIconButton(
                          icon: Icons.ios_share_rounded,
                          onTap: () async {
                            try {
                              await SharingService.sharePlace(place);
                            } catch (e) {
                              showWanderMoodToast(
                                context,
                                message: l10n.placeCardFailedToShare('$e'),
                                isError: true,
                              );
                            }
                          },
                        ),
                        if (showAddToMyDayButton) ...[
                          const SizedBox(height: 8),
                          _CardIconButton(
                            icon: Icons.add_circle_outline_rounded,
                            onTap: () => _addToMyDay(context, ref),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _CardIconButton(
                          icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          iconColor: isFavorite ? _wmSunset : null,
                          onTap: () async {
                            final savedPlacesService = ref.read(savedPlacesServiceProvider);
                            try {
                              if (isFavorite) {
                                await savedPlacesService.unsavePlace(place.id);
                                ref.invalidate(savedPlacesProvider);
                                showWanderMoodToast(
                                  context,
                                  message: l10n.dayPlanCardRemovedFromSaved(place.name),
                                  isWarning: true,
                                );
                              } else {
                                await savedPlacesService.savePlace(place);
                                ref.invalidate(savedPlacesProvider);
                                showWanderMoodToast(
                                  context,
                                  message: l10n.placeCardSaved(place.name),
                                );
                              }
                            } catch (e) {
                              if (kDebugMode) debugPrint('❌ Error toggling favorite: $e');
                              showWanderMoodToast(
                                context,
                                message: l10n.placeCardFailedToggleSave(place.name),
                                isError: true,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Place name and rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (place.rating > 0) ...[
                        Row(
                          children: [
                            const Icon(Icons.star, color: _wmSunset, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              place.rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (place.reviewCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${place.reviewCount} reviews)',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                  
                  // Place tag and Energy Level
                  if (place.tag != null || place.energyLevel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (place.tag != null) ...[
                        Text(
                          place.tag!,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                        if (place.tag != null && place.energyLevel.isNotEmpty) 
                          const SizedBox(width: 12),
                        if (place.energyLevel.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getEnergyColor(place.energyLevel).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getEnergyColor(place.energyLevel).withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getEnergyIcon(place.energyLevel),
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getEnergyLabel(place.energyLevel),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: _getEnergyColor(place.energyLevel),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  
                  // Description
                  if (place.description != null && place.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      place.description!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.5,
                        color: _wmDusk,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Bottom metadata row: price pill + distance pill + Mijn Dag CTA
                  Builder(
                    builder: (context) {
                      final distance = _calculateDistance();
                      final hasPricePill = _shouldShowPriceBadge();
                      final hasDistancePill = distance != null;
                      if (!hasPricePill && !hasDistancePill && !showAddToMyDayButton) {
                        return const SizedBox(height: 4);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Row(
                          children: [
                            // Price pill
                            if (hasPricePill) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _getPriceBadgeColor().withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getPriceBadgeColor().withValues(alpha: 0.55),
                                    width: 1.25,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_getCurrencyIcon(), color: _getPriceBadgeColor(), size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getPriceBadgeText(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: _getPriceBadgeColor(),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            // Distance pill
                            if (hasDistancePill) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _wmForestTint,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _wmParchment, width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.directions_walk_rounded, color: _wmForest, size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      distance,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: _wmForest,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const Spacer(),
                            // Mijn Dag CTA
                            if (showAddToMyDayButton)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: onAddToMyDayTap ?? () => _addToMyDay(context, ref),
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: _wmForest,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _wmForest.withValues(alpha: 0.22),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          l10n.dayPlanAddToMyDay,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  // "See activity" label when used on Day Plan
                  if (showSeeActivityLabel) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.visibility_outlined, size: 18, color: _wmForest),
                        const SizedBox(width: 6),
                        Text(
                          'See activity',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _wmForest,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build category pill with icon and label
  Widget _buildCategoryPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
                        return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
                            border: Border.all(
          color: color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
          Icon(
            icon,
            size: 14,
            color: color,
                              ),
          const SizedBox(width: 4),
                              Text(
            label,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
                                ),
                            ),
                            ],
                          ),
                        );
  }
  
  // Helper method to build type pill
  Widget _buildTypePill(String type) {
    String label = type.replaceAll('_', ' ');
    label = label[0].toUpperCase() + label.substring(1);
    
    IconData icon;
    Color color;
    
    if (type.contains('restaurant') || type.contains('food') || type.contains('cafe')) {
      icon = Icons.restaurant;
      color = Colors.orange;
    } else if (type.contains('museum') || type.contains('culture') || type.contains('art')) {
      icon = Icons.museum;
      color = Colors.purple;
    } else if (type.contains('park') || type.contains('outdoor') || type.contains('nature')) {
      icon = Icons.park;
      color = Colors.green;
    } else if (type.contains('hotel') || type.contains('lodging')) {
      icon = Icons.hotel;
      color = Colors.blue;
    } else {
      icon = Icons.place;
      color = Colors.grey;
    }
    
    return _buildCategoryPill(
      icon: icon,
      label: label,
      color: color,
    );
  }

  /// Get currency symbol based on location
  String _getCurrencySymbol() {
    final city = (cityName ?? _extractCityName()).toLowerCase();
    final countryFlag = _getCountryFlag();
    
    // UK cities
    if (countryFlag == '🇬🇧' || ['london', 'birmingham', 'manchester', 'glasgow', 'liverpool', 'leeds'].any((c) => city.contains(c))) {
      return '£';
    }
    
    // US cities
    if (countryFlag == '🇺🇸' || ['new york', 'los angeles', 'chicago', 'houston', 'phoenix', 'philadelphia', 'san antonio', 'san diego', 'dallas', 'boston', 'seattle'].any((c) => city.contains(c))) {
      return '\$';
    }
    
    // Default to Euro for Netherlands and most European countries
    return '€';
  }
  
  /// Get currency icon based on currency symbol
  IconData _getCurrencyIcon() {
    final currency = _getCurrencySymbol();
    switch (currency) {
      case '£':
        return Icons.currency_pound;
      case '\$':
        return Icons.attach_money;
      case '€':
      default:
        return Icons.euro_symbol;
    }
  }

  // Pricing helper methods
  bool _shouldShowPriceBadge() {
    final hasPriceRange = (place.priceRange?.trim().isNotEmpty ?? false);
    return place.isFree || place.priceLevel != null || hasPriceRange;
  }
  
  String _getPriceBadgeText() {
    final currency = _getCurrencySymbol();
    
    // Show only explicit backend-derived free state
    if (place.isFree || place.priceLevel == 0) {
      return 'Free';
    }
    
    // If we have explicit price range, use it (but replace currency if needed)
    if (place.priceRange != null && place.priceRange!.trim().isNotEmpty) {
      // Replace any existing currency symbols with the detected one
      return place.priceRange!.replaceAll(RegExp(r'[€£\$]'), currency);
    }
    
    // If we have explicit price level, convert to range with currency
    if (place.priceLevel != null) {
      return _getPriceLevelText(place.priceLevel!, currency: currency);
    }
    
    return '';
  }
  
  Color _getPriceBadgeColor() {
    // Explicit free states
    if (place.isFree || place.priceLevel == 0) {
      return _wmForest;
    }
    
    if (place.priceLevel != null) {
      switch (place.priceLevel!) {
        case 0:
        case 1:
          return _wmForest;
        case 2:
        case 3:
        case 4:
          return _wmSunset;
        default:
          return _wmDusk.withValues(alpha: 0.8);
      }
    }
    
    // Default color for price range
    return _wmDusk.withValues(alpha: 0.8);
  }
  
  String _getPriceLevelText(int priceLevel, {String currency = '€'}) {
    switch (priceLevel) {
      case 0: return 'Free';
      case 1: return '$currency 5-15';
      case 2: return '$currency 15-30';
      case 3: return '$currency 30-50';
      case 4: return '$currency 50+';
      default: return '';
    }
  }
  
  // Helper to check if place is free based on type
  bool _isFreeByType() {
    final freeTypes = [
      'park',
      'arboretum',
      'garden',
      'botanical_garden',
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
      'viewpoint',
      'monument',
    ];
    
    return place.types.any((type) => 
      freeTypes.any((freeType) => 
        type.toLowerCase().contains(freeType.toLowerCase())
      )
    );
  }
  
  // Helper method to check if place is wheelchair accessible
  bool _isWheelchairAccessible() {
    // Check place types for accessibility indicators
    for (final type in place.types) {
      if (type.toLowerCase().contains('accessible')) {
        return true;
      }
    }
    
    // Check activities for accessibility keywords
    for (final activity in place.activities) {
      final activityLower = activity.toLowerCase();
      if (activityLower.contains('wheelchair') || 
          activityLower.contains('accessible') || 
          activityLower.contains('accessibility')) {
        return true;
      }
    }
    
    // Check description for accessibility mentions
    if (place.description != null) {
      final descLower = place.description!.toLowerCase();
      if (descLower.contains('wheelchair') || 
          descLower.contains('accessible') || 
          descLower.contains('accessibility')) {
        return true;
      }
    }
    
    return false;
  }
  
  // Add to My Day: saves to Supabase (scheduled_activities) so My Day shows it.
  Future<void> _addToMyDay(BuildContext context, WidgetRef ref) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _showErrorSnackBar(context, 'Please sign in to add activities to My Day');
        return;
      }

      final timeOfDay = _getRecommendedTimeOfDay();
      final duration = _getEstimatedDuration();
      final startTime = _getDefaultStartTimeForToday(timeOfDay);
      final timeSlotEnum = timeOfDay == 'morning'
          ? TimeSlot.morning
          : timeOfDay == 'afternoon'
              ? TimeSlot.afternoon
              : TimeSlot.evening;

      PaymentType paymentType = PaymentType.free;
      if (place.types.contains('restaurant') ||
          place.types.contains('spa') ||
          place.types.contains('museum') ||
          place.types.contains('tourist_attraction')) {
        paymentType = PaymentType.reservation;
      }

      final imageUrl = place.photos.isNotEmpty ? place.photos.first : '';

      final activity = Activity(
        id: 'place_${place.id}_${DateTime.now().millisecondsSinceEpoch}',
        name: place.name,
        description: place.description ?? '',
        imageUrl: imageUrl,
        rating: place.rating,
        startTime: startTime,
        duration: duration,
        timeSlot: timeOfDay,
        timeSlotEnum: timeSlotEnum,
        tags: place.types,
        location: LatLng(place.location.lat, place.location.lng),
        paymentType: paymentType,
        priceLevel: place.priceRange,
        // Preserve place link so My Day/Agenda can open rich Place Detail.
        placeId: place.id,
      );

      final scheduledActivityService = ref.read(scheduledActivityServiceProvider);
      await scheduledActivityService.saveScheduledActivities([activity], isConfirmed: false);

      ref.invalidate(scheduledActivityServiceProvider);
      ref.invalidate(scheduledActivitiesForTodayProvider);
      ref.invalidate(todayActivitiesProvider);
      ref.invalidate(cachedActivitySuggestionsProvider);

      if (context.mounted) {
        _showSuccessSnackBar(context, 'Added ${place.name} to My Day!');
      }
    } catch (e) {
      debugPrint('Error adding to My Day: $e');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to add ${place.name} to My Day');
      }
    }
  }

  /// Default start time for today so the activity appears in My Day (today filter).
  DateTime _getDefaultStartTimeForToday(String timeOfDay) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (timeOfDay) {
      case 'morning':
        return today.add(const Duration(hours: 9));
      case 'afternoon':
        return today.add(const Duration(hours: 14));
      case 'evening':
        return today.add(const Duration(hours: 18));
      default:
        return today.add(const Duration(hours: 14));
    }
  }

  // Open directions functionality
  Future<void> _openDirections(BuildContext context) async {
    try {
      // Check if maps are available
      final availableMaps = await MapLauncher.installedMaps;
      
      if (availableMaps.isNotEmpty) {
        // Use the first available map app
        await availableMaps.first.showMarker(
          coords: Coords(place.location.lat, place.location.lng),
          title: place.name,
          description: place.address,
        );
      } else {
        // Fallback to Google Maps web
        final url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${place.location.lat},${place.location.lng}'
        );
        
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not open maps';
        }
      }
    } catch (e) {
      debugPrint('Error opening directions: $e');
      _showErrorSnackBar(context, 'Unable to open directions');
    }
  }

  // Helper methods
  String _getRecommendedTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  int _getEstimatedDuration() {
    // Estimate duration based on place type
    for (final type in place.types) {
      final typeLower = type.toLowerCase();
      if (['museum', 'tourist_attraction', 'amusement_park'].contains(typeLower)) {
        return 120; // 2 hours
      } else if (['restaurant', 'cafe'].contains(typeLower)) {
        return 60; // 1 hour
      } else if (['store', 'shopping_mall'].contains(typeLower)) {
        return 90; // 1.5 hours
      }
    }
    return 60; // Default 1 hour
  }

  DateTime _getDefaultStartTime() {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Schedule for next appropriate time slot
    if (hour < 9) {
      return DateTime(now.year, now.month, now.day, 10, 0); // 10 AM
    } else if (hour < 14) {
      return DateTime(now.year, now.month, now.day, 15, 0); // 3 PM
    } else {
      return DateTime(now.year, now.month, now.day + 1, 10, 0); // Tomorrow 10 AM
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    showWanderMoodToast(
      context,
      message: message,
      duration: const Duration(seconds: 4),
      actionLabel: 'View',
      onAction: () {
        if (context.mounted) {
          context.go('/main', extra: {'tab': 0});
        }
      },
    );
  }

  void _showInfoSnackBar(BuildContext context, String message) {
    showWanderMoodToast(
      context,
      message: message,
      isWarning: true,
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    showWanderMoodToast(
      context,
      message: message,
      isError: true,
      duration: const Duration(seconds: 3),
    );
  }
}

/// Unified frosted-glass icon button used on place card image overlay.
class _CardIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _CardIconButton({required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFE8E2D8).withValues(alpha: 0.6),
            width: 0.75,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor ?? const Color(0xFF2A6049),
          size: 18,
        ),
      ),
    );
  }
}