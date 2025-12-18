import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/trending_activities_service.dart';
import '../../models/trending_activity.dart';
import 'trending_detail_screen.dart';

class TrendingListScreen extends ConsumerStatefulWidget {
  const TrendingListScreen({super.key});

  @override
  ConsumerState<TrendingListScreen> createState() => _TrendingListScreenState();
}

class _TrendingListScreenState extends ConsumerState<TrendingListScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedTrend = 'All';
  String _sortBy = 'Popularity';
  
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _categories = ['All', 'Dining', 'Culture', 'Outdoor', 'Sightseeing', 'Activity'];
  final List<String> _trendTypes = ['All', 'Hot', 'Rising', 'Popular'];
  final List<String> _sortOptions = ['Popularity', 'People Count', 'Alphabetical', 'Category'];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<TrendingActivity> _filterAndSortActivities(List<TrendingActivity> activities) {
    var filtered = activities.where((activity) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          activity.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          activity.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          activity.category.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Category filter
      final matchesCategory = _selectedCategory == 'All' ||
          activity.category.toLowerCase() == _selectedCategory.toLowerCase();
      
      // Trend type filter
      final matchesTrend = _selectedTrend == 'All' ||
          activity.trend.toLowerCase() == _selectedTrend.toLowerCase();
      
      return matchesSearch && matchesCategory && matchesTrend;
    }).toList();

    // Sort activities
    switch (_sortBy) {
      case 'People Count':
        filtered.sort((a, b) => b.peopleCount.compareTo(a.peopleCount));
        break;
      case 'Alphabetical':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Category':
        filtered.sort((a, b) => a.category.compareTo(b.category));
        break;
      case 'Popularity':
      default:
        filtered.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final trendingAsync = ref.watch(trendingActivitiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            _buildSearchAndFilters(),
            trendingAsync.when(
              data: (activities) => _buildTrendingGrid(activities),
              loading: () => _buildLoadingSliver(),
              error: (error, stack) => _buildErrorSliver(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF12B347),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "🔥",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              "Trending in Rotterdam",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF12B347),
                Color(0xFF0E8B3A),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Search trending activities...",
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF12B347)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterSection("Category", _categories, _selectedCategory, (value) {
                    setState(() => _selectedCategory = value);
                  }),
                  const SizedBox(width: 16),
                  _buildFilterSection("Trend", _trendTypes, _selectedTrend, (value) {
                    setState(() => _selectedTrend = value);
                  }),
                  const SizedBox(width: 16),
                  _buildFilterSection("Sort", _sortOptions, _sortBy, (value) {
                    setState(() => _sortBy = value);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options, String selected, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = option == selected;
              
              return Container(
                margin: EdgeInsets.only(right: index < options.length - 1 ? 8 : 0),
                child: FilterChip(
                  label: Text(
                    option,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF4A5568),
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => onChanged(option),
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF12B347),
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF12B347) : Colors.grey[300]!,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingGrid(List<TrendingActivity> allActivities) {
    final filteredActivities = _filterAndSortActivities(allActivities);
    
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Results Count
            Text(
              "${filteredActivities.length} trending activities found",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4A5568),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Grid of Activities
            if (filteredActivities.isEmpty)
              _buildEmptyState()
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filteredActivities.length,
                itemBuilder: (context, index) {
                  final activity = filteredActivities[index];
                  return _buildTrendingCard(activity);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingCard(TrendingActivity activity) {
    return GestureDetector(
      onTap: () {
        context.push('/trending-detail', extra: activity);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with emoji and trend badge
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  _buildTrendBadge(activity.trend),
                ],
              ),
            ),
            
            // Title and subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3748),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF4A5568),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Stats and category
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: const Color(0xFF12B347),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${activity.peopleCount}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF12B347),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12B347).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activity.category.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF12B347),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendBadge(String trend) {
    Color bgColor;
    Color textColor = Colors.white;
    IconData icon;

    switch (trend.toLowerCase()) {
      case 'hot':
        bgColor = const Color(0xFFFF6B6B);
        icon = Icons.local_fire_department;
        break;
      case 'rising':
        bgColor = const Color(0xFFFFB366);
        icon = Icons.trending_up;
        break;
      case 'popular':
      default:
        bgColor = const Color(0xFF4ECDC4);
        icon = Icons.star;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            trend.toLowerCase() == 'hot' ? 'Hot' : 
            trend.toLowerCase() == 'rising' ? 'Rising' : 'Popular',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Text("🔍", style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            "No trending activities found",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your filters or search terms",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedCategory = 'All';
                _selectedTrend = 'All';
                _sortBy = 'Popularity';
                _searchController.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF12B347),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Clear Filters",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
            ),
            const SizedBox(height: 16),
            Text(
              "Loading trending activities...",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSliver() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Text("😞", style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              "Couldn't load trending activities",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please check your connection and try again",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF718096),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(trendingActivitiesProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF12B347),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Try Again",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 