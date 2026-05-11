import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/presentation/widgets/place_card.dart';

class PartnerCarousel extends ConsumerWidget {
  const PartnerCarousel({
    super.key,
    required this.label,
    required this.places,
    required this.userLocation,
    required this.cityName,
    required this.photoSelectionSeed,
    required this.onOpenPlace,
    required this.onAddToMyDay,
    this.onMoreTap,
  });

  final String label;
  final List<Place> places;
  final Position? userLocation;
  final String cityName;
  final int photoSelectionSeed;
  final void Function(Place place) onOpenPlace;
  final void Function(Place place) onAddToMyDay;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (places.length < 2) return const SizedBox.shrink();

    // PlaceCard is fairly tall (rich description + pills + CTA).
    // If we keep the carousel height too small, Flutter paints a "bottom overflow".
    final availableHeight = MediaQuery.sizeOf(context).height;
    final carouselHeight = math.min(640.0, availableHeight * 0.78);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1C18),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onMoreTap,
                child: Text(
                  'Meer →',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A6049),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: carouselHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              return SizedBox(
                width: 328,
                child: PlaceCard(
                  place: place,
                  userLocation: userLocation,
                  cityName: cityName,
                  photoSelectionSeed: photoSelectionSeed,
                  allowVisibilityEnrichment: true,
                  cardMargin: const EdgeInsets.only(
                      left: 8, right: 8, top: 2, bottom: 12),
                  onTap: () => onOpenPlace(place),
                  onAddToMyDayTap: () => onAddToMyDay(place),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
