import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/services/partner_listing_service.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/services/places_service.dart';

/// Horizontal "stories" row for the curated Trending strip on Explore.
class PartnerStoriesRow extends ConsumerWidget {
  const PartnerStoriesRow({
    super.key,
    required this.partners,
    required this.headline,
    required this.onTapPartnerPlace,
  });

  final List<PartnerListing> partners;
  final String headline;
  final void Function(Place place) onTapPartnerPlace;

  static const double _avatarOuter = 72;
  static const double _avatarPhoto = 62;
  /// Dark espresso panel behind the trending strip.
  static const Color _espresso = Color(0xFF251A15);
  static const Color _espressoMid = Color(0xFF2E2119);
  /// Matches wandermood-landing `--home-accent` (e.g. Trending pills).
  static const Color _accentOrange = Color(0xFFE8784A);
  static const Color _gold = Color(0xFFD4A85A);
  static const Color _captionOnDark = Color(0xFFF0E6DC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (partners.length < 3) return const SizedBox.shrink();
    final rows = partners
        .where((p) => p.placeId != null && p.placeId!.trim().isNotEmpty)
        .toList();
    if (rows.length < 3) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _espresso,
              _espressoMid,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headline.toUpperCase(),
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.3,
                  height: 1.2,
                  color: _accentOrange,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 112,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final partner = rows[i];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: i == rows.length - 1 ? 0 : 12,
                      ),
                      child: SizedBox(
                        width: 84,
                        child: FutureBuilder<Place>(
                          future: ref
                              .read(placesServiceProvider.notifier)
                              .getPlaceById(partner.placeId!),
                          builder: (context, snap) {
                            final place = snap.data;
                            final photo = place?.photos.isNotEmpty == true
                                ? place!.photos.first
                                : '';
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: place == null
                                    ? null
                                    : () => onTapPartnerPlace(place),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                    horizontal: 2,
                                  ),
                                  child: Column(
                                    children: [
                                      _PartnerStoryAvatar(
                                        photo: photo,
                                        fallbackLetter: partner
                                                .businessName.isNotEmpty
                                            ? partner.businessName
                                                .substring(0, 1)
                                                .toUpperCase()
                                            : '?',
                                        featured: partner.isFeaturedThisWeek,
                                        showNew: partner.showNewBadge,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        partner.businessName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          height: 1.2,
                                          color: _captionOnDark,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartnerStoryAvatar extends StatelessWidget {
  const _PartnerStoryAvatar({
    required this.photo,
    required this.fallbackLetter,
    required this.featured,
    required this.showNew,
  });

  final String photo;
  final String fallbackLetter;
  final bool featured;
  final bool showNew;

  static const double _outer = PartnerStoriesRow._avatarOuter;
  static const double _photo = PartnerStoriesRow._avatarPhoto;

  @override
  Widget build(BuildContext context) {
    final ringGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: featured
          ? [
              PartnerStoriesRow._accentOrange.withValues(alpha: 0.9),
              PartnerStoriesRow._gold.withValues(alpha: 0.88),
              const Color(0xFFFFD89B).withValues(alpha: 0.86),
            ]
          : [
              PartnerStoriesRow._gold.withValues(alpha: 0.7),
              PartnerStoriesRow._accentOrange.withValues(alpha: 0.48),
            ],
    );

    return SizedBox(
      width: _outer,
      height: _outer,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: _outer,
            height: _outer,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: ringGradient,
              boxShadow: [
                BoxShadow(
                  color: PartnerStoriesRow._accentOrange.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Container(
                // Slightly larger inner disc = thinner visible gradient ring.
                width: _photo + 7,
                height: _photo + 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PartnerStoriesRow._espresso.withValues(alpha: 0.55),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.75,
                  ),
                ),
                alignment: Alignment.center,
                child: ClipOval(
                  child: photo.isEmpty
                      ? Container(
                          width: _photo,
                          height: _photo,
                          color: const Color(0xFF3D2E26),
                          alignment: Alignment.center,
                          child: Text(
                            fallbackLetter,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: PartnerStoriesRow._accentOrange,
                            ),
                          ),
                        )
                      : WmPlacePhotoNetworkImage(
                          photo,
                          fit: BoxFit.cover,
                          width: _photo,
                          height: _photo,
                        ),
                ),
              ),
            ),
          ),
          if (showNew)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF5DCAA5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: PartnerStoriesRow._espresso,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  'NEW',
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
