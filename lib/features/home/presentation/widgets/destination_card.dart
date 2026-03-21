import 'package:flutter/material.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/presentation/widgets/place_image.dart';

class DestinationCard extends StatelessWidget {
  final Place place;
  final VoidCallback? onTap;
  final double elevation;
  final bool showDescription;
  final bool compact;

  const DestinationCard({
    super.key,
    required this.place,
    this.onTap,
    this.elevation = 2.0,
    this.showDescription = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            _buildImageSection(),

            // Content section
            Padding(
              padding: EdgeInsets.all(compact ? 12.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleRow(context),
                  if (showDescription && place.description != null && place.description!.isNotEmpty)
                    _buildDescription(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Image
        PlaceImage(
          imageUrl: place.photos.isNotEmpty
              ? place.photos.first
              : 'assets/images/fallbacks/default.jpg',
          height: 180,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),

        // Rating badge
        if (place.rating > 0)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    color: Color(0xFFFFB800),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    place.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            place.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      place.description!,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Colors.grey[600],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPriceLevelIndicator(int priceLevel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '\$' * priceLevel,
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  bool _isRelevantType(String type) {
    final relevantTypes = {
      'restaurant',
      'museum',
      'park',
      'shopping_mall',
      'tourist_attraction',
      'art_gallery',
      'cafe',
      'bar',
      'historic',
      'landmark',
    };
    return relevantTypes.contains(type);
  }

  Widget _buildOpeningHoursBanner(PlaceOpeningHours openingHours) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: openingHours.isOpen ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            openingHours.isOpen ? Icons.check_circle : Icons.access_time,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            openingHours.isOpen ? 'Open Now' : 'Closed',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.favorite_border,
        color: Colors.grey,
        size: 20,
      ),
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.share,
        color: Colors.grey,
        size: 20,
      ),
    );
  }

  Widget _buildActivityChip(BuildContext context, String type) {
    final displayType = type.replaceAll('_', ' ').toLowerCase();
    IconData icon;
    
    switch (type) {
      case 'restaurant':
        icon = Icons.restaurant;
        break;
      case 'museum':
        icon = Icons.museum;
        break;
      case 'park':
        icon = Icons.park;
        break;
      case 'shopping_mall':
        icon = Icons.shopping_bag;
        break;
      case 'tourist_attraction':
        icon = Icons.photo_camera;
        break;
      default:
        icon = Icons.place;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            displayType,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
} 