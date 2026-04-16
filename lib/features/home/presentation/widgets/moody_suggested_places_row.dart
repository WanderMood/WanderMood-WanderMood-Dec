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
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';

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
        padding: EdgeInsets.only(left: leftInset, top: 8),
        child: SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: places.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _MiniPlaceCard(place: places[i]),
          ),
        ),
      ),
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
  late final Animation<double> _size = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
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
    return FadeTransition(
      opacity: _opacity,
      child: SizeTransition(
        sizeFactor: _size,
        axisAlignment: -1,
        child: widget.child,
      ),
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final photo = place.photos.isNotEmpty ? place.photos.first : '';

    return SizedBox(
      width: 160,
      height: 180,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/place/${place.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 90,
                child: photo.trim().isEmpty
                    ? Container(color: const Color(0xFFEBF3EE))
                    : WmPlacePhotoHeroNetworkImage(
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
                      Expanded(
                        child: Text(
                          _blurb(place),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            height: 1.25,
                            color: const Color(0xFF8C8780),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
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

