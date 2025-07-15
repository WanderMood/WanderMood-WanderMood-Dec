import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/core/services/distance_service.dart';
import 'package:wandermood/features/places/providers/saved_places_provider.dart';
import 'package:wandermood/features/places/services/sharing_service.dart';
import 'package:geolocator/geolocator.dart';

class PlaceCard extends ConsumerWidget {
  final Place place;
  final VoidCallback onTap;
  final Position? userLocation;

  const PlaceCard({
    Key? key,
    required this.place,
    required this.onTap,
    this.userLocation,
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

  String _getPriceLevelText(int? priceLevel) {
    if (priceLevel == null) return '';
    switch (priceLevel) {
      case 1:
        return 'Inexpensive';
      case 2:
        return 'Moderate';
      case 3:
        return 'Expensive';
      case 4:
        return 'Very Expensive';
      default:
        return '';
    }
  }



  /// Calculate distance from user location to place with caching
  String? _calculateDistance() {
    // Create cache key based on place ID and user location
    final userLat = userLocation?.latitude ?? 51.9225;
    final userLng = userLocation?.longitude ?? 4.4792;
    final cacheKey = '${place.id}_${userLat.toStringAsFixed(4)}_${userLng.toStringAsFixed(4)}';
    
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
    
    double finalUserLat, finalUserLng;
    
    if (userLocation != null) {
      // Check if this is unrealistic coordinates (outside Netherlands bounds or SF simulator)
      final lat = userLocation!.latitude;
      final lng = userLocation!.longitude;
      
      // Check for San Francisco simulator coordinates (approximate)
      final isSanFrancisco = (lat - 37.785834).abs() < 0.1 && (lng + 122.406417).abs() < 0.1;
      
      // Netherlands boundaries: lat 50.0-54.0, lng 3.0-8.0
      final isWithinNetherlands = lat >= 50.0 && lat <= 54.0 && lng >= 3.0 && lng <= 8.0;
      
      if (!isSanFrancisco && isWithinNetherlands) {
        finalUserLat = lat;
        finalUserLng = lng;
        // Only log once per cache refresh
        if (!_distanceCache.containsKey(cacheKey)) {
          debugPrint('📍 Using real user location for distance calculation: $lat, $lng');
        }
      } else {
        // Use Rotterdam city center for unrealistic coordinates (like simulator SF coordinates)
        finalUserLat = 51.9225;
        finalUserLng = 4.4792;
        // Only log once per cache refresh
        if (!_distanceCache.containsKey(cacheKey)) {
          debugPrint('📍 User location outside Netherlands bounds or SF simulator ($lat, $lng), using Rotterdam fallback');
        }
      }
    } else {
      // Use Rotterdam city center as fallback
      finalUserLat = 51.9225;
      finalUserLng = 4.4792;
      // Only log once per cache refresh
      if (!_distanceCache.containsKey(cacheKey)) {
        debugPrint('📍 Using Rotterdam city center as fallback for distance calculation');
      }
    }
    
    final distance = DistanceService.calculateDistance(
      finalUserLat,
      finalUserLng,
      place.location.lat,
      place.location.lng,
    );
    
    final formattedDistance = DistanceService.formatDistance(distance);
    
    // Only log once per cache refresh
    if (!_distanceCache.containsKey(cacheKey)) {
      debugPrint('📏 Distance to ${place.name}: $formattedDistance (${distance.toStringAsFixed(2)}km)');
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
      String cityPart = addressParts.last.trim();
      
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

  /// Get energy level color
  Color _getEnergyColor(String energyLevel) {
    switch (energyLevel.toLowerCase()) {
      case 'low':
        return const Color(0xFF66BB6A); // Calm green
      case 'medium':
        return const Color(0xFFFFB74D); // Medium orange
      case 'high':
        return const Color(0xFFFF6B6B); // High energy red
      default:
        return const Color(0xFFFFB74D);
    }
  }

  /// Get color for activity tags based on activity type
  Color _getTagColor(String activity) {
    final activityLower = activity.toLowerCase();
    
    // Food related
    if (activityLower.contains('food') || activityLower.contains('dining') || 
        activityLower.contains('restaurant') || activityLower.contains('cafe') ||
        activityLower.contains('cooking') || activityLower.contains('culinary')) {
      return const Color(0xFFFF6B6B); // Red
    }
    
    // Shopping related
    if (activityLower.contains('shop') || activityLower.contains('market') || 
        activityLower.contains('mall') || activityLower.contains('store')) {
      return const Color(0xFF4ECDC4); // Teal
    }
    
    // Culture/Art related
    if (activityLower.contains('art') || activityLower.contains('culture') || 
        activityLower.contains('museum') || activityLower.contains('gallery') ||
        activityLower.contains('history') || activityLower.contains('heritage')) {
      return const Color(0xFF45B7D1); // Blue
    }
    
    // Architecture related
    if (activityLower.contains('architect') || activityLower.contains('building') || 
        activityLower.contains('design') || activityLower.contains('landmark')) {
      return const Color(0xFF96CEB4); // Green
    }
    
    // Nature/Outdoor related
    if (activityLower.contains('park') || activityLower.contains('nature') || 
        activityLower.contains('outdoor') || activityLower.contains('garden') ||
        activityLower.contains('walking') || activityLower.contains('cycling')) {
      return const Color(0xFF66BB6A); // Nature green
    }
    
    // Entertainment/Fun related
    if (activityLower.contains('entertainment') || activityLower.contains('fun') || 
        activityLower.contains('game') || activityLower.contains('amusement') ||
        activityLower.contains('music') || activityLower.contains('show')) {
      return const Color(0xFFBA68C8); // Purple
    }
    
    // Sightseeing/Tours related
    if (activityLower.contains('sightseeing') || activityLower.contains('tour') || 
        activityLower.contains('view') || activityLower.contains('observation') ||
        activityLower.contains('photo')) {
      return const Color(0xFFFFB74D); // Orange
    }
    
    // Default color for other activities
    return const Color(0xFF12B347); // App primary green
  }

  Widget _buildPlaceImage() {
    if (place.photos.isEmpty) {
      return Container(
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
    }

    if (place.isAsset) {
      try {
        return Image.asset(
          place.photos.first,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading asset image: $error');
            return _buildFallbackImage();
          },
        );
      } catch (e) {
        debugPrint('Exception loading asset image: $e');
        return _buildFallbackImage();
      }
    } else {
      return Image.network(
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
                color: const Color(0xFF12B347),
              ),
            ),
          );
        },
      );
    }
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
    final savedPlacesAsync = ref.watch(savedPlacesProvider);
    final isFavorite = savedPlacesAsync.value?.any((p) => p.id == place.id) ?? false;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            // Primary shadow for depth
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            // Secondary shadow for ambient light
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
            // Subtle close shadow for definition
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: -1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                              ? const Color(0xFF12B347) 
                              : Colors.red.withOpacity(0.9),
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
                              place.openingHours!.isOpen ? 'Open' : 'Closed',
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
                      
                  // Action buttons (favorite and share)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Share button
                        GestureDetector(
                          onTap: () async {
                            try {
                              await SharingService.sharePlace(place);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to share place: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                                  spreadRadius: -1,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.share,
                              color: const Color(0xFF12B347),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Favorite button
                        GestureDetector(
                          onTap: () async {
                            await ref.read(savedPlacesProvider.notifier).toggleSave(place);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFavorite 
                                    ? '${place.name} removed from saved places' 
                                    : '${place.name} saved to favorites!'
                                ),
                                backgroundColor: isFavorite ? Colors.orange : const Color(0xFF12B347),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                  spreadRadius: -1,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                      ),
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
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (place.rating > 0) ...[
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
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
                                  '${place.energyLevel} energy',
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
                  
                  // Description with indoor/outdoor indicator
                  if (place.description != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Indoor/Outdoor icon
                        Icon(
                          place.isIndoor ? Icons.home : Icons.nature,
                          color: place.isIndoor 
                            ? const Color(0xFF66BB6A) 
                            : const Color(0xFF4ECDC4),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                      place.description!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey[800],
                      ),
                            maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                        ),
                  ],
                    ),
                  ],

                  // City with flag and distance
                  Builder(
                    builder: (context) {
                      final cityName = _extractCityName();
                      final countryFlag = _getCountryFlag();
                      final distance = _calculateDistance();
                      
                      if (cityName.isNotEmpty || distance != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Location with flag
                              if (cityName.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.grey[500],
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      cityName,
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      countryFlag,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                const SizedBox.shrink(),
                              ],
                              // Distance
                              if (distance != null) ...[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.directions_walk, color: const Color(0xFF12B347), size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      distance,
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF12B347),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                  
                  // Activity tags
                  if (place.activities.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: place.activities.take(3).map((activity) {
                        final tagColor = _getTagColor(activity);
                        final activityEmoji = _getActivityEmoji(activity);
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: tagColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: tagColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                activityEmoji,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                            activity,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                                  color: tagColor,
                                  fontWeight: FontWeight.w600,
                                ),
                            ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 