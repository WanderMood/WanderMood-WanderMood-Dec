import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/guest_demo_about_sections.dart';
import 'package:wandermood/core/utils/explore_place_card_copy.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/presentation/widgets/place_moody_copy_skeleton.dart';
import 'package:wandermood/features/places/providers/moody_place_card_blurb_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Place detail "About" body: sectioned rich copy when available, else long detail blurb in one titled block.
class PlaceDetailAboutBlock extends ConsumerWidget {
  const PlaceDetailAboutBlock({
    super.key,
    required this.place,
  });

  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final uiAsync = ref.watch(moodyPlaceCardUiDescriptionProvider(place));

    return uiAsync.when(
      data: (ui) {
        if (ui.isRich) {
          return GuestDemoAboutSectionsView(
            source: ui.sectionsSource!,
            compact: false,
          );
        }
        return _PlaceDetailPlainAboutBlurb(place: place, l10n: l10n);
      },
      loading: () => const PlaceMoodyCopySkeleton(compact: false),
      error: (_, __) => _PlaceDetailPlainAboutBlurb(place: place, l10n: l10n),
    );
  }
}

class _PlaceDetailPlainAboutBlurb extends ConsumerWidget {
  const _PlaceDetailPlainAboutBlurb({
    required this.place,
    required this.l10n,
  });

  final Place place;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blurAsync = ref.watch(moodyPlaceDetailBlurbProvider(place));

    return blurAsync.when(
      data: (blurb) {
        final body = blurb.trim().isEmpty
            ? ExplorePlaceCardCopy.detailFallbackDescription(place, l10n)
            : blurb.trim();
        return GuestDemoAboutSectionsView(
          source: '📚 ${l10n.placeDetailAboutThisPlace}\n\n$body',
          compact: false,
        );
      },
      loading: () => const PlaceMoodyCopySkeleton(compact: false),
      error: (_, __) => Text(
        ExplorePlaceCardCopy.detailFallbackDescription(place, l10n),
        style: GoogleFonts.poppins(
          fontSize: 14,
          height: 1.6,
          color: const Color(0xFF1E1C18).withValues(alpha: 0.85),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
