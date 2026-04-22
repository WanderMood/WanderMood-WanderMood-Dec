import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/features/plans/utils/activity_place_adapter.dart';
import 'package:wandermood/features/places/presentation/widgets/place_card_moody_description.dart';
import 'package:wandermood/features/places/services/places_service.dart';
import 'package:wandermood/features/places/services/sharing_service.dart';
import 'package:wandermood/features/places/services/saved_places_service.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/features/plans/presentation/providers/place_open_now_provider.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/core/presentation/widgets/guest_demo_about_sections.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/utils/google_place_photo_device_url.dart';

/// v2 design tokens — day plan result cards
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmSky = Color(0xFFA8C8DC);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmDusk = Color(0xFF4A4640);
const Color _wmSeeActivityText = Color(0xFF1A3D50);

/// Day Plan activity card matching the reference design:
/// gradient accent bar, image with overlays (mood match, category, rating, actions),
/// title, mood tags (gradient + glassy), description, info pills (gradient + glassy), Not feeling this? + See activity buttons.
class DayPlanActivityCard extends ConsumerStatefulWidget {
  final Activity activity;
  /// Called when the card or "See activity" is tapped. Receives activity and optional distance for detail screen.
  final void Function(Activity activity, {String? distanceKm}) onTap;
  /// When set, the left button shows "Not feeling this?" (swap activity) instead of Directions.
  final VoidCallback? onNotFeelingThis;
  final String? distanceKm;
  /// Optional address/location line (e.g. from Places API — not the long description).
  final String? locationLabel;
  /// Guest preview: Moody voice line above the factual description.
  final String? moodyPersonalityLine;
  /// Callback when the activity is successfully added to My Day.
  final VoidCallback? onAdded;

  /// Guest onboarding preview: hide save / add-to–My Day and favorite; keep directions & share.
  final bool guestPreviewMode;

  const DayPlanActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    this.onNotFeelingThis,
    this.distanceKm,
    this.locationLabel,
    this.moodyPersonalityLine,
    this.onAdded,
    this.guestPreviewMode = false,
  });

  @override
  ConsumerState<DayPlanActivityCard> createState() => _DayPlanActivityCardState();
}

class _DayPlanActivityCardState extends ConsumerState<DayPlanActivityCard> {
  bool _isAdding = false;
  bool _isAdded = false;
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;
  // Static cache so we don't re-fetch photos on every rebuild
  static final Map<String, Future<List<String>>> _photoListCache = {};

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  /// Returns a list of photo URLs for the activity (full gallery via edge `places` details, not cached single-image place).
  Future<List<String>> _resolvePhotos() async {
    final placeId = widget.activity.placeId?.trim();
    final imageUrl = widget.activity.imageUrl;

    if (placeId != null && placeId.isNotEmpty) {
      final cacheKey = placeId.startsWith('google_') ? placeId : 'google_$placeId';
      return _photoListCache.putIfAbsent(cacheKey, () async {
        try {
          final service = ref.read(placesServiceProvider.notifier);
          var urls = await service.fetchPhotoUrlsForGooglePlace(cacheKey);
          if (imageUrl.isNotEmpty) {
            urls = [imageUrl, ...urls.where((u) => u != imageUrl)];
          }
          if (urls.isNotEmpty) return urls;
        } catch (_) {}
        return imageUrl.isNotEmpty ? [imageUrl] : [];
      });
    }

    if (imageUrl.isNotEmpty) return [imageUrl];
    return [];
  }

  String _durationText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = widget.activity.duration;
    if (d >= 60) {
      final h = d ~/ 60;
      final m = d % 60;
      if (m == 0) return l10n.dayPlanDurationHoursOnly(h);
      return l10n.dayPlanDurationHoursMinutes(h, m);
    }
    return l10n.dayPlanDurationMinutesOnly(d);
  }

  Widget _buildGuestPreviewDescription(BuildContext context) {
    final desc = widget.activity.description.trim();
    final voice = widget.moodyPersonalityLine?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (voice.isNotEmpty) ...[
          Text(
            voice,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: _wmForest,
              height: 1.35,
            ),
          ),
          if (desc.isNotEmpty) const SizedBox(height: 8),
        ],
        if (desc.isNotEmpty)
          GuestDemoAboutSectionsView(source: desc, compact: true),
      ],
    );
  }

  String _localizedTagLabel(BuildContext context, String tag) {
    final l10n = AppLocalizations.of(context)!;
    final t = tag.toLowerCase().trim();
    if (t.isEmpty) return tag;
    if (t.contains('foody') || t.contains('foodie')) return l10n.moodFoody;
    if (t.contains('food')) return l10n.placeCategoryFood;
    if (t.contains('restaurant')) return l10n.placeCategoryRestaurant;
    if (t.contains('cafe') || t.contains('coffee')) return l10n.placeCategoryCafe;
    if (t.contains('bar') || t.contains('pub') || t.contains('night')) return l10n.placeCategoryBar;
    if (t.contains('museum') || t.contains('gallery')) return l10n.placeCategoryMuseum;
    if (t.contains('park') || t.contains('garden') || t.contains('nature')) return l10n.placeCategoryPark;
    if (t.contains('shop') || t.contains('mall') || t.contains('store')) return l10n.placeCategoryShopping;
    if (t.contains('culture') || t.contains('historic')) return l10n.placeCategoryCulture;
    if (t.contains('hiking') || t.contains('outdoor') || t.contains('trail')) return l10n.placeCategoryNature;
    if (t.contains('club') || t.contains('nightlife')) return l10n.placeCategoryNightlife;
    if (t.contains('adventure')) return l10n.placeCategoryAdventure;
    return l10n.placeCategorySpot;
  }

  /// Google place photo URLs need [WmPlacePhotoNetworkImage]; Unsplash and other HTTPS use [WmNetworkImage].
  Widget _planCardPhoto(
    String url, {
    required BoxFit fit,
    ProgressIndicatorBuilder? progressIndicatorBuilder,
  }) {
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    final host = uri?.host.toLowerCase() ?? '';
    final isGooglePlacePhoto = (host == 'maps.googleapis.com' && trimmed.contains('place/photo')) ||
        (host == 'places.googleapis.com' && trimmed.contains('/media'));
    if (isGooglePlacePhoto) {
      return WmPlacePhotoNetworkImage(
        trimmed,
        fit: fit,
        progressIndicatorBuilder: progressIndicatorBuilder,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }
    return WmNetworkImage(
      deviceAccessibleGooglePlacePhotoUrl(trimmed),
      fit: fit,
      progressIndicatorBuilder: progressIndicatorBuilder,
      errorBuilder: (_, __, ___) => _imagePlaceholder(),
    );
  }

  String _priceText(BuildContext context) {
    switch (widget.activity.paymentType) {
      case PaymentType.free:
        return AppLocalizations.of(context)!.dayPlanCardFree;
      case PaymentType.ticket:
      case PaymentType.reservation:
        final p = widget.activity.priceLevel?.toLowerCase() ?? '';
        if (p.contains('€€€') || p == '3') return '€€€';
        if (p.contains('€€') || p == '2') return '€€';
        return '€';
    }
  }

  /// Swipeable photo carousel for the card image section.
  Widget _buildCardImage(WidgetRef ref) {
    // Provide a single-image initial state while the full list loads
    final initialPhotos = widget.activity.imageUrl.isNotEmpty
        ? [widget.activity.imageUrl]
        : <String>[];

    return FutureBuilder<List<String>>(
      future: _resolvePhotos(),
      initialData: initialPhotos,
      builder: (context, snapshot) {
        final photos = snapshot.data ?? initialPhotos;
        if (photos.isEmpty) return _imagePlaceholder();
        if (photos.length == 1) {
          return _planCardPhoto(
            photos[0],
            fit: BoxFit.cover,
            progressIndicatorBuilder: (c, url, progress) => Container(
              color: Colors.grey.shade200,
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.progress,
                  color: _wmForest,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }
        return Stack(
          key: ValueKey<String>(photos.join('|')),
          children: [
            PageView.builder(
              controller: _imagePageController,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _currentImageIndex = i),
              itemBuilder: (_, i) => _planCardPhoto(
                photos[i],
                fit: BoxFit.cover,
                progressIndicatorBuilder: (c, url, progress) => Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.progress,
                      color: _wmForest,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(photos.length > 10 ? 10 : photos.length, (i) {
                  final active = i == _currentImageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white.withOpacity(0.95)
                          : Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.20),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.place, size: 48, color: Colors.grey),
    );
  }

  Future<void> _openDirections(BuildContext context) async {
    try {
      final availableMaps = await MapLauncher.installedMaps;
      if (availableMaps.isNotEmpty) {
        await availableMaps.first.showMarker(
          coords: Coords(widget.activity.location.latitude, widget.activity.location.longitude),
          title: widget.activity.name,
          description: widget.activity.description,
        );
      } else {
        final url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${widget.activity.location.latitude},${widget.activity.location.longitude}',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.dayPlanCardUnableToOpenDirections,
          isError: true,
        );
      }
    }
  }

  Future<void> _share(BuildContext context) async {
    try {
      final place = activityToPlace(widget.activity);
      await SharingService.sharePlace(place, context: context);
    } catch (e) {
      if (context.mounted) {
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.dayPlanCardFailedToShare,
          isError: true,
        );
      }
    }
  }

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref) async {
    final place = activityToPlace(widget.activity);
    final savedPlacesService = ref.read(savedPlacesServiceProvider);
    final savedPlacesAsync = ref.read(savedPlacesProvider);
    final isFav = savedPlacesAsync.value?.any((sp) => sp.place.id == place.id) ?? false;

    if (isFav) {
      try {
        await savedPlacesService.unsavePlace(place.id);
        ref.invalidate(savedPlacesProvider);
        if (context.mounted) {
          showWanderMoodToast(
            context,
            message: AppLocalizations.of(context)!.dayPlanCardRemovedFromSaved(place.name),
          );
        }
      } catch (e) {
        if (context.mounted) {
          showWanderMoodToast(
            context,
            message: AppLocalizations.of(context)!.dayPlanCardFailedToRemove(place.name),
            isError: true,
          );
        }
      }
      return;
    }

    try {
      await savedPlacesService.savePlace(place);
      ref.invalidate(savedPlacesProvider);
      if (context.mounted) {
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.dayPlanCardSavedToMoodyHub(place.name),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.dayPlanCardCouldNotSaveMoodyHub,
          isError: true,
        );
      }
    }
  }

  Future<void> _addToMyDay(BuildContext context, WidgetRef ref) async {
    if (_isAdded) return;
    
    setState(() {
      _isAdding = true;
    });
    
    final scheduledActivityService = ref.read(scheduledActivityServiceProvider);
    try {
      await scheduledActivityService.saveScheduledActivities([widget.activity], isConfirmed: false);
      ref.invalidate(scheduledActivityServiceProvider);
      ref.invalidate(scheduledActivitiesForTodayProvider);
      ref.invalidate(todayActivitiesProvider);
      
      if (mounted) {
        setState(() {
          _isAdding = false;
          _isAdded = true;
        });
        widget.onAdded?.call();
      }
      
      if (context.mounted) {
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.dayPlanCardAddedToMyDay(widget.activity.name),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
      if (context.mounted) {
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.dayPlanCardCouldNotAddMyDay,
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedPlacesAsync = ref.watch(savedPlacesProvider);
    final place = activityToPlace(widget.activity);
    final isFavorite = savedPlacesAsync.value?.any((sp) => sp.place.id == place.id) ?? false;
    final placeId = widget.activity.placeId;
    final openNowAsync = placeId != null && placeId.isNotEmpty
        ? ref.watch(placeOpenNowProvider(placeId))
        : const AsyncValue.data(null);
    final isOpenNow = openNowAsync.valueOrNull;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: _wmWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _wmParchment, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accent bar — wmForest (v2)
            Container(
              height: 4,
              width: double.infinity,
              color: _wmForest,
            ),
            // Image: swipeable PageView — deferToChild so horizontal drags reach the PageView (Explore parity).
            GestureDetector(
              onTap: () => widget.onTap(widget.activity, distanceKm: widget.distanceKm),
              child: SizedBox(
                height: 192,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCardImage(ref),
                    // Gradient overlay
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                    // Rating badge (bottom-left)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _wmForest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              widget.activity.rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Action buttons (bottom-right): white + parchment + forest icons (v2)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _imageActionButton(
                            icon: Icons.directions,
                            onTap: () => _openDirections(context),
                          ),
                          const SizedBox(width: 8),
                          _imageActionButton(
                            icon: Icons.share,
                            onTap: () => _share(context),
                          ),
                          if (!widget.guestPreviewMode) ...[
                            const SizedBox(width: 8),
                            _imageActionButton(
                              icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                              iconColor: isFavorite ? const Color(0xFFE05C5C) : _wmForest,
                              onTap: () => _toggleFavorite(context, ref),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content section
            InkWell(
              onTap: () => widget.onTap(widget.activity, distanceKm: widget.distanceKm),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.activity.name,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _wmCharcoal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Category / mood tags — wmForestTint + wmForest (v2)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.activity.tags.take(5).map((tag) {
                        final label = _localizedTagLabel(context, tag);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _wmForestTint,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _wmParchment, width: 0.5),
                          ),
                          child: Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _wmForest,
                              letterSpacing: 0.2,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Location/address when provided
                    if (widget.locationLabel != null && widget.locationLabel!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.locationLabel!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    // Description: guest preview uses plain copy + optional Moody line (no async blurb duplicate).
                    if (widget.guestPreviewMode)
                      _buildGuestPreviewDescription(context)
                    else
                      Consumer(
                        builder: (context, ref, _) {
                          final p = placeForMoodyBlurb(
                            widget.activity,
                            locationLabel: widget.locationLabel,
                          );
                          return PlaceCardMoodyDescription(
                            place: p,
                            maxLines: 4,
                            paddingTop: 0,
                            textStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF4B5563),
                              height: 1.4,
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    // Info pills: Duration, Price, Distance, Open/Closed (live when placeId set)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _flatMetaPill(
                          icon: Icons.schedule,
                          label: _durationText(context),
                        ),
                        _flatMetaPill(
                          icon: Icons.euro,
                          label: _priceText(context),
                        ),
                        if (widget.distanceKm != null)
                          _flatMetaPill(
                            icon: Icons.location_on,
                            label: widget.distanceKm!,
                          ),
                        if (isOpenNow != null)
                          _flatMetaPill(
                            icon: Icons.circle,
                            label: isOpenNow ? AppLocalizations.of(context)!.dayPlanCardOpenNow : AppLocalizations.of(context)!.dayPlanCardClosed,
                            isOpenDot: isOpenNow,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Action buttons: Not feeling this? | See activity (Directions stays in image overlay)
                    Row(
                      children: [
                        Expanded(
                          child: widget.onNotFeelingThis != null
                              ? OutlinedButton.icon(
                                  onPressed: widget.onNotFeelingThis,
                                  icon: const Icon(Icons.refresh_rounded, size: 18, color: _wmForest),
                                  label: Text(
                                    AppLocalizations.of(context)!.dayPlanCardNotFeelingThis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _wmForest,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: const BorderSide(color: _wmForest, width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                    backgroundColor: _wmWhite,
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: () => _openDirections(context),
                                  icon: const Icon(Icons.directions, size: 18, color: _wmForest),
                                  label: Text(
                                    AppLocalizations.of(context)!.dayPlanCardDirections,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _wmDusk,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: const BorderSide(color: _wmParchment, width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                    backgroundColor: _wmWhite,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => widget.onTap(widget.activity, distanceKm: widget.distanceKm),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _wmSky,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.dayPlanCardSeeActivity,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _wmSeeActivityText,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('🎫', style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!widget.guestPreviewMode) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isAdded ? null : () => _addToMyDay(context, ref),
                          icon: _isAdding
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _wmForest),
                                )
                              : Icon(
                                  _isAdded ? Icons.check_circle_rounded : Icons.calendar_today_rounded,
                                  size: 16,
                                  color: _isAdded ? Colors.white : _wmForest,
                                ),
                          label: Text(
                            _isAdded
                                ? AppLocalizations.of(context)!.dayPlanCardAdded
                                : AppLocalizations.of(context)!.dayPlanCardAddToMyDay,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isAdded ? Colors.white : _wmForest,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: _isAdded ? _wmForest : _wmForest,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            backgroundColor: _isAdded ? _wmForest : _wmWhite,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _flatMetaPill({
    required IconData icon,
    required String label,
    bool isOpenDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _wmCream,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _wmParchment, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOpenDot)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _wmForest,
                shape: BoxShape.circle,
              ),
            )
          else
            Icon(icon, size: 14, color: _wmForest),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _wmCharcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _wmWhite,
            shape: BoxShape.circle,
            border: Border.all(color: _wmParchment, width: 0.5),
          ),
          child: Icon(icon, size: 20, color: iconColor ?? _wmForest),
        ),
      ),
    );
  }
}
