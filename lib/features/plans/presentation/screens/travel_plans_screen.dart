import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:intl/intl.dart';

// Sample plan data model
class TravelPlan {
  final String id;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String imageUrl;
  final List<String> activities;
  final bool isCompleted;
  final bool isFavorite;

  TravelPlan({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.imageUrl,
    required this.activities,
    this.isCompleted = false,
    this.isFavorite = false,
  });
}

class TravelPlansScreen extends ConsumerStatefulWidget {
  const TravelPlansScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TravelPlansScreen> createState() => _TravelPlansScreenState();
}

class _TravelPlansScreenState extends ConsumerState<TravelPlansScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Sample travel plans data
  final List<TravelPlan> _travelPlans = [
    TravelPlan(
      id: '1',
      title: 'San Francisco Adventure',
      destination: 'San Francisco, CA',
      startDate: DateTime.now().add(const Duration(days: 15)),
      endDate: DateTime.now().add(const Duration(days: 20)),
      imageUrl: 'assets/images/fallbacks/default.jpg',
      activities: ['Golden Gate Bridge', 'Alcatraz Island', 'Fisherman\'s Wharf', 'Union Square'],
    ),
    TravelPlan(
      id: '2',
      title: 'Weekend Getaway',
      destination: 'Napa Valley, CA',
      startDate: DateTime.now().add(const Duration(days: 3)),
      endDate: DateTime.now().add(const Duration(days: 5)),
      imageUrl: 'assets/images/fallbacks/default.jpg',
      activities: ['Wine Tasting', 'Hot Air Balloon Ride', 'Spa Day', 'Fine Dining'],
      isFavorite: true,
    ),
    TravelPlan(
      id: '3',
      title: 'Summer Beach Vacation',
      destination: 'Santa Cruz, CA',
      startDate: DateTime.now().add(const Duration(days: 45)),
      endDate: DateTime.now().add(const Duration(days: 52)),
      imageUrl: 'assets/images/fallbacks/default.jpg',
      activities: ['Beach Day', 'Boardwalk', 'Surfing Lessons', 'Coastal Hiking'],
    ),
    TravelPlan(
      id: '4',
      title: 'City Exploration',
      destination: 'San Francisco, CA',
      startDate: DateTime.now().subtract(const Duration(days: 20)),
      endDate: DateTime.now().subtract(const Duration(days: 15)),
      imageUrl: 'assets/images/fallbacks/default.jpg',
      activities: ['Museum Tour', 'Shopping', 'Ferry Building', 'Chinatown'],
      isCompleted: true,
    ),
    TravelPlan(
      id: '5',
      title: 'Nature Retreat',
      destination: 'Yosemite National Park, CA',
      startDate: DateTime.now().subtract(const Duration(days: 60)),
      endDate: DateTime.now().subtract(const Duration(days: 55)),
      imageUrl: 'assets/images/fallbacks/default.jpg',
      activities: ['Hiking', 'Photography', 'Camping', 'Stargazing'],
      isCompleted: true,
      isFavorite: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter plans by upcoming/past
    final upcomingPlans = _travelPlans.where((plan) => !plan.isCompleted).toList();
    final pastPlans = _travelPlans.where((plan) => plan.isCompleted).toList();
    
    // Sort by date
    upcomingPlans.sort((a, b) => a.startDate.compareTo(b.startDate));
    pastPlans.sort((a, b) => b.endDate.compareTo(a.endDate)); // Past plans in reverse chronological

    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Travel Plans',
            style: GoogleFonts.museoModerno(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF12B347),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF12B347),
            unselectedLabelColor: Colors.black54,
            indicatorColor: const Color(0xFF12B347),
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Upcoming plans tab
            _buildPlansList(upcomingPlans, isUpcoming: true),
            
            // Past plans tab
            _buildPlansList(pastPlans, isUpcoming: false),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: "create_travel_plan_fab",
          backgroundColor: const Color(0xFF12B347),
          child: const Icon(Icons.add),
          onPressed: () {
            // Create new travel plan
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Create a new travel plan'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Build list of travel plans
  Widget _buildPlansList(List<TravelPlan> plans, {required bool isUpcoming}) {
    if (plans.isEmpty) {
      return _buildEmptyState(isUpcoming);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return _buildPlanCard(plan, isUpcoming);
      },
    );
  }
  
  // Empty state widget
  Widget _buildEmptyState(bool isUpcoming) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isUpcoming ? Icons.backpack_outlined : Icons.history_outlined,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isUpcoming ? 'No upcoming travel plans' : 'No past travel plans',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUpcoming
                ? 'Create a new plan to start your next adventure'
                : 'Your completed travel plans will appear here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (isUpcoming) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Create new plan
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF12B347),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(
                'Create New Plan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
  
  // Travel plan card widget
  Widget _buildPlanCard(TravelPlan plan, bool isUpcoming) {
    final startDate = DateFormat('MMM d, yyyy').format(plan.startDate);
    final endDate = DateFormat('MMM d, yyyy').format(plan.endDate);
    
    // Calculate days remaining or days since
    final now = DateTime.now();
    final difference = plan.startDate.difference(now).inDays;
    
    String timeIndicator;
    Color timeColor;
    
    if (isUpcoming) {
      if (difference == 0) {
        timeIndicator = 'Today';
        timeColor = Colors.orange;
      } else if (difference == 1) {
        timeIndicator = 'Tomorrow';
        timeColor = Colors.orange;
      } else {
        timeIndicator = '$difference days to go';
        timeColor = const Color(0xFF12B347);
      }
    } else {
      final daysSince = now.difference(plan.endDate).inDays;
      timeIndicator = '$daysSince days ago';
      timeColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  plan.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.white, size: 40),
                  ),
                ),
              ),
              
              // Favorite indicator
              if (plan.isFavorite)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ),
              
              // Destination badge
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        plan.destination,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Content section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan title and status indicator
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: timeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        timeIndicator,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: timeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Date range
                Row(
                  children: [
                    const Icon(
                      Icons.date_range,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$startDate - $endDate',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Activities list
                Text(
                  'Activities:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: plan.activities.map((activity) {
                    return Chip(
                      label: Text(
                        activity,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      backgroundColor: Colors.grey[200],
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isUpcoming)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      // Edit plan
                    },
                  ),
                IconButton(
                  icon: Icon(
                    plan.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: plan.isFavorite ? Colors.red : null,
                  ),
                  onPressed: () {
                    // Toggle favorite
                    setState(() {
                      final index = _travelPlans.indexWhere((p) => p.id == plan.id);
                      if (index != -1) {
                        final updatedPlan = TravelPlan(
                          id: plan.id,
                          title: plan.title,
                          destination: plan.destination,
                          startDate: plan.startDate,
                          endDate: plan.endDate,
                          imageUrl: plan.imageUrl,
                          activities: plan.activities,
                          isCompleted: plan.isCompleted,
                          isFavorite: !plan.isFavorite,
                        );
                        _travelPlans[index] = updatedPlan;
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    // Share plan
                  },
                ),
                if (!isUpcoming)
                  IconButton(
                    icon: const Icon(Icons.photo_library_outlined),
                    onPressed: () {
                      // View memories
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 