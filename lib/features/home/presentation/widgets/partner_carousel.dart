import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
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
  });

  final String label;
  final List<Place> places;
  final Position? userLocation;
  final String cityName;
  final int photoSelectionSeed;
  final void Function(Place place) onOpenPlace;
  final void Function(Place place) onAddToMyDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (places.length < 2) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1C18),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final place in places)
                SizedBox(
                  width: 328,
                  child: PlaceCard(
                    place: place,
                    userLocation: userLocation,
                    cityName: cityName,
                    photoSelectionSeed: photoSelectionSeed,
                    allowVisibilityEnrichment: true,
                    compactMoodCopy: true,
                    cardMargin: const EdgeInsets.only(
                        left: 8, right: 8, top: 2, bottom: 6),
                    onTap: () => onOpenPlace(place),
                    onAddToMyDayTap: () => onAddToMyDay(place),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
