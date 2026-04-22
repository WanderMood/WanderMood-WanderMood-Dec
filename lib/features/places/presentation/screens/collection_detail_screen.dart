import 'package:cached_network_image/cached_network_image.dart';
import 'package:wandermood/core/cache/wandermood_image_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/home/presentation/utils/my_day_slot_period.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/services/trip_collections_service.dart';
import 'package:wandermood/features/places/utils/place_city_hint.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/features/plans/domain/enums/time_slot.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/places/presentation/screens/place_detail_screen.dart';
import 'package:wandermood/l10n/app_localizations.dart';

const _wmForest = Color(0xFF2A6049);
const _wmCream = Color(0xFFF5F0E8);
const _wmParchment = Color(0xFFE8E2D8);
const _wmStone = Color(0xFF8C8780);

class CollectionDetailScreen extends ConsumerStatefulWidget {
  final TripCollection collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  ConsumerState<CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState
    extends ConsumerState<CollectionDetailScreen> {
  late TripCollection _collection;
  final Map<String, bool> _collapsedCities = {};

  @override
  void initState() {
    super.initState();
    _collection = widget.collection;
  }

  @override
  Widget build(BuildContext context) {
    final placesAsync =
        ref.watch(collectionPlacesProvider(_collection.id));

    return Scaffold(
      backgroundColor: _wmCream,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(placesAsync),
          placesAsync.when(
            data: (places) => places.isEmpty
                ? SliverFillRemaining(child: _buildEmptyState())
                : _buildPlacesGroupedByCity(places),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: _wmForest)),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(AsyncValue<List<CollectionPlace>> placesAsync) {
    final coverUrl = placesAsync.maybeWhen(
      data: (places) {
        for (final cp in places) {
          if (cp.place.photos.isNotEmpty && cp.place.photos.first.isNotEmpty) {
            return cp.place.photos.first;
          }
        }
        return null;
      },
      orElse: () => null,
    );

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _wmForest,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: _showEditSheet,
          tooltip: AppLocalizations.of(context)!.profileActionEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          onPressed: _confirmDelete,
          tooltip: AppLocalizations.of(context)!.myDayDeleteActivityCta,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _collection.emoji,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _collection.name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        background: coverUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    cacheManager: WanderMoodImageCacheManager.instance,
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: _wmForest),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                color: _wmForest,
                child: Center(
                  child: Text(
                    _collection.emoji,
                    style: const TextStyle(fontSize: 72),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_collection.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No places yet',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Go to Saved Places and long-press any place\nto add it to this collection.',
              style: GoogleFonts.poppins(fontSize: 14, color: _wmStone),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Groups saved spots by parsed city from [Place.address] so mixed cities stay readable.
  Widget _buildPlacesGroupedByCity(List<CollectionPlace> places) {
    final groups = _sortedCityGroups(places);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            for (final (city, list) in groups) ...[
              _buildCityHeader(city, list.length),
              if (!(_collapsedCities[city] ?? false))
                ...list.map((p) => _buildPlaceCard(context, p)),
            ],
          ],
        ),
      ),
    );
  }

  List<(String city, List<CollectionPlace> items)> _sortedCityGroups(
      List<CollectionPlace> places) {
    final map = <String, List<CollectionPlace>>{};
    for (final p in places) {
      final c = placeCityHint(p.place.address);
      map.putIfAbsent(c, () => []).add(p);
    }
    final keys = map.keys.toList()
      ..sort((a, b) {
        final ao = a == 'Other' ? 1 : 0;
        final bo = b == 'Other' ? 1 : 0;
        if (ao != bo) return ao - bo;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    return [for (final k in keys) (k, map[k]!)];
  }

  Widget _buildCityHeader(String city, int count) {
    final isCollapsed = _collapsedCities[city] ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _collapsedCities[city] = !isCollapsed;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(Icons.place_outlined,
                  size: 16, color: _wmForest.withOpacity(0.85)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  city,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _wmForest,
                  ),
                ),
              ),
              Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _wmStone,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                isCollapsed ? Icons.expand_more : Icons.expand_less,
                size: 18,
                color: _wmStone,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceCard(BuildContext context, CollectionPlace cp) {
    final place = cp.place;
    final city = placeCityHint(place.address);
    return GestureDetector(
      onTap: () => _showCollectionCardActions(cp),
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (place.photos.isNotEmpty && place.photos.first.isNotEmpty)
                    CachedNetworkImage(
                      cacheManager: WanderMoodImageCacheManager.instance,
                      imageUrl: place.photos.first,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: _wmParchment),
                      errorWidget: (_, __, ___) => Container(
                        color: _wmParchment,
                        child: Center(
                          child: Text(
                            _emojiForTypes(place.types),
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: _wmParchment,
                      child: Center(
                        child: Text(
                          _emojiForTypes(place.types),
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.55),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 14,
                    right: 14,
                    child: Text(
                      place.name,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (place.rating > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 13, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              place.rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Actions row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (place.types.isNotEmpty)
                          Text(
                            place.types.first
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: _wmStone,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (place.address.trim().isNotEmpty &&
                            city != 'Other')
                          Text(
                            city,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: _wmStone.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  _iconBtn(
                    icon: Icons.directions_outlined,
                    color: _wmForest,
                    bg: const Color(0xFFEBF3EE),
                    onTap: () => _openDirections(place),
                  ),
                  const SizedBox(width: 8),
                  _iconBtn(
                    icon: Icons.remove_circle_outline,
                    color: Colors.red.shade400,
                    bg: Colors.red.shade50,
                    onTap: () => _removePlace(cp),
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

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _showCollectionCardActions(CollectionPlace cp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CollectionPlaceActionsSheet(
        place: cp.place,
        onAddToMyDay: () {
          Navigator.pop(context);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _PlanCollectionPlaceSheet(place: cp.place),
          );
        },
        onViewDetails: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaceDetailScreen(placeId: cp.place.id),
            ),
          );
        },
      ),
    );
  }

  void _removePlace(CollectionPlace cp) async {
    HapticFeedback.lightImpact();
    await ref
        .read(tripCollectionsServiceProvider)
        .removePlaceFromCollection(
          collectionId: _collection.id,
          placeId: cp.placeId,
        );
    ref.invalidate(collectionPlacesProvider(_collection.id));
    ref.invalidate(tripCollectionsProvider);
    if (mounted) {
      showWanderMoodToast(
        context,
        message: AppLocalizations.of(context)!
            .socialRemovedFromCollection(cp.placeName, _collection.name),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.grey.shade700,
      );
    }
  }

  void _openDirections(Place place) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(place.name)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showEditSheet() {
    final nameCtrl = TextEditingController(text: _collection.name);
    String selectedEmoji = _collection.emoji;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: _wmParchment,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(AppLocalizations.of(context)!.socialEditCollection,
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                // Emoji picker row
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _kCollectionEmojis.map((e) {
                    final selected = e == selectedEmoji;
                    return GestureDetector(
                      onTap: () =>
                          setModalState(() => selectedEmoji = e),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? _wmForest.withOpacity(0.12)
                              : _wmParchment,
                          borderRadius: BorderRadius.circular(12),
                          border: selected
                              ? Border.all(color: _wmForest, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(e,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.socialCollectionName,
                    filled: true,
                    fillColor: _wmCream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 15),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      await ref
                          .read(tripCollectionsServiceProvider)
                          .updateCollection(
                            _collection.id,
                            name: name,
                            emoji: selectedEmoji,
                          );
                      ref.invalidate(tripCollectionsProvider);
                      if (mounted) {
                        setState(() {
                          _collection =
                              _collection.copyWith(name: name, emoji: selectedEmoji);
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _wmForest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(AppLocalizations.of(context)!.saveChanges,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.socialDeleteCollectionTitle,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
            'This removes "${_collection.name}" and all its places. Your saved places are not deleted.',
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: GoogleFonts.poppins(color: _wmStone)),
          ),
          TextButton(
            onPressed: () async {
                              Navigator.pop(ctx);
                              await ref
                                  .read(tripCollectionsServiceProvider)
                                  .deleteCollection(_collection.id);
                              ref.invalidate(tripCollectionsProvider);
                              if (mounted) Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.myDayDeleteActivityCta,
                style: GoogleFonts.poppins(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _emojiForTypes(List<String> types) {
    const map = {
      'restaurant': '🍽️',
      'cafe': '☕',
      'bar': '🍸',
      'museum': '🏛️',
      'park': '🌳',
      'beach': '🏖️',
      'shopping_mall': '🛍️',
      'gym': '💪',
      'spa': '💆',
      'tourist_attraction': '🗺️',
      'landmark': '🏰',
    };
    for (final t in types) {
      if (map.containsKey(t)) return map[t]!;
    }
    return '✨';
  }
}

class _CollectionPlaceActionsSheet extends StatelessWidget {
  final Place place;
  final VoidCallback onAddToMyDay;
  final VoidCallback onViewDetails;

  const _CollectionPlaceActionsSheet({
    required this.place,
    required this.onAddToMyDay,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _wmParchment,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            place.name,
            style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          _actionTile(Icons.event_available_outlined, 'Add to My Day', onAddToMyDay),
          _actionTile(Icons.info_outline, 'View Details', onViewDetails),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: _wmForest, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCollectionPlaceSheet extends ConsumerStatefulWidget {
  final Place place;
  const _PlanCollectionPlaceSheet({required this.place});

  @override
  ConsumerState<_PlanCollectionPlaceSheet> createState() =>
      _PlanCollectionPlaceSheetState();
}

class _PlanCollectionPlaceSheetState
    extends ConsumerState<_PlanCollectionPlaceSheet> {
  late DateTime _selectedDate;
  late int _slotIndex; // 0 morning, 1 afternoon, 2 evening
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _slotIndex = myDayQuickAddFirstOfferedSlotIndex(
          selectedDay: _selectedDate,
          now: now,
        ) ??
        2;
  }

  void _clampSlotToOffered() {
    final now = DateTime.now();
    if (myDayQuickAddSlotOfferedForDay(
      slotIndex: _slotIndex,
      selectedDay: _selectedDate,
      now: now,
    )) {
      return;
    }
    _slotIndex = myDayQuickAddFirstOfferedSlotIndex(
          selectedDay: _selectedDate,
          now: now,
        ) ??
        2;
  }

  DateTime get _selectedStartTime {
    final d = _selectedDate;
    final hour = _slotIndex == 0 ? 9 : (_slotIndex == 1 ? 14 : 19);
    return DateTime(d.year, d.month, d.day, hour, 0);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(first) ? first : _selectedDate,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365)),
      helpText: AppLocalizations.of(context)!.socialPickDayForPlan,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        _clampSlotToOffered();
      });
    }
  }

  Future<void> _addToMyDay() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final place = widget.place;
      final startTime = _selectedStartTime;
      final hour = startTime.hour;
      final timeOfDay = (hour >= 6 && hour < 12)
          ? 'morning'
          : (hour >= 12 && hour < 17)
              ? 'afternoon'
              : 'evening';
      final timeSlotEnum = timeOfDay == 'morning'
          ? TimeSlot.morning
          : timeOfDay == 'afternoon'
              ? TimeSlot.afternoon
              : TimeSlot.evening;

      PaymentType paymentType = PaymentType.free;
      if (place.types.any((t) =>
          ['restaurant', 'spa', 'museum', 'tourist_attraction'].contains(t))) {
        paymentType = PaymentType.reservation;
      }

      int duration = 60;
      for (final type in place.types) {
        final t = type.toLowerCase();
        if (['museum', 'tourist_attraction', 'amusement_park'].contains(t)) {
          duration = 120;
          break;
        } else if (['store', 'shopping_mall'].contains(t)) {
          duration = 90;
          break;
        }
      }

      final imageUrl = place.photos.isNotEmpty
          ? place.photos.first
          : 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&q=80';

      final activity = Activity(
        id: 'collection_place_${place.id}_${DateTime.now().millisecondsSinceEpoch}',
        name: place.name,
        description: place.description ?? 'Explore ${place.name}',
        imageUrl: imageUrl,
        rating: place.rating > 0 ? place.rating : 4.5,
        startTime: startTime,
        duration: duration,
        timeSlot: timeOfDay,
        timeSlotEnum: timeSlotEnum,
        tags: place.types.isNotEmpty ? place.types : ['explore'],
        location: LatLng(place.location.lat, place.location.lng),
        paymentType: paymentType,
        priceLevel: place.priceRange,
      );

      await ref
          .read(scheduledActivityServiceProvider)
          .saveScheduledActivities(
            [activity],
            isConfirmed: false,
            streakRefreshRef: ref,
          );

      final selectedDay = DateTime(startTime.year, startTime.month, startTime.day);
      ref.read(selectedMyDayDateProvider.notifier).state = selectedDay;
      ref.invalidate(scheduledActivitiesForTodayProvider);
      ref.invalidate(todayActivitiesProvider);
      ref.invalidate(cachedActivitySuggestionsProvider);

      if (mounted) {
        Navigator.pop(context);
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.dayPlanCardAddedToMyDay(place.name),
          duration: const Duration(seconds: 3),
          actionLabel: AppLocalizations.of(context)!.bookingViewAction,
          onAction: () {
            if (mounted) {
              context.go('/main', extra: {
                'tab': 0,
                'refresh': true,
                'targetDate': selectedDay.toIso8601String(),
              });
            }
          },
        );
      }
    } catch (_) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.dayPlanCardCouldNotAddMyDay,
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFEBF3EE) : const Color(0xFFF5F0E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? _wmForest : _wmParchment,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? _wmForest : _wmStone,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final tomorrowDate = todayDate.add(const Duration(days: 1));
    final isToday = _isSameDay(_selectedDate, todayDate);
    final isTomorrow = _isSameDay(_selectedDate, tomorrowDate);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _wmParchment,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            l10n.myDayQuickAddActivity,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            widget.place.name,
            style: GoogleFonts.poppins(fontSize: 13, color: _wmStone),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.socialDay, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              chip(
                label: l10n.timeLabelToday,
                selected: isToday,
                onTap: () => setState(() {
                  _selectedDate = todayDate;
                  _clampSlotToOffered();
                }),
              ),
              const SizedBox(width: 8),
              chip(
                label: l10n.timeLabelTomorrow,
                selected: isTomorrow,
                onTap: () => setState(() {
                  _selectedDate = tomorrowDate;
                  _clampSlotToOffered();
                }),
              ),
              const SizedBox(width: 8),
              chip(
                label: isToday || isTomorrow ? 'Pick date' : _formatDate(_selectedDate),
                selected: !isToday && !isTomorrow,
                onTap: _pickCustomDate,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Selected: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            style: GoogleFonts.poppins(fontSize: 11, color: _wmStone),
          ),
          const SizedBox(height: 14),
          Text(AppLocalizations.of(context)!.socialTime, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: () {
              final chips = <Widget>[];
              final clock = DateTime.now();
              for (var j = 0; j < 3; j++) {
                if (!myDayQuickAddSlotOfferedForDay(
                  slotIndex: j,
                  selectedDay: _selectedDate,
                  now: clock,
                )) {
                  continue;
                }
                if (chips.isNotEmpty) chips.add(const SizedBox(width: 8));
                final label = j == 0
                    ? l10n.timeLabelMorning
                    : (j == 1 ? l10n.timeLabelAfternoon : l10n.timeLabelEvening);
                chips.add(
                  chip(
                    label: label,
                    selected: _slotIndex == j,
                    onTap: () => setState(() => _slotIndex = j),
                  ),
                );
              }
              return chips;
            }(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _addToMyDay,
              style: ElevatedButton.styleFrom(
                backgroundColor: _wmForest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(AppLocalizations.of(context)!.dayPlanCardAddToMyDay, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

const _kCollectionEmojis = [
  '📍', '🏖️', '🌿', '🍽️', '🌃', '🎭', '🏔️', '☕',
  '🎨', '🛍️', '🏛️', '🌊', '🌸', '🎶', '🍹', '🏕️',
];
