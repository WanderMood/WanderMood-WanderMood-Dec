import 'package:cached_network_image/cached_network_image.dart';
import 'package:wandermood/core/cache/wandermood_image_cache_manager.dart';
import 'package:wandermood/core/utils/explore_place_card_copy.dart';
import 'package:wandermood/core/utils/google_place_photo_device_url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/presentation/widgets/place_card_moody_description.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Design tokens — My Day free-time section (v2 spec).
/// Matches [MyDayTimelineSection] horizontal inset so carousel cards line up with timeline cards.
const double _kTimelineAlignPadding = 24;

const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmSunset = Color(0xFFE8784A);

class MyDayFreeTimeCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> activities;
  final void Function(Map<String, dynamic>) onActivityTap;
  final void Function(Map<String, dynamic>) onSaveTap;
  final void Function(Map<String, dynamic>) onDirectionsTap;
  /// When true, shows the section header and a loading indicator (not an empty sliver).
  final bool isLoading;
  /// When true, shows the section header and a short error hint.
  final bool loadFailed;

  const MyDayFreeTimeCarousel({
    super.key,
    required this.activities,
    required this.onActivityTap,
    required this.onSaveTap,
    required this.onDirectionsTap,
    this.isLoading = false,
    this.loadFailed = false,
  });

  @override
  State<MyDayFreeTimeCarousel> createState() => _MyDayFreeTimeCarouselState();
}

class _MyDayFreeTimeCarouselState extends State<MyDayFreeTimeCarousel> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    // ~0.78 shows more of the next card (peek) — matches compact My Day spec.
    _pageController = PageController(viewportFraction: 0.78);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.isLoading) {
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

    if (widget.loadFailed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(l10n),
          const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kTimelineAlignPadding),
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

    if (widget.activities.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(l10n),
          const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kTimelineAlignPadding),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(l10n),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: _kTimelineAlignPadding),
          child: LayoutBuilder(
            builder: (context, _) {
              // Taller than fixed 352 so Moody copy + pill wraps + CTAs fit (avoids bottom overflow).
              final screenH = MediaQuery.sizeOf(context).height;
              final cardHeight = (screenH * 0.26).clamp(400.0, 520.0);
              return SizedBox(
                height: cardHeight,
                child: PageView.builder(
              controller: _pageController,
              clipBehavior: Clip.none,
              padEnds: false,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.activities.length,
              itemBuilder: (context, index) {
                final activity = widget.activities[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _FreeTimeCard(
                    activity: activity,
                    onTap: () => widget.onActivityTap(activity),
                    onSaveTap: () => widget.onSaveTap(activity),
                    onDirectionsTap: () => widget.onDirectionsTap(activity),
                  ).animate(delay: (index * 120).ms)
                      .slideX(begin: 0.2, duration: 500.ms)
                      .fadeIn(duration: 500.ms),
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
}

/// Category / duration / rating / price / distance — aligned with Explore card pills.
class _FreeTimeMetaPillsRow extends StatelessWidget {
  const _FreeTimeMetaPillsRow({
    required this.l10n,
    required this.place,
    required this.distanceLabel,
    this.categoryFallback,
  });

  final AppLocalizations l10n;
  final Place place;
  final String distanceLabel;
  final String? categoryFallback;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final primary = ExplorePlaceCardCopy.primaryTypeLabelForCard(place, l10n);
    if (primary != null) {
      children.add(_forestPill(primary));
    } else if (categoryFallback != null && categoryFallback!.trim().isNotEmpty) {
      children.add(_forestPill(categoryFallback!.trim()));
    }
    children.add(_forestPill(
      ExplorePlaceCardCopy.exploreCardVisitDurationLabel(place, l10n),
    ));
    if (place.rating > 0) {
      children.add(_ratingPill(place.rating));
    }
    if (ExplorePlaceCardCopy.shouldShowExplorePriceBadge(place)) {
      children.add(_pricePill(place, l10n));
    }
    if (distanceLabel.isNotEmpty) {
      children.add(_walkPill(distanceLabel));
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  Widget _forestPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _wmForestTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wmParchment, width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _wmForest,
        ),
      ),
    );
  }

  Widget _ratingPill(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _wmForestTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wmParchment, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: _wmSunset, size: 12),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _wmForest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pricePill(Place p, AppLocalizations l10n) {
    final color = ExplorePlaceCardCopy.explorePriceBadgeColor(p);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.1),
      ),
      child: Text(
        ExplorePlaceCardCopy.explorePriceBadgeText(p, l10n),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _walkPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _wmForestTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wmParchment, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_walk_rounded, color: _wmForest, size: 12),
          const SizedBox(width: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _wmForest,
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeTimeCard extends ConsumerWidget {
  final Map<String, dynamic> activity;
  final VoidCallback onTap;
  final VoidCallback onSaveTap;
  final VoidCallback onDirectionsTap;

  const _FreeTimeCard({
    required this.activity,
    required this.onTap,
    required this.onSaveTap,
    required this.onDirectionsTap,
  });

  static String _categoryLabel(AppLocalizations l10n, String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return l10n.exploreCategoryFood;
      case 'exercise':
        return l10n.myDayFreeTimeCategoryExercise;
      case 'culture':
        return l10n.exploreCategoryCulture;
      case 'entertainment':
        return l10n.myDayFreeTimeCategoryEntertainment;
      case 'shopping':
        return l10n.exploreCategoryChipShopping;
      case 'social':
        return l10n.myDayFreeTimeCategorySocial;
      case 'nature':
        return l10n.exploreCategoryNature;
      default:
        return l10n.myDayFreeTimeCategorySpot;
    }
  }

  static String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return '🍽️';
      case 'exercise':
        return '🏃';
      case 'culture':
        return '🎨';
      case 'entertainment':
        return '🎭';
      case 'shopping':
        return '🛍️';
      case 'social':
        return '👋';
      case 'nature':
        return '🌳';
      default:
        return '📍';
    }
  }

  static String _insightLine(AppLocalizations l10n, Map<String, dynamic> activity) {
    final parts = <String>[];
    final duration = activity['duration'];
    if (duration is int && duration > 0) {
      parts.add(l10n.myDayFreeTimeInsightDuration(duration));
    } else if (duration is num && duration > 0) {
      parts.add(l10n.myDayFreeTimeInsightDuration(duration.round()));
    }
    final rating = (activity['rating'] as num?)?.toDouble();
    if (rating != null && rating > 0) {
      parts.add(l10n.myDayFreeTimeInsightRating(rating.toStringAsFixed(1)));
    }
    final isFree = activity['isFree'] == true;
    final pl = activity['priceLevel'];
    final priceLevel = pl is int ? pl : (pl is num ? pl.toInt() : null);
    if (isFree || priceLevel == 0) {
      parts.add('🎁 ${l10n.dayPlanCardFree}');
    } else if (priceLevel != null && priceLevel > 0 && priceLevel <= 4) {
      parts.add(l10n.myDayFreeTimeInsightPricePaid('€' * priceLevel));
    }
    if (parts.isEmpty) return '✨ ${l10n.myDayCarouselSpotFallbackDescription}';
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final l10n = AppLocalizations.of(context)!;
    final title = activity['title'] as String? ?? l10n.myDayActivityFallbackLabel;
    final description = activity['description'] as String? ?? '';
    final distance = activity['distance'] as String? ?? '';
    final category = (activity['category'] as String?) ?? '';
    final rawImageUrl = activity['imageUrl'] as String? ??
        'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&q=80';
    final imageUrl = deviceAccessibleGooglePlacePhotoUrl(rawImageUrl);
    final insight = _insightLine(l10n, activity);
    final catEmoji = category.isNotEmpty ? _categoryEmoji(category) : '✨';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: _wmWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _wmParchment, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shorter image strip → more vertical room for title / Moody / pills (reduces overflow).
            AspectRatio(
              aspectRatio: 2.35,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    cacheManager: WanderMoodImageCacheManager.instance,
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 600,
                    memCacheHeight: 260,
                    placeholder: (context, url) => Container(
                      color: _wmCream,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _wmForest,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: _wmCream,
                      child: Icon(Icons.image_outlined, color: _wmStone, size: 40),
                    ),
                  ),
                  if (distance.isNotEmpty)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _wmWhite.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _wmParchment, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.place_outlined, color: _wmStone, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              distance,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _wmCharcoal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _wmCharcoal,
                                height: 1.15,
                              ),
                            ),
                            if (activity['place'] is! Place) ...[
                              const SizedBox(height: 4),
                              Text(
                                insight,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _wmForest,
                                  height: 1.25,
                                ),
                              ),
                            ],
                            if (activity['place'] is Place) ...[
                              const SizedBox(height: 4),
                              PlaceCardMoodyDescription(
                                place: activity['place'] as Place,
                                maxLines: 5,
                                paddingTop: 0,
                                useCardStackLayout: true,
                                structuredTitleFontSize: 11,
                                structuredBodyFontSize: 11,
                                textStyle: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w400,
                                  color: _wmCharcoal.withValues(alpha: 0.78),
                                  height: 1.3,
                                ),
                              ),
                            ] else if (description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w400,
                                  color: _wmCharcoal.withValues(alpha: 0.78),
                                  height: 1.3,
                                ),
                              ),
                            ],
                            if (activity['place'] is Place) ...[
                              const SizedBox(height: 6),
                              _FreeTimeMetaPillsRow(
                                l10n: l10n,
                                place: activity['place'] as Place,
                                distanceLabel: distance,
                                categoryFallback: category.isNotEmpty
                                    ? '$catEmoji ${_categoryLabel(l10n, category)}'
                                    : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onSaveTap,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _wmForest,
                              side: const BorderSide(
                                  color: _wmForest, width: 1.5),
                              backgroundColor: _wmWhite,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              minimumSize: const Size(0, 34),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                l10n.prefSave,
                                maxLines: 1,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onDirectionsTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _wmForest,
                              foregroundColor: _wmWhite,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              minimumSize: const Size(0, 34),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                l10n.myDayFreeTimeDirectionsShort,
                                maxLines: 1,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
