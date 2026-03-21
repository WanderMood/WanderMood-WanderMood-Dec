import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/features/plans/utils/activity_place_adapter.dart';
import 'package:wandermood/features/plans/presentation/providers/place_photo_url_provider.dart';
import 'package:wandermood/features/places/services/sharing_service.dart';
import 'package:wandermood/features/places/services/saved_places_service.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/features/plans/presentation/providers/place_open_now_provider.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

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
  /// Optional address/location line (e.g. from Places API or activity.description).
  final String? locationLabel;
  /// Callback when the activity is successfully added to My Day.
  final VoidCallback? onAdded;

  const DayPlanActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    this.onNotFeelingThis,
    this.distanceKm,
    this.locationLabel,
    this.onAdded,
  });

  @override
  ConsumerState<DayPlanActivityCard> createState() => _DayPlanActivityCardState();
}

class _DayPlanActivityCardState extends ConsumerState<DayPlanActivityCard> {
  bool _isAdding = false;
  bool _isAdded = false;

  String get _durationText {
    if (widget.activity.duration >= 60) {
      final h = widget.activity.duration ~/ 60;
      final m = widget.activity.duration % 60;
      if (m == 0) return '${h}h';
      return '${h}h ${m}min';
    }
    return '${widget.activity.duration} min';
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

  /// Image for the card: use activity.imageUrl if set; otherwise fetch from Places API (same key as Explore).
  Widget _buildCardImage(WidgetRef ref) {
    final hasImageUrl = widget.activity.imageUrl.isNotEmpty;
    if (hasImageUrl) {
      return CachedNetworkImage(
        imageUrl: widget.activity.imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => _imagePlaceholder(),
        errorWidget: (_, __, ___) => _imagePlaceholder(),
      );
    }
    final placeId = widget.activity.placeId;
    if (placeId != null && placeId.isNotEmpty) {
      final photoAsync = ref.watch(placePhotoUrlProvider(placeId));
      return photoAsync.when(
        data: (url) {
          if (url != null && url.isNotEmpty) {
            return CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => _imagePlaceholder(),
              errorWidget: (_, __, ___) => _imagePlaceholder(),
            );
          }
          return _imagePlaceholder();
        },
        loading: () => _imagePlaceholder(),
        error: (_, __) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
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
      await SharingService.sharePlace(place);
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
      child: InkWell(
        onTap: () => widget.onTap(widget.activity, distanceKm: widget.distanceKm),
        borderRadius: BorderRadius.circular(16),
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
              // Image section: use activity.imageUrl, or fetch from Places API (same as Explore) when empty
              SizedBox(
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
                          const SizedBox(width: 8),
                          _imageActionButton(
                            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                            iconColor: isFavorite ? const Color(0xFFE05C5C) : _wmForest,
                            onTap: () => _toggleFavorite(context, ref),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content section
              Padding(
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
                        final label = tag.length > 2
                            ? '${tag[0].toUpperCase()}${tag.substring(1)}'
                            : tag.toUpperCase();
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
                    // Description
                    Text(
                      widget.activity.description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF4B5563),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    // Info pills: Duration, Price, Distance, Open/Closed (live when placeId set)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _flatMetaPill(
                          icon: Icons.schedule,
                          label: _durationText,
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
                    const SizedBox(height: 10),
                    // Add to My Day button
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
                ),
              ),
            ],
          ),
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
