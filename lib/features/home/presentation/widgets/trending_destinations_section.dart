import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/core/services/distance_service.dart';
import 'package:wandermood/features/home/presentation/screens/all_trending_destinations_screen.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/providers/trending_destinations_provider.dart';

class TrendingDestinationsSection extends ConsumerWidget {
  final List<Place> destinations;

  const TrendingDestinationsSection({
    super.key,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCity =
        ref.watch(locationNotifierProvider).asData?.value ?? 'Rotterdam';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '🔥 Trending',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ).animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              ).shimmer(
                duration: const Duration(seconds: 3),
                color: const Color(0xFF2A6049).withOpacity(0.3),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => AllTrendingDestinationsScreen(
                        destinations: destinations,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFF2A6049),
                  size: 18,
                ),
                label: Text(
                  'See All',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2A6049),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              ).scale(
                duration: const Duration(seconds: 2),
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                trendingDestinationsProvider(city: currentCity),
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: destinations.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSpecialCard(
                    title: 'Last-Minute\nDeals',
                    emoji: '⏳',
                    color: Colors.orange,
                    subtitle: 'Save up to 50%',
                  );
                }
                if (index == destinations.length + 1) {
                  return _buildSpecialCard(
                    title: 'Hidden\nGems',
                    emoji: '💎',
                    color: Colors.purple,
                    subtitle: 'Discover unique places',
                  );
                }
                final destination = destinations[index - 1];
                return _buildDestinationCard(destination, ref, currentCity);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationCard(
    Place destination,
    WidgetRef ref,
    String currentCity,
  ) {
    final posAsync = ref.watch(userLocationProvider);
    final distanceKm = posAsync.maybeWhen(
      data: (pos) {
        if (pos == null) return null;
        if (destination.location.lat == 0 && destination.location.lng == 0) {
          return null;
        }
        return DistanceService.calculateDistance(
          pos.latitude,
          pos.longitude,
          destination.location.lat,
          destination.location.lng,
        ).round();
      },
      orElse: () => null,
    );
    final distanceLabel = distanceKm != null
        ? '$distanceKm km'
        : '${200 + destination.id.hashCode % 1000} km';

    final bookingsCount = 5 + (destination.id.hashCode % 38);

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: SizedBox(
        width: 160,
        child: Card(
          elevation: 8,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (destination.photos.isNotEmpty)
                Image.network(
                  destination.photos.first,
                  fit: BoxFit.cover,
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A6049),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$bookingsCount booked today',
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
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () =>
                      _shareDestination(destination, currentCity),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Colors.black54,
                      size: 16,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          destination.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distanceLabel,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (destination.types.isNotEmpty)
                      Text(
                        destination.types.first
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate()
          .fadeIn(duration: const Duration(milliseconds: 500))
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          ),
    );
  }

  Future<void> _shareDestination(Place destination, String city) async {
    try {
      final message =
          'Check out this trending destination: ${destination.name} in $city! Found via WanderMood app 🔥✨';
      await SharePlus.instance.share(ShareParams(text: message));
    } catch (e) {
      debugPrint('Error sharing destination: $e');
    }
  }

  Widget _buildSpecialCard({
    required String title,
    required String emoji,
    required Color color,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: SizedBox(
        width: 140,
        child: Card(
          elevation: 8,
          shadowColor: color.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.8),
                  color.withOpacity(0.6),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -20,
                  right: -20,
                  child: Text(
                    emoji,
                    style: TextStyle(
                      fontSize: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate(
        onPlay: (controller) => controller.repeat(reverse: true),
      ).shimmer(
        duration: const Duration(seconds: 3),
        color: Colors.white.withOpacity(0.3),
      ),
    );
  }
}
