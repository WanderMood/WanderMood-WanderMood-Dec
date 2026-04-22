import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/presentation/utils/save_explore_place_to_my_day.dart';
import 'package:wandermood/features/places/presentation/widgets/add_place_to_my_day_sheet.dart';
import 'package:wandermood/features/places/services/saved_places_service.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/services/taste_profile_service.dart';

class MoodySuggestedPlacesRow extends StatelessWidget {
  const MoodySuggestedPlacesRow({
    super.key,
    required this.places,
    required this.leftInset,
  });

  final List<Place> places;
  final double leftInset;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();

    return _MoodySuggestedPlacesFadeIn(
      child: Padding(
        padding: EdgeInsets.only(left: leftInset, top: 8, right: 12),
        child: _MoodySuggestedPlacesCarousel(places: places),
      ),
    );
  }
}

/// Horizontal strip of place cards **without** a nested horizontal [Scrollable].
///
/// A horizontal [ListView] inside the vertical chat [ListView] keeps winning the
/// gesture arena, so the thread stops scrolling. Here we pan with
/// [Transform.translate] driven from [Listener.onPointerMove] when movement is
/// mostly horizontal ([Listener] does not compete with the parent scroll view).
class _MoodySuggestedPlacesCarousel extends StatefulWidget {
  const _MoodySuggestedPlacesCarousel({required this.places});

  final List<Place> places;

  @override
  State<_MoodySuggestedPlacesCarousel> createState() =>
      _MoodySuggestedPlacesCarouselState();
}

class _MoodySuggestedPlacesCarouselState extends State<_MoodySuggestedPlacesCarousel> {
  static const double _cardWidth = 160;
  static const double _separatorWidth = 8;

  /// Horizontal translation (≤ 0). Clamped when viewport/content size changes.
  double _dragOffset = 0;

  double _contentWidth() {
    final n = widget.places.length;
    return n * _cardWidth + (n > 1 ? (n - 1) * _separatorWidth : 0);
  }

  void _nudgeParentVertical(double dy) {
    if (!mounted || dy == 0) return;
    final scrollable = Scrollable.maybeOf(context, axis: Axis.vertical);
    if (scrollable == null) return;
    final position = scrollable.position;
    if (!position.hasContentDimensions) return;
    final target = (position.pixels - dy)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if (target != position.pixels) {
      position.jumpTo(target);
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    final dx = e.delta.dx;
    final dy = e.delta.dy;
    if (dx.abs() <= dy.abs()) {
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    final viewportW = box?.size.width;
    if (viewportW == null || !viewportW.isFinite || viewportW <= 0) return;

    final contentW = _contentWidth();
    final minOffset = math.min(0.0, viewportW - contentW);

    setState(() {
      final synced = _dragOffset.clamp(minOffset, 0.0);
      _dragOffset = (synced + dx).clamp(minOffset, 0.0);
    });
  }

  bool _samePlaceStrip(List<Place> a, List<Place> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant _MoodySuggestedPlacesCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_samePlaceStrip(oldWidget.places, widget.places) && _dragOffset != 0) {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentW = _contentWidth();
        final viewportW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final minOffset = math.min(0.0, viewportW - contentW);
        final displayOffset = _dragOffset.clamp(minOffset, 0.0);

        final row = SizedBox(
          height: 180,
          width: contentW,
          child: Row(
            children: [
              for (var i = 0; i < widget.places.length; i++) ...[
                if (i > 0) const SizedBox(width: _separatorWidth),
                _MiniPlaceCard(place: widget.places[i]),
              ],
            ],
          ),
        );

        // Viewport-sized box: the [Row] is wider than the strip; without a bounded
        // width the layout overflows ("RIGHT OVERFLOWED BY … PIXELS").
        return Listener(
          onPointerMove: _onPointerMove,
          onPointerSignal: (signal) {
            if (signal is! PointerScrollEvent) return;
            final d = signal.scrollDelta;
            if (d.dy.abs() > d.dx.abs()) {
              if (d.dy != 0) _nudgeParentVertical(d.dy);
              return;
            }
            if (d.dx != 0) {
              setState(() {
                final s = _dragOffset.clamp(minOffset, 0.0);
                _dragOffset = (s + d.dx).clamp(minOffset, 0.0);
              });
            }
          },
          child: SizedBox(
            width: viewportW,
            height: 180,
            child: ClipRect(
              clipBehavior: Clip.hardEdge,
              // Let the card row lay out at [contentW] while this strip stays
              // [viewportW] wide — otherwise the [Row] is given maxWidth ==
              // viewport and overflows by (contentW - viewportW) (~174px).
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: contentW,
                maxWidth: contentW,
                minHeight: 180,
                maxHeight: 180,
                child: Transform.translate(
                  offset: Offset(displayOffset, 0),
                  child: row,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MoodySuggestedPlacesFadeIn extends StatefulWidget {
  const _MoodySuggestedPlacesFadeIn({required this.child});

  final Widget child;

  @override
  State<_MoodySuggestedPlacesFadeIn> createState() =>
      _MoodySuggestedPlacesFadeInState();
}

class _MoodySuggestedPlacesFadeInState extends State<_MoodySuggestedPlacesFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fade only — [SizeTransition] animates height from 0 and can give inner
    // [Column]/[Expanded] children transient bad constraints, triggering
    // "Incorrect use of ParentDataWidget" and breaking chat scroll.
    return FadeTransition(
      opacity: _opacity,
      child: widget.child,
    );
  }
}

class _MiniPlaceCard extends ConsumerWidget {
  const _MiniPlaceCard({required this.place});

  final Place place;

  String _readableType(String raw) {
    final t = raw.replaceAll('_', ' ').trim();
    if (t.isEmpty) return '';
    return t[0].toUpperCase() + (t.length > 1 ? t.substring(1) : '');
  }

  String _blurb(Place p) {
    final primary = (p.primaryType ?? '').trim();
    final social = (p.socialSignal ?? '').trim();
    final best = (p.bestTime ?? '').trim();
    for (final s in [
      (p.editorialSummary ?? '').trim(),
      (p.description ?? '').trim(),
      (p.tag ?? '').trim(),
      if (primary.isNotEmpty) _readableType(primary),
      if (p.types.isNotEmpty) _readableType(p.types.first),
      if (social.isNotEmpty) _readableType(social),
      if (best.isNotEmpty) _readableType(best),
      p.address.trim(),
    ]) {
      if (s.isNotEmpty) return s;
    }
    if (p.rating > 0) {
      return '${p.rating.toStringAsFixed(1)} ★';
    }
    return '';
  }

  Future<void> _addToMyDay(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final selectedDate = ref.read(selectedMyDayDateProvider);
    final planningDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    final scheduledActivityService = ref.read(scheduledActivityServiceProvider);
    final occupied = await scheduledActivityService.getOccupiedTimeSlotKeysForPlaceOnDate(
      placeId: place.id,
      date: planningDate,
    );
    if (occupied.length >= 3) {
      showWanderMoodToast(
        context,
        message: l10n.exploreAlreadyInDayPlan,
        isWarning: true,
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddPlaceToMyDaySheet(
        place: place,
        planningDate: planningDate,
        onTimeSelected: (startTime) async {
          await saveExplorePlaceToMyDay(
            context: context,
            ref: ref,
            place: place,
            startTime: startTime,
            photoSelectionSeed: 0,
          );
          TasteProfileService.recordFromPlace(
            place,
            interactionType: 'added_to_day',
            timeSlot: TasteProfileService.inferTimeSlotFromHour(startTime.hour),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final photo = place.photos.isNotEmpty ? place.photos.first : '';
    final savedPlacesAsync = ref.watch(savedPlacesProvider);
    final isFavorite = savedPlacesAsync.value?.any((sp) => sp.place.id == place.id) ?? false;

    return SizedBox(
      width: 160,
      height: 180,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            TasteProfileService.recordFromPlace(
              place,
              interactionType: 'tapped',
            );
            context.push('/place/${place.id}');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 90,
                child: photo.trim().isEmpty
                    ? Container(color: const Color(0xFFEBF3EE))
                    : WmPlacePhotoNetworkImage(
                        photo,
                        fit: BoxFit.cover,
                        width: 160,
                        height: 90,
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E1C18),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _blurb(place),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              height: 1.25,
                              color: const Color(0xFF8C8780),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: const Color(0xFFEBF3EE),
                                foregroundColor: const Color(0xFF2A6049),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () => _addToMyDay(context, ref),
                              child: Text(
                                '+ ${l10n.carouselAddToDay}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () async {
                                final savedPlacesService =
                                    ref.read(savedPlacesServiceProvider);
                                try {
                                  if (isFavorite) {
                                    await savedPlacesService.unsavePlace(place.id);
                                  } else {
                                    await savedPlacesService.savePlace(place);
                                    TasteProfileService.recordFromPlace(
                                      place,
                                      interactionType: 'saved',
                                    );
                                  }
                                  ref.invalidate(savedPlacesProvider);
                                } catch (_) {}
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBF3EE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  size: 14,
                                  color: isFavorite
                                      ? const Color(0xFFE05C5C)
                                      : const Color(0xFF2A6049),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

