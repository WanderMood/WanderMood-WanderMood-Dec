import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/home/presentation/screens/main_screen.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/services/saved_places_service.dart';
import 'package:wandermood/features/places/services/trip_collections_service.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/features/plans/domain/enums/payment_type.dart';
import 'package:wandermood/features/plans/domain/enums/time_slot.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'place_detail_screen.dart';
import 'collection_detail_screen.dart';

const _wmForest = Color(0xFF2A6049);
const _wmCream = Color(0xFFF5F0E8);
const _wmParchment = Color(0xFFE8E2D8);
const _wmStone = Color(0xFF8C8780);
/// My Day "PLANNED" chip — saved place cards use same frame color.
const _wmWarmBronze = Color(0xFF8F7355);
const _wmWarmBronzeDeep = Color(0xFF6B5A47);

class SavedPlacesScreen extends ConsumerStatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  ConsumerState<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends ConsumerState<SavedPlacesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.invalidate(savedPlacesProvider);
      // Make sure collections tables exist.
      await ref.read(tripCollectionsServiceProvider).ensureTablesExist();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _wmCream,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: _wmCream,
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFF1A202C)),
            title: Text(
              l10n.savedPlacesScreenTitle,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A202C),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_outlined,
                    color: Color(0xFF1A202C)),
                onPressed: () {
                  ref.invalidate(savedPlacesProvider);
                  ref.invalidate(tripCollectionsProvider);
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelStyle:
                  GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle:
                  GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 14),
              labelColor: _wmForest,
              unselectedLabelColor: _wmStone,
              indicatorColor: _wmForest,
              indicatorWeight: 2.5,
              tabs: [
                Tab(text: l10n.savedPlacesTabAllSaved),
                Tab(text: l10n.savedPlacesTabCollections),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _AllSavedTab(),
            _CollectionsTab(),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// All Saved tab
// ────────────────────────────────────────────────────────────────────────────

class _AllSavedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedPlacesProvider);

    return savedAsync.when(
      data: (places) => places.isEmpty
          ? _emptyState(context, ref)
          : _PlacesList(places: places),
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _wmForest)),
      error: (e, _) => Center(
        child: Text(e.toString(),
            style: GoogleFonts.poppins(color: _wmStone)),
      ),
    );
  }

  Widget _emptyState(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _wmParchment,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_border,
                  size: 56, color: _wmStone),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.savedPlacesEmptyTitle,
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.savedPlacesEmptyBody,
              style: GoogleFonts.poppins(fontSize: 14, color: _wmStone),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(mainTabProvider.notifier).state = 1;
                if (context.mounted) {
                  context.go('/main', extra: {'tab': 1});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _wmForest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(AppLocalizations.of(context)!.guestExplorePlaces,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacesList extends ConsumerWidget {
  final List<SavedPlace> places;
  const _PlacesList({required this.places});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: places.length,
      itemBuilder: (context, index) =>
          _SavedPlaceCard(savedPlace: places[index]),
    );
  }
}

class _SavedPlaceCard extends ConsumerStatefulWidget {
  final SavedPlace savedPlace;
  const _SavedPlaceCard({required this.savedPlace});

  @override
  ConsumerState<_SavedPlaceCard> createState() => _SavedPlaceCardState();
}

class _SavedPlaceCardState extends ConsumerState<_SavedPlaceCard> {
  static const _gradients = [
    [Color(0xFFFFE5B4), Color(0xFFFFD6A5)],
    [Color(0xFFB4E5FF), Color(0xFFA5D8FF)],
    [Color(0xFFFFB4E5), Color(0xFFFFA5D8)],
    [Color(0xFFB4FFD5), Color(0xFFA5FFBB)],
    [Color(0xFFD4B4FF), Color(0xFFC8A5FF)],
    [Color(0xFFFFE5D4), Color(0xFFFFD4B4)],
    [Color(0xFFD4FFE5), Color(0xFFB4FFD4)],
    [Color(0xFFFFD4E5), Color(0xFFFFC4D4)],
  ];

  List<Color> _gradient(int hash) => _gradients[hash.abs() % _gradients.length];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final place = widget.savedPlace.place;
    final grad = _gradient(widget.savedPlace.hashCode);
    final hasPhoto =
        place.photos.isNotEmpty && place.photos.first.isNotEmpty;

    return GestureDetector(
      onTap: () => _showCardActionsSheet(context),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showAddToCollectionSheet(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.28),
            width: 1.25,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasPhoto)
                    CachedNetworkImage(
                      imageUrl: place.photos.first,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: grad,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) =>
                          _emojiPlaceholder(place.types, grad),
                    )
                  else
                    _emojiPlaceholder(place.types, grad),
                  if (!hasPhoto)
                    Container(
                      color: _wmWarmBronze.withValues(alpha: 0.4),
                    ),
                  if (hasPhoto)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              _wmWarmBronze.withValues(alpha: 0.45),
                              _wmWarmBronzeDeep.withValues(alpha: 0.9),
                            ],
                            stops: const [0.0, 0.38, 0.68, 1.0],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 14,
                    left: 14,
                    right: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (place.rating > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade600,
                              borderRadius: BorderRadius.circular(10),
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
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          color: Colors.white.withValues(alpha: 0.2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.collections_bookmark_outlined,
                                  size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                l10n.savedPlacesHoldToCollect,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 1,
                      ),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        _wmWarmBronze.withValues(alpha: 0.75),
                        _wmWarmBronzeDeep.withValues(alpha: 0.92),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.savedPlacesSavedPrefix(
                                _timeAgo(context, widget.savedPlace.savedAt),
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                            if (place.types.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                place.types.first
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _iconBtn(
                        icon: Icons.collections_bookmark_outlined,
                        color: Colors.white,
                        bg: Colors.white.withValues(alpha: 0.2),
                        tooltip: AppLocalizations.of(context)!.socialAddToCollection,
                        onTap: () => _showAddToCollectionSheet(context),
                      ),
                      const SizedBox(width: 8),
                      _iconBtn(
                        icon: Icons.directions_outlined,
                        color: Colors.white,
                        bg: Colors.white.withValues(alpha: 0.2),
                        tooltip: AppLocalizations.of(context)!.activityDetailDirections,
                        onTap: () => _openDirections(place),
                      ),
                      const SizedBox(width: 8),
                      _iconBtn(
                        icon: Icons.bookmark_remove_outlined,
                        color: const Color(0xFFFFD0D0),
                        bg: Colors.white.withValues(alpha: 0.14),
                        tooltip: AppLocalizations.of(context)!.myDayDeleteActivityCta,
                        onTap: () => _remove(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emojiPlaceholder(List<String> types, List<Color> grad) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: grad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(_emojiForTypes(types),
            style: const TextStyle(fontSize: 56)),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  void _remove(BuildContext context) {
    ref
        .read(savedPlacesServiceProvider)
        .unsavePlace(widget.savedPlace.placeId);
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!
          .socialRemoved(widget.savedPlace.placeName),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.grey.shade700,
    );
  }

  void _openDirections(Place place) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(place.name)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showAddToCollectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddToCollectionSheet(savedPlace: widget.savedPlace),
    );
  }

  void _showCardActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SavedPlaceActionsSheet(
        place: widget.savedPlace.place,
        onViewDetails: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaceDetailScreen(placeId: widget.savedPlace.place.id),
            ),
          );
        },
        onAddToMyDay: () {
          Navigator.pop(context);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _PlanSavedPlaceSheet(place: widget.savedPlace.place),
          );
        },
        onAddToCollection: () {
          Navigator.pop(context);
          _showAddToCollectionSheet(context);
        },
      ),
    );
  }

  String _timeAgo(BuildContext context, DateTime dt) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return l10n.savedPlacesTimeJustNow;
      return l10n.savedPlacesTimeHoursAgo(diff.inHours);
    } else if (diff.inDays == 1) {
      return l10n.savedPlacesTimeYesterday;
    } else if (diff.inDays < 7) {
      return l10n.savedPlacesTimeDaysAgo(diff.inDays);
    }
    return DateFormat.yMMMd(locale).format(dt);
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

// ────────────────────────────────────────────────────────────────────────────
// Collections tab
// ────────────────────────────────────────────────────────────────────────────

class _CollectionsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(tripCollectionsProvider);

    return collectionsAsync.when(
      data: (collections) => _CollectionsGrid(collections: collections),
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _wmForest)),
      error: (e, _) => Center(
          child: Text(e.toString(),
              style: GoogleFonts.poppins(color: _wmStone))),
    );
  }
}

class _CollectionsGrid extends ConsumerWidget {
  final List<TripCollection> collections;
  const _CollectionsGrid({required this.collections});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemCount: collections.length + 1, // +1 for "New collection" card
      itemBuilder: (context, index) {
        if (index == 0) return _NewCollectionCard();
        final collection = collections[index - 1];
        return _CollectionCard(collection: collection);
      },
    );
  }
}

class _CollectionCard extends ConsumerWidget {
  final TripCollection collection;
  const _CollectionCard({required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CollectionDetailScreen(collection: collection),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
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
              // Cover photo or emoji block
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (collection.coverPhotoUrl != null &&
                        collection.coverPhotoUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: collection.coverPhotoUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            _emojiBlock(collection.emoji),
                      )
                    else
                      _emojiBlock(collection.emoji),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Text(
                        collection.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Place count row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 14, color: _wmStone),
                    const SizedBox(width: 4),
                    Text(
                      collection.placeCount == 1
                          ? l10n.savedPlacesPlaceCountOne(collection.placeCount)
                          : l10n.savedPlacesPlaceCountMany(collection.placeCount),
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: _wmStone),
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

  Widget _emojiBlock(String emoji) {
    return Container(
      color: _wmParchment,
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 48)),
      ),
    );
  }
}

class _NewCollectionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _CreateCollectionSheet(),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _wmForest.withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _wmForest.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: _wmForest, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.savedPlacesNewCollection,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _wmForest,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.savedPlacesNewCollectionSubtitle,
              style: GoogleFonts.poppins(fontSize: 11, color: _wmStone),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateCollectionSheet extends ConsumerStatefulWidget {
  const _CreateCollectionSheet();

  @override
  ConsumerState<_CreateCollectionSheet> createState() =>
      _CreateCollectionSheetState();
}

class _CreateCollectionSheetState extends ConsumerState<_CreateCollectionSheet> {
  final _nameCtrl = TextEditingController();
  String _emoji = '📍';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(tripCollectionsServiceProvider).createCollection(
        name: name,
        emoji: _emoji,
      );
      ref.invalidate(tripCollectionsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
            Text(
              l10n.savedPlacesNewCollection,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _kCollectionEmojis.map((e) {
                final selected = e == _emoji;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
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
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.socialCollectionNameHint,
                filled: true,
                fillColor: _wmCream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 15),
              onSubmitted: (_) => _create(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.red.shade600),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _wmForest,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _wmForest.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(AppLocalizations.of(context)!.socialCreate,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Add to collection bottom sheet
// ────────────────────────────────────────────────────────────────────────────

class _AddToCollectionSheet extends ConsumerWidget {
  final SavedPlace savedPlace;
  const _AddToCollectionSheet({required this.savedPlace});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final collectionsAsync = ref.watch(tripCollectionsProvider);

    return Container(
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
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _wmParchment,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            l10n.savedPlacesAddToCollectionTitle,
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            savedPlace.placeName,
            style: GoogleFonts.poppins(fontSize: 13, color: _wmStone),
          ),
          const SizedBox(height: 16),
          collectionsAsync.when(
            data: (collections) => collections.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l10n.savedPlacesNoCollectionsHint,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: _wmStone),
                    ),
                  )
                : ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: collections.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final col = collections[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _wmParchment,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(col.emoji,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                          title: Text(
                            col.name,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text(
                            l10n.savedPlacesPlacesCount(col.placeCount),
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: _wmStone),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: _wmStone),
                          onTap: () async {
                            await ref
                                .read(tripCollectionsServiceProvider)
                                .addPlaceToCollection(
                                  collectionId: col.id,
                                  place: savedPlace.place,
                                );
                            ref.invalidate(tripCollectionsProvider);
                            ref.invalidate(collectionPlacesProvider(col.id));
                            if (context.mounted) {
                              Navigator.pop(context);
                              showWanderMoodToast(
                                context,
                                message:
                                    l10n.savedPlacesAddedToCollection(col.name),
                                duration: const Duration(seconds: 2),
                                leading: Text(col.emoji,
                                    style: const TextStyle(fontSize: 18)),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                  child: CircularProgressIndicator(color: _wmForest)),
            ),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SavedPlaceActionsSheet extends StatelessWidget {
  final Place place;
  final VoidCallback onViewDetails;
  final VoidCallback onAddToMyDay;
  final VoidCallback onAddToCollection;

  const _SavedPlaceActionsSheet({
    required this.place,
    required this.onViewDetails,
    required this.onAddToMyDay,
    required this.onAddToCollection,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          _actionTile(Icons.event_available_outlined, l10n.savedPlacesActionAddToMyDay, onAddToMyDay),
          _actionTile(Icons.collections_bookmark_outlined, l10n.savedPlacesActionAddToCollection, onAddToCollection),
          _actionTile(Icons.info_outline, l10n.savedPlacesActionViewDetails, onViewDetails),
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

class _PlanSavedPlaceSheet extends ConsumerStatefulWidget {
  final Place place;
  const _PlanSavedPlaceSheet({required this.place});

  @override
  ConsumerState<_PlanSavedPlaceSheet> createState() => _PlanSavedPlaceSheetState();
}

class _PlanSavedPlaceSheetState extends ConsumerState<_PlanSavedPlaceSheet> {
  late DateTime _selectedDate;
  int _slotIndex = 1; // 0 morning, 1 afternoon, 2 evening
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  DateTime get _selectedStartTime {
    final d = _selectedDate;
    final hour = _slotIndex == 0 ? 9 : (_slotIndex == 1 ? 14 : 19);
    return DateTime(d.year, d.month, d.day, hour, 0);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('d MMM', locale).format(date);
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
        id: 'saved_place_${place.id}_${DateTime.now().millisecondsSinceEpoch}',
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
          .saveScheduledActivities([activity], isConfirmed: false);

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
    } catch (e) {
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
            l10n.savedPlacesPlanSheetTitle,
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
                onTap: () => setState(() => _selectedDate = todayDate),
              ),
              const SizedBox(width: 8),
              chip(
                label: l10n.timeLabelTomorrow,
                selected: isTomorrow,
                onTap: () => setState(() => _selectedDate = tomorrowDate),
              ),
              const SizedBox(width: 8),
              chip(
                label: isToday || isTomorrow ? l10n.savedPlacesPickDate : _formatDate(_selectedDate),
                selected: !isToday && !isTomorrow,
                onTap: _pickCustomDate,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.savedPlacesSelectedDate(
              DateFormat.yMd(Localizations.localeOf(context).toString())
                  .format(_selectedDate),
            ),
            style: GoogleFonts.poppins(fontSize: 11, color: _wmStone),
          ),
          const SizedBox(height: 14),
          Text(AppLocalizations.of(context)!.socialTime, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              chip(label: l10n.timeLabelMorning, selected: _slotIndex == 0, onTap: () => setState(() => _slotIndex = 0)),
              const SizedBox(width: 8),
              chip(label: l10n.timeLabelAfternoon, selected: _slotIndex == 1, onTap: () => setState(() => _slotIndex = 1)),
              const SizedBox(width: 8),
              chip(label: l10n.timeLabelEvening, selected: _slotIndex == 2, onTap: () => setState(() => _slotIndex = 2)),
            ],
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
