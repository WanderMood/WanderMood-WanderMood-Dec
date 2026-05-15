import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/moody_avatar_compact.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/services/distance_service.dart';
import 'package:wandermood/core/utils/explore_place_card_copy.dart';
import 'package:wandermood/core/utils/explore_quick_peek_copy.dart';
import 'package:wandermood/core/utils/place_card_photo_index.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/providers/moody_place_card_blurb_provider.dart';
import 'package:wandermood/features/places/services/places_service.dart';
import 'package:wandermood/features/places/services/reviews_cache_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';

const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmDusk = Color(0xFF4A4640);
const Color _wmStone = Color(0xFF8C8780);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmSunset = Color(0xFFE8784A);
const Color _wmWhite = Color(0xFFFFFFFF);

/// Compact Explore decision sheet — not the full place detail page.
Future<void> showExplorePlaceQuickPeekSheet({
  required BuildContext context,
  required Place place,
  required int photoSelectionSeed,
  Position? userLocation,
  String? cityName,
  required VoidCallback onViewFullPlace,
  required VoidCallback onAddToMyDay,
  required VoidCallback onPlanWithFriend,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.5,
        maxChildSize: 0.68,
        builder: (context, scrollController) {
          return Material(
            color: _wmCream,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: _ExplorePlaceQuickPeekBody(
              scrollController: scrollController,
              place: place,
              photoSelectionSeed: photoSelectionSeed,
              userLocation: userLocation,
              cityName: cityName,
              onViewFullPlace: () {
                Navigator.of(sheetContext).pop();
                onViewFullPlace();
              },
              onAddToMyDay: () {
                Navigator.of(sheetContext).pop();
                onAddToMyDay();
              },
              onPlanWithFriend: () {
                Navigator.of(sheetContext).pop();
                onPlanWithFriend();
              },
            ),
          );
        },
      );
    },
  );
}

class _ExplorePlaceQuickPeekBody extends ConsumerStatefulWidget {
  const _ExplorePlaceQuickPeekBody({
    required this.scrollController,
    required this.place,
    required this.photoSelectionSeed,
    this.userLocation,
    this.cityName,
    required this.onViewFullPlace,
    required this.onAddToMyDay,
    required this.onPlanWithFriend,
  });

  final ScrollController scrollController;
  final Place place;
  final int photoSelectionSeed;
  final Position? userLocation;
  final String? cityName;
  final VoidCallback onViewFullPlace;
  final VoidCallback onAddToMyDay;
  final VoidCallback onPlanWithFriend;

  @override
  ConsumerState<_ExplorePlaceQuickPeekBody> createState() =>
      _ExplorePlaceQuickPeekBodyState();
}

class _ExplorePlaceQuickPeekBodyState
    extends ConsumerState<_ExplorePlaceQuickPeekBody> {
  Map<String, dynamic>? _cachedReview;
  bool _reviewLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCachedReview());
  }

  Future<void> _loadCachedReview() async {
    final id = widget.place.id.trim();
    if (id.isEmpty) {
      if (mounted) setState(() => _reviewLoaded = true);
      return;
    }
    final reviews =
        await ref.read(reviewsCacheServiceProvider).getCachedReviews(id);
    if (!mounted) return;
    setState(() {
      _cachedReview = reviews != null && reviews.isNotEmpty ? reviews.first : null;
      _reviewLoaded = true;
    });
  }

  String? _distanceLabel() {
    Position? reference = widget.userLocation;
    final city = widget.cityName?.trim();
    if (reference == null && city != null && city.isNotEmpty) {
      const cityCoords = {
        'Rotterdam': (51.9244, 4.4777),
        'Amsterdam': (52.3676, 4.9041),
        'The Hague': (52.0705, 4.3007),
        'Utrecht': (52.0907, 5.1214),
      };
      final coords = cityCoords[city];
      if (coords != null) {
        reference = Position(
          latitude: coords.$1,
          longitude: coords.$2,
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
    }
    if (reference == null) return null;
    return DistanceService.formatDistance(
      DistanceService.calculateDistance(
        reference.latitude,
        reference.longitude,
        widget.place.location.lat,
        widget.place.location.lng,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final moodSlug = ref.watch(dailyMoodStateNotifierProvider).currentMood;
    final uiAsync = ref.watch(moodyPlaceCardUiDescriptionProvider(widget.place));
    final category =
        ExplorePlaceCardCopy.primaryTypeLabelForCard(widget.place, l10n);

    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(20, 8, 20, 10 + bottomInset),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _wmParchment,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 100,
            width: double.infinity,
            child: _QuickPeekHero(
              place: widget.place,
              photoSelectionSeed: widget.photoSelectionSeed,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.place.name,
          style: GoogleFonts.poppins(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: _wmCharcoal,
            height: 1.2,
            letterSpacing: -0.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        _MetaLine(
          category: category,
          rating: widget.place.rating,
        ),
        const SizedBox(height: 12),
        uiAsync.when(
          loading: () => const _MoodyTakeSkeleton(),
          error: (_, __) => _MoodyTakeCard(
            moodSlug: moodSlug,
            whyFits: ExploreQuickPeekCopy.whyFitsLine(moodSlug, l10n),
            take: null,
          ),
          data: (ui) => _MoodyTakeCard(
            moodSlug: moodSlug,
            whyFits: ExploreQuickPeekCopy.whyFitsLine(moodSlug, l10n),
            take: ExploreQuickPeekCopy.moodyTakeLine(ui, widget.place, l10n),
          ),
        ),
        const SizedBox(height: 10),
        _PracticalChips(
          place: widget.place,
          distance: _distanceLabel(),
          l10n: l10n,
        ),
        const SizedBox(height: 10),
        _FitsForRow(
          labels: ExploreQuickPeekCopy.fitsForLabels(
            widget.place,
            l10n,
            moodSlug: moodSlug,
          ),
          title: l10n.explorePeekFitsForTitle,
        ),
        if (_reviewLoaded &&
            ExploreQuickPeekCopy.miniReviewSnippet(_cachedReview) != null) ...[
          const SizedBox(height: 10),
          _MiniReviewCard(
            author: ExploreQuickPeekCopy.miniReviewAuthor(_cachedReview),
            snippet: ExploreQuickPeekCopy.miniReviewSnippet(_cachedReview)!,
            noteLabel: l10n.explorePeekVisitorNote,
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onAddToMyDay();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _wmForest,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.dayPlanCardAddToMyDay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onPlanWithFriend();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _wmForest,
                  backgroundColor: _wmForestTint,
                  side: const BorderSide(color: _wmForest, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  l10n.planMetVriendCta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onViewFullPlace();
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.explorePeekViewFullPlace,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _wmForest,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({this.category, required this.rating});

  final String? category;
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (category != null)
          Flexible(
            child: Text(
              category!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _wmStone,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (category != null && rating > 0)
          Text(' · ', style: GoogleFonts.poppins(color: _wmStone, fontSize: 13)),
        if (rating > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: _wmSunset, size: 15),
              const SizedBox(width: 2),
              Text(
                rating.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _wmCharcoal,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _MoodyTakeCard extends StatelessWidget {
  const _MoodyTakeCard({
    required this.moodSlug,
    this.whyFits,
    this.take,
  });

  final String? moodSlug;
  final String? whyFits;
  final String? take;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if ((whyFits == null || whyFits!.isEmpty) &&
        (take == null || take!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _wmWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _wmParchment),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MoodyAvatarCompact(
            size: 34,
            mood: moodSlug ?? 'idle',
            glowOpacityScale: 0.16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.explorePeekMoodyTakeTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _wmStone,
                    letterSpacing: 0.2,
                  ),
                ),
                if (whyFits != null && whyFits!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    whyFits!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _wmForest,
                      height: 1.35,
                    ),
                  ),
                ],
                if (take != null && take!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    take!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                      color: _wmDusk,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodyTakeSkeleton extends StatelessWidget {
  const _MoodyTakeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: _wmWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _wmParchment),
      ),
    );
  }
}

class _PracticalChips extends StatelessWidget {
  const _PracticalChips({
    required this.place,
    required this.l10n,
    this.distance,
  });

  final Place place;
  final AppLocalizations l10n;
  final String? distance;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (distance != null) {
      chips.add(_QuickPeekChip(
        icon: Icons.directions_walk_rounded,
        label: distance!,
      ));
    }
    if (ExplorePlaceCardCopy.shouldShowExplorePriceBadge(place)) {
      final price = ExplorePlaceCardCopy.explorePriceBadgeText(place, l10n);
      if (price.isNotEmpty) {
        chips.add(_QuickPeekChip(label: price, accent: true));
      }
    }
    chips.add(_QuickPeekChip(
      icon: Icons.schedule_rounded,
      label: l10n.dayPlanDurationMinutesOnly(
        ExplorePlaceCardCopy.suggestedVisitDurationMinutes(place),
      ),
    ));
    final hours = place.openingHours;
    if (hours != null) {
      chips.add(_QuickPeekChip(
        icon: hours.isOpen ? Icons.circle : Icons.circle_outlined,
        label: hours.isOpen ? l10n.dayPlanCardOpenNow : l10n.dayPlanCardClosed,
        accent: hours.isOpen,
      ));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }
}

class _FitsForRow extends StatelessWidget {
  const _FitsForRow({required this.labels, required this.title});

  final List<String> labels;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _wmStone,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: labels
              .map(
                (l) => _QuickPeekChip(
                  label: l,
                  accent: true,
                  soft: true,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _MiniReviewCard extends StatelessWidget {
  const _MiniReviewCard({
    required this.snippet,
    required this.noteLabel,
    this.author,
  });

  final String snippet;
  final String noteLabel;
  final String? author;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _wmWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _wmParchment),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            noteLabel,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _wmStone,
            ),
          ),
          if (author != null) ...[
            const SizedBox(height: 4),
            Text(
              author!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _wmCharcoal,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '“$snippet”',
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.4,
              color: _wmDusk,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickPeekChip extends StatelessWidget {
  const _QuickPeekChip({
    this.icon,
    required this.label,
    this.accent = false,
    this.soft = false,
  });

  final IconData? icon;
  final String label;
  final bool accent;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final fg = accent ? _wmForest : _wmDusk;
    final bg = soft
        ? _wmForestTint.withValues(alpha: 0.55)
        : accent
            ? _wmForestTint
            : _wmWhite;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent ? _wmForest.withValues(alpha: 0.22) : _wmParchment,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPeekHero extends ConsumerWidget {
  const _QuickPeekHero({
    required this.place,
    required this.photoSelectionSeed,
  });

  final Place place;
  final int photoSelectionSeed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<String>>(
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
              child: Icon(Icons.image_outlined, size: 36, color: _wmStone),
            ),
          );
        }
        final idx = placeCardPhotoIndex(
          place.id,
          photos.length,
          refreshSeed: photoSelectionSeed,
        );
        final safeIdx = math.min(math.max(idx, 0), photos.length - 1);
        final url = photos[safeIdx];
        if (place.isAsset) {
          return Image.asset(
            url,
            height: 100,
            width: double.infinity,
            fit: BoxFit.cover,
          );
        }
        return WmPlacePhotoNetworkImage(
          url,
          height: 100,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      },
    );
  }
}
