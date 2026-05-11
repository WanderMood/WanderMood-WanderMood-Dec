import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/services/partner_listing_service.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/services/places_service.dart';

class PartnerStoriesRow extends ConsumerWidget {
  const PartnerStoriesRow({
    super.key,
    required this.partners,
    required this.label,
    required this.onTapPartnerPlace,
  });

  final List<PartnerListing> partners;
  final String label;
  final void Function(Place place) onTapPartnerPlace;

  static const double circleSize = 64.0;
  static const double ringWidth = 2.5;

  static const Color ringColor = Color(0xFFE8784A);
  static const Color newDotColor = Color(0xFF5DCAA5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (partners.length < 3) return const SizedBox.shrink();
    final rows = partners
        .where((p) => p.placeId != null && p.placeId!.trim().isNotEmpty)
        .toList();
    if (rows.length < 3) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
              color: const Color(0xFF5DCAA5),
            ),
          ),
        ),
        SizedBox(
          height: 108,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final partner = rows[i];
              return SizedBox(
                width: 80,
                child: FutureBuilder<Place>(
                  future: ref
                      .read(placesServiceProvider.notifier)
                      .getPlaceById(partner.placeId!),
                  builder: (context, snap) {
                    final place = snap.data;
                    final photo = place?.photos.isNotEmpty == true
                        ? place!.photos.first
                        : '';
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap:
                          place == null ? null : () => onTapPartnerPlace(place),
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: circleSize,
                                height: circleSize,
                                padding: EdgeInsets.all(
                                    partner.isFeaturedThisWeek ? ringWidth : 0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: partner.isFeaturedThisWeek
                                      ? Border.all(
                                          color: ringColor, width: ringWidth)
                                      : null,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(
                                      partner.isFeaturedThisWeek ? 3 : 0),
                                  child: ClipOval(
                                    child: photo.isEmpty
                                        ? Container(
                                            color: const Color(0xFFE8E2D8),
                                            alignment: Alignment.center,
                                            child: Text(
                                              partner.businessName.isNotEmpty
                                                  ? partner.businessName
                                                      .substring(0, 1)
                                                      .toUpperCase()
                                                  : '?',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF2A6049),
                                              ),
                                            ),
                                          )
                                        : WmPlacePhotoNetworkImage(
                                            photo,
                                            fit: BoxFit.cover,
                                            width: circleSize,
                                            height: circleSize,
                                          ),
                                  ),
                                ),
                              ),
                              if (partner.showNewBadge)
                                const Positioned(
                                  right: 2,
                                  top: 1,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: newDotColor,
                                    ),
                                    child: SizedBox(width: 10, height: 10),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            partner.businessName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              height: 1.2,
                              color: const Color(0xFF4A4640),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
