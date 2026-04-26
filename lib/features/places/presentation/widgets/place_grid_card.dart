import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wandermood/features/places/services/saved_places_service.dart';
import 'package:wandermood/core/services/distance_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/features/places/services/places_service.dart';
import 'package:wandermood/core/utils/explore_place_card_copy.dart';
import 'package:wandermood/core/utils/place_card_photo_index.dart';
import 'package:wandermood/features/places/presentation/widgets/place_card_moody_description.dart';

const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmSunset = Color(0xFFE8784A);
const Color _wmError = Color(0xFFE05C5C);
const Color _wmDusk = Color(0xFF4A4640);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmStone = Color(0xFF8C8780);

/// A compact grid card for displaying places in a grid layout
class PlaceGridCard extends ConsumerWidget {
  final Place place;
  final VoidCallback onTap;
  final VoidCallback? onAddToMyDayTap;
  /// Optional callback when this place gets newly saved (not unsaved).
  final VoidCallback? onSavedTap;
  final Position? userLocation;
  final String? cityName; // City name for fallback distance calculation
  final int photoSelectionSeed;
  /// When true, grid card can fetch extra details/photos while visible.
  /// Set false for strict cache-only Explore scrolling.
  final bool allowVisibilityEnrichment;

  const PlaceGridCard({
    Key? key,
    required this.place,
    required this.onTap,
    this.onAddToMyDayTap,
    this.onSavedTap,
    this.userLocation,
    this.cityName,
    this.photoSelectionSeed = 0,
    this.allowVisibilityEnrichment = true,
  }) : super(key: key);

  static const double _kGridImageHeight = 96;

  Widget _buildPlaceImageArea(WidgetRef ref) {
    Widget buildPhotoAt(int index, List<String> photos) {
      final safeIndex = index >= 0 && index < photos.length ? index : 0;
      final photo = photos[safeIndex];
      if (place.isAsset) {
        return Image.asset(
          photo,
          height: _kGridImageHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
        );
      }
      return WmPlacePhotoNetworkImage(
        photo,
        height: _kGridImageHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
      );
    }

    return FutureBuilder<List<String>>(
      future: allowVisibilityEnrichment
          ? ref
              .read(placesServiceProvider.notifier)
              .resolveExploreCardPhotos(place, maxPhotos: 10)
          : Future.value(place.photos.take(10).toList()),
      initialData: place.photos.isNotEmpty ? place.photos : null,
      builder: (context, snapshot) {
        final photos = snapshot.data ?? place.photos;
        if (photos.isEmpty) return _buildFallbackImage();
        final idx = placeCardPhotoIndex(
          place.id,
          photos.length,
          refreshSeed: photoSelectionSeed,
        );
        return buildPhotoAt(idx, photos);
      },
    );
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
        height: _kGridImageHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: _kGridImageHeight,
            width: double.infinity,
            color: Colors.grey[300],
            child: Center(
              child: Icon(Icons.image_not_supported,
                  size: 30, color: Colors.grey[500]),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        height: _kGridImageHeight,
        width: double.infinity,
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.image_not_supported,
              size: 30, color: Colors.grey[500]),
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
      final cityCenter = _getCityCenterCoordinates(cityName);

      // Check if this is unrealistic coordinates (SF simulator)
      final isSanFrancisco = (userLat - 37.785834).abs() < 0.1 &&
          (userLng + 122.406417).abs() < 0.1;
      final isFarFromSelectedCity = cityCenter != null &&
          DistanceService.calculateDistance(
                userLat,
                userLng,
                cityCenter.latitude,
                cityCenter.longitude,
              ) >
              150;

      if (!isSanFrancisco && !isFarFromSelectedCity) {
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
    final l10n = AppLocalizations.of(context)!;
    final savedPlacesAsync = ref.watch(savedPlacesProvider);
    final isFavorite =
        savedPlacesAsync.value?.any((sp) => sp.placeId == place.id) ?? false;
    final currencySymbol = _getCurrencySymbol();
    final explorePriceLabel =
        ExplorePlaceCardCopy.shouldShowExplorePriceBadge(place)
            ? ExplorePlaceCardCopy.explorePriceBadgeText(
                place,
                l10n,
                currency: currencySymbol,
              )
            : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _wmWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _wmParchment, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 3,
              width: double.infinity,
              color: _wmForest,
            ),
            // Image section
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(9)),
              child: SizedBox(
                height: _kGridImageHeight,
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                  // Main image(s) — swipeable when the gallery has more than one photo
                  _buildPlaceImageArea(ref),

                  // Open/closed only (top-left) — social pills hidden for calmer grid cards.
                    if (place.openingHours != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: place.openingHours!.isOpen
                              ? _wmForest
                              : _wmError.withValues(alpha: 0.92),
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
                          place.openingHours!.isOpen
                              ? l10n.dayPlanCardOpenNow
                              : l10n.dayPlanCardClosed,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // Favorite only on grid — directions/maps live on place detail
                  // to keep tiles calmer and reduce accidental launches.
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Favorite indicator
                        GestureDetector(
                          onTap: () async {
                            final savedPlacesService =
                                ref.read(savedPlacesServiceProvider);
                            try {
                              if (isFavorite) {
                                await savedPlacesService.unsavePlace(place.id);
                              } else {
                                await savedPlacesService.savePlace(place);
                                onSavedTap?.call();
                              }
                              ref.invalidate(savedPlacesProvider);
                            } catch (e) {
                              // Error handling - could show snackbar if needed
                              if (kDebugMode)
                                debugPrint('Error toggling save: $e');
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
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? _wmSunset : Colors.grey,
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
            ),

            // Title + rating on separate lines (full-width name → less ugly truncation).
            // Body is top-aligned in a scroll view so we do not stretch content to fill
            // the whole flex region (that created tall bands of empty white).
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 5, 8, 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (place.rating > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: _wmSunset,
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            place.rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (place.reviewCount > 0) ...[
                            Text(
                              ' · ',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: _wmStone,
                              ),
                            ),
                            Text(
                              ExplorePlaceCardCopy.formatReviewCount(
                                  place.reviewCount),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: _wmStone,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 3),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PlaceCardMoodyDescription(
                              place: place,
                              maxLines: 3,
                              paddingTop: 0,
                              useCardStackLayout: false,
                              cacheOnly: !allowVisibilityEnrichment,
                              textStyle: GoogleFonts.poppins(
                                fontSize: 10.5,
                                height: 1.32,
                                color: _wmDusk,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Builder(
                              builder: (context) {
                                final primaryLbl =
                                    ExplorePlaceCardCopy
                                        .primaryTypeLabelForCard(
                                  place,
                                  l10n,
                                );
                                return Wrap(
                                  spacing: 3,
                                  runSpacing: 3,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    if (primaryLbl != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _wmForestTint,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _wmParchment,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          primaryLbl,
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            color: _wmForest,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    if (_calculateDistance() != null)
                                      _buildCategoryPill(
                                        icon: Icons.directions_walk,
                                        label: _calculateDistance()!,
                                        color: _wmForest,
                                      ),
                                    if (explorePriceLabel.isNotEmpty)
                                      _buildCategoryPill(
                                        icon: _getCurrencyIcon(),
                                        label: explorePriceLabel,
                                        color: ExplorePlaceCardCopy
                                            .explorePriceBadgeColor(place),
                                      ),
                                  ],
                                );
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
            if (onAddToMyDayTap != null)
              Material(
                color: _wmForest,
                child: InkWell(
                  onTap: onAddToMyDayTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 15),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            l10n.dayPlanAddToMyDay,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
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
    if (type.contains('restaurant') ||
        type.contains('food') ||
        type.contains('cafe')) {
      return Icons.restaurant;
    } else if (type.contains('museum') ||
        type.contains('culture') ||
        type.contains('art')) {
      return Icons.museum;
    } else if (type.contains('park') ||
        type.contains('outdoor') ||
        type.contains('nature')) {
      return Icons.park;
    } else if (type.contains('hotel') || type.contains('lodging')) {
      return Icons.hotel;
    } else {
      return Icons.place;
    }
  }

  // Helper method to get color for category
  Color _getCategoryColor(String type) {
    if (type.contains('restaurant') ||
        type.contains('food') ||
        type.contains('cafe')) {
      return Colors.orange;
    } else if (type.contains('museum') ||
        type.contains('culture') ||
        type.contains('art')) {
      return Colors.purple;
    } else if (type.contains('park') ||
        type.contains('outdoor') ||
        type.contains('nature')) {
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
    if (['london', 'birmingham', 'manchester', 'glasgow', 'liverpool', 'leeds']
        .any((c) => city.contains(c))) {
      return '£';
    }

    // US cities
    if ([
      'new york',
      'los angeles',
      'chicago',
      'houston',
      'phoenix',
      'philadelphia',
      'san antonio',
      'san diego',
      'dallas',
      'boston',
      'seattle'
    ].any((c) => city.contains(c))) {
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

}
