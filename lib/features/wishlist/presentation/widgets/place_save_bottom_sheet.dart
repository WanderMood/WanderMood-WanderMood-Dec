import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:wandermood/features/places/services/places_service.dart';
import 'package:wandermood/features/wishlist/data/extract_place_from_url_service.dart';
import 'package:wandermood/features/wishlist/data/wishlist_service.dart';
import 'package:wandermood/features/wishlist/presentation/utils/plan_with_friend_launcher.dart';

const _wmCream = Color(0xFFF5F0E8);
const _wmForest = Color(0xFF2A6049);
const _wmAccent = Color(0xFF5DCAA5);
const _wmCharcoal = Color(0xFF1A1714);
const _wmMuted = Color(0x8C1A1714);

enum _SheetPhase { loading, found, manual, success }

class PlaceSaveBottomSheet extends ConsumerStatefulWidget {
  const PlaceSaveBottomSheet({super.key, required this.url});

  final String url;

  @override
  ConsumerState<PlaceSaveBottomSheet> createState() =>
      _PlaceSaveBottomSheetState();
}

class _PlaceSaveBottomSheetState extends ConsumerState<PlaceSaveBottomSheet> {
  _SheetPhase _phase = _SheetPhase.loading;
  ExtractedPlacePayload? _payload;
  bool _saving = false;
  final _searchController = TextEditingController();
  List<PlacesSearchResult> _searchResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    unawaited(_extract());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _extract() async {
    final city =
        ref.read(locationNotifierProvider).valueOrNull?.trim() ?? 'Rotterdam';
    final result = await ref
        .read(extractPlaceFromUrlServiceProvider)
        .extract(url: widget.url, city: city);
    if (!mounted) return;
    setState(() {
      if (result != null) {
        _payload = result;
        _phase = _SheetPhase.found;
      } else {
        _phase = _SheetPhase.manual;
      }
    });
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final lang = Localizations.localeOf(context).languageCode;
      final results = await ref
          .read(placesServiceProvider.notifier)
          .searchPlaces(query.trim(), language: lang);
      if (mounted) setState(() => _searchResults = results);
    });
  }

  Future<void> _selectSearchResult(PlacesSearchResult result) async {
    setState(() {
      _phase = _SheetPhase.loading;
    });
    final details =
        await ref.read(placesServiceProvider.notifier).getPlaceDetails(
              result.placeId,
            );
    if (!mounted) return;
    final place = _placeFromDetails(result, details);
    setState(() {
      _payload = ExtractedPlacePayload(
        placeId: place.id,
        placeName: place.name,
        source: 'manual',
        confidence: 'medium',
        placeData: {
          'name': place.name,
          'address': place.address,
          'rating': place.rating,
          'types': place.types,
          'photo_url':
              place.photos.isNotEmpty ? place.photos.first : null,
          'photos': place.photos,
          'location': {
            'lat': place.location.lat,
            'lng': place.location.lng,
          },
        },
      );
      _phase = _SheetPhase.found;
    });
  }

  Place _placeFromDetails(
    PlacesSearchResult result,
    Map<String, dynamic> details,
  ) {
    final geometry = details['geometry']?['location'] as Map?;
    final lat = (geometry?['lat'] as num?)?.toDouble() ??
        result.geometry?.location.lat ??
        0.0;
    final lng = (geometry?['lng'] as num?)?.toDouble() ??
        result.geometry?.location.lng ??
        0.0;
    final photos = <String>[];
    final refs = result.photos;
    if (refs != null && refs.isNotEmpty) {
      final svc = ref.read(placesServiceProvider.notifier);
      for (final ph in refs.take(2)) {
        try {
          photos.add(svc.getPhotoUrl(ph.photoReference));
        } catch (_) {}
      }
    }
    return Place(
      id: result.placeId,
      name: result.name,
      address: result.formattedAddress ?? result.vicinity ?? '',
      rating: (result.rating as num?)?.toDouble() ?? 0.0,
      photos: photos,
      types: result.types ?? const [],
      location: PlaceLocation(lat: lat, lng: lng),
    );
  }

  Future<void> _save({bool planAfter = false}) async {
    final payload = _payload;
    if (payload == null || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(wishlistServiceProvider).saveFromShare(
            payload: payload,
            sourceUrl: widget.url,
          );
      if (!mounted) return;
      setState(() {
        _phase = _SheetPhase.success;
        _saving = false;
      });
      if (planAfter) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        Navigator.of(context).pop();
        openPlanWithFriend(
          context,
          PlanWithFriendArgs.fromExtracted(payload, sourceUrl: widget.url),
        );
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showWanderMoodToast(
          context,
          message: 'Opslaan mislukt. Probeer het opnieuw.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Material(
          color: _wmCream,
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.88,
              ),
              child: _buildBody(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _SheetPhase.loading:
        return _loading();
      case _SheetPhase.found:
        return _found();
      case _SheetPhase.manual:
        return _manual();
      case _SheetPhase.success:
        return _success();
    }
  }

  Widget _loading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _moodyCircle(48),
          const SizedBox(height: 16),
          Text(
            'Even zoeken...',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _wmCharcoal,
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _wmForest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _success() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: _wmForest, size: 56),
          const SizedBox(height: 16),
          Text(
            'Opgeslagen! 🎉',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _wmCharcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _found() {
    final p = _payload!;
    final photo = p.photoUrl;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (photo != null && photo.isNotEmpty)
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: WmPlacePhotoNetworkImage(
                    photo,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _sourceBadge(p.source),
                ),
              ],
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _wmForest.withValues(alpha: 0.85),
                    _wmAccent.withValues(alpha: 0.6),
                  ],
                ),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _sourceBadge(p.source),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.placeName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _wmCharcoal,
                  ),
                ),
                if (p.rating != null && p.rating! > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8DF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '★ ${p.rating!.toStringAsFixed(1)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE8784A),
                      ),
                    ),
                  ),
                ],
                if (p.primaryType != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    p.primaryType!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _wmMuted,
                    ),
                  ),
                ],
                if (p.city != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    p.city!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _wmMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _primaryButton(
                  label: 'Opslaan in wishlist',
                  onPressed: _saving ? null : () => _save(),
                ),
                const SizedBox(height: 10),
                _outlineButton(
                  label: 'Plan met vriend →',
                  onPressed: _saving ? null : () => _save(planAfter: true),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _phase = _SheetPhase.manual),
                    child: Text(
                      'Niet de juiste plek?',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _wmForest,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _manual() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'We konden de plek niet vinden.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _wmCharcoal,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Zoek de plek handmatig...',
              hintStyle: GoogleFonts.poppins(color: _wmMuted, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _wmForest.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _wmForest.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _wmForest, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final r = _searchResults[index];
                return ListTile(
                  title: Text(
                    r.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: r.formattedAddress != null
                      ? Text(
                          r.formattedAddress!,
                          style: GoogleFonts.poppins(fontSize: 12),
                        )
                      : null,
                  onTap: () => _selectSearchResult(r),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _moodyCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF2A6049),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        'M',
        style: GoogleFonts.poppins(
          fontSize: size * 0.45,
          fontWeight: FontWeight.bold,
          color: _wmAccent,
        ),
      ),
    );
  }

  Widget _sourceBadge(String source) {
    final label = switch (source.toLowerCase()) {
      'tiktok' => 'van TikTok',
      'instagram' => 'van Instagram',
      _ => 'Gedeeld',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Opgeslagen $label',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _primaryButton({required String label, VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _wmForest,
          foregroundColor: _wmCream,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _outlineButton({required String label, VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _wmForest,
          side: const BorderSide(color: _wmForest, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
