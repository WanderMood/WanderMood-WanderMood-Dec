import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../models/trending_activity.dart';
import '../../../places/models/place.dart';
import '../../../places/providers/moody_explore_provider.dart';
import '../../../places/presentation/widgets/place_card.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class TrendingDetailScreen extends ConsumerStatefulWidget {
  final TrendingActivity trending;

  const TrendingDetailScreen({
    super.key,
    required this.trending,
  });

  @override
  ConsumerState<TrendingDetailScreen> createState() => _TrendingDetailScreenState();
}

class _TrendingDetailScreenState extends ConsumerState<TrendingDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final explorePlacesAsync = ref.watch(moodyHubExploreCacheOnlyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTrendingStats(),
                      const SizedBox(height: 24),
                      _buildDescriptionCard(),
                      const SizedBox(height: 24),
                      _buildRelatedPlaces(explorePlacesAsync),
                      const SizedBox(height: 100), // Bottom padding
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: _getTrendColor(),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getTrendColor(),
                _getTrendColor().withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.trending.emoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.trending.title,
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildTrendBadge(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildTrendBadge() {
    String text;
    IconData icon;
    
    switch (widget.trending.trend) {
      case 'hot':
        text = 'Hot Trending';
        icon = Icons.local_fire_department;
        break;
      case 'rising':
        text = 'Rising';
        icon = Icons.trending_up;
        break;
      case 'popular':
        text = 'Popular';
        icon = Icons.star;
        break;
      default:
        text = 'Trending';
        icon = Icons.trending_up;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem("👥", "${widget.trending.peopleCount}", "People exploring"),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[200],
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          _buildStatItem("📊", "${widget.trending.popularityScore.toInt()}%", "Match score"),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[200],
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          _buildStatItem("🏷️", widget.trending.category.toUpperCase(), "Category"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF4A5568),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("✨", style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                "What's Special",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.trending.subtitle,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF4A5568),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getDetailedDescription(AppLocalizations.of(context)!),
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF4A5568),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedPlaces(AsyncValue<List<Place>> explorePlacesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("📍", style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.trendingDetailSimilarPlacesSection,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        explorePlacesAsync.when(
          data: (places) => _buildPlacesList(places),
          loading: () => _buildLoadingPlaces(),
          error: (_, __) => _buildErrorState(),
        ),
      ],
    );
  }

  Widget _buildPlacesList(List<Place> allPlaces) {
    // Filter places based on the trending category
    final filteredPlaces = allPlaces.where((place) {
      final placeName = place.name.toLowerCase();
      final placeTypes = place.types.map((t) => t.toLowerCase()).toList();
      final category = widget.trending.category.toLowerCase();
      
      switch (category) {
        case 'dining':
          return placeName.contains('restaurant') || 
                 placeName.contains('cafe') || 
                 placeName.contains('bar') ||
                 placeName.contains('umami') ||
                 placeName.contains('bazar') ||
                 placeTypes.any((type) => type.contains('restaurant') || 
                                        type.contains('food') || 
                                        type.contains('cafe'));
        case 'culture':
          return placeName.contains('museum') || 
                 placeName.contains('gallery') || 
                 placeName.contains('art') ||
                 placeName.contains('kijk') ||
                 placeTypes.any((type) => type.contains('museum') || 
                                        type.contains('gallery') || 
                                        type.contains('cultural'));
        case 'outdoor':
          return placeName.contains('park') || 
                 placeName.contains('garden') || 
                 placeName.contains('tour') ||
                 placeName.contains('bridge') ||
                 placeName.contains('boompjes') ||
                 placeTypes.any((type) => type.contains('park') || 
                                        type.contains('tourist') || 
                                        type.contains('attraction'));
        case 'sightseeing':
          return placeName.contains('bridge') || 
                 placeName.contains('view') || 
                 placeName.contains('tower') ||
                 placeName.contains('erasmus') ||
                 placeName.contains('markthal') ||
                 placeTypes.any((type) => type.contains('tourist') || 
                                        type.contains('attraction') || 
                                        type.contains('landmark'));
        case 'activity':
        default:
          // Show a broader range of places for general activities
          return !placeName.contains('hotel') || 
                 placeTypes.any((type) => type.contains('tourist') || 
                                        type.contains('attraction') || 
                                        type.contains('restaurant') ||
                                        type.contains('museum'));
      }
    }).take(5).toList();

    if (filteredPlaces.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Text("🔍", style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              l10n.trendingDetailNoRelatedPlaces,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: filteredPlaces.map((place) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: PlaceCard(
          place: place,
          onTap: () {
            // Navigate to place detail
            context.push('/place-detail', extra: place);
          },
        ),
      )).toList(),
    );
  }

  Widget _buildLoadingPlaces() {
    return Column(
      children: List.generate(2, (index) => Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
      )),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Text("😅", style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            l10n.trendingDetailRelatedPlacesError,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF4A5568),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTrendColor() {
    switch (widget.trending.trend) {
      case 'hot':
        return const Color(0xFFE53E3E);
      case 'rising':
        return const Color(0xFFD69E2E);
      case 'popular':
        return const Color(0xFF2A6049);
      default:
        return const Color(0xFF4299E1);
    }
  }

  String _getDetailedDescription(AppLocalizations l10n) {
    final category = widget.trending.category;
    final title = widget.trending.title;

    switch (category) {
      case 'dining':
        return l10n.trendingDetailLongDining(title);
      case 'culture':
        return l10n.trendingDetailLongCulture(title);
      case 'outdoor':
        return l10n.trendingDetailLongOutdoor(title);
      case 'sightseeing':
        return l10n.trendingDetailLongSightseeing(title);
      case 'shopping':
        return l10n.trendingDetailLongShopping(title);
      case 'fitness':
        return l10n.trendingDetailLongFitness(title);
      default:
        return l10n.trendingDetailLongDefault(title);
    }
  }
} 