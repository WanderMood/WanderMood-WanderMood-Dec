import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/presentation/widgets/place_card.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Full vertical list for one Explore section ("See all").
class ExploreSeeAllScreen extends ConsumerStatefulWidget {
  const ExploreSeeAllScreen({
    super.key,
    required this.title,
    required this.initialCards,
    required this.onLoadMore,
    required this.onAddToMyDay,
  });

  final String title;
  final List<Place> initialCards;
  final Future<List<Place>> Function() onLoadMore;
  final void Function(Place place) onAddToMyDay;

  @override
  ConsumerState<ExploreSeeAllScreen> createState() => _ExploreSeeAllScreenState();
}

class _ExploreSeeAllScreenState extends ConsumerState<ExploreSeeAllScreen> {
  late List<Place> _cards;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _cards = List<Place>.from(widget.initialCards);
  }

  @override
  void didUpdateWidget(covariant ExploreSeeAllScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCards != widget.initialCards) {
      _cards = List<Place>.from(widget.initialCards);
    }
  }

  Future<void> _onLoadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.onLoadMore();
      if (mounted) setState(() => _cards = List<Place>.from(next));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final city = ref.watch(locationNotifierProvider).value ?? '';
    final ul = ref.watch(userLocationProvider).value;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0E8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1C18)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E1C18),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _cards.length + 1,
        itemBuilder: (context, index) {
          if (index == _cards.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: TextButton(
                  onPressed: _loadingMore ? null : _onLoadMore,
                  child: Text(
                    l10n.exploreLoadMore,
                    style: TextStyle(
                      color: _loadingMore
                          ? const Color(0xFF8C8780)
                          : const Color(0xFF2A6049),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }
          final place = _cards[index];
          return PlaceCard(
            place: place,
            userLocation: ul,
            cityName: city.isNotEmpty ? city : null,
            showAddToMyDayButton: true,
            onAddToMyDayTap: () => widget.onAddToMyDay(place),
            onTap: () => context.push('/place/${place.id}'),
          );
        },
      ),
    );
  }
}
