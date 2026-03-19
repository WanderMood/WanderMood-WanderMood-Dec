import 'dart:ui';
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

  /// Gradient for accent bar and "See activity" button by time slot / category.
  LinearGradient _cardGradient() {
    final first = widget.activity.tags.isNotEmpty ? widget.activity.tags.first.toLowerCase() : '';
    if (first.contains('cultural') || first.contains('museum') || first.contains('art')) {
      return const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF6366F1)], begin: Alignment.centerLeft, end: Alignment.centerRight);
    }
    if (first.contains('food') || first.contains('dining') || first.contains('restaurant')) {
      return const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF97316)], begin: Alignment.centerLeft, end: Alignment.centerRight);
    }
    if (first.contains('market') || first.contains('dining')) {
      return const LinearGradient(colors: [Color(0xFFFB7185), Color(0xFFF43F5E)], begin: Alignment.centerLeft, end: Alignment.centerRight);
    }
    return const LinearGradient(colors: [Color(0xFFF472B6), Color(0xFFFB7185)], begin: Alignment.centerLeft, end: Alignment.centerRight);
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.dayPlanCardUnableToOpenDirections), backgroundColor: Colors.red),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.dayPlanCardFailedToShare), backgroundColor: Colors.red),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.dayPlanCardRemovedFromSaved(place.name)), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.dayPlanCardFailedToRemove(place.name)), backgroundColor: Colors.red),
          );
        }
      }
      return;
    }

    try {
      await savedPlacesService.savePlace(place);
      ref.invalidate(savedPlacesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.dayPlanCardSavedToMoodyHub(place.name)),
            backgroundColor: const Color(0xFF12B347),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.dayPlanCardCouldNotSaveMoodyHub),
            backgroundColor: Colors.orange,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.dayPlanCardAddedToMyDay(widget.activity.name)),
            backgroundColor: const Color(0xFF12B347),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.dayPlanCardCouldNotAddMyDay),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _cardGradient();
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
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF3F4F6), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient accent bar
              Container(
                height: 8,
                decoration: BoxDecoration(gradient: gradient),
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
                    // Rating badge (bottom-left) – gradient + glassy
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: _glassyGradientPill(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF9E6), Color(0xFFFFF3CC)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 16, color: Color(0xFFFBBF24)),
                            const SizedBox(width: 4),
                            Text(
                              widget.activity.rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Action buttons (bottom-right): Directions, Share, Heart
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _imageActionButton(
                            icon: Icons.directions,
                            color: const Color(0xFF2563EB),
                            onTap: () => _openDirections(context),
                          ),
                          const SizedBox(width: 8),
                          _imageActionButton(
                            icon: Icons.share,
                            color: const Color(0xFF9333EA),
                            onTap: () => _share(context),
                          ),
                          const SizedBox(width: 8),
                          _imageActionButton(
                            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey.shade700,
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
                        color: const Color(0xFF1F2937),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Mood tags (gradient + glassy pills)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.activity.tags.take(5).map((tag) {
                        final style = _tagGradient(tag);
                        return _glassyGradientPill(
                          gradient: style,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: Text(
                            tag.length > 2 ? '${tag[0].toUpperCase()}${tag.substring(1)}' : tag.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                        _infoPill(
                          icon: Icons.schedule,
                          label: _durationText,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFBFDBFE), Color(0xFF67E8F9)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          iconColor: const Color(0xFF2563EB),
                        ),
                        _infoPill(
                          icon: Icons.euro,
                          label: _priceText(context),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          iconColor: const Color(0xFF059669),
                        ),
                        if (widget.distanceKm != null)
                          _infoPill(
                            icon: Icons.location_on,
                            label: widget.distanceKm!,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFED7AA), Color(0xFFFBCFE8)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            iconColor: const Color(0xFFEA580C),
                          ),
                        // Only show Open/Closed when we have live data from Google Places (placeId)
                        if (isOpenNow != null)
                          _infoPill(
                            icon: Icons.circle,
                            label: isOpenNow ? AppLocalizations.of(context)!.dayPlanCardOpenNow : AppLocalizations.of(context)!.dayPlanCardClosed,
                            gradient: LinearGradient(
                              colors: isOpenNow
                                  ? const [Color(0xFF4ADE80), Color(0xFF10B981)]
                                  : [Colors.grey.shade400, Colors.grey.shade500],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            iconColor: Colors.white,
                            isPulsingDot: isOpenNow,
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
                                  icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF4CAF50)),
                                  label: Text(
                                    AppLocalizations.of(context)!.dayPlanCardNotFeelingThis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF4CAF50),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    backgroundColor: Colors.white,
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: () => _openDirections(context),
                                  icon: const Icon(Icons.directions, size: 18, color: Color(0xFF2563EB)),
                                  label: Text(
                                    AppLocalizations.of(context)!.dayPlanCardDirections,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF374151),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => widget.onTap(widget.activity, distanceKm: widget.distanceKm),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: gradient,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.dayPlanCardSeeActivity,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
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
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
                              )
                            : Icon(
                                _isAdded ? Icons.check_circle_rounded : Icons.calendar_today_rounded, 
                                size: 16, 
                                color: _isAdded ? Colors.white : const Color(0xFF7C3AED),
                              ),
                        label: Text(
                          _isAdded 
                              ? AppLocalizations.of(context)!.dayPlanCardAdded
                              : AppLocalizations.of(context)!.dayPlanCardAddToMyDay,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _isAdded ? Colors.white : const Color(0xFF7C3AED),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: _isAdded ? const Color(0xFF12B347) : const Color(0xFF7C3AED), 
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: _isAdded ? const Color(0xFF12B347) : const Color(0xFFF5F3FF),
                        ).copyWith(
                          // Ensure disabled state still shows the custom colors
                          foregroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.disabled)) {
                              return _isAdded ? Colors.white : const Color(0xFF7C3AED);
                            }
                            return null; // Defer to default
                          }),
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

  LinearGradient _tagGradient(String tag) {
    final t = tag.toLowerCase();
    if (t.contains('cultural') || t.contains('culture')) {
      return const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF6366F1)], begin: Alignment.centerLeft, end: Alignment.centerRight);
    }
    if (t.contains('food') || t.contains('foodie') || t.contains('dining')) {
      return const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF97316)], begin: Alignment.centerLeft, end: Alignment.centerRight);
    }
    if (t.contains('instagram') || t.contains('iconic')) {
      return const LinearGradient(colors: [Color(0xFFF472B6), Color(0xFFFB7185)], begin: Alignment.centerLeft, end: Alignment.centerRight);
    }
    if (t.contains('indoor')) {
      return const LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFF22D3EE)], begin: Alignment.centerLeft, end: Alignment.centerRight);
    }
    if (t.contains('outdoor') || t.contains('walking') || t.contains('tour')) {
      return const LinearGradient(colors: [Color(0xFFFB923C), Color(0xFFEF4444)], begin: Alignment.centerLeft, end: Alignment.centerRight);
    }
    return const LinearGradient(colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)], begin: Alignment.centerLeft, end: Alignment.centerRight);
  }

  /// Gradient + glassy pill (frosted look with blur and semi-transparent gradient).
  Widget _glassyGradientPill({
    required LinearGradient gradient,
    required EdgeInsets padding,
    required Widget child,
  }) {
    final colors = gradient.colors;
    final softGradient = LinearGradient(
      colors: colors.map((c) => c.withOpacity(0.88)).toList(),
      begin: gradient.begin,
      end: gradient.end,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: softGradient,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _infoPill({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required Color iconColor,
    bool isPulsingDot = false,
  }) {
    return _glassyGradientPill(
      gradient: gradient,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPulsingDot)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            )
          else
            Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPulsingDot ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.92),
                  Colors.white.withOpacity(0.75),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
