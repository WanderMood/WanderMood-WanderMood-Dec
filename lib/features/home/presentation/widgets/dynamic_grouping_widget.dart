import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../places/models/place.dart';
import '../../../places/presentation/widgets/place_card.dart';
import '../../providers/dynamic_grouping_provider.dart';
import '../../providers/smart_context_provider.dart';

class DynamicGroupingWidget extends ConsumerWidget {
  final List<Place> allPlaces;
  final dynamic userLocation;
  final List<String> aiRecommendedPlaceNames;

  const DynamicGroupingWidget({
    Key? key,
    required this.allPlaces,
    this.userLocation,
    this.aiRecommendedPlaceNames = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupingResult = ref.watch(dynamicGroupingProvider);
    final userId = ref.watch(currentUserIdProvider);

    if (groupingResult == null) {
      // Trigger initial grouping
      final smartContext = ref.watch(smartContextProvider);
      if (allPlaces.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(dynamicGroupingProvider.notifier).groupPlaces(
            places: allPlaces,
            context: smartContext,
            userId: userId,
          );
        });
      }
      return _buildLoadingState();
    }

    if (groupingResult.isLoading) {
      return _buildLoadingState();
    }

    if (groupingResult.error != null) {
      return _buildErrorState(groupingResult.error!);
    }

    if (groupingResult.groups.isEmpty) {
      return _buildFallbackList();
    }

    return _buildGroupedPlaces(context, ref, groupingResult);
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.blue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Analyzing places with smart context...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildErrorState(String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Smart grouping temporarily unavailable',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: allPlaces.length,
      itemBuilder: (context, index) {
        final place = allPlaces[index];
        return PlaceCard(
          key: ValueKey(place.id), // Add key to prevent unnecessary rebuilds
          place: place,
          userLocation: userLocation,
          onTap: () => context.push('/place/${place.id}'),
        );
      },
    );
  }

  Widget _buildGroupedPlaces(BuildContext context, WidgetRef ref, DynamicGroupingResult result) {
    final groups = result.groups;
    final sortedGroupKeys = _sortGroupsByRelevance(groups);

    return CustomScrollView(
      slivers: [
        // Dynamic Grouping Header
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.withOpacity(0.1),
                  Colors.blue.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.deepPurple.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dynamic Grouping Active ✨',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Text(
                        '${result.totalPlaces} places in ${groups.length} contextual groups',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildGroupSwitcher(context, ref, sortedGroupKeys, groups),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
        ),

        // Smart Recommendations
        if (result.recommendations.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: result.recommendations.map((rec) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        rec,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 100.ms),
          ),

        // Grouped Places
        ...sortedGroupKeys.map((groupKey) {
          final groupName = _formatGroupName(groupKey);
          final groupPlaces = groups[groupKey]!;
          final groupIndex = sortedGroupKeys.indexOf(groupKey);

          return SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Header
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getGroupColor(groupIndex),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getGroupIcon(groupKey),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              groupName,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              '${groupPlaces.length} places',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildGroupScoreIndicator(groupPlaces),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: (groupIndex * 100).ms),

                // Group Places
                ...groupPlaces.asMap().entries.map((entry) {
                  final placeIndex = entry.key;
                  final place = entry.value;
                  final isAIRecommended = aiRecommendedPlaceNames.contains(place.name);

                  Widget placeCard = PlaceCard(
                    key: ValueKey('${place.id}_${groupKey}_$placeIndex'), // Unique key to prevent rebuilds
                    place: place,
                    userLocation: userLocation,
                    onTap: () {
                      // Track user interaction
                      final userId = ref.read(currentUserIdProvider);
                      if (userId != null) {
                        ref.read(dynamicGroupingProvider.notifier)
                            .updateUserInteraction(
                          userId: userId,
                          visitedPlaceId: place.id,
                        );
                      }
                      context.push('/place/${place.id}');
                    },
                  );

                  // Add group-specific styling
                  placeCard = Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getGroupColor(groupIndex).withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getGroupColor(groupIndex).withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: placeCard,
                  );

                  // Add AI recommendation styling if applicable
                  if (isAIRecommended) {
                    placeCard = Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2A6049).withOpacity(0.1),
                            const Color(0xFF2A6049).withOpacity(0.05),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF2A6049).withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          placeCard,
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A6049),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'AI Pick',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return placeCard.animate()
                      .fadeIn(duration: 300.ms, delay: ((groupIndex * 2 + placeIndex) * 50).ms)
                      .slideX(begin: 0.2, end: 0);
                }),
              ],
            ),
          );
        }),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildGroupSwitcher(BuildContext context, WidgetRef ref, List<String> groupKeys, Map<String, List<Place>> groups) {
    if (groupKeys.length <= 1) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: Icon(Icons.tune, color: Colors.deepPurple),
      itemBuilder: (context) => groupKeys.map((key) {
        final groupName = _formatGroupName(key);
        final count = groups[key]!.length;
        return PopupMenuItem<String>(
          value: key,
          child: Row(
            children: [
              Icon(_getGroupIcon(key), size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(groupName)),
              Text('($count)', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        );
      }).toList(),
      onSelected: (key) {
        // Scroll to group - implement if needed
      },
    );
  }

  Widget _buildGroupScoreIndicator(List<Place> places) {
    final avgRating = places.map((p) => p.rating).reduce((a, b) => a + b) / places.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 2),
          Text(
            avgRating.toStringAsFixed(1),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _sortGroupsByRelevance(Map<String, List<Place>> groups) {
    final entries = groups.entries.toList();
    entries.sort((a, b) {
      // Prioritize by number of places and average rating
      final aScore = a.value.length * a.value.map((p) => p.rating).reduce((x, y) => x + y) / a.value.length;
      final bScore = b.value.length * b.value.map((p) => p.rating).reduce((x, y) => x + y) / b.value.length;
      return bScore.compareTo(aScore);
    });
    return entries.map((e) => e.key).toList();
  }

  String _formatGroupName(String key) {
    return key.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  IconData _getGroupIcon(String groupKey) {
    if (groupKey.contains('morning') || groupKey.contains('start')) return Icons.wb_sunny;
    if (groupKey.contains('afternoon')) return Icons.wb_sunny_outlined;
    if (groupKey.contains('evening')) return Icons.wb_twilight;
    if (groupKey.contains('night')) return Icons.bedtime;
    if (groupKey.contains('indoor')) return Icons.home;
    if (groupKey.contains('outdoor')) return Icons.nature;
    if (groupKey.contains('energy') || groupKey.contains('adventure')) return Icons.flash_on;
    if (groupKey.contains('peaceful') || groupKey.contains('calm')) return Icons.spa;
    if (groupKey.contains('social')) return Icons.group;
    if (groupKey.contains('solo')) return Icons.person;
    return Icons.place;
  }

  Color _getGroupColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.brown,
    ];
    return colors[index % colors.length];
  }
} 