import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wandermood/features/places/services/saved_places_service.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/core/services/distance_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// A compact grid card for displaying places in a grid layout
class PlaceGridCard extends ConsumerWidget {
  final Place place;
  final VoidCallback onTap;
  final Position? userLocation;
  final String? cityName; // City name for fallback distance calculation

  const PlaceGridCard({
    Key? key,
    required this.place,
    required this.onTap,
    this.userLocation,
    this.cityName,
  }) : super(key: key);

  // Helper method to get emoji for energy level
  String _getEnergyEmoji(String energyLevel) {
    switch (energyLevel.toLowerCase()) {
      case 'low':
        return '🧘‍♀️';
      case 'medium':
        return '🚶‍♂️';
      case 'high':
        return '🏃‍♂️';
      default:
        return '🚶‍♂️';
    }
  }
  
  // Helper method to get color for energy level
  Color _getEnergyColor(String energyLevel) {
    switch (energyLevel.toLowerCase()) {
      case 'low':
        return Colors.teal;
      case 'medium':
        return Colors.amber;
      case 'high':
        return Colors.deepOrange;
      default:
        return Colors.amber;
    }
  }

  Widget _buildPlaceImage() {
    // Use photo URL if available
    if (place.photos.isNotEmpty) {
      return Image.network(
        place.photos.first,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage();
        },
      );
    }
    
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    // Select fallback image based on place type
    String imagePath = 'assets/images/fallbacks/default.jpg';
    
    if (place.types.contains('restaurant') || 
        place.types.contains('cafe') ||
        place.types.contains('food')) {
      imagePath = 'assets/images/brooke-lark-W1B2LpQOBxA-unsplash.jpg';
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
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 120,
            width: double.infinity,
            color: Colors.grey[300],
            child: Center(
              child: Icon(Icons.image_not_supported, size: 30, color: Colors.grey[500]),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        height: 120,
        width: double.infinity,
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.image_not_supported, size: 30, color: Colors.grey[500]),
        ),
      );
    }
  }
  
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
    return null;
  }

  // Calculate distance from user location to place with city center fallback
  String? _calculateDistance() {
    // Determine reference point: user location > city center > null
    Position? referencePoint;
    
    if (userLocation != null) {
      final userLat = userLocation!.latitude;
      final userLng = userLocation!.longitude;
      
      // Check if this is unrealistic coordinates (SF simulator)
      final isSanFrancisco = (userLat - 37.785834).abs() < 0.1 && (userLng + 122.406417).abs() < 0.1;
      
      if (!isSanFrancisco) {
        // Use valid user location
        referencePoint = userLocation;
      }
    }
    
    // Fallback to city center if user location unavailable or invalid
    if (referencePoint == null) {
      referencePoint = _getCityCenterCoordinates(cityName);
      if (referencePoint == null) {
        return null;
      }
    }
    
    final distance = DistanceService.calculateDistance(
      referencePoint.latitude,
      referencePoint.longitude,
      place.location.lat,
      place.location.lng,
    );
    
    return DistanceService.formatDistance(distance);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedPlacesAsync = ref.watch(savedPlacesProvider);
    final isFavorite = savedPlacesAsync.value?.any((sp) => sp.placeId == place.id) ?? false;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  // Main image
                  _buildPlaceImage(),
                  
                  // Open/closed indicator
                  if (place.openingHours?.isOpen != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: place.openingHours!.isOpen 
                              ? const Color(0xFF12B347) 
                              : Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          place.openingHours!.isOpen ? 'Open' : 'Closed',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                  // Action buttons (directions, share, favorite) - stacked vertically
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Get Directions button
                        GestureDetector(
                          onTap: () async {
                            final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${place.location.lat},${place.location.lng}');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.directions,
                              color: Color(0xFF12B347),
                              size: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Favorite indicator
                        GestureDetector(
                          onTap: () async {
                            final savedPlacesService = ref.read(savedPlacesServiceProvider);
                            try {
                              if (isFavorite) {
                                await savedPlacesService.unsavePlace(place.id);
                              } else {
                                await savedPlacesService.savePlace(place);
                              }
                              ref.invalidate(savedPlacesProvider);
                            } catch (e) {
                              // Error handling - could show snackbar if needed
                              if (kDebugMode) debugPrint('Error toggling save: $e');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey,
                              size: 14,
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
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and rating - fixed overflow
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (place.rating > 0) ...[
                        const SizedBox(width: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFFFFD700),
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              place.rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  // Optional short description (1–2 lines)
                  if (place.description != null && place.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      place.description!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        height: 1.3,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  // Distance and price info - compact layout with overflow protection
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Distance pill
                      if (_calculateDistance() != null)
                        _buildCategoryPill(
                          icon: Icons.directions_walk,
                          label: _calculateDistance()!,
                          color: const Color(0xFF12B347),
                        ),
                      // Price badge
                      if (_getPriceBadgeText().isNotEmpty)
                        _buildCategoryPill(
                          icon: _getCurrencyIcon(),
                          label: _getPriceBadgeText(),
                          color: _getPriceBadgeColor(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper function to capitalize first letter
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return "${text[0].toUpperCase()}${text.substring(1)}";
  }
  
  // Helper method to get icon for category
  IconData _getCategoryIcon(String type) {
    if (type.contains('restaurant') || type.contains('food') || type.contains('cafe')) {
      return Icons.restaurant;
    } else if (type.contains('museum') || type.contains('culture') || type.contains('art')) {
      return Icons.museum;
    } else if (type.contains('park') || type.contains('outdoor') || type.contains('nature')) {
      return Icons.park;
    } else if (type.contains('hotel') || type.contains('lodging')) {
      return Icons.hotel;
    } else {
      return Icons.place;
    }
  }
  
  // Helper method to get color for category
  Color _getCategoryColor(String type) {
    if (type.contains('restaurant') || type.contains('food') || type.contains('cafe')) {
      return Colors.orange;
    } else if (type.contains('museum') || type.contains('culture') || type.contains('art')) {
      return Colors.purple;
    } else if (type.contains('park') || type.contains('outdoor') || type.contains('nature')) {
      return Colors.green;
    } else if (type.contains('hotel') || type.contains('lodging')) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }
  
  // Build category pill with icon and optional label - overflow protected
  Widget _buildCategoryPill({
    required IconData icon,
    String? label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
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
            size: 12,
            color: color,
          ),
          if (label != null) ...[
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Get currency symbol based on location
  String _getCurrencySymbol() {
    final city = (cityName ?? '').toLowerCase();
    
    // UK cities
    if (['london', 'birmingham', 'manchester', 'glasgow', 'liverpool', 'leeds'].any((c) => city.contains(c))) {
      return '£';
    }
    
    // US cities
    if (['new york', 'los angeles', 'chicago', 'houston', 'phoenix', 'philadelphia', 'san antonio', 'san diego', 'dallas', 'boston', 'seattle'].any((c) => city.contains(c))) {
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
  
  /// Get price badge text
  String _getPriceBadgeText() {
    final currency = _getCurrencySymbol();
    
    // Check if truly free
    if (place.isFree || place.priceLevel == 0 || _isFreeByType()) {
      return 'Free 🎉';
    }
    
    // If we have explicit price range, use it
    if (place.priceRange != null) {
      return place.priceRange!.replaceAll(RegExp(r'[€£\$]'), currency);
    }
    
    // If we have explicit price level, convert to range
    if (place.priceLevel != null) {
      return _getPriceLevelText(place.priceLevel!, currency: currency);
    }
    
    // Infer from place types
    final inferredPrice = _inferPriceFromTypes(currency: currency);
    if (inferredPrice != null) {
      return inferredPrice;
    }
    
    // Last resort: show "Price varies"
    return 'Price varies';
  }
  
  String _getPriceLevelText(int priceLevel, {String currency = '€'}) {
    switch (priceLevel) {
      case 0: return 'Free 🎉';
      case 1: return '$currency 5-15';
      case 2: return '$currency 15-30';
      case 3: return '$currency 30-50';
      case 4: return '$currency 50+';
      default: return '';
    }
  }
  
  /// Infer price from place types
  String? _inferPriceFromTypes({String currency = '€'}) {
    if (_isFreeByType()) {
      return 'Free 🎉';
    }
    
    for (final type in place.types) {
      final typeLower = type.toLowerCase();
      if (['museum', 'tourist_attraction', 'amusement_park'].contains(typeLower)) {
        return '$currency 10-25';
      } else if (['restaurant', 'bar'].contains(typeLower)) {
        return '$currency 15-40';
      } else if (['cafe', 'store'].contains(typeLower)) {
        return '$currency 5-15';
      } else if (['hotel', 'spa'].contains(typeLower)) {
        return '$currency 50+';
      }
    }
    
    return null;
  }
  
  /// Check if place is free by type
  bool _isFreeByType() {
    final freeTypes = [
      'park', 'arboretum', 'garden', 'botanical_garden', 'natural_feature',
      'cemetery', 'church', 'mosque', 'synagogue', 'hindu_temple', 'library',
      'public_square', 'plaza', 'beach', 'hiking_area', 'walking_street',
      'street', 'route', 'neighborhood', 'locality', 'viewpoint', 'monument',
    ];
    
    return place.types.any((type) => 
      freeTypes.any((freeType) => 
        type.toLowerCase().contains(freeType.toLowerCase())
      )
    );
  }
  
  /// Get price badge color
  Color _getPriceBadgeColor() {
    if (place.isFree || place.priceLevel == 0 || _isFreeByType()) {
      return const Color(0xFF4CAF50); // Green for FREE
    }
    
    if (place.priceLevel != null) {
      switch (place.priceLevel!) {
        case 0: return const Color(0xFF4CAF50);
        case 1: return const Color(0xFF4CAF50);
        case 2: return const Color(0xFFFF9800);
        case 3: return const Color(0xFFE91E63);
        case 4: return const Color(0xFF9C27B0);
        default: return Colors.black.withOpacity(0.7);
      }
    }
    
    return Colors.black.withOpacity(0.7);
  }
} 