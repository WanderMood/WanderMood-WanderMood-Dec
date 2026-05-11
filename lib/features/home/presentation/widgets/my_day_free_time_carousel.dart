import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/presentation/widgets/place_card.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Design tokens — My Day free-time section (v2 spec).
/// Matches [MyDayTimelineSection] horizontal inset so carousel cards line up with timeline cards.
const double _kTimelineAlignPadding = 24;

const Color _wmForest = Color(0xFF2A6049);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);

/// Same horizontal [PlaceCard] strip as Explore [PartnerCarousel] (compact mood copy, max 10).
class MyDayFreeTimeCarousel extends ConsumerWidget {
  const MyDayFreeTimeCarousel({
    super.key,
    required this.activities,
    required this.onActivityTap,
    required this.onSaveTap,
    this.isLoading = false,
    this.loadFailed = false,
  });

  final List<Map<String, dynamic>> activities;
  final void Function(Map<String, dynamic>) onActivityTap;
  final void Function(Map<String, dynamic>) onSaveTap;
  final bool isLoading;
  final bool loadFailed;

  static const int _kMaxPlaces = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(l10n),
          const SizedBox(height: 24),
          const SizedBox(
            height: 120,
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: _wmForest,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (loadFailed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(l10n),
          const SizedBox(height: 12),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: _kTimelineAlignPadding),
            child: Text(
              l10n.myDayFreeTimeLoadingFailed,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.35,
                color: _wmStone,
              ),
            ),
          ),
        ],
      );
    }

    final withPlace = activities
        .where((a) => a['place'] is Place)
        .take(_kMaxPlaces)
        .toList();

    if (activities.isEmpty || withPlace.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(l10n),
          const SizedBox(height: 12),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: _kTimelineAlignPadding),
            child: Text(
              l10n.myDayFreeTimeEmptyHint,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.35,
                color: _wmStone,
              ),
            ),
          ),
        ],
      );
    }

    final userLocation = ref.watch(userLocationProvider).asData?.value;
    final city = ref.watch(locationNotifierProvider).asData?.value?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(l10n),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < withPlace.length; i++)
                SizedBox(
                  width: 328,
                  child: PlaceCard(
                    place: withPlace[i]['place'] as Place,
                    userLocation: userLocation,
                    cityName: city.isEmpty ? null : city,
                    photoSelectionSeed: 0,
                    allowVisibilityEnrichment: true,
                    compactMoodCopy: true,
                    cardMargin: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      top: 2,
                      bottom: 6,
                    ),
                    onTap: () => onActivityTap(withPlace[i]),
                    onAddToMyDayTap: () => onSaveTap(withPlace[i]),
                    onSavedTap: null,
                  )
                      .animate()
                      .fadeIn(
                        duration: 300.ms,
                        delay: Duration(milliseconds: i * 50),
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _sectionHeader(AppLocalizations l10n) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 32),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: _kTimelineAlignPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '✨ ',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _wmForest,
                    ),
                  ),
                  TextSpan(
                    text: l10n.myDayFreeTimeSectionTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _wmCharcoal,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.myDayFreeTimeIntroOneLine,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: _wmStone,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
