import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/utils/explore_place_card_copy.dart';
import 'package:wandermood/core/utils/place_card_photo_index.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/services/places_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Map: quick read on a place before opening full detail (list/grid still push directly).
Future<void> showExplorePlaceQuickPeekSheet({
  required BuildContext context,
  required Place place,
  required int photoSelectionSeed,
  required VoidCallback onViewFullPlace,
  required VoidCallback onAddToMyDay,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.52,
        minChildSize: 0.36,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: SingleChildScrollView(
              controller: scrollController,
              child: _ExplorePlaceQuickPeekBody(
                place: place,
                photoSelectionSeed: photoSelectionSeed,
                onViewFullPlace: () {
                  Navigator.of(sheetContext).pop();
                  onViewFullPlace();
                },
                onAddToMyDay: () {
                  Navigator.of(sheetContext).pop();
                  onAddToMyDay();
                },
              ),
            ),
          );
        },
      );
    },
  );
}

class _ExplorePlaceQuickPeekBody extends ConsumerWidget {
  const _ExplorePlaceQuickPeekBody({
    required this.place,
    required this.photoSelectionSeed,
    required this.onViewFullPlace,
    required this.onAddToMyDay,
  });

  final Place place;
  final int photoSelectionSeed;
  final VoidCallback onViewFullPlace;
  final VoidCallback onAddToMyDay;

  static const double _photoHeight = 148;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final blurb = ExplorePlaceCardCopy.cardDescription(place, l10n);

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 10, 18, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0DCD4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: _photoHeight,
              width: double.infinity,
              child: FutureBuilder<List<String>>(
                future: ref
                    .read(placesServiceProvider.notifier)
                    .resolveExploreCardPhotos(place, maxPhotos: 8),
                initialData: place.photos.isNotEmpty ? place.photos : null,
                builder: (context, snapshot) {
                  final photos = snapshot.data ?? place.photos;
                  if (photos.isEmpty) {
                    return const ColoredBox(
                      color: Color(0xFFF0EDE6),
                      child: Center(
                        child: Icon(Icons.image_outlined,
                            size: 48, color: Color(0xFF8C8780)),
                      ),
                    );
                  }
                  final idx = placeCardPhotoIndex(
                    place.id,
                    photos.length,
                    refreshSeed: photoSelectionSeed,
                  );
                  final safeIdx =
                      math.min(math.max(idx, 0), photos.length - 1);
                  final url = photos[safeIdx];
                  if (place.isAsset) {
                    return Image.asset(
                      url,
                      height: _photoHeight,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFF0EDE6),
                        child: Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Color(0xFF8C8780)),
                        ),
                      ),
                    );
                  }
                  return WmPlacePhotoNetworkImage(
                    url,
                    height: _photoHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFFF0EDE6),
                      child: Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: Color(0xFF8C8780)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            place.name,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1C18),
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (place.rating > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFE8784A), size: 20),
                const SizedBox(width: 4),
                Text(
                  place.rating.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (blurb.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              blurb,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.4,
                color: const Color(0xFF4A4640),
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onViewFullPlace,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2A6049),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              l10n.explorePeekViewFullPlace,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onAddToMyDay,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2A6049),
              side: const BorderSide(color: Color(0xFF2A6049), width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              l10n.dayPlanAddToMyDay,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
